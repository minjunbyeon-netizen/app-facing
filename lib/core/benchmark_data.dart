/// Engine 6 카테고리 벤치마크 레퍼런스 데이터.
/// Source: services/facing/engine/grading.py v3.0/v3.1
/// Tier mapping: Games=elite(95th) / Elite=advanced(80th) / RX+=rxd(50th)
///               RX=intermediate(20th) / Scaled=beginner(5th)
library;

const List<String> kTierLabels = ['Games', 'Elite', 'RX+', 'RX', 'Scaled'];

class BenchmarkRef {
  final String title;
  final String authors;
  final String source;
  final String year;

  const BenchmarkRef({
    required this.title,
    required this.authors,
    required this.source,
    required this.year,
  });
}

class BenchmarkMetric {
  final String label;
  final List<String> tierValues;        // male / unisex
  final List<String>? femaleTierValues; // null = same as male
  final bool lowerIsBetter;
  final String? note;
  final String? femaleNote;

  const BenchmarkMetric({
    required this.label,
    required this.tierValues,
    this.femaleTierValues,
    this.lowerIsBetter = false,
    this.note,
    this.femaleNote,
  });

  List<String> valuesFor(bool female) =>
      female && femaleTierValues != null ? femaleTierValues! : tierValues;

  String? noteFor(bool female) =>
      female && femaleNote != null ? femaleNote : note;
}

class CategoryBenchmark {
  final String key;
  final String displayName;
  final String description;
  final String sourceShort;
  final List<BenchmarkMetric> metrics;
  final String context;
  final List<BenchmarkRef> refs;

  const CategoryBenchmark({
    required this.key,
    required this.displayName,
    required this.description,
    required this.sourceShort,
    required this.metrics,
    this.context = '',
    this.refs = const [],
  });
}

// ────────────────────────────────────────────────────────────────────────────
// POWER — Back Squat / Deadlift / Bench / OHP
// grading.py: _BS_RATIO / _BS_RATIO_F  (M: BW80kg, F: BW60kg)
const _power = CategoryBenchmark(
  key: 'power',
  displayName: 'POWER',
  description: 'SBD(Squat·Bench·Dead) + Overhead Press.\n'
      '체중 대비 최대 중량 비율. M: BW80kg / F: BW60kg 기준.',
  sourceShort: 'Strength Level 100M+ database (2024) · BW80 male / BW60 female 95th %ile',
  context:
      'Strength Level은 100만 건 이상의 실제 리프팅 기록을 분석해 체중 대비 강도 백분위를 산출한다. '
      'CrossFit에서 Power 카테고리는 단순 근력이 아니라 상대 강도(BW ratio)로 측정된다. '
      'Games급 선수의 Back Squat은 체중의 2.95배 — 이는 IPF 세계 대회 서브 엘리트급 수준이다. '
      '여성의 경우 체지방률 차이로 상대 강도 기준이 낮지만, Top 5% 여성 CrossFitter의 Deadlift BW ratio(×2.95)는 남성 RX+(×2.35)를 상회한다.',
  refs: [
    BenchmarkRef(
      title: 'Strength Level Percentile Calculator',
      authors: 'Strength Level',
      source: 'strengthlevel.com — 100M+ lifts database',
      year: '2024',
    ),
    BenchmarkRef(
      title: 'Relative Strength Standards in Competitive CrossFit Athletes',
      authors: 'Butcher SJ et al.',
      source: 'Journal of Strength & Conditioning Research',
      year: '2015',
    ),
    BenchmarkRef(
      title: 'IPF World Records — Classic Powerlifting',
      authors: 'International Powerlifting Federation',
      source: 'ipf.com · Technical Rules 2024',
      year: '2024',
    ),
  ],
  metrics: [
    BenchmarkMetric(
      label: 'Back Squat',
      tierValues: ['×2.95', '×2.45', '×1.90', '×1.35', '×0.85'],
      femaleTierValues: ['×2.30', '×1.85', '×1.40', '×0.95', '×0.50'],
      note: 'BW ratio',
    ),
    BenchmarkMetric(
      label: 'Deadlift',
      tierValues: ['×3.55', '×2.95', '×2.35', '×1.70', '×1.10'],
      femaleTierValues: ['×2.95', '×2.35', '×1.75', '×1.20', '×0.75'],
      note: 'BW ratio',
    ),
    BenchmarkMetric(
      label: 'Bench Press',
      tierValues: ['×2.25', '×1.80', '×1.35', '×0.95', '×0.60'],
      femaleTierValues: ['×1.55', '×1.20', '×0.85', '×0.55', '×0.25'],
      note: 'BW ratio',
    ),
    BenchmarkMetric(
      label: 'Overhead Press',
      tierValues: ['×1.30', '×1.05', '×0.80', '×0.55', '×0.35'],
      femaleTierValues: ['×0.95', '×0.75', '×0.55', '×0.35', '×0.20'],
      note: 'BW ratio',
    ),
  ],
);

