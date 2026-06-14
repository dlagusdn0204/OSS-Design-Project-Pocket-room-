// ApiClient — 앱과 백엔드 서버(pocket_room_server) 사이의 "주문 창구"입니다.
//
// 하는 일:
//   - 서버에 GET/POST/PUT 요청을 보내고, JSON 응답을 Map 으로 돌려줍니다.
//   - 인증이 필요한 요청에는 자동으로 Authorization: Bearer <access토큰> 헤더를 붙입니다.
//   - access 토큰이 만료돼 401 이 오면, refresh 토큰으로 새 access 를 받아 "딱 한 번" 재시도합니다.
//
// 설계 근거: BACKEND_GUIDE 작업 #9, Design 2.9(ApiClient)·2.10(REST API 명세).
//
// 입문자 메모:
//   - 네트워크는 언제든 실패할 수 있습니다(서버 꺼짐/와이파이 끊김 등). 그래서 모든 호출을
//     try/catch 로 감싸고, 실패는 ApiException 으로 통일해 던집니다(호출하는 쪽이 잡기 쉽게).
//   - statusCode 0 = "서버까지 닿지도 못함(네트워크/타임아웃)" 을 뜻하는 우리만의 약속입니다.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'secure_storage.dart';

/// 서버 호출 실패를 나타내는 예외.
///   - statusCode: HTTP 상태코드(0 이면 네트워크/타임아웃 등 연결 실패)
///   - message   : 사용자/개발자에게 보여줄 메시지(가능하면 서버가 준 error 문구)
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  /// 네트워크 자체가 안 돼서 서버에 닿지 못한 경우인지.
  bool get isNetworkError => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final SecureStorageService _secure;
  final http.Client _http;
  final String baseUrl;

  // 테스트 시 가짜 http.Client / SecureStorage 를 끼워 넣을 수 있게 생성자로 받습니다.
  ApiClient({
    SecureStorageService? secure,
    http.Client? httpClient,
    String? baseUrl,
  })  : _secure = secure ?? SecureStorageService(),
        _http = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? AppConfig.serverBaseUrl;

  // 너무 오래 기다리지 않도록 요청 제한 시간(특히 무료 서버는 잠들었다 깰 때 느림).
  static const _timeout = Duration(seconds: 20);

  // ── 인증 엔드포인트(토큰 불필요) ─────────────────────────────

  /// 로그인. 성공 시 { accessToken, refreshToken } 을 반환합니다(저장은 호출자 몫).
  /// 실패 시 ApiException(401 등)을 던집니다.
  Future<Map<String, dynamic>> login({
    required String id,
    required String password,
  }) {
    return _sendRaw('POST', '/auth/login',
        body: {'id': id, 'password': password}, authenticated: false);
  }

  /// 회원가입. 성공 시 { user } 를 반환, 아이디 중복이면 ApiException(409).
  Future<Map<String, dynamic>> signup({
    required String id,
    required String password,
    required String email,
  }) {
    return _sendRaw('POST', '/auth/signup',
        body: {'id': id, 'password': password, 'email': email},
        authenticated: false);
  }

  /// 보관된 refresh 토큰으로 새 access 토큰을 받아 저장합니다.
  ///   성공하면 true, (refresh 없음/만료/위조 등) 실패하면 false.
  ///   401 자동 재시도와 자동로그인 판단에 모두 쓰입니다.
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

  // ── 인증이 필요한 일반 호출(토큰 자동 첨부 + 401 재시도) ──────
  // C-B 에서 방·카드·요금 화면이 이 메서드들을 사용합니다.

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) =>
      _send('PUT', path, body: body);

  // 인증 요청의 공통 흐름: 보내보고, 401 이면 한 번 refresh 후 재시도.
  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      return await _sendRaw(method, path, body: body, authenticated: true);
    } on ApiException catch (e) {
      // access 만료(401)면 refresh 로 새 토큰을 받아 딱 한 번만 다시 시도합니다.
      if (e.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          return _sendRaw(method, path, body: body, authenticated: true);
        }
      }
      rethrow; // 그 외(또는 refresh 실패)는 그대로 호출자에게 전달.
    }
  }

  // ── 실제 HTTP 전송(가장 낮은 단계) ──────────────────────────
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
      // SocketException, TimeoutException, ClientException 등 → 연결 실패로 통일.
      throw ApiException(0, '서버에 연결할 수 없습니다. 네트워크나 서버 상태를 확인해주세요.');
    }

    // 본문이 비어 있을 수도 있으니 안전하게 파싱.
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

    // 서버가 { ok:false, error:"..." } 형태로 주므로 error 문구를 우선 사용.
    final message = (decoded['error'] as String?) ?? 'HTTP ${res.statusCode}';
    throw ApiException(res.statusCode, message);
  }
}
