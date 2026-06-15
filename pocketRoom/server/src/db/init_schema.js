
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
