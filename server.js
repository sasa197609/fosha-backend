const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const { Low } = require('lowdb');
const { JSONFile } = require('lowdb/node');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

app.use(cors());
app.use(express.json());

// ========== قاعدة البيانات ==========
const adapter = new JSONFile('db.json');
const db = new Low(adapter, { users: [], trips: [] });

async function initDB() {
  await db.read();
  db.data ||= { users: [], trips: [] };
  await db.write();
  console.log('قاعدة البيانات جاهزة ✅');
}

initDB();

// ========== API التسجيل ==========
app.post('/register', async (req, res) => {
  const { name, phone, password, type } = req.body;
  await db.read();
  const exists = db.data.users.find(u => u.phone === phone);
  if (exists) return res.status(400).json({ message: 'الرقم ده موجود بالفعل' });
  const user = { id: Date.now(), name, phone, password, type };
  db.data.users.push(user);
  await db.write();
  res.json({ message: 'تم التسجيل بنجاح', user });
});

// ========== API الدخول ==========
app.post('/login', async (req, res) => {
  await db.read();
  const user = db.data.users.find(u => u.phone === req.body.phone && u.password === req.body.password);
  if (!user) return res.status(400).json({ message: 'رقم التليفون أو كلمة السر غلط' });
  res.json({ message: 'تم الدخول', user });
});

// ========== Socket.io ==========
const drivers = {};
const riders = {};

io.on('connection', (socket) => {
  console.log('اتصل مستخدم:', socket.id);

  socket.on('driver_online', (data) => {
    drivers[socket.id] = { ...data, socketId: socket.id };
    console.log('سائق اتصل:', data.name);
  });

  socket.on('request_trip', (data) => {
    riders[socket.id] = { ...data, socketId: socket.id };
    Object.values(drivers).forEach(driver => {
      io.to(driver.socketId).emit('new_trip_request', {
        ...data,
        riderSocketId: socket.id,
      });
    });
  });

  socket.on('accept_trip', (data) => {
    io.to(data.riderSocketId).emit('trip_accepted', {
      driverName: data.driverName,
      message: 'السائق قبل طلبك وفي الطريق!',
    });
  });

  socket.on('reject_trip', (data) => {
    io.to(data.riderSocketId).emit('trip_rejected', {
      message: 'السائق رفض الطلب',
    });
  });

  socket.on('trip_done', (data) => {
    io.to(data.riderSocketId).emit('trip_finished', {
      message: 'وصلت بالسلامة!',
    });
  });

  socket.on('disconnect', () => {
    delete drivers[socket.id];
    delete riders[socket.id];
    console.log('انقطع مستخدم:', socket.id);
  });
});

// ========== تشغيل السيرفر ==========
server.listen(3000, () => {
  console.log('السيرفر شغال على البورت 3000 🚀');
});