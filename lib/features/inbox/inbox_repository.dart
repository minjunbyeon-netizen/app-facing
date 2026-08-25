// v1.18 Sprint 19: Inbox + Coach Note + Group repository.

import '../../core/api_client.dart';
import '../../models/chat_message.dart';
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
        .map(
          (j) => OutboxNote(
            note: CoachNote.fromJson(j),
            stats: j['stats'] is Map
                ? NoteOutboxStats.fromJson(
                    Map<String, dynamic>.from(j['stats'] as Map),
                  )
                : const NoteOutboxStats(total: 0, read: 0, completed: 0),
          ),
        )
        .toList();
  }

  Future<CoachNote> getNote(int noteId) async {
    final data = await api.get('/api/v1/gym/notes/$noteId');
    return CoachNote.fromJson(data);
  }

  /// v1.25: 회원↔코치 양방향 대화 — 보낸 것 + 받은 것 시간순(desc).
  /// [peer] 지정 시 그 상대와의 1:1 대화만 (코치 스레드용).
  Future<List<ChatMessage>> listMessages(int gymId, {String? peer}) async {
    final q = (peer != null && peer.isNotEmpty)
        ? '?peer=${Uri.encodeQueryComponent(peer)}'
        : '';
    final data = await api.get('/api/v1/gym/$gymId/messages$q');
    final raw = data['items'];
    return (raw is List ? raw : const [])
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
  }

  /// v1.25: 코치 대화 목록 — 회원별 1:1 스레드 요약 (최신순).
  Future<List<CoachThread>> listThreads(int gymId) async {
    final data = await api.get('/api/v1/gym/$gymId/threads');
    final raw = data['items'];
    return (raw is List ? raw : const [])
        .whereType<Map<String, dynamic>>()
        .map(CoachThread.fromJson)
        .toList();
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
  Future<void> decline(int noteId, {String? reason}) => api.post(
    '/api/v1/gym/notes/$noteId/decline',
    {if (reason != null && reason.isNotEmpty) 'reason': reason},
  );
  Future<void> askCoach(int noteId, String body) =>
      api.post('/api/v1/gym/notes/$noteId/ask', {'body': body});

  // ---- Profile info (display_name 등) ----
  Future<Map<String, dynamic>> getProfileInfo() =>
      api.get('/api/v1/profile/info');
  Future<void> updateProfileInfo({
    String? displayName,
    String? avatarColor,
    String? injuryNotes,
  }) => api.post('/api/v1/profile/info', {
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
    final data = await api.post(
      '/api/v1/gym/$gymId/invite-code/regenerate',
      const {},
    );
    return data['invite_code']?.toString();
  }

  Future<Map<String, dynamic>> joinByCode(String code) =>
      api.post('/api/v1/gym/join-by-code', {'code': code});

  // (v3.28: 그룹 메서드 4종 삭제 — 폰 쪽지에서 그룹 기능 폐지. 서버 API 는 PC 용으로 유지.)
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
