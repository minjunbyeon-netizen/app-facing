// v1.15.3: 박스/코치 WOD 피드 DTO.

class GymSummary {
  final int id;
  final String name;
  final String location;
  final int memberCount;
  final bool isOfficial;

  const GymSummary({
    required this.id,
    required this.name,
    required this.location,
    required this.memberCount,
    this.isOfficial = false,
  });

  factory GymSummary.fromJson(Map<String, dynamic> j) => GymSummary(
        id: (j['id'] as num).toInt(),
        name: (j['name'] ?? '').toString(),
        location: (j['location'] ?? '').toString(),
        memberCount: ((j['member_count'] ?? 0) as num).toInt(),
        isOfficial: (j['is_official'] == true) ||
            ((j['name'] ?? '').toString() == 'FACING'),
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
  final String? deviceHashFull; // v1.16 Sprint 15: 코치 조회 시만 전체 노출 (DM 송신용).
  final String status;
  final DateTime requestedAt;
  final DateTime? decidedAt;
  // v1.16 Sprint 12: 코치 대시보드 활동 통계.
  final DateTime? lastWodAt;
  final int totalSessions;
  final int streakDays;

  const GymMember({
    required this.id,
    required this.deviceHashPrefix,
    this.deviceHashFull,
    required this.status,
    required this.requestedAt,
    this.decidedAt,
    this.lastWodAt,
    this.totalSessions = 0,
    this.streakDays = 0,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  /// 오늘·어제 활동 여부. streak 끊김 경고용.
  int get daysSinceLastWod {
    if (lastWodAt == null) return 999;
    return DateTime.now().difference(lastWodAt!).inDays;
  }

  bool get isDormant => isApproved && daysSinceLastWod >= 14;

  factory GymMember.fromJson(Map<String, dynamic> j) => GymMember(
        id: (j['id'] as num).toInt(),
        deviceHashPrefix: (j['device_hash_prefix'] ?? '').toString(),
        deviceHashFull: j['device_hash']?.toString(),
        status: (j['status'] ?? '').toString(),
        requestedAt: DateTime.parse(j['requested_at'] as String),
        decidedAt: j['decided_at'] == null
            ? null
            : DateTime.parse(j['decided_at'] as String),
        lastWodAt: j['last_wod_at'] == null
            ? null
            : DateTime.parse(j['last_wod_at'] as String),
        totalSessions: ((j['total_sessions'] ?? 0) as num).toInt(),
        streakDays: ((j['streak_days'] ?? 0) as num).toInt(),
      );
}

class WodRoundItem {
  final String label;
  final String content;
  final int? timeCapSec;

  const WodRoundItem({
    required this.label,
    required this.content,
    this.timeCapSec,
  });

  factory WodRoundItem.fromJson(Map<String, dynamic> j) => WodRoundItem(
        label: (j['label'] ?? '').toString(),
        content: (j['content'] ?? '').toString(),
        timeCapSec: (j['time_cap_sec'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'content': content,
        if (timeCapSec != null) 'time_cap_sec': timeCapSec,
      };
}

class GymWodPost {
  final int id;
  final String postDate; // YYYY-MM-DD
  final String wodType;
  final String content; // RX 버전
  final String? scaledVersion;
  final String? beginnerVersion;
  final String? scaleGuide;
  final List<WodRoundItem> roundsData;
  final int? rounds;
  final int? timeCapSec;
  final DateTime createdAt;

  const GymWodPost({
    required this.id,
    required this.postDate,
    required this.wodType,
    required this.content,
    this.scaledVersion,
    this.beginnerVersion,
    this.scaleGuide,
    this.roundsData = const [],
    this.rounds,
    this.timeCapSec,
    required this.createdAt,
  });

  bool get hasVersions =>
      (scaledVersion != null && scaledVersion!.isNotEmpty) ||
      (beginnerVersion != null && beginnerVersion!.isNotEmpty);

  String get timeCapDisplay {
    if (timeCapSec == null) return '';
    final m = timeCapSec! ~/ 60;
    final s = timeCapSec! % 60;
    if (s == 0) return '${m}min cap';
    return '$m:${s.toString().padLeft(2, '0')} cap';
  }

  factory GymWodPost.fromJson(Map<String, dynamic> j) {
    final roundsRaw = j['rounds_data'];
    final rounds = (roundsRaw is List)
        ? roundsRaw
            .whereType<Map<String, dynamic>>()
            .map(WodRoundItem.fromJson)
            .toList()
        : <WodRoundItem>[];
    return GymWodPost(
      id: (j['id'] as num).toInt(),
      postDate: (j['post_date'] ?? '').toString(),
      wodType: (j['wod_type'] ?? '').toString(),
      content: (j['content'] ?? '').toString(),
      scaledVersion: j['scaled_version']?.toString(),
      beginnerVersion: j['beginner_version']?.toString(),
      scaleGuide: j['scale_guide']?.toString(),
      roundsData: rounds,
      rounds: (j['rounds'] as num?)?.toInt(),
      timeCapSec: (j['time_cap_sec'] as num?)?.toInt(),
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}

/// v1.16 Sprint 16: WOD 리더보드 항목.
class GymWodResult {
  final int id;
  final int rank;
  final String deviceHashPrefix;
  final bool isMine;
  final int? timeSec;
  final int? rounds;
  final int? extraReps;
  final String scaleLevel; // rx · scaled · beginner
  final String notes;
  final DateTime createdAt;

  const GymWodResult({
    required this.id,
    required this.rank,
    required this.deviceHashPrefix,
    required this.isMine,
    this.timeSec,
    this.rounds,
    this.extraReps,
    required this.scaleLevel,
    required this.notes,
    required this.createdAt,
  });

  String get display {
    if (timeSec != null) {
      final m = timeSec! ~/ 60;
      final s = timeSec! % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    if (rounds != null) {
      final r = rounds!;
      final reps = extraReps ?? 0;
      if (reps > 0) return '$r+$reps';
      return '$r rounds';
    }
    return '-';
  }

  factory GymWodResult.fromJson(Map<String, dynamic> j) => GymWodResult(
        id: (j['id'] as num).toInt(),
        rank: ((j['rank'] ?? 0) as num).toInt(),
        deviceHashPrefix: (j['device_hash_prefix'] ?? '').toString(),
        isMine: j['is_mine'] == true,
        timeSec: (j['time_sec'] as num?)?.toInt(),
        rounds: (j['rounds'] as num?)?.toInt(),
        extraReps: (j['extra_reps'] as num?)?.toInt(),
        scaleLevel: (j['scale_level'] ?? 'rx').toString(),
        notes: (j['notes'] ?? '').toString(),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

/// v1.16 Sprint 16: WOD 댓글.
class GymWodComment {
  final int id;
  final String authorPrefix;
  final bool isMine;
  final String body;
  final DateTime createdAt;

  const GymWodComment({
    required this.id,
    required this.authorPrefix,
    required this.isMine,
    required this.body,
    required this.createdAt,
  });

  factory GymWodComment.fromJson(Map<String, dynamic> j) => GymWodComment(
        id: (j['id'] as num).toInt(),
        authorPrefix: (j['author_prefix'] ?? '').toString(),
        isMine: j['is_mine'] == true,
        body: (j['body'] ?? '').toString(),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
