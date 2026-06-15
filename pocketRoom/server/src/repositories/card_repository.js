
const { query } = require('../db/pool');

async function upsertCard(roomId, type, data) {
  const sql = `
    INSERT INTO cards (room_id, type, data, updated_at)
    VALUES ($1, $2, $3::jsonb, now())
    ON CONFLICT (room_id, type)
    DO UPDATE SET data = EXCLUDED.data, updated_at = now()
    RETURNING id, room_id, type, data, updated_at
  `;
  const result = await query(sql, [roomId, type, JSON.stringify(data ?? {})]);
  return result.rows[0];
}

async function findByRoom(roomId) {
  const sql = `
    SELECT id, room_id, type, data, updated_at
    FROM cards
    WHERE room_id = $1
    ORDER BY type ASC
  `;
  const result = await query(sql, [roomId]);
  return result.rows;
}

async function insertBillRecord({
  cardId,
  year,
  month,
  amountWon,
  usageKwh = null,
  usageM3 = null,
}) {
  const sql = `
    INSERT INTO bill_records (card_id, year, month, amount_won, usage_kwh, usage_m3)
    VALUES ($1, $2, $3, $4, $5, $6)
    ON CONFLICT (card_id, year, month)
    DO UPDATE SET
      amount_won = EXCLUDED.amount_won,
      usage_kwh  = EXCLUDED.usage_kwh,
      usage_m3   = EXCLUDED.usage_m3,
      fetched_at = now()
    RETURNING id, card_id, year, month, amount_won, usage_kwh, usage_m3, fetched_at
  `;
  const result = await query(sql, [cardId, year, month, amountWon, usageKwh, usageM3]);
  return result.rows[0];
}

async function getBillRecords(cardId) {
  const sql = `
    SELECT id, card_id, year, month, amount_won, usage_kwh, usage_m3, fetched_at
    FROM bill_records
    WHERE card_id = $1
    ORDER BY year ASC, month ASC
  `;
  const result = await query(sql, [cardId]);
  return result.rows;
}

async function clearBillRecords(cardId) {
  await query('DELETE FROM bill_records WHERE card_id = $1', [cardId]);
}

module.exports = {
  upsertCard,
  findByRoom,
  insertBillRecord,
  getBillRecords,
  clearBillRecords,
};
