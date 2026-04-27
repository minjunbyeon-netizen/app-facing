// v1.20 Phase 2.5: EngineDecay 단위 테스트.
// reference/gamification.md §3-3 정책 회귀.

import 'package:flutter_test/flutter_test.dart';
import 'package:facing_app/core/engine_decay.dart';

void main() {
  group('EngineDecay.decayFactor — 곡선 경계', () {
    test('30일 이하 → 0% (decay 없음)', () {
      expect(EngineDecay.decayFactor(0), 0.0);
      expect(EngineDecay.decayFactor(15), 0.0);
      expect(EngineDecay.decayFactor(30), 0.0);
    });

    test('60일 → ~3%', () {
      expect(EngineDecay.decayFactor(60), closeTo(0.03, 0.001));
    });

    test('90일 → ~6%', () {
      expect(EngineDecay.decayFactor(90), closeTo(0.06, 0.001));
    });

    test('180일 → 15% (캡 진입 직전)', () {
      expect(EngineDecay.decayFactor(180), closeTo(0.15, 0.001));
    });

    test('180일 초과 → 20% 캡', () {
      expect(EngineDecay.decayFactor(181), 0.20);
      expect(EngineDecay.decayFactor(365), 0.20);
      expect(EngineDecay.decayFactor(10000), 0.20);
    });
  });

  group('EngineDecay.applyDecay — 점수 감산', () {
    test('decay 0% 구간 → 원본 그대로', () {
      expect(EngineDecay.applyDecay(80.0, 10), 80.0);
    });

    test('60일 시점 80점 → 80 × 0.97 = 77.6', () {
      expect(EngineDecay.applyDecay(80.0, 60), closeTo(77.6, 0.01));
    });

    test('365일 시점 100점 → 80 (20% 캡)', () {
      expect(EngineDecay.applyDecay(100.0, 365), closeTo(80.0, 0.001));
    });
  });

  group('EngineDecay.statusCaption / statusLabel', () {
    test('30일 이하 → null (표시 안 함)', () {
      expect(EngineDecay.statusCaption(0), isNull);
      expect(EngineDecay.statusCaption(30), isNull);
      expect(EngineDecay.statusLabel(30), isNull);
    });

    test('45일 → 무측정 안내 (감산 미표시)', () {
      final c = EngineDecay.statusCaption(45);
      expect(c, isNotNull);
      expect(c!.contains('45일'), isTrue);
      expect(c.contains('재측정'), isTrue);
      expect(EngineDecay.statusLabel(45), 'STALE');
    });

    test('120일 → 표시 점수 -X% 안내 포함', () {
      final c = EngineDecay.statusCaption(120);
      expect(c, isNotNull);
      expect(c!.contains('120일'), isTrue);
      expect(c.contains('표시 점수'), isTrue);
    });

    test('200일 → -20% 캡 안내', () {
      final c = EngineDecay.statusCaption(200);
      expect(c, isNotNull);
      expect(c!.contains('-20%'), isTrue);
      expect(c.contains('캡'), isTrue);
    });
  });
}
