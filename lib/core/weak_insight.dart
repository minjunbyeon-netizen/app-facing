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
      return '$score/100 — SBD + OHP 1RM 보강. '
          '체중 대비 Back Squat 1.5x, Deadlift 2.0x 우선.\n'
          '(샘플 코멘트 — 실제 AI 분석은 Phase 2)';
    case 'OLYMPIC':
      return '$score/100 — Clean·Snatch 기술 정체 신호. '
          '가벼운 무게로 Tall 드릴·Position 반복.\n'
          '(샘플 코멘트 — 실제 AI 분석은 Phase 2)';
    case 'GYMNASTICS':
      return '$score/100 — Pull-up·HSPU Max UB 부족. '
          'Strict + 볼륨 주 3회. Ring/Bar MU 단계 진입 체크.\n'
          '(샘플 코멘트 — 실제 AI 분석은 Phase 2)';
    case 'CARDIO':
      return '$score/100 — Engine 용량 부족. '
          'Z2 지속주 주 2회 + Row 2K 타임 트라이얼 월 1회.\n'
          '(샘플 코멘트 — 실제 AI 분석은 Phase 2)';
    case 'METCON':
      return '$score/100 — 1분 max 출력 부족. '
          'Burpee·DU·Wall Ball 분당 max 테스트 주기적 체크.\n'
          '(샘플 코멘트 — 실제 AI 분석은 Phase 2)';
    default:
      return '$score/100 — 약점 카테고리 개선 필요.\n'
          '(샘플 코멘트 — 실제 AI 분석은 Phase 2)';
  }
}

String _balancedComment(int avg) {
  if (avg >= 80) {
    return '모든 카테고리 80+ — Complete Athlete 수준.\n'
        'Elite 구간 진입. 상위 3 카테고리 Peaking 전략 고려.\n'
        '(샘플 코멘트 — 실제 AI 분석은 Phase 2)';
  }
  if (avg >= 60) {
    return '전 카테고리 균형. 극적 약점 없음. '
        '전체 강도 5% 상향 또는 볼륨 10% 상향.\n'
        '(샘플 코멘트 — 실제 AI 분석은 Phase 2)';
  }
  return '전 카테고리 균형이나 절대값 낮음. '
      '주 3회 기본 프로그래밍 + 벤치마크 월 1회.\n'
      '(샘플 코멘트 — 실제 AI 분석은 Phase 2)';
}
