// v1.16 Sprint 15: 박스 공지 리스트 + 코치 작성 UI.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/announcement.dart';
import '../gym/gym_repository.dart';
import '../gym/gym_state.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  Future<List<GymAnnouncement>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final gs = context.read<GymState>();
    final gym = gs.membership.gym;
    if (gym == null) {
      setState(() => _future = Future.value(const []));
    } else {
      setState(() {
        _future = context.read<GymRepository>().listAnnouncements(gym.id);
      });
    }
  }

  Future<void> _openCompose() async {
    Haptic.light();
    // QA B-ML-7: titleCtrl, bodyCtrl dispose 보장.
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String priority = 'normal';
    try {
      await showModalBottomSheet<void>(
      context: context,
      backgroundColor: FacingTokens.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FacingTokens.r4)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (innerCtx, setSheet) {
        return Padding(
          padding: EdgeInsets.only(
            left: FacingTokens.sp4,
            right: FacingTokens.sp4,
            top: FacingTokens.sp4,
            bottom:
                MediaQuery.of(ctx).viewInsets.bottom + FacingTokens.sp4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('NEW ANNOUNCEMENT',
                  style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp3),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: '제목 (선택)',
                ),
                maxLength: 120,
              ),
              const SizedBox(height: FacingTokens.sp2),
              TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(
                  labelText: '본문',
                  hintText: '멤버에게 전달할 내용',
                ),
                maxLines: 5,
                maxLength: 2000,
              ),
              const SizedBox(height: FacingTokens.sp3),
              Wrap(
                spacing: FacingTokens.sp2,
                children: ['normal', 'urgent']
                    .map((p) => ChoiceChip(
                          label: Text(p.toUpperCase()),
                          selected: priority == p,
                          backgroundColor: FacingTokens.surface,
                          selectedColor: FacingTokens.accent,
                          onSelected: (_) {
                            setSheet(() => priority = p);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: FacingTokens.sp4),
              ElevatedButton(
                onPressed: () async {
                  final body = bodyCtrl.text.trim();
                  if (body.isEmpty) return;
                  Haptic.medium();
                  final gs = context.read<GymState>();
                  final gym = gs.membership.gym;
                  if (gym == null) return;
                  try {
                    await context.read<GymRepository>().postAnnouncement(
                          gymId: gym.id,
                          title: titleCtrl.text.trim(),
                          body: body,
                          priority: priority,
                        );
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    _reload();
                  } on AppException catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('게시 실패: ${e.messageKo}')),
                    );
                  }
                },
                child: const Text('Post'),
              ),
            ],
          ),
        );
      }),
    );
    } finally {
      titleCtrl.dispose();
      bodyCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final gym = gs.membership.gym;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ANNOUNCEMENTS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: SafeArea(
        child: gym == null
            ? const Center(
                child: Text('박스 소속 없음.', style: FacingTokens.caption))
            : FutureBuilder<List<GymAnnouncement>>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: FacingTokens.muted, strokeWidth: 2),
                    );
                  }
                  if (snap.hasError) {
                    final e = snap.error;
                    final msg = e is AppException ? e.messageKo : '로딩 실패';
                    return Padding(
                      padding: const EdgeInsets.all(FacingTokens.sp4),
                      child: Text(msg, style: FacingTokens.body),
                    );
                  }
                  final items = snap.data ?? const <GymAnnouncement>[];
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('공지 없음.', style: FacingTokens.caption),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(FacingTokens.sp4),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: FacingTokens.sp3),
                    itemBuilder: (_, i) => _AnnouncementCard(item: items[i]),
                  );
                },
              ),
      ),
      floatingActionButton: gs.isOwner
          ? FloatingActionButton.extended(
              backgroundColor: FacingTokens.accent,
              foregroundColor: FacingTokens.fg,
              onPressed: _openCompose,
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('New'),
            )
          : null,
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final GymAnnouncement item;
  const _AnnouncementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final accent = item.isUrgent ? FacingTokens.accent : FacingTokens.muted;
    return Container(
      padding: const EdgeInsets.all(FacingTokens.sp3),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        borderRadius: BorderRadius.circular(FacingTokens.r2),
        border: Border.all(
          color: item.isUrgent ? FacingTokens.accent : FacingTokens.border,
          width: item.isUrgent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                item.priority.toUpperCase(),
                style: FacingTokens.micro.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(item.createdAt),
                style: FacingTokens.micro.copyWith(color: FacingTokens.muted),
              ),
            ],
          ),
          if (item.title.isNotEmpty) ...[
            const SizedBox(height: FacingTokens.sp1),
            Text(item.title,
                style: FacingTokens.h3.copyWith(fontWeight: FontWeight.w800)),
          ],
          const SizedBox(height: FacingTokens.sp1),
          Text(item.body, style: FacingTokens.body),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final l = d.toLocal();
    return '${l.month.toString().padLeft(2, '0')}/${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}
