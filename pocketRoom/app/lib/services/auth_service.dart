
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import 'api_client.dart';
import 'secure_storage.dart';
import 'local_cache_service.dart';

class AuthService extends ChangeNotifier {
  final ApiClient _api;
  final SecureStorageService _secure;
  final LocalCacheService _cache;

  AuthService({
    ApiClient? api,
    SecureStorageService? secure,
    LocalCacheService? cache,
  })  : _api = api ?? ApiClient(),
        _secure = secure ?? SecureStorageService(),
        _cache = cache ?? LocalCacheService();

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  User _userFromId(String id) => User(
        id: id,
        passwordHash: '',
        email: '',
        createdAt: DateTime.now(),
      );

  Future<bool> checkDuplicateId(String id) async {
    final res = await _api.checkId(id);
    return res['available'] == false;
  }

  Future<bool> signUp({
    required String id,
    required String password,
    required String email,
  }) async {
    try {
      await _api.signup(id: id, password: password, email: email);
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 409) return false;
      debugPrint('[AuthService] 회원가입 실패: $e');
      return false;
    }
  }

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

      await _secure.saveTokens(
        accessToken: access,
        refreshToken: refresh,
        userId: id,
        autoLogin: autoLogin,
      );

      _currentUser = _userFromId(id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      debugPrint('[AuthService] 로그인 실패: $e');
      return false;
    }
  }

  Future<bool> checkAutoLogin() async {
    if (!await _secure.isAutoLoginEnabled()) {
      await _secure.clearTokens();
      return false;
    }

    final userId = await _secure.getAuthUserId();
    if (userId == null) return false;

    final refreshed = await _api.refreshAccessToken();
    if (!refreshed) {
      await _secure.clearTokens();
      return false;
    }

    _currentUser = _userFromId(userId);
    notifyListeners();
    return true;
  }

  Future<String> findId(String email) async {
    final res = await _api.findId(email);
    return res['id'] as String;
  }

  Future<void> resetPassword({
    required String id,
    required String email,
    required String newPassword,
  }) async {
    await _api.resetPassword(id: id, email: email, newPassword: newPassword);
  }

  Future<void> logout() async {
    _currentUser = null;
    await _secure.clearTokens();
    await _cache.clear();
    notifyListeners();
  }
}
