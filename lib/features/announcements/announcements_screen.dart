// v1.16 Sprint 15: 박스 공지 리스트 + 코치 작성 UI.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/announcement.dart';
import '../../widgets/coach_badge.dart';
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
                  labelText: 'Title',
                ),
                maxLength: 120,
              ),
              const SizedBox(height: FacingTokens.sp2),
              TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Body',
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
                  } catch (e) {
                    // /go Tier 3: generic catch.
                    debugPrint('[Announcements._compose] $e');
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('게시 실패. 다시 시도.')),
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
          if (gs.isOwner) const CoachBadgeAction(),
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _GymInfoCard(gym: gym),
                      Expanded(
                        child: items.isEmpty
                            ? const Center(
                                child: Text('공지 없음.',
                                    style: FacingTokens.caption),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(FacingTokens.sp4),
                                itemCount: items.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: FacingTokens.sp3),
                                itemBuilder: (_, i) =>
                                    _AnnouncementCard(item: items[i]),
                              ),
                      ),
                    ],
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

/// 공지 화면 상단 — 박스 요약 카드 (가상 데이터 포함).
/// TODO(go): 코치 프로필·수업시간·모토를 API로 연동 시 _mock* 상수 제거.
class _GymInfoCard extends StatelessWidget {
  final GymSummary gym;
  const _GymInfoCard({required this.gym});

  static const _mockCoach = '김준혁 코치 · CrossFit L2 Trainer, 체육학 석사';
  static const _mockTimes =
      '평일  06:00 · 07:00 · 18:30 · 19:30\n주말  09:00 · 10:00';
  static const _mockMotto = 'Every rep counts.';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          FacingTokens.sp4, FacingTokens.sp4, FacingTokens.sp4, 0),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        borderRadius: BorderRadius.circular(FacingTokens.r2),
        border: Border.all(color: FacingTokens.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: const BoxDecoration(
                color: FacingTokens.accent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(FacingTokens.r2),
                  bottomLeft: Radius.circular(FacingTokens.r2),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(FacingTokens.sp4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gym.name,
                      style: FacingTokens.h3
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (gym.location.isNotEmpty) ...[
                      const SizedBox(height: FacingTokens.sp1),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: FacingTokens.muted),
                          const SizedBox(width: FacingTokens.sp1),
                          Text(gym.location, style: FacingTokens.caption),
                        ],
                      ),
                    ],
                    const SizedBox(height: FacingTokens.sp3),
                    const Divider(color: FacingTokens.border, height: 1),
                    const SizedBox(height: FacingTokens.sp3),
                    _InfoRow(label: 'COACH', value: _mockCoach),
                    const SizedBox(height: FacingTokens.sp3),
                    _InfoRow(label: 'CLASS', value: _mockTimes),
                    const SizedBox(height: FacingTokens.sp3),
                    Text('MOTTO', style: FacingTokens.sectionLabel),
                    const SizedBox(height: FacingTokens.sp1),
                    Text(_mockMotto, style: FacingTokens.quote),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp1),
        Text(value,
            style: FacingTokens.body.copyWith(height: 1.6)),
      ],
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
                style: FacingTokens.microLabel.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
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
