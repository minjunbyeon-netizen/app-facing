// v1.18 Sprint 19: Inbox 통합 화면 — 4 탭 (All / Notes / Assignments / Announcements).
//
// 톤: 흑백·전사·Obsession.
// Coach Dossier 카드: 좌 4px accent stripe + 이니셜 모노그램.
// 미읽음: stripe accent + 굵은 폰트 + 우측 빨간 dot.
// 읽음: stripe muted + 보통 폰트.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/coach_note.dart';
import '../../widgets/coach_badge.dart';
import '../../widgets/avatar.dart';
import '../gym/gym_state.dart';
import 'compose_note_screen.dart';
import 'group_management_screen.dart';
import 'inbox_state.dart';
import 'note_detail_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _isCoach = false;

  @override
  void initState() {
    super.initState();
    final isCoach = context.read<GymState>().isOwner;
    _isCoach = isCoach;
    // v1.19 페르소나 P2-27: Outbox 탭은 코치만 노출 → 회원은 3탭, 코치는 4탭.
    _tabs = TabController(length: isCoach ? 4 : 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gym = context.read<GymState>().membership.gym;
      if (gym != null) {
        context.read<InboxState>().bind(gym.id);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InboxState>();
    final gs = context.watch<GymState>();
    final isCoach = gs.isOwner;
    // QA B-INB-1: build() 안 dispose+재생성 → assertion. PostFrameCallback 으로 다음 프레임에 setState.
    if (isCoach != _isCoach) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (gs.isOwner == _isCoach) return; // 이미 동기화됨
        setState(() {
          _tabs.dispose();
          _isCoach = gs.isOwner;
          _tabs = TabController(length: _isCoach ? 4 : 3, vsync: this);
        });
      });
    }
    final items = state.inbox.items;

    final notes = items.where((n) => n.kind == 'note').toList();
    final assignments = items.where((n) => n.kind == 'assignment').toList();

    final tabs = <Tab>[
      Tab(text: 'ALL · ${items.length}'),
      Tab(text: 'NOTES · ${notes.length}'),
      Tab(text: 'ASSIGNMENTS · ${assignments.length}'),
      if (isCoach) const Tab(text: 'OUTBOX'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('INBOX'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: FacingTokens.accent,
          labelColor: FacingTokens.fg,
          unselectedLabelColor: FacingTokens.muted,
          labelStyle: FacingTokens.micro.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
          tabs: tabs,
        ),
        actions: [
          if (isCoach) const CoachBadgeAction(),
          IconButton(
            icon: const Icon(Icons.refresh),
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
        ],
      ),
      body: SafeArea(
        child: state.isLoading && items.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: FacingTokens.muted,
                  strokeWidth: 2,
                ),
              )
            // /go 전수조사: state.error 노출 + Retry — 이전엔 빈 화면만 표시.
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
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _NoteList(notes: items),
                      _NoteList(notes: notes),
                      _NoteList(notes: assignments),
                      if (isCoach) _OutboxView(visible: isCoach),
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
                  await state.refreshOutbox();
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

class _NoteList extends StatelessWidget {
  final List<CoachNote> notes;
  const _NoteList({required this.notes});

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const Center(
        child: Text('No items.', style: FacingTokens.caption),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        vertical: FacingTokens.sp3,
        horizontal: FacingTokens.sp4,
      ),
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: FacingTokens.sp3),
      itemBuilder: (ctx, i) => CoachDossierTile(note: notes[i]),
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
        // v1.19 페르소나 P0-2: 비균일 border 는 borderRadius 와 충돌. 좌측 stripe 는
        // child 로 그려서 회피.
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
              Expanded(child: Padding(
                padding: const EdgeInsets.all(FacingTokens.sp3),
                child: _buildBody(stripeColor, dueLabel, senderLabel, isUnread),
              )),
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
            // v1.19 페르소나 P0-2: hash 이니셜 → display_name + 색상 아바타.
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
                            : (note.kind == 'assignment' ? 'ASSIGNMENT' : 'NOTE'),
                        style: FacingTokens.micro.copyWith(
                          color: note.isAuto
                              ? FacingTokens.success
                              : stripeColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: FacingTokens.sp2),
                      Flexible(
                        child: Text(
                          'COACH · ${senderLabel.toUpperCase()}',
                          style: FacingTokens.micro.copyWith(
                            color: FacingTokens.muted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
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
                        fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
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
                        color: isUnread ? FacingTokens.fg : FacingTokens.muted,
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
            // v1.19 페르소나 P2-20: 카드 dot 제거. 좌측 4px stripe 만으로 미읽음 표시 충분.
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
    // QA B-TZ-1: due_date 는 백엔드 KST 기준 YYYY-MM-DD. 로컬 시간으로 비교.
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final diff = due.difference(today).inDays;
    // v1.19 페르소나 P2-22: OVERDUE 색을 accent → overdue (warning) 로 분리.
    if (diff < 0) return _DueBadge('OVERDUE', color: FacingTokens.overdue);
    if (diff == 0) return _DueBadge('TODAY', color: FacingTokens.accent);
    if (diff <= 3) return _DueBadge('D-$diff', color: FacingTokens.accent);
    return _DueBadge('D-$diff', color: FacingTokens.muted);
  }

  static String _agoLabel(DateTime created) {
    // QA B-TZ-2: created 는 UTC. now 도 UTC 로 통일해 차이 계산.
    final now = DateTime.now().toUtc();
    final d = now.difference(created.isUtc ? created : created.toUtc());
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    final l = created.toLocal();
    final mm = l.month.toString().padLeft(2, '0');
    final dd = l.day.toString().padLeft(2, '0');
    // QA B-LW-1: 1년 이상 지난 항목은 YYYY-MM-DD 로 연도 명시.
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

class _OutboxView extends StatefulWidget {
  final bool visible;
  const _OutboxView({required this.visible});

  @override
  State<_OutboxView> createState() => _OutboxViewState();
}

class _OutboxViewState extends State<_OutboxView> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<InboxState>().refreshOutbox();
        if (mounted) setState(() => _loaded = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) {
      return const Center(
        child: Text('Coach only.', style: FacingTokens.caption),
      );
    }
    final state = context.watch<InboxState>();
    final items = state.outbox;
    if (!_loaded && items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: FacingTokens.muted,
          strokeWidth: 2,
        ),
      );
    }
    if (items.isEmpty) {
      return const Center(
        child: Text('Nothing sent yet.', style: FacingTokens.caption),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: FacingTokens.sp3),
      itemBuilder: (ctx, i) {
        final o = items[i];
        return Container(
          decoration: BoxDecoration(
            color: FacingTokens.surface,
            border: Border.all(color: FacingTokens.border),
            borderRadius: BorderRadius.circular(FacingTokens.r2),
          ),
          padding: const EdgeInsets.all(FacingTokens.sp3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'TO ${_targetLabel(o.note)}',
                    style: FacingTokens.micro.copyWith(
                      color: FacingTokens.muted,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    o.note.kind.toUpperCase(),
                    style: FacingTokens.micro.copyWith(
                      color: FacingTokens.accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              if (o.note.title.isNotEmpty) ...[
                const SizedBox(height: FacingTokens.sp1),
                Text(o.note.title,
                    style: FacingTokens.h3
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
              if (o.note.body.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(o.note.body,
                    style: FacingTokens.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: FacingTokens.sp2),
              Row(
                children: [
                  Text(
                    '${o.stats.read}/${o.stats.total} read',
                    style: FacingTokens.micro,
                  ),
                  const SizedBox(width: FacingTokens.sp3),
                  if (o.note.kind == 'assignment')
                    Text(
                      '${o.stats.completed}/${o.stats.total} completed',
                      style: FacingTokens.micro.copyWith(
                        color: FacingTokens.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _targetLabel(CoachNote n) {
    switch (n.targetType) {
      case 'all':
        return 'ALL MEMBERS';
      case 'group':
        // QA B-LW-2: group ID 노출은 코치에게도 무의미. 'GROUP' 라벨만.
        // 그룹 이름 매핑은 별도 caller(_OutboxView)에서 plumb 가능 → 향후 개선.
        return 'GROUP';
      case 'individual':
      default:
        final id = (n.targetId ?? '').toString();
        return id.length < 8 ? id : id.substring(0, 8);
    }
  }
}
