// v1.16 Sprint 10: WOD 세션 기록 저장 후 Attendance·History 탭 자동 새로고침용 이벤트 버스.
// Consumer가 notifyListeners를 받아 reload하면 된다.

import 'package:flutter/foundation.dart';

class WodSessionBus extends ChangeNotifier {
  int _completedCount = 0;
  DateTime? _lastCompletedAt;

  int get completedCount => _completedCount;
  DateTime? get lastCompletedAt => _lastCompletedAt;

  /// WOD 세션 완료 시 호출. 리스너들이 reload 트리거.
  void bump() {
    _completedCount++;
    _lastCompletedAt = DateTime.now();
    notifyListeners();
  }
}
