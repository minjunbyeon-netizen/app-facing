// Debug-only: 페르소나별 체형·벤치마크·합성 grade 데이터.
// persona_switcher_screen.dart / mypage_screen.dart 에서 공용 사용.
// kDebugMode 가드는 호출자 책임.

/// tier 문자열 → 합성 grade result (backend 응답 스키마 동일).
/// overall_score 및 category score = 1.0~6.0 (backend 스케일).
/// engineScoreTo100 = ((s - 1.0) / 5.0 * 100).round() — scoring.dart 참조.
Map<String, dynamic> tierGrade(String tier) {
  switch (tier) {
    case 'Scaled':
      return {
        'overall_number': 1,
        'overall_score': 1.5,
        'overall': 'Scaled',
        'overall_label_ko': '스케일드',
        'power': {'score': 1.4},
        'olympic': {'score': 1.3},
        'gymnastics': {'score': 1.6},
        'cardio': {'score': 1.7},
        'metcon': {'score': 1.5},
        'body_composition': {'score': 1.5},
      };
    case 'RX':
      return {
        'overall_number': 3,
        'overall_score': 3.3,
        'overall': 'RX',
        'overall_label_ko': 'RX',
        'power': {'score': 3.1},
        'olympic': {'score': 3.0},
        'gymnastics': {'score': 3.3},
        'cardio': {'score': 3.5},
        'metcon': {'score': 3.4},
        'body_composition': {'score': 3.2},
      };
    case 'RX+':
      return {
        'overall_number': 4,
        'overall_score': 4.3,
        'overall': 'RX+',
        'overall_label_ko': 'RX 플러스',
        'power': {'score': 4.1},
        'olympic': {'score': 4.0},
        'gymnastics': {'score': 4.4},
        'cardio': {'score': 4.6},
        'metcon': {'score': 4.3},
        'body_composition': {'score': 4.2},
      };
    case 'Elite':
      return {
        'overall_number': 5,
        'overall_score': 5.2,
        'overall': 'Elite',
        'overall_label_ko': '엘리트',
        'power': {'score': 5.0},
        'olympic': {'score': 4.9},
        'gymnastics': {'score': 5.4},
        'cardio': {'score': 5.5},
        'metcon': {'score': 5.2},
        'body_composition': {'score': 5.1},
      };
    case 'Games':
      return {
        'overall_number': 6,
        'overall_score': 5.8,
        'overall': 'Games',
        'overall_label_ko': '게임스',
        'power': {'score': 5.7},
        'olympic': {'score': 5.6},
        'gymnastics': {'score': 5.9},
        'cardio': {'score': 5.9},
        'metcon': {'score': 5.8},
        'body_composition': {'score': 5.7},
      };
    default:
      return {
        'overall_number': 3,
        'overall_score': 3.3,
        'overall': 'RX',
        'overall_label_ko': 'RX',
        'power': {'score': 3.1},
        'olympic': {'score': 3.0},
        'gymnastics': {'score': 3.3},
        'cardio': {'score': 3.5},
        'metcon': {'score': 3.4},
        'body_composition': {'score': 3.2},
      };
  }
}

class PersonaBodyData {
  final double bodyWeightKg;
  final double heightCm;
  final double ageYears;
  final String gender;
  final double experienceYears;
  final Map<String, double> benchmarks;

  const PersonaBodyData({
    required this.bodyWeightKg,
    required this.heightCm,
    required this.ageYears,
    required this.gender,
    required this.experienceYears,
    required this.benchmarks,
  });
}

