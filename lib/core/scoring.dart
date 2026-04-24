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

/// v1.15.3: Tier 기반 CrossFit 커뮤니티 근사 백분위.
///
/// 진짜 percentile은 population data가 필요. 여기서는 Tier 구조를
/// 공개 등급 분포(Open·Quarterfinal 통계 근사)에 매핑해 추정값 반환.
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
String formatTopPercent(double topPercent) {
  if (topPercent < 1.0) return 'Top <1%';
  return 'Top ${topPercent.round()}%';
}
