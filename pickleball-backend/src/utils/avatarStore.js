const { readJson, writeJson } = require('./jsonStore');

const AVATAR_STORE_PATH = 'data/user_avatars.json';

const getAvatarMap = () => readJson(AVATAR_STORE_PATH, {});
const saveAvatarMap = (items) => writeJson(AVATAR_STORE_PATH, items);

const getAvatarUrlByUserId = (userId) => {
  if (!userId) return null;
  const items = getAvatarMap();
  return items[String(userId)] || null;
};

const setAvatarUrlByUserId = (userId, avatarUrl) => {
  if (!userId) return null;
  const items = getAvatarMap();
  items[String(userId)] = avatarUrl || null;
  saveAvatarMap(items);
  return items[String(userId)] || null;
};

const attachAvatar = (user) => {
  if (!user) return null;
  return { ...user, avatarUrl: getAvatarUrlByUserId(user.id) };
};

module.exports = {
  getAvatarUrlByUserId,
  setAvatarUrlByUserId,
  attachAvatar,
};
