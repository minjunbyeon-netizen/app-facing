import 'package:dio/dio.dart';

import 'device_id.dart';
import 'exception.dart';

class ApiClient {
  // Android 에뮬레이터에서 호스트는 10.0.2.2. 실기기는 배포 URL로 교체.
  static const String baseUrl = 'http://10.0.2.2:5060';

  final Dio _dio;
  final List<Future<void> Function()> _retryQueue = [];

  ApiClient._(this._dio);

  /// 네트워크 실패로 적재된 요청을 순서대로 재실행.
  /// ConnectivityState가 온라인 복귀 시 호출.
  Future<void> flushRetryQueue() async {
    if (_retryQueue.isEmpty) return;
    final pending = List<Future<void> Function()>.from(_retryQueue);
    _retryQueue.clear();
    for (final task in pending) {
      try {
        await task();
      } catch (_) {
        // 실패해도 나머지 계속. 영구 실패는 호출부 책임.
      }
    }
  }

  /// 네트워크 에러일 때 재시도용으로 적재. 호출부가 직접 enqueue.
  void enqueueRetry(Future<void> Function() task) {
    _retryQueue.add(task);
  }

  static ApiClient create() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.headers['X-Device-Id'] = await DeviceIdService.get();
        handler.next(options);
      },
    ));
    return ApiClient._(dio);
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
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return AppException('서버 응답이 지연됩니다', code: 'TIMEOUT');
    }
    if (e.type == DioExceptionType.connectionError) {
      return AppException('서버에 연결할 수 없습니다', code: 'NETWORK');
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
