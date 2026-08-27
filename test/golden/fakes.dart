import 'dart:async';

import 'package:hyphen_app/core/api_client.dart';
import 'package:hyphen_app/core/connectivity_state.dart';
import 'package:hyphen_app/core/exception.dart';
import 'package:hyphen_app/core/sse_client.dart';
import 'package:hyphen_app/features/boss/boss_api_client.dart';
import 'package:hyphen_app/features/boss/boss_auth_state.dart';
import 'package:hyphen_app/core/app_clock.dart';

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

  FakeApi(
    this.responses, {
    this.hang = false,
    this.hangPaths = const {},
    this.errorPaths = const {},
  });

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
    String path,
    Map<String, dynamic> body,
  ) async {
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
  /// D59 세션 만료 골든 — expire()/clear() 가 이 값을 내린다 (secure storage 없이).
  bool loggedIn = true;

  @override
  bool get isLoggedIn => loggedIn;

  @override
  Future<void> expire() async {
    if (!loggedIn) return;
    loggedIn = false;
    notifyListeners();
  }

  @override
  Future<void> clear() async {
    loggedIn = false;
    notifyListeners();
  }

  @override
  String? get loginId => 'boss01';
  @override
  String? get name => '박준서';
  @override
  String? get role => 'owner';
  @override
  int? get gymId => 1;
  @override
  String? get gymName => 'HYPHEN 서면';
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

  /// D59 — 이 경로는 서버 세션 만료(401 UNAUTHORIZED)처럼 군다: 실물
  /// BossApiClient._checkSession 과 같이 auth.expire() 뒤 예외.
  final Set<String> unauthorizedPaths;
  BossAuthState? _auth;

  FakeBossApi(
    this.responses, {
    this.errorPaths = const {},
    this.unauthorizedPaths = const {},
  });

  Future<void> _checkSession(String path) async {
    if (unauthorizedPaths.any(path.startsWith)) {
      // 실물은 네트워크 왕복 뒤에 온다 — initState 의 build 중에 notify 하지
      // 않도록 한 틱 양보.
      await Future<void>.delayed(Duration.zero);
      await _auth?.expire();
      throw AppException('로그인이 필요합니다.',
          code: 'UNAUTHORIZED', statusCode: 401);
    }
  }

  Future<Map<String, dynamic>> _respond(String path) async {
    await _checkSession(path);
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
  void bindAuth(BossAuthState state) {
    _auth = state;
  }

  @override
  Future<Map<String, dynamic>> login(String loginId, String password) =>
      _respond('/api/v1/admin/login');

  // v3.19 로그인 창구 통합 — 앱이 실제로 부르는 창구는 이쪽 하나다.
  @override
  Future<Map<String, dynamic>> unifiedLogin(String loginId, String password) =>
      _respond('/api/v1/auth/login');

  @override
  Future<Map<String, dynamic>> get(String path) => _respond(path);

  // v3.28 주간 수업 목록 — 경로 prefix 로 찾아 List 그대로 (쿼리스트링 무시).
  @override
  Future<List<dynamic>> getList(String path) async {
    await _checkSession(path);
    if (errorPaths.any(path.startsWith)) {
      throw AppException('백엔드 OFF · 재시도', code: 'NETWORK');
    }
    for (final e in responses.entries) {
      if (path.startsWith(e.key)) return List<dynamic>.from(e.value as List);
    }
    throw AppException('골든 미정의 경로: $path', code: 'NO_FAKE');
  }

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

/// /api/v1/gyms/mine — 승인된 일반 회원 (박스: HYPHEN CrossFit 서면).
/// /api/v1/gyms/1/members — 코치 시점 회원 목록 (새 쪽지 받는 사람 고르기, v3.28).
List<Map<String, dynamic>> gymMembersList() => [
      {
        'id': 41, 'device_hash_prefix': 'a1b2c3d4', 'device_hash': 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2',
        'status': 'approved', 'requested_at': '2026-07-01T10:00:00',
        'decided_at': '2026-07-01T11:00:00', 'name': '김민준', 'phone': '010-1234-5678',
        'level': 'rxd', 'total_sessions': 42, 'streak_days': 5,
      },
      {
        'id': 42, 'device_hash_prefix': 'b2c3d4e5', 'device_hash': 'b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3',
        'status': 'approved', 'requested_at': '2026-07-10T10:00:00',
        'decided_at': '2026-07-10T11:00:00', 'name': '박서연', 'phone': '010-2345-6789',
        'level': 'scaled', 'total_sessions': 12, 'streak_days': 2,
      },
      {
        'id': 43, 'device_hash_prefix': 'c3d4e5f6', 'device_hash': 'c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4',
        'status': 'pending', 'requested_at': '2026-08-20T10:00:00', 'name': '이도윤',
        'total_sessions': 0, 'streak_days': 0,
      },
    ];

const gymsMine = {
  'gym': {
    'id': 1,
    'name': 'HYPHEN 서면',
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
  final now = appClock.now();
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
      // v3.16 기록 UX 2·3 — 서버 추천 (score_hint + 동작 이름 후보).
      'score_hint': 'time',
      'movement_suggestions': ['Thruster'],
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
      'score_hint': 'rounds',
      'movement_suggestions': <String>[],
    },
  ];
}

/// P3 — 도전 카드 (reward-progress). 문장·진행률은 서버 완성분 그대로.
List<Map<String, dynamic>> rewardProgressRows() => [
  {
    'rule_id': 1,
    'category': 3,
    'label': '달리기 인증',
    'trigger': 'custom',
    'sentence': '달리기 인증 매주 2회 달성 시 100P 적립 — 주기마다 반복',
    'progress': 1,
    'target': 2,
    'pending': 1,
    'done_this_window': false,
    'can_log': true,
  },
  {
    'rule_id': 2,
    'category': 1,
    'label': '주간 출석 3회',
    'trigger': 'attendance',
    'sentence': '출석 매주 3회 달성 시 300P 적립 — 주기마다 반복',
    'progress': 3,
    'target': 3,
    'pending': 0,
    'done_this_window': true,
    'can_log': false,
  },
];

/// Q3 (v3.4) — 수업 상세 "내 이전 기록" (오늘 WOD 31 = Fran 계열 for_time).
/// 최근이 위, PR 은 최신 기록에.
Map<String, dynamic> wodMyHistory() {
  final now = appClock.now();
  return {
    'kind': 'time',
    'items': [
      {'wod_post_id': 31, 'date': _ymd(now), 'label': '4:18', 'is_pr': true},
      {
        'wod_post_id': 29,
        'date': _ymd(now.subtract(const Duration(days: 7))),
        'label': '4:30',
        'is_pr': false,
      },
      {
        'wod_post_id': 27,
        'date': _ymd(now.subtract(const Duration(days: 14))),
        'label': '5:02',
        'is_pr': false,
      },
    ],
  };
}

/// Q3 (v3.4) — 1RM 보드 (리프트별 역대 최고 무게).
List<Map<String, dynamic>> strengthBoard() {
  final now = appClock.now();
  return [
    {
      'movement': 'Back Squat',
      'best_kg': 105,
      'best_reps': 3,
      'best_date': _ymd(now),
      'last_kg': 105,
      'last_date': _ymd(now),
      'count': 4,
    },
    {
      'movement': 'Deadlift',
      'best_kg': 140,
      'best_reps': 1,
      'best_date': _ymd(now.subtract(const Duration(days: 21))),
      'last_kg': 135,
      'last_date': _ymd(now.subtract(const Duration(days: 7))),
      'count': 3,
    },
    {
      'movement': 'Shoulder Press',
      'best_kg': 52.5,
      'best_reps': 5,
      'best_date': _ymd(now.subtract(const Duration(days: 10))),
      'last_kg': 50,
      'last_date': _ymd(now.subtract(const Duration(days: 3))),
      'count': 2,
    },
  ];
}

/// 오늘 WOD 가 Strength(무게 측정일)인 변형 — 결과 시트 무게 입력 분기 골든용.
/// v3.4 (2026-08-20 승인 — docs/PLAN-record-structures.md Part A).
List<Map<String, dynamic>> gymWodsStrengthToday() {
  final now = appClock.now();
  return [
    {
      'id': 33,
      'post_date': _ymd(now),
      'wod_type': 'strength',
      'content': 'Back Squat 5x5\n무거운 5회 × 5세트 — 마지막 세트 최고 무게를 기록',
      'rounds_data': [
        {
          'label': 'A. Strength',
          'content': 'Back Squat 5x5',
          'movements': [
            {'name': 'Back Squat', 'slug': 'back_squat', 'reps': '5x5'},
          ],
        },
      ],
      // 결함 수정 4 — 기존 기록 상태 (카드 '기록 105kg' 배지 + 시트 프리필·
      // 덮어쓰기 안내를 한 캡처로).
      'my_result': {
        'weight_kg': 105,
        'weight_reps': 3,
        'scale_level': 'rx',
        'display': '105kg×3',
      },
      'created_at': '${_ymd(now)}T06:30:00',
      'locked': false,
      'score_hint': 'weight',
      'movement_suggestions': ['Back Squat'],
    },
  ];
}

/// /api/v1/member/attendances — 최근 QR 체크인 6회 (실행 시점 기준).
List<Map<String, dynamic>> memberAttendances() {
  final now = appClock.now();
  return [
    for (final ago in [1, 3, 5, 7, 10, 12])
      {'date': _ymd(now.subtract(Duration(days: ago))), 'count': 1},
  ];
}

/// 오늘 [hour] 시 정각.
///
/// v2.6 (2026-08-13): 구 `_todayLater(now, minutes)` 폐기 — "지금부터 N분 뒤"를
/// 10분 단위로 깎아 쓰다 보니 **화면에 찍히는 시각이 10분마다 바뀌어**
/// `member_01_shell_wod` · `state_01_wod_error` 골든이 계속 깨졌다 (회귀 게이트가
/// 아니라 시계를 검사하고 있었다). 시각을 고정하면 라벨이 결정론적이 된다.
///
/// 저녁 시간대를 쓰는 이유는 v2.4 때와 같다 — 캡처 시점이 대개 그 전이라
/// "아직 안 지난 오늘 수업"으로 남아 예약 버튼이 골든에 찍힌다.
/// (날짜 흔들림은 2026-08-14 해소 — 앱 코드 DateTime.now() 전량을 `appClock.now()`
/// 로 갈았고, flutter_test_config 의 `kTestClock`(Clock.fixed 2026-08-12 10:30)
/// 이 모든 테스트의 시각을 고정한다. 이 파일의 `appClock.now()` 도 같은 값을 받는다.)
String _todayAt(DateTime now, int hour) =>
    '${_ymd(now)}T${hour.toString().padLeft(2, '0')}:00:00';

/// /api/v1/member/classes — 오늘 남은 시간대 2 + 내일 아침 1 (마감 1 포함).
List<Map<String, dynamic>> memberClasses() {
  final now = appClock.now();
  final tomorrow = _ymd(now.add(const Duration(days: 1)));
  return [
    {
      'id': 101,
      'gym_id': 1,
      'start_at': _todayAt(now, 20),
      'duration_minutes': 60,
      'title': 'WOD Class',
      'description': '오늘의 수업 내용 · 스케일 옵션 제공',
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
      'start_at': _todayAt(now, 21),
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

/// /api/v1/member/classes — 위와 동일하되 20시 수업에 내 예약 확정 (예약됨 상태 캡처용).
List<Map<String, dynamic>> memberClassesReserved() {
  final list = memberClasses();
  list[0] = {
    ...list[0],
    'reserved_count': 9,
    'my_reservation': {
      'reservation_id': 55,
      'status': 'confirmed',
      'promoted_from_waitlist': false,
    },
  };
  return list;
}

/// /api/v1/member/classes — 위와 동일 + 이미 끝난 오전 수업 1 (종료 배지 캡처용).
/// kTestClock 10:30 기준 08:00+60분 = 09:00 종료 → isEnded true.
List<Map<String, dynamic>> memberClassesWithEnded() {
  final now = appClock.now();
  return [
    {
      'id': 100,
      'gym_id': 1,
      'start_at': _todayAt(now, 8),
      'duration_minutes': 60,
      'title': 'Morning Metcon',
      'description': '오전 컨디셔닝 · 소그룹',
      'room': 'Main Floor',
      'coach_user_id': 11,
      'capacity': 12,
      'waitlist_capacity': 4,
      'reserved_count': 10,
      'waitlist_count': 0,
      'status': 'scheduled',
      'my_reservation': null,
      'my_waitlist_position': null,
    },
    ...memberClasses(),
  ];
}

/// /api/v1/member/classes — 21시 만석 수업에 내가 대기 1번 (대기 취소 캡처용).
List<Map<String, dynamic>> memberClassesWaitlisted() {
  final list = memberClasses();
  list[1] = {...list[1], 'my_waitlist_position': 1};
  return list;
}

/// /api/v1/admin/gyms/1/class-settings — 예약 정책 (설정 예약 탭 골든용).
const bossClassSettings = {
  'gym_id': 1,
  'daily_reservation_limit': 2,
  'updated_at': null,
};

/// /api/v1/admin/gyms/1/plans — 설정 첫 탭(요금제)이 mount 시 먼저 부른다.
const bossPlansEmpty = {'plans': []};

/// 같은 경로 — 요금제가 있는 박스. 표기 한글화(2026-08-25) 확인용:
/// 기간제·횟수제·비활성 3형태를 한 화면에 담는다.
const bossPlans = {
  'plans': [
    {
      'id': 1,
      'name': '3개월권',
      'plan_type': 'time_based',
      'price_krw': 630000,
      'duration_days': 90,
      'session_count': null,
      'is_active': true,
    },
    {
      'id': 2,
      'name': '수강권 10회',
      'plan_type': 'session_based',
      'price_krw': 176000,
      'duration_days': null,
      'session_count': 10,
      'is_active': true,
    },
    {
      'id': 3,
      'name': '6개월권',
      'plan_type': 'time_based',
      'price_krw': 1200000,
      'duration_days': 180,
      'session_count': null,
      'is_active': false,
    },
  ],
};

/// /api/v1/member/me/contracts — 회원 전자계약 2건 (서명 완료 1 + 서명 대기 1).
const memberContracts = [
  {
    'id': 1,
    'status': 'signed',
    'template_name': '회원권 이용 계약',
    'created_at': '2026-08-01T10:00:00',
    'signed_at': '2026-08-02T18:30:00',
  },
  {
    'id': 2,
    'status': 'sent',
    'template_name': '개인정보 수집·이용 동의서',
    'created_at': '2026-08-10T09:00:00',
    'signed_at': null,
  },
];

/// /api/v1/member/contracts/2 — 서명 대기 계약 상세.
/// variable_labels 는 서버가 내려주는 한글 항목 이름 (2026-08-25 갭 해소).
const memberContractDetail = {
  'id': 2,
  'status': 'sent',
  'template_name': '회원권 이용 계약',
  'template_category': 'membership',
  'body_text': null,
  'variables': {
    'member_name': '박서준',
    'member_phone': '010-1234-5678',
    'plan_name': '3개월권',
    'start_date': '2026-08-01',
    'end_date': '2026-10-30',
    'price': '630,000',
    'payment_method': '카드',
    'gym_name': 'HYPHEN',
  },
  'variable_labels': {
    'member_name': '회원 이름',
    'member_phone': '회원 전화',
    'plan_name': '회원권 종류',
    'start_date': '시작일',
    'end_date': '종료일',
    'price': '결제 금액',
    'payment_method': '결제 수단',
    'gym_name': '체육관 이름',
  },
  'pdf_path': null,
  'sent_at': '2026-08-10T09:00:00',
  'viewed_at': null,
  'signed_at': null,
  'created_at': '2026-08-10T09:00:00',
};

/// /api/v1/member/me/memberships — 활성 회원권 1건 (진행률 살아있게 상대 날짜).
List<Map<String, dynamic>> memberMemberships() {
  final now = appClock.now();
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

/// 횟수권 1건 — D57 내 정보 카드 '2회 남음'·면제 잔여 골든용 (state_14).
/// 서버 session_summary 필드를 그대로 흉내 (3회 중 1회 사용).
List<Map<String, dynamic>> memberMembershipsSessionPass() {
  final now = appClock.now();
  return [
    {
      'id': 3,
      'gym_id': 1,
      'member_id': 7,
      'plan_name': '이벤트 3회권',
      'start_date': _ymd(now.subtract(const Duration(days: 3))),
      'end_date': _ymd(now.add(const Duration(days: 27))),
      'price': 9900,
      'status': 'active',
      'session_total': 3,
      'session_used': 1,
      'session_remaining': 2,
      'no_show_count': 0,
      'late_cancel_count': 0,
      'free_no_show_left': 1,
      'free_late_cancel_left': 1,
    },
  ];
}

/// 예약 오픈 전 수업 — D58 '오픈 전' 배지 골든용 (state_15). 모레 수업, 오픈 = 내일 11:00.
List<Map<String, dynamic>> memberClassesBookingNotOpen() {
  final now = appClock.now();
  final dayAfter = _ymd(now.add(const Duration(days: 2)));
  final tomorrow = _ymd(now.add(const Duration(days: 1)));
  return [
    ...memberClasses(),
    {
      'id': 104,
      'gym_id': 1,
      'start_at': '${dayAfter}T06:00:00',
      'duration_minutes': 60,
      'title': 'AWAKE',
      'description': null,
      'room': null,
      'coach_user_id': 11,
      'capacity': 12,
      'waitlist_capacity': 4,
      'reserved_count': 0,
      'waitlist_count': 0,
      'status': 'open',
      'my_reservation': null,
      'my_waitlist_position': null,
      'booking_open_at': '${tomorrow}T11:00:00',
    },
  ];
}

/// 만료된 회원권만 1건 — S5 '회원권 필요' 배지 골든용 (state_11).
List<Map<String, dynamic>> memberMembershipsExpired() {
  final now = appClock.now();
  return [
    {
      'id': 1,
      'gym_id': 1,
      'member_id': 7,
      'plan_name': '1개월 무제한',
      'start_date': _ymd(now.subtract(const Duration(days: 40))),
      'end_date': _ymd(now.subtract(const Duration(days: 10))),
      'price': 130000,
      'status': 'expired',
    },
  ];
}

/// /api/v1/achievements — 업적 카탈로그 + 해금 2건.
/// v3.2 (2026-08-20): 백엔드 카탈로그 대수술(달성 불가 Engine 계열 삭제 +
/// icon·points·repeat_kind 필드 신설)에 맞춰 실시드 코드로 교체.
const achievementsSnapshot = {
  'catalog': [
    {
      'code': 'WOD_10',
      'name': 'First Ten.',
      'description': '수업 기록 10회.',
      'rarity': 'Common',
      'is_hidden': false,
      'sort_order': 85,
      'icon': 'barbell',
      'points': 100,
      'repeat_kind': 'once',
    },
    {
      'code': 'VOL_TRIPLE_STREAK',
      'name': 'Triple Threat Week.',
      'description': '3주 연속 주 4회 기록.',
      'rarity': 'Epic',
      'is_hidden': false,
      'sort_order': 530,
      'icon': 'flame',
      'points': 0,
      'repeat_kind': 'repeat',
    },
    {
      'code': 'PR_FIRST',
      'name': 'First PR.',
      'description': '첫 개인 기록 갱신.',
      'rarity': 'Common',
      'is_hidden': false,
      'sort_order': 410,
      'icon': 'trophy',
      'points': 0,
      'repeat_kind': 'once',
    },
    {
      'code': 'CF_OPEN_SURVIVOR',
      'name': 'Open Survivor.',
      'description': 'CrossFit Open 기간 (2/22~3/15) 기록 5회.',
      'rarity': 'Epic',
      'is_hidden': false,
      'sort_order': 610,
      'icon': 'flag',
      'points': 0,
      'repeat_kind': 'once',
    },
  ],
  'unlocked': [
    {'code': 'WOD_10', 'unlocked_at': '2026-07-10T10:00:00'},
    {'code': 'PR_FIRST', 'unlocked_at': '2026-07-21T09:00:00'},
  ],
  'unlocked_count': 2,
  'visible_count': 4,
};

/// 등급 4단 + 판 모양 3종이 실제로 구분돼 보이는지 고정하는 표본
/// (2026-08-21 — 팩 체크리스트 "전설이 검은 판인지·32px 에서도 모양이 갈리는지").
/// 전부 해금 상태로 둔다 — 잠기면 회색이라 등급 색을 볼 수 없다.
const achievementsAllRarities = {
  'catalog': [
    {
      'code': 'WOD_10',
      'name': 'First Ten.',
      'description': '수업 기록 10회.',
      'rarity': 'Common',
      'is_hidden': false,
      'sort_order': 10,
      'icon': 'barbell',
      'points': 100,
      'repeat_kind': 'once',
    },
    {
      'code': 'STREAK_7',
      'name': 'Seven Straight.',
      'description': '7일 연속 출석.',
      'rarity': 'Rare',
      'is_hidden': false,
      'sort_order': 20,
      'icon': 'flame',
      'points': 200,
      'repeat_kind': 'once',
    },
    {
      'code': 'PR_10',
      'name': 'PR Hunter.',
      'description': 'PR 10회 누적.',
      'rarity': 'Epic',
      'is_hidden': false,
      'sort_order': 30,
      'icon': 'trophy',
      'points': 300,
      'repeat_kind': 'once',
    },
    {
      'code': 'GAMES_1',
      'name': 'Games Finisher.',
      'description': 'Games WOD 완주 — 코치 확인.',
      'rarity': 'Legendary',
      'is_hidden': false,
      'sort_order': 40,
      'icon': 'crown',
      'points': 1000,
      'repeat_kind': 'once',
    },
    {
      'code': 'GIRLS_FRAN',
      'name': 'Fran.',
      'description': 'Fran 완주 — 코치 확인.',
      'rarity': 'Rare',
      'is_hidden': false,
      'sort_order': 50,
      'icon': 'ribbon',
      'points': 200,
      'repeat_kind': 'once',
    },
    {
      'code': 'EGG_1',
      'name': '???',
      'description': '숨김 업적.',
      'rarity': 'Epic',
      'is_hidden': true,
      'sort_order': 60,
      'icon': 'star',
      'points': 0,
      'repeat_kind': 'once',
    },
  ],
  'unlocked': [
    {'code': 'WOD_10', 'unlocked_at': '2026-07-10T10:00:00'},
    {'code': 'STREAK_7', 'unlocked_at': '2026-07-12T10:00:00'},
    {'code': 'PR_10', 'unlocked_at': '2026-07-14T10:00:00'},
    {'code': 'GAMES_1', 'unlocked_at': '2026-07-16T10:00:00'},
    {'code': 'GIRLS_FRAN', 'unlocked_at': '2026-07-18T10:00:00'},
  ],
  'unlocked_count': 5,
  'visible_count': 6,
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
/// 코치 세션 가정 — D30 이후 이름은 평문, 전화만 마스킹된 값이 온다
/// (마스킹 SSOT = 백엔드 _mask_pii · scope members_name_full).
/// 고아 예약(회원 행 삭제 + 예약 잔존) 1건 포함 — 실DB 에 존재하는 상태다.
/// 대기 position 은 저장값이 아니라 백엔드가 매번 다시 센 현재 순번 (D31).
// S3 (2026-08-26): 출석 배지는 시작 후에만 — 기본 명단은 시작이 지난 수업
// (테스트 시각 10:30 기준 09:00). 시작 전 잠금 상태는 [classRosterUpcoming].
Map<String, dynamic> classRosterUpcoming() => {
  ...classRoster(),
  'start_at': '2026-08-12T19:00:00',
};

Map<String, dynamic> classRoster() => {
  'class_session_id': 101,
  'title': 'WOD Class',
  'start_at': '2026-08-12T09:00:00',
  'room': 'Main Floor',
  'coach_user_id': 'coach_park',
  'coach_name': '박지훈', // S10 — 머리에 아이디 대신 이름
  'capacity': 12,
  // G24 2차 — 수정 시트 프리필용 (백엔드 admin_list_class_reservations 동봉).
  'duration_minutes': 60,
  'track': 'RX',
  'confirmed_count': 4,
  'waitlist_count': 2,
  'items': [
    {
      'kind': 'reservation',
      'reservation_id': 1,
      'member_id': 11,
      'name': '김도윤',
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
      'name': '정하은',
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
      'name': '강민석',
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
      'name': '한서연',
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
      'name': '최지우',
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
  final now = appClock.now();
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
const gymsMineEmpty = {'gym': null, 'role': null, 'status': null};

/// /api/v1/gyms/mine — 가입 신청은 냈고 코치 승인 대기 중 (v2.8 승인 대기 게이트).
final Map<String, dynamic> gymsMinePending = {...gymsMine, 'status': 'pending'};

/// /api/v1/member/announcements — 홈 공지 아코디언 노출용 (R7 소스 교체 검증).
/// 기본 memberWorld 는 빈 목록 유지 (기존 골든 보존) — 아코디언 골든에서만 주입.
/// 정렬 기대: 핀 고정(휴관 안내) 먼저, 나머지 최신순.
List<Map<String, dynamic>> memberAnnouncements() {
  final now = appClock.now();
  String daysAgo(int d) => '${_ymd(now.subtract(Duration(days: d)))}T09:00:00';
  return [
    {
      'id': 1,
      'title': '휴관 안내',
      'body': '8월 15일 광복절 휴관. 당일 예약 수업은 자동 취소됩니다.',
      'priority': 'urgent',
      'pinned': true,
      'category': 'notice',
      'visible_to': 'all',
      'created_at': daysAgo(4),
    },
    {
      'id': 2,
      'title': '저녁 수업 신설',
      'body': '저녁 8시 수업 추가. 예약 화면에서 신청.',
      'priority': 'normal',
      'pinned': false,
      'category': 'notice',
      'visible_to': 'all',
      'created_at': daysAgo(1),
    },
    {
      'id': 3,
      'title': '샤워실 보수 공사',
      'body': '이번 주 금요일 오전 샤워실 이용 불가.',
      'priority': 'normal',
      'pinned': false,
      'category': 'notice',
      'visible_to': 'all',
      'created_at': daysAgo(2),
    },
  ];
}

/// 회원 셸 공용 기본 응답 맵 — 구체 경로 먼저 (prefix 매칭).
Map<String, dynamic> memberWorld() => {
  '/health': const <String, dynamic>{},
  '/api/v1/gyms/mine': gymsMine,
  // 하위 경로(results·comments·feedback)가 아래 '/api/v1/gyms/1/wods'
  // prefix 에 삼켜져 WOD 목록이 리더보드 행으로 오염되던 충돌 방지
  // (2026-08-19 골든 확장에서 발견 — "0th user:" 유령 행). 구체 경로 먼저.
  // Q3 (v3.4) — 오늘 WOD(id 31)의 내 이전 기록. 구체 경로라 맨 앞.
  '/api/v1/gyms/1/wods/31/my-history': wodMyHistory(),
  // P3 — 도전 카드 (홈). custom 1건(인증 가능·대기 1) + 자동 1건(달성).
  '/api/v1/member/me/reward-progress': rewardProgressRows(),
  '/api/v1/gyms/1/wods/': const <dynamic>[],
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
