const prisma = require('../config/prisma');
const { readJson, writeJson } = require('../utils/jsonStore');

const REWARDS_PATH = 'data/spin_rewards.json';

const getRewards = () => readJson(REWARDS_PATH, []);
const saveRewards = (items) => writeJson(REWARDS_PATH, items);

const createReward = async (payload) => {
  const rewards = getRewards();
  const item = {
    id: String(payload.id || payload.label || `reward_${Date.now()}`).toLowerCase().replace(/[^a-z0-9_]+/g, '_'),
    label: payload.label,
    rewardType: payload.rewardType || 'COIN',
    amount: Number(payload.amount || 0),
    voucherId: payload.voucherId ? Number(payload.voucherId) : null,
    weight: Number(payload.weight || 1),
    active: true,
  };
  rewards.push(item);
  saveRewards(rewards);
  return item;
};

const deleteReward = async (id) => {
  const rewards = getRewards();
  saveRewards(rewards.filter((item) => item.id !== id));
  return true;
};

const weightedPick = (items) => {
  const list = items.flatMap((item) => Array.from({ length: Math.max(1, Number(item.weight || 1)) }, () => item));
  return list[Math.floor(Math.random() * list.length)];
};

const playSpin = async (userId) => {
  const today = new Date().toISOString().slice(0, 10);
  const existing = await prisma.coinTransaction.findFirst({ where: { userId: Number(userId), type: 'SPIN_DAILY', note: { contains: today } } });
  if (existing) throw new Error('Bạn đã quay hôm nay rồi');

  const rewards = getRewards().filter((item) => item.active !== false);
  if (!rewards.length) throw new Error('Chưa cấu hình phần thưởng vòng quay');
  const reward = weightedPick(rewards);

  if (reward.rewardType === 'VOUCHER') {
    if (!reward.voucherId) throw new Error('Phần thưởng voucher chưa hợp lệ');
    await prisma.userVoucher.create({ data: { userId: Number(userId), voucherId: Number(reward.voucherId), status: 'AVAILABLE' } });
    await prisma.coinTransaction.create({ data: { userId: Number(userId), amount: 0, type: 'SPIN_DAILY', note: `SPIN ${today} ${reward.label}` } });
  } else {
    await prisma.coinTransaction.create({ data: { userId: Number(userId), amount: Number(reward.amount || 0), type: 'SPIN_DAILY', note: `SPIN ${today} ${reward.label}` } });
  }

  return { reward };
};

module.exports = { playSpin, getRewards, createReward, deleteReward };
