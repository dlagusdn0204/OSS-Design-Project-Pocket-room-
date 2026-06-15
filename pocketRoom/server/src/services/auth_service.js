
const bcrypt = require('bcrypt');
const userRepository = require('../repositories/user_repository');
const tokenService = require('./token_service');
const { badRequest, unauthorized, conflict, notFound } = require('../utils/http_error');

const SALT_ROUNDS = 10;

async function hashPassword(plain) {
  return bcrypt.hash(plain, SALT_ROUNDS);
}

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

async function checkId({ id }) {
  if (!id || !id.trim()) {
    throw badRequest('id 는 필수입니다');
  }
  const exists = await userRepository.exists(id.trim());
  return { available: !exists };
}

async function login({ id, password }) {
  if (!id || !password) {
    throw badRequest('id, password 는 필수입니다');
  }
  const user = await userRepository.findById(id);
  if (!user) {
    throw unauthorized('아이디 또는 비밀번호가 올바르지 않습니다');
  }
  const matched = await bcrypt.compare(password, user.password_hash);
  if (!matched) {
    throw unauthorized('아이디 또는 비밀번호가 올바르지 않습니다');
  }
  return tokenService.issue(user.id);
}

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
  const { accessToken } = tokenService.issue(payload.sub);
  return { accessToken };
}

async function findId({ email }) {
  if (!email || !email.trim()) {
    throw badRequest('email 은 필수입니다');
  }
  const user = await userRepository.findByEmail(email.trim());
  if (!user) {
    throw notFound('해당 이메일로 가입된 아이디가 없습니다');
  }
  return { id: user.id };
}

async function resetPassword({ id, email, newPassword }) {
  if (!id || !email || !newPassword) {
    throw badRequest('id, email, newPassword 는 필수입니다');
  }
  const user = await userRepository.findById(id.trim());
  if (!user || user.email !== email.trim()) {
    throw badRequest('아이디와 이메일이 일치하지 않습니다');
  }
  const passwordHash = await hashPassword(newPassword);
  await userRepository.updatePassword(user.id, passwordHash);
  return { ok: true };
}

module.exports = {
  signup,
  checkId,
  login,
  refresh,
  hashPassword,
  findId,
  resetPassword,
};
