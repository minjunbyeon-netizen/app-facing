// v2.0 (2026-04-28): SSOT를 ~/.claude/reference/study/fitness.md 로 통합.
// 폐기: services/facing/docs/refer/* (10개 카테고리, 38 파일 일괄 삭제).
// fitness.md = Tier 1+2 통합 (ACSM, NHANES, Cooper Institute, NSCA, ExRx, Strength Level,
// IWF, World Athletics, openpowerlifting, crossfit.com, WMA).

class FormulaReference {
  final String title;
  final String authors;
  final String relevance;
  final String section;
  const FormulaReference({
    required this.title,
    required this.authors,
    required this.relevance,
    required this.section,
  });
}

/// fitness.md 단일 SSOT 기반 reference 8개.
const List<FormulaReference> kFormulaReferences = [
  FormulaReference(
    title: 'ACSM Health-Related Physical Fitness Assessment Manual',
    authors: 'American College of Sports Medicine, 11th ed. (2024)',
    relevance: 'VO2max·근지구력·유연성 percentile 표준. Cooper 12-min run.',
    section: 'fitness.md §3 (Tier 1)',
  ),
  FormulaReference(
    title: 'NHANES + FRIEND Registry',
    authors: 'CDC NHANES 2011–2014 + FRIEND (n=7,800) + Cooper Institute Longitudinal',
    relevance: '연령·성별 VO2max·grip strength percentile 모집단 norm.',
    section: 'fitness.md §3.1, §3.2, §3.7 (Tier 1)',
  ),
  FormulaReference(
    title: 'ExRx + Strength Level + USAW Strength Standards',
    authors: 'ExRx.net + strengthlevel.com (n>10⁵) + USA Weightlifting',
    relevance: '체중 대비 1RM 비율 (Untrained/Novice/Intermediate/Advanced/Elite).',
    section: 'fitness.md §4 (Tier 2)',
  ),
  FormulaReference(
    title: 'Run Pace Standards by Level',
    authors: 'World Athletics + Running Level + Runners Connect',
    relevance: 'Mile/5K/Marathon 페이스 (Recreational→Elite/world).',
    section: 'fitness.md §5.3 (Tier 1+2)',
  ),
  FormulaReference(
    title: 'Karvonen 5-Zone Heart Rate',
    authors: 'Karvonen et al. 1957 + ACSM',
    relevance: 'HR target = HRrest + intensity × (HRmax − HRrest). 페이싱 zone 매핑.',
    section: 'fitness.md §5.4 (Tier 1)',
  ),
  FormulaReference(
    title: 'Central Governor + W-prime Balance',
    authors: 'Noakes (2004, 2012) + Skiba et al. (2012)',
    relevance: 'Burst 후반 W-prime 85% 전소 + 분할/휴식 회복 계산.',
    section: 'PMC + JAP (Tier 1, fitness.md 미수록 — pacing 전용)',
  ),
  FormulaReference(
    title: 'IWF World Records + Powerlifting WR',
    authors: 'iwf.sport + openpowerlifting.org',
    relevance: 'Olympic·Powerlifting 역대 max — Lasha 225kg snatch +109 (2.06× BW).',
    section: 'fitness.md §6.1, §6.3 (Tier 1+2)',
  ),
  FormulaReference(
    title: 'WMA Age Grading Factor 2023',
    authors: 'World Masters Athletics',
    relevance: 'Masters 35+/45+/55+ 연령 보정 (cardio 임계값 1/factor 완화).',
    section: 'worldmastersathletics.org (Tier 1, fitness.md 미수록)',
  ),
];

/// 카테고리별 기여도 설명 (fitness.md 섹션 매핑).
String categoryContribution(String category) {
  switch (category.toLowerCase()) {
    case 'power':
      return 'BS·DL·Bench·OHP·FS 1RM 대비 BW 비율 (fitness.md §4.1–4.4).';
    case 'olympic':
      return 'Snatch·C&J·Clean·Power Clean·Power Snatch BW 비율 (fitness.md §4.5–4.8).';
    case 'gymnastics':
      return 'Pull-up·HSPU·MU·T2B Max UB + push-up (ACSM §3.3 정렬).';
    case 'cardio':
      return 'Run·Row·Cooper 페이스 (fitness.md §3.9, §5.3).';
    case 'metcon':
      return '1분 max (Burpee·DU·KB·Wall Ball) + 멘탈 보너스.';
    case 'weightlifting':
      return 'Power + Olympic 평균 (deprecated v1.10+).';
    default:
      return '6 카테고리 가중 평균 (fitness.md SSOT).';
  }
}
