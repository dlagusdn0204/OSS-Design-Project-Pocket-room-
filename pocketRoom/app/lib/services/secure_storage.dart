// 민감정보 보안 저장소 래퍼
// flutter_secure_storage를 감싸서 한전/가스 로그인 정보·자동로그인 토큰을 저장합니다.
// ⚠️ 이 서비스에만 민감정보를 저장하세요. SQLite(storage_service.dart)에는 절대 넣지 마세요.
// ℹ️ 웹(Chrome)에서는 브라우저 localStorage를 사용합니다. 진짜 보안은 iOS/Android 기기에서만 보장됩니다.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    // iOS: Keychain, Android: EncryptedSharedPreferences
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── JWT 토큰 (서버 인증, 세션 C-A~) ──────────────────────────
  // 서버 로그인 성공 시 받는 access/refresh 토큰을 보관합니다.
  //   - access  : API 호출마다 헤더에 붙이는 짧은 수명 토큰(기본 15분)
  //   - refresh : access 가 만료되면 새 access 를 받아오는 긴 수명 토큰(기본 14일)
  //   - userId  : 토큰의 주인(로그인 아이디). 자동로그인 시 화면에 표시할 사용자 식별에 사용.
  //   - autoLogin: 사용자가 "자동 로그인"을 켰는지. 다음 앱 실행 때 자동로그인 여부를 결정.
  // ⚠️ 이전의 자체 자동로그인 토큰(saveAutoLoginToken)은 서버 JWT 로 대체되었습니다.

  static const _accessTokenKey = 'jwt_access_token';
  static const _refreshTokenKey = 'jwt_refresh_token';
  static const _authUserIdKey = 'auth_user_id';
  static const _autoLoginEnabledKey = 'auto_login_enabled';

  // 로그인 직후 토큰 한 쌍 + 사용자 + 자동로그인 여부를 함께 저장합니다.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required bool autoLogin,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _authUserIdKey, value: userId);
    await _storage.write(
        key: _autoLoginEnabledKey, value: autoLogin ? '1' : '0');
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<String?> getAuthUserId() => _storage.read(key: _authUserIdKey);

  Future<bool> isAutoLoginEnabled() async =>
      (await _storage.read(key: _autoLoginEnabledKey)) == '1';

  // access 토큰만 갱신(refresh 로 새 access 를 받았을 때).
  Future<void> updateAccessToken(String accessToken) =>
      _storage.write(key: _accessTokenKey, value: accessToken);

  // 로그아웃·세션 종료 시 토큰 일체를 지웁니다.
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _authUserIdKey);
    await _storage.delete(key: _autoLoginEnabledKey);
  }

  // ── 한전 로그인 정보 ─────────────────────────────────────────
  // secureKeyPrefix: 카드별 고유 접두사 (예: "elec_card123")
  // TODO: OPM 연동 시 loginId/loginPassword 대신 OPM 토큰으로 교체

  Future<void> saveElectricityCredentials({
    required String prefix,
    required String loginId,
    required String loginPassword,
  }) async {
    await _storage.write(key: '${prefix}_id', value: loginId);
    await _storage.write(key: '${prefix}_pw', value: loginPassword);
  }

  Future<String?> getElectricityLoginId(String prefix) =>
      _storage.read(key: '${prefix}_id');

  Future<String?> getElectricityLoginPassword(String prefix) =>
      _storage.read(key: '${prefix}_pw');

  Future<void> deleteElectricityCredentials(String prefix) async {
    await _storage.delete(key: '${prefix}_id');
    await _storage.delete(key: '${prefix}_pw');
  }

  // ── 도시가스 로그인 정보 ─────────────────────────────────────
  // TODO: 도시가스 회사별 API 연동 시 구현 방식 결정

  Future<void> saveCityGasCredentials({
    required String prefix,
    required String loginId,
    required String loginPassword,
  }) async {
    await _storage.write(key: '${prefix}_id', value: loginId);
    await _storage.write(key: '${prefix}_pw', value: loginPassword);
  }

  Future<String?> getCityGasLoginId(String prefix) =>
      _storage.read(key: '${prefix}_id');

  Future<String?> getCityGasLoginPassword(String prefix) =>
      _storage.read(key: '${prefix}_pw');

  Future<void> deleteCityGasCredentials(String prefix) async {
    await _storage.delete(key: '${prefix}_id');
    await _storage.delete(key: '${prefix}_pw');
  }

  // ── 전체 삭제 (로그아웃 시) ──────────────────────────────────

  Future<void> deleteAll() => _storage.deleteAll();
}
