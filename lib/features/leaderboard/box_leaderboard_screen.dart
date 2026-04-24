// v1.16 Sprint 13: 박스 내 리더보드 — total_sessions · streak_days 정렬.
// P5 페르소나 최우선 요구.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/exception.dart';
import '../../core/theme.dart';
import '../../models/gym.dart';
import '../gym/gym_repository.dart';
import '../gym/gym_state.dart';

enum _SortMode { sessions, streak }

class BoxLeaderboardScreen extends StatefulWidget {
  const BoxLeaderboardScreen({super.key});

  @override
  State<BoxLeaderboardScreen> createState() => _BoxLeaderboardScreenState();
}

class _BoxLeaderboardScreenState extends State<BoxLeaderboardScreen> {
  Future<List<GymMember>>? _future;
  _SortMode _sort = _SortMode.sessions;

  @override
  void initState() {
    super.initState();
    final gs = context.read<GymState>();
    final gym = gs.membership.gym;
    if (gym == null) {
      _future = Future.value(const []);
    } else {
      _future = context.read<GymRepository>().listMembers(gym.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GymState>();
    final gym = gs.membership.gym;
    return Scaffold(
      appBar: AppBar(title: const Text('LEADERBOARD')),
      body: SafeArea(
        child: gym == null
            ? const Center(
                child: Text('박스 소속 없음. Find Box에서 가입.',
                    style: FacingTokens.caption),
              )
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
                    final msg = e is AppException ? e.messageKo : '로딩 실패';
                    return Padding(
                      padding: const EdgeInsets.all(FacingTokens.sp4),
                      child: Text(msg, style: FacingTokens.body),
                    );
                  }
                  final members = (snap.data ?? const [])
                      .where((m) => m.isApproved)
                      .toList();
                  if (_sort == _SortMode.sessions) {
                    members.sort((a, b) =>
                        b.totalSessions.compareTo(a.totalSessions));
                  } else {
                    members.sort(
                        (a, b) => b.streakDays.compareTo(a.streakDays));
                  }
                  return ListView(
                    padding: const EdgeInsets.all(FacingTokens.sp4),
                    children: [
                      Text(gym.name,
                          style: FacingTokens.h3.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: FacingTokens.sp1),
                      Text('${members.length} approved · 익명 랭킹',
                          style: FacingTokens.caption),
                      const SizedBox(height: FacingTokens.sp3),
                      SegmentedButton<_SortMode>(
                        segments: const [
                          ButtonSegment(
                            value: _SortMode.sessions,
                            label: Text('Sessions'),
                          ),
                          ButtonSegment(
                            value: _SortMode.streak,
                            label: Text('Streak'),
                          ),
                        ],
                        selected: {_sort},
                        onSelectionChanged: (s) {
                          setState(() => _sort = s.first);
                        },
                      ),
                      const SizedBox(height: FacingTokens.sp4),
                      ...List.generate(members.length, (i) {
                        final m = members[i];
                        return _LeaderRow(
                          rank: i + 1,
                          member: m,
                          highlight: false,
                          metric: _sort == _SortMode.sessions
                              ? '${m.totalSessions}'
                              : '${m.streakDays}',
                          metricLabel: _sort == _SortMode.sessions
                              ? 'SESSIONS'
                              : 'DAYS',
                        );
                      }),
                      const SizedBox(height: FacingTokens.sp3),
                      const Text(
                        '⚠️ 가상 데이터 · 더미 멤버 포함. 실사용자 랭킹은 Phase 2.',
                        style: FacingTokens.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final int rank;
  final GymMember member;
  final bool highlight;
  final String metric;
  final String metricLabel;
  const _LeaderRow({
    required this.rank,
    required this.member,
    required this.highlight,
    required this.metric,
    required this.metricLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isTop = rank <= 3;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
      padding: const EdgeInsets.all(FacingTokens.sp3),
      decoration: BoxDecoration(
        color: highlight
            ? FacingTokens.accent.withValues(alpha: 0.12)
            : FacingTokens.surface,
        border: Border.all(
          color: highlight ? FacingTokens.accent : FacingTokens.border,
          width: highlight ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(FacingTokens.r2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: FacingTokens.h3.copyWith(
                color: isTop ? FacingTokens.accent : FacingTokens.fg,
                fontWeight: FontWeight.w800,
                fontFeatures: FacingTokens.tabular,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'user:${member.deviceHashPrefix}',
              style: FacingTokens.body.copyWith(
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(metricLabel,
                  style: FacingTokens.micro.copyWith(
                    color: FacingTokens.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  )),
              Text(metric,
                  style: FacingTokens.h3.copyWith(
                    fontFeatures: FacingTokens.tabular,
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
