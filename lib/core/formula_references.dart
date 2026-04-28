// v3.0 (2026-04-29): SSOT를 ~/.claude/reference/study/fitness/ 5 sub-file 로 통합.
// 폐기: services/facing/docs/refer/* (38 파일) + 단일 fitness.md 시절 인용.
// fitness/ 5 sub-file = Tier 1+2 통합, 290 출처, T1 50%+:
//   - power.md (Strength Level 2024 / OpenPowerlifting / IPF / Sayers)
//   - olympic-lifting.md (IWF / strengthlevel.com / Catalyst Athletics / KWA)
//   - cardio.md (ACSM 11th / Cooper Institute / Daniels VDOT / Karvonen / Tanaka)
//   - gymnastics.md (USMC PFT / ACFT / FIG / GymnasticBodies / Steven Low OG)
//   - physical-norms.md (NHANES / NIH Toolbox / KCDC / KSPO 국민체력100)

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

/// fitness/ 5 sub-file SSOT 기반 reference 8개.
const List<FormulaReference> kFormulaReferences = [
  FormulaReference(
    title: 'Strength Level 2024 — Lift Standards Database',
    authors: 'Strength Level (100M+ aggregated lifts)',
    relevance: '체중 대비 1RM 비율 5-tier (Beginner=5th → Elite=95th percentile).',
    section: 'fitness/power.md §A3 (Tier 2)',
  ),
  FormulaReference(
    title: 'IPF Bylaws + DOTS Coefficients 2020',
    authors: 'International Powerlifting Federation + OpenPowerlifting',
    relevance: '파워리프팅 점수 보정 (Wilks → DOTS → IPF GL). 체급 간 비교 SSOT.',
    section: 'fitness/power.md §A4 (Tier 1)',
  ),
  FormulaReference(
    title: 'IWF Technical Rules 2025 + World Records',
    authors: 'International Weightlifting Federation (iwf.sport)',
    relevance: 'Snatch/C&J protocol + 세계기록 (Lasha 225/267/492 +109).',
    section: 'fitness/olympic-lifting.md §3, §5 (Tier 1)',
  ),
  FormulaReference(
    title: 'ACSM Guidelines 11th ed. + Cooper Institute',
    authors: 'American College of Sports Medicine (2021) + Cooper KH (JAMA 1968)',
    relevance: 'VO2max percentile (연령·성별 6 군) + Cooper 12-min 식 = 22.351×km−11.288.',
    section: 'fitness/cardio.md §3, §7 (Tier 1)',
  ),
  FormulaReference(
    title: 'Daniels VDOT + Karvonen HRR + Tanaka HRmax',
    authors: 'Daniels & Gilbert 1979 / Karvonen 1957 / Tanaka 2001 (JACC PMID 11153730)',
    relevance: '레이스 페이스 → 트레이닝 zone 5단계 (E/M/T/I/R) + 개인화 target HR.',
    section: 'fitness/cardio.md §4, §5 (Tier 1)',
  ),
  FormulaReference(
    title: 'USMC PFT + US Army ACFT Scoring',
    authors: 'MARADMIN 595/22 (marines.mil) + army.mil',
    relevance: 'Pull-up 23=max points / HRP 60=100pts. 군 표준 reps.',
    section: 'fitness/gymnastics.md §2 (Tier 1)',
  ),
  FormulaReference(
    title: 'Sayers Power + Wingate Anaerobic',
    authors: 'Sayers et al. 1999 (PMID:10331897) + Inbar/Bar-Or/Skinner 1996',
    relevance: '수직점프 → Peak Power(W) 환산 + 30s anaerobic W/kg 5-tier.',
    section: 'fitness/power.md §B1, §B4 (Tier 1)',
  ),
  FormulaReference(
    title: 'Central Governor + W-prime Balance',
    authors: 'Noakes (2004, 2012) + Skiba et al. (2012)',
    relevance: 'Burst 후반 W-prime 85% 전소 + 분할/휴식 회복 (Pacing 전용).',
    section: 'PMC + JAP (Tier 1, fitness/ 미수록)',
  ),
];

/// 카테고리별 기여도 설명 (fitness/ sub-file 매핑).
String categoryContribution(String category) {
  switch (category.toLowerCase()) {
    case 'power':
      return 'BS·DL·Bench·OHP·FS 1RM 대비 BW 비율 (power.md §A3 Strength Level 95th%ile).';
    case 'olympic':
      return 'Snatch·C&J·Power Clean BW 비율 (olympic-lifting.md §5–6 strengthlevel.com + IWF).';
    case 'gymnastics':
      return 'Pull-up·HSPU·MU·Push-up Max UB (gymnastics.md §2 USMC PFT + ACFT).';
    case 'cardio':
      return 'Run·Row·Cooper 페이스 (cardio.md §3 Cooper, §5 Daniels VDOT).';
    case 'metcon':
      return '1분 max (Burpee·DU·KB·Wall Ball) — CrossFit Games 영상 분석 추정.';
    case 'weightlifting':
      return 'Power + Olympic 평균 (deprecated v1.10+).';
    default:
      return '6 카테고리 가중 평균 (fitness/ 5 sub-file SSOT).';
  }
}
