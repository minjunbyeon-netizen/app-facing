import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// 네트워크 연결 상태 감시 + ApiClient 재시도 큐 플러시 트리거.
class ConnectivityState extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> init() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = _interpret(result);
    } catch (_) {
      _isOnline = true;
    }
    _sub = _connectivity.onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = _interpret(result);
      notifyListeners();
      if (wasOffline && _isOnline && _flushCallback != null) {
        _flushCallback!();
      }
    });
  }

  bool _interpret(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  VoidCallback? _flushCallback;
  void bindRetryQueue(ApiClient api) {
    _flushCallback = () => api.flushRetryQueue();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
