// v1.20 Phase 2: Panel B 칭호 카탈로그 단위 테스트.

import 'package:flutter_test/flutter_test.dart';
import 'package:facing_app/core/titles_catalog.dart';

void main() {
  group('Panel B catalog', () {
    test('총 20개 칭호', () {
      expect(kPanelBTitles.length, 20);
    });

    test('각 code 고유', () {
      final codes = kPanelBTitles.map((t) => t.code).toSet();
      expect(codes.length, 20);
    });

    test('rarity 분포 — Common 6 / Rare 8 / Epic 4 / Legendary 2', () {
      final by = <String, int>{};
      for (final t in kPanelBTitles) {
        by[t.rarity] = (by[t.rarity] ?? 0) + 1;
      }
      expect(by['Common'], 6);
      expect(by['Rare'], 8);
      expect(by['Epic'], 4);
      expect(by['Legendary'], 2);
    });

    test('모든 라벨 영문 단독 (한글 미포함)', () {
      final hangulRe = RegExp(r'[ㄱ-ㅎ가-힣]');
      for (final t in kPanelBTitles) {
        expect(hangulRe.hasMatch(t.label), isFalse,
            reason: '${t.code} label 한글 포함: ${t.label}');
      }
    });

    test('captionKo 한글 포함 (V10 패턴)', () {
      final hangulRe = RegExp(r'[ㄱ-ㅎ가-힣]');
      for (final t in kPanelBTitles) {
        expect(hangulRe.hasMatch(t.captionKo), isTrue,
            reason: '${t.code} captionKo 한글 누락');
      }
    });
  });

  group('PanelBUnlocker', () {
    test('빈 signals → 해금 0', () {
      final out = PanelBUnlocker.unlockedCodes(const TitleUnlockSignals());
      expect(out, isEmpty);
    });

    test('100세션 → THE GRINDER', () {
      final out = PanelBUnlocker.unlockedCodes(
        const TitleUnlockSignals(totalSessions: 100),
      );
      expect(out, contains('PB_GRINDER'));
    });

    test('99세션 → 미해금', () {
      final out = PanelBUnlocker.unlockedCodes(
        const TitleUnlockSignals(totalSessions: 99),
      );
      expect(out, isNot(contains('PB_GRINDER')));
    });

    test('Snatch 100kg → SNATCH KING (Legendary)', () {
      final out = PanelBUnlocker.unlockedCodes(
        const TitleUnlockSignals(snatch1rmKg: 100.5),
      );
      expect(out, contains('PB_SNATCH_KING'));
    });

    test('Fran 179초 → THRUSTER LORD, 180초는 미해금', () {
      expect(
        PanelBUnlocker.unlockedCodes(
            const TitleUnlockSignals(franSec: 179)),
        contains('PB_THRUSTER'),
      );
      expect(
        PanelBUnlocker.unlockedCodes(
            const TitleUnlockSignals(franSec: 180)),
        isNot(contains('PB_THRUSTER')),
      );
    });

    test('복합 signals → 다중 해금', () {
      final out = PanelBUnlocker.unlockedCodes(
        const TitleUnlockSignals(
          totalSessions: 100,
          benchmarkCount: 5,
          hasGym: true,
          backSquat1rmKg: 200,
        ),
      );
      expect(out, containsAll(<String>[
        'PB_GRINDER',
        'PB_METRIC_DEVOTEE',
        'PB_BOX_MEMBER',
        'PB_HEAVY',
      ]));
    });
  });
}
