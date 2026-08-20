// v1.22: Inbox → NOTICE 단일 피드 (날짜순). ALL/NOTES/ASSIGNMENTS/OUTBOX 4탭 폐지.
//
// 톤: 흑백·전사·Obsession.
// Coach Dossier 카드: 좌 4px accent stripe + 이니셜 모노그램.
// 미읽음: stripe accent + 굵은 폰트.
// 읽음: stripe muted + 보통 폰트.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/sse_client.dart';
import '../../core/theme.dart';
import '../../models/announcement.dart';
import '../../models/chat_message.dart';
import '../../models/coach_note.dart';
import '../../widgets/avatar.dart';
import '../announcements/announcements_state.dart';
import '../gym/gym_repository.dart';
import '../gym/gym_state.dart';
import 'compose_note_screen.dart';
import 'group_management_screen.dart';
import 'inbox_repository.dart';
import 'inbox_state.dart';
import 'note_detail_screen.dart';
import '../../core/app_clock.dart';

// v3.2 (2026-08-20 사용자 지시 "깨끗하게 다 지워"): 구 Notice 탭의 InboxScreen
// (재활 가이드 전담)은 셸에서 빠진 뒤 도달 불가 — rehab 일체와 함께 삭제.
// 대장 = README.md §제거된 기능 대장.

