
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'secure_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  bool get isNetworkError => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final SecureStorageService _secure;
  final http.Client _http;
  final String baseUrl;

  ApiClient({
    SecureStorageService? secure,
    http.Client? httpClient,
    String? baseUrl,
  })  : _secure = secure ?? SecureStorageService(),
        _http = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.serverBaseUrl;

  static const _timeout = Duration(seconds: 20);


  Future<Map<String, dynamic>> login({
    required String id,
    required String password,
  }) {
    return _sendRaw('POST', '/auth/login',
        body: {'id': id, 'password': password}, authenticated: false);
  }

  Future<Map<String, dynamic>> signup({
    required String id,
    required String password,
    required String email,
  }) {
    return _sendRaw('POST', '/auth/signup',
        body: {'id': id, 'password': password, 'email': email},
        authenticated: false);
  }

  Future<Map<String, dynamic>> checkId(String id) {
    final encoded = Uri.encodeQueryComponent(id);
    return _sendRaw('GET', '/auth/check-id?id=$encoded', authenticated: false);
  }

  Future<Map<String, dynamic>> findId(String email) {
    return _sendRaw('POST', '/auth/find-id',
        body: {'email': email}, authenticated: false);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String id,
    required String email,
    required String newPassword,
  }) {
    return _sendRaw('POST', '/auth/reset-password',
        body: {'id': id, 'email': email, 'newPassword': newPassword},
        authenticated: false);
  }

  Future<bool> refreshAccessToken() async {
    final refreshToken = await _secure.getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final data = await _sendRaw('POST', '/auth/refresh',
          body: {'refreshToken': refreshToken}, authenticated: false);
      final newAccess = data['accessToken'] as String?;
      if (newAccess == null) return false;
      await _secure.updateAccessToken(newAccess);
      return true;
    } on ApiException {
      return false;
    }
  }


  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      return await _sendRaw(method, path, body: body, authenticated: true);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          return _sendRaw(method, path, body: body, authenticated: true);
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _sendRaw(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authenticated) {
      final access = await _secure.getAccessToken();
      if (access != null) headers['Authorization'] = 'Bearer $access';
    }

    final encoded = body == null ? null : jsonEncode(body);

    http.Response res;
    try {
      switch (method) {
        case 'GET':
          res = await _http.get(uri, headers: headers).timeout(_timeout);
          break;
        case 'POST':
          res = await _http
              .post(uri, headers: headers, body: encoded)
              .timeout(_timeout);
          break;
        case 'PUT':
          res = await _http
              .put(uri, headers: headers, body: encoded)
              .timeout(_timeout);
          break;
        default:
          throw ApiException(0, '지원하지 않는 메서드: $method');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, '서버에 연결할 수 없습니다. 네트워크나 서버 상태를 확인해주세요.');
    }

    Map<String, dynamic> decoded;
    try {
      decoded = res.body.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    } catch (_) {
      decoded = <String, dynamic>{};
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    final message = (decoded['error'] as String?) ?? 'HTTP ${res.statusCode}';
    throw ApiException(res.statusCode, message);
  }
}
