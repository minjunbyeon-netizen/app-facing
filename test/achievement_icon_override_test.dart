import 'package:flutter_test/flutter_test.dart';

import 'package:hyphen_app/features/achievement/hyphen_pictogram.dart';
import 'package:hyphen_app/models/achievement.dart';

/// PC 업적 설정에서 코치가 고른 픽토그램이 폰에 그대로 나오는지 고정한다.
/// 2026-08-21 — 서버는 늘 icon 을 내려줬는데 앱이 버리고 있었다 (끊긴 고리).
void main() {
  group('코치가 고른 아이콘', () {
    test('서버 응답의 icon 을 카탈로그가 보관한다', () {
      final c = AchievementCatalog.fromJson(const {
        'code': 'VOL_TRIPLE_STREAK',
        'name': 'Triple Threat Week.',
        'description': '3주 연속 주 4회 기록.',
        'rarity': 'Rare',
        'is_hidden': false,
        'sort_order': 530,
        'icon': 'crown',
      });
      expect(c.icon, 'crown');
      expect(c.rarity, 'Rare');
    });

    test('고른 이름이 코드 매핑을 이긴다', () {
      // 코드 매핑상 이 코드는 crown 이 아니다 — override 가 이겨야 한다.
      final byCode = HyphenPictogram.assetFor('VOL_TRIPLE_STREAK');
      final byCoach =
          HyphenPictogram.assetFor('VOL_TRIPLE_STREAK', override: 'crown');
      expect(byCoach, 'assets/pictograms/crown.svg');
      expect(byCoach, isNot(byCode));
    });

    test('팩에 없는 이름은 무시하고 코드 매핑으로 떨어진다', () {
      final byCode = HyphenPictogram.assetFor('STREAK_3');
      final bogus =
          HyphenPictogram.assetFor('STREAK_3', override: 'no-such-icon');
      expect(bogus, byCode);
    });

    test('숨김+잠김이면 코치가 골랐어도 자물쇠로 덮는다', () {
      final locked = HyphenPictogram.assetFor('EGG_1',
          hiddenLocked: true, override: 'crown');
      expect(locked, 'assets/pictograms/lock.svg');
    });

    test('모르는 코드도 비지 않는다 (star 폴백)', () {
      expect(HyphenPictogram.assetFor('ZZZ_UNKNOWN'),
          'assets/pictograms/star.svg');
    });
  });
}
