// PHASE5 §1.2 — 사장 dashboard 데이터 모델.
// GET /api/v1/admin/gyms/{gym_id}/dashboard 응답 매핑.

class DashboardData {
  final String today;
  final DashboardCount todayReservations;
  final DashboardCount todayAttendances;
  final DashboardCount newMembersThisWeek;
  final List<TodayClass> todayClasses;
  final List<ExpiringMember> expiringSoon;

  const DashboardData({
    required this.today,
    required this.todayReservations,
    required this.todayAttendances,
    required this.newMembersThisWeek,
    required this.todayClasses,
    required this.expiringSoon,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
        today: j['today']?.toString() ?? '',
        todayReservations: DashboardCount.fromJson(
            j['today_reservations'] as Map<String, dynamic>? ?? {}),
        todayAttendances: DashboardCount.fromJson(
            j['today_attendances'] as Map<String, dynamic>? ?? {}),
        newMembersThisWeek: DashboardCount.fromJson(
            j['new_members_this_week'] as Map<String, dynamic>? ?? {}),
        todayClasses: (j['today_classes'] as List? ?? [])
            .map((e) => TodayClass.fromJson(e as Map<String, dynamic>))
            .toList(),
        expiringSoon: (j['expiring_soon'] as List? ?? [])
            .map((e) => ExpiringMember.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DashboardCount {
  final int count;
  final List<MemberSnippet> members;

  const DashboardCount({required this.count, required this.members});

  factory DashboardCount.fromJson(Map<String, dynamic> j) => DashboardCount(
        count: (j['count'] as num?)?.toInt() ?? 0,
        members: (j['members'] as List? ?? [])
            .map((e) => MemberSnippet.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MemberSnippet {
  final int id;
  final String name;
  final String? profilePhotoUrl;

  const MemberSnippet(
      {required this.id, required this.name, this.profilePhotoUrl});

  factory MemberSnippet.fromJson(Map<String, dynamic> j) => MemberSnippet(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name']?.toString() ?? '',
        profilePhotoUrl: j['profile_photo_url']?.toString(),
      );
}

class TodayClass {
  final int id;
  final String title;
  final String startAt;
  final String endAt;
  final int reserved;
  final int? capacity;
  final List<String> coaches;
  final String? room;
  final String status;

  const TodayClass({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.reserved,
    this.capacity,
    required this.coaches,
    this.room,
    required this.status,
  });

  factory TodayClass.fromJson(Map<String, dynamic> j) => TodayClass(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? 'WOD',
        startAt: j['start_at']?.toString() ?? '',
        endAt: j['end_at']?.toString() ?? '',
        reserved: (j['reserved'] as num?)?.toInt() ?? 0,
        capacity: (j['capacity'] as num?)?.toInt(),
        coaches: (j['coaches'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        room: j['room']?.toString(),
        status: j['status']?.toString() ?? 'scheduled',
      );
}

class ExpiringMember {
  final int memberId;
  final String name;
  final int dDay;
  final String endDate;

  const ExpiringMember({
    required this.memberId,
    required this.name,
    required this.dDay,
    required this.endDate,
  });

  factory ExpiringMember.fromJson(Map<String, dynamic> j) => ExpiringMember(
        memberId: (j['member_id'] as num?)?.toInt() ?? 0,
        name: j['name']?.toString() ?? '',
        dDay: (j['d_day'] as num?)?.toInt() ?? 0,
        endDate: j['end_date']?.toString() ?? '',
      );
}
