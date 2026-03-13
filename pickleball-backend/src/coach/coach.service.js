const prisma = require('../config/prisma');

const getCoaches = async () => {
  return prisma.user.findMany({ where: { role: 'COACH' } });
};

module.exports = { getCoaches };