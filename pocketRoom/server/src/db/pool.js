// PostgreSQL 연결 풀 — 서버 전체가 이 pool 하나를 공유합니다.
// "풀(pool)"이란: 매 요청마다 DB 접속을 새로 여는 대신,
//                미리 만들어 둔 연결 여러 개를 돌려쓰는 방식(성능·안정성).

const { Pool } = require('pg');

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  // .env 에 DATABASE_URL 이 없으면 서버가 DB 작업을 할 수 없으므로 바로 알림
  console.error(
    '[DB] DATABASE_URL 이 설정되지 않았습니다. .env 파일을 확인하세요. (.env.example 참고)'
  );
}

// Render 무료 PostgreSQL 은 SSL 연결을 요구합니다.
// 로컬(localhost) DB 로 붙을 때는 SSL 이 없으므로 호스트를 보고 켜고 끕니다.
const isLocal =
  !connectionString ||
  connectionString.includes('localhost') ||
  connectionString.includes('127.0.0.1');

const pool = new Pool({
  connectionString,
  // rejectUnauthorized:false → Render 가 주는 자체 서명 인증서를 허용 (무료 티어 표준 설정)
  ssl: isLocal ? false : { rejectUnauthorized: false },
});

// 연결이 처음 맺어질 때 한 번 로그 (살아있음 확인용)
pool.on('connect', () => {
  console.log('[DB] PostgreSQL 연결 풀에서 클라이언트 연결됨');
});

pool.on('error', (err) => {
  console.error('[DB] 유휴 클라이언트에서 예기치 못한 오류:', err.message);
});

// query 를 한 군데로 모아두면 나중에 로깅·트랜잭션 처리하기 쉽습니다.
async function query(text, params) {
  return pool.query(text, params);
}

module.exports = { pool, query };
