const prisma = require('../config/prisma');

const mapCourtToProduct = (court) => ({
  id: `court-${court.id}`,
  legacyId: court.id,
  name: court.name,
  description: court.description,
  imageUrl: court.imageUrl,
  type: 'COURT',
  price: court.priceSlots?.[0]?.price || 0,
  stock: 1,
  status: court.status || 'ACTIVE',
  coachUserId: null,
  coach: null,
  source: 'COURT_TABLE',
  openTime: court.openTime,
  closeTime: court.closeTime,
  priceSlots: court.priceSlots || [],
  createdAt: court.createdAt,
});

const getCourtsAsProducts = async () => {
  const courts = await prisma.court.findMany({
    include: { priceSlots: { orderBy: { startTime: 'asc' } } },
    orderBy: { id: 'desc' },
  }).catch(() => []);
  return courts.map(mapCourtToProduct);
};

const getProducts = async (type) => {
  if (type === 'COURT') {
    return getCourtsAsProducts();
  }

  const where = type ? { type } : undefined;
  return prisma.product.findMany({
    where,
    include: { coach: { select: { id: true, name: true, email: true } } },
    orderBy: { id: 'desc' },
  });
};

const createCourtProduct = async (data) => {
  const slots = Array.isArray(data.priceSlots) ? data.priceSlots : [];
  const court = await prisma.court.create({
    data: {
      name: data.name,
      description: data.description || '',
      imageUrl: data.imageUrl || null,
      openTime: data.openTime || '06:00',
      closeTime: data.closeTime || '22:00',
      status: data.status === 'INACTIVE' ? 'MAINTENANCE' : (data.status || 'AVAILABLE'),
      priceSlots: {
        create: slots
          .filter((slot) => slot && slot.startTime && slot.endTime)
          .map((slot) => ({
            startTime: String(slot.startTime),
            endTime: String(slot.endTime),
            price: Number(slot.price || 0),
          })),
      },
    },
    include: { priceSlots: { orderBy: { startTime: 'asc' } } },
  });
  return mapCourtToProduct(court);
};

const updateCourtProduct = async (id, data) => {
  const courtId = Number(String(id).replace('court-', ''));
  const slots = Array.isArray(data.priceSlots) ? data.priceSlots : [];
  await prisma.courtPriceSlot.deleteMany({ where: { courtId } });
  const court = await prisma.court.update({
    where: { id: courtId },
    data: {
      name: data.name,
      description: data.description || '',
      imageUrl: data.imageUrl || undefined,
      openTime: data.openTime || '06:00',
      closeTime: data.closeTime || '22:00',
      status: data.status === 'INACTIVE' ? 'MAINTENANCE' : (data.status || undefined),
      priceSlots: {
        create: slots
          .filter((slot) => slot && slot.startTime && slot.endTime)
          .map((slot) => ({
            startTime: String(slot.startTime),
            endTime: String(slot.endTime),
            price: Number(slot.price || 0),
          })),
      },
    },
    include: { priceSlots: { orderBy: { startTime: 'asc' } } },
  });
  return mapCourtToProduct(court);
};

const deleteCourtProduct = async (id) => {
  const courtId = Number(String(id).replace('court-', ''));
  await prisma.court.delete({ where: { id: courtId } });
  return true;
};

const createProduct = async (data) => {
  if ((data.type || 'COURT') === 'COURT') return createCourtProduct(data);
  return prisma.product.create({
    data: {
      name: data.name,
      description: data.description || '',
      imageUrl: data.imageUrl || null,
      type: data.type || 'BALL',
      price: Number(data.price || 0),
      stock: Number(data.stock || 0),
      status: data.status || 'ACTIVE',
      coachUserId: data.coachUserId ? Number(data.coachUserId) : null,
    },
    include: { coach: { select: { id: true, name: true, email: true } } },
  });
};

const updateProduct = async (id, data) => {
  if (String(id).startsWith('court-')) return updateCourtProduct(id, data);
  return prisma.product.update({
    where: { id: Number(id) },
    data: {
      name: data.name,
      description: data.description || '',
      imageUrl: data.imageUrl || undefined,
      type: data.type || undefined,
      price: Number(data.price || 0),
      stock: Number(data.stock || 0),
      status: data.status || undefined,
      coachUserId: data.coachUserId ? Number(data.coachUserId) : null,
    },
    include: { coach: { select: { id: true, name: true, email: true } } },
  });
};

const deleteProduct = async (id) => {
  if (String(id).startsWith('court-')) return deleteCourtProduct(id);
  return prisma.product.delete({ where: { id: Number(id) } });
};

module.exports = { getProducts, createProduct, updateProduct, deleteProduct };
