// /go 7 Phase 3 (B2): Panel B shareCount signal 저장소.
//
// SharedPreferences 'panel_b_share_count' 단일 키.
// share_plus 호출 직후 increment() 한 번씩.
// PanelBUnlocker 가 PB_PHOTO_FINISH 등 공유 의존 칭호 unlock 추론에 사용.

import 'package:shared_preferences/shared_preferences.dart';

class ShareCountStore {
  static const _key = 'panel_b_share_count';

  static Future<int> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  static Future<void> increment() async {
    final prefs = await SharedPreferences.getInstance();
    final cur = prefs.getInt(_key) ?? 0;
    await prefs.setInt(_key, cur + 1);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
