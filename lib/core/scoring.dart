/// v1.15.3: Engine 점수 스케일 변환 단일 진원지.
///
/// 백엔드 `overall_score` / 카테고리 score 는 1.0 ~ 6.0 스케일.
/// UI에는 0 ~ 100 만점으로 표기.
///
/// 공식: `((s - 1.0) / 5.0) * 100` → s=1→0, s=6→100.
/// 경계 밖은 clamp(0, 100).
int engineScoreTo100(dynamic raw) {
  if (raw is! num) return 0;
  final s = raw.toDouble();
  final pct = ((s - 1.0) / 5.0 * 100).round();
  return pct.clamp(0, 100);
}

/// ⚠️ **가상 데이터**: Tier 기반 근사 백분위.
///
/// v1.15.3: Tier 구조를 공개 등급 분포(Open·Quarterfinal 통계 근사)에
/// 매핑해 추정값 반환. **실제 유저 집계 아님**.
/// Phase 2에서 서버 `/api/v1/stats/distribution` 엔드포인트로 대체 예정.
///
/// 매핑:
///   - score 1.0 → 0%ile
///   - score 3.0 → 50%ile (RX 진입)
///   - score 4.0 → 80%ile (RX+ 진입)
///   - score 5.0 → 95%ile (Elite 진입)
///   - score 6.0 → 99.5%ile (Games)
///
/// 반환값은 "상위 X%" 표기에 쓰도록 `topPercent = 100 - percentile`.
/// 예) score 4.5 → percentile 87.5 → topPercent 12.5 → UI "Top 12%".
double engineScoreToTopPercent(dynamic raw) {
  if (raw is! num) return 100.0;
  final s = raw.toDouble().clamp(1.0, 6.0);
  double pct;
  if (s >= 5.0) {
    pct = 95.0 + (s - 5.0) * 4.5; // 5→95, 6→99.5
  } else if (s >= 4.0) {
    pct = 80.0 + (s - 4.0) * 15.0; // 4→80, 5→95
  } else if (s >= 3.0) {
    pct = 50.0 + (s - 3.0) * 30.0; // 3→50, 4→80
  } else {
    pct = (s - 1.0) * 25.0; // 1→0, 3→50
  }
  return (100.0 - pct).clamp(0.1, 100.0);
}

/// "Top 12%" 표기용 라벨 — 값이 너무 작으면 "Top <1%".
/// ⚠️ 가상 근사값 (실제 유저 집계 아님).
String formatTopPercent(double topPercent) {
  if (topPercent < 1.0) return 'Top <1%';
  return 'Top ${topPercent.round()}%';
}

/// v1.16 Sprint 7b U5: 백분위 UI에 "가상" 명시 suffix.
String formatTopPercentMock(double topPercent) {
  return '${formatTopPercent(topPercent)} · mock';
}

/// v1.16 버그 fix: 백엔드 grade 문자열 → number(1~6) fallback.
/// 백엔드가 `number`를 안 주거나 구버전 gradeResult 저장본일 때 사용.
///
/// 백엔드 grading.py `GRADES` 순서와 일치:
/// scaled=1, beginner=2, intermediate=3, rxd=4, advanced=5, elite=6.
int gradeStringToNumber(dynamic raw) {
  if (raw is! String) return 1;
  switch (raw.toLowerCase()) {
    case 'elite':
      return 6;
    case 'advanced':
      return 5;
    case 'rxd':
    case 'rx':
      return 4;
    case 'intermediate':
      return 3;
    case 'beginner':
      return 2;
    case 'scaled':
    default:
      return 1;
  }
}

/// 카테고리 dict에서 number 해석. 우선순위: number(num) → score(1~6 round) → grade(str) → 1.
int resolveCategoryNumber(Map data) {
  final rawNum = data['number'];
  if (rawNum is num) return rawNum.round().clamp(1, 6);
  final rawScore = data['score'];
  if (rawScore is num) {
    return rawScore.round().clamp(1, 6);
  }
  return gradeStringToNumber(data['grade']);
}

/// v1.16 Sprint 7a: 연령 → Masters 분류 (WMA 2023 기준 차용).
/// 35+ : Masters 35-44 / 45+ : Masters 45-54 / 55+ : Masters 55-64 / 65+ : Masters 65+.
/// null or <35: null 반환 (일반 Open 분류).
String? mastersCategory(num? ageYears) {
  if (ageYears == null) return null;
  final age = ageYears.toInt();
  if (age >= 65) return '65+';
  if (age >= 55) return '55+';
  if (age >= 45) return '45+';
  if (age >= 35) return '35+';
  return null;
}

/// Masters 라벨 (UI 배지용).
String? mastersLabel(num? ageYears) {
  final cat = mastersCategory(ageYears);
  if (cat == null) return null;
  return 'MASTERS $cat';
}
