// v1.16 Sprint 11: Shell 탭 전환 딥링크용 글로벌 버스.
// box_wod_screen 등 하위 화면에서 MainShell의 현재 탭을 다른 탭으로 전환하려 할 때 사용.

import 'package:flutter/foundation.dart';

class ShellNavBus extends ChangeNotifier {
  int? _requestedIndex;

  /// MainShell이 전환 완료 후 null로 초기화하여 재전환 가능하게 유지.
  int? get requestedIndex => _requestedIndex;

  void requestTab(int index) {
    _requestedIndex = index;
    notifyListeners();
  }

  void consume() {
    _requestedIndex = null;
  }
}
