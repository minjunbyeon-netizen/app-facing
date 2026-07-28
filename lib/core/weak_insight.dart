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
  // v1.29: 카피 한글 기본 (DESIGN-SSOT §7) — 도메인 용어만 영문 유지.
  switch (category) {
    case 'POWER':
      return '$score/100 — SBD·OHP 1RM 부족. '
          '우선순위: Back Squat 1.5×체중, Deadlift 2.0×체중.';
    case 'OLYMPIC':
      return '$score/100 — Clean·Snatch 기술 정체. '
          '가벼운 중량 Tall 드릴 + 포지션 반복.';
    case 'GYMNASTICS':
      return '$score/100 — Pull-up·HSPU Max UB 낮음. '
          'Strict 볼륨 주 3회. Ring/Bar MU 진행 점검.';
    case 'CARDIO':
      return '$score/100 — Engine 용량 낮음. '
          'Z2 베이스 주 2회 + 매월 Row 2K 타임 트라이얼.';
    case 'METCON':
      return '$score/100 — 1분 최대 출력 약함. '
          'Burpee · DU · Wall Ball 분당 테스트 주기적으로.';
    case 'BODY':
      return '$score/100 — 체성분 개선 필요. '
          'InBody 점수 · 골격근 비율 · 체지방률 최적화.';
    default:
      return '$score/100 — 약점 카테고리 보강 필요.';
  }
}

String _balancedComment(int avg) {
  if (avg >= 80) {
    return '전 카테고리 80+ — Complete Athlete 구간.\n'
        'Elite 존 도달. 상위 3개 카테고리 피킹 전략.';
  }
  if (avg >= 60) {
    return '카테고리 균형. 뚜렷한 약점 없음. '
        '전체 강도 5% 또는 볼륨 10% 증량.';
  }
  return '카테고리 균형이나 절대값 낮음. '
      '주 3회 세션 + 월 1회 벤치마크.';
}
