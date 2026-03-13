const prisma = require("../config/prisma");

async function getLiveContext({ question, userId }) {
  const q = (question || "").toLowerCase();

  const needsCourts =
    /sân|court|giờ cao điểm|giờ thấp điểm|giá sân|khung giờ|slot|mở cửa|đóng cửa/.test(q);

  const needsBookings =
    /đặt sân|booking|lịch đặt|còn trống|trống|hôm nay|tối nay|ngày mai/.test(q);

  const needsCoaches =
    /hlv|huấn luyện viên|coach|dạy|lớp học/.test(q);

  const needsVouchers =
    /voucher|khuyến mãi|ưu đãi|mã giảm/.test(q);

  const needsVideos =
    /video|clip|hướng dẫn|reel|tiktok/.test(q);

  const live = {
    courts: [],
    coaches: [],
    vouchers: [],
    videos: [],
    bookings: [],
  };

  if (needsCourts || needsBookings) {
    live.courts = await prisma.court.findMany({
      include: {
        priceSlots: {
          orderBy: { startTime: "asc" },
        },
      },
      orderBy: { id: "asc" },
    });
  }

  if (needsCoaches) {
    live.coaches = await prisma.user.findMany({
      where: { role: "COACH" },
      select: {
        id: true,
        name: true,
        phone: true,
        email: true,
      },
      orderBy: { id: "asc" },
    });
  }

  if (needsVouchers) {
    const now = new Date();
    live.vouchers = await prisma.voucher.findMany({
      where: {
        isActive: true,
        startDate: { lte: now },
        endDate: { gte: now },
      },
      orderBy: { createdAt: "desc" },
      take: 10,
    });
  }

  if (needsVideos) {
    live.videos = await prisma.video.findMany({
      where: { isActive: true },
      orderBy: { createdAt: "desc" },
      take: 10,
    });
  }

  if (needsBookings && userId) {
    live.bookings = await prisma.booking.findMany({
      where: { userId: Number(userId) },
      include: {
        court: {
          select: {
            id: true,
            name: true,
            openTime: true,
            closeTime: true,
          },
        },
      },
      orderBy: { createdAt: "desc" },
      take: 10,
    });
  }

  return live;
}

function formatCourt(court) {
  const slots = (court.priceSlots || [])
    .map((s) => `${s.startTime}-${s.endTime}: ${Number(s.price).toLocaleString("vi-VN")}đ`)
    .join("; ");

  return `- ${court.name} | giờ hoạt động ${court.openTime}-${court.closeTime} | trạng thái ${court.status}${slots ? ` | giá: ${slots}` : ""}`;
}

function formatBooking(booking) {
  return `- Booking #${booking.id} | sân ${booking.court?.name || booking.courtId} | ngày ${new Date(
    booking.bookingDate
  ).toLocaleDateString("vi-VN")} | ${booking.startTime}-${booking.endTime} | trạng thái ${booking.status} | tổng ${Number(
    booking.totalPrice
  ).toLocaleString("vi-VN")}đ`;
}

function formatLiveContext(liveData) {
  const parts = [];

  if (liveData.courts?.length) {
    parts.push(
      `DANH SÁCH SÂN HIỆN TẠI:\n${liveData.courts.map(formatCourt).join("\n")}`
    );
  }

  if (liveData.coaches?.length) {
    parts.push(
      `HLV HIỆN CÓ:\n${liveData.coaches
        .map((c) => `- ${c.name}${c.phone ? ` | ${c.phone}` : ""}`)
        .join("\n")}`
    );
  }

  if (liveData.vouchers?.length) {
    parts.push(
      `VOUCHER ĐANG HOẠT ĐỘNG:\n${liveData.vouchers
        .map(
          (v) =>
            `- ${v.code} | ${v.title} | ${v.discountType} ${v.discountValue} | hết hạn ${new Date(
              v.endDate
            ).toLocaleDateString("vi-VN")}`
        )
        .join("\n")}`
    );
  }

  if (liveData.videos?.length) {
    parts.push(
      `VIDEO ĐANG CÓ:\n${liveData.videos
        .map((v) => `- ${v.title} | category ${v.category}`)
        .join("\n")}`
    );
  }

  if (liveData.bookings?.length) {
    parts.push(
      `BOOKING CỦA NGƯỜI DÙNG:\n${liveData.bookings.map(formatBooking).join("\n")}`
    );
  }

  return parts.join("\n\n").trim();
}

module.exports = {
  getLiveContext,
  formatLiveContext,
};