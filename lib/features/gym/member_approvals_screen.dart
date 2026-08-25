// 가입 신청 승인 — 폰 코치가 하는 회원 관리는 이것 하나다.
//
// v3.21 (2026-08-25 사용자 지시): 구 CoachDashboardScreen 에서 회원 명단·활동
// 통계·회원 상세·코치 노트·회원 요청·체육관 프로필 수정을 전부 내렸다.
//   · 회원 명단/통계 → PC
//   · 코치 노트·회원 요청 → 쪽지 하나로 (중복이었다)
//   · 체육관 프로필 수정 → PC
// 남은 것은 '가입 신청 승인/거절' 뿐이라 이름도 그에 맞춘다 (§0-B).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import '../../widgets/coach_badge.dart';
import '../../widgets/hkit.dart';
import 'gym_repository.dart';
import 'gym_state.dart';
import '../../core/time_format.dart';

class MemberApprovalsScreen extends StatefulWidget {
  const MemberApprovalsScreen({super.key});

  @override
  State<MemberApprovalsScreen> createState() => _MemberApprovalsScreenState();
}

class _MemberApprovalsScreenState extends State<MemberApprovalsScreen> {
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
      HkSnack.error(context, context.read<GymState>().error ?? '처리 실패');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final gym = gs.membership.gym;
    return Scaffold(
      appBar: HkAppBar(
        title: '가입 신청',
        actions: [
          const CoachBadgeAction(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: SafeArea(
        child: gym == null
            ? const HkEmptyState(title: '체육관 정보 없음')
            : FutureBuilder<List<GymMember>>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const HkLoading();
                  }
                  if (snap.hasError) {
                    final e = snap.error;
                    final msg = e is AppException ? e.messageKo : '로딩 실패';
                    return Padding(
                      padding: const EdgeInsets.all(HyphenTokens.sp4),
                      child: Text(msg, style: HyphenTokens.body),
                    );
                  }
                  final members = snap.data ?? const [];
                  final pending = members.where((m) => m.isPending).toList();
                  if (pending.isEmpty) {
                    return const HkEmptyState(
                      title: '가입 신청 없음',
                      caption: '새 신청이 오면 여기에 뜹니다.',
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(HyphenTokens.sp4),
                    children: [
                      Text(
                        gym.name,
                        style: HyphenTokens.h3.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: HyphenTokens.sp3),
                      HkSectionLabel('승인 대기 (${pending.length})'),
                      const SizedBox(height: HyphenTokens.sp2),
                      ...pending.map(
                        (m) => _PendingRow(
                          member: m,
                          onApprove: () => _decide(m, 'approve'),
                          onReject: () => _decide(m, 'reject'),
                        ),
                      ),
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
      padding: const EdgeInsets.symmetric(vertical: HyphenTokens.sp2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: HyphenTokens.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  ymd(member.requestedAt),
                  style: HyphenTokens.caption,
                ),
                if ((member.phone ?? '').isNotEmpty)
                  Text(member.phone!, style: HyphenTokens.caption),
              ],
            ),
          ),
          HkButton.tertiary('승인', onPressed: onApprove),
          HkButton.tertiary('거절', neutral: true, onPressed: onReject),
        ],
      ),
    );
  }
}
