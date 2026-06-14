// 앱 전역 설정 — 서버 주소(baseUrl)를 한 곳에 모아둡니다.
//
// 왜 한 곳에 모으나요?
//   로컬에서 개발할 때(localhost)와 배포 서버(Render)를 오갈 때, 주소가 코드 곳곳에
//   흩어져 있으면 바꾸기 번거롭습니다. 여기 한 줄만 바꾸면 앱 전체가 따라갑니다.
//
// 전환 방법(둘 중 하나):
//   1) 아래 defaultValue 를 직접 수정
//   2) 실행 시 --dart-define 로 덮어쓰기(코드 수정 없이 전환):
//      flutter run -d chrome --dart-define=SERVER_BASE_URL=https://<배포주소>
//
// ⚠️ 끝에 슬래시(/)를 붙이지 마세요. 경로는 ApiClient 가 '/auth/login' 처럼 이어붙입니다.

class AppConfig {
  // 서버 기본 주소. 기본값은 로컬 개발 서버(pocket_room_server 의 기본 포트 3000).
  static const String serverBaseUrl = String.fromEnvironment(
    'SERVER_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
