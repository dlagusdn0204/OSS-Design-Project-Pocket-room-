
const { query } = require('../db/pool');

async function insert({ id, passwordHash, email }) {
  const sql = `
    INSERT INTO users (id, password_hash, email)
    VALUES ($1, $2, $3)
    RETURNING id, email, created_at
  `;
  const result = await query(sql, [id, passwordHash, email]);
  return result.rows[0];
}

async function findById(id) {
  const sql = `
    SELECT id, password_hash, email, created_at
    FROM users
    WHERE id = $1
  `;
  const result = await query(sql, [id]);
  return result.rows[0] || null;
}

async function exists(id) {
  const sql = `SELECT 1 FROM users WHERE id = $1`;
  const result = await query(sql, [id]);
  return result.rowCount > 0;
}

async function findByEmail(email) {
  const sql = `
    SELECT id, email, created_at
    FROM users
    WHERE email = $1
  `;
  const result = await query(sql, [email]);
  return result.rows[0] || null;
}

async function updatePassword(id, passwordHash) {
  const sql = `UPDATE users SET password_hash = $2 WHERE id = $1`;
  const result = await query(sql, [id, passwordHash]);
  return result.rowCount;
}

module.exports = { insert, findById, exists, findByEmail, updatePassword };
