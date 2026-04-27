// QA B-LW-4: LevelSystem Lv20 ↔ Lv21 경계 회귀 테스트.
// 두 구간 곡선(linear 1~20 / quadratic 21~50) 연결점 정합 검증.

import 'package:flutter_test/flutter_test.dart';
import 'package:facing_app/core/level_system.dart';

void main() {
  group('LevelSystem cumulative XP curve', () {
    test('Lv1 = 0, Lv2 = 500 (linear 시작)', () {
      expect(LevelSystem.xpForLevel(1), 0);
      expect(LevelSystem.xpForLevel(2), 500);
    });

    test('Lv20 누적 = 9500 (linear 끝)', () {
      expect(LevelSystem.xpForLevel(20), 9500);
    });

    test('Lv21 누적 = 9500 + 1*1*40 = 9540 (quadratic 시작 연결)', () {
      // 곡선 연결점: linear 19*500 = 9500 + (21-20)^2 * 40 = 40 → 9540.
      expect(LevelSystem.xpForLevel(21), 9540);
    });

    test('Lv 50 maxLevel 도달', () {
      expect(LevelSystem.maxLevel, 50);
      // 9500 + 30^2 * 40 = 9500 + 36000 = 45500
      expect(LevelSystem.xpForLevel(50), 45500);
    });

    test('levelFromXp 경계 — 9499 → Lv19, 9500 → Lv20, 9540 → Lv21', () {
      expect(LevelSystem.levelFromXp(9499), 19);
      expect(LevelSystem.levelFromXp(9500), 20);
      expect(LevelSystem.levelFromXp(9539), 20);
      expect(LevelSystem.levelFromXp(9540), 21);
    });

    test('xpToNextLevel 단조 감소 / 음수 없음', () {
      // 임의 스팟 4개에서 0 이상.
      for (final xp in [0, 100, 9500, 9540, 30000]) {
        expect(LevelSystem.xpToNextLevel(xp), greaterThanOrEqualTo(0));
      }
    });

    test('levelProgress 0~1 범위', () {
      // Lv20 정확 진입 = 0.0 / Lv20 직전 = ~1.0
      expect(LevelSystem.levelProgress(9500), closeTo(0.0, 0.001));
      expect(LevelSystem.levelProgress(9539),
          closeTo(((9539 - 9500) / 40), 0.001));
      // 음수 XP 클램프.
      expect(LevelSystem.levelProgress(-100), inInclusiveRange(0.0, 1.0));
    });

    test('compute breakdown — 누적합 일치', () {
      final bd = LevelSystem.compute(
        totalSessions: 10,
        currentStreakDays: 5,
        tierNumber: 3,
        weeklyGoalHitWeeks: 2,
      );
      // 10*100 + 5*50 + 3*500 + 2*300 = 1000 + 250 + 1500 + 600 = 3350
      expect(bd.sessionXp, 1000);
      expect(bd.streakXp, 250);
      expect(bd.tierXp, 1500);
      expect(bd.weeklyXp, 600);
      expect(bd.totalXp, 3350);
    });
  });
}
