import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

import 'device_id.dart';
import 'exception.dart';

class ApiClient {
  // 빌드 시 --dart-define=API_BASE_URL=... 로 주입. 미지정 시 에뮬레이터 기본값.
  // 예) flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.100:5060
  // 실기기 베타 테스트는 LAN IP 또는 배포 URL 필요. 10.0.2.2 는 에뮬레이터 전용.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5060',
  );

  final Dio _dio;
  final CookieJar _cookieJar;
  final List<Future<void> Function()> _retryQueue = [];

  ApiClient._(this._dio, this._cookieJar);

  /// 현재 보관 중인 Flask 세션 쿠키를 "session=xxx" 헤더 형태로 반환 (없으면 null).
  /// D26 — 소셜 로그인 세션을 사장 인증(BossAuthState)에 넘겨 재로그인 없이 대시보드 진입.
  Future<String?> sessionCookie() async {
    final cookies = await _cookieJar.loadForRequest(Uri.parse(baseUrl));
    for (final c in cookies) {
      if (c.name == 'session') return 'session=${c.value}';
    }
    return null;
  }

  /// 네트워크 실패로 적재된 요청을 순서대로 재실행.
  /// ConnectivityState가 온라인 복귀 시 호출.
  Future<void> flushRetryQueue() async {
    if (_retryQueue.isEmpty) return;
    final pending = List<Future<void> Function()>.from(_retryQueue);
    _retryQueue.clear();
    var failed = 0;
    for (final task in pending) {
      try {
        await task();
      } catch (e) {
        // QA B-EX-4: 실패해도 나머지 계속. 디버깅용 카운트·로그 유지.
        failed++;
        debugPrint('[ApiClient.flushRetryQueue] task failed: $e');
      }
    }
    if (failed > 0) {
      debugPrint('[ApiClient.flushRetryQueue] $failed/${pending.length} failed');
    }
  }

  /// 네트워크 에러일 때 재시도용으로 적재. 호출부가 직접 enqueue.
  void enqueueRetry(Future<void> Function() task) {
    _retryQueue.add(task);
  }

  static ApiClient create() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      // 2026-08-13 — 3초는 실기기에 너무 짧다. 실사용에서 폰이 가입 신청 중
      // "백엔드 OFF" 를 맞았는데 같은 시각 서버는 정상(200, 0.25초)이었다.
      // PC 유선은 0.08초지만 폰 LTE 는 DNS+TCP+TLS 만으로 3초를 넘길 수 있다.
      // 서버가 죽은 것과 손이 느린 것을 3초로 가르면 후자가 전자로 오진된다.
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ));
    // D26 소셜 로그인 — Flask 세션 쿠키 보관(in-memory). /auth/social 로그인 후
    // /auth/me·/auth/link-staff·/auth/logout 이 같은 세션을 자동으로 실어 보냄.
    final cookieJar = CookieJar();
    dio.interceptors.add(CookieManager(cookieJar));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.headers['X-Device-Id'] = await DeviceIdService.get();
        handler.next(options);
      },
    ));
    return ApiClient._(dio, cookieJar);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post(path, data: body);
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final res = await _dio.get(path);
      return _unwrapMap(res);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<List<dynamic>> getList(String path) async {
    try {
      final res = await _dio.get(path);
      return _unwrapList(res);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.patch(path, data: body);
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await _dio.delete(path);
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  dynamic _rawData(Response res) {
    final data = res.data;
    if (data is! Map) {
      throw AppException('응답 형식이 올바르지 않습니다', code: 'PROTOCOL');
    }
    if (data['ok'] == true) {
      return data['data'];
    }
    throw AppException(
      (data['error'] ?? '알 수 없는 오류').toString(),
      code: data['code']?.toString(),
      statusCode: res.statusCode,
    );
  }

  Map<String, dynamic> _unwrapMap(Response res) {
    final d = _rawData(res);
    if (d is Map) return Map<String, dynamic>.from(d);
    throw AppException('응답 데이터 형식이 올바르지 않습니다', code: 'PROTOCOL');
  }

  List<dynamic> _unwrapList(Response res) {
    final d = _rawData(res);
    if (d is List) return d;
    throw AppException('응답 데이터 형식이 올바르지 않습니다', code: 'PROTOCOL');
  }

  Map<String, dynamic> _unwrap(Response res) => _unwrapMap(res);

  AppException _mapDio(DioException e) {
    // v1.20: connect 실패(=백엔드 OFF/네트워크 차단)와 receive 지연(=요청 후 응답 지연)을 분리.
    // 기존 connectionTimeout이 TIMEOUT 메시지로 떨어져 "백엔드 OFF" 상황을 가렸음.
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      // 문구도 정정 — 사용자는 서버 상태를 모른다. 실제로는 '연결 못 함' 이고,
      // 서버가 멀쩡한데도 이 메시지가 떠서 장애로 오해하게 만들었다.
      return AppException('연결하지 못했습니다 · 네트워크 확인 후 다시 시도',
          code: 'NETWORK');
    }
    if (e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return AppException('서버 응답이 지연됩니다', code: 'TIMEOUT');
    }
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return AppException(
        data['error'].toString(),
        code: data['code']?.toString(),
        statusCode: e.response?.statusCode,
      );
    }
    return AppException('요청 처리 실패', code: 'UNKNOWN',
                        statusCode: e.response?.statusCode);
  }
}