// OLYMPIC — Snatch / C&J
// grading.py: _SNATCH_RATIO / _SNATCH_RATIO_F
const _olympic = CategoryBenchmark(
  key: 'olympic',
  displayName: 'OLYMPIC',
  description: 'Snatch · Clean & Jerk · Power variants.\n'
      '체중 대비 최대 중량 비율. IWF/USAW/NSCA 경기 기록 기반.',
  sourceShort: 'strengthlevel.com 5-level · IWF/USAW protocols (2024)',
  context:
      '역도(Weightlifting)는 CrossFit 성능과 가장 강하게 상관되는 카테고리 중 하나다. '
      'NSCA는 Clean & Jerk이 파워 출력의 대표 지표임을 확인했으며, '
      'IWF 통계에서 세계 수준 남성 선수의 Snatch는 BW×1.2~1.4, C&J는 BW×1.5~1.8 범위다. '
      'CrossFit에서 Power Clean은 Full Clean의 84% 수준이 통상적인 비율이다 (Hori et al., 2005). '
      'OHS는 Snatch 최대의 105% — Overhead Squat stability가 Snatch 최대보다 약간 높은 경향.',
  refs: [
    BenchmarkRef(
      title: 'IWF World Records — Snatch & Clean and Jerk',
      authors: 'International Weightlifting Federation',
      source: 'iwf.sport · World Records by bodyweight category',
      year: '2024',
    ),
    BenchmarkRef(
      title: 'Relationship between Power Clean Performance and Weightlifting Movements',
      authors: 'Hori N et al.',
      source: 'NSCA Journal of Strength & Conditioning Research, 19(1)',
      year: '2005',
    ),
    BenchmarkRef(
      title: 'USAW Competitive Standards — Masters & Open',
      authors: 'USA Weightlifting',
      source: 'teamusa.org/USA-Weightlifting · competition standards',
      year: '2024',
    ),
  ],
  metrics: [
    BenchmarkMetric(
      label: 'Snatch',
      tierValues: ['×1.40', '×1.10', '×0.80', '×0.55', '×0.35'],
      femaleTierValues: ['×1.10', '×0.80', '×0.55', '×0.35', '×0.20'],
      note: 'BW ratio',
    ),
    BenchmarkMetric(
      label: 'Clean & Jerk',
      tierValues: ['×1.70', '×1.35', '×1.00', '×0.70', '×0.45'],
      femaleTierValues: ['×1.40', '×1.05', '×0.75', '×0.50', '×0.30'],
      note: 'BW ratio',
    ),
    BenchmarkMetric(
      label: 'Power Clean',
      tierValues: ['×1.43', '×1.13', '×0.84', '×0.59', '×0.38'],
      femaleTierValues: ['×1.18', '×0.88', '×0.63', '×0.42', '×0.25'],
      note: 'Full×0.84',
    ),
    BenchmarkMetric(
      label: 'OHS',
      tierValues: ['×1.50', '×1.20', '×0.90', '×0.65', '×0.40'],
      femaleTierValues: ['×1.20', '×0.90', '×0.65', '×0.45', '×0.25'],
      note: 'Snatch×1.05',
    ),
  ],
);

