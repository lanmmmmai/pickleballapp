const prisma = require("../config/prisma");
const { readJson, writeJson } = require('../utils/jsonStore');
const { createAutoNotification } = require('../notification/notification.service');

const TASKS_PATH = 'data/coin_tasks.json';
const getTaskStore = () => readJson(TASKS_PATH, []);
const saveTaskStore = (tasks) => writeJson(TASKS_PATH, tasks);

const getUserCoin = async (userId) => {
  const tx = await prisma.coinTransaction.findMany({ where: { userId: Number(userId) }, select: { amount: true } });
  return tx.reduce((sum, item) => sum + Number(item.amount || 0), 0);
};

const getUsersWithCoin = async () => {
  const users = await prisma.user.findMany({ select: { id: true, name: true, email: true, phone: true, role: true, createdAt: true }, orderBy: [{ id: "asc" }] });
  const withCoin = await Promise.all(users.map(async (user) => ({ ...user, coin: await getUserCoin(user.id) })));
  return withCoin.sort((a, b) => b.coin - a.coin || a.id - b.id);
};

const getCoinTransactions = async () => prisma.coinTransaction.findMany({ include: { user: { select: { id: true, name: true, email: true } } }, orderBy: { createdAt: "desc" } });
const getUserCoinHistory = async (userId) => prisma.coinTransaction.findMany({ where: { userId: Number(userId) }, orderBy: { createdAt: 'desc' } });
const getMyVouchers = async (userId) => prisma.userVoucher.findMany({ where: { userId: Number(userId) }, include: { voucher: true }, orderBy: [{ status: 'asc' }, { createdAt: 'desc' }] });

const isTaskEligible = async (userId, task) => {
  const title = String(task.title || '').toLowerCase();
  const user = await prisma.user.findUnique({ where: { id: Number(userId) } });
  if (!user) return { eligible: false, reason: 'Không tìm thấy người dùng' };
  if (title.includes('đăng nhập')) return { eligible: true, reason: '' };
  if (title.includes('hồ sơ')) {
    const ok = Boolean(user.phone) && Array.isArray(user.paymentMethods) && user.paymentMethods.length > 0;
    return { eligible: ok, reason: ok ? '' : 'Hãy cập nhật số điện thoại và phương thức thanh toán trong hồ sơ' };
  }
  if (title.includes('video')) return { eligible: false, reason: 'Nhiệm vụ này sẽ mở khi hệ thống theo dõi lượt xem video' };
  if (task.criteriaType === 'PROFILE_COMPLETED') {
    const ok = Boolean(user.phone) && Array.isArray(user.paymentMethods) && user.paymentMethods.length > 0;
    return { eligible: ok, reason: ok ? '' : 'Hồ sơ chưa hoàn tất' };
  }
  return { eligible: false, reason: 'Nhiệm vụ chưa đủ điều kiện để nhận thưởng' };
};

const getTasks = async (userId) => {
  const tasks = getTaskStore().filter((task) => task.active !== false);
  const today = new Date().toISOString().slice(0, 10);
  const tx = await prisma.coinTransaction.findMany({ where: { userId: Number(userId) }, select: { type: true, note: true } });
  const doneSet = new Set(tx.filter((t) => (t.note || '').includes(today)).map((t) => t.type));
  const enriched = [];
  for (const task of tasks) {
    const eligibility = await isTaskEligible(userId, task);
    enriched.push({ ...task, claimed: doneSet.has(`TASK_${task.id}`), eligible: eligibility.eligible, reason: eligibility.reason || null });
  }
  return enriched;
};

const claimTask = async (userId, taskId) => {
  const task = getTaskStore().find((item) => item.id === taskId && item.active !== false);
  if (!task) throw new Error("Không tìm thấy nhiệm vụ");
  const eligibility = await isTaskEligible(userId, task);
  if (!eligibility.eligible) throw new Error(eligibility.reason || 'Bạn chưa hoàn thành nhiệm vụ này');
  const today = new Date().toISOString().slice(0, 10);
  const txType = `TASK_${task.id}`;
  const existing = await prisma.coinTransaction.findFirst({ where: { userId: Number(userId), type: txType, note: { contains: today } } });
  if (existing) throw new Error("Bạn đã nhận nhiệm vụ này hôm nay");
  const user = await prisma.user.findUnique({ where: { id: Number(userId) } });
  if (task.rewardType === 'VOUCHER') {
    if (!task.voucherId) throw new Error('Nhiệm vụ này chưa gắn voucher');
    const voucher = await prisma.voucher.findUnique({ where: { id: Number(task.voucherId) } });
    if (!voucher || !voucher.isActive) throw new Error('Voucher không khả dụng');
    const ownedVoucher = await prisma.userVoucher.findFirst({ where: { userId: Number(userId), voucherId: Number(task.voucherId), status: 'AVAILABLE' } });
    if (ownedVoucher) throw new Error('Bạn đang có voucher này và chưa sử dụng');
    await prisma.userVoucher.create({ data: { userId: Number(userId), voucherId: Number(task.voucherId), status: 'AVAILABLE' } });
    const tx = await prisma.coinTransaction.create({ data: { userId: Number(userId), amount: 0, type: txType, note: `Task voucher ${task.id} ${today}` } });
    await createAutoNotification({ title: 'Bạn nhận được voucher', content: `${user?.name || 'Người dùng'} vừa nhận voucher ${voucher.code} từ nhiệm vụ ${task.title}.`, type: 'COIN', userId: Number(userId) });
    return tx;
  }
  const tx = await prisma.coinTransaction.create({ data: { userId: Number(userId), amount: Number(task.amount || 0), type: txType, note: `Task ${task.id} ${today}` } });
  await createAutoNotification({ title: 'Bạn nhận được xu', content: `${user?.name || 'Người dùng'} vừa nhận ${Number(task.amount || 0)} xu từ nhiệm vụ ${task.title}.`, type: 'COIN', userId: Number(userId) });
  return tx;
};

const createTask = async (payload) => {
  const tasks = getTaskStore();
  const id = String(payload.id || payload.title || `task_${Date.now()}`).toLowerCase().replace(/[^a-z0-9_]+/g, '_');
  if (tasks.some((t) => t.id === id)) throw new Error('Mã nhiệm vụ đã tồn tại');
  const item = { id, title: payload.title, rewardType: payload.rewardType || 'COIN', amount: Number(payload.amount || 0), voucherId: payload.voucherId ? Number(payload.voucherId) : null, criteriaType: payload.criteriaType || null, active: true };
  tasks.push(item);
  saveTaskStore(tasks);
  return item;
};

const deleteTask = async (id) => { const tasks = getTaskStore(); saveTaskStore(tasks.filter((item) => item.id !== id)); return true; };
module.exports = { getUsersWithCoin, getCoinTransactions, getUserCoinHistory, getMyVouchers, getTasks, claimTask, getUserCoin, createTask, deleteTask };
