const prisma = require("../config/prisma");
const { readJson, writeJson } = require('../utils/jsonStore');

const USER_NOTIFICATIONS_PATH = 'data/user_notifications.json';
const getStore = () => readJson(USER_NOTIFICATIONS_PATH, []);
const saveStore = (items) => writeJson(USER_NOTIFICATIONS_PATH, items);

const getNotifications = async (userId = null, options = {}) => {
  const items = getStore();
  const includeAll = options.includeAll === true;
  if (includeAll) {
    return items
      .filter((n) => n.isActive !== false)
      .sort((a, b) => new Date(b.createdAt || 0).getTime() - new Date(a.createdAt || 0).getTime());
  }
  if (userId) {
    return items
      .filter((n) => Number(n.userId) === Number(userId) && n.isActive !== false)
      .sort((a, b) => new Date(b.createdAt || 0).getTime() - new Date(a.createdAt || 0).getTime());
  }
  return [];
};

const getNotificationById = async (id, userId = null) => {
  const all = await getNotifications(userId);
  return all.find((item) => Number(item.id) === Number(id)) || null;
};

const createNotification = async ({ title, content, type, isActive, imageUrl, userId = null }) => {
  if (userId) {
    const items = getStore();
    const item = {
      id: Date.now(),
      userId: Number(userId),
      title,
      content,
      type,
      imageUrl: imageUrl || null,
      isActive,
      createdAt: new Date().toISOString(),
    };
    items.unshift(item);
    saveStore(items);
    return item;
  }
  const items = getStore();
  const item = {
    id: Date.now(),
    userId: null,
    title,
    content,
    type,
    imageUrl: imageUrl || null,
    isActive,
    createdAt: new Date().toISOString(),
  };
  items.unshift(item);
  saveStore(items);
  return item;
};

const createAutoNotification = async ({ title, content, type = 'SYSTEM', userId = null }) => {
  try {
    return await createNotification({ title, content, type, isActive: true, userId });
  } catch (error) {
    console.error('[notification] auto create failed:', error.message);
    return null;
  }
};

const updateNotification = async (id, { title, content, type, isActive, imageUrl, userId = null }) => {
  if (userId) {
    const items = getStore();
    const idx = items.findIndex((n) => Number(n.id) === Number(id) && Number(n.userId) === Number(userId));
    if (idx < 0) throw new Error('Không tìm thấy thông báo');
    items[idx] = { ...items[idx], title, content, type, isActive, ...(imageUrl !== undefined ? { imageUrl } : {}) };
    saveStore(items);
    return items[idx];
  }
  const items = getStore();
  const idx = items.findIndex((n) => Number(n.id) === Number(id));
  if (idx < 0) throw new Error('Không tìm thấy thông báo');
  items[idx] = { ...items[idx], title, content, type, isActive, ...(imageUrl !== undefined ? { imageUrl } : {}) };
  saveStore(items);
  return items[idx];
};

const deleteNotification = async (id, userId = null) => {
  if (userId) {
    const items = getStore().filter((n) => !(Number(n.id) === Number(id) && Number(n.userId) === Number(userId)));
    saveStore(items);
    return true;
  }
  const items = getStore().filter((n) => Number(n.id) !== Number(id));
  saveStore(items);
  return true;
};

module.exports = {
  getNotifications,
  getNotificationById,
  createNotification,
  createAutoNotification,
  updateNotification,
  deleteNotification,
};
