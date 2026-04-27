// v1.18 Sprint 19: Inbox + Coach Note + Group repository.

import '../../core/api_client.dart';
import '../../models/coach_group.dart';
import '../../models/coach_note.dart';

class InboxRepository {
  final ApiClient api;
  InboxRepository(this.api);

  // ---- Inbox / Outbox ----

  Future<InboxResult> listInbox(int gymId) async {
    final data = await api.get('/api/v1/gym/$gymId/inbox');
    // QA B-INB-4: items 가 List 가 아닌 응답이면 silent 무시 대신 빈 결과 (서버 형 변경 알림은 unread_count 0 으로).
    final itemsRaw = data['items'];
    final raw = (itemsRaw is List ? itemsRaw : const [])
        .whereType<Map<String, dynamic>>()
        .map(CoachNote.fromJson)
        .toList();
    final unread = ((data['unread_count'] ?? 0) as num).toInt();
    return InboxResult(items: raw, unreadCount: unread);
  }

  Future<List<OutboxNote>> listOutbox(int gymId) async {
    final data = await api.get('/api/v1/gym/$gymId/outbox');
    final itemsRaw = data['items'];
    final raw = (itemsRaw is List ? itemsRaw : const []);
    return raw
        .whereType<Map<String, dynamic>>()
        .map((j) => OutboxNote(
              note: CoachNote.fromJson(j),
              stats: j['stats'] is Map
                  ? NoteOutboxStats.fromJson(
                      Map<String, dynamic>.from(j['stats'] as Map))
                  : const NoteOutboxStats(total: 0, read: 0, completed: 0),
            ))
        .toList();
  }

  Future<CoachNote> getNote(int noteId) async {
    final data = await api.get('/api/v1/gym/notes/$noteId');
    return CoachNote.fromJson(data);
  }

  Future<int> postNote({
    required int gymId,
    required String targetType,
    String? targetId,
    required String kind,
    required String title,
    required String body,
    String? rationale,
    List<AssignmentItem> structured = const [],
    String? dueDate,
    String? dueStart,
    String? dueEnd,
  }) async {
    final payload = <String, dynamic>{
      'target_type': targetType,
      'kind': kind,
      'title': title,
      'body': body,
      if (targetId != null && targetId.isNotEmpty) 'target_id': targetId,
      if (rationale != null && rationale.isNotEmpty) 'rationale': rationale,
      if (structured.isNotEmpty)
        'structured': structured.map((s) => s.toJson()).toList(),
      if (dueDate != null && dueDate.isNotEmpty) 'due_date': dueDate,
      if (dueStart != null && dueStart.isNotEmpty) 'due_start': dueStart,
      if (dueEnd != null && dueEnd.isNotEmpty) 'due_end': dueEnd,
    };
    final data = await api.post('/api/v1/gym/$gymId/notes', payload);
    return ((data['note_id'] ?? 0) as num).toInt();
  }

  Future<void> markRead(int noteId) =>
      api.post('/api/v1/gym/notes/$noteId/read', const {});
  Future<void> accept(int noteId) =>
      api.post('/api/v1/gym/notes/$noteId/accept', const {});
  Future<void> complete(int noteId, {List<ActualSet> actual = const []}) =>
      api.post('/api/v1/gym/notes/$noteId/complete', {
        if (actual.isNotEmpty) 'actual': actual.map((a) => a.toJson()).toList(),
      });
  Future<void> decline(int noteId, {String? reason}) =>
      api.post('/api/v1/gym/notes/$noteId/decline', {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
  Future<void> askCoach(int noteId, String body) =>
      api.post('/api/v1/gym/notes/$noteId/ask', {'body': body});

  // ---- Profile info (display_name 등) ----
  Future<Map<String, dynamic>> getProfileInfo() =>
      api.get('/api/v1/profile/info');
  Future<void> updateProfileInfo({
    String? displayName,
    String? avatarColor,
    String? injuryNotes,
  }) =>
      api.post('/api/v1/profile/info', {
        'display_name': ?displayName,
        'avatar_color': ?avatarColor,
        'injury_notes': ?injuryNotes,
      });

  // ---- Gym invite code ----
  Future<String?> getInviteCode(int gymId) async {
    final data = await api.get('/api/v1/gym/$gymId/invite-code');
    return data['invite_code']?.toString();
  }

  Future<String?> regenerateInviteCode(int gymId) async {
    final data =
        await api.post('/api/v1/gym/$gymId/invite-code/regenerate', const {});
    return data['invite_code']?.toString();
  }

  Future<Map<String, dynamic>> joinByCode(String code) =>
      api.post('/api/v1/gym/join-by-code', {'code': code});

  // ---- Groups ----

  Future<List<CoachGroup>> listGroups(int gymId) async {
    final data = await api.get('/api/v1/gym/$gymId/groups');
    return (data['groups'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CoachGroup.fromJson)
        .toList();
  }

  Future<int> createGroup({
    required int gymId,
    required String name,
    String description = '',
    String? colorHex,
    int? capacity,
    List<int> weekdaySlot = const [],
    String? timeSlot,
    String? notes,
  }) async {
    final data = await api.post('/api/v1/gym/$gymId/groups', {
      'name': name,
      'description': description,
      if (colorHex != null && colorHex.isNotEmpty) 'color_hex': colorHex,
      'capacity': ?capacity,
      if (weekdaySlot.isNotEmpty) 'weekday_slot': weekdaySlot,
      if (timeSlot != null && timeSlot.isNotEmpty) 'time_slot': timeSlot,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return ((data['id'] ?? 0) as num).toInt();
  }

  Future<void> addGroupMember({
    required int gymId,
    required int groupId,
    required String memberHash,
  }) async {
    await api.post(
      '/api/v1/gym/$gymId/groups/$groupId/members',
      {'member_hash': memberHash},
    );
  }

  Future<void> removeGroupMember({
    required int gymId,
    required int groupId,
    required String memberHash,
  }) async {
    await api.delete('/api/v1/gym/$gymId/groups/$groupId/members/$memberHash');
  }
}

class InboxResult {
  final List<CoachNote> items;
  final int unreadCount;
  const InboxResult({required this.items, required this.unreadCount});

  static const empty = InboxResult(items: [], unreadCount: 0);
}

class OutboxNote {
  final CoachNote note;
  final NoteOutboxStats stats;
  const OutboxNote({required this.note, required this.stats});
}
