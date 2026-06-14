// BillController — 카드/요금 관련 HTTP 요청/응답을 다룹니다. 판단은 BillService 에 위임.
// ⚠️ ownerId 는 항상 req.userId(토큰에서 온 값), roomId 는 URL 파라미터(req.params.id).
//    소유권 확인은 Service 가 수행합니다(내 방이 아니면 404).

const billService = require('../services/bill_service');

function handleError(res, err) {
  const status = err.status || 500;
  if (status === 500) {
    console.error('[bill] 예기치 못한 오류:', err);
  }
  res.status(status).json({ ok: false, error: err.message });
}

// GET /rooms/:id/cards  → 200 { ok, cards: [ ...3종(+history) ] }
async function getCards(req, res) {
  try {
    const cards = await billService.getCards(req.userId, req.params.id);
    res.json({ ok: true, cards });
  } catch (err) {
    handleError(res, err);
  }
}

// PUT /rooms/:id/cards/contract  — { rentWon, accountNumber, address, paymentDueDay }
//   → 200 { ok, card }
async function saveContract(req, res) {
  try {
    const card = await billService.saveContract(req.userId, req.params.id, req.body || {});
    res.json({ ok: true, card });
  } catch (err) {
    handleError(res, err);
  }
}

// POST /rooms/:id/cards/electricity/refresh  — body: 예시 OPM 응답(JSON)
//   → 200 { ok, card, saved, history }
async function refreshElectricity(req, res) {
  try {
    const result = await billService.refreshElectricity(
      req.userId,
      req.params.id,
      req.body || {}
    );
    res.json({ ok: true, ...result });
  } catch (err) {
    handleError(res, err);
  }
}

module.exports = { getCards, saveContract, refreshElectricity };
