// v1.16 Sprint 7a: Pacing 계산 근거 논문·공식 SSOT.
// UX_QUESTIONS_v1.16 Category G (데이터 신뢰) 대응.
// P2·P4·P6·P8 페르소나 공통 요구: "계산 근거·논문 공개".

class FormulaReference {
  final String title;
  final String authors;
  final String relevance;
  const FormulaReference({
    required this.title,
    required this.authors,
    required this.relevance,
  });
}

/// v1.16: Pacing/Split/Burst 핵심 근거 8개.
const List<FormulaReference> kFormulaReferences = [
  FormulaReference(
    title: 'Central Governor Model',
    authors: 'Noakes (2004, 2012)',
    relevance: 'Burst 구간·후반 85% W-prime 전소 허용 근거.',
  ),
  FormulaReference(
    title: 'W-prime Balance Model',
    authors: 'Skiba et al. (2012)',
    relevance: '분할·휴식 회복 계산. 근지구력 capacity.',
  ),
  FormulaReference(
    title: 'Descending Split Strategy',
    authors: 'Abbiss & Laursen (2008)',
    relevance: '내림차순 분할 · AMRAP 균등 페이싱.',
  ),
  FormulaReference(
    title: 'NSCA Strength Standards',
    authors: 'National Strength & Conditioning Association',
    relevance: '체중 대비 1RM 비율 Tier 기준 (Back Squat·Bench 등).',
  ),
  FormulaReference(
    title: 'Catalyst Athletics Olympic Ratios',
    authors: 'Greg Everett',
    relevance: 'Clean·Snatch BW 비율 권고치.',
  ),
  FormulaReference(
    title: 'Concept2 World Rowing Standards',
    authors: 'Concept2 Ltd.',
    relevance: 'Row 500m·2km 페이스 Tier 임계값.',
  ),
  FormulaReference(
    title: 'WMA Age Grading Factor 2023',
    authors: 'World Masters Athletics',
    relevance: 'Masters 연령 보정 계수 (35+/45+/55+).',
  ),
  FormulaReference(
    title: 'CrossFit Games Open Statistics',
    authors: 'CrossFit Inc. (2022~2024)',
    relevance: 'Metcon 1분 max·Games Tier 기준 영상 분석.',
  ),
];

/// 짧은 카테고리별 기여도 설명.
String categoryContribution(String category) {
  switch (category.toLowerCase()) {
    case 'power':
      return 'SBD · OHP 1RM 대비 체중 비율 가중 평균.';
    case 'olympic':
      return 'Clean · Snatch · C&J · Power Clean · Power Snatch BW 비율.';
    case 'gymnastics':
      return 'Pull-up · HSPU · MU · T2B Max UB 개수 + Strict 가중.';
    case 'cardio':
      return 'Run · Row · Cooper · 500m pace 기준 임계값.';
    case 'metcon':
      return '1분 max (Burpee · DU · KB · Wall Ball) + 멘탈 bonus.';
    case 'weightlifting':
      return 'Power + Olympic 평균 (v1.10 이후 deprecated).';
    default:
      return '6 카테고리 가중 평균.';
  }
}
