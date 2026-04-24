// v1.16 Sprint 14: Level / XP 시스템 — Panel A 기조 + 로컬 계산.
//
// ⚠️ XP는 현재 ProfileState / HistoryRepository의 기존 데이터로 **파생 계산**.
//    백엔드 컬럼 추가 없이 앱 내부에서 산출 (Phase 2에서 user.experience_points 도입).
//
// XP 소스 (MVP):
//  - 세션 완료: +100 per WOD history record
//  - Streak 유지: +50 per day (현재 streak)
//  - Tier 승급: +500 × overall_number (누적 보너스)
//  - 주간 목표 챌린지: +300 × 달성 주수 (이번 세션은 계산 생략)
//
// Level 1~50 하이브리드 곡선:
//   Lv1~20 선형: cumulative = 500 * L
//   Lv21~50 이차: cumulative = 500 * L^2 / 30
//
// 두 구간 연결점 (Lv20): 500×20 = 10,000. 이차식에서 L=20일 때 500×400/30 ≈ 6,667 — 연결성 확보 위해 보정.
// 실용적으로: Lv1~20은 linear 500/레벨, Lv21~50은 추가 (L-20)²×40 식 누적.

class LevelSystem {
  // 레벨별 누적 XP 임계.
  static const int maxLevel = 50;

  /// 해당 레벨 도달에 필요한 누적 XP.
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    if (level <= 20) {
      return 500 * (level - 1);
    }
    // Lv20 누적 9,500 (500×19). 이후 (L-20)²×40 추가.
    final base = 500 * 19; // 9500
    final extra = (level - 20) * (level - 20) * 40;
    return base + extra;
  }

  /// 누적 XP → 현재 Level.
  static int levelFromXp(int xp) {
    if (xp < 0) return 1;
    for (int l = maxLevel; l >= 1; l--) {
      if (xp >= xpForLevel(l)) return l;
    }
    return 1;
  }

  /// 다음 레벨까지 필요한 XP (남은 수).
  static int xpToNextLevel(int xp) {
    final current = levelFromXp(xp);
    if (current >= maxLevel) return 0;
    return xpForLevel(current + 1) - xp;
  }

  /// 현재 레벨 내 진행률 0~1.
  static double levelProgress(int xp) {
    final current = levelFromXp(xp);
    if (current >= maxLevel) return 1.0;
    final currentCumulative = xpForLevel(current);
    final nextCumulative = xpForLevel(current + 1);
    final span = nextCumulative - currentCumulative;
    if (span <= 0) return 1.0;
    return ((xp - currentCumulative) / span).clamp(0.0, 1.0);
  }

  /// MVP: 세션 수 · streak · tier number · weekly goal 달성 주수로 총 XP 계산.
  static LevelXpBreakdown compute({
    required int totalSessions,
    required int currentStreakDays,
    required int tierNumber,
    int weeklyGoalHitWeeks = 0,
  }) {
    final sessionXp = totalSessions * 100;
    final streakXp = currentStreakDays * 50;
    final tierXp = (tierNumber.clamp(0, 6)) * 500;
    final weeklyXp = weeklyGoalHitWeeks * 300;
    final total = sessionXp + streakXp + tierXp + weeklyXp;
    return LevelXpBreakdown(
      sessionXp: sessionXp,
      streakXp: streakXp,
      tierXp: tierXp,
      weeklyXp: weeklyXp,
      totalXp: total,
      level: levelFromXp(total),
      progress: levelProgress(total),
      xpToNext: xpToNextLevel(total),
    );
  }
}

class LevelXpBreakdown {
  final int sessionXp;
  final int streakXp;
  final int tierXp;
  final int weeklyXp;
  final int totalXp;
  final int level;
  final double progress;
  final int xpToNext;

  const LevelXpBreakdown({
    required this.sessionXp,
    required this.streakXp,
    required this.tierXp,
    required this.weeklyXp,
    required this.totalXp,
    required this.level,
    required this.progress,
    required this.xpToNext,
  });
}
