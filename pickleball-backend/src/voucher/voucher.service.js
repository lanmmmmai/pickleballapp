const prisma = require("../config/prisma");
const { createAutoNotification } = require('../notification/notification.service');

const getVouchers = async () => prisma.voucher.findMany({ orderBy: { createdAt: "desc" } });

const createVoucher = async ({ code, title, description, discountType, discountValue, minOrderValue, coinCost, quantity, startDate, endDate, isActive }) => {
  return prisma.voucher.create({
    data: { code, title, description, discountType, discountValue: Number(discountValue), minOrderValue: Number(minOrderValue || 0), coinCost: Number(coinCost || 0), quantity: Number(quantity || 0), redeemedCount: 0, usedCount: 0, startDate: new Date(startDate), endDate: new Date(endDate), isActive: isActive === true || isActive === "true" },
  });
};

const updateVoucher = async (id, { code, title, description, discountType, discountValue, minOrderValue, coinCost, quantity, startDate, endDate, isActive }) => {
  return prisma.voucher.update({
    where: { id: Number(id) },
    data: { code, title, description, discountType, discountValue: Number(discountValue), minOrderValue: Number(minOrderValue || 0), coinCost: Number(coinCost || 0), quantity: Number(quantity || 0), startDate: new Date(startDate), endDate: new Date(endDate), isActive: isActive === true || isActive === "true" },
  });
};

const redeemVoucher = async ({ userId, voucherId }) => {
  const voucher = await prisma.voucher.findUnique({ where: { id: Number(voucherId) } });
  if (!voucher) throw new Error("Không tìm thấy voucher");
  if (!voucher.isActive) throw new Error("Voucher đang bị ẩn");
  const now = new Date();
  if (now < new Date(voucher.startDate) || now > new Date(voucher.endDate)) throw new Error("Voucher không nằm trong thời gian áp dụng");
  if (voucher.redeemedCount >= voucher.quantity) throw new Error("Voucher đã hết lượt đổi");
  const user = await prisma.user.findUnique({ where: { id: Number(userId) } });
  if (!user) throw new Error("Không tìm thấy user");
  const existingAvailable = await prisma.userVoucher.findFirst({ where: { userId: Number(userId), voucherId: Number(voucherId), status: 'AVAILABLE' } });
  if (existingAvailable) throw new Error('Bạn đã có voucher này và chưa sử dụng');
  const coinTx = await prisma.coinTransaction.findMany({ where: { userId: Number(userId) }, select: { amount: true } });
  const currentCoin = coinTx.reduce((sum, item) => sum + Number(item.amount || 0), 0);
  if (currentCoin < voucher.coinCost) throw new Error("Không đủ xu để đổi voucher");

  await prisma.$transaction([
    prisma.voucher.update({ where: { id: Number(voucherId) }, data: { redeemedCount: { increment: 1 } } }),
    prisma.userVoucher.create({ data: { userId: Number(userId), voucherId: Number(voucherId), status: "AVAILABLE" } }),
    prisma.coinTransaction.create({ data: { userId: Number(userId), amount: -voucher.coinCost, type: "VOUCHER_REDEEM", note: `Đổi voucher ${voucher.code}` } }),
  ]);
  await createAutoNotification({ title: 'Đổi voucher thành công', content: `${user.name} vừa đổi voucher ${voucher.code} với ${voucher.coinCost} xu.`, type: 'VOUCHER', userId: Number(userId) });
  return { message: "Đổi voucher thành công" };
};

const deleteVoucher = async (id) => prisma.voucher.delete({ where: { id: Number(id) } });

module.exports = { getVouchers, createVoucher, updateVoucher, redeemVoucher, deleteVoucher };
