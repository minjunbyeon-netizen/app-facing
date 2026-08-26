// v1.16 Sprint 17: CoachFeedback + MemberRequest DTO.
import '../core/time_format.dart';

class CoachFeedback {
  final int id;
  final String memberHashPrefix;
  final bool isMine; // 멤버 조회 시 본인 피드백 여부.
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CoachFeedback({
    required this.id,
    required this.memberHashPrefix,
    required this.isMine,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CoachFeedback.fromJson(Map<String, dynamic> j) => CoachFeedback(
        id: (j['id'] as num).toInt(),
        memberHashPrefix: (j['member_hash_prefix'] ?? '').toString(),
        isMine: j['is_mine'] == true,
        body: (j['body'] ?? '').toString(),
        createdAt: parseServerTime(j['created_at'] as String).toLocal(),
        updatedAt: parseServerTime(j['updated_at'] as String).toLocal(),
      );
}

class MemberRequest {
  final int id;
  final String fromHashPrefix;
  final bool isMine;
  final int? wodPostId;
  final String subject;
  final String body;
  final String status; // open · resolved · dismissed
  final String? coachResponse;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const MemberRequest({
    required this.id,
    required this.fromHashPrefix,
    required this.isMine,
    this.wodPostId,
    required this.subject,
    required this.body,
    required this.status,
    this.coachResponse,
    required this.createdAt,
    this.respondedAt,
  });

  bool get isOpen => status == 'open';
  bool get isResolved => status == 'resolved';

  factory MemberRequest.fromJson(Map<String, dynamic> j) => MemberRequest(
        id: (j['id'] as num).toInt(),
        fromHashPrefix: (j['from_hash_prefix'] ?? '').toString(),
        isMine: j['is_mine'] == true,
        wodPostId: (j['wod_post_id'] as num?)?.toInt(),
        subject: (j['subject'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        status: (j['status'] ?? 'open').toString(),
        coachResponse: j['coach_response']?.toString(),
        createdAt: parseServerTime(j['created_at'] as String).toLocal(),
        respondedAt: j['responded_at'] == null
            ? null
            : parseServerTime(j['responded_at'] as String).toLocal(),
      );
}
