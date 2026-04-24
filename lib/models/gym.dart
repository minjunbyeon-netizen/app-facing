// v1.15.3: 박스/코치 WOD 피드 DTO.

class GymSummary {
  final int id;
  final String name;
  final String location;
  final int memberCount;

  const GymSummary({
    required this.id,
    required this.name,
    required this.location,
    required this.memberCount,
  });

  factory GymSummary.fromJson(Map<String, dynamic> j) => GymSummary(
        id: (j['id'] as num).toInt(),
        name: (j['name'] ?? '').toString(),
        location: (j['location'] ?? '').toString(),
        memberCount: ((j['member_count'] ?? 0) as num).toInt(),
      );
}

/// 내 박스 소속 스냅샷. role ∈ {owner, member, null}. status ∈ {pending, approved, rejected, null}.
class GymMembership {
  final GymSummary? gym;
  final String? role;
  final String? status;

  const GymMembership({this.gym, this.role, this.status});

  bool get hasGym => gym != null;
  bool get isOwner => role == 'owner';
  bool get isApprovedMember => role == 'member' && status == 'approved';
  bool get isPending => role == 'member' && status == 'pending';
  bool get isRejected => role == 'member' && status == 'rejected';

  factory GymMembership.fromJson(Map<String, dynamic> j) {
    final gymRaw = j['gym'];
    return GymMembership(
      gym: gymRaw is Map<String, dynamic>
          ? GymSummary.fromJson(gymRaw)
          : null,
      role: j['role']?.toString(),
      status: j['status']?.toString(),
    );
  }

  static const GymMembership empty =
      GymMembership(gym: null, role: null, status: null);
}

class GymMember {
  final int id;
  final String deviceHashPrefix;
  final String status;
  final DateTime requestedAt;
  final DateTime? decidedAt;

  const GymMember({
    required this.id,
    required this.deviceHashPrefix,
    required this.status,
    required this.requestedAt,
    this.decidedAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory GymMember.fromJson(Map<String, dynamic> j) => GymMember(
        id: (j['id'] as num).toInt(),
        deviceHashPrefix: (j['device_hash_prefix'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        requestedAt: DateTime.parse(j['requested_at'] as String),
        decidedAt: j['decided_at'] == null
            ? null
            : DateTime.parse(j['decided_at'] as String),
      );
}

class GymWodPost {
  final int id;
  final String postDate; // YYYY-MM-DD
  final String wodType;
  final String content;
  final int? rounds;
  final int? timeCapSec;
  final DateTime createdAt;

  const GymWodPost({
    required this.id,
    required this.postDate,
    required this.wodType,
    required this.content,
    this.rounds,
    this.timeCapSec,
    required this.createdAt,
  });

  String get timeCapDisplay {
    if (timeCapSec == null) return '';
    final m = timeCapSec! ~/ 60;
    final s = timeCapSec! % 60;
    if (s == 0) return '${m}min cap';
    return '$m:${s.toString().padLeft(2, '0')} cap';
  }

  factory GymWodPost.fromJson(Map<String, dynamic> j) => GymWodPost(
        id: (j['id'] as num).toInt(),
        postDate: (j['post_date'] ?? '').toString(),
        wodType: (j['wod_type'] ?? '').toString(),
        content: (j['content'] ?? '').toString(),
        rounds: (j['rounds'] as num?)?.toInt(),
        timeCapSec: (j['time_cap_sec'] as num?)?.toInt(),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
