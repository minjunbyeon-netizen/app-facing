// v1.20 Phase 2: StreakFreezeStore 단위 테스트.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facing_app/core/streak_freeze.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('StreakFreezeStore', () {
    test('초기 상태 — 사용 가능', () async {
      expect(await StreakFreezeStore.available(), isTrue);
    });

    test('consume 1회 후 같은 주에는 사용 불가', () async {
      final mon = DateTime(2026, 4, 27); // Mon
      expect(await StreakFreezeStore.consume(now: mon), isTrue);
      // 같은 주 수요일에는 false.
      expect(
        await StreakFreezeStore.available(now: DateTime(2026, 4, 29)),
        isFalse,
      );
      expect(
        await StreakFreezeStore.consume(now: DateTime(2026, 4, 29)),
        isFalse,
      );
    });

    test('다음 주 월요일에는 다시 사용 가능', () async {
      final thisMon = DateTime(2026, 4, 27);
      await StreakFreezeStore.consume(now: thisMon);
      final nextMon = DateTime(2026, 5, 4);
      expect(await StreakFreezeStore.available(now: nextMon), isTrue);
      expect(await StreakFreezeStore.consume(now: nextMon), isTrue);
    });

    test('nextRefill — 화요일 → 다음 월요일 (5/4)', () {
      final tue = DateTime(2026, 4, 28);
      final next = StreakFreezeStore.nextRefill(tue);
      expect(next.weekday, DateTime.monday);
      expect(next.year, 2026);
      expect(next.month, 5);
      expect(next.day, 4);
    });

    test('nextRefill — 월요일 → 다다음 월요일 (오늘 사용 가정)', () {
      final mon = DateTime(2026, 4, 27);
      final next = StreakFreezeStore.nextRefill(mon);
      expect(next.weekday, DateTime.monday);
      expect(next.month, 5);
      expect(next.day, 4);
    });

    test('reset 후 다시 사용 가능', () async {
      await StreakFreezeStore.consume(now: DateTime(2026, 4, 27));
      await StreakFreezeStore.reset();
      expect(await StreakFreezeStore.available(now: DateTime(2026, 4, 27)),
          isTrue);
    });
  });
}
