// User Repository — users 테이블의 입출고(SQL)만 담당합니다.
// "로그인 성공/실패" 같은 판단은 여기 두지 않습니다. 그건 다음 단계 Service 의 몫.
// ⚠️ 값은 항상 파라미터 바인딩($1, $2 …)으로 넘깁니다 (SQL 인젝션 방지).

const { query } = require('../db/pool');

// 사용자 1명 추가.
//   user: { id, passwordHash, email }
//   반환: 방금 저장된 행(비밀번호 해시 제외) — 호출부가 바로 응답에 쓰기 좋게.
async function insert({ id, passwordHash, email }) {
  const sql = `
    INSERT INTO users (id, password_hash, email)
    VALUES ($1, $2, $3)
    RETURNING id, email, created_at
  `;
  const result = await query(sql, [id, passwordHash, email]);
  return result.rows[0];
}

// 아이디로 사용자 1명 조회.
//   반환: 행(password_hash 포함 — 로그인 검증에 필요) 또는 없으면 null.
async function findById(id) {
  const sql = `
    SELECT id, password_hash, email, created_at
    FROM users
    WHERE id = $1
  `;
  const result = await query(sql, [id]);
  return result.rows[0] || null;
}

// 아이디 중복 확인용 — 존재하면 true.
//   회원가입 전에 "이미 쓰는 아이디인지" 빠르게 보는 용도(전체 행을 안 불러옴).
async function exists(id) {
  const sql = `SELECT 1 FROM users WHERE id = $1`;
  const result = await query(sql, [id]);
  return result.rowCount > 0;
}

module.exports = { insert, findById, exists };
