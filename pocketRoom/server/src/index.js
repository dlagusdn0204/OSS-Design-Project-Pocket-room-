// 서버 진입점 — .env 를 읽고 Express 앱을 지정 포트로 띄웁니다.
// 실행: `npm run dev` (코드 저장 시 자동 재시작) 또는 `npm start`

require('dotenv').config(); // 가장 먼저: 이후 모든 모듈이 process.env 를 쓸 수 있게

const app = require('./app');

// Render 는 PORT 를 환경변수로 자동 주입합니다. 로컬은 .env 의 PORT(기본 3000).
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`[server] Pocket Room 서버 실행 중 → http://localhost:${PORT}`);
  console.log(`[server] 헬스체크: GET /health , DB확인: GET /health/db`);
});
