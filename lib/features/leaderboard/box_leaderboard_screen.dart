// v1.16 Sprint 13: 체육관 내 리더보드 — total_sessions · streak_days 정렬.
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
      appBar: AppBar(title: const Text('리더보드')),
      body: SafeArea(
        child: gym == null
            ? const Center(
                child: Text('체육관 소속 없음. 가입 후 이용 가능.',
                    style: HyphenTokens.caption),
              )
            : FutureBuilder<List<GymMember>>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: HyphenTokens.muted, strokeWidth: 2),
                    );
                  }
                  if (snap.hasError) {
                    final e = snap.error;
                    final msg = e is AppException ? e.messageKo : '로딩 실패';
                    return Padding(
                      padding: const EdgeInsets.all(HyphenTokens.sp4),
                      child: Text(msg, style: HyphenTokens.body),
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
                    padding: const EdgeInsets.all(HyphenTokens.sp4),
                    children: [
                      Text(gym.name,
                          style: HyphenTokens.h3.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: HyphenTokens.sp1),
                      Text('승인 회원 ${members.length}명 · 익명 랭킹',
                          style: HyphenTokens.caption),
                      const SizedBox(height: HyphenTokens.sp3),
                      SegmentedButton<_SortMode>(
                        segments: const [
                          ButtonSegment(
                            value: _SortMode.sessions,
                            label: Text('세션'),
                          ),
                          ButtonSegment(
                            value: _SortMode.streak,
                            label: Text('스트릭'),
                          ),
                        ],
                        selected: {_sort},
                        onSelectionChanged: (s) {
                          setState(() => _sort = s.first);
                        },
                      ),
                      const SizedBox(height: HyphenTokens.sp4),
                      // /go 전수조사: 빈 멤버 상태 명시 — 이전엔 빈 ListView 로 로딩과 구분 불가.
                      if (members.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: HyphenTokens.sp5),
                          child: Center(
                            child: Text(
                              '승인된 멤버 없음. 코치 승인 후 랭킹 표시.',
                              style: HyphenTokens.caption,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
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
                      const SizedBox(height: HyphenTokens.sp3),
                      const Text(
                        '익명 해시 기반 랭킹. 닉네임 표시는 추후 지원.',
                        style: HyphenTokens.caption,
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
      margin: const EdgeInsets.symmetric(vertical: HyphenTokens.sp1),
      padding: const EdgeInsets.all(HyphenTokens.sp3),
      decoration: BoxDecoration(
        color: highlight
            ? HyphenTokens.accent.withValues(alpha: 0.12)
            : HyphenTokens.surface,
        border: Border.all(
          color: highlight ? HyphenTokens.accent : HyphenTokens.border,
          width: highlight ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(HyphenTokens.r2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: HyphenTokens.h3.copyWith(
                color: isTop ? HyphenTokens.accent : HyphenTokens.fg,
                fontWeight: FontWeight.w800,
                fontFeatures: HyphenTokens.tabular,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'user:${member.deviceHashPrefix}',
              style: HyphenTokens.body.copyWith(
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(metricLabel, style: HyphenTokens.microLabel),
              Text(metric,
                  style: HyphenTokens.h3.copyWith(
                    fontFeatures: HyphenTokens.tabular,
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
