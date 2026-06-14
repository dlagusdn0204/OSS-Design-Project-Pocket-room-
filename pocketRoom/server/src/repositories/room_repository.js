// Room Repository — rooms 테이블의 입출고(SQL)만 담당합니다.
// "빈 카드 3종도 같이 만들기" 같은 흐름은 Service(작업 #6)에서 조합합니다.

const { query } = require('../db/pool');

// 방 1개 추가.
//   id 는 스키마 기본값(gen_random_uuid)으로 자동 생성되므로 owner_id, name 만 받습니다.
//   반환: 생성된 방 행.
async function insert(ownerId, name) {
  const sql = `
    INSERT INTO rooms (owner_id, name)
    VALUES ($1, $2)
    RETURNING id, owner_id, name, created_at
  `;
  const result = await query(sql, [ownerId, name]);
  return result.rows[0];
}

// 특정 사용자가 가진 방 목록(오래된 순).
//   반환: 방 행 배열(없으면 빈 배열).
async function findByOwner(ownerId) {
  const sql = `
    SELECT id, owner_id, name, created_at
    FROM rooms
    WHERE owner_id = $1
    ORDER BY created_at ASC
  `;
  const result = await query(sql, [ownerId]);
  return result.rows;
}

// 방 1개 조회(방 id 기준).
//   소유권 확인(이 방이 내 방인지)에 사용 → owner_id 를 함께 반환합니다.
//   반환: 방 행 1개, 없으면 null.
async function findById(roomId) {
  const sql = `
    SELECT id, owner_id, name, created_at
    FROM rooms
    WHERE id = $1
  `;
  const result = await query(sql, [roomId]);
  return result.rows[0] || null;
}

module.exports = { insert, findByOwner, findById };
