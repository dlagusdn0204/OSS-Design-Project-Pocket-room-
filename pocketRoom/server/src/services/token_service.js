
const jwt = require('jsonwebtoken');

const ACCESS_SECRET = process.env.JWT_ACCESS_SECRET;
const REFRESH_SECRET = process.env.JWT_REFRESH_SECRET;

const ACCESS_EXPIRES = process.env.JWT_ACCESS_EXPIRES || '15m';
const REFRESH_EXPIRES = process.env.JWT_REFRESH_EXPIRES || '14d';

if (!ACCESS_SECRET || !REFRESH_SECRET) {
  console.error(
    '[Token] JWT_ACCESS_SECRET / JWT_REFRESH_SECRET 이 설정되지 않았습니다. .env 를 확인하세요.'
  );
}

function issue(userId) {
  const accessToken = jwt.sign({ sub: userId, type: 'access' }, ACCESS_SECRET, {
    expiresIn: ACCESS_EXPIRES,
  });
  const refreshToken = jwt.sign({ sub: userId, type: 'refresh' }, REFRESH_SECRET, {
    expiresIn: REFRESH_EXPIRES,
  });
  return { accessToken, refreshToken };
}

function verifyAccess(token) {
  const payload = jwt.verify(token, ACCESS_SECRET);
  if (payload.type !== 'access') {
    throw new Error('access 토큰이 아닙니다');
  }
  return payload;
}

function verifyRefresh(token) {
  const payload = jwt.verify(token, REFRESH_SECRET);
  if (payload.type !== 'refresh') {
    throw new Error('refresh 토큰이 아닙니다');
  }
  return payload;
}

module.exports = { issue, verifyAccess, verifyRefresh };
