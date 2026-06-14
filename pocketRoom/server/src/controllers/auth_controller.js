// AuthController — HTTP 요청/응답을 다루고, 실제 판단은 AuthService 에 위임합니다.
// 컨트롤러의 일: req.body 에서 값 꺼내기 → 서비스 호출 → 상태코드와 JSON 으로 응답.
// (서비스가 던진 HttpError 의 status 를 그대로 HTTP 상태로 변환)

const authService = require('../services/auth_service');

// 서비스 호출을 감싸 에러를 status 로 변환하는 작은 도우미.
//   HttpError 면 그 status, 아니면 500(예상 못 한 서버 오류)으로 응답.
function handleError(res, err) {
  const status = err.status || 500;
  if (status === 500) {
    console.error('[auth] 예기치 못한 오류:', err);
  }
  res.status(status).json({ ok: false, error: err.message });
}

// POST /auth/signup  — { id, password, email } → 201 { ok, user }
async function signup(req, res) {
  try {
    const { id, password, email } = req.body || {};
    const user = await authService.signup({ id, password, email });
    res.status(201).json({ ok: true, user });
  } catch (err) {
    handleError(res, err);
  }
}

// POST /auth/login  — { id, password } → 200 { ok, accessToken, refreshToken }
async function login(req, res) {
  try {
    const { id, password } = req.body || {};
    const tokens = await authService.login({ id, password });
    res.json({ ok: true, ...tokens });
  } catch (err) {
    handleError(res, err);
  }
}

// POST /auth/refresh  — { refreshToken } → 200 { ok, accessToken }
async function refresh(req, res) {
  try {
    const { refreshToken } = req.body || {};
    const result = await authService.refresh({ refreshToken });
    res.json({ ok: true, ...result });
  } catch (err) {
    handleError(res, err);
  }
}

module.exports = { signup, login, refresh };
