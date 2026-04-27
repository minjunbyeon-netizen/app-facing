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
    final raw = (data['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CoachNote.fromJson)
        .toList();
    final unread = ((data['unread_count'] ?? 0) as num).toInt();
    return InboxResult(items: raw, unreadCount: unread);
  }

  Future<List<OutboxNote>> listOutbox(int gymId) async {
    final data = await api.get('/api/v1/gym/$gymId/outbox');
    final raw = (data['items'] as List? ?? const []);
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
    List<AssignmentItem> structured = const [],
    String? dueDate,
  }) async {
    final payload = <String, dynamic>{
      'target_type': targetType,
      'kind': kind,
      'title': title,
      'body': body,
      if (targetId != null && targetId.isNotEmpty) 'target_id': targetId,
      if (structured.isNotEmpty)
        'structured': structured.map((s) => s.toJson()).toList(),
      if (dueDate != null && dueDate.isNotEmpty) 'due_date': dueDate,
    };
    final data = await api.post('/api/v1/gym/$gymId/notes', payload);
    return ((data['note_id'] ?? 0) as num).toInt();
  }

  Future<void> markRead(int noteId) =>
      api.post('/api/v1/gym/notes/$noteId/read', const {});
  Future<void> accept(int noteId) =>
      api.post('/api/v1/gym/notes/$noteId/accept', const {});
  Future<void> complete(int noteId) =>
      api.post('/api/v1/gym/notes/$noteId/complete', const {});
  Future<void> decline(int noteId) =>
      api.post('/api/v1/gym/notes/$noteId/decline', const {});

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
  }) async {
    final data = await api.post('/api/v1/gym/$gymId/groups', {
      'name': name,
      'description': description,
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
