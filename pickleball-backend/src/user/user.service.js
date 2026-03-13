const prisma = require("../config/prisma");
const { hashPassword } = require("../utils/hash");
const { attachAvatar, setAvatarUrlByUserId } = require("../utils/avatarStore");
const { attachCover, setCoverUrlByUserId } = require("../utils/coverStore");

const baseSelect = {
  id: true,
  name: true,
  email: true,
  phone: true,
  role: true,
  emailVerified: true,
  paymentMethods: true,
  createdAt: true,
};

const normalizePaymentMethods = (items) => {
  if (!Array.isArray(items)) return [];
  return Array.from(new Set(items.map((item) => String(item || '').trim()).filter(Boolean)));
};

const attachProfileAssets = (user) => attachCover(attachAvatar(user));

const attachCoin = async (user) => {
  if (!user) return null;
  const tx = await prisma.coinTransaction.findMany({
    where: { userId: Number(user.id) },
    select: { amount: true },
  });
  return attachProfileAssets({ ...user, coin: tx.reduce((sum, item) => sum + Number(item.amount || 0), 0) });
};

const getCurrentUser = async (id) => attachCoin(await prisma.user.findUnique({ where: { id: Number(id) }, select: baseSelect }));

const updateCurrentUser = async (id, { name, phone, paymentMethods }) => {
  const existingUser = await prisma.user.findUnique({ where: { id: Number(id) } });
  if (!existingUser) throw new Error("Không tìm thấy user");
  const user = await prisma.user.update({
    where: { id: Number(id) },
    data: { name, phone, paymentMethods: normalizePaymentMethods(paymentMethods) },
    select: baseSelect,
  });
  return attachCoin(user);
};

const getUsers = async () => {
  const users = await prisma.user.findMany({ orderBy: { id: "asc" }, select: baseSelect });
  return Promise.all(users.map(attachCoin));
};

const getUserById = async (id) => attachCoin(await prisma.user.findUnique({ where: { id: Number(id) }, select: baseSelect }));

const createUserByAdmin = async ({ name, email, phone, password, role, emailVerified }) => {
  const existingUser = await prisma.user.findUnique({ where: { email } });
  if (existingUser) throw new Error("Email đã tồn tại");
  const hashedPassword = await hashPassword(password);
  const user = await prisma.user.create({
    data: { name, email, phone, password: hashedPassword, role, emailVerified: Boolean(emailVerified), emailVerifyCode: null, emailVerifyExpires: null, paymentMethods: [] },
    select: baseSelect,
  });
  return attachCoin(user);
};

const updateUserInfo = async (id, { name, email, phone, role, emailVerified, password }) => {
  const existingUser = await prisma.user.findUnique({ where: { id: Number(id) } });
  if (!existingUser) throw new Error("Không tìm thấy user");
  if (email && email !== existingUser.email) {
    const emailExists = await prisma.user.findUnique({ where: { email } });
    if (emailExists) throw new Error("Email đã tồn tại");
  }
  const updateData = { name, email, phone, role, emailVerified: Boolean(emailVerified) };
  if (password && password.trim()) updateData.password = await hashPassword(password.trim());
  const user = await prisma.user.update({ where: { id: Number(id) }, data: updateData, select: baseSelect });
  return attachCoin(user);
};

const updateUserRole = async (id, role) => attachCoin(await prisma.user.update({ where: { id: Number(id) }, data: { role }, select: baseSelect }));

const deleteUser = async (id) => prisma.user.delete({ where: { id: Number(id) } });

const updateCurrentUserAvatar = async (id, avatarUrl) => {
  await prisma.user.findUniqueOrThrow({ where: { id: Number(id) } });
  setAvatarUrlByUserId(Number(id), avatarUrl || null);
  return getCurrentUser(id);
};

const updateCurrentUserCover = async (id, coverUrl) => {
  await prisma.user.findUniqueOrThrow({ where: { id: Number(id) } });
  setCoverUrlByUserId(Number(id), coverUrl || null);
  return getCurrentUser(id);
};

const updateUserAvatarByAdmin = async (id, avatarUrl) => {
  await prisma.user.findUniqueOrThrow({ where: { id: Number(id) } });
  setAvatarUrlByUserId(Number(id), avatarUrl || null);
  return getUserById(id);
};

const removeUserAvatarByAdmin = async (id) => {
  await prisma.user.findUniqueOrThrow({ where: { id: Number(id) } });
  setAvatarUrlByUserId(Number(id), null);
  return getUserById(id);
};

module.exports = { getCurrentUser, updateCurrentUser, getUsers, getUserById, createUserByAdmin, updateUserInfo, updateUserRole, deleteUser, updateCurrentUserAvatar, updateCurrentUserCover, updateUserAvatarByAdmin, removeUserAvatarByAdmin };
