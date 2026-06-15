
const authService = require('../services/auth_service');

function handleError(res, err) {
  const status = err.status || 500;
  if (status === 500) {
    console.error('[auth] 예기치 못한 오류:', err);
  }
  res.status(status).json({ ok: false, error: err.message });
}

async function signup(req, res) {
  try {
    const { id, password, email } = req.body || {};
    const user = await authService.signup({ id, password, email });
    res.status(201).json({ ok: true, user });
  } catch (err) {
    handleError(res, err);
  }
}

async function checkId(req, res) {
  try {
    const { id } = req.query || {};
    const result = await authService.checkId({ id });
    res.json({ ok: true, ...result });
  } catch (err) {
    handleError(res, err);
  }
}

async function login(req, res) {
  try {
    const { id, password } = req.body || {};
    const tokens = await authService.login({ id, password });
    res.json({ ok: true, ...tokens });
  } catch (err) {
    handleError(res, err);
  }
}

async function refresh(req, res) {
  try {
    const { refreshToken } = req.body || {};
    const result = await authService.refresh({ refreshToken });
    res.json({ ok: true, ...result });
  } catch (err) {
    handleError(res, err);
  }
}

async function findId(req, res) {
  try {
    const { email } = req.body || {};
    const result = await authService.findId({ email });
    res.json({ ok: true, ...result });
  } catch (err) {
    handleError(res, err);
  }
}

async function resetPassword(req, res) {
  try {
    const { id, email, newPassword } = req.body || {};
    const result = await authService.resetPassword({ id, email, newPassword });
    res.json({ ok: true, ...result });
  } catch (err) {
    handleError(res, err);
  }
}

module.exports = { signup, checkId, login, refresh, findId, resetPassword };
