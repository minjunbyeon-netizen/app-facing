// v1.16 Sprint 9a: UI 접근성 환경설정 (폰트 확대 등).
// UX_QUESTIONS_v1.16 Category O (Masters 접근성) 대응 — P9 Chulsoo P0.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 폰트 스케일 프리셋.
/// 100% / 115% / 130% / 150% — Masters·시력 약 사용자 대응.
class UiPrefsState extends ChangeNotifier {
  static const _kTextScale = 'ui_text_scale_v1';

  double _textScale = 1.0;

  double get textScale => _textScale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _textScale = prefs.getDouble(_kTextScale) ?? 1.0;
    notifyListeners();
  }

  Future<void> setTextScale(double s) async {
    _textScale = s.clamp(1.0, 1.5);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kTextScale, _textScale);
    notifyListeners();
  }
}
