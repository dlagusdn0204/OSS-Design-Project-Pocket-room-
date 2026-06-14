// TokenService — JWT(access/refresh) 토큰을 발급·검증합니다.
// 비유: access 토큰 = 놀이공원 손목밴드(자주 확인, 짧게 유효),
//       refresh 토큰 = 재입장 영수증(밴드 잃으면 이걸로 재발급, 길게 유효).
//
// 🔒 시크릿(JWT_ACCESS_SECRET / JWT_REFRESH_SECRET)은 .env 에만 둡니다.
//    access 와 refresh 의 시크릿을 따로 둬서, access 시크릿이 새도 refresh 는 안전.

const jwt = require('jsonwebtoken');

const ACCESS_SECRET = process.env.JWT_ACCESS_SECRET;
const REFRESH_SECRET = process.env.JWT_REFRESH_SECRET;

// 만료 시간은 .env 로 덮어쓸 수 있고, 없으면 기본값(access 15분 / refresh 14일).
const ACCESS_EXPIRES = process.env.JWT_ACCESS_EXPIRES || '15m';
const REFRESH_EXPIRES = process.env.JWT_REFRESH_EXPIRES || '14d';

// 서버 시작 시 시크릿이 비어 있으면 바로 경고 (토큰 발급이 불가능한 상태).
if (!ACCESS_SECRET || !REFRESH_SECRET) {
  console.error(
    '[Token] JWT_ACCESS_SECRET / JWT_REFRESH_SECRET 이 설정되지 않았습니다. .env 를 확인하세요.'
  );
}

// access + refresh 토큰을 한 쌍으로 발급.
//   payload 에는 최소한의 정보(userId)만 담습니다(토큰은 누구나 디코드 가능하므로 비밀 금지).
//   type 클레임으로 access/refresh 를 구분해, 서로 다른 용도로 못 쓰게 막습니다.
function issue(userId) {
  const accessToken = jwt.sign({ sub: userId, type: 'access' }, ACCESS_SECRET, {
    expiresIn: ACCESS_EXPIRES,
  });
  const refreshToken = jwt.sign({ sub: userId, type: 'refresh' }, REFRESH_SECRET, {
    expiresIn: REFRESH_EXPIRES,
  });
  return { accessToken, refreshToken };
}

// access 토큰 검증 → 통과하면 payload 반환, 위조·만료면 예외를 던집니다.
//   type 이 'access' 가 아니면(예: refresh 를 access 자리에 넣음) 거부.
function verifyAccess(token) {
  const payload = jwt.verify(token, ACCESS_SECRET);
  if (payload.type !== 'access') {
    throw new Error('access 토큰이 아닙니다');
  }
  return payload;
}

// refresh 토큰 검증 → 통과하면 payload 반환, 아니면 예외.
//   재발급(POST /auth/refresh)에서 사용합니다.
function verifyRefresh(token) {
  const payload = jwt.verify(token, REFRESH_SECRET);
  if (payload.type !== 'refresh') {
    throw new Error('refresh 토큰이 아닙니다');
  }
  return payload;
}

module.exports = { issue, verifyAccess, verifyRefresh };
