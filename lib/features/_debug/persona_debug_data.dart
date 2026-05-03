// Debug-only: 페르소나별 체형·벤치마크·합성 grade 데이터.
// persona_switcher_screen.dart / mypage_screen.dart 에서 공용 사용.
// kDebugMode 가드는 호출자 책임.

/// tier 문자열 → 합성 grade result (backend 응답 스키마 동일).
Map<String, dynamic> tierGrade(String tier) {
  switch (tier) {
    case 'Scaled':
      return {
        'overall_number': 1,
        'overall_score': 0.18,
        'overall': 'Scaled',
        'power': {'score': 0.16},
        'olympic': {'score': 0.14},
        'gymnastics': {'score': 0.20},
        'cardio': {'score': 0.22},
        'metcon': {'score': 0.18},
        'body_composition': {'score': 0.18},
      };
    case 'RX':
      return {
        'overall_number': 3,
        'overall_score': 0.55,
        'overall': 'RX',
        'power': {'score': 0.52},
        'olympic': {'score': 0.50},
        'gymnastics': {'score': 0.54},
        'cardio': {'score': 0.58},
        'metcon': {'score': 0.56},
        'body_composition': {'score': 0.55},
      };
    case 'RX+':
      return {
        'overall_number': 4,
        'overall_score': 0.72,
        'overall': 'RX+',
        'power': {'score': 0.70},
        'olympic': {'score': 0.68},
        'gymnastics': {'score': 0.74},
        'cardio': {'score': 0.76},
        'metcon': {'score': 0.72},
        'body_composition': {'score': 0.72},
      };
    case 'Elite':
      return {
        'overall_number': 5,
        'overall_score': 0.88,
        'overall': 'Elite',
        'power': {'score': 0.86},
        'olympic': {'score': 0.84},
        'gymnastics': {'score': 0.90},
        'cardio': {'score': 0.92},
        'metcon': {'score': 0.88},
        'body_composition': {'score': 0.88},
      };
    case 'Games':
      return {
        'overall_number': 6,
        'overall_score': 0.97,
        'overall': 'Games',
        'power': {'score': 0.96},
        'olympic': {'score': 0.94},
        'gymnastics': {'score': 0.98},
        'cardio': {'score': 0.98},
        'metcon': {'score': 0.97},
        'body_composition': {'score': 0.97},
      };
    default:
      return {
        'overall_number': 3,
        'overall_score': 0.55,
        'overall': 'RX',
        'power': {'score': 0.52},
        'olympic': {'score': 0.50},
        'gymnastics': {'score': 0.54},
        'cardio': {'score': 0.58},
        'metcon': {'score': 0.56},
        'body_composition': {'score': 0.55},
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
