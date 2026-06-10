import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../gym/gym_repository.dart';
import '../inbox/inbox_screen.dart' show MessagingFeed;

/// v1.23 (2026-06-02) 재배치 Phase 3: Attend = 출석 캘린더 전담.
/// 게이미피케이션(Level·업적·Milestones)은 Home 으로 이관됨.
/// 캘린더는 Profile 의 컴팩트 출석 카드를 이 화면으로 되돌린 것.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // G-6 (2026-06-10): IndexedStack 으로 탭 state 가 유지돼 앱 기동 시점
  // 출석 데이터가 세션 내내 캐시되는 문제 — pull-to-refresh 로 재조회.
  int _tick = 0;

  Future<void> _refresh() async {
    setState(() => _tick++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ATTEND'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: FacingTokens.accent,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp4),
            children: [
              _AttendanceCalendar(key: ValueKey('att-cal-$_tick')),
              const SizedBox(height: FacingTokens.sp5),
              const Divider(height: 1, color: FacingTokens.border),
              const SizedBox(height: FacingTokens.sp4),
              // v1.24 (2026-06-03): 공지·쪽지·대화를 Notice 탭에서 캘린더 밑으로 이동.
              MessagingFeed(key: ValueKey('att-feed-$_tick')),
            ],
          ),
        ),
      ),
    );
  }
}

/// 월별 출석 미니 캘린더 + 1줄 통계 (STREAK · TOTAL · THIS MONTH).
/// 데이터 소스: /api/v1/member/attendances — 진짜 QR 체크인(gym_attendances).
/// v1.25 (2026-06-09): 개인 페이싱 계산 기록(/history/wod)을 출석으로 칠하던
/// 버그 수정. 이제 실제 출석 데이터만 반영. 체크인 있는 날은 accent 강도색.
class _AttendanceCalendar extends StatefulWidget {
  const _AttendanceCalendar({super.key});

  @override
  State<_AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<_AttendanceCalendar> {
  Future<Map<DateTime, int>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final repo = GymRepository(context.read<ApiClient>());
    _future = repo.listMyAttendances();
  }

  int _currentStreak(Set<DateTime> days) {
    if (days.isEmpty) return 0;
    final today = DateTime.now();
    DateTime cursor = DateTime(today.year, today.month, today.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    int count = 0;
    while (days.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp4),
      child: FutureBuilder<Map<DateTime, int>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox(height: 80);
          }
          // E-2 (2026-06-10) — 네트워크 실패를 빈 출석으로 오인하지 않도록 분기
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp4),
              child: Column(
                children: [
                  Text('Load failed', style: FacingTokens.caption),
                  const SizedBox(height: FacingTokens.sp2),
                  TextButton(
                    onPressed: () => setState(_reload),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final byDay = snap.data ?? const <DateTime, int>{};
          final now = DateTime.now();
          final monthYear = now.year;
          final monthNum = now.month;
          final daysInMonth = DateUtils.getDaysInMonth(monthYear, monthNum);
          final firstWeekday = DateTime(monthYear, monthNum, 1).weekday % 7;
          final totalCells = ((firstWeekday + daysInMonth) / 7).ceil() * 7;

          final counts = <int, int>{};
          final allDays = <DateTime>{};
          int totalCheckins = 0;
          byDay.forEach((d, c) {
            allDays.add(DateTime(d.year, d.month, d.day));
            totalCheckins += c;
            if (d.year == monthYear && d.month == monthNum) {
              counts[d.day] = (counts[d.day] ?? 0) + c;
            }
          });
          int maxCount = 1;
          for (final v in counts.values) {
            if (v > maxCount) maxCount = v;
          }
          final streak = _currentStreak(allDays);
          final attended = counts.keys.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('ATTENDANCE', style: FacingTokens.sectionLabel),
                  const Spacer(),
                  Text(
                    '$monthYear.${monthNum.toString().padLeft(2, '0')}',
                    style: FacingTokens.caption,
                  ),
                ],
              ),
              const SizedBox(height: FacingTokens.sp3),
              // 요일 헤더
              Row(
                children: const ['일', '월', '화', '수', '목', '금', '토']
                    .map((w) => Expanded(
                          child: Center(
                            child: Text(w, style: FacingTokens.micro),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: FacingTokens.sp2),
              // 미니 캘린더 — 일자 숫자 + 강도색.
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCells,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (_, i) {
                  final dayNum = i - firstWeekday + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const SizedBox.shrink();
                  }
                  final count = counts[dayNum] ?? 0;
                  final isToday = now.day == dayNum;
                  final intensity =
                      count == 0 ? 0.0 : (0.35 + (count / maxCount) * 0.55);
                  return Container(
                    decoration: BoxDecoration(
                      color: count > 0
                          ? FacingTokens.accent.withValues(alpha: intensity)
                          : FacingTokens.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isToday
                            ? FacingTokens.accent
                            : FacingTokens.border,
                        width: isToday ? 1.5 : 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNum',
                      // R5: 하드코드 fontSize 제거 — micro(13) 토큰 기반.
                      style: FacingTokens.micro.copyWith(
                        height: 1,
                        fontWeight:
                            isToday ? FontWeight.w800 : FontWeight.w400,
                        color: count > 0
                            ? FacingTokens.fg
                            : FacingTokens.muted.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: FacingTokens.sp4),
              // 1줄 통계 — streak · total · 이달 출석.
              Row(
                children: [
                  _StatBlock(label: 'STREAK', value: '${streak}d'),
                  const SizedBox(width: FacingTokens.sp4),
                  _StatBlock(label: 'TOTAL', value: '$totalCheckins'),
                  const SizedBox(width: FacingTokens.sp4),
                  _StatBlock(label: 'THIS MONTH', value: '${attended}d'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FacingTokens.microLabel),
        const SizedBox(height: 2),
        Text(value,
            style: FacingTokens.h3.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: FacingTokens.tabular,
              color: FacingTokens.fg,
            )),
      ],
    );
  }
}
