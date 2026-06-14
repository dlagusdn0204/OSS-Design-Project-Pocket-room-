// schema.sql 을 읽어 DB 에 적용하는 1회성 스크립트.
// 실행: `npm run db:init`  (이미 Render DB 에 붙는 .env 가 있어야 함)
// IF NOT EXISTS 기반이라 여러 번 돌려도 안전합니다.

require('dotenv').config();

const fs = require('fs');
const path = require('path');
const { pool } = require('./pool');

async function main() {
  const schemaPath = path.join(__dirname, 'schema.sql');
  const sql = fs.readFileSync(schemaPath, 'utf-8');

  console.log('[db:init] schema.sql 적용 시작...');
  await pool.query(sql);
  console.log('[db:init] ✅ 스키마 적용 완료 (users / rooms / cards / bill_records)');

  await pool.end();
}

main().catch((err) => {
  console.error('[db:init] ❌ 실패:', err.message);
  process.exit(1);
});
