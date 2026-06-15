
require('dotenv').config();

const app = require('./app');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`[server] Pocket Room 서버 실행 중 → http://localhost:${PORT}`);
  console.log(`[server] 헬스체크: GET /health , DB확인: GET /health/db`);
});
