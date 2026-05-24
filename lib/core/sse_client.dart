import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'device_id.dart';

/// PHASE5 — 회원 폰 SSE 구독 클라이언트.
///
/// 백엔드 `/api/v1/member/me/events` 가 text/event-stream chunked 응답을 보내고,
/// 같은 박스의 모든 mutation (member.created · membership.issued · wod.posted ·
/// announcement.posted · class_cancelled 등) 을 push.
///
/// dio stream + StreamTransformer 로 line 단위 파싱.
/// SSE 표준: `event: <type>\n` `data: <json>\n` `\n` (빈 줄로 메시지 종료).
class SseEvent {
  final String type;
  final Map<String, dynamic> data;
  const SseEvent({required this.type, required this.data});

  @override
  String toString() => 'SseEvent($type, $data)';
}

class SseClient {
  final Dio _dio;
  StreamController<SseEvent>? _controller;
  CancelToken? _cancelToken;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _disposed = false;
  bool _connecting = false;

  SseClient(ApiClient _) : _dio = Dio(BaseOptions(
          baseUrl: ApiClient.baseUrl,
          // SSE 는 무한 stream — receiveTimeout 비활성.
          receiveTimeout: Duration.zero,
          connectTimeout: const Duration(seconds: 5),
        ));

  Stream<SseEvent> get events {
    _controller ??= StreamController<SseEvent>.broadcast(
      onListen: _ensureConnected,
      onCancel: () {
        // 마지막 listener 사라지면 연결 끊음 (자원 절약).
        if (_controller?.hasListener == false) {
          _disconnect();
        }
      },
    );
    return _controller!.stream;
  }

  void _ensureConnected() {
    if (_connecting || _cancelToken != null || _disposed) return;
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
        '/api/v1/member/me/events',
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
      debugPrint('[SSE] connected /api/v1/member/me/events');

      String? pendingEvent;
      final buffer = StringBuffer();

      await res.data!.stream
          .transform(StreamTransformer<Uint8List, String>.fromHandlers(
        handleData: (chunk, sink) => sink.add(utf8.decode(chunk, allowMalformed: true)),
      ))
          .transform(const LineSplitter())
          .forEach((line) {
        if (line.isEmpty) {
          // 빈 줄 = 메시지 종료.
          if (buffer.isNotEmpty) {
            try {
              final raw = buffer.toString();
              final parsed = jsonDecode(raw);
              if (parsed is Map<String, dynamic>) {
                final type = pendingEvent ?? (parsed['type']?.toString() ?? 'message');
                debugPrint('[SSE] recv $type ${raw.length > 80 ? raw.substring(0, 80) : raw}');
                _controller?.add(SseEvent(type: type, data: parsed));
              }
            } catch (e) {
              debugPrint('[SSE] parse failed: $e raw=${buffer.toString().substring(0, buffer.length.clamp(0, 80))}');
            }
          }
          buffer.clear();
          pendingEvent = null;
          return;
        }
        if (line.startsWith(':')) return; // keepalive comment
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
      if (CancelToken.isCancel(e)) {
        debugPrint('[SSE] cancelled');
      } else {
        debugPrint('[SSE] error: ${e.type} ${e.message}');
        _scheduleReconnect();
      }
    } catch (e) {
      debugPrint('[SSE] unexpected: $e');
      _scheduleReconnect();
    } finally {
      _connecting = false;
      _cancelToken = null;
    }

    // stream end → 서버가 connection 닫음. 재연결.
    if (!_disposed && _controller?.hasListener == true) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectAttempts = (_reconnectAttempts + 1).clamp(0, 6);
    // 1s, 2s, 4s, 8s, 16s, 32s, 64s (cap)
    final delaySec = 1 << (_reconnectAttempts - 1);
    debugPrint('[SSE] reconnect in ${delaySec}s (attempt $_reconnectAttempts)');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySec), () {
      if (_controller?.hasListener == true) _ensureConnected();
    });
  }

  void _disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cancelToken?.cancel('disconnect');
    _cancelToken = null;
  }

  void dispose() {
    _disposed = true;
    _disconnect();
    _controller?.close();
    _controller = null;
  }
}
