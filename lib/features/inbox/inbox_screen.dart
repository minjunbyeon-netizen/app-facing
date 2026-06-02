// v1.22: Inbox → NOTICE 단일 피드 (날짜순). ALL/NOTES/ASSIGNMENTS/OUTBOX 4탭 폐지.
//
// 톤: 흑백·전사·Obsession.
// Coach Dossier 카드: 좌 4px accent stripe + 이니셜 모노그램.
// 미읽음: stripe accent + 굵은 폰트.
// 읽음: stripe muted + 보통 폰트.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/announcement.dart';
import '../../models/chat_message.dart';
import '../../models/coach_note.dart';
import '../../widgets/avatar.dart';
import '../../widgets/coach_badge.dart';
import '../announcements/announcements_state.dart';
import '../gym/gym_repository.dart';
import '../gym/gym_state.dart';
import 'compose_note_screen.dart';
import 'group_management_screen.dart';
import 'inbox_repository.dart';
import 'inbox_state.dart';
import 'note_detail_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gym = context.read<GymState>().membership.gym;
      if (gym != null) {
        context.read<InboxState>().bind(gym.id);
        // 공지 bind만 — markSeen은 사용자가 실제 탭했을 때만 (main_shell _onTap)
        final annState = context.read<AnnouncementsState>();
        final repo = context.read<GymRepository>();
        if (annState.boundGymId != gym.id) {
          annState.bind(repo, gym.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InboxState>();
    final gs = context.watch<GymState>();
    final isCoach = gs.isOwner;
    final gymId = gs.membership.gym?.id;

    // v1.22: 모든 항목(notes/assignments/announcements) 날짜순 단일 피드.
    final items = [...state.inbox.items];
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTICE'),
        actions: [
          if (isCoach) const CoachBadgeAction(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => state.refresh(),
          ),
          if (isCoach)
            IconButton(
              icon: const Icon(Icons.group_outlined),
              tooltip: 'Groups',
              onPressed: () {
                Haptic.light();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const GroupManagementScreen(),
                ));
              },
            ),
          if (isCoach)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'New Note',
              onPressed: () async {
                Haptic.light();
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const ComposeNoteScreen(),
                  ),
                );
                if (ok == true && context.mounted) {
                  await context.read<InboxState>().refresh();
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        // v1.25: 회원 = 코치와의 1:1 대화뷰(말풍선+입력바). 코치 = 기존 단일 피드.
        //   박스 기본정보(GymInfoCard)는 WOD 탭 BOX INFO 아코디언으로 이관됨.
        child: !isCoach
            ? (gymId == null
                ? const Center(
                    child: Text('박스 가입 후 이용 가능.',
                        style: FacingTokens.caption))
                : _MemberConversation(gymId: gymId))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: state.isLoading && items.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: FacingTokens.muted,
                        strokeWidth: 2,
                      ),
                    )
                  : (state.error != null && items.isEmpty)
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(FacingTokens.sp5),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('LOAD FAILED',
                                    style: FacingTokens.sectionLabel),
                                const SizedBox(height: FacingTokens.sp2),
                                Text(state.error!, style: FacingTokens.caption),
                                const SizedBox(height: FacingTokens.sp3),
                                OutlinedButton(
                                  onPressed: () => state.refresh(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('No notices.',
                                      style: FacingTokens.caption),
                                  if (isCoach) ...[
                                    const SizedBox(height: FacingTokens.sp2),
                                    Text(
                                      '오른쪽 상단 ✏ 또는 + New 버튼으로 쪽지·숙제 발송.',
                                      style: FacingTokens.micro,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => state.refresh(),
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  vertical: FacingTokens.sp3,
                                  horizontal: FacingTokens.sp4,
                                ),
                                itemCount: items.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: FacingTokens.sp3),
                                itemBuilder: (ctx, i) =>
                                    CoachDossierTile(note: items[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: isCoach
          ? FloatingActionButton.extended(
              backgroundColor: FacingTokens.accent,
              foregroundColor: FacingTokens.fg,
              onPressed: () async {
                Haptic.light();
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const ComposeNoteScreen(),
                  ),
                );
                if (ok == true && mounted) {
                  await state.refresh();
                }
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('New'),
            )
          : null,
    );
  }
}

