// Express 앱 구성 — 미들웨어 + 라우트를 한 곳에서 등록합니다.
// (서버를 "켜는" 일은 index.js 가 담당, 여기서는 "무엇을 처리할지"만 정의)

const express = require('express');
const cors = require('cors');
const { pool } = require('./db/pool');
const authRouter = require('./routes/auth_router');
const roomRouter = require('./routes/room_router');
const billRouter = require('./routes/bill_router');

const app = express();

// ── 공통 미들웨어 ──────────────────────────────────────────────
// CORS: Flutter Web 은 다른 포트(예: localhost:xxxxx)에서 호출하므로 허용 필요.
app.use(cors());
// JSON 본문 파싱: req.body 를 객체로 쓸 수 있게 함.
app.use(express.json());

// ── 헬스체크 라우트 ────────────────────────────────────────────
// 1) 서버가 살아있는지 (DB 무관)
app.get('/health', (req, res) => {
  res.json({ ok: true });
});

// 2) DB 까지 연결되는지 — 가장 가벼운 쿼리(SELECT 1)로 확인
app.get('/health/db', async (req, res) => {
  try {
    const result = await pool.query('SELECT 1 AS ok');
    res.json({ ok: true, db: result.rows[0].ok === 1 });
  } catch (err) {
    console.error('[health/db] DB 연결 실패:', err.message);
    res.status(503).json({ ok: false, error: 'DB 연결 실패' });
  }
});

// ── 기능 라우트 등록 ──────────────────────────────────────────
app.use('/auth', authRouter); // 작업 #5: 가입·로그인·재발급 (인증 불필요)
app.use('/rooms', roomRouter); // 작업 #6: 방 목록·생성 (requireAuth 적용)
app.use('/rooms', billRouter); // 작업 #7: 카드 조회·계약 저장·전기요금 갱신 (requireAuth 적용)

// ── 404 핸들러 ────────────────────────────────────────────────
// 위 라우트 어디에도 안 걸린 경로 → JSON 404.
app.use((req, res) => {
  res.status(404).json({ ok: false, error: 'Not Found' });
});

// ── 공통 에러 핸들러 (작업 #8) ─────────────────────────────────
// 컨트롤러들은 각자 try/catch 로 처리하지만, 그 그물을 빠져나온
// 예기치 못한 에러(미들웨어/동기 throw 등)를 여기서 마지막으로 받아 JSON 으로 응답합니다.
// ⚠️ Express 는 인자 4개(err, req, res, next)인 함수를 "에러 핸들러"로 인식합니다.
//    next 를 안 써도 4개를 유지해야 합니다.
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  const status = err.status || 500;
  if (status === 500) {
    console.error('[app] 처리되지 않은 오류:', err);
  }
  res.status(status).json({ ok: false, error: err.message || '서버 오류' });
});

module.exports = app;