/// 외부에서도 재사용 (홈 화면 미읽음 카드 노출 등).
class CoachDossierTile extends StatelessWidget {
  final CoachNote note;
  const CoachDossierTile({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final isUnread = note.my?.isUnread ?? false;
    final stripeColor = isUnread ? HyphenTokens.accent : HyphenTokens.muted;
    final dueLabel = _dueLabel(note.dueDate);
    final senderLabel = note.displayLabel();

    return InkWell(
      onTap: () async {
        Haptic.light();
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => NoteDetailScreen(noteId: note.id),
        ));
        if (context.mounted) {
          await context.read<InboxState>().refresh();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: HyphenTokens.surface,
          border: Border.all(color: HyphenTokens.border, width: 1),
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
        ),
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: stripeColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(HyphenTokens.sp3),
                  child: _buildBody(
                      stripeColor, dueLabel, senderLabel, isUnread),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    Color stripeColor,
    _DueBadge? dueLabel,
    String senderLabel,
    bool isUnread,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Avatar(
          hash: note.senderShort,
          displayName: note.senderName,
          colorHex: note.senderColor,
        ),
        const SizedBox(width: HyphenTokens.sp3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    note.isAuto
                        ? 'AUTO'
                        : (note.kind == 'assignment'
                            ? 'ASSIGNMENT'
                            : 'NOTE'),
                    style: HyphenTokens.microLabel.copyWith(
                      color: note.isAuto
                          ? HyphenTokens.success
                          : stripeColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: HyphenTokens.sp2),
                  Flexible(
                    child: Text(
                      'COACH · ${senderLabel.toUpperCase()}',
                      style: HyphenTokens.microLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _agoLabel(note.createdAt),
                    style: HyphenTokens.micro,
                  ),
                ],
              ),
              if (note.title.isNotEmpty) ...[
                const SizedBox(height: HyphenTokens.sp1),
                Text(
                  note.title,
                  style: HyphenTokens.body.copyWith(
                    fontWeight:
                        isUnread ? FontWeight.w800 : FontWeight.w700,
                    color: HyphenTokens.fg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (note.body.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  note.body,
                  style: HyphenTokens.caption.copyWith(
                    color: isUnread
                        ? HyphenTokens.fg
                        : HyphenTokens.muted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (note.kind == 'assignment') ...[
                const SizedBox(height: HyphenTokens.sp2),
                Row(
                  children: [
                    if (dueLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: HyphenTokens.sp2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: dueLabel.color,
                          ),
                          borderRadius:
                              BorderRadius.circular(HyphenTokens.r1),
                        ),
                        child: Text(
                          dueLabel.text,
                          style: HyphenTokens.micro.copyWith(
                            color: dueLabel.color,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    const SizedBox(width: HyphenTokens.sp2),
                    if (note.my != null)
                      Text(
                        note.my!.status.toUpperCase(),
                        style: HyphenTokens.micro.copyWith(
                          color: _statusColor(note.my!.status),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'completed':
        return HyphenTokens.success;
      case 'accepted':
        return HyphenTokens.fg;
      case 'declined':
        return HyphenTokens.muted;
      case 'read':
        return HyphenTokens.muted;
      case 'sent':
      default:
        return HyphenTokens.accent;
    }
  }

  static _DueBadge? _dueLabel(String? dueDate) {
    if (dueDate == null || dueDate.isEmpty) return null;
    final due = DateTime.tryParse('${dueDate}T00:00:00');
    if (due == null) return null;
    final now = appClock.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final diff = due.difference(today).inDays;
    if (diff < 0) return _DueBadge('OVERDUE', color: HyphenTokens.overdue);
    if (diff == 0) return _DueBadge('TODAY', color: HyphenTokens.accent);
    if (diff <= 3) return _DueBadge('D-$diff', color: HyphenTokens.accent);
    return _DueBadge('D-$diff', color: HyphenTokens.muted);
  }

  static String _agoLabel(DateTime created) {
    final now = appClock.now().toUtc();
    final d = now.difference(created.isUtc ? created : created.toUtc());
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    final l = created.toLocal();
    final mm = l.month.toString().padLeft(2, '0');
    final dd = l.day.toString().padLeft(2, '0');
    if (l.year != appClock.now().year) {
      return '${l.year}-$mm-$dd';
    }
    return '$mm/$dd';
  }
}

class _DueBadge {
  final String text;
  final Color color;
  const _DueBadge(this.text, {required this.color});
}

// ─── 회원 ↔ 코치 양방향 대화 (v1.25) ──────────────────────────────────────────

/// 말풍선 — mine(보낸 것)=우측 accent, 받은 것=좌측 surface.
class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final mine = msg.mine;
    return Padding(
      padding: const EdgeInsets.only(bottom: HyphenTokens.sp3),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!mine)
            Padding(
              padding: const EdgeInsets.only(bottom: 3, left: 4),
              child: Text(
                msg.isAuto
                    ? 'AUTO'
                    : (msg.senderName ?? 'COACH').toUpperCase(),
                style: HyphenTokens.microLabel.copyWith(
                  color:
                      msg.isAuto ? HyphenTokens.success : HyphenTokens.muted,
                ),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: HyphenTokens.sp3,
                vertical: HyphenTokens.sp2 + 2,
              ),
              decoration: BoxDecoration(
                color: mine ? HyphenTokens.accent : HyphenTokens.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(HyphenTokens.r3),
                  topRight: const Radius.circular(HyphenTokens.r3),
                  bottomLeft: Radius.circular(
                      mine ? HyphenTokens.r3 : HyphenTokens.r1),
                  bottomRight: Radius.circular(
                      mine ? HyphenTokens.r1 : HyphenTokens.r3),
                ),
                border:
                    mine ? null : Border.all(color: HyphenTokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.title.isNotEmpty) ...[
                    Text(
                      msg.title,
                      style: HyphenTokens.body.copyWith(
                        fontWeight: FontWeight.w800,
                        color: HyphenTokens.fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    msg.body,
                    style: HyphenTokens.body.copyWith(color: HyphenTokens.fg),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
            child: Text(_timeLabel(msg.createdAt), style: HyphenTokens.micro),
          ),
        ],
      ),
    );
  }

  static String _timeLabel(DateTime t) {
    final now = appClock.now();
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    final mo = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '$mo/$d';
  }
}

/// 상단 핀 공지 — 최신 1건 요약. 새 소식 제일 위 노출.
class _PinnedAnnouncement extends StatelessWidget {
  final List<GymAnnouncement> announcements;
  const _PinnedAnnouncement({required this.announcements});

  @override
  Widget build(BuildContext context) {
    final latest = announcements.first;
    final more = announcements.length - 1;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
          HyphenTokens.sp4, HyphenTokens.sp3, HyphenTokens.sp4, 0),
      padding: const EdgeInsets.all(HyphenTokens.sp3),
      decoration: BoxDecoration(
        color: HyphenTokens.surface,
        borderRadius: BorderRadius.circular(HyphenTokens.r2),
        border: Border.all(
          color:
              latest.isUrgent ? HyphenTokens.accent : HyphenTokens.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'NOTICE',
                style: HyphenTokens.microLabel.copyWith(
                  color: latest.isUrgent
                      ? HyphenTokens.accent
                      : HyphenTokens.muted,
                ),
              ),
              if (more > 0) ...[
                const Spacer(),
                Text('+$more', style: HyphenTokens.micro),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (latest.title.isNotEmpty)
            Text(
              latest.title,
              style: HyphenTokens.body.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (latest.body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                latest.body,
                style: HyphenTokens.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

/// 하단 입력바 — 쪽지 발신. 전송 버튼은 입력창 suffixIcon 으로.
class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final String hint;
  const _ChatInputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
    this.hint = '메시지…',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        HyphenTokens.sp3,
        HyphenTokens.sp2,
        HyphenTokens.sp3,
        HyphenTokens.sp2,
      ),
      decoration: const BoxDecoration(
        color: HyphenTokens.bg,
        border: Border(top: BorderSide(color: HyphenTokens.border, width: 1)),
      ),
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: 4,
        maxLength: 500,
        style: HyphenTokens.body,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => onSend(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: HyphenTokens.caption,
          counterText: '',
          isDense: true,
          filled: true,
          fillColor: HyphenTokens.surface,
          contentPadding: const EdgeInsets.fromLTRB(
            HyphenTokens.sp3,
            HyphenTokens.sp2 + 2,
            HyphenTokens.sp1,
            HyphenTokens.sp2 + 2,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(HyphenTokens.r3),
            borderSide: const BorderSide(color: HyphenTokens.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(HyphenTokens.r3),
            borderSide: const BorderSide(color: HyphenTokens.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(HyphenTokens.r3),
            borderSide:
                const BorderSide(color: HyphenTokens.accent, width: 1.5),
          ),
          suffixIcon: sending
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: HyphenTokens.accent, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_upward,
                      color: HyphenTokens.accent),
                  onPressed: onSend,
                ),
        ),
      ),
    );
  }
}

String _shortTime(DateTime t) {
  final now = appClock.now();
  if (t.year == now.year && t.month == now.month && t.day == now.day) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
  final mo = t.month.toString().padLeft(2, '0');
  final d = t.day.toString().padLeft(2, '0');
  return '$mo/$d';
}

/// v1.25: 새 쪽지 SSE(note.new) 구독 → 디바운스 후 onReload. 대화 자동 갱신.
StreamSubscription<SseEvent> _listenNoteNew(
  BuildContext context,
  void Function() onReload,
) {
  Timer? debounce;
  return context.read<SseClient>().events.listen((ev) {
    if (ev.type != 'note.new') return;
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), onReload);
  });
}

// ─── 메시징 피드 ─────────────────────────────────────────────────────────

/// v1.26 (2026-06-11): 쪽지·공지 진입을 종(벨)으로 일원화 — 벨 탭 시 이 화면.
/// (구 v1.24 Attend 캘린더 밑 임베드는 ClassesSection 으로 대체됨.)
class MessagingScreen extends StatelessWidget {
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 쪽지·숙제·공지가 함께 쌓이는 화면이라 '공지' 는 내용과 불일치 (2026-08-06).
      appBar: AppBar(title: const Text('알림함')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: HyphenTokens.sp4),
          children: const [MessagingFeed()],
        ),
      ),
    );
  }
}

/// 공지 + 코치/회원 대화목록 + 작성 진입을 한 덩어리로 묶은 임베드 위젯.
/// Scaffold 없이 스크롤 부모(ListView) 안에 들어가도록 자체 스크롤을 쓰지 않는다.
class MessagingFeed extends StatelessWidget {
  const MessagingFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final isCoach = gs.isOwner;
    final gymId = gs.membership.gym?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              HyphenTokens.sp4, 0, HyphenTokens.sp4, HyphenTokens.sp2),
          child: Row(
            children: [
              const Text('메시지', style: HyphenTokens.sectionLabel),
              const Spacer(),
              if (gymId != null) ..._actions(context, gs, isCoach, gymId),
            ],
          ),
        ),
        if (gymId == null)
          const Padding(
            padding: EdgeInsets.fromLTRB(HyphenTokens.sp4, HyphenTokens.sp2,
                HyphenTokens.sp4, HyphenTokens.sp4),
            child: Text('가입 승인 후 코치 쪽지·공지 사용 가능.',
                style: HyphenTokens.caption),
          )
        else ...[
          Consumer<AnnouncementsState>(
            builder: (ctx, ann, _) => ann.items.isEmpty
                ? const SizedBox.shrink()
                : _PinnedAnnouncement(announcements: ann.items),
          ),
          _EmbeddedThreadList(
            gymId: gymId,
            emptyHint:
                isCoach ? '회원 쪽지 도착 시 표시.' : '코치 쪽지 도착 시 표시.',
          ),
        ],
      ],
    );
  }

  List<Widget> _actions(
      BuildContext context, GymState gs, bool isCoach, int gymId) {
    if (isCoach) {
      return [
        _FeedAction(
          icon: Icons.group_outlined,
          label: '그룹',
          onTap: () {
            Haptic.light();
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const GroupManagementScreen(),
            ));
          },
        ),
        const SizedBox(width: HyphenTokens.sp2),
        _FeedAction(
          icon: Icons.edit_outlined,
          label: '새 쪽지',
          onTap: () async {
            Haptic.light();
            final ok = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const ComposeNoteScreen()),
            );
            if (ok == true && context.mounted) {
              await context.read<InboxState>().refresh();
            }
          },
        ),
      ];
    }
    // 회원 — 코치에게 먼저 쪽지 시작.
    if (gs.membership.gym?.ownerHash == null) return const [];
    return [
      _FeedAction(
        icon: Icons.edit_outlined,
        label: '코치에게 쪽지',
        onTap: () {
          Haptic.light();
          final gymv = gs.membership.gym!;
          final coachName = gs.coaches.isNotEmpty
              ? gs.coaches.first.name
              : ((gymv.profile?.coachName ?? '').trim().isNotEmpty
                  ? gymv.profile!.coachName!.trim()
                  : '코치');
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChatThreadScreen(
              gymId: gymv.id,
              peerHash: gymv.ownerHash!,
              peerName: coachName,
            ),
          ));
        },
      ),
    ];
  }
}

