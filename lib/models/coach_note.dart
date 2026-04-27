// v1.18 Sprint 19: Coach Note + Recipient + structured Assignment items.

class CoachNote {
  final int id;
  final int gymId;
  final String senderHash;
  final String senderShort; // hash 앞 8자 (이름 폴백)
  final String targetType; // individual | group | all
  final String? targetId;
  final String kind; // note | assignment
  final String title;
  final String body;
  final List<AssignmentItem> structured;
  final String? dueDate; // YYYY-MM-DD
  final DateTime createdAt;
  final RecipientStatus? my;
  final List<RecipientSummary> recipients; // outbox 상세용

  const CoachNote({
    required this.id,
    required this.gymId,
    required this.senderHash,
    required this.senderShort,
    required this.targetType,
    required this.targetId,
    required this.kind,
    required this.title,
    required this.body,
    required this.structured,
    required this.dueDate,
    required this.createdAt,
    this.my,
    this.recipients = const [],
  });

  bool get isAssignment => kind == 'assignment';

  factory CoachNote.fromJson(Map<String, dynamic> j) {
    final rawStructured = j['structured'];
    final items = <AssignmentItem>[];
    if (rawStructured is List) {
      for (final it in rawStructured) {
        if (it is Map<String, dynamic>) {
          items.add(AssignmentItem.fromJson(it));
        } else if (it is Map) {
          items.add(AssignmentItem.fromJson(Map<String, dynamic>.from(it)));
        }
      }
    }
    final rawRecips = j['recipients'];
    final recips = <RecipientSummary>[];
    if (rawRecips is List) {
      for (final r in rawRecips) {
        if (r is Map) {
          recips.add(RecipientSummary.fromJson(Map<String, dynamic>.from(r)));
        }
      }
    }
    return CoachNote(
      id: ((j['id'] ?? 0) as num).toInt(),
      gymId: ((j['gym_id'] ?? 0) as num).toInt(),
      senderHash: (j['sender_hash'] ?? '').toString(),
      senderShort: (j['sender_short'] ?? '').toString(),
      targetType: (j['target_type'] ?? 'individual').toString(),
      targetId: j['target_id']?.toString(),
      kind: (j['kind'] ?? 'note').toString(),
      title: (j['title'] ?? '').toString(),
      body: (j['body'] ?? '').toString(),
      structured: items,
      dueDate: j['due_date']?.toString(),
      createdAt: DateTime.parse(j['created_at'] as String),
      my: j['my'] is Map
          ? RecipientStatus.fromJson(Map<String, dynamic>.from(j['my'] as Map))
          : null,
      recipients: recips,
    );
  }
}

class AssignmentItem {
  final String movementSlug;
  final int? sets;
  final int? reps;
  final num? loadPct; // 1RM 비율 0~1.5 가능
  final int? rounds;
  final String? note;

  const AssignmentItem({
    required this.movementSlug,
    this.sets,
    this.reps,
    this.loadPct,
    this.rounds,
    this.note,
  });

  factory AssignmentItem.fromJson(Map<String, dynamic> j) => AssignmentItem(
        movementSlug: (j['movement_slug'] ?? '').toString(),
        sets: j['sets'] is num ? (j['sets'] as num).toInt() : null,
        reps: j['reps'] is num ? (j['reps'] as num).toInt() : null,
        loadPct: j['load_pct'] is num ? j['load_pct'] as num : null,
        rounds: j['rounds'] is num ? (j['rounds'] as num).toInt() : null,
        note: j['note']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'movement_slug': movementSlug,
        if (sets != null) 'sets': sets,
        if (reps != null) 'reps': reps,
        if (loadPct != null) 'load_pct': loadPct,
        if (rounds != null) 'rounds': rounds,
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  String displayLine() {
    final parts = <String>[movementSlug];
    if (sets != null && reps != null) parts.add('$sets×$reps');
    if (loadPct != null) parts.add('${(loadPct! * 100).round()}%');
    if (rounds != null) parts.add('${rounds}R');
    return parts.join(' · ');
  }
}

class RecipientStatus {
  final String status; // sent | read | accepted | completed | declined
  final DateTime? readAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  const RecipientStatus({
    required this.status,
    this.readAt,
    this.acceptedAt,
    this.completedAt,
  });

  bool get isUnread => status == 'sent';

  factory RecipientStatus.fromJson(Map<String, dynamic> j) => RecipientStatus(
        status: (j['status'] ?? 'sent').toString(),
        readAt: j['read_at'] is String ? DateTime.parse(j['read_at']) : null,
        acceptedAt:
            j['accepted_at'] is String ? DateTime.parse(j['accepted_at']) : null,
        completedAt:
            j['completed_at'] is String ? DateTime.parse(j['completed_at']) : null,
      );
}

class RecipientSummary {
  final String hash;
  final String status;
  final DateTime? readAt;
  final DateTime? completedAt;

  const RecipientSummary({
    required this.hash,
    required this.status,
    this.readAt,
    this.completedAt,
  });

  factory RecipientSummary.fromJson(Map<String, dynamic> j) => RecipientSummary(
        hash: (j['hash'] ?? '').toString(),
        status: (j['status'] ?? 'sent').toString(),
        readAt: j['read_at'] is String ? DateTime.parse(j['read_at']) : null,
        completedAt:
            j['completed_at'] is String ? DateTime.parse(j['completed_at']) : null,
      );
}

/// outbox 응답에 포함된 발송 통계.
class NoteOutboxStats {
  final int total;
  final int read;
  final int completed;

  const NoteOutboxStats({
    required this.total,
    required this.read,
    required this.completed,
  });

  factory NoteOutboxStats.fromJson(Map<String, dynamic> j) => NoteOutboxStats(
        total: ((j['total'] ?? 0) as num).toInt(),
        read: ((j['read'] ?? 0) as num).toInt(),
        completed: ((j['completed'] ?? 0) as num).toInt(),
      );
}
