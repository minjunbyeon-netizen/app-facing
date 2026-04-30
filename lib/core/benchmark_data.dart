/// Engine 6 카테고리 벤치마크 레퍼런스 데이터.
/// Source: services/facing/engine/grading.py v3.0/v3.1
/// Tier mapping: Games=elite(95th) / Elite=advanced(80th) / RX+=rxd(50th)
///               RX=intermediate(20th) / Scaled=beginner(5th)
library;

const List<String> kTierLabels = ['Games', 'Elite', 'RX+', 'RX', 'Scaled'];

class BenchmarkMetric {
  final String label;
  final List<String> tierValues; // index 0=Games … 4=Scaled
  final bool lowerIsBetter;
  final String? note;
  const BenchmarkMetric({
    required this.label,
    required this.tierValues,
    this.lowerIsBetter = false,
    this.note,
  });
}

class CategoryBenchmark {
  final String key;          // matches gradeResult key: 'power','olympic',etc.
  final String displayName;
  final String description;
  final String sourceShort;  // 화면 하단 출처 한 줄
  final List<BenchmarkMetric> metrics;
  const CategoryBenchmark({
    required this.key,
    required this.displayName,
    required this.description,
    required this.sourceShort,
    required this.metrics,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// POWER — Back Squat / Deadlift / Bench / OHP
// grading.py: _BS_RATIO, _DL_RATIO, _BENCH_RATIO, _OHP_RATIO (BW80 남)
const _power = CategoryBenchmark(
  key: 'power',
  displayName: 'POWER',
  description: 'SBD(Squat·Bench·Dead) + Overhead Press.\n'
      '체중 대비 최대 중량 비율로 측정. 남성 BW80kg 기준.',
  sourceShort: 'Strength Level 100M+ database (2024) · BW80kg male 95th %ile',
  metrics: [
    BenchmarkMetric(
      label: 'Back Squat',
      tierValues: ['×2.95', '×2.45', '×1.90', '×1.35', '×0.85'],
      note: 'BW ratio',
    ),
    BenchmarkMetric(
      label: 'Deadlift',
      tierValues: ['×3.55', '×2.95', '×2.35', '×1.70', '×1.10'],
      note: 'BW ratio',
    ),
    BenchmarkMetric(
      label: 'Bench Press',
      tierValues: ['×2.25', '×1.80', '×1.35', '×0.95', '×0.60'],
      note: 'BW ratio',
    ),
    BenchmarkMetric(
      label: 'Overhead Press',
      tierValues: ['×1.30', '×1.05', '×0.80', '×0.55', '×0.35'],
      note: 'BW ratio',
    ),
  ],
);

// OLYMPIC — Snatch / C&J
// grading.py: _SNATCH_RATIO, _CLEAN_AND_JERK_RATIO (BW 남)
const _olympic = CategoryBenchmark(
  key: 'olympic',
  displayName: 'OLYMPIC',
  description: 'Snatch · Clean & Jerk · Power variants.\n'
      '체중 대비 최대 중량 비율. IWF/USAW/NSCA 경기 기록 기반.',
  sourceShort: 'strengthlevel.com 5-level Male · IWF/USAW protocols (2024)',
  metrics: [
    BenchmarkMetric(
      label: 'Snatch',
      tierValues: ['×1.40', '×1.10', '×0.80', '×0.55', '×0.35'],
      note: 'BW ratio',
    ),
    BenchmarkMetric(
      label: 'Clean & Jerk',
      tierValues: ['×1.70', '×1.35', '×1.00', '×0.70', '×0.45'],
      note: 'BW ratio',
    ),
    BenchmarkMetric(
      label: 'Power Clean',
      tierValues: ['×1.43', '×1.13', '×0.84', '×0.59', '×0.38'],
      note: 'Full×0.84',
    ),
    BenchmarkMetric(
      label: 'OHS',
      tierValues: ['×1.50', '×1.20', '×0.90', '×0.65', '×0.40'],
      note: 'Snatch×1.05',
    ),
  ],
);

// GYMNASTICS — Pull-up / T2B / HSPU / Bar MU
// grading.py: _PULLUP_UB, _T2B_UB, _HSPU_UB, _BAR_MUSCLE_UP_UB
const _gymnastics = CategoryBenchmark(
  key: 'gymnastics',
  displayName: 'GYMNASTICS',
  description: 'Unbroken max reps (UB). 연속 실패 없이 이어서 수행한 최대 횟수.\n'
      'Pull-up/T2B/HSPU/Muscle-up 능력이 CrossFit 등급을 결정.',
  sourceShort: 'USMC PFT · ACFT · gymnastics.md §2–3 (CF Games 관찰값 포함)',
  metrics: [
    BenchmarkMetric(
      label: 'Pull-up UB',
      tierValues: ['23+', '18', '12', '7', '3'],
      note: 'kipping ok',
    ),
    BenchmarkMetric(
      label: 'T2B UB',
      tierValues: ['25+', '17', '10', '5', '2'],
      note: 'reps',
    ),
    BenchmarkMetric(
      label: 'HSPU UB',
      tierValues: ['25+', '15', '8', '4', '1'],
      note: 'strict wall',
    ),
    BenchmarkMetric(
      label: 'Bar Muscle-up',
      tierValues: ['15+', '10', '6', '3', '1'],
      note: 'UB reps',
    ),
  ],
);

// CARDIO — Row 500m / Run 1mi / Row 2km
// grading.py: _ROW_500M_SEC, _RUN_MILE_SEC, _ROW_2KM_SEC
const _cardio = CategoryBenchmark(
  key: 'cardio',
  displayName: 'CARDIO',
  description: '유산소 Engine 용량. 빠를수록 좋음.\n'
      'Concept2 에르고미터 + 달리기 기록. VO2max 95th %ile 기준.',
  sourceShort: 'Concept2 World Rankings · Daniels VDOT tables · ACSM VO2max norms',
  metrics: [
    BenchmarkMetric(
      label: 'Row 500m',
      tierValues: ['1:25', '1:35', '1:45', '1:55', '2:10'],
      lowerIsBetter: true,
    ),
    BenchmarkMetric(
      label: 'Run 1 mile',
      tierValues: ['4:00', '4:30', '6:00', '8:30', '10:00'],
      lowerIsBetter: true,
    ),
    BenchmarkMetric(
      label: 'Row 2km',
      tierValues: ['5:40', '6:50', '8:00', '9:05', '10:30'],
      lowerIsBetter: true,
    ),
  ],
);

// METCON — Burpee/min · Fran · Helen · Wall Ball/min
// grading.py: _BURPEE_PER_MIN, _FRAN_SEC, _HELEN_SEC, _WALL_BALL_PER_MIN
const _metcon = CategoryBenchmark(
  key: 'metcon',
  displayName: 'METCON',
  description: '복합 대사 용량 (Metabolic Conditioning).\n'
      'Burpee 강도, 대표 벤치마크 WOD 시간 기준.',
  sourceShort: 'CF Games 영상 분석 + community consensus · v3.1 실사용자 캘리브레이션',
  metrics: [
    BenchmarkMetric(
      label: 'Burpee/min',
      tierValues: ['30+', '26', '22', '17', '12'],
    ),
    BenchmarkMetric(
      label: 'Wall Ball/min',
      tierValues: ['34+', '28', '22', '16', '10'],
      note: '@20lb',
    ),
    BenchmarkMetric(
      label: 'Fran',
      tierValues: ['<2:00', '<3:00', '<4:00', '<5:00', '<7:00'],
      lowerIsBetter: true,
      note: '21-15-9 Thruster+PU',
    ),
    BenchmarkMetric(
      label: 'Helen',
      tierValues: ['<8:00', '<10:00', '<12:00', '<14:00', '<17:00'],
      lowerIsBetter: true,
      note: '3rnd 400m+KB+PU',
    ),
  ],
);

// BODY — InBody Score / Body Fat %
// grading.py: _INBODY_SCORE, _BF_PCT_M
const _body = CategoryBenchmark(
  key: 'body_composition',
  displayName: 'BODY',
  description: 'InBody 체성분 분석. 골격근량·체지방률 복합 점수.\n'
      'CrossFit 선수는 높은 근육량 + 낮은 체지방이 특징.',
  sourceShort: 'ACE body fat classification · InBody normative data · physical-norms.md §5',
  metrics: [
    BenchmarkMetric(
      label: 'InBody Score',
      tierValues: ['90+', '85', '80', '75', '<75'],
    ),
    BenchmarkMetric(
      label: 'Body Fat % (M)',
      tierValues: ['<10%', '<13%', '<17%', '<20%', '<25%'],
      lowerIsBetter: true,
      note: 'ACE Athlete class',
    ),
    BenchmarkMetric(
      label: 'Body Fat % (F)',
      tierValues: ['<16%', '<20%', '<24%', '<28%', '<32%'],
      lowerIsBetter: true,
      note: 'ACE Athlete class',
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
