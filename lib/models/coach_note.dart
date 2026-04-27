// v1.18 Sprint 19: Coach Note + Recipient + structured Assignment items.

class CoachNote {
  final int id;
  final int gymId;
  final String senderHash;
  final String senderShort; // hash 앞 8자 (이름 폴백)
  final String? senderName; // v1.19 페르소나 P0-2
  final String? senderColor; // v1.19 페르소나 P0-2
  final String targetType; // individual | group | all
  final String? targetId;
  final String kind; // note | assignment
  final String title;
  final String body;
  final String? rationale; // v1.19 페르소나 P0-4
  final List<AssignmentItem> structured;
  final String? dueDate; // YYYY-MM-DD
  final String? dueStart; // v1.19 페르소나 P2-26
  final String? dueEnd;
  final String? voiceMemoPath; // v1.19 페르소나 P2-25 (재생 UI는 Phase 2)
  final String? autoKind; // v1.19 페르소나 P0-7 ('achievement:STREAK_30' 등)
  final DateTime createdAt;
  final RecipientStatus? my;
  final List<RecipientSummary> recipients; // outbox 상세용

  const CoachNote({
    required this.id,
    required this.gymId,
    required this.senderHash,
    required this.senderShort,
    this.senderName,
    this.senderColor,
    required this.targetType,
    required this.targetId,
    required this.kind,
    required this.title,
    required this.body,
    this.rationale,
    required this.structured,
    required this.dueDate,
    this.dueStart,
    this.dueEnd,
    this.voiceMemoPath,
    this.autoKind,
    required this.createdAt,
    this.my,
    this.recipients = const [],
  });

  /// 화면에 노출할 발신자 라벨. displayName 우선, fallback hash 8자.
  String displayLabel() {
    if (senderName != null && senderName!.isNotEmpty) return senderName!;
    return senderShort.toUpperCase();
  }

  bool get isAuto => autoKind != null && autoKind!.isNotEmpty;

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
      senderName: j['sender_name']?.toString(),
      senderColor: j['sender_color']?.toString(),
      targetType: (j['target_type'] ?? 'individual').toString(),
      targetId: j['target_id']?.toString(),
      kind: (j['kind'] ?? 'note').toString(),
      title: (j['title'] ?? '').toString(),
      body: (j['body'] ?? '').toString(),
      rationale: j['rationale']?.toString(),
      structured: items,
      dueDate: j['due_date']?.toString(),
      dueStart: j['due_start']?.toString(),
      dueEnd: j['due_end']?.toString(),
      voiceMemoPath: j['voice_memo_path']?.toString(),
      autoKind: j['auto_kind']?.toString(),
      createdAt: DateTime.parse(j['created_at'] as String),
      my: j['my'] is Map
          ? RecipientStatus.fromJson(Map<String, dynamic>.from(j['my'] as Map))
          : null,
      recipients: recips,
    );
  }
}

/// v1.19 페르소나 P0-3 (C3 코치 리 / M4 게임스 지망): structured items 단위 다양화.
///
/// unit 값:
///  - 'pct_1rm' : load_value 가 0~1.5 비율 (75% = 0.75)
///  - 'rpe'     : load_value 가 1~10 RPE
///  - 'kg' / 'lb' : 절대 무게
///  - 'sec_per_500m' : pace
///  - 'time_cap_sec' : 단일 라운드 캡
///  - 'tempo' : tempo_pattern 문자열 ('3-1-1-0')
///  - 'feel' : load_value 0/1/2 → lighter/same/heavier (페르소나 P2-21 신입 친화)
class AssignmentItem {
  final String movementSlug;
  final String? alternateMovement; // v1.19 페르소나 P1-17
  final int? sets;
  final int? reps;
  final num? loadValue; // unit 따라 의미 변동
  final String? unit; // pct_1rm | rpe | kg | lb | sec_per_500m | time_cap_sec | tempo | feel
  final int? restSec; // v1.19 페르소나 P0-3 (C3)
  final String? tempoPattern; // '3-1-1-0'
  final int? timeCapSec; // 라운드 타임캡
  final int? rounds;
  final String? note;

  const AssignmentItem({
    required this.movementSlug,
    this.alternateMovement,
    this.sets,
    this.reps,
    this.loadValue,
    this.unit,
    this.restSec,
    this.tempoPattern,
    this.timeCapSec,
    this.rounds,
    this.note,
  });

  // 기존 호환 — load_pct 직접 입력.
  num? get loadPct {
    if (unit == 'pct_1rm' && loadValue != null) return loadValue;
    return null;
  }