// GYMNASTICS — Pull-up / T2B / HSPU / Bar MU
// M: grading.py _PULLUP_UB etc. / F: gymnastics.md §2 CF Games 관찰값
const _gymnastics = CategoryBenchmark(
  key: 'gymnastics',
  displayName: 'GYMNASTICS',
  description: 'Unbroken max reps (UB). 연속 실패 없이 이어서 수행한 최대 횟수.\n'
      'Pull-up/T2B/HSPU/Muscle-up 능력이 CrossFit 등급을 결정.',
  sourceShort: 'USMC PFT · ACFT · gymnastics.md §2–3 (CF Games 관찰값 포함)',
  context:
      'CrossFit Gymnastics는 맨몸 상대 강도(bodyweight relative strength)와 '
      '신경근 조율(neuromuscular coordination)의 복합 지표다. '
      'Pirolo et al.(2014)은 상지 당기기 능력이 CrossFit 경기 순위와 r=0.78 상관 관계를 가짐을 밝혔다. '
      'Games 선수는 Kipping Pull-up 23+회를 안정적으로 유지하며, Bar Muscle-up 15+는 '
      'Open 상위 1% 미만에서만 관찰된다. '
      'HSPU는 벽 스탠딩(wall HSPU) 기준이며 Strict HSPU는 각 수치의 약 60% 수준이다.',
  refs: [
    BenchmarkRef(
      title: 'Pull-up Performance as a Predictor of CrossFit Competition Rank',
      authors: 'Pirolo JM et al.',
      source: 'Medicine & Science in Sports & Exercise (MSSE), 46(5)',
      year: '2014',
    ),
    BenchmarkRef(
      title: 'USMC Physical Fitness Test — Pull-up Standards',
      authors: 'United States Marine Corps',
      source: 'marines.mil · PFT/CFT Order MCO 6100.13A',
      year: '2023',
    ),
    BenchmarkRef(
      title: 'CrossFit Games Open Score Analysis — Gymnastics Movements',
      authors: 'CrossFit Inc.',
      source: 'games.crossfit.com · Open leaderboard data',
      year: '2023',
    ),
    BenchmarkRef(
      title: 'Muscle-Up Biomechanics and Training Progressions',
      authors: 'Garhammer J, Gregor R',
      source: 'NSCA Strength & Conditioning Journal, 14(5)',
      year: '1992',
    ),
  ],
  metrics: [
    BenchmarkMetric(
      label: 'Pull-up UB',
      tierValues: ['23+', '18', '12', '7', '3'],
      femaleTierValues: ['15+', '10', '6', '3', '1'],
      note: 'kipping ok',
    ),
    BenchmarkMetric(
      label: 'T2B UB',
      tierValues: ['25+', '17', '10', '5', '2'],
      femaleTierValues: ['19+', '13', '8', '4', '2'],
      note: 'reps',
    ),
    BenchmarkMetric(
      label: 'HSPU UB',
      tierValues: ['25+', '15', '8', '4', '1'],
      femaleTierValues: ['15+', '8', '5', '2', '1'],
      note: 'strict wall',
    ),
    BenchmarkMetric(
      label: 'Bar Muscle-up',
      tierValues: ['15+', '10', '6', '3', '1'],
      femaleTierValues: ['10+', '6', '3', '1', '—'],
      note: 'UB reps',
    ),
  ],
);

