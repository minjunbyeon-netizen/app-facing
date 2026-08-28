// v1.18 Sprint 19: Inbox 전역 상태 — unread count + items 캐시.
//
// 2026-08-28 테스터 지시 — "쪽지가 왔을 때 직접적인 알람이 떠야 하는데 오지 않음".
// 종전엔 note.new SSE 를 **쪽지함 화면이 열려 있을 때만** 들었다. 화면을 닫아 두면
// 아무 일도 안 일어나고, 벨을 직접 눌러야 알 수 있었다. 이제 전역에서 듣는다.
//
// 남의 쪽지에 진동하지 않게 하는 법: note.new 는 체육관 전체에 뿌려지므로 이벤트만
// 보고 띄우면 다른 회원에게 간 쪽지에도 알림이 뜬다. **내 미읽음 수가 실제로 늘었을
// 때만** 띄운다 — 서버가 수신자를 흘리지 않아도 되고, 내 것만 정확히 걸린다.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/exception.dart';
import '../../core/notification_service.dart';
import '../../core/sse_client.dart';
import '../../models/coach_note.dart';
import 'inbox_repository.dart';

import '../../core/app_clock.dart';

class InboxState extends ChangeNotifier {
  final InboxRepository repo;
  final SseClient? sse;
  StreamSubscription<SseEvent>? _sseSub;
  Timer? _noteDebounce;

  InboxState(this.repo, {this.sse}) {
    _bindSse();
  }

  void _bindSse() {
    if (sse == null) return;
    _sseSub = sse!.events.listen((ev) {
      if (ev.type != 'note.new') return;
      // 여러 건이 몰아쳐도 한 번만 받아 온다 (알림은 늘어난 만큼 한 줄로).
      _noteDebounce?.cancel();
      _noteDebounce = Timer(const Duration(milliseconds: 700), _onNoteNew);
    }, onError: (e) => debugPrint('[InboxState] sse error: $e'));
  }

  Future<void> _onNoteNew() async {
    if (_gymId == null) return;
    final before = _inbox.unreadCount;
    await refresh();
    final gained = _inbox.unreadCount - before;
    if (gained <= 0) return;   // 내게 온 게 아니거나 이미 읽은 것 — 조용히.
    final newest = _inbox.items
        .where((n) => n.my != null && n.my!.isUnread)
        .fold<CoachNote?>(null, (best, n) =>
            best == null || n.createdAt.isAfter(best.createdAt) ? n : best);
    final preview = newest == null
        ? ''
        : (newest.title.trim().isNotEmpty ? newest.title.trim()
                                          : newest.body.trim());
    await NotificationService.instance.showFromSseEvent(
      eventType: 'note.new',
      payload: {
        'note_id': newest?.id,
        'sender_name': newest?.senderName,
        'preview': gained > 1 ? '읽지 않은 쪽지 $gained건' : preview,
      },
    );
  }

  @override
  void dispose() {
    _noteDebounce?.cancel();
    _sseSub?.cancel();
    super.dispose();
  }

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
      _error = '쪽지를 불러오지 못했습니다.';
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
      _error = '보낸 쪽지를 불러오지 못했습니다.';
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

  /// 대화 화면에서 받은 쪽지를 한꺼번에 읽음 처리 (2026-08-28 테스터 지시).
  ///
  /// 종전엔 쪽지 **상세**(NoteDetailScreen)를 열어야만 읽음이 찍혔다. 회원이 실제로
  /// 쓰는 길인 대화(ChatThreadScreen)에는 그 호출이 없어서, 다 읽고 나와도 벨의
  /// 빨간 등이 그대로 남았다 — "확인을 해도 표시가 사라지지 않음".
  ///
  /// 실패한 건은 조용히 넘긴다 (하나 실패했다고 나머지를 막지 않는다). 끝나고
  /// 목록을 다시 받아 미읽음 수를 서버 기준으로 맞춘다.
  Future<void> markThreadRead(Iterable<int> noteIds) async {
    final ids = noteIds.toSet();
    if (ids.isEmpty) return;
    for (final id in ids) {
      try {
        await repo.markRead(id);
        _localStatusUpdate(id, 'read');
      } catch (e) {
        debugPrint('[InboxState.markThreadRead] $id: $e');
      }
    }
    await refresh();
  }

  Future<bool> accept(int noteId) =>
      _runAction('수락', () => repo.accept(noteId), noteId, 'accepted');

  Future<bool> complete(int noteId, {List<ActualSet> actual = const []}) =>
      _runAction(
        '완료 기록',
        () => repo.complete(noteId, actual: actual),
        noteId,
        'completed',
      );

  Future<bool> decline(int noteId, {String? reason}) => _runAction(
    '거절',
    () => repo.decline(noteId, reason: reason),
    noteId,
    'declined',
  );

  /// v1.19 페르소나 P1-15 (M2 신입 정): Ask Coach.
  Future<bool> askCoach(int noteId, String body) =>
      _runAction('질문 전송', () => repo.askCoach(noteId, body), noteId, 'asked');

  /// 낙관적 갱신: 서버 200 후 _inbox 내 해당 note의 my.status 교체.
  void _localStatusUpdate(int noteId, String newStatus) {
    final updated = <CoachNote>[];
    var unread = 0;
    for (final n in _inbox.items) {
      if (n.id == noteId && n.my != null) {
        updated.add(
          CoachNote(
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
              readAt: n.my!.readAt ?? appClock.now(),
              acceptedAt: newStatus == 'accepted'
                  ? appClock.now()
                  : n.my!.acceptedAt,
              completedAt: newStatus == 'completed'
                  ? appClock.now()
                  : n.my!.completedAt,
              declineReason: n.my!.declineReason,
              actual: n.my!.actual,
            ),
            recipients: n.recipients,
          ),
        );
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
