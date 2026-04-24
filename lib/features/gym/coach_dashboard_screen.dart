// v1.16 Sprint 12: Coach Dashboard — 승인 관리 + 멤버 로스터 + 활동 통계 + 부상 메모 mock.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import '../messages/messages_screen.dart';
import 'gym_repository.dart';
import 'gym_state.dart';

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  Future<List<GymMember>>? _future;

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
      return;
    }
    setState(() {
      _future = context.read<GymRepository>().listMembers(gym.id);
    });
  }

  Future<void> _decide(GymMember m, String action) async {
    Haptic.medium();
    final ok = await context.read<GymState>().decideMember(
          memberId: m.id,
          action: action,
        );
    if (!mounted) return;
    if (ok) {
      _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<GymState>().error ?? '처리 실패')),
      );
    }
  }

  void _openMemberSheet(GymMember m) {
    Haptic.light();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: FacingTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FacingTokens.r4)),
      ),
      builder: (ctx) => _MemberDetailSheet(member: m),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final gym = gs.membership.gym;
    return Scaffold(
      appBar: AppBar(
        title: const Text('COACH DASHBOARD'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: SafeArea(
        child: gym == null
            ? const Center(
                child: Text('박스 정보 없음.', style: FacingTokens.caption))
            : FutureBuilder<List<GymMember>>(
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
                    final msg =
                        e is AppException ? e.messageKo : '로딩 실패';
                    return Padding(
                      padding: const EdgeInsets.all(FacingTokens.sp4),
                      child: Text(msg, style: FacingTokens.body),
                    );
                  }
                  final members = snap.data ?? const [];
                  final pending = members.where((m) => m.isPending).toList();
                  final approved =
                      members.where((m) => m.isApproved).toList();
                  final rejected =
                      members.where((m) => m.isRejected).toList();
                  final activeCount = approved
                      .where((m) => m.lastWodAt != null && !m.isDormant)
                      .length;
                  final dormantCount =
                      approved.where((m) => m.isDormant).length;
                  final totalSessions = approved
                      .map((m) => m.totalSessions)
                      .fold<int>(0, (a, b) => a + b);

                  return ListView(
                    padding: const EdgeInsets.all(FacingTokens.sp4),
                    children: [
                      // Overview stats
                      Text(gym.name,
                          style: FacingTokens.h3.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: FacingTokens.sp1),
                      Text(
                        '${approved.length} approved · $activeCount active · $dormantCount dormant · $totalSessions sessions',
                        style: FacingTokens.caption,
                      ),
                      const SizedBox(height: FacingTokens.sp5),
                      if (pending.isNotEmpty) ...[
                        Text('PENDING (${pending.length})',
                            style: FacingTokens.sectionLabel),
                        const SizedBox(height: FacingTokens.sp2),
                        ...pending.map((m) => _PendingRow(
                              member: m,
                              onApprove: () => _decide(m, 'approve'),
                              onReject: () => _decide(m, 'reject'),
                            )),
                        const SizedBox(height: FacingTokens.sp5),
                      ],
                      Text('ROSTER (${approved.length})',
                          style: FacingTokens.sectionLabel),
                      const SizedBox(height: FacingTokens.sp2),
                      if (approved.isEmpty)
                        const Text('승인된 멤버 없음.',
                            style: FacingTokens.caption)
                      else
                        ...approved.map((m) => _RosterRow(
                              member: m,
                              onTap: () => _openMemberSheet(m),
                            )),
                      if (rejected.isNotEmpty) ...[
                        const SizedBox(height: FacingTokens.sp5),
                        Text('REJECTED (${rejected.length})',
                            style: FacingTokens.sectionLabel),
                        const SizedBox(height: FacingTokens.sp2),
                        ...rejected.map((m) => _RosterRow(
                              member: m,
                              onTap: () => _openMemberSheet(m),
                              muted: true,
                            )),
                      ],
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  final GymMember member;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingRow({
    required this.member,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('user:${member.deviceHashPrefix}',
                    style: FacingTokens.body.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                Text(_dateShort(member.requestedAt),
                    style: FacingTokens.caption),
              ],
            ),
          ),
          TextButton(onPressed: onApprove, child: const Text('Approve')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: FacingTokens.muted),
            onPressed: onReject,
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

class _RosterRow extends StatelessWidget {
  final GymMember member;
  final VoidCallback onTap;
  final bool muted;

  const _RosterRow({
    required this.member,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = muted ? FacingTokens.muted : FacingTokens.fg;
    final lastLabel = _lastLabel(member);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'user:${member.deviceHashPrefix}',
                          style: FacingTokens.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: FacingTokens.sp2),
                      if (member.isDormant)
                        _statusChip('DORMANT', FacingTokens.warning)
                      else if (member.lastWodAt == null && member.isApproved)
                        _statusChip('NEW', FacingTokens.muted),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastLabel,
                    style: FacingTokens.caption,
                  ),
                ],
              ),
            ),
            _numBlock(label: 'SESSIONS', value: '${member.totalSessions}'),
            const SizedBox(width: FacingTokens.sp3),
            _numBlock(label: 'STREAK', value: '${member.streakDays}'),
            const SizedBox(width: FacingTokens.sp2),
            const Icon(Icons.chevron_right, color: FacingTokens.muted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _numBlock({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: FacingTokens.micro.copyWith(
              color: FacingTokens.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            )),
        Text(value,
            style: FacingTokens.body.copyWith(
              fontFeatures: FacingTokens.tabular,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(FacingTokens.r1),
      ),
      child: Text(
        label,
        style: FacingTokens.micro.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _lastLabel(GymMember m) {
    if (m.status != 'approved') {
      return _dateShort(m.requestedAt);
    }
    if (m.lastWodAt == null) return '기록 없음';
    final days = m.daysSinceLastWod;
    if (days == 0) return '오늘 활동';
    if (days == 1) return '어제 활동';
    if (days < 7) return '$days일 전';
    if (days < 30) return '${days ~/ 7}주 전';
    return _dateShort(m.lastWodAt!);
  }
}

String _dateShort(DateTime d) {
  final l = d.toLocal();
  return '${l.month.toString().padLeft(2, '0')}/${l.day.toString().padLeft(2, '0')} '
      '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

/// v1.16 Sprint 12: 멤버 탭 시 bottom sheet — 코치 전용 mock 부상 메모.
class _MemberDetailSheet extends StatelessWidget {
  final GymMember member;
  const _MemberDetailSheet({required this.member});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(FacingTokens.sp5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('user:${member.deviceHashPrefix}',
                      style: FacingTokens.h3),
                ),
                Text(
                  member.status.toUpperCase(),
                  style: FacingTokens.micro.copyWith(
                    color: FacingTokens.accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FacingTokens.sp4),
            _kv('가입 요청', _dateShort(member.requestedAt)),
            if (member.decidedAt != null)
              _kv('승인·거절', _dateShort(member.decidedAt!)),
            _kv('총 세션', '${member.totalSessions}'),
            _kv('현재 Streak', '${member.streakDays} days'),
            _kv('마지막 WOD',
                member.lastWodAt == null ? '-' : _dateShort(member.lastWodAt!)),
            const SizedBox(height: FacingTokens.sp4),
            const Text('COACH NOTES', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            Container(
              padding: const EdgeInsets.all(FacingTokens.sp3),
              decoration: BoxDecoration(
                color: FacingTokens.surfaceOverlay,
                borderRadius: BorderRadius.circular(FacingTokens.r2),
                border: Border.all(color: FacingTokens.border),
              ),
              child: Text(
                member.isDormant
                    ? '⚠️ 가상 데이터 — 2주 이상 미참석. 재참여 캠페인 추천.'
                    : member.totalSessions == 0
                        ? '⚠️ 가상 데이터 — 신규 멤버. 첫 WOD 유도 필요.'
                        : '⚠️ 가상 데이터 — 부상 메모 · 목표 기록은 Phase 2.',
                style: FacingTokens.caption,
              ),
            ),
            const SizedBox(height: FacingTokens.sp4),
            if (member.deviceHashFull != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MessagesScreen(
                      withHash: member.deviceHashFull!,
                      withLabel: member.deviceHashPrefix,
                    ),
                  ));
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Send Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FacingTokens.accent,
                  foregroundColor: FacingTokens.fg,
                ),
              ),
            const SizedBox(height: FacingTokens.sp2),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(k,
                style: FacingTokens.micro.copyWith(
                  color: FacingTokens.muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                )),
          ),
          Expanded(
            child: Text(v,
                style: FacingTokens.body.copyWith(
                  fontFeatures: FacingTokens.tabular,
                )),
          ),
        ],
      ),
    );
  }
}