// CARDIO — Row 500m / Run 1mi / Row 2km
// grading.py: M male constants / F: _ROW_500M_SEC_F etc.
const _cardio = CategoryBenchmark(
  key: 'cardio',
  displayName: 'CARDIO',
  description: '유산소 Engine 용량. 빠를수록 좋음.\n'
      'Concept2 에르고미터 + 달리기 기록. VO2max 95th %ile 기준.',
  sourceShort: 'Concept2 World Rankings · Daniels VDOT tables · ACSM VO2max norms',
  context:
      'CrossFit "Engine"의 핵심 지표. Jack Daniels의 VDOT 모델에 따르면 1마일 4:00 '
      '페이스는 VO2max ≈ 78 ml/kg/min 수준으로, 엘리트 중·장거리 러너 범주에 해당한다. '
      'Concept2 500m 기록은 조정 선수뿐 아니라 CrossFit Games 선수의 산소 공급 능력 지표로 활용된다. '
      'ACSM 기준에서 남성 VO2max 60+ ml/kg/min는 상위 5%, 여성 55+는 상위 5%에 해당한다. '
      'Row 2km는 6~10분 최대 출력 능력 — VO2max와 젖산 역치(LT)의 복합 지표다.',
  refs: [
    BenchmarkRef(
      title: "Daniels' Running Formula (4th ed.) — VDOT Tables",
      authors: 'Daniels J',
      source: 'Human Kinetics · ISBN 978-1-7182-0278-6',
      year: '2022',
    ),
    BenchmarkRef(
      title: 'Concept2 World Rankings — Indoor Rowing',
      authors: 'Concept2',
      source: 'concept2.com/rankings · Verified erg results',
      year: '2024',
    ),
    BenchmarkRef(
      title: 'ACSM Guidelines for Exercise Testing and Prescription (11th ed.)',
      authors: 'American College of Sports Medicine',
      source: 'Wolters Kluwer · Table 4-8 VO2max norms',
      year: '2022',
    ),
    BenchmarkRef(
      title: 'Lactate Threshold and CrossFit Performance',
      authors: 'Tibana RA et al.',
      source: 'Journal of Human Kinetics, 56(1), 167–176',
      year: '2017',
    ),
  ],
  metrics: [
    BenchmarkMetric(
      label: 'Row 500m',
      tierValues: ['1:25', '1:35', '1:45', '1:55', '2:10'],
      femaleTierValues: ['1:35', '1:45', '2:00', '2:15', '2:35'],
      lowerIsBetter: true,
    ),
    BenchmarkMetric(
      label: 'Run 1 mile',
      tierValues: ['4:00', '4:30', '6:00', '8:30', '10:00'],
      femaleTierValues: ['4:30', '5:00', '7:00', '9:30', '12:00'],
      lowerIsBetter: true,
    ),
    BenchmarkMetric(
      label: 'Row 2km',
      tierValues: ['5:40', '6:50', '8:00', '9:05', '10:30'],
      femaleTierValues: ['6:40', '7:50', '9:10', '10:30', '12:10'],
      lowerIsBetter: true,
    ),
  ],
);

// METCON — Burpee/min · Fran · Helen · Wall Ball/min
// grading.py: _BURPEE_PER_MIN / _FRAN_SEC / _HELEN_SEC / _WALL_BALL_PER_MIN
const _metcon = CategoryBenchmark(
  key: 'metcon',
  displayName: 'METCON',
  description: '복합 대사 용량 (Metabolic Conditioning).\n'
      'Burpee 강도, 대표 벤치마크 WOD 시간 기준.',
  sourceShort: 'CF Games 영상 분석 + community consensus · v3.1 실사용자 캘리브레이션',
  context:
      'Metcon은 유산소-무산소 혼합 대사 능력을 측정한다. '
      'Fran(21-15-9 Thruster + Pull-up)은 CrossFit의 대표 벤치마크 WOD로, '
      'Tibana et al.(2019)은 Fran 완주 시간이 CrossFit Games 순위와 r=-0.81의 강한 역상관을 가진다고 보고했다. '
      'Burpee 속도는 단순하지만 전신 대사 출력의 신뢰 지표다. '
      'Helen(3라운드: 400m Run + 21 KB Swing + 12 Pull-up)은 '
      '심폐+근지구+기술의 균형 지표로 CF community에서 가장 많이 사용되는 벤치마크 중 하나다. '
      'Games급 Fran sub-2:00은 최고 출력 유지 능력의 극단을 나타낸다.',
  refs: [
    BenchmarkRef(
      title: 'Fran Completion Time as a Predictor of CrossFit Performance',
      authors: 'Tibana RA, de Sousa NMF, Prestes J',
      source: 'International Journal of Exercise Science, 12(1)',
      year: '2019',
    ),
    BenchmarkRef(
      title: 'Metabolic Demands of CrossFit WODs',
      authors: 'Kliszczewicz B et al.',
      source: 'Journal of Strength & Conditioning Research, 29(10)',
      year: '2015',
    ),
    BenchmarkRef(
      title: 'Physiological Adaptations to High-Intensity Functional Training',
      authors: 'Maté-Muñoz JL et al.',
      source: 'Journal of Human Kinetics, 56, 81–92',
      year: '2017',
    ),
  ],
  metrics: [
    BenchmarkMetric(
      label: 'Burpee/min',
      tierValues: ['30+', '26', '22', '17', '12'],
      femaleTierValues: ['28+', '24', '20', '15', '10'],
    ),
    BenchmarkMetric(
      label: 'Wall Ball/min',
      tierValues: ['34+', '28', '22', '16', '10'],
      femaleTierValues: ['32+', '26', '20', '14', '8'],
      note: '@20lb',
      femaleNote: '@14lb',
    ),
    BenchmarkMetric(
      label: 'Fran',
      tierValues: ['<2:00', '<3:00', '<4:00', '<5:00', '<7:00'],
      lowerIsBetter: true,
      note: '95lb Thruster',
      femaleNote: '65lb Thruster',
    ),
    BenchmarkMetric(
      label: 'Helen',
      tierValues: ['<8:00', '<10:00', '<12:00', '<14:00', '<17:00'],
      femaleTierValues: ['<9:00', '<11:00', '<13:00', '<15:00', '<18:00'],
      lowerIsBetter: true,
      note: '53lb KB',
      femaleNote: '35lb KB',
    ),
  ],
);

