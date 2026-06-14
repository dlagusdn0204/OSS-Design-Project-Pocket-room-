// Card Repository — cards / bill_records 테이블의 입출고(SQL)만 담당합니다.
// 카드의 가변 필드는 JSONB(data)로 단순화돼 있어, 여기서는 통째로 넣고 뺍니다.

const { query } = require('../db/pool');

// 카드 1장 저장(없으면 추가, 있으면 갱신).
//   방 하나당 같은 type 카드는 1장뿐(UNIQUE(room_id, type)) → 그 키로 upsert.
//   data 는 JS 객체를 그대로 넘기면 pg 가 JSONB 로 변환합니다.
//   반환: 저장된 카드 행.
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

// 한 방의 카드 전체(보통 contract/electricity/cityGas 3장).
//   반환: 카드 행 배열(없으면 빈 배열).
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

// 월별 요금 이력 1건 저장(같은 카드의 같은 연·월이면 덮어쓰기).
//   record: { cardId, year, month, amountWon, usageKwh?, usageM3? }
//   전기는 usageKwh, 가스는 usageM3 만 채우고 나머지는 null 로 둡니다.
//   반환: 저장된 이력 행.
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

// 한 카드의 요금 이력(연·월 오름차순) — 추이 그래프용.
//   반환: 이력 행 배열(없으면 빈 배열).
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

module.exports = { upsertCard, findByRoom, insertBillRecord, getBillRecords };
