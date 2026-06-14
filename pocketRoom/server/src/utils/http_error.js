// HttpError — 서비스 계층에서 "이건 400/401/409 상황"이라고 표시해 던지는 작은 도우미.
// 컨트롤러가 err.status 를 보고 알맞은 HTTP 상태로 응답합니다.
// (공통 에러 미들웨어는 작업 #8 에서 정리 예정 — 지금은 각 컨트롤러가 직접 잡습니다.)

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.name = 'HttpError';
    this.status = status; // 예: 400(잘못된 요청), 401(인증 실패), 409(중복)
  }
}

// 자주 쓰는 상태코드는 함수로 만들어 두면 호출부가 읽기 쉽습니다.
const badRequest = (msg) => new HttpError(400, msg); // 필수값 누락 등
const unauthorized = (msg) => new HttpError(401, msg); // 로그인 실패·토큰 문제
const notFound = (msg) => new HttpError(404, msg); // 자원 없음
const conflict = (msg) => new HttpError(409, msg); // 아이디 중복 등

module.exports = { HttpError, badRequest, unauthorized, notFound, conflict };
