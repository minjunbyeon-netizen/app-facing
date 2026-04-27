// v1.20 Phase 2: 시즌 참여 배지.
//
// reference/gamification.md §2 시즌 배지.
// 정책:
// - 시즌(Open/Quarterfinals/Semifinals/Games) 동안 1회 이상 세션 → 자동 unlock.
// - 클라이언트 로컬 저장 (Phase 2.5 백엔드 통합).
// - 코드 형식: SEASON_{SLUG}_{YEAR}.
// - 표시: 영문 라벨 + 한글 캡션 (V10).

import 'package:shared_preferences/shared_preferences.dart';

import 'season.dart';

class SeasonBadge {
  final String code;
  final String label;
  final String captionKo;

  const SeasonBadge({
    required this.code,
    required this.label,
    required this.captionKo,
  });
}

class SeasonBadgeService {
  SeasonBadgeService._();

  static String _slug(CrossFitSeason s) {
    switch (s) {
      case CrossFitSeason.open:
        return 'OPEN';
      case CrossFitSeason.quarterfinals:
        return 'QF';
      case CrossFitSeason.semifinals:
        return 'SF';
      case CrossFitSeason.games:
        return 'GAMES';
      case CrossFitSeason.offseason:
        return 'OFF';
    }
  }

  static String? badgeCodeFor(SeasonInfo info, [DateTime? now]) {
    if (!info.isActive) return null;
    final n = now ?? DateTime.now().toLocal();
    return 'SEASON_${_slug(info.current)}_${n.year}';
  }

  static SeasonBadge? badgeFor(SeasonInfo info, [DateTime? now]) {
    final code = badgeCodeFor(info, now);
    if (code == null) return null;
    final n = now ?? DateTime.now().toLocal();
    final year = n.year;
    switch (info.current) {
      case CrossFitSeason.open:
        return SeasonBadge(
          code: code,
          label: 'OPEN $year',
          captionKo: '$year Open 시즌 참여.',
        );
      case CrossFitSeason.quarterfinals:
        return SeasonBadge(
          code: code,
          label: 'QF $year',
          captionKo: '$year Quarterfinals 진행 중 세션 기록.',
        );
      case CrossFitSeason.semifinals:
        return SeasonBadge(
          code: code,
          label: 'SF $year',
          captionKo: '$year Semifinals 시즌 참여.',
        );
      case CrossFitSeason.games:
        return SeasonBadge(
          code: code,
          label: 'GAMES $year',
          captionKo: '$year Games 시즌 참여.',
        );
      case CrossFitSeason.offseason:
        return null;
    }
  }

  /// 세션 발생 시 호출. 현재 시즌이 active 면 해당 배지 unlock.
  /// 반환: 새로 해금된 배지 (이미 해금돼 있으면 null).
  static Future<SeasonBadge?> recordSessionToday({DateTime? now}) async {
    final n = now ?? DateTime.now().toLocal();
    final info = currentSeason(n);
    final badge = badgeFor(info, n);
    if (badge == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final key = 'season_badge_${badge.code}';
    if (prefs.getBool(key) == true) return null;
    await prefs.setBool(key, true);
    return badge;
  }

  /// 현재까지 unlock 된 시즌 배지 코드 목록.
  static Future<List<String>> unlockedCodes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getKeys()
        .where((k) => k.startsWith('season_badge_'))
        .where((k) => prefs.getBool(k) == true)
        .map((k) => k.replaceFirst('season_badge_', ''))
        .toList()
      ..sort();
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('season_badge_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
