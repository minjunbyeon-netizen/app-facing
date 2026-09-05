// PHASE4 §1.1 — 클래스 예약 시스템 폰 모델.
// 백엔드 endpoint:
//   GET    /api/v1/member/classes?from=&to=
//   GET    /api/v1/member/reservations
//   POST   /api/v1/member/classes/{id}/reservations
//   DELETE /api/v1/member/reservations/{id}

import '../core/app_clock.dart';
import '../core/time_format.dart';

class ClassSessionDto {
  final int id;
  final int gymId;
  final DateTime startAt;
  final int durationMinutes;
  final String title;
  final String? description;
  final String? room;
  final String? coachUserId;
  final int capacity;
  final int waitlistCapacity;
  final int reservedCount;
  final int waitlistCount;
  final String status; // open | cancelled | completed
  final String? track; // 수업 종류 (intro/rx/... 자유 문자열) — G25
  /// D111 (2026-09-04) — 이 수업이 붙은 수업 종류(class_templates.id). 수업 줄을
  /// 펼칠 때 그날 글(`GymWodPost.templateId`)을 찾는 유일한 축. 서버 `template_id`
  /// — 없으면(단발 수업·옛 서버) 프로그램을 붙이지 않는다 (이름으로 맞추지 않는다).
  final int? templateId;
  final String? color; // 캘린더 칩 hex — 파싱만, UI 미사용 (토큰 정책)
  final MyReservationDto? myReservation;
  final int? myWaitlistPosition;
  // D58 (2026-08-26) — 예약이 열리는 순간 (서버 booking_open_at). null = 제한 없음.
  final DateTime? bookingOpenAt;
  // 화면에 적는 수업 이름은 항상 [displayTitle] — 서버 `display_title` 그대로 (앱은
  // 붙이지 않는다). [title] 은 저장값(PC 편집칸용). D109 (2026-09-04): 구 D89 세션
  // 꼬리('AWAKE · A 세션', `variant`·`variant_label`)는 폐기 — 지금은 제목과 같다.
  final String displayTitle;
  /// 과제 4 (2026-08-30) — 그날 유효한 회원권이 있는가. 서버 예약 게이트(pick_membership)와
  /// 같은 함수의 답 (`membership_ok`). null = 서버가 안 준 것(코치 조회) → 배지는 정상.
  final bool? membershipOk;
  /// 2026-09-02 — 이 수업을 새로 예약하면 하루·주 한도에 걸리는가. 서버 예약
  /// 게이트와 같은 함수(reserve_limit_reached)의 답 — 'daily' | 'weekly' | null.
  /// null = 여유·미설정·코치 조회. 이 값이 있으면 앱은 그 줄의 **예약 배지를
  /// 세우지 않는다** (D119 · 2026-09-05 — 구 '오늘/이번 주 예약 완료' 배지 폐기).
  final String? reserveLimitReached;

  const ClassSessionDto({
    required this.id,
    required this.gymId,
    required this.startAt,
    required this.durationMinutes,
    required this.title,
    this.description,
    this.room,
    this.coachUserId,
    required this.capacity,
    required this.waitlistCapacity,
    required this.reservedCount,
    required this.waitlistCount,
    required this.status,
    this.track,
    this.templateId,
    this.color,
    this.myReservation,
    this.myWaitlistPosition,
    this.bookingOpenAt,
    String? displayTitle,
    this.membershipOk,
    this.reserveLimitReached,
  }) : displayTitle = displayTitle ?? title;

  /// 아직 예약이 안 열렸는가 — 서버 BOOKING_NOT_OPEN 의 표시용 거울 (정본은 서버).
  bool get isBookingNotOpen =>
      bookingOpenAt != null && appClock.now().isBefore(bookingOpenAt!);

  bool get isOpen => status == 'open';
  bool get isCancelled => status == 'cancelled';

  /// 종료 여부 — 시작 + 진행시간 경과. 서버 예약 게이트(CLASS_ENDED)의 UX 거울
  /// (정본은 서버 — 기기 시계가 틀려도 서버가 최종 거절한다).
  /// 주간 보드(week_board)의 시작 시각 기준 isOver 보다 느슨하다 — 진행 중
  /// 지각 예약은 이 화면 경로로만 열려 있다 (서버 컷오프와 동일).
  bool get isEnded => appClock
      .now()
      .isAfter(startAt.add(Duration(minutes: durationMinutes)));
  bool get isFull => reservedCount >= capacity;
  bool get isReserved => myReservation?.status == 'confirmed';
  bool get isWaitlisted => myWaitlistPosition != null;

