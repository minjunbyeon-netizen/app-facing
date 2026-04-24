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
