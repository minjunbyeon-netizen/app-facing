/// D29 (2026-08-12) — 수업별 예약자 명단.
/// GET /api/v1/admin/classes/{class_id}/reservations
///
/// PII 는 이름·전화 **전부 평문**으로 온다 (D32, 2026-08-12 마스킹 폐기).
/// 스태프는 역할과 무관하게 같은 값을 본다 — 앱에서 가리는 가공 금지.
library;

class RosterEntry {
  /// 'reservation' | 'waitlist'
  final String kind;
  final int memberId;
  final String name;
  final String? phone;

  /// 예약 행 id — 출석 체크(PATCH)의 대상. kind='waitlist' 면 null.
  final int? reservationId;

  /// confirmed | attended | no_show | waitlisted
  final String status;

  /// 회원 행이 지워졌는데 예약만 남은 고아 (name='탈퇴 회원').
  final bool orphan;

  /// 대기 **현재** 순번 (kind='waitlist' 일 때만).
  /// 백엔드가 매 조회마다 다시 센 값 — 앞사람이 빠지면 줄어든다 (D31).
  final int? position;

  /// 대기열에서 승격된 예약인지.
  final bool promotedFromWaitlist;

  const RosterEntry({
    required this.kind,
    required this.memberId,
    required this.name,
    required this.status,
    required this.orphan,
    this.phone,
    this.reservationId,
    this.position,
    this.promotedFromWaitlist = false,
  });

  bool get isWaitlist => kind == 'waitlist';

  /// 출석 체크 가능 여부 — 대기자·고아(회원 행 없음)는 찍을 대상이 아니다.
  bool get markable => !isWaitlist && !orphan && reservationId != null;

  RosterEntry withStatus(String next) => RosterEntry(
    kind: kind,
    memberId: memberId,
    name: name,
    status: next,
    orphan: orphan,
    phone: phone,
    reservationId: reservationId,
    position: position,
    promotedFromWaitlist: promotedFromWaitlist,
  );

  factory RosterEntry.fromJson(Map<String, dynamic> j) => RosterEntry(
    kind: j['kind']?.toString() ?? 'reservation',
    memberId: (j['member_id'] as num?)?.toInt() ?? 0,
    name: j['name']?.toString() ?? '이름 미등록',
    phone: j['phone']?.toString(),
    reservationId: (j['reservation_id'] as num?)?.toInt(),
    status: j['status']?.toString() ?? 'confirmed',
    orphan: j['orphan'] == true,
    position: (j['position'] as num?)?.toInt(),
    promotedFromWaitlist: j['promoted_from_waitlist'] == true,
  );
}

class ClassRoster {
  final int classSessionId;
  final String title;
  final String startAt;
  final String? room;
  final String? coachUserId;
  final int? capacity;

  /// G24 2차 (2026-08-19) — 수정 시트 프리필용. 명단 응답에 백엔드가 같이 준다.
  final int? durationMinutes;
  final String? track;

  final int confirmedCount;
  final int waitlistCount;
  final List<RosterEntry> items;

  const ClassRoster({
    required this.classSessionId,
    required this.title,
    required this.startAt,
    required this.confirmedCount,
    required this.waitlistCount,
    required this.items,
    this.room,
    this.coachUserId,
    this.capacity,
    this.durationMinutes,
    this.track,
  });

  List<RosterEntry> get reservations =>
      items.where((e) => !e.isWaitlist).toList();
  List<RosterEntry> get waitlist => items.where((e) => e.isWaitlist).toList();

  factory ClassRoster.fromJson(Map<String, dynamic> j) => ClassRoster(
    classSessionId: (j['class_session_id'] as num?)?.toInt() ?? 0,
    title: j['title']?.toString() ?? '수업',
    startAt: j['start_at']?.toString() ?? '',
    room: j['room']?.toString(),
    coachUserId: j['coach_user_id']?.toString(),
    capacity: (j['capacity'] as num?)?.toInt(),
    durationMinutes: (j['duration_minutes'] as num?)?.toInt(),
    track: j['track']?.toString(),
    confirmedCount: (j['confirmed_count'] as num?)?.toInt() ?? 0,
    waitlistCount: (j['waitlist_count'] as num?)?.toInt() ?? 0,
    items: (j['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => RosterEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}
