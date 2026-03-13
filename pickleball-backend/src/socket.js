let io = null;

function setIo(instance) {
  io = instance;
}

function getIo() {
  return io;
}

function emitBookingUpdate(payload) {
  if (io) io.emit('booking:update', payload);
}

module.exports = { setIo, getIo, emitBookingUpdate };
