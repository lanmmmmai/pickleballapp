const prisma = require("../config/prisma");

const getCourts = async () => {
  return prisma.court.findMany({
    include: {
      priceSlots: {
        orderBy: { startTime: "asc" },
      },
    },
    orderBy: { id: "asc" },
  });
};

const createCourt = async ({
  name,
  description,
  imageUrl,
  openTime,
  closeTime,
  status,
  priceSlots,
}) => {
  return prisma.court.create({
    data: {
      name,
      description,
      imageUrl,
      openTime,
      closeTime,
      status,
      priceSlots: {
        create: priceSlots.map((slot) => ({
          startTime: slot.startTime,
          endTime: slot.endTime,
          price: Number(slot.price),
        })),
      },
    },
    include: {
      priceSlots: true,
    },
  });
};

const updateCourt = async (
  id,
  {
    name,
    description,
    imageUrl,
    openTime,
    closeTime,
    status,
    priceSlots,
  }
) => {
  await prisma.courtPriceSlot.deleteMany({
    where: { courtId: Number(id) },
  });

  return prisma.court.update({
    where: { id: Number(id) },
    data: {
      name,
      description,
      openTime,
      closeTime,
      status,
      ...(imageUrl !== undefined ? { imageUrl } : {}),
      priceSlots: {
        create: priceSlots.map((slot) => ({
          startTime: slot.startTime,
          endTime: slot.endTime,
          price: Number(slot.price),
        })),
      },
    },
    include: {
      priceSlots: true,
    },
  });
};

const deleteCourt = async (id) => {
  return prisma.court.delete({
    where: { id: Number(id) },
  });
};

module.exports = {
  getCourts,
  createCourt,
  updateCourt,
  deleteCourt,
};