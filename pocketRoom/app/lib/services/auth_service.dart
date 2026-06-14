// 인증 서비스 — 회원가입 / 로그인 / 자동로그인 / 로그아웃을 담당합니다.
//
// 📡 provider 개념 설명 (입문용):
//   AuthService 는 ChangeNotifier 를 상속합니다.
//   ChangeNotifier 는 "방송국" 같은 존재예요. 로그인 상태(_currentUser)가 바뀌면
//   notifyListeners() 로 "상태가 바뀌었다!"고 방송합니다.
//   화면(LoginScreen, AuthGate 등)은 이 방송을 '구독'하고 있다가
//   방송이 오면 스스로 다시 그려집니다(rebuild).
//
// 🔄 세션 C-A 변경(작업 #10):
//   "겉(메서드 이름·반환형)은 그대로, 속(구현)만 서버 호출로 교체"했습니다.
//   그래서 화면(LoginScreen/SignupScreen/AuthGate) 코드는 한 줄도 바꾸지 않습니다.
//   - 예전: 비밀번호를 로컬에서 SHA-256 해시해 SQLite 와 비교 → 로컬 인증
//   - 지금: 서버(/auth/*)에 위임 → 서버가 bcrypt 로 검증하고 JWT 토큰을 발급
//   - 자동로그인: 자체 토큰 대신 서버 refresh 토큰의 유효성으로 판단
//   - SQLite 는 데이터 원본에서 "캐시(LocalCacheService)"로 강등(로그아웃 시 비움)
//
// ⚠️ 클라이언트 AuthService 와 서버 AuthService 는 이름만 같고 다른 클래스입니다.
// Design 2.9(ApiClient)·3.7(로그인/JWT 인증)을 따릅니다.

import 'package:flutter/foundation.dart'; // ChangeNotifier, debugPrint

import '../models/user.dart';
import 'api_client.dart';
import 'secure_storage.dart';
import 'local_cache_service.dart';

class AuthService extends ChangeNotifier {
  final ApiClient _api;
  final SecureStorageService _secure;
  final LocalCacheService _cache;

  // 생성자: 기본적으로 실제 서비스를 쓰지만, 테스트 시 다른 구현을 끼워 넣을 수 있게 했습니다.
  AuthService({
    ApiClient? api,
    SecureStorageService? secure,
    LocalCacheService? cache,
  })  : _api = api ?? ApiClient(),
        _secure = secure ?? SecureStorageService(),
        _cache = cache ?? LocalCacheService();

  // 현재 로그인된 사용자. null 이면 로그아웃 상태입니다.
  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // 로그인 아이디만으로 최소 User 객체를 만듭니다.
  //   비밀번호 해시는 이제 서버만 보관하므로 클라이언트엔 없습니다(빈 값).
  //   이메일/가입일도 로그인 응답엔 없으므로, 필요해지면 별도 조회로 채웁니다(C-B).
  User _userFromId(String id) => User(
        id: id,
        passwordHash: '', // 서버 보관, 클라이언트는 갖지 않음
        email: '',
        createdAt: DateTime.now(),
      );

  // ── 아이디 중복 확인 (UC #1) ─────────────────────────────────
  // 서버에 전용 중복확인 엔드포인트가 아직 없어, 가입 전에 미리 확인하지는 못합니다.
  // 실제 중복 여부는 회원가입 시 서버가 409 로 알려주고, signUp() 이 false 를 반환합니다.
  // (UI 흐름 유지를 위해 여기서는 "사용 가능"으로 통과시킵니다.)
  // TODO: 서버에 GET /auth/check-id 같은 엔드포인트가 생기면 여기서 호출.
  Future<bool> checkDuplicateId(String id) async {
    return false; // false = 중복 아님(사용 가능)
  }

  // ── 회원가입 (UC #1) ─────────────────────────────────────────
  // 성공하면 true, 아이디가 이미 있으면(409) false.
  Future<bool> signUp({
    required String id,
    required String password,
    required String email,
  }) async {
    try {
      await _api.signup(id: id, password: password, email: email);
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 409) return false; // 아이디 중복
      // 그 외(네트워크 실패 등)도 화면 시그니처상 false 로 알리되, 로그를 남깁니다.
      debugPrint('[AuthService] 회원가입 실패: $e');
      return false;
    }
  }

  // ── 로그인 (UC #2) ───────────────────────────────────────────
  // autoLogin 이 true 면, 다음 앱 실행 때 자동로그인되도록 토큰을 보관합니다.
  Future<bool> login({
    required String id,
    required String password,
    bool autoLogin = false,
  }) async {
    try {
      final tokens = await _api.login(id: id, password: password);
      final access = tokens['accessToken'] as String?;
      final refresh = tokens['refreshToken'] as String?;
      if (access == null || refresh == null) {
        debugPrint('[AuthService] 로그인 응답에 토큰이 없습니다: $tokens');
        return false;
      }

      // 토큰을 보안 저장소(Keychain/Keystore)에 저장합니다.
      // ⚠️ 토큰은 일반 DB(SQLite)가 아니라 secure_storage 에만 저장합니다 (Design 4.4).
      await _secure.saveTokens(
        accessToken: access,
        refreshToken: refresh,
        userId: id,
        autoLogin: autoLogin,
      );

      _currentUser = _userFromId(id);
      notifyListeners(); // "로그인됨!" 방송 → AuthGate 가 대시보드로 전환
      return true;
    } on ApiException catch (e) {
      // 아이디/비밀번호 불일치(401)·네트워크 실패 등 → 로그인 실패로 통일.
      debugPrint('[AuthService] 로그인 실패: $e');
      return false;
    }
  }

  // ── 자동로그인 확인 (앱 시작 시, Sequence 3.1 첫 단계) ────────
  // 자동로그인이 켜져 있고, 보관된 refresh 토큰으로 새 access 발급이 되면 유효한 세션으로 봅니다.
  Future<bool> checkAutoLogin() async {
    // 자동로그인을 끈 상태면 이전 세션 토큰을 정리하고 종료.
    if (!await _secure.isAutoLoginEnabled()) {
      await _secure.clearTokens();
      return false;
    }

    final userId = await _secure.getAuthUserId();
    if (userId == null) return false;

    // refresh 토큰이 유효하면 새 access 가 발급됩니다(만료·위조면 false).
    final refreshed = await _api.refreshAccessToken();
    if (!refreshed) {
      await _secure.clearTokens(); // 만료/위조 토큰 정리
      return false;
    }

    _currentUser = _userFromId(userId);
    notifyListeners();
    return true;
  }

  // ── 로그아웃 ─────────────────────────────────────────────────
  Future<void> logout() async {
    _currentUser = null;
    await _secure.clearTokens(); // 토큰 일체 삭제
    await _cache.clear(); // 로컬 캐시(방·카드·요금)도 비움
    notifyListeners(); // "로그아웃됨!" 방송 → AuthGate 가 로그인 화면으로 전환
  }
}
