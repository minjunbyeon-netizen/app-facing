// v1.16 Sprint 7b U4: 약점 카테고리 자동 강조 + mock AI 코멘트.
// UX_QUESTIONS_v1.16 Category N 대응 (P4·P5·P6·P7 공통 요구).
// ⚠️ **가상 데이터** — 코멘트 템플릿 5종 하드코딩. 실제 AI 모델 연결은 Phase 2.

class WeakInsight {
  final String weakestCategory; // 'POWER'·'OLYMPIC'·... 또는 'BALANCED'
  final int weakestScore100; // 0~100
  final String comment; // 한글 코멘트 2~3줄

  const WeakInsight({
    required this.weakestCategory,
    required this.weakestScore100,
    required this.comment,
  });
}

/// 카테고리 scores (0~100) → 가장 약한 카테고리 + mock 코멘트.
/// 모든 값이 비슷(표준편차 < 10)하면 BALANCED 반환.
WeakInsight? analyzeWeakness(Map<String, int> scoresByCategory) {
  if (scoresByCategory.isEmpty) return null;
  if (scoresByCategory.values.every((v) => v == 0)) return null;

  // 약점 카테고리 = 최저값.
  String weakKey = scoresByCategory.keys.first;
  int weakVal = scoresByCategory[weakKey]!;
  for (final e in scoresByCategory.entries) {
    if (e.value < weakVal) {
      weakKey = e.key;
      weakVal = e.value;
    }
  }

  // 균형 체크 — 표준편차 유사.
  final values = scoresByCategory.values.toList();
  final avg = values.reduce((a, b) => a + b) / values.length;
  final variance = values
          .map((v) => (v - avg) * (v - avg))
          .reduce((a, b) => a + b) /
      values.length;
  final std = variance <= 0 ? 0.0 : _sqrt(variance);

  if (std < 8) {
    return WeakInsight(
      weakestCategory: 'BALANCED',
      weakestScore100: weakVal,
      comment: _balancedComment(avg.round()),
    );
  }

  return WeakInsight(
    weakestCategory: weakKey,
    weakestScore100: weakVal,
    comment: _weakComment(weakKey, weakVal),
  );
}

double _sqrt(double x) {
  // dart:math 없이 sqrt — 단순 근사 (Newton's method 10회)
  if (x <= 0) return 0;
  double g = x;
  for (int i = 0; i < 10; i++) {
    g = 0.5 * (g + x / g);
  }
  return g;
}

/// ⚠️ **가상 데이터**: 카테고리별 mock 코멘트 5종.
/// 실제 AI 모델 (Claude/GPT 등) 연결 시 이 함수 대체.
String _weakComment(String category, int score) {
  switch (category) {
    case 'POWER':
      return '$score/100 — SBD + OHP 1RM weak. '
          'Priority: BS 1.5×BW, DL 2.0×BW.\n'
          '(Sample comment · Real AI analysis Phase 2)';
    case 'OLYMPIC':
      return '$score/100 — Clean/Snatch technique plateau. '
          'Light weight Tall drills + position reps.\n'
          '(Sample comment · Real AI analysis Phase 2)';
    case 'GYMNASTICS':
      return '$score/100 — Pull-up/HSPU Max UB low. '
          'Strict volume 3×/week. Check Ring/Bar MU progression.\n'
          '(Sample comment · Real AI analysis Phase 2)';
    case 'CARDIO':
      return '$score/100 — Engine capacity low. '
          'Z2 base 2×/week + Row 2K time trial monthly.\n'
          '(Sample comment · Real AI analysis Phase 2)';
    case 'METCON':
      return '$score/100 — 1-min max output weak. '
          'Burpee · DU · Wall Ball per-min tests periodic.\n'
          '(Sample comment · Real AI analysis Phase 2)';
    case 'BODY':
      return '$score/100 — Body composition needs work. '
          'InBody Score / SMM ratio / BF% optimization.\n'
          '(Sample comment · Real AI analysis Phase 2)';
    default:
      return '$score/100 — Weak category improvement needed.\n'
          '(Sample comment · Real AI analysis Phase 2)';
  }
}

String _balancedComment(int avg) {
  if (avg >= 80) {
    return 'All categories 80+ — Complete Athlete tier.\n'
        'Elite zone reached. Top 3 categories peaking strategy.\n'
        '(Sample comment · Real AI analysis Phase 2)';
  }
  if (avg >= 60) {
    return 'Categories balanced. No dramatic weakness. '
        'Increase total intensity 5% or volume 10%.\n'
        '(Sample comment · Real AI analysis Phase 2)';
  }
  return 'Categories balanced but absolute values low. '
      '3 sessions/week + monthly benchmark.\n'
      '(Sample comment · Real AI analysis Phase 2)';
}
