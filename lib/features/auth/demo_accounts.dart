// 회의 데모용: 백엔드 페르소나 시드와 1:1 매핑된 3명 (코치 1 + 회원 2). 사장은 Box Owner Login.
// ⚠️ **가상 데이터** — 실제 사용자 아님. 회의 시연용 프로필 샘플.
// 누르면 deviceIdSeed 로 device_id 강제 교체 → 백엔드 페르소나 데이터로 즉시 진입.
// 2026-05-30: 송예준(개인) 카드 제거 · 최서윤 가입대기→회원 승격 (코치+회원2 세트).

class DemoAccount {
  final String id; // internal slug
  final String nameLabel; // '박지훈 · FACING SEONGSU 코치' (@deprecated v1.16.2 — UI 표시는 personName/boxName/role 분리)
  final String personName; // '박지훈' — IdentityCard h2 표시용
  final String role; // 'coach' | 'member' | 'solo' | 'pending'
  final String boxName;
  final double bodyWeightKg;
  final int heightCm;
  final int ageYears;
  final String gender;
  final double experienceYears;
  final Map<String, double> benchmarks;
  final String hintTier;
  // v1.22: 백엔드 페르소나 device_id 시드. null 이면 새 device_id 생성 (기존 동작).
  final String? deviceIdSeed;

  const DemoAccount({
    required this.id,
    required this.nameLabel,
    required this.personName,
    required this.role,
    required this.boxName,
    required this.bodyWeightKg,
    required this.heightCm,
    required this.ageYears,
    required this.gender,
    required this.experienceYears,
    required this.benchmarks,
    required this.hintTier,
    this.deviceIdSeed,
  });
}

/// ⚠️ **가상 데이터** 3건 (코치 1 + 회원 2). 회의 데모용 — 백엔드 personas 와 동기화.
const List<DemoAccount> kDemoAccounts = [
  // 1. 박지훈 — FACING SEONGSU 코치 (오너)
  DemoAccount(
    id: 'coach_park',
    nameLabel: '박지훈 · FACING SEONGSU 코치',
    personName: '박지훈',
    role: 'coach',
    boxName: 'FACING SEONGSU',
    bodyWeightKg: 85,
    heightCm: 178,
    ageYears: 32,
    gender: 'male',
    experienceYears: 8,
    benchmarks: {
      'back_squat_1rm_lb': 400,
      'deadlift_1rm_lb': 500,
      'clean_1rm_lb': 295,
      'snatch_1rm_lb': 245,
      'strict_pull_up_max_ub': 42,
      'hspu_max_ub': 22,
      'row_500m_sec': 88,
      'double_under_per_min': 100,
    },
    // QA 2026-06-11 #3: 하드코딩 Engine 수치는 백엔드 산정값과 어긋남 — Tier 만 표기.
    hintTier: 'Elite',
    deviceIdSeed: 'persona-coach-park-2026',
  ),
  // 2. 김도윤 — FACING SEONGSU 정식 회원
  DemoAccount(
    id: 'member_kim',
    nameLabel: '김도윤 · FACING SEONGSU 회원',
    personName: '김도윤',
    role: 'member',
    boxName: 'FACING SEONGSU',
    bodyWeightKg: 78,
    heightCm: 175,
    ageYears: 26,
    gender: 'male',
    experienceYears: 3,
    benchmarks: {
      'back_squat_1rm_lb': 285,
      'deadlift_1rm_lb': 375,
      'clean_1rm_lb': 205,
      'strict_pull_up_max_ub': 15,
      'run_mile_sec': 420,
    },
    hintTier: 'RX',
    deviceIdSeed: 'persona-member-kim-doyun-2026',
  ),
  // 3. 최서윤 — FACING SEONGSU 정식 회원 (여성 회원 — 2026-05-30 가입대기→승인)
  DemoAccount(
    id: 'member_choi',
    nameLabel: '최서윤 · FACING SEONGSU 회원',
    personName: '최서윤',
    role: 'member',
    boxName: 'FACING SEONGSU',
    bodyWeightKg: 56,
    heightCm: 161,
    ageYears: 22,
    gender: 'female',
    experienceYears: 0.5,
    benchmarks: {
      'back_squat_1rm_lb': 95,
      'deadlift_1rm_lb': 135,
      'run_mile_sec': 660,
    },
    hintTier: 'Scaled',
    deviceIdSeed: 'persona-member-choi-seoyun-2026',
  ),
];
