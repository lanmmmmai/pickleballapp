const http = require('http');
const { Server } = require('socket.io');
const app = require('./app');
const { setIo } = require('./socket');
const { syncDatabaseSchema } = require('./config/dbSync');

const PORT = process.env.PORT || 3000;
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  },
});

io.on('connection', (socket) => {
  socket.on('join:staff', () => socket.join('staff'));
  socket.on('join:user', (userId) => socket.join(`user:${userId}`));
});

setIo(io);

const start = async () => {
  await syncDatabaseSchema();
  server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
};

start().catch((error) => {
  console.error('Failed to start server:', error);
  process.exit(1);
});
