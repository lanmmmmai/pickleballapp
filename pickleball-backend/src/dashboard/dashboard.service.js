const prisma = require("../config/prisma");

const getDashboardStats = async () => {
  const [
    totalUsers,
    totalCourts,
    totalBookings,
    totalNotifications,
    totalVideos,
    totalVouchers,
    latestUsers,
    latestBookings,
  ] = await Promise.all([
    prisma.user.count(),
    prisma.court.count(),
    prisma.booking.count(),
    prisma.notification.count(),
    prisma.video.count(),
    prisma.voucher.count().catch(() => 0),
    prisma.user.findMany({
      orderBy: { createdAt: "desc" },
      take: 5,
      select: {
        id: true,
        name: true,
        email: true,
        createdAt: true,
      },
    }),
    prisma.booking.findMany({
      orderBy: { createdAt: "desc" },
      take: 5,
      include: {
        user: { select: { name: true } },
        court: { select: { name: true } },
      },
    }).catch(() => []),
  ]);

  return {
    totalUsers,
    totalCourts,
    totalBookings,
    totalNotifications,
    totalVideos,
    totalVouchers,
    latestUsers,
    latestBookings,
  };
};

module.exports = {
  getDashboardStats,
};
