
const tokenService = require('../services/token_service');

function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res
      .status(401)
      .json({ ok: false, error: '인증 토큰이 필요합니다 (Authorization: Bearer ...)' });
  }

  try {
    const payload = tokenService.verifyAccess(token);
    req.userId = payload.sub;
    next();
  } catch (err) {
    return res.status(401).json({ ok: false, error: '유효하지 않거나 만료된 토큰입니다' });
  }
}

module.exports = { requireAuth };
