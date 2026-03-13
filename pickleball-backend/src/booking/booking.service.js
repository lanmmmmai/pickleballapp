const prisma = require("../config/prisma");
const { emitBookingUpdate } = require('../socket');
const { createAutoNotification } = require('../notification/notification.service');
const { sendBookingBillEmail } = require('../services/email.service');

const bookingInclude = {
  user: { select: { id: true, name: true, email: true, phone: true } },
  court: { select: { id: true, name: true, imageUrl: true, openTime: true, closeTime: true, priceSlots: true } },
};

const getBookings = async () => prisma.booking.findMany({ orderBy: { id: 'desc' }, include: bookingInclude });
const getBookingById = async (id) => prisma.booking.findUnique({ where: { id: Number(id) }, include: bookingInclude });
const getMyBookings = async (userId) => prisma.booking.findMany({ where: { userId: Number(userId) }, orderBy: { id: 'desc' }, include: bookingInclude });

const toMinutes = (value) => {
  const [h = '0', m = '0'] = String(value || '').split(':');
  return Number(h) * 60 + Number(m);
};

const normalizeCourtId = async (courtId) => {
  const numericId = Number(String(courtId).replace('court-', ''));
  if (!numericId) throw new Error('Sân không hợp lệ');
  const court = await prisma.court.findUnique({ where: { id: numericId }, include: { priceSlots: true } });
  if (!court) throw new Error('Không tìm thấy sân');
  return court;
};

const computeCourtPrice = (priceSlots = [], startTime, endTime) => {
  const startMin = toMinutes(startTime);
  const endMin = toMinutes(endTime);
  if (!startMin || !endMin || endMin <= startMin) throw new Error('Khung giờ không hợp lệ');
  let total = 0;
  for (const slot of priceSlots || []) {
    const slotStart = toMinutes(slot.startTime);
    const slotEnd = toMinutes(slot.endTime);
    const overlapStart = Math.max(startMin, slotStart);
    const overlapEnd = Math.min(endMin, slotEnd);
    if (overlapEnd > overlapStart) {
      const hours = (overlapEnd - overlapStart) / 60;
      total += hours * Number(slot.price || 0);
    }
  }
  if (total <= 0) throw new Error('Không tính được giá sân cho khung giờ đã chọn');
  return Number(total.toFixed(2));
};

const normalizeExtras = (extras = []) => {
  if (!Array.isArray(extras)) return [];
  return extras
    .map((item) => ({
      id: Number(item.id || 0),
      name: String(item.name || 'Dịch vụ'),
      type: String(item.type || 'EXTRA'),
      qty: Number(item.qty || 0),
      price: Number(item.price || 0),
    }))
    .filter((item) => item.qty > 0 && item.price >= 0);
};

const computeExtrasTotal = (extras = []) => {
  return Number(extras.reduce((sum, item) => sum + (Number(item.qty || 0) * Number(item.price || 0)), 0).toFixed(2));
};

const createBooking = async ({ userId, courtId, bookingDate, startTime, endTime, totalPrice, paymentMethod, voucherCode, extras = [] }) => {
  const court = await normalizeCourtId(courtId);
  const normalizedExtras = normalizeExtras(extras);
  const courtPrice = computeCourtPrice(court.priceSlots || [], startTime, endTime);
  const extrasTotal = computeExtrasTotal(normalizedExtras);
  const subtotal = Number((courtPrice + extrasTotal).toFixed(2));

  let usableVoucher = null;
  let discountValue = 0;
  if (voucherCode) {
    const userVoucher = await prisma.userVoucher.findFirst({
      where: { userId: Number(userId), status: 'AVAILABLE', voucher: { code: voucherCode } },
      include: { voucher: true },
      orderBy: { id: 'desc' },
    });
    if (!userVoucher) throw new Error('Voucher không khả dụng hoặc đã dùng');

    const voucher = userVoucher.voucher;
    const now = new Date();
    if (voucher.isActive === false) throw new Error('Voucher hiện không hoạt động');
    if (voucher.startDate && now < new Date(voucher.startDate)) throw new Error('Voucher chưa đến thời gian sử dụng');
    if (voucher.endDate && now > new Date(voucher.endDate)) throw new Error('Voucher đã hết hạn');
    if (subtotal < Number(voucher.minOrderValue || 0)) throw new Error('Đơn chưa đủ điều kiện áp dụng voucher');

    const rawDiscount = voucher.discountType === 'PERCENT'
      ? subtotal * Number(voucher.discountValue || 0) / 100
      : Number(voucher.discountValue || 0);
    discountValue = Math.min(subtotal, Number(rawDiscount || 0));
    usableVoucher = userVoucher;
  }

  const finalTotal = Number((subtotal - discountValue).toFixed(2));
  if (Number(totalPrice || 0) > 0) {
    const delta = Math.abs(Number(totalPrice || 0) - finalTotal);
    if (delta > 1000) {
      throw new Error('Tổng tiền không hợp lệ, vui lòng thử đặt lại');
    }
  }

  const booking = await prisma.booking.create({
    data: {
      userId: Number(userId),
      courtId: court.id,
      bookingDate: new Date(bookingDate),
      startTime,
      endTime,
      totalPrice: finalTotal,
      courtPrice,
      paymentMethod: paymentMethod || 'Tiền mặt',
      voucherCode: voucherCode || null,
      extras: normalizedExtras,
      status: 'CONFIRMED',
    },
    include: bookingInclude,
  });
  emitBookingUpdate({ action: 'created', booking });

  await createAutoNotification({
    title: 'Đặt sân thành công',
    content: `${booking.user.name} đã đặt ${booking.court.name} vào ${booking.startTime} - ${booking.endTime}, tổng ${Number(booking.totalPrice).toFixed(0)}đ.`,
    type: 'BOOKING',
    userId: booking.userId,
  });
  await createAutoNotification({
    title: 'Booking mới',
    content: `${booking.user.name} vừa tạo booking #${booking.id} tại ${booking.court.name} (${booking.startTime} - ${booking.endTime}).`,
    type: 'BOOKING',
    userId: null,
  });

  if (usableVoucher) {
    await prisma.$transaction([
      prisma.userVoucher.update({ where: { id: usableVoucher.id }, data: { status: 'USED', usedAt: new Date() } }),
      prisma.voucher.update({ where: { id: usableVoucher.voucherId }, data: { usedCount: { increment: 1 } } }),
    ]);
  }

  if (booking.user?.email) {
    await sendBookingBillEmail({
      to: booking.user.email,
      name: booking.user.name,
      booking,
      extras: normalizedExtras,
      voucherCode,
      paymentMethod,
    }).catch((error) => console.error('[booking] send bill failed:', error.message));
  }

  return booking;
};

const updateBookingStatus = async (id, status) => {
  const data = { status };
  if (status === 'CHECKED_IN') data.checkedInAt = new Date();
  const booking = await prisma.booking.update({ where: { id: Number(id) }, data, include: bookingInclude });
  emitBookingUpdate({ action: 'status', booking });
  await createAutoNotification({
    title: `Booking #${booking.id} cập nhật`,
    content: `${booking.user.name} • ${booking.court.name} hiện ở trạng thái ${booking.status}`,
    type: 'BOOKING',
    userId: booking.userId,
  });
  return booking;
};

const deleteBooking = async (id) => {
  const booking = await prisma.booking.delete({ where: { id: Number(id) } });
  emitBookingUpdate({ action: 'deleted', booking });
  return booking;
};

module.exports = { getBookings, getBookingById, getMyBookings, createBooking, updateBookingStatus, deleteBooking };