class _FeedAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FeedAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(HyphenTokens.r1),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: HyphenTokens.sp2, vertical: HyphenTokens.sp1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: HyphenTokens.accent),
            const SizedBox(width: 4),
            Text(label,
                style:
                    HyphenTokens.micro.copyWith(color: HyphenTokens.accent)),
          ],
        ),
      ),
    );
  }
}

/// 스크롤 부모(ListView) 안에 들어가는 대화 목록 — 자체 스크롤 X, Column 으로 렌더.
class _EmbeddedThreadList extends StatefulWidget {
  final int gymId;
  final String emptyHint;
  const _EmbeddedThreadList({required this.gymId, required this.emptyHint});

  @override
  State<_EmbeddedThreadList> createState() => _EmbeddedThreadListState();
}

class _EmbeddedThreadListState extends State<_EmbeddedThreadList> {
  late final InboxRepository _repo;
  Future<List<CoachThread>>? _future;
  StreamSubscription<SseEvent>? _sseSub;

  @override
  void initState() {
    super.initState();
    _repo = InboxRepository(context.read<ApiClient>());
    _future = _repo.listThreads(widget.gymId);
    _sseSub = _listenNoteNew(context, () {
      if (mounted) _reload();
    });
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _repo.listThreads(widget.gymId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CoachThread>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(HyphenTokens.sp5),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: HyphenTokens.muted, strokeWidth: 2),
              ),
            ),
          );
        }
        final threads = snap.data ?? const <CoachThread>[];
        if (threads.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(HyphenTokens.sp4,
                HyphenTokens.sp2, HyphenTokens.sp4, HyphenTokens.sp4),
            child: Text(widget.emptyHint, style: HyphenTokens.caption),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < threads.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  color: HyphenTokens.border,
                  indent: HyphenTokens.sp4,
                  endIndent: HyphenTokens.sp4,
                ),
              _ThreadRow(
                thread: threads[i],
                gymId: widget.gymId,
                onReturn: _reload,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// 대화 목록 1줄 — 회원 이름 · 마지막 메시지 · 시각 · 안읽음.
class _ThreadRow extends StatelessWidget {
  final CoachThread thread;
  final int gymId;
  final VoidCallback onReturn;
  const _ThreadRow({
    required this.thread,
    required this.gymId,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final raw = (thread.peerName ?? '').trim();
    final name = raw.isNotEmpty
        ? raw
        : (thread.peerHash.isNotEmpty
            ? thread.peerHash.substring(
                0, thread.peerHash.length < 6 ? thread.peerHash.length : 6)
            : 'MEMBER');
    final unread = thread.unread > 0;
    return InkWell(
      onTap: () async {
        Haptic.light();
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatThreadScreen(
            gymId: gymId,
            peerHash: thread.peerHash,
            peerName: name,
          ),
        ));
        onReturn();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HyphenTokens.sp4,
          vertical: HyphenTokens.sp3,
        ),
        child: Row(
          children: [
            Avatar(
              hash: thread.peerHash,
              displayName: name,
              colorHex: thread.peerColor,
            ),
            const SizedBox(width: HyphenTokens.sp3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: HyphenTokens.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: HyphenTokens.fg,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(_shortTime(thread.lastAt),
                          style: HyphenTokens.micro),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    thread.lastBody,
                    style: HyphenTokens.caption.copyWith(
                      color: unread ? HyphenTokens.fg : HyphenTokens.muted,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: HyphenTokens.sp2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: HyphenTokens.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${thread.unread}',
                  style: HyphenTokens.micro.copyWith(
                    color: HyphenTokens.fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 코치 ↔ 특정 회원 1:1 채팅 화면. 말풍선 + 입력바(개별 발신).
class ChatThreadScreen extends StatefulWidget {
  final int gymId;
  final String peerHash;
  final String peerName;
  const ChatThreadScreen({
    super.key,
    required this.gymId,
    required this.peerHash,
    required this.peerName,
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  late final InboxRepository _repo;
  late final GymRepository _gymRepo;
  final _ctrl = TextEditingController();
  Future<List<ChatMessage>>? _future;
  bool _sending = false;
  StreamSubscription<SseEvent>? _sseSub;

  @override
  void initState() {
    super.initState();
    final api = context.read<ApiClient>();
    _repo = InboxRepository(api);
    _gymRepo = GymRepository(api);
    _future = _repo.listMessages(widget.gymId, peer: widget.peerHash);
    _sseSub = _listenNoteNew(context, () {
      if (mounted) _reload();
    });
  }

  void _reload() {
    setState(() {
      _future = _repo.listMessages(widget.gymId, peer: widget.peerHash);
    });
  }

  Future<void> _send() async {
    final msg = _ctrl.text.trim();
    if (msg.isEmpty || _sending) return;
    Haptic.light();
    final isOwner = context.read<GymState>().isOwner;
    setState(() => _sending = true);
    try {
      if (isOwner) {
        // 코치 → 회원: 개별 note.
        await _repo.postNote(
          gymId: widget.gymId,
          targetType: 'individual',
          targetId: widget.peerHash,
          kind: 'note',
          title: '',
          body: msg,
        );
      } else {
        // 회원 → 코치: member-report 로 그 코치에게.
        await _gymRepo.memberReport(
          gymId: widget.gymId,
          message: msg,
          to: widget.peerHash,
        );
      }
      _ctrl.clear();
      _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전송 실패. 다시 시도.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = context.watch<GymState>().isOwner;
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: FutureBuilder<List<ChatMessage>>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: HyphenTokens.muted, strokeWidth: 2),
                    );
                  }
                  final msgs = snap.data ?? const <ChatMessage>[];
                  if (msgs.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text('첫 쪽지 작성.',
                              style: HyphenTokens.caption),
                        ),
                      ],
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: HyphenTokens.sp4,
                        vertical: HyphenTokens.sp3,
                      ),
                      itemCount: msgs.length,
                      itemBuilder: (_, i) => _ChatBubble(msg: msgs[i]),
                    ),
                  );
                },
              ),
            ),
            _ChatInputBar(
              controller: _ctrl,
              sending: _sending,
              onSend: _send,
              hint: isOwner ? '회원에게 쪽지…' : '코치에게 쪽지…',
            ),
          ],
        ),
      ),
    );
  }
}
