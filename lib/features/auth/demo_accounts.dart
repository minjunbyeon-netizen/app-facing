// v1.16 Sprint 8 U1: 5 데모 계정 프리셋.
// ⚠️ **가상 데이터** — 실제 사용자 아님. 테스트·체험용 프로필 샘플.
// 앱 최초 진입 시 빠른 상태 진입을 위해 Signup 화면에 노출.

class DemoAccount {
  final String id; // internal slug
  final String nameLabel; // '코치 김 · A Box'
  final String role; // 'coach' | 'member' | 'solo' | 'masters' | 'elite'
  final String boxName; // 'A Box' | '' (solo/elite no box)
  final double bodyWeightKg;
  final int heightCm;
  final int ageYears;
  final String gender; // 'male' | 'female'
  final double experienceYears;
  final Map<String, double> benchmarks; // 1RM·UB·카디오
  final String hintTier; // UI 미리 표시용

  const DemoAccount({
    required this.id,
    required this.nameLabel,
    required this.role,
    required this.boxName,
    required this.bodyWeightKg,
    required this.heightCm,
    required this.ageYears,
    required this.gender,
    required this.experienceYears,
    required this.benchmarks,
    required this.hintTier,
  });
}

/// ⚠️ **가상 데이터** 5건.
const List<DemoAccount> kDemoAccounts = [
  DemoAccount(
    id: 'coach_a',
    nameLabel: '코치 김 · A Box owner',
    role: 'coach',
    boxName: 'A Box',
    bodyWeightKg: 85,
    heightCm: 178,
    ageYears: 32,
    gender: 'male',
    experienceYears: 8,
    benchmarks: {
      'back_squat_1rm_lb': 365,
      'front_squat_1rm_lb': 300,
      'deadlift_1rm_lb': 475,
      'bench_press_1rm_lb': 275,
      'ohp_1rm_lb': 165,
      'clean_1rm_lb': 275,
      'snatch_1rm_lb': 225,
      'strict_pull_up_max_ub': 35,
      'hspu_max_ub': 20,
      'row_500m_sec': 92,
    },
    hintTier: 'RX+ / Engine 75',
  ),
  DemoAccount(
    id: 'member_a',
    nameLabel: '박 회원 · A Box member',
    role: 'member',
    boxName: 'A Box',
    bodyWeightKg: 72,
    heightCm: 170,
    ageYears: 28,
    gender: 'male',
    experienceYears: 2,
    benchmarks: {
      'back_squat_1rm_lb': 265,
      'deadlift_1rm_lb': 355,
      'bench_press_1rm_lb': 205,
      'clean_1rm_lb': 175,
      'strict_pull_up_max_ub': 15,
      'run_mile_sec': 420,
    },
    hintTier: 'RX / Engine 55',
  ),
  DemoAccount(
    id: 'solo_hwpo',
    nameLabel: '솔로 선수 · 박스 없음',
    role: 'solo',
    boxName: '',
    bodyWeightKg: 78,
    heightCm: 175,
    ageYears: 30,
    gender: 'male',
    experienceYears: 3,
    benchmarks: {
      'back_squat_1rm_lb': 305,
      'deadlift_1rm_lb': 405,
      'bench_press_1rm_lb': 225,
      'clean_1rm_lb': 205,
      'snatch_1rm_lb': 165,
      'strict_pull_up_max_ub': 22,
      'hspu_max_ub': 10,
      'double_under_per_min': 75,
      'run_mile_sec': 390,
    },
    hintTier: 'RX / Engine 62',
  ),
  DemoAccount(
    id: 'masters_52',
    nameLabel: '이 마스터스 · 52세',
    role: 'masters',
    boxName: 'B Box',
    bodyWeightKg: 75,
    heightCm: 172,
    ageYears: 52,
    gender: 'male',
    experienceYears: 10,
    benchmarks: {
      'back_squat_1rm_lb': 245,
      'deadlift_1rm_lb': 315,
      'bench_press_1rm_lb': 185,
      'clean_1rm_lb': 155,
      'strict_pull_up_max_ub': 10,
      'run_mile_sec': 480,
      'row_500m_sec': 108,
    },
    hintTier: 'RX / Engine 48 · Masters 45+',
  ),
  DemoAccount(
    id: 'elite_games',
    nameLabel: 'Dara · Games 지망',
    role: 'elite',
    boxName: '',
    bodyWeightKg: 62,
    heightCm: 165,
    ageYears: 29,
    gender: 'female',
    experienceYears: 6,
    benchmarks: {
      'back_squat_1rm_lb': 245,
      'front_squat_1rm_lb': 215,
      'deadlift_1rm_lb': 335,
      'bench_press_1rm_lb': 145,
      'ohp_1rm_lb': 115,
      'clean_1rm_lb': 195,
      'snatch_1rm_lb': 155,
      'strict_pull_up_max_ub': 28,
      'hspu_max_ub': 15,
      'bar_muscle_up_max_ub': 8,
      'double_under_per_min': 110,
      'row_500m_sec': 98,
    },
    hintTier: 'Elite / Engine 88',
  ),
];
