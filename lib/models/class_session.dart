// PHASE4 §1.1 — 클래스 예약 시스템 폰 모델.
// 백엔드 endpoint:
//   GET    /api/v1/member/classes?from=&to=
//   GET    /api/v1/member/reservations
//   POST   /api/v1/member/classes/{id}/reservations
//   DELETE /api/v1/member/reservations/{id}

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
  final String? color; // 캘린더 칩 hex — 파싱만, UI 미사용 (토큰 정책)
  final MyReservationDto? myReservation;
  final int? myWaitlistPosition;

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
    this.color,
    this.myReservation,
    this.myWaitlistPosition,
  });

  bool get isOpen => status == 'open';
  bool get isCancelled => status == 'cancelled';
  bool get isFull => reservedCount >= capacity;
  bool get isReserved => myReservation?.status == 'confirmed';
  bool get isWaitlisted => myWaitlistPosition != null;

  factory ClassSessionDto.fromJson(Map<String, dynamic> j) => ClassSessionDto(
        id: (j['id'] as num).toInt(),
        gymId: (j['gym_id'] as num?)?.toInt() ?? 0,
        startAt: DateTime.parse(j['start_at'] as String),
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
        color: j['color']?.toString(),
        myReservation: j['my_reservation'] is Map<String, dynamic>
            ? MyReservationDto.fromJson(j['my_reservation'] as Map<String, dynamic>)
            : null,
        myWaitlistPosition: (j['my_waitlist_position'] as num?)?.toInt(),
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
    this.room,
    required this.status,
    this.position,
    this.promotedFromWaitlist = false,
  });

  bool get isWaitlist => kind == 'waitlist';

  factory MyReservationItem.fromJson(Map<String, dynamic> j) {
    final isWl = j['kind'] == 'waitlist';
    return MyReservationItem(
      kind: (j['kind'] ?? 'reservation').toString(),
      id: ((isWl ? j['waitlist_id'] : j['reservation_id']) as num).toInt(),
      classSessionId: (j['class_session_id'] as num).toInt(),
      startAt: DateTime.parse(j['start_at'] as String),
      durationMinutes: (j['duration_minutes'] as num?)?.toInt() ?? 60,
      title: (j['title'] ?? '수업').toString(),
      room: j['room']?.toString(),
      status: (j['status'] ?? '').toString(),
      position: (j['position'] as num?)?.toInt(),
      promotedFromWaitlist: j['promoted_from_waitlist'] == true,
    );
  }
}