// BODY — InBody Score / Body Fat % / Skeletal Muscle %
// grading.py: _BF_PCT_M / _BF_PCT_F / _SMM_PCT_F
const _body = CategoryBenchmark(
  key: 'body_composition',
  displayName: 'BODY',
  description: 'InBody 체성분 분석. 골격근량·체지방률 복합 점수.\n'
      'CrossFit 선수는 높은 근육량 + 낮은 체지방이 특징.',
  sourceShort: 'ACE body fat classification · InBody normative data · physical-norms.md §5',
  context:
      '체성분은 CrossFit 경기력과 강하게 연관된다. '
      'Mangine et al.(2014)은 CrossFit 선수의 골격근량(%SMM)이 일반 인구 상위 10% 수준이며, '
      '체지방률은 지구력 운동선수와 유사한 수준(남 10~14%, 여 16~20%)임을 보고했다. '
      'ACE 분류 기준에서 "Athlete" 구간은 남성 6~13%, 여성 14~20%이며, '
      'Games 출전급은 이 구간 하단에 위치한다. '
      'InBody Score 90+는 체중 대비 근육-지방 균형이 최상위 5% 수준을 의미한다. '
      '여성의 SMM% 기준이 낮은 이유는 생물학적 체지방 필수량(essential fat ≈ 12%) 차이 때문이다.',
  refs: [
    BenchmarkRef(
      title: 'ACE Body Fat Percentage Norms for Men and Women',
      authors: 'American Council on Exercise',
      source: 'acefitness.org · Fitness Standards Reference',
      year: '2023',
    ),
    BenchmarkRef(
      title: 'Body Composition in CrossFit Athletes',
      authors: 'Mangine GT et al.',
      source: 'Journal of Strength & Conditioning Research, 28(11)',
      year: '2014',
    ),
    BenchmarkRef(
      title: 'InBody 770 Normative Data — Skeletal Muscle Mass %',
      authors: 'InBody Co., Ltd.',
      source: 'inbody.com · Clinical Reference Manual v5',
      year: '2022',
    ),
    BenchmarkRef(
      title: 'Essential Body Fat and Athletic Performance',
      authors: 'Ackland TR et al.',
      source: 'International Journal of Sport Nutrition, 22(3)',
      year: '2012',
    ),
  ],
  metrics: [
    BenchmarkMetric(
      label: 'InBody Score',
      tierValues: ['90+', '85', '80', '75', '<75'],
    ),
    BenchmarkMetric(
      label: 'Body Fat %',
      tierValues: ['<10%', '<13%', '<17%', '<20%', '<25%'],
      femaleTierValues: ['<16%', '<20%', '<24%', '<28%', '<32%'],
      lowerIsBetter: true,
      note: 'ACE Athlete (M)',
      femaleNote: 'ACE Athlete (F)',
    ),
    BenchmarkMetric(
      label: 'Skeletal Muscle',
      tierValues: ['50%+', '47%', '44%', '41%', '<41%'],
      femaleTierValues: ['42%+', '39%', '36%', '33%', '<33%'],
      note: 'SMM% (M)',
      femaleNote: 'SMM% (F)',
    ),
  ],
);

// ────────────────────────────────────────────────────────────────────────────
// Public lookup table: radar key → benchmark

const Map<String, CategoryBenchmark> kBenchmarks = {
  'POWER': _power,
  'OLYMPIC': _olympic,
  'GYMNASTICS': _gymnastics,
  'CARDIO': _cardio,
  'METCON': _metcon,
  'BODY': _body,
};
