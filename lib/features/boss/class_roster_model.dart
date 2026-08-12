/// D29 (2026-08-12) — 수업별 예약자 명단.
/// GET /api/v1/admin/classes/{class_id}/reservations
///
/// PII 는 백엔드 `_viewer_scope()` + `_mask_pii()` 가 role 별로 처리해서 내려준다.
/// 코치 세션이면 name='윤**', phone='010-****-6612' 형태로 이미 마스킹된 값이 온다 —
/// 앱에서 추가 가공하지 않는다 (마스킹 정책 SSOT = 백엔드).
library;

class RosterEntry {
  /// 'reservation' | 'waitlist'
  final String kind;
  final int memberId;
  final String name;
  final String? phone;

  /// confirmed | attended | no_show | waitlisted
  final String status;

  /// 회원 행이 지워졌는데 예약만 남은 고아 (name='탈퇴 회원').
  final bool orphan;

  /// 대기 순번 (kind='waitlist' 일 때만).
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
    this.position,
    this.promotedFromWaitlist = false,
  });

  bool get isWaitlist => kind == 'waitlist';

  factory RosterEntry.fromJson(Map<String, dynamic> j) => RosterEntry(
        kind: j['kind']?.toString() ?? 'reservation',
        memberId: (j['member_id'] as num?)?.toInt() ?? 0,
        name: j['name']?.toString() ?? '이름 미등록',
        phone: j['phone']?.toString(),
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
  });

  List<RosterEntry> get reservations =>
      items.where((e) => !e.isWaitlist).toList();
  List<RosterEntry> get waitlist => items.where((e) => e.isWaitlist).toList();

  factory ClassRoster.fromJson(Map<String, dynamic> j) => ClassRoster(
        classSessionId: (j['class_session_id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? 'WOD',
        startAt: j['start_at']?.toString() ?? '',
        room: j['room']?.toString(),
        coachUserId: j['coach_user_id']?.toString(),
        capacity: (j['capacity'] as num?)?.toInt(),
        confirmedCount: (j['confirmed_count'] as num?)?.toInt() ?? 0,
        waitlistCount: (j['waitlist_count'] as num?)?.toInt() ?? 0,
        items: (j['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => RosterEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
