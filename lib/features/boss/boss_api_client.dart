import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import '../../core/device_id.dart';
import '../../core/exception.dart';
import 'boss_auth_state.dart';

// PHASE5 §1.1 — 사장 전용 Dio 인스턴스.
// 백엔드가 Flask session cookie 기반이므로:
//   1. 로그인 응답 Set-Cookie → _sessionCookie 추출 → BossAuthState 저장
//   2. 이후 모든 요청에 Cookie 헤더 + X-CSRF-Token 헤더 자동 주입.
//      (헤더명은 백엔드 admin.py require_csrf + CORS allow_headers 와 동일 — X-CSRF-Token)
class BossApiClient {
  final Dio _dio;
  BossAuthState? _authState;

  BossApiClient._(this._dio);

  void bindAuth(BossAuthState state) {
    _authState = state;
  }

  static BossApiClient create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiClient.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
        responseType: ResponseType.json,
        // 쿠키 리다이렉트 자동 따라가되 Set-Cookie 보존
        followRedirects: false,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    return BossApiClient._(dio);
  }

  /// POST /api/v1/auth/login — **통합 로그인** (2026-08-25 사용자 지시: 창구는 하나).
  ///
  /// 아이디·비밀번호만 보내면 서버가 코치인지 회원인지 판정해 `kind` 로 알려준다.
  /// 회원 로그인까지 이 클라이언트가 맡는 이유는 하나다 — 코치로 판정났을 때
  /// 세션 쿠키를 받아 둬야 하는데, Set-Cookie 를 다루는 클라이언트가 여기뿐이다
  /// (회원 API 는 X-Device-Id 헤더만 쓴다). 새 변형을 만들지 않고 재사용한다 (§3).
  ///
  /// 반환: `{'data': {...kind 포함...}, 'session_cookie': '...'}`
  /// (회원이면 session_cookie 는 빈 문자열일 수 있다 — 쓰지 않는다.)
  Future<Map<String, dynamic>> unifiedLogin(
    String loginId,
    String password,
  ) async {
    return _loginTo('/api/v1/auth/login', loginId, password);
  }

  /// POST /api/v1/admin/login — 쿠키 세션 획득.
  /// v1.17 — X-Device-Id 헤더 동봉. 백엔드가 GymManager.device_hash 자동 등록 →
  /// staff SSE (/api/v1/staff/me/events) 페어링 완료 상태로 들어감.
  Future<Map<String, dynamic>> login(String loginId, String password) async {
    return _loginTo('/api/v1/admin/login', loginId, password);
  }

  /// 두 로그인 창구가 공유하는 몸통 — 요청·쿠키 추출·에러 매핑 한 벌 (§0-B).
  Future<Map<String, dynamic>> _loginTo(
    String path,
    String loginId,
    String password,
  ) async {
    try {
      final deviceId = await DeviceIdService.get();
      final res = await _dio.post(
        path,
        data: {'login_id': loginId, 'password': password},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Device-Id': deviceId,
          },
        ),
      );
      final raw = res.data;
      if (raw is! Map || raw['ok'] != true) {
        throw AppException(
          (raw is Map ? raw['error'] : null) ?? '로그인 실패',
          code: raw is Map ? raw['code']?.toString() : null,
          statusCode: res.statusCode,
        );
      }
      // Set-Cookie 헤더에서 session 쿠키 추출
      final setCookie = res.headers['set-cookie'];
      String sessionCookie = '';
      if (setCookie != null && setCookie.isNotEmpty) {
        // 'session=xxx; HttpOnly; ...' → 첫 세미콜론 전까지만
        for (final c in setCookie) {
          if (c.startsWith('session=')) {
            sessionCookie = c.split(';').first.trim();
            break;
          }
        }
      }
      if (sessionCookie.isEmpty) {
        debugPrint(
          '[BossApiClient] 경고: session 쿠키 없음 — 백엔드 SESSION_COOKIE_SECURE 확인',
        );
      }
      return {'data': raw['data'], 'session_cookie': sessionCookie};
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  /// 인증 헤더 포함 GET
  Future<Map<String, dynamic>> get(String path) async {
    try {
      final res = await _dio.get(path, options: _authOpts());
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  /// 인증 헤더 포함 POST
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.post(path, data: body, options: _authOpts());
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  /// 인증 헤더 포함 PATCH (Phase 1-2·1-3 settings 갱신용)
  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.patch(path, data: body, options: _authOpts());
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  /// 인증 헤더 포함 DELETE
  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await _dio.delete(path, options: _authOpts());
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Options _authOpts() {
    final auth = _authState;
    final headers = <String, dynamic>{};
    if (auth?.sessionCookie != null) {
      headers['Cookie'] = auth!.sessionCookie!;
    }
    if (auth?.csrfToken != null) {
      headers['X-CSRF-Token'] = auth!.csrfToken!;
    }
    return Options(headers: headers);
  }

  Map<String, dynamic> _unwrap(Response res) {
    final data = res.data;
    if (data is! Map) {
      throw AppException('응답 형식 오류', code: 'PROTOCOL');
    }
    if (data['ok'] == true) {
      final d = data['data'];
      if (d is Map) return Map<String, dynamic>.from(d);
      return {'_raw': d};
    }
    throw AppException(
      (data['error'] ?? '서버 오류').toString(),
      code: data['code']?.toString(),
      statusCode: res.statusCode,
    );
  }

  AppException _mapDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return AppException('백엔드 OFF · 재시도', code: 'NETWORK');
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return AppException('서버 응답 지연', code: 'TIMEOUT');
    }
    final d = e.response?.data;
    if (d is Map && d['error'] != null) {
      return AppException(
        d['error'].toString(),
        code: d['code']?.toString(),
        statusCode: e.response?.statusCode,
      );
    }
    return AppException(
      '요청 실패',
      code: 'UNKNOWN',
      statusCode: e.response?.statusCode,
    );
  }
}
