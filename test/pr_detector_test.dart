// v1.20 Phase 2.5: PrDetector 단위 테스트.

import 'package:flutter_test/flutter_test.dart';
import 'package:facing_app/core/pr_detector.dart';
import 'package:facing_app/features/history/history_models.dart';

WodHistoryItem _h(String type, int sec, int dayOffset) {
  return WodHistoryItem(
    id: dayOffset,
    wodType: type,
    notes: '',
    createdAt: DateTime(2026, 1, 1).add(Duration(days: dayOffset)),
    estimatedTotalSec: sec,
  );
}

void main() {
  group('PrDetector.countPrs', () {
    test('빈 history → 0', () {
      expect(PrDetector.countPrs(const []), 0);
    });

    test('단일 기록 → 0 (비교 대상 없음)', () {
      expect(PrDetector.countPrs([_h('fran', 200, 0)]), 0);
    });

    test('동일 type 시간 단축 1회 → 1 PR', () {
      expect(
        PrDetector.countPrs([_h('fran', 200, 0), _h('fran', 180, 1)]),
        1,
      );
    });

    test('동일 type 점진 단축 3회 → 3 PR', () {
      expect(
        PrDetector.countPrs([
          _h('fran', 200, 0),
          _h('fran', 180, 1),
          _h('fran', 170, 2),
          _h('fran', 165, 3),
        ]),
        3,
      );
    });

    test('동일 type 시간 늘어나면 PR 아님', () {
      expect(
        PrDetector.countPrs([_h('fran', 180, 0), _h('fran', 220, 1)]),
        0,
      );
    });

    test('서로 다른 wod_type 은 독립 best', () {
      expect(
        PrDetector.countPrs([
          _h('fran', 200, 0),
          _h('grace', 150, 1),
          _h('fran', 180, 2), // PR
          _h('grace', 140, 3), // PR
        ]),
        2,
      );
    });

    test('estimatedTotalSec null → skip', () {
      expect(
        PrDetector.countPrs([
          WodHistoryItem(
            id: 1,
            wodType: 'fran',
            notes: '',
            createdAt: DateTime(2026, 1, 1),
          ),
          _h('fran', 180, 1),
        ]),
        0, // 첫 비교 대상 없음 → PR 아님
      );
    });

    test('빈 wod_type 은 skip', () {
      expect(
        PrDetector.countPrs([_h('', 200, 0), _h('', 180, 1)]),
        0,
      );
    });

    test('time tie (같은 시간) → PR 아님 (strict less)', () {
      expect(
        PrDetector.countPrs([_h('fran', 180, 0), _h('fran', 180, 1)]),
        0,
      );
    });
  });
}
