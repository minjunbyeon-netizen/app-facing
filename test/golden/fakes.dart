import 'dart:async';

import 'package:facing_app/core/api_client.dart';
import 'package:facing_app/core/connectivity_state.dart';
import 'package:facing_app/core/exception.dart';
import 'package:facing_app/core/sse_client.dart';
import 'package:facing_app/features/boss/boss_api_client.dart';
import 'package:facing_app/features/boss/boss_auth_state.dart';

/// 골든 테스트용 가짜 백엔드 — 경로 prefix → 응답 데이터 맵. 네트워크 0.
/// ApiClient 를 implements + noSuchMethod 로 대체 (생성자가 private 이라 상속 불가).
/// 맵은 삽입 순서대로 prefix 매칭 — 구체 경로를 먼저 넣을 것.
class FakeApi implements ApiClient {
  final Map<String, dynamic> responses;

  /// true 면 모든 응답을 영원히 보류 — 로딩 화면 고정용.
  final bool hang;

  /// 이 prefix 로 시작하는 경로만 보류.
  final Set<String> hangPaths;

  /// 이 prefix 로 시작하는 경로는 네트워크 에러 — 에러 상태 화면 고정용.
  final Set<String> errorPaths;

  FakeApi(this.responses,
      {this.hang = false,
      this.hangPaths = const {},
      this.errorPaths = const {}});

  Future<dynamic> _respond(String path) {
    if (hang || hangPaths.any(path.startsWith)) {
      return Completer<dynamic>().future; // 영원히 pending
    }
    if (errorPaths.any(path.startsWith)) {
      return Future.error(AppException('백엔드 OFF · 잠시 후 재시도', code: 'NETWORK'));
    }
    for (final e in responses.entries) {
      if (path.startsWith(e.key)) return Future.value(e.value);
    }
    return Future.error(AppException('골든 미정의 경로: $path', code: 'NO_FAKE'));
  }

  @override
  Future<Map<String, dynamic>> get(String path) async {
    final d = await _respond(path);
    return Map<String, dynamic>.from(d as Map);
  }

  @override
  Future<List<dynamic>> getList(String path) async {
    final d = await _respond(path);
    return d as List;
  }

  @override
  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    if (hang || hangPaths.any(path.startsWith)) {
      return Completer<Map<String, dynamic>>().future;
    }
    if (errorPaths.any(path.startsWith)) {
      throw AppException('백엔드 OFF · 잠시 후 재시도', code: 'NETWORK');
    }
    for (final e in responses.entries) {
      if (path.startsWith(e.key)) {
        return Map<String, dynamic>.from(e.value as Map);
      }
    }
    // 배경 fire-and-forget 쓰기(markSeen 등)는 조용히 성공 처리.
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) =>
      post(path, body);

  @override
  Future<Map<String, dynamic>> delete(String path) => post(path, const {});

  @override
  Future<String?> sessionCookie() async => null;

  @override
  Future<void> flushRetryQueue() async {}

  @override
  void enqueueRetry(Future<void> Function() task) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// SSE 무동작 대체 — 실 SseClient 는 listen 시 실네트워크 연결 + 재접속 타이머를
/// 걸어 골든 테스트를 죽인다 (pending timer). 빈 스트림으로 대체.
class FakeSse implements SseClient {
  @override
  Stream<SseEvent> get events => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 오프라인 고정 — connectivity_plus 플러그인 없이 isOnline=false 상태 렌더.
class OfflineConnectivity extends ConnectivityState {
  @override
  bool get isOnline => false;
}

/// 사장 로그인 완료 상태 — flutter_secure_storage 플러그인 없이 getter 만 대체.
class FakeBossAuth extends BossAuthState {
  @override
  bool get isLoggedIn => true;
  @override
  String? get loginId => 'boss01';
  @override
  String? get name => '박준서';
  @override
  String? get role => 'owner';
  @override
  int? get gymId => 1;
  @override
  String? get gymName => 'HYPHEN CrossFit 서면';
  @override
  String? get csrfToken => 'golden-csrf';
  @override
  String? get sessionCookie => 'session=golden';
}

/// 사장 전용 클라이언트의 가짜 — FakeApi 와 동일한 prefix 맵 방식.
/// 응답은 unwrap 이후의 data 맵을 그대로 넣는다.
class FakeBossApi implements BossApiClient {
  final Map<String, dynamic> responses;
  final Set<String> errorPaths;

