import 'package:shared_preferences/shared_preferences.dart';

/// 앱 사용자 역할.
/// - coach: 박스 운영. 박스 등록 + WOD 게시 + 멤버 관리
/// - member: 박스 멤버. 박스 검색 + 코치 WOD 받기 + 인박스
/// - solo: 혼자 트레이닝. 페이싱·Engine·업적만
enum AppMode { coach, member, solo }

/// SharedPreferences 'app_mode' 키 wrapper.
/// Splash 의 _bootstrap → mode 미설정 시 ModeSelectScreen 진입 분기.
class AppModeStore {
  static const _key = 'app_mode';

  static Future<AppMode?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    if (v == null) return null;
    return switch (v) {
      'coach' => AppMode.coach,
      'member' => AppMode.member,
      'solo' => AppMode.solo,
      _ => null,
    };
  }

  static Future<void> set(AppMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
