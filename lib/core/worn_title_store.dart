// v1.16 Sprint 14: 착용 칭호 저장소 (Panel B 설계).
// Profile 프로필 영역 옆 표시용. 착용 1개 · 언제든 변경 가능.

import 'package:shared_preferences/shared_preferences.dart';

class WornTitleStore {
  static const _key = 'worn_title_code_v1';

  static Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    return (v == null || v.isEmpty) ? null : v;
  }

  static Future<void> set(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
