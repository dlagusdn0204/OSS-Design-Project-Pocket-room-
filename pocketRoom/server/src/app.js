
const express = require('express');
const cors = require('cors');
const { pool } = require('./db/pool');
const authRouter = require('./routes/auth_router');
const roomRouter = require('./routes/room_router');
const billRouter = require('./routes/bill_router');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ ok: true });
});

app.get('/health/db', async (req, res) => {
  try {
    const result = await pool.query('SELECT 1 AS ok');
    res.json({ ok: true, db: result.rows[0].ok === 1 });
  } catch (err) {
    console.error('[health/db] DB 연결 실패:', err.message);
    res.status(503).json({ ok: false, error: 'DB 연결 실패' });
  }
});

app.use('/auth', authRouter);
app.use('/rooms', roomRouter);
app.use('/rooms', billRouter);

app.use((req, res) => {
  res.status(404).json({ ok: false, error: 'Not Found' });
});

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  const status = err.status || 500;
  if (status === 500) {
    console.error('[app] 처리되지 않은 오류:', err);
  }
  res.status(status).json({ ok: false, error: err.message || '서버 오류' });
});

module.exports = app;
