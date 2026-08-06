// v1.30 (2026-08-06): 업적 한글 칭호 매핑 가드.
//
// 서버 카탈로그(56종)의 모든 code 에 한글 칭호가 붙어 있는지, 칭호가 서로
// 겹치지 않는지 검사. 코드 목록 갱신법:
//   python - <<'PY' … GET /api/v1/achievements 의 catalog[].code 나열
// 서버가 코드를 추가하면 이 테스트가 먼저 실패해 칭호 누락을 잡는다.

import 'package:flutter_test/flutter_test.dart';
import 'package:facing_app/features/achievement/achievement_card.dart';

/// 서버 카탈로그 계약 (service-facing seeds/seed_achievements.py 기준, 56종).
const kServerAchievementCodes = <String>[
  'FIRST_ENGINE',
  'REACH_SCALED',
  'REACH_INTERMEDIATE',
  'REACH_RX',
  'REACH_RX_PLUS',
  'REACH_ELITE',
  'SCORE_50_OVERALL',
  'SCORE_60_OVERALL',
  'SCORE_70_OVERALL',
  'SCORE_80_OVERALL',
  'SCORE_90_OVERALL',
  'ALL_CAT_60',
  'HOLY_TRINITY',
  'WOD_10',
  'WOD_25',
  'WOD_75',
  'WOD_50',
  'STREAK_3',
  'STREAK_7',
  'STREAK_10',
  'STREAK_60',
  'STREAK_90',
  'GIRLS_5_COMPLETE',
  'HEROES_3',
  'HEROES_5',
  'GAMES_1',
  'TITLE_SCHOLAR',
  'TITLE_UNDEFEATED',
  'SEASON_SPRING',
  'SEASON_SUMMER',
  'SEASON_FALL',
  'SEASON_WINTER',
  'SEASON_YEAREND',
  'EGG_TRIPLE',
  'PR_FIRST',
  'PR_HUNTER',
  'PR_25',
  'PR_LIFT_KING',
  'PR_ENGINE',
  'PR_DEADLIFT_2X',
  'PR_SQUAT_2X',
  'PR_SNATCH_BW',
  'VOL_100_WODS',
  'VOL_TRIPLE_STREAK',
  'VOL_COMEBACK',
  'VOL_COMEBACK_60',
  'VOL_EQUAL',
  'CAT_POWER_RX',
  'CAT_OLYMPIC_RX',
  'CAT_GYMN_RX',
  'CAT_CARDIO_RX',
  'CAT_METCON_RX',
  'CAT_BODY_RX',
  'CF_OPEN_SURVIVOR',
  'CF_QUARTERFINAL_GRINDER',
  'CF_SEMIFINAL_WATCH',
];

void main() {
  group('업적 한글 칭호 (AchievementCard.koreanTitle)', () {
    test('서버 카탈로그 56종 전수 커버 — 영문명 폴백 0건', () {
      expect(kServerAchievementCodes.length, 56);
      final missing = kServerAchievementCodes
          .where((c) => AchievementCard.koreanTitle(c).isEmpty)
          .toList();
      expect(missing, isEmpty, reason: '한글 칭호 누락: ${missing.join(', ')}');
    });

    test('칭호 중복 0건 — 두 업적이 같은 이름으로 보이지 않는다', () {
      final seen = <String, String>{};
      final dupes = <String>[];
      for (final code in kServerAchievementCodes) {
        final title = AchievementCard.koreanTitle(code);
        final prev = seen[title];
        if (prev != null) dupes.add('$title ($prev ↔ $code)');
        seen[title] = code;
      }
      expect(dupes, isEmpty, reason: '중복 칭호: ${dupes.join(' / ')}');
    });

    test('미매핑 코드는 빈 문자열 — 호출부가 영문 고유명으로 폴백', () {
      expect(AchievementCard.koreanTitle('NO_SUCH_CODE'), '');
    });
  });
}
