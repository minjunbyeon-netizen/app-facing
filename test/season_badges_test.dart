// v1.20 Phase 2: Season Badges 단위 테스트.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facing_app/core/season.dart';
import 'package:facing_app/core/season_badges.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('SeasonBadgeService', () {
    test('offseason → null', () {
      const offInfo = SeasonInfo(
        current: CrossFitSeason.offseason,
        label: 'OFFSEASON',
        description: '',
      );
      expect(SeasonBadgeService.badgeCodeFor(offInfo), isNull);
      expect(SeasonBadgeService.badgeFor(offInfo), isNull);
    });

    test('Quarterfinals 4월 10일 → SEASON_QF_2026', () {
      final apr = DateTime(2026, 4, 10);
      final info = currentSeason(apr);
      expect(info.current, CrossFitSeason.quarterfinals);
      expect(SeasonBadgeService.badgeCodeFor(info, apr), 'SEASON_QF_2026');
      final b = SeasonBadgeService.badgeFor(info, apr);
      expect(b!.label, 'QF 2026');
      expect(b.captionKo, contains('Quarterfinals'));
    });

    test('Open 2/25 → SEASON_OPEN_2026', () {
      final feb = DateTime(2026, 2, 25);
      final info = currentSeason(feb);
      expect(info.current, CrossFitSeason.open);
      expect(SeasonBadgeService.badgeCodeFor(info, feb), 'SEASON_OPEN_2026');
    });

    test('recordSessionToday — Quarterfinals 시즌 첫 호출 → 새 배지', () async {
      final apr = DateTime(2026, 4, 10);
      final b = await SeasonBadgeService.recordSessionToday(now: apr);
      expect(b, isNotNull);
      expect(b!.code, 'SEASON_QF_2026');
      // 두번째 호출은 null (이미 해금).
      final b2 = await SeasonBadgeService.recordSessionToday(now: apr);
      expect(b2, isNull);
    });

    test('unlockedCodes — 누적 unlock 반영', () async {
      await SeasonBadgeService.recordSessionToday(
          now: DateTime(2026, 4, 10)); // QF
      await SeasonBadgeService.recordSessionToday(
          now: DateTime(2026, 5, 15)); // SF
      final codes = await SeasonBadgeService.unlockedCodes();
      expect(codes, containsAll(['SEASON_QF_2026', 'SEASON_SF_2026']));
    });

    test('reset 후 unlockedCodes 비어있음', () async {
      await SeasonBadgeService.recordSessionToday(
          now: DateTime(2026, 4, 10));
      await SeasonBadgeService.reset();
      expect(await SeasonBadgeService.unlockedCodes(), isEmpty);
    });
  });
}
