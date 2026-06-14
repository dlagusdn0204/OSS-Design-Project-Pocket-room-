// AuthService — 회원가입·로그인·토큰 재발급의 "판단(비즈니스 로직)"을 담당합니다.
// Repository(DB 말)와 TokenService(토큰 발급)를 조합해 흐름을 만듭니다.
// Design 3.7(로그인/JWT 인증) 시퀀스를 그대로 구현.
//
// 🔒 비밀번호는 bcrypt 해시로만 저장하고, 검증도 여기(서버)에서 합니다.
//    클라이언트는 평문을 잠깐 들고 전송 후 버립니다(HTTPS 전제).

const bcrypt = require('bcrypt');
const userRepository = require('../repositories/user_repository');
const tokenService = require('./token_service');
const { badRequest, unauthorized, conflict } = require('../utils/http_error');

// bcrypt 의 비용(cost). 높을수록 안전하지만 느려집니다. 10 이 일반적인 기본값.
const SALT_ROUNDS = 10;

// 비밀번호 평문 → bcrypt 해시.
//   bcrypt 는 salt 를 해시 안에 함께 담으므로 별도 salt 컬럼이 필요 없습니다.
async function hashPassword(plain) {
  return bcrypt.hash(plain, SALT_ROUNDS);
}

// 회원가입.
//   입력: { id, password, email }
//   - 아이디가 이미 있으면 409(conflict).
//   - 성공 시 저장된 사용자(해시 제외)를 반환.
async function signup({ id, password, email }) {
  if (!id || !password || !email) {
    throw badRequest('id, password, email 은 필수입니다');
  }
  if (await userRepository.exists(id)) {
    throw conflict('이미 사용 중인 아이디입니다');
  }
  const passwordHash = await hashPassword(password);
  return userRepository.insert({ id, passwordHash, email });
}

// 로그인.
//   입력: { id, password }
//   - 아이디가 없거나 비밀번호가 틀리면 둘 다 401(아이디 존재 여부를 노출하지 않음).
//   - 성공 시 access/refresh 토큰 한 쌍을 반환.
async function login({ id, password }) {
  if (!id || !password) {
    throw badRequest('id, password 는 필수입니다');
  }
  const user = await userRepository.findById(id);
  // 아이디가 없어도, 비밀번호가 틀려도 같은 메시지(401) → 계정 존재 추측 차단.
  if (!user) {
    throw unauthorized('아이디 또는 비밀번호가 올바르지 않습니다');
  }
  const matched = await bcrypt.compare(password, user.password_hash);
  if (!matched) {
    throw unauthorized('아이디 또는 비밀번호가 올바르지 않습니다');
  }
  return tokenService.issue(user.id);
}

// 토큰 재발급.
//   입력: { refreshToken }
//   - refresh 토큰이 유효하면 새 access 토큰만 발급(Design 2.10: 응답 { accessToken }).
//   - 위조·만료면 401.
async function refresh({ refreshToken }) {
  if (!refreshToken) {
    throw badRequest('refreshToken 은 필수입니다');
  }
  let payload;
  try {
    payload = tokenService.verifyRefresh(refreshToken);
  } catch (err) {
    throw unauthorized('유효하지 않거나 만료된 refresh 토큰입니다');
  }
  // issue 는 한 쌍을 만들지만, 재발급에서는 새 access 만 돌려줍니다.
  const { accessToken } = tokenService.issue(payload.sub);
  return { accessToken };
}

module.exports = { signup, login, refresh, hashPassword };
