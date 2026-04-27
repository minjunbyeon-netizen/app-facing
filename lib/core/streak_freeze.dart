// v1.20 Phase 2: Streak Freeze — 1주 1회 무료 토큰.
//
// reference/gamification.md §3-1.
// 정책:
// - 사용자가 missed-day 직전 또는 직후에 freeze 1회 사용 → streak 유지.
// - 충전: 매주 월요일 00:00 KST 1회 무료.
// - 누적 X (사용 안 한 freeze 는 다음 주에 사라짐).
// - 클라이언트 로컬 저장 (Phase 2.5 백엔드 동기화).

import 'package:shared_preferences/shared_preferences.dart';

class StreakFreezeStore {
  static const _kLastUseIso = 'streak_freeze_last_use_iso';
  static const _kWeekStartIso = 'streak_freeze_week_start_iso';

  /// 현재 사용 가능 여부 (이번 주 미사용).
  static Future<bool> available({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastUse = prefs.getString(_kLastUseIso);
    if (lastUse == null) return true;
    final lastUseDt = DateTime.tryParse(lastUse);
    if (lastUseDt == null) return true;
    return !_inSameIsoWeek(lastUseDt, now ?? DateTime.now().toLocal());
  }

  /// freeze 사용. 성공 시 true / 이미 이번 주 사용했으면 false.
  static Future<bool> consume({DateTime? now}) async {
    final n = now ?? DateTime.now().toLocal();
    final ok = await available(now: n);
    if (!ok) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastUseIso, n.toIso8601String());
    await prefs.setString(_kWeekStartIso, _weekStart(n).toIso8601String());
    return true;
  }

  /// 마지막 사용일 (UI 표시용).
  static Future<DateTime?> lastUse() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_kLastUseIso);
    return iso == null ? null : DateTime.tryParse(iso);
  }

  /// 다음 충전일 (월요일 00:00 KST 기준).
  static DateTime nextRefill([DateTime? now]) {
    final n = now ?? DateTime.now().toLocal();
    final daysUntilMonday = (8 - n.weekday) % 7;
    final base = n.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
    return DateTime(base.year, base.month, base.day);
  }

  /// 디버그·테스트 리셋.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastUseIso);
    await prefs.remove(_kWeekStartIso);
  }

  // ---- internals ----
  static bool _inSameIsoWeek(DateTime a, DateTime b) {
    final wa = _weekStart(a);
    final wb = _weekStart(b);
    return wa.year == wb.year && wa.month == wb.month && wa.day == wb.day;
  }

  static DateTime _weekStart(DateTime d) {
    final local = DateTime(d.year, d.month, d.day);
    final offset = local.weekday - DateTime.monday; // Mon=1 → 0
    return local.subtract(Duration(days: offset));
  }
}
