
const { Pool } = require('pg');

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error(
    '[DB] DATABASE_URL 이 설정되지 않았습니다. .env 파일을 확인하세요. (.env.example 참고)'
  );
}

const isLocal =
  !connectionString ||
  connectionString.includes('localhost') ||
  connectionString.includes('127.0.0.1');

const pool = new Pool({
  connectionString,
  ssl: isLocal ? false : { rejectUnauthorized: false },
});

pool.on('connect', () => {
  console.log('[DB] PostgreSQL 연결 풀에서 클라이언트 연결됨');
});

pool.on('error', (err) => {
  console.error('[DB] 유휴 클라이언트에서 예기치 못한 오류:', err.message);
});

async function query(text, params) {
  return pool.query(text, params);
}

module.exports = { pool, query };
