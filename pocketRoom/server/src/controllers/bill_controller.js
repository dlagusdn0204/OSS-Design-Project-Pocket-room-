
const billService = require('../services/bill_service');

function handleError(res, err) {
  const status = err.status || 500;
  if (status === 500) {
    console.error('[bill] 예기치 못한 오류:', err);
  }
  res.status(status).json({ ok: false, error: err.message });
}

async function getCards(req, res) {
  try {
    const cards = await billService.getCards(req.userId, req.params.id);
    res.json({ ok: true, cards });
  } catch (err) {
    handleError(res, err);
  }
}

async function saveContract(req, res) {
  try {
    const card = await billService.saveContract(req.userId, req.params.id, req.body || {});
    res.json({ ok: true, card });
  } catch (err) {
    handleError(res, err);
  }
}

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

async function refreshCityGas(req, res) {
  try {
    const result = await billService.refreshCityGas(
      req.userId,
      req.params.id,
      req.body || {}
    );
    res.json({ ok: true, ...result });
  } catch (err) {
    handleError(res, err);
  }
}

module.exports = { getCards, saveContract, refreshElectricity, refreshCityGas };