  factory AssignmentItem.fromJson(Map<String, dynamic> j) => AssignmentItem(
        movementSlug: (j['movement_slug'] ?? '').toString(),
        alternateMovement: j['alternate_movement']?.toString(),
        sets: j['sets'] is num ? (j['sets'] as num).toInt() : null,
        reps: j['reps'] is num ? (j['reps'] as num).toInt() : null,
        loadValue: () {
          if (j['load_value'] is num) return j['load_value'] as num;
          // 기존 load_pct 폴백.
          if (j['load_pct'] is num) return j['load_pct'] as num;
          return null;
        }(),
        unit: () {
          if (j['unit'] is String) return j['unit'] as String;
          if (j['load_pct'] is num) return 'pct_1rm';
          return null;
        }(),
        restSec: j['rest_sec'] is num ? (j['rest_sec'] as num).toInt() : null,
        tempoPattern: j['tempo_pattern']?.toString(),
        timeCapSec:
            j['time_cap_sec'] is num ? (j['time_cap_sec'] as num).toInt() : null,
        rounds: j['rounds'] is num ? (j['rounds'] as num).toInt() : null,
        note: j['note']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'movement_slug': movementSlug,
        if (alternateMovement != null && alternateMovement!.isNotEmpty)
          'alternate_movement': alternateMovement,
        if (sets != null) 'sets': sets,
        if (reps != null) 'reps': reps,
        if (loadValue != null) 'load_value': loadValue,
        if (unit != null) 'unit': unit,
        if (restSec != null) 'rest_sec': restSec,
        if (tempoPattern != null && tempoPattern!.isNotEmpty)
          'tempo_pattern': tempoPattern,
        if (timeCapSec != null) 'time_cap_sec': timeCapSec,
        if (rounds != null) 'rounds': rounds,
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  String displayLine() {
    final parts = <String>[movementSlug];
    if (sets != null && reps != null) parts.add('$sets×$reps');
    final loadStr = _formatLoad();
    if (loadStr != null) parts.add(loadStr);
    if (rounds != null) parts.add('${rounds}R');
    if (timeCapSec != null) parts.add('cap ${timeCapSec}s');
    if (tempoPattern != null && tempoPattern!.isNotEmpty) {
      parts.add('tempo $tempoPattern');
    }
    if (restSec != null) parts.add('rest ${restSec}s');
    return parts.join(' · ');
  }

  String? _formatLoad() {
    if (loadValue == null) return null;
    switch (unit) {
      case 'pct_1rm':
        return '${(loadValue! * 100).round()}%';
      case 'rpe':
        return 'RPE ${loadValue!.toStringAsFixed(loadValue! % 1 == 0 ? 0 : 1)}';
      case 'kg':
        return '${loadValue!.toStringAsFixed(loadValue! % 1 == 0 ? 0 : 1)}kg';
      case 'lb':
        return '${loadValue!.toStringAsFixed(loadValue! % 1 == 0 ? 0 : 1)}lb';
      case 'sec_per_500m':
        return '${loadValue!.toInt()}s/500m';
      case 'feel':
        switch (loadValue!.toInt()) {
          case 0:
            return 'lighter';
          case 1:
            return 'same';
          case 2:
            return 'heavier';
          default:
            return 'feel';
        }
      default:
        return null;
    }
  }
}

class RecipientStatus {
  final String status; // sent | read | accepted | completed | declined | asked
  final DateTime? readAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String? declineReason; // v1.19 페르소나 P0-6
  final List<ActualSet> actual; // v1.19 페르소나 P0-5

  const RecipientStatus({
    required this.status,
    this.readAt,
    this.acceptedAt,
    this.completedAt,
    this.declineReason,
    this.actual = const [],
  });

  bool get isUnread => status == 'sent';

  factory RecipientStatus.fromJson(Map<String, dynamic> j) {
    final rawActual = j['actual'];
    final actuals = <ActualSet>[];
    if (rawActual is List) {
      for (final a in rawActual) {
        if (a is Map) {
          actuals.add(ActualSet.fromJson(Map<String, dynamic>.from(a)));
        }
      }
    }
    return RecipientStatus(
      status: (j['status'] ?? 'sent').toString(),
      readAt: j['read_at'] is String ? DateTime.parse(j['read_at']) : null,
      acceptedAt:
          j['accepted_at'] is String ? DateTime.parse(j['accepted_at']) : null,
      completedAt:
          j['completed_at'] is String ? DateTime.parse(j['completed_at']) : null,
      declineReason: j['decline_reason']?.toString(),
      actual: actuals,
    );
  }
}

/// v1.19 페르소나 P0-5: 세트별 실제 수행 결과.
class ActualSet {
  final int setIndex;
  final num? actualLoad;
  final int? actualReps;
  final num? rpe;
  final String? note;

  const ActualSet({
    required this.setIndex,
    this.actualLoad,
    this.actualReps,
    this.rpe,
    this.note,
  });

  factory ActualSet.fromJson(Map<String, dynamic> j) => ActualSet(
        setIndex: ((j['set_index'] ?? 0) as num).toInt(),
        actualLoad: j['actual_load'] is num ? j['actual_load'] as num : null,
        actualReps:
            j['actual_reps'] is num ? (j['actual_reps'] as num).toInt() : null,
        rpe: j['rpe'] is num ? j['rpe'] as num : null,
        note: j['note']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'set_index': setIndex,
        if (actualLoad != null) 'actual_load': actualLoad,
        if (actualReps != null) 'actual_reps': actualReps,
        if (rpe != null) 'rpe': rpe,
        if (note != null && note!.isNotEmpty) 'note': note,
      };
}

class RecipientSummary {
  final String hash;
  final String? name;
  final String? color;
  final String status;
  final DateTime? readAt;
  final DateTime? completedAt;
  final String? declineReason;

  const RecipientSummary({
    required this.hash,
    this.name,
    this.color,
    required this.status,
    this.readAt,
    this.completedAt,
    this.declineReason,
  });

  String displayLabel() {
    if (name != null && name!.isNotEmpty) return name!;
    return hash.toUpperCase();
  }

  factory RecipientSummary.fromJson(Map<String, dynamic> j) => RecipientSummary(
        hash: (j['hash'] ?? '').toString(),
        name: j['name']?.toString(),
        color: j['color']?.toString(),
        status: (j['status'] ?? 'sent').toString(),
        readAt: j['read_at'] is String ? DateTime.parse(j['read_at']) : null,
        completedAt:
            j['completed_at'] is String ? DateTime.parse(j['completed_at']) : null,
        declineReason: j['decline_reason']?.toString(),
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
