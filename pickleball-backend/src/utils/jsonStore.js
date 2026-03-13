const fs = require('fs');
const path = require('path');

const readJson = (relPath, fallback=[]) => {
  const file = path.join(__dirname, '..', relPath);
  try {
    if (!fs.existsSync(file)) return fallback;
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch (e) {
    return fallback;
  }
};

const writeJson = (relPath, data) => {
  const file = path.join(__dirname, '..', relPath);
  fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf8');
  return data;
};

module.exports = { readJson, writeJson };