  FakeBossApi(this.responses, {this.errorPaths = const {}});

  Future<Map<String, dynamic>> _respond(String path) async {
    if (errorPaths.any(path.startsWith)) {
      throw AppException('백엔드 OFF · 재시도', code: 'NETWORK');
    }
    for (final e in responses.entries) {
      if (path.startsWith(e.key)) {
        return Map<String, dynamic>.from(e.value as Map);
      }
    }
    throw AppException('골든 미정의 경로: $path', code: 'NO_FAKE');
  }

  @override
  void bindAuth(BossAuthState state) {}

  @override
  Future<Map<String, dynamic>> login(String loginId, String password) =>
      _respond('/api/v1/admin/login');

  @override
  Future<Map<String, dynamic>> get(String path) => _respond(path);

  @override
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _respond(path);

  @override
  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) =>
      _respond(path);

  @override
  Future<Map<String, dynamic>> delete(String path) => _respond(path);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ── 샘플 데이터 ─────────────────────────────────────────────

/// /api/v1/gyms/mine — 승인된 일반 회원 (박스: FACING CrossFit 서면).
const gymsMine = {
  'gym': {
    'id': 1,
    'name': 'HYPHEN CrossFit 서면',
    'location': '부산 부산진구',
    'member_count': 42,
    'is_official': false,
    'owner_hash': 'coachhash0001',
    'profile': {
      'phone': '051-123-4567',
      'coach_name': '박준서',
      'coach_bio': 'CF-L2 · 리저널 3회 출전',
      'class_schedule': '평일 06:00-22:00 · 토 10:00-14:00',
      'motto': 'Earn it.',
      'instagram': 'facing_seomyeon',
    },
  },
  'role': 'member',
  'status': 'approved',
  'member_id': 7,
  'member_profile': {
    'name': '김민준',
    'gender': 'male',
    'birth_date': '1998-03-14',
    'phone': '010-1234-5678',
    'level': 'RX',
  },
};

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// /api/v1/gyms/1/wods — 코치 오늘 WOD 보드 (rounds_data 구조화 포함).
/// 날짜는 실행 시점 기준 — 언제 갱신해도 TODAY 밴드가 살아있게 (writeplz generations 패턴).
List<Map<String, dynamic>> gymWods() {
  final now = DateTime.now();
  return [
    {
      'id': 31,
      'post_date': _ymd(now),
      'wod_type': 'for_time',
      'content': '21-15-9\nThruster 42.5kg\nPull-up',
      'scaled_version': '15-12-9\nThruster 30kg\nRing Row',
      'beginner_version': '12-9-6\nGoblet Squat 12kg\nRing Row',
      'scale_guide': 'Thruster 는 프론트랙 유지가 무너지면 중량을 낮춘다.',
      'rounds_data': [
        {
          'label': 'A. Metcon',
          'content': '21-15-9 Thruster + Pull-up',
          'time_cap_sec': 600,
          'movements': [
            {
              'name': 'Thruster',
              'slug': 'thruster',
              'reps': '21-15-9',
              'load_value': '42.5',
              'load_unit': 'kg',
            },
            {'name': 'Pull-up', 'slug': 'pull_up', 'reps': '21-15-9'},
          ],
        },
      ],
      'time_cap_sec': 600,
      'created_at': '${_ymd(now)}T06:30:00',
      'locked': false,
    },
    {
      'id': 30,
      'post_date': _ymd(now.subtract(const Duration(days: 1))),
      'wod_type': 'amrap',
      'content': 'AMRAP 20\n5 Pull-up\n10 Push-up\n15 Air Squat',
      'rounds_data': [],
      'time_cap_sec': 1200,
      'created_at': '${_ymd(now.subtract(const Duration(days: 1)))}T06:30:00',
      'locked': false,
    },
  ];
}

/// /api/v1/member/attendances — 최근 QR 체크인 6회 (실행 시점 기준).
List<Map<String, dynamic>> memberAttendances() {
  final now = DateTime.now();
  return [
    for (final ago in [1, 3, 5, 7, 10, 12])
      {'date': _ymd(now.subtract(Duration(days: ago))), 'count': 1},
  ];
}

/// /api/v1/member/classes — 오늘 저녁 2 + 내일 아침 1 (마감 1 포함).
List<Map<String, dynamic>> memberClasses() {
  final now = DateTime.now();
  final today = _ymd(now);
  final tomorrow = _ymd(now.add(const Duration(days: 1)));
  return [
    {
      'id': 101,
      'gym_id': 1,
      'start_at': '${today}T19:00:00',
      'duration_minutes': 60,
      'title': 'WOD Class',
      'description': '오늘의 WOD · 스케일 옵션 제공',
      'room': 'Main Floor',
      'coach_user_id': 11,
      'capacity': 12,
      'waitlist_capacity': 4,
      'reserved_count': 8,
      'waitlist_count': 0,
      'status': 'scheduled',
      'my_reservation': null,
      'my_waitlist_position': null,
    },
    {
      'id': 102,
      'gym_id': 1,
      'start_at': '${today}T20:00:00',
      'duration_minutes': 60,
      'title': 'Olympic Lifting',
      'description': 'Snatch 테크닉 · 소그룹',
      'room': 'Platform',
      'coach_user_id': 11,
      'capacity': 12,
      'waitlist_capacity': 4,
      'reserved_count': 12,
      'waitlist_count': 2,
      'status': 'scheduled',
      'my_reservation': null,
      'my_waitlist_position': null,
    },
    {
      'id': 103,
      'gym_id': 1,
      'start_at': '${tomorrow}T06:00:00',
      'duration_minutes': 60,
      'title': 'Morning WOD',
      'description': '출근 전 클래스',
      'room': 'Main Floor',
      'coach_user_id': 12,
      'capacity': 10,
      'waitlist_capacity': 4,
      'reserved_count': 3,
      'waitlist_count': 0,
      'status': 'scheduled',
      'my_reservation': null,
      'my_waitlist_position': null,
    },
  ];
}

/// /api/v1/member/me/memberships — 활성 회원권 1건 (진행률 살아있게 상대 날짜).
List<Map<String, dynamic>> memberMemberships() {
  final now = DateTime.now();
  return [
    {
      'id': 1,
      'gym_id': 1,
      'member_id': 7,
      'plan_name': '3개월 무제한',
      'start_date': _ymd(now.subtract(const Duration(days: 56))),
      'end_date': _ymd(now.add(const Duration(days: 34))),
      'price': 330000,
      'status': 'active',
    },
  ];
}

/// /api/v1/achievements — 업적 카탈로그 + 해금 2건.
const achievementsSnapshot = {
  'catalog': [
    {
      'code': 'FIRST_WOD',
      'name': 'First Blood',
      'description': '첫 WOD 기록 제출',
      'rarity': 'Common',
      'is_hidden': false,
      'sort_order': 1,
    },
    {
      'code': 'STREAK_7',
      'name': 'Consistency',
      'description': '7일 연속 출석',
      'rarity': 'Rare',
      'is_hidden': false,
      'sort_order': 2,
    },
    {
      'code': 'RX_FIRST',
      'name': 'RX Day',
      'description': '첫 RX 완수',
      'rarity': 'Rare',
      'is_hidden': false,
      'sort_order': 3,
    },
    {
      'code': 'ENGINE_80',
      'name': 'Big Engine',
      'description': 'Engine 80점 돌파',
      'rarity': 'Epic',
      'is_hidden': false,
      'sort_order': 4,
    },
  ],
  'unlocked': [
    {'code': 'FIRST_WOD', 'unlocked_at': '2026-07-10T10:00:00'},
    {'code': 'STREAK_7', 'unlocked_at': '2026-07-21T09:00:00'},
  ],
  'unlocked_count': 2,
  'visible_count': 4,
};

/// /api/v1/movements/categories — WOD 빌더 동작 카탈로그 (축약 4 카테고리).
const movementCategories = [
  {
    'slug': 'gymnastics',
    'name_ko': 'Gymnastics',
    'movements': [
      {
        'slug': 'pull_up',
        'name_ko': 'Pull-up',
        'unit': 'reps',
        'load_type': 'none',
        'required_metrics': ['max_unbroken'],
      },
      {
        'slug': 'toes_to_bar',
        'name_ko': 'Toes to Bar',
        'unit': 'reps',
        'load_type': 'none',
        'required_metrics': ['max_unbroken'],
      },
      {
        'slug': 'hspu',
        'name_ko': 'Handstand Push-up',
        'unit': 'reps',
        'load_type': 'none',
        'required_metrics': ['max_unbroken'],
      },
    ],
  },
  {
    'slug': 'bodyweight',
    'name_ko': 'Bodyweight',
    'movements': [
      {
        'slug': 'burpee',
        'name_ko': 'Burpee',
        'unit': 'reps',
        'load_type': 'none',
        'required_metrics': [],
      },
      {
        'slug': 'air_squat',
        'name_ko': 'Air Squat',
        'unit': 'reps',
        'load_type': 'none',
        'required_metrics': [],
      },
    ],
  },
  {
    'slug': 'cardio',
    'name_ko': 'Cardio',
    'movements': [
      {
        'slug': 'run',
        'name_ko': 'Run',
        'unit': 'meters',
        'load_type': 'none',
        'required_metrics': ['max_pace_sec_per_500m'],
      },
      {
        'slug': 'row',
        'name_ko': 'Row',
        'unit': 'meters',
        'load_type': 'none',
        'required_metrics': ['max_pace_sec_per_500m'],
      },
    ],
  },
  {
    'slug': 'weightlifting',
    'name_ko': 'Weightlifting',
    'movements': [
      {
        'slug': 'thruster',
        'name_ko': 'Thruster',
        'unit': 'reps',
        'load_type': 'barbell',
        'required_metrics': ['one_rep_max'],
      },
      {
        'slug': 'deadlift',
        'name_ko': 'Deadlift',
        'unit': 'reps',
        'load_type': 'barbell',
        'required_metrics': ['one_rep_max'],
      },
      {
        'slug': 'clean',
        'name_ko': 'Clean',
        'unit': 'reps',
        'load_type': 'barbell',
        'required_metrics': ['one_rep_max'],
      },
    ],
  },
];

/// /api/v1/wods/presets — 벤치마크 Girl WOD 3종.
const presetWods = [
  {
    'slug': 'fran',
    'name_ko': 'Fran',
    'description_ko': '가장 유명한 벤치마크. 짧고 강렬한 스프린트.',
    'category': 'girl',
    'wod_type': 'for_time',
    'time_cap_sec': 600,
    'rounds': null,
    'rx_time_advanced_sec': 180,
    'items': [
      {
        'movement_slug': 'thruster',
        'reps': 21,
        'load_value': 42.5,
        'load_unit': 'kg',
        'position': 0,
      },
      {'movement_slug': 'pull_up', 'reps': 21, 'position': 1},
    ],
  },
  {
    'slug': 'cindy',
    'name_ko': 'Cindy',
    'description_ko': '20분 AMRAP. 맨몸 지구력의 표준.',
    'category': 'girl',
    'wod_type': 'amrap',
    'time_cap_sec': 1200,
    'rounds': null,
    'rx_time_advanced_sec': null,
    'items': [
      {'movement_slug': 'pull_up', 'reps': 5, 'position': 0},
      {'movement_slug': 'burpee', 'reps': 10, 'position': 1},
      {'movement_slug': 'air_squat', 'reps': 15, 'position': 2},
    ],
  },
  {
    'slug': 'helen',
    'name_ko': 'Helen',
    'description_ko': '러닝과 케틀벨의 3라운드 클래식.',
    'category': 'girl',
    'wod_type': 'for_time',
    'time_cap_sec': 900,
    'rounds': 3,
    'rx_time_advanced_sec': 540,
    'items': [
      {'movement_slug': 'run', 'distance_m': 400, 'position': 0},
      {'movement_slug': 'pull_up', 'reps': 12, 'position': 1},
    ],
  },
];

/// /api/v1/pacing/calculate — Fran RX 페이싱 플랜 (백엔드 응답 스키마 동일).
const pacingPlanFran = {
  'formula_version': 'v2.3',
  'estimated_total_sec': 291,
  'estimated_total_display': '4:51',
  'segments': [
    {
      'movement_slug': 'thruster',
      'segment_type': 'reps',
      'split_pattern': [12, 9],
      'rest_between_sec': 10,
      'estimated_sec': 55,
      'estimated_display': '0:55',
      'is_explosion': false,
      'rationale_code': 'FRACTION_1RM',
      'rationale_ko': '1RM 대비 46% — 12+9 분할이 근신경 피로 누적을 지연.',
    },
    {
      'movement_slug': 'pull_up',
      'segment_type': 'reps',
      'split_pattern': [11, 10],
      'rest_between_sec': 15,
      'estimated_sec': 62,
      'estimated_display': '1:02',
      'is_explosion': false,
      'rationale_code': 'GRIP_DECAY',
      'rationale_ko': 'Max UB 15회 — 73% 지점 분할로 그립 유지.',
    },
    {
      'movement_slug': 'thruster',
      'segment_type': 'reps',
      'split_pattern': [9, 6],
      'rest_between_sec': 12,
      'estimated_sec': 44,
      'estimated_display': '0:44',
      'is_explosion': false,
      'rationale_code': 'FRACTION_1RM',
      'rationale_ko': '라운드 2 — W-prime 잔량 기준 세트 축소.',
    },
    {
      'movement_slug': 'pull_up',
      'segment_type': 'reps',
      'split_pattern': [8, 7],
      'rest_between_sec': 15,
      'estimated_sec': 50,
      'estimated_display': '0:50',
      'is_explosion': false,
      'rationale_code': 'GRIP_DECAY',
      'rationale_ko': '그립 잔량 유지 — 8+7.',
    },
    {
      'movement_slug': 'thruster',
      'segment_type': 'reps',
      'split_pattern': [9],
      'rest_between_sec': 0,
      'estimated_sec': 35,
      'estimated_display': '0:35',
      'is_explosion': false,
      'rationale_code': 'FINAL_ROUND',
      'rationale_ko': '마지막 라운드 — Unbroken.',
    },
    {
      'movement_slug': 'pull_up',
      'segment_type': 'reps',
      'split_pattern': [9],
      'rest_between_sec': 0,
      'estimated_sec': 45,
      'estimated_display': '0:45',
      'is_explosion': true,
      'rationale_code': 'BURST_FINAL',
      'rationale_ko': '마지막 9회 버스트 — 이후 동작 없음, 전량 소진.',
    },
  ],
};

/// /api/v1/admin/classes/101/reservations — D29 수업별 예약자 명단.
/// 코치 세션 가정이라 이름·전화가 이미 마스킹된 값 (마스킹 SSOT = 백엔드 _mask_pii).
/// 고아 예약(회원 행 삭제 + 예약 잔존) 1건 포함 — 실DB 에 존재하는 상태다.
Map<String, dynamic> classRoster() => {
      'class_session_id': 101,
      'title': 'WOD Class',
      'start_at': '2026-08-12T19:00:00',
      'room': 'Main Floor',
      'coach_user_id': 'coach_park',
      'capacity': 12,
      'confirmed_count': 4,
      'waitlist_count': 2,
      'items': [
        {
          'kind': 'reservation',
          'reservation_id': 1,
          'member_id': 11,
          'name': '김**',
          'phone': '010-****-1234',
          'status': 'confirmed',
          'orphan': false,
          'promoted_from_waitlist': false,
          'reserved_at': '2026-08-11T09:12:00',
        },
        {
          'kind': 'reservation',
          'reservation_id': 2,
          'member_id': 12,
          'name': '정**',
          'phone': '010-****-5678',
          'status': 'attended',
          'orphan': false,
          'promoted_from_waitlist': false,
          'reserved_at': '2026-08-11T10:30:00',
        },
        {
          'kind': 'reservation',
          'reservation_id': 3,
          'member_id': 13,
          'name': '강**',
          'phone': '010-****-9012',
          'status': 'no_show',
          'orphan': false,
          'promoted_from_waitlist': true,
          'reserved_at': '2026-08-11T18:05:00',
        },
        {
          'kind': 'reservation',
          'reservation_id': 4,
          'member_id': 99,
          'name': '탈퇴 회원',
          'phone': null,
          'status': 'confirmed',
          'orphan': true,
          'promoted_from_waitlist': false,
          'reserved_at': '2026-08-10T21:40:00',
        },
        {
          'kind': 'waitlist',
          'waitlist_id': 7,
          'member_id': 14,
          'name': '한**',
          'phone': '010-****-3456',
          'status': 'waitlisted',
          'orphan': false,
          'position': 1,
          'waitlisted_at': '2026-08-12T08:00:00',
        },
        {
          'kind': 'waitlist',
          'waitlist_id': 8,
          'member_id': 15,
          'name': '최**',
          'phone': '010-****-7890',
          'status': 'waitlisted',
          'orphan': false,
          'position': 2,
          'waitlisted_at': '2026-08-12T08:20:00',
        },
      ],
    };

/// /api/v1/admin/gyms/1/dashboard — 사장 대시보드 (오늘 운영, 실행 시점 상대 날짜).
Map<String, dynamic> bossDashboard() {
  final now = DateTime.now();
  return {
    'today': _ymd(now),
    'today_reservations': {
      'count': 14,
      'members': [
        {'id': 1, 'name': '김민준'},
        {'id': 2, 'name': '정하은'},
        {'id': 3, 'name': '강민재'},
      ],
    },
    'today_attendances': {
      'count': 9,
      'members': [
        {'id': 1, 'name': '김민준'},
        {'id': 4, 'name': '윤지원'},
      ],
    },
    'new_members_this_week': {
      'count': 3,
      'members': [
        {'id': 8, 'name': '한수아'},
        {'id': 9, 'name': '최서윤'},
        {'id': 10, 'name': '송예준'},
      ],
    },
    'today_classes': [
      {
        'id': 101,
        'title': 'WOD Class',
        'start_at': '${_ymd(now)}T19:00:00',
        'end_at': '${_ymd(now)}T20:00:00',
        'reserved': 8,
        'capacity': 12,
        'coaches': ['박준서'],
        'room': 'Main Floor',
        'status': 'scheduled',
      },
      {
        'id': 102,
        'title': 'Olympic Lifting',
        'start_at': '${_ymd(now)}T20:00:00',
        'end_at': '${_ymd(now)}T21:00:00',
        'reserved': 12,
        'capacity': 12,
        'coaches': ['박준서'],
        'room': 'Platform',
        'status': 'scheduled',
      },
    ],
    'expiring_soon': [
      {
        'member_id': 2,
        'name': '정하은',
        'd_day': 3,
        'end_date': _ymd(now.add(const Duration(days: 3))),
      },
      {
        'member_id': 5,
        'name': '윤지원',
        'd_day': 6,
        'end_date': _ymd(now.add(const Duration(days: 6))),
      },
    ],
  };
}

/// /api/v1/gyms/mine — 박스 미가입 (신규 가입 직후) 상태.
const gymsMineEmpty = {
  'gym': null,
  'role': null,
  'status': null,
};

/// 회원 셸 공용 기본 응답 맵 — 구체 경로 먼저 (prefix 매칭).
Map<String, dynamic> memberWorld() => {
      '/health': const <String, dynamic>{},
      '/api/v1/gyms/mine': gymsMine,
      '/api/v1/gyms/1/wods': gymWods(),
      '/api/v1/gyms/1/coaches': const {
        'coaches': [
          {
            'id': 1,
            'coach_user_id': 11,
            'gym_id': 1,
            'name': '박준서',
            'career': 'CF-L2 · 리저널 3회 출전',
            'certifications': 'CF-L2, USAW-L1',
            'specialty': 'Olympic Lifting',
            'pt_bookable': true,
            'hired_at': '2025-03-01T00:00:00',
            'display_order': 1,
          },
          {
            'id': 2,
            'coach_user_id': 12,
            'gym_id': 1,
            'name': '이서연',
            'career': 'CF-L1 · 지도 5년',
            'certifications': 'CF-L1',
            'specialty': 'Gymnastics',
            'pt_bookable': false,
            'hired_at': '2025-06-15T00:00:00',
            'display_order': 2,
          },
        ],
      },
      '/api/v1/gyms/1/announcements': const <dynamic>[],
      '/api/v1/member/announcements': const <dynamic>[],
      '/api/v1/member/attendances': memberAttendances(),
      '/api/v1/member/classes': memberClasses(),
      '/api/v1/member/reservations': const <dynamic>[],
      '/api/v1/member/me/memberships': memberMemberships(),
      '/api/v1/member/me/locker': const <dynamic>[],
      '/api/v1/member/points': const {'points': 300, 'history': <dynamic>[]},
      '/api/v1/achievements/check': const {'newly_unlocked': <dynamic>[]},
      '/api/v1/achievements': achievementsSnapshot,
      '/api/v1/movements/categories': movementCategories,
      '/api/v1/wods/presets': presetWods,
      '/api/v1/pacing/calculate': pacingPlanFran,
      '/api/v1/history/engine': const <dynamic>[],
      '/api/v1/history/wod': const <dynamic>[],
      '/api/v1/gym/1/inbox': const {'items': <dynamic>[]},
      '/api/v1/gym/1/outbox': const {'items': <dynamic>[]},
      '/api/v1/gym/1/threads': const {'items': <dynamic>[]},
      '/api/v1/gym/1/messages': const {'items': <dynamic>[]},
      '/api/v1/gym/1/groups': const {'groups': <dynamic>[]},
      '/api/v1/profile/info': const <String, dynamic>{},
    };
