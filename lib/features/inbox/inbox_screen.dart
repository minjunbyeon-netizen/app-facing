// v1.22: Inbox → NOTICE 단일 피드 (날짜순). ALL/NOTES/ASSIGNMENTS/OUTBOX 4탭 폐지.
//
// 톤: 흑백·전사·Obsession.
// Coach Dossier 카드: 좌 4px accent stripe + 이니셜 모노그램.
// 미읽음: stripe accent + 굵은 폰트.
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

class _InboxScreenState extends State<InboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gym = context.read<GymState>().membership.gym;
      if (gym != null) {
        context.read<InboxState>().bind(gym.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InboxState>();
    final gs = context.watch<GymState>();
    final isCoach = gs.isOwner;

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
                    ? const Center(
                        child: Text('No notices.',
                            style: FacingTokens.caption),
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
