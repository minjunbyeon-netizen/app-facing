// v1.18 Sprint 19: Inbox 전역 상태 — unread count + items 캐시.

import 'package:flutter/foundation.dart';

import '../../core/exception.dart';
import '../../models/coach_note.dart';
import 'inbox_repository.dart';

class InboxState extends ChangeNotifier {
  final InboxRepository repo;
  InboxState(this.repo);

  InboxResult _inbox = InboxResult.empty;
  List<OutboxNote> _outbox = const [];
  bool _loading = false;
  String? _error;
  int? _gymId; // 현재 바인딩된 gym

  InboxResult get inbox => _inbox;
  List<OutboxNote> get outbox => _outbox;
  bool get isLoading => _loading;
  String? get error => _error;
  int get unreadCount => _inbox.unreadCount;

  /// 다른 영역(GymState load 직후)에서 호출.
  Future<void> bind(int? gymId) async {
    if (gymId == null) {
      _gymId = null;
      _inbox = InboxResult.empty;
      _outbox = const [];
      notifyListeners();
      return;
    }
    if (_gymId == gymId && _inbox.items.isNotEmpty) return;
    _gymId = gymId;
    await refresh();
  }

  Future<void> refresh() async {
    final gid = _gymId;
    if (gid == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _inbox = await repo.listInbox(gid);
    } on AppException catch (e) {
      _error = e.messageKo;
    } catch (e) {
      _error = '인박스 로딩 실패: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshOutbox() async {
    final gid = _gymId;
    if (gid == null) return;
    try {
      _outbox = await repo.listOutbox(gid);
      notifyListeners();
    } on AppException catch (e) {
      _error = e.messageKo;
      notifyListeners();
    }
  }

  Future<bool> markRead(int noteId) async {
    try {
      await repo.markRead(noteId);
      _localStatusUpdate(noteId, 'read');
      return true;
    } on AppException catch (e) {
      _error = e.messageKo;
      notifyListeners();
      return false;
    }
  }

  Future<bool> accept(int noteId) async {
    try {
      await repo.accept(noteId);
      _localStatusUpdate(noteId, 'accepted');
      return true;
    } on AppException catch (e) {
      _error = e.messageKo;
      notifyListeners();
      return false;
    }
  }

  Future<bool> complete(int noteId) async {
    try {
      await repo.complete(noteId);
      _localStatusUpdate(noteId, 'completed');
      return true;
    } on AppException catch (e) {
      _error = e.messageKo;
      notifyListeners();
      return false;
    }
  }

  Future<bool> decline(int noteId) async {
    try {
      await repo.decline(noteId);
      _localStatusUpdate(noteId, 'declined');
      return true;
    } on AppException catch (e) {
      _error = e.messageKo;
      notifyListeners();
      return false;
    }
  }

  /// 낙관적 갱신: 서버 200 후 _inbox 내 해당 note의 my.status 교체.
  void _localStatusUpdate(int noteId, String newStatus) {
    final updated = <CoachNote>[];
    var unread = 0;
    for (final n in _inbox.items) {
      if (n.id == noteId && n.my != null) {
        updated.add(CoachNote(
          id: n.id,
          gymId: n.gymId,
          senderHash: n.senderHash,
          senderShort: n.senderShort,
          targetType: n.targetType,
          targetId: n.targetId,
          kind: n.kind,
          title: n.title,
          body: n.body,
          structured: n.structured,
          dueDate: n.dueDate,
          createdAt: n.createdAt,
          my: RecipientStatus(
            status: newStatus,
            readAt: n.my!.readAt ?? DateTime.now(),
            acceptedAt: newStatus == 'accepted'
                ? DateTime.now()
                : n.my!.acceptedAt,
            completedAt: newStatus == 'completed'
                ? DateTime.now()
                : n.my!.completedAt,
          ),
          recipients: n.recipients,
        ));
      } else {
        updated.add(n);
      }
      if (updated.last.my?.status == 'sent') unread++;
    }
    _inbox = InboxResult(items: updated, unreadCount: unread);
    notifyListeners();
  }
}
