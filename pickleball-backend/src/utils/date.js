const toDateString = (date = new Date()) => {
  return new Date(date).toISOString().split('T')[0];
};

module.exports = {
  toDateString,
};