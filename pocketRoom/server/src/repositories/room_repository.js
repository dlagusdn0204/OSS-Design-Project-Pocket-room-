
const { query } = require('../db/pool');

async function insert(ownerId, name) {
  const sql = `
    INSERT INTO rooms (owner_id, name)
    VALUES ($1, $2)
    RETURNING id, owner_id, name, created_at
  `;
  const result = await query(sql, [ownerId, name]);
  return result.rows[0];
}

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