/// 외부에서도 재사용 (홈 화면 미읽음 카드 노출 등).
class CoachDossierTile extends StatelessWidget {
  final CoachNote note;
  const CoachDossierTile({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final isUnread = note.my?.isUnread ?? false;
    final stripeColor = isUnread ? FacingTokens.accent : FacingTokens.muted;
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
          color: FacingTokens.surface,
          border: Border.all(color: FacingTokens.border, width: 1),
          borderRadius: BorderRadius.circular(FacingTokens.r2),
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
                  padding: const EdgeInsets.all(FacingTokens.sp3),
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
        const SizedBox(width: FacingTokens.sp3),
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
                    style: FacingTokens.microLabel.copyWith(
                      color: note.isAuto
                          ? FacingTokens.success
                          : stripeColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: FacingTokens.sp2),
                  Flexible(
                    child: Text(
                      'COACH · ${senderLabel.toUpperCase()}',
                      style: FacingTokens.microLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _agoLabel(note.createdAt),
                    style: FacingTokens.micro,
                  ),
                ],
              ),
              if (note.title.isNotEmpty) ...[
                const SizedBox(height: FacingTokens.sp1),
                Text(
                  note.title,
                  style: FacingTokens.body.copyWith(
                    fontWeight:
                        isUnread ? FontWeight.w800 : FontWeight.w700,
                    color: FacingTokens.fg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (note.body.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  note.body,
                  style: FacingTokens.caption.copyWith(
                    color: isUnread
                        ? FacingTokens.fg
                        : FacingTokens.muted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (note.kind == 'assignment') ...[
                const SizedBox(height: FacingTokens.sp2),
                Row(
                  children: [
                    if (dueLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FacingTokens.sp2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: dueLabel.color,
                          ),
                          borderRadius:
                              BorderRadius.circular(FacingTokens.r1),
                        ),
                        child: Text(
                          dueLabel.text,
                          style: FacingTokens.micro.copyWith(
                            color: dueLabel.color,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    const SizedBox(width: FacingTokens.sp2),
                    if (note.my != null)
                      Text(
                        note.my!.status.toUpperCase(),
                        style: FacingTokens.micro.copyWith(
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
        return FacingTokens.success;
      case 'accepted':
        return FacingTokens.fg;
      case 'declined':
        return FacingTokens.muted;
      case 'read':
        return FacingTokens.muted;
      case 'sent':
      default:
        return FacingTokens.accent;
    }
  }

  static _DueBadge? _dueLabel(String? dueDate) {
    if (dueDate == null || dueDate.isEmpty) return null;
    final due = DateTime.tryParse('${dueDate}T00:00:00');
    if (due == null) return null;
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final diff = due.difference(today).inDays;
    if (diff < 0) return _DueBadge('OVERDUE', color: FacingTokens.overdue);
    if (diff == 0) return _DueBadge('TODAY', color: FacingTokens.accent);
    if (diff <= 3) return _DueBadge('D-$diff', color: FacingTokens.accent);
    return _DueBadge('D-$diff', color: FacingTokens.muted);
  }

  static String _agoLabel(DateTime created) {
    final now = DateTime.now().toUtc();
    final d = now.difference(created.isUtc ? created : created.toUtc());
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    final l = created.toLocal();
    final mm = l.month.toString().padLeft(2, '0');
    final dd = l.day.toString().padLeft(2, '0');
    if (l.year != DateTime.now().year) {
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

/// 회원 NOTICE = 코치와의 1:1 대화. 상단 공지 핀 + 말풍선 타임라인 + 입력바.
class _MemberConversation extends StatefulWidget {
  final int gymId;
  const _MemberConversation({required this.gymId});

  @override
  State<_MemberConversation> createState() => _MemberConversationState();
}

class _MemberConversationState extends State<_MemberConversation> {
  late final InboxRepository _repo;
  late final GymRepository _gymRepo;
  final _ctrl = TextEditingController();
  Future<List<ChatMessage>>? _future;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final api = context.read<ApiClient>();
    _repo = InboxRepository(api);
    _gymRepo = GymRepository(api);
    _load();
  }

  void _load() {
    setState(() => _future = _repo.listMessages(widget.gymId));
  }

  Future<void> _send() async {
    final msg = _ctrl.text.trim();
    if (msg.isEmpty || _sending) return;
    Haptic.light();
    setState(() => _sending = true);
    try {
      await _gymRepo.memberReport(gymId: widget.gymId, message: msg);
      _ctrl.clear();
      _load();
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
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anns = context.watch<AnnouncementsState>().items;
    return Column(
      children: [
        if (anns.isNotEmpty) _PinnedAnnouncement(announcements: anns),
        Expanded(
          child: FutureBuilder<List<ChatMessage>>(
            future: _future,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: FacingTokens.muted, strokeWidth: 2),
                );
              }
              final msgs = snap.data ?? const <ChatMessage>[];
              if (msgs.isEmpty) return _empty();
              // 서버 desc → reverse:true 로 최신이 하단.
              return RefreshIndicator(
                onRefresh: () async => _load(),
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: FacingTokens.sp4,
                    vertical: FacingTokens.sp3,
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
        ),
      ],
    );
  }

  Widget _empty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 100),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No messages', style: FacingTokens.sectionLabel),
              SizedBox(height: FacingTokens.sp2),
              Text('코치에게 첫 쪽지를 보내보세요.', style: FacingTokens.caption),
            ],
          ),
        ),
      ],
    );
  }
}

/// 말풍선 — mine(보낸 것)=우측 accent, 받은 것=좌측 surface.
class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final mine = msg.mine;
    return Padding(
      padding: const EdgeInsets.only(bottom: FacingTokens.sp3),
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
                style: FacingTokens.microLabel.copyWith(
                  color:
                      msg.isAuto ? FacingTokens.success : FacingTokens.muted,
                ),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FacingTokens.sp3,
                vertical: FacingTokens.sp2 + 2,
              ),
              decoration: BoxDecoration(
                color: mine ? FacingTokens.accent : FacingTokens.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(FacingTokens.r3),
                  topRight: const Radius.circular(FacingTokens.r3),
                  bottomLeft: Radius.circular(
                      mine ? FacingTokens.r3 : FacingTokens.r1),
                  bottomRight: Radius.circular(
                      mine ? FacingTokens.r1 : FacingTokens.r3),
                ),
                border:
                    mine ? null : Border.all(color: FacingTokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.title.isNotEmpty) ...[
                    Text(
                      msg.title,
                      style: FacingTokens.body.copyWith(
                        fontWeight: FontWeight.w800,
                        color: FacingTokens.fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    msg.body,
                    style: FacingTokens.body.copyWith(color: FacingTokens.fg),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
            child: Text(_timeLabel(msg.createdAt), style: FacingTokens.micro),
          ),
        ],
      ),
    );
  }

  static String _timeLabel(DateTime t) {
    final now = DateTime.now();
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
          FacingTokens.sp4, FacingTokens.sp3, FacingTokens.sp4, 0),
      padding: const EdgeInsets.all(FacingTokens.sp3),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        borderRadius: BorderRadius.circular(FacingTokens.r2),
        border: Border.all(
          color:
              latest.isUrgent ? FacingTokens.accent : FacingTokens.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'NOTICE',
                style: FacingTokens.microLabel.copyWith(
                  color: latest.isUrgent
                      ? FacingTokens.accent
                      : FacingTokens.muted,
                ),
              ),
              if (more > 0) ...[
                const Spacer(),
                Text('+$more', style: FacingTokens.micro),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (latest.title.isNotEmpty)
            Text(
              latest.title,
              style: FacingTokens.body.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (latest.body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                latest.body,
                style: FacingTokens.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

/// 하단 입력바 — 회원이 코치에게 쪽지 발신.
class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _ChatInputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        FacingTokens.sp3,
        FacingTokens.sp2,
        FacingTokens.sp3,
        FacingTokens.sp2,
      ),
      decoration: const BoxDecoration(
        color: FacingTokens.bg,
        border: Border(top: BorderSide(color: FacingTokens.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 500,
              style: FacingTokens.body,
              decoration: InputDecoration(
                hintText: '코치에게 쪽지…',
                hintStyle: FacingTokens.caption,
                counterText: '',
                isDense: true,
                filled: true,
                fillColor: FacingTokens.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: FacingTokens.sp3,
                  vertical: FacingTokens.sp2 + 2,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FacingTokens.r3),
                  borderSide: const BorderSide(color: FacingTokens.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FacingTokens.r3),
                  borderSide: const BorderSide(color: FacingTokens.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FacingTokens.r3),
                  borderSide: const BorderSide(
                      color: FacingTokens.accent, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: FacingTokens.sp2),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: sending ? null : onSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: FacingTokens.accent,
                foregroundColor: FacingTokens.fg,
                padding:
                    const EdgeInsets.symmetric(horizontal: FacingTokens.sp3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FacingTokens.r3),
                ),
              ),
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: FacingTokens.fg, strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_upward, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