/// deviceIdSeed → 체형·벤치마크 데이터.
const Map<String, PersonaBodyData> kPersonaBodyMap = {
  'persona-admin-byun-2026': PersonaBodyData(
    bodyWeightKg: 82.0,
    heightCm: 177.0,
    ageYears: 34.0,
    gender: 'male',
    experienceYears: 9.0,
    benchmarks: {
      'back_squat_1rm_lb': 365.0,
      'deadlift_1rm_lb': 455.0,
      'clean_1rm_lb': 265.0,
      'snatch_1rm_lb': 215.0,
      'strict_pull_up_max_ub': 30.0,
      'row_500m_sec': 92.0,
    },
  ),
  'persona-coach-park-2026': PersonaBodyData(
    bodyWeightKg: 85.0,
    heightCm: 178.0,
    ageYears: 32.0,
    gender: 'male',
    experienceYears: 8.0,
    benchmarks: {
      'back_squat_1rm_lb': 400.0,
      'deadlift_1rm_lb': 500.0,
      'clean_1rm_lb': 295.0,
      'snatch_1rm_lb': 245.0,
      'strict_pull_up_max_ub': 42.0,
      'hspu_max_ub': 22.0,
      'row_500m_sec': 88.0,
      'double_under_per_min': 100.0,
    },
  ),
  'persona-coach-lee-2026': PersonaBodyData(
    bodyWeightKg: 64.0,
    heightCm: 164.0,
    ageYears: 28.0,
    gender: 'female',
    experienceYears: 7.0,
    benchmarks: {
      'back_squat_1rm_lb': 245.0,
      'deadlift_1rm_lb': 315.0,
      'clean_1rm_lb': 185.0,
      'snatch_1rm_lb': 155.0,
      'strict_pull_up_max_ub': 28.0,
      'hspu_max_ub': 15.0,
      'row_500m_sec': 96.0,
      'double_under_per_min': 95.0,
    },
  ),
  'persona-member-kim-doyun-2026': PersonaBodyData(
    bodyWeightKg: 78.0,
    heightCm: 175.0,
    ageYears: 26.0,
    gender: 'male',
    experienceYears: 3.0,
    benchmarks: {
      'back_squat_1rm_lb': 285.0,
      'deadlift_1rm_lb': 375.0,
      'clean_1rm_lb': 205.0,
      'strict_pull_up_max_ub': 15.0,
      'run_mile_sec': 420.0,
    },
  ),
  'persona-member-jung-haeun-2026': PersonaBodyData(
    bodyWeightKg: 59.0,
    heightCm: 163.0,
    ageYears: 25.0,
    gender: 'female',
    experienceYears: 2.0,
    benchmarks: {
      'back_squat_1rm_lb': 165.0,
      'deadlift_1rm_lb': 225.0,
      'clean_1rm_lb': 135.0,
      'strict_pull_up_max_ub': 10.0,
      'run_mile_sec': 510.0,
    },
  ),
  'persona-member-choi-seoyun-2026': PersonaBodyData(
    bodyWeightKg: 56.0,
    heightCm: 161.0,
    ageYears: 22.0,
    gender: 'female',
    experienceYears: 0.5,
    benchmarks: {
      'back_squat_1rm_lb': 95.0,
      'deadlift_1rm_lb': 135.0,
      'run_mile_sec': 660.0,
    },
  ),
  'persona-member-kang-minjae-2026': PersonaBodyData(
    bodyWeightKg: 82.0,
    heightCm: 176.0,
    ageYears: 28.0,
    gender: 'male',
    experienceYears: 5.0,
    benchmarks: {
      'back_squat_1rm_lb': 335.0,
      'deadlift_1rm_lb': 445.0,
      'clean_1rm_lb': 255.0,
      'snatch_1rm_lb': 205.0,
      'strict_pull_up_max_ub': 25.0,
      'hspu_max_ub': 12.0,
      'row_500m_sec': 94.0,
    },
  ),
  'persona-member-yoon-jiwon-2026': PersonaBodyData(
    bodyWeightKg: 62.0,
    heightCm: 166.0,
    ageYears: 27.0,
    gender: 'female',
    experienceYears: 3.0,
    benchmarks: {
      'back_squat_1rm_lb': 175.0,
      'deadlift_1rm_lb': 245.0,
      'clean_1rm_lb': 145.0,
      'strict_pull_up_max_ub': 12.0,
      'run_mile_sec': 490.0,
    },
  ),
  'persona-member-han-suah-2026': PersonaBodyData(
    bodyWeightKg: 55.0,
    heightCm: 160.0,
    ageYears: 21.0,
    gender: 'female',
    experienceYears: 0.5,
    benchmarks: {
      'back_squat_1rm_lb': 85.0,
      'deadlift_1rm_lb': 115.0,
      'run_mile_sec': 720.0,
    },
  ),
  'persona-app-song-yejun-2026': PersonaBodyData(
    bodyWeightKg: 75.0,
    heightCm: 174.0,
    ageYears: 30.0,
    gender: 'male',
    experienceYears: 4.0,
    benchmarks: {
      'back_squat_1rm_lb': 275.0,
      'deadlift_1rm_lb': 365.0,
      'clean_1rm_lb': 185.0,
      'strict_pull_up_max_ub': 18.0,
      'run_mile_sec': 450.0,
    },
  ),
};
