import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import 'gym_repository.dart';
import 'gym_state.dart';

/// v1.15.3: 코치 전용 — 멤버 pending/approved/rejected 관리.
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
    if (gym == null || !gs.isOwner) {
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

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final gym = gs.membership.gym;
    return Scaffold(
      appBar: AppBar(
        title: const Text('MANAGE MEMBERS'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: SafeArea(
        child: !gs.isOwner || gym == null
            ? const Center(
                child: Text('코치 권한이 없음.', style: FacingTokens.caption))
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
                  if (members.isEmpty) {
                    return const Center(
                        child:
                            Text('가입 요청 없음.', style: FacingTokens.caption));
                  }
                  final pending =
                      members.where((m) => m.isPending).toList();
                  final approved =
                      members.where((m) => m.isApproved).toList();
                  final rejected =
                      members.where((m) => m.isRejected).toList();
                  return ListView(
                    padding: const EdgeInsets.all(FacingTokens.sp4),
                    children: [
                      _Section(
                        title: 'PENDING (${pending.length})',
                        members: pending,
                        actionLabel: (_) => 'approve·reject',
                        onApprove: (m) => _decide(m, 'approve'),
                        onReject: (m) => _decide(m, 'reject'),
                      ),
                      const SizedBox(height: FacingTokens.sp5),
                      _Section(
                        title: 'APPROVED (${approved.length})',
                        members: approved,
                      ),
                      const SizedBox(height: FacingTokens.sp5),
                      _Section(
                        title: 'REJECTED (${rejected.length})',
                        members: rejected,
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<GymMember> members;
  final String Function(GymMember)? actionLabel;
  final void Function(GymMember)? onApprove;
  final void Function(GymMember)? onReject;

  const _Section({
    required this.title,
    required this.members,
    this.actionLabel,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        if (members.isEmpty)
          const Text('없음', style: FacingTokens.caption)
        else
          ...members.map((m) => Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('user:${m.deviceHashPrefix}',
                              style: FacingTokens.body.copyWith(
                                fontWeight: FontWeight.w700,
                              )),
                          Text(_formatDate(m.requestedAt),
                              style: FacingTokens.caption),
                        ],
                      ),
                    ),
                    if (onApprove != null)
                      TextButton(
                        onPressed: () => onApprove!(m),
                        child: const Text('Approve'),
                      ),
                    if (onReject != null)
                      TextButton(
                        style: TextButton.styleFrom(
                            foregroundColor: FacingTokens.muted),
                        onPressed: () => onReject!(m),
                        child: const Text('Reject'),
                      ),
                  ],
                ),
              )),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}
