import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'device_id.dart';
import 'notification_service.dart';

/// v1.17 사장·코치 폰 SSE 푸시 서비스.
///
/// 백엔드 `/api/v1/staff/me/events` 에 device_hash 로 인증해서 상시 연결 유지.
/// 본인이 운영하는 모든 박스의 sse_publish 이벤트를 받음 — member_join_request 등.
///
/// 받은 이벤트는 [NotificationService] 로 위임해 OS 알림바에 표시.
/// 앱이 포그라운드든 백그라운드든 같은 핸들러 사용.
///
/// Foreground Service 와 결합 (foreground_handler.dart) 시 앱 종료 후에도 유지.
class StaffPushService {
  final Dio _dio;
  StreamController<Map<String, dynamic>>? _controller;
  CancelToken? _cancelToken;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _disposed = false;
  bool _connecting = false;
  bool _started = false;

  StaffPushService()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiClient.baseUrl,
          receiveTimeout: Duration.zero,
          connectTimeout: const Duration(seconds: 5),
        ));

  /// 사장·코치 로그인 직후 호출. 알림 표시 부수 효과 시작.
  void start() {
    if (_started || _disposed) return;
    _started = true;
    _controller ??= StreamController<Map<String, dynamic>>.broadcast();
    _controller!.stream.listen(_handleEvent, onError: (e) {
      debugPrint('[STAFF_SSE] stream error: $e');
    });
    _ensureConnected();
    debugPrint('[STAFF_SSE] started');
  }

  /// 로그아웃 시 호출. 연결 끊고 재연결 중단.
  void stop() {
    _started = false;
    _disconnect();
    debugPrint('[STAFF_SSE] stopped');
  }

  Stream<Map<String, dynamic>>? get events => _controller?.stream;

  void _ensureConnected() {
    if (_connecting || _cancelToken != null || _disposed || !_started) return;
    _connecting = true;
    _connect();
  }

  Future<void> _connect() async {
    if (_disposed) {
      _connecting = false;
      return;
    }
    _cancelToken = CancelToken();
    try {
      final deviceId = await DeviceIdService.get();
      final res = await _dio.get<ResponseBody>(
        '/api/v1/staff/me/events',
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'X-Device-Id': deviceId,
            'Accept': 'text/event-stream',
          },
        ),
        cancelToken: _cancelToken,
      );

      _reconnectAttempts = 0;
      _connecting = false;
      debugPrint('[STAFF_SSE] connected /api/v1/staff/me/events');

      String? pendingEvent;
      final buffer = StringBuffer();

      await res.data!.stream
          .transform(StreamTransformer<Uint8List, String>.fromHandlers(
        handleData: (chunk, sink) =>
            sink.add(utf8.decode(chunk, allowMalformed: true)),
      ))
          .transform(const LineSplitter())
          .forEach((line) {
        if (line.isEmpty) {
          if (buffer.isNotEmpty) {
            try {
              final raw = buffer.toString();
              final parsed = jsonDecode(raw);
              if (parsed is Map<String, dynamic>) {
                final type =
                    pendingEvent ?? (parsed['type']?.toString() ?? 'message');
                debugPrint(
                    '[STAFF_SSE] recv $type ${raw.length > 80 ? raw.substring(0, 80) : raw}');
                _controller?.add({'type': type, 'data': parsed});
              }
            } catch (e) {
              debugPrint('[STAFF_SSE] parse failed: $e');
            }
          }
          buffer.clear();
          pendingEvent = null;
          return;
        }
        if (line.startsWith(':')) return;
        if (line.startsWith('event:')) {
          pendingEvent = line.substring(6).trim();
          return;
        }
        if (line.startsWith('data:')) {
          buffer.write(line.substring(5).trim());
          return;
        }
      });
    } on DioException catch (e) {
      if (!CancelToken.isCancel(e)) {
        debugPrint('[STAFF_SSE] error: ${e.type} ${e.message}');
        _scheduleReconnect();
      }
    } catch (e) {
      debugPrint('[STAFF_SSE] unexpected: $e');
      _scheduleReconnect();
    } finally {
      _connecting = false;
      _cancelToken = null;
    }
    if (!_disposed && _started) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed || !_started) return;
    _reconnectAttempts = (_reconnectAttempts + 1).clamp(0, 6);
    final delaySec = 1 << (_reconnectAttempts - 1);
    debugPrint(
        '[STAFF_SSE] reconnect in ${delaySec}s (attempt $_reconnectAttempts)');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySec), () {
      if (_started) _ensureConnected();
    });
  }

  void _disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cancelToken?.cancel('disconnect');
    _cancelToken = null;
  }

  Future<void> _handleEvent(Map<String, dynamic> evt) async {
    final type = evt['type'] as String? ?? 'message';
    final data = evt['data'] as Map<String, dynamic>? ?? const {};
    // ping 은 알림 안 띄움.
    if (type == 'ping') return;
    await NotificationService.instance.showFromSseEvent(
      eventType: type,
      payload: data,
    );
  }

  void dispose() {
    _disposed = true;
    _started = false;
    _disconnect();
    _controller?.close();
    _controller = null;
  }
}
