
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );


  static const _accessTokenKey = 'jwt_access_token';
  static const _refreshTokenKey = 'jwt_refresh_token';
  static const _authUserIdKey = 'auth_user_id';
  static const _autoLoginEnabledKey = 'auto_login_enabled';

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

  Future<void> updateAccessToken(String accessToken) =>
      _storage.write(key: _accessTokenKey, value: accessToken);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _authUserIdKey);
    await _storage.delete(key: _autoLoginEnabledKey);
  }


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


  Future<void> deleteAll() => _storage.deleteAll();
}
