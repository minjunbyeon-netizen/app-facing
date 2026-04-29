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
  /// v1.21: GymState 변경 시 bind 재시도용 — 외부에서 현재 바인딩 ID 확인.
  int? get boundGymId => _gymId;

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
    } catch (e) {
      // QA B-EX-1: 일반 예외도 사용자 알림.
      _error = '아웃박스 로딩 실패';
      notifyListeners();
      debugPrint('[InboxState.refreshOutbox] $e');
    }
  }

  // QA B-EX-2: 5개 액션 메서드 일반 catch 추가.
  Future<bool> _runAction(
    String label,
    Future<void> Function() action,
    int noteId,
    String newStatus,
  ) async {
    try {
      await action();
      _localStatusUpdate(noteId, newStatus);
      return true;
    } on AppException catch (e) {
      _error = e.messageKo;
      notifyListeners();
      return false;
    } catch (e) {
      _error = '$label 실패. 다시 시도.';
      notifyListeners();
      debugPrint('[InboxState.$label] $e');
      return false;
    }
  }

  Future<bool> markRead(int noteId) =>
      _runAction('읽음 처리', () => repo.markRead(noteId), noteId, 'read');

  Future<bool> accept(int noteId) =>
      _runAction('수락', () => repo.accept(noteId), noteId, 'accepted');

  Future<bool> complete(int noteId, {List<ActualSet> actual = const []}) =>
      _runAction('완료 기록',
          () => repo.complete(noteId, actual: actual), noteId, 'completed');

  Future<bool> decline(int noteId, {String? reason}) =>
      _runAction('거절',
          () => repo.decline(noteId, reason: reason), noteId, 'declined');

  /// v1.19 페르소나 P1-15 (M2 신입 정): Ask Coach.
  Future<bool> askCoach(int noteId, String body) =>
      _runAction('질문 전송',
          () => repo.askCoach(noteId, body), noteId, 'asked');

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
          senderName: n.senderName,
          senderColor: n.senderColor,
          targetType: n.targetType,
          targetId: n.targetId,
          kind: n.kind,
          title: n.title,
          body: n.body,
          rationale: n.rationale,
          structured: n.structured,
          dueDate: n.dueDate,
          dueStart: n.dueStart,
          dueEnd: n.dueEnd,
          voiceMemoPath: n.voiceMemoPath,
          autoKind: n.autoKind,
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
            declineReason: n.my!.declineReason,
            actual: n.my!.actual,
          ),
          recipients: n.recipients,
        ));
      } else {
        updated.add(n);
      }
    }
    // QA B-LG-1 / B-ST-2: 매 루프 마지막만 검사 → 전체 스캔으로 교정.
    for (final n in updated) {
      if (n.my != null && n.my!.status == 'sent') unread++;
    }
    _inbox = InboxResult(items: updated, unreadCount: unread);
    notifyListeners();
  }
}
