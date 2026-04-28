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

  group('PrDetector.isPrAgainst — wod_session 단건 비교', () {
    test('빈 prior + 새 기록 → false (첫 기록은 PR 아님)', () {
      expect(
        PrDetector.isPrAgainst(
          priorHistory: const [],
          wodType: 'fran',
          newTotalSec: 180,
        ),
        isFalse,
      );
    });

    test('prior best 200, new 180 → true (단축)', () {
      expect(
        PrDetector.isPrAgainst(
          priorHistory: [_h('fran', 200, 0)],
          wodType: 'fran',
          newTotalSec: 180,
        ),
        isTrue,
      );
    });

    test('prior best 180, new 180 → false (strict less)', () {
      expect(
        PrDetector.isPrAgainst(
          priorHistory: [_h('fran', 180, 0)],
          wodType: 'fran',
          newTotalSec: 180,
        ),
        isFalse,
      );
    });

    test('prior best 180, new 200 → false (느림)', () {
      expect(
        PrDetector.isPrAgainst(
          priorHistory: [_h('fran', 180, 0)],
          wodType: 'fran',
          newTotalSec: 200,
        ),
        isFalse,
      );
    });

    test('prior 다중 best 결정 — 200, 170, 190 중 170 → new 165 PR', () {
      expect(
        PrDetector.isPrAgainst(
          priorHistory: [
            _h('fran', 200, 0),
            _h('fran', 170, 1),
            _h('fran', 190, 2),
          ],
          wodType: 'fran',
          newTotalSec: 165,
        ),
        isTrue,
      );
    });

    test('prior 다중 best 결정 — 170 → new 175 PR 아님', () {
      expect(
        PrDetector.isPrAgainst(
          priorHistory: [
            _h('fran', 200, 0),
            _h('fran', 170, 1),
            _h('fran', 190, 2),
          ],
          wodType: 'fran',
          newTotalSec: 175,
        ),
        isFalse,
      );
    });

    test('서로 다른 wod_type — fran prior best 무관, helen 첫 기록 → false', () {
      expect(
        PrDetector.isPrAgainst(
          priorHistory: [_h('fran', 200, 0), _h('fran', 170, 1)],
          wodType: 'helen',
          newTotalSec: 300,
        ),
        isFalse,
      );
    });

    test('newTotalSec ≤ 0 → false (의미 없음)', () {
      expect(
        PrDetector.isPrAgainst(
          priorHistory: [_h('fran', 200, 0)],
          wodType: 'fran',
          newTotalSec: 0,
        ),
        isFalse,
      );
      expect(
        PrDetector.isPrAgainst(
          priorHistory: [_h('fran', 200, 0)],
          wodType: 'fran',
          newTotalSec: -1,
        ),
        isFalse,
      );
    });

    test('빈 wodType → false (분류 불가)', () {
      expect(
        PrDetector.isPrAgainst(
          priorHistory: [_h('fran', 200, 0)],
          wodType: '',
          newTotalSec: 150,
        ),
        isFalse,
      );
      expect(
        PrDetector.isPrAgainst(
          priorHistory: [_h('fran', 200, 0)],
          wodType: '   ',
          newTotalSec: 150,
        ),
        isFalse,
      );
    });

    test('대소문자/공백 정규화 — FRAN vs fran 동일', () {
      expect(
        PrDetector.isPrAgainst(
          priorHistory: [_h('fran', 200, 0)],
          wodType: 'FRAN',
          newTotalSec: 180,
        ),
        isTrue,
      );
      expect(
        PrDetector.isPrAgainst(
          priorHistory: [_h(' Fran ', 200, 0)],
          wodType: 'fran',
          newTotalSec: 180,
        ),
        isTrue,
      );
    });

    test('estimatedTotalSec null 인 prior 항목 skip', () {
      final priorWithNull = [
        WodHistoryItem(
          id: 1,
          wodType: 'fran',
          notes: '',
          createdAt: DateTime(2026, 1, 1),
          // estimatedTotalSec: null (생략)
        ),
        _h('fran', 200, 1),
      ];
      expect(
        PrDetector.isPrAgainst(
          priorHistory: priorWithNull,
          wodType: 'fran',
          newTotalSec: 180,
        ),
        isTrue, // 200 만 유효 best → 180 < 200 PR
      );
    });
  });
}
