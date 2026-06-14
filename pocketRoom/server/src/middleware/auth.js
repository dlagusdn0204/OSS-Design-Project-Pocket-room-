// 인증 미들웨어 — 보호된 라우트 앞단에서 access 토큰을 거릅니다.
// 통과하면 req.userId 를 채워주고, 실패하면 401 로 막습니다.
// 사용 예(작업 #6~): router.get('/rooms', requireAuth, roomController.list)

const tokenService = require('../services/token_service');

function requireAuth(req, res, next) {
  // 헤더 형식: "Authorization: Bearer <token>"
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res
      .status(401)
      .json({ ok: false, error: '인증 토큰이 필요합니다 (Authorization: Bearer ...)' });
  }

  try {
    const payload = tokenService.verifyAccess(token);
    // 이후 컨트롤러/서비스는 req.userId 로 "누가 요청했는지" 알 수 있습니다.
    // ⚠️ ownerId 는 항상 이 값에서 꺼냅니다(요청 본문으로 받지 않음 → 남의 자원 조작 방지).
    req.userId = payload.sub;
    next();
  } catch (err) {
    // 위조·만료·형식 오류 모두 여기로 → 401 로 통일.
    return res.status(401).json({ ok: false, error: '유효하지 않거나 만료된 토큰입니다' });
  }
}

module.exports = { requireAuth };