  factory ClassSessionDto.fromJson(Map<String, dynamic> j) => ClassSessionDto(
        id: (j['id'] as num).toInt(),
        gymId: (j['gym_id'] as num?)?.toInt() ?? 0,
        // S7: naive 시각은 KST 로 고정 — 기기 시간대와 무관하게 '시작 지남' 판정.
        startAt: parseServerTime(j['start_at'] as String),
        durationMinutes: (j['duration_minutes'] as num?)?.toInt() ?? 60,
        title: (j['title'] ?? '수업').toString(),
        description: j['description']?.toString(),
        room: j['room']?.toString(),
        coachUserId: j['coach_user_id']?.toString(),
        capacity: (j['capacity'] as num?)?.toInt() ?? 0,
        waitlistCapacity: (j['waitlist_capacity'] as num?)?.toInt() ?? 0,
        reservedCount: (j['reserved_count'] as num?)?.toInt() ?? 0,
        waitlistCount: (j['waitlist_count'] as num?)?.toInt() ?? 0,
        status: (j['status'] ?? 'open').toString(),
        track: j['track']?.toString(),
        templateId: (j['template_id'] as num?)?.toInt(),
        color: j['color']?.toString(),
        myReservation: j['my_reservation'] is Map<String, dynamic>
            ? MyReservationDto.fromJson(j['my_reservation'] as Map<String, dynamic>)
            : null,
        myWaitlistPosition: (j['my_waitlist_position'] as num?)?.toInt(),
        bookingOpenAt: j['booking_open_at'] is String
            ? parseServerTime(j['booking_open_at'] as String)
            : null,
        displayTitle: j['display_title']?.toString(),
        membershipOk: j['membership_ok'] is bool ? j['membership_ok'] as bool : null,
        reserveLimitReached: j['reserve_limit_reached'] is String
            ? j['reserve_limit_reached'] as String
            : null,
      );
}

class MyReservationDto {
  final int reservationId;
  final String status;
  final bool promotedFromWaitlist;

  const MyReservationDto({
    required this.reservationId,
    required this.status,
    required this.promotedFromWaitlist,
  });

  factory MyReservationDto.fromJson(Map<String, dynamic> j) =>
      MyReservationDto(
        reservationId: (j['reservation_id'] as num).toInt(),
        status: (j['status'] ?? '').toString(),
        promotedFromWaitlist: j['promoted_from_waitlist'] == true,
      );
}

class MyReservationItem {
  final String kind; // 'reservation' | 'waitlist'
  final int id; // reservation_id 또는 waitlist_id
  final int classSessionId;
  final DateTime startAt;
  final int durationMinutes;
  final String title;
  // 화면 이름 — 서버 display_title, 없으면 title (D109: 세션 꼬리 없음).
  final String displayTitle;
  final String? room;
  final String status;
  final int? position; // waitlist 만
  final bool promotedFromWaitlist;

  const MyReservationItem({
    required this.kind,
    required this.id,
    required this.classSessionId,
    required this.startAt,
    required this.durationMinutes,
    required this.title,
    String? displayTitle,
    this.room,
    required this.status,
    this.position,
    this.promotedFromWaitlist = false,
  }) : displayTitle = displayTitle ?? title;

  bool get isWaitlist => kind == 'waitlist';

  factory MyReservationItem.fromJson(Map<String, dynamic> j) {
    final isWl = j['kind'] == 'waitlist';
    return MyReservationItem(
      kind: (j['kind'] ?? 'reservation').toString(),
      id: ((isWl ? j['waitlist_id'] : j['reservation_id']) as num).toInt(),
      classSessionId: (j['class_session_id'] as num).toInt(),
      startAt: parseServerTime(j['start_at'] as String),
      durationMinutes: (j['duration_minutes'] as num?)?.toInt() ?? 60,
      title: (j['title'] ?? '수업').toString(),
      displayTitle: j['display_title']?.toString(),
      room: j['room']?.toString(),
      status: (j['status'] ?? '').toString(),
      position: (j['position'] as num?)?.toInt(),
      promotedFromWaitlist: j['promoted_from_waitlist'] == true,
    );
  }
}
