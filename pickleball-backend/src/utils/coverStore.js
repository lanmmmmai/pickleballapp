const { readJson, writeJson } = require('./jsonStore');

const COVER_STORE_PATH = 'data/user_covers.json';

const getCoverMap = () => readJson(COVER_STORE_PATH, {});
const saveCoverMap = (items) => writeJson(COVER_STORE_PATH, items);

const getCoverUrlByUserId = (userId) => {
  if (!userId) return null;
  const items = getCoverMap();
  return items[String(userId)] || null;
};

const setCoverUrlByUserId = (userId, coverUrl) => {
  if (!userId) return null;
  const items = getCoverMap();
  items[String(userId)] = coverUrl || null;
  saveCoverMap(items);
  return items[String(userId)] || null;
};

const attachCover = (user) => {
  if (!user) return null;
  return { ...user, coverUrl: getCoverUrlByUserId(user.id) };
};

module.exports = {
  getCoverUrlByUserId,
  setCoverUrlByUserId,
  attachCover,
};
