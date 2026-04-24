import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../history/history_models.dart';
import '../history/history_repository.dart';

/// v1.15.3: 출석률 — 월별 WOD 완료 기록 캘린더.
/// 데이터 소스: /api/v1/history/wod. 세션 있는 날은 accent dot + 횟수.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final HistoryRepository _repo;
  Future<List<WodHistoryItem>>? _future;
  late DateTime _month; // 1일 00:00 기준

  @override
  void initState() {
    super.initState();
    _repo = HistoryRepository(context.read<ApiClient>());
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _repo.listWodHistory(limit: 200);
    });
  }

  void _shiftMonth(int delta) {
    Haptic.selection();
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ATTENDANCE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<WodHistoryItem>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: FacingTokens.muted),
                ),
              );
            }
            if (snap.hasError) {
              final e = snap.error;
              final msg = e is AppException ? e.messageKo : 'Load failed.';
              return _ErrorState(message: msg, onRetry: _reload);
            }
            final records = snap.data ?? const [];
            return _AttendanceBody(
              records: records,
              month: _month,
              onPrevMonth: () => _shiftMonth(-1),
              onNextMonth: () => _shiftMonth(1),
            );
          },
        ),
      ),
    );
  }
}

class _AttendanceBody extends StatelessWidget {
  final List<WodHistoryItem> records;
  final DateTime month;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  const _AttendanceBody({
    required this.records,
    required this.month,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  Map<int, int> _countsByDay() {
    final map = <int, int>{};
    for (final r in records) {
      final d = r.createdAt.toLocal();
      if (d.year != month.year || d.month != month.month) continue;
      map[d.day] = (map[d.day] ?? 0) + 1;
    }
    return map;
  }

  /// v1.16: 전체 기록에서 고유 일자 집합 (date 기준).
  Set<DateTime> _uniqueDays() {
    return records
        .map((r) {
          final d = r.createdAt.toLocal();
          return DateTime(d.year, d.month, d.day);
        })
        .toSet();
  }

  /// 현재 streak — 오늘(또는 가장 최근 세션일)부터 연속된 일수.
  int _currentStreak() {
    final days = _uniqueDays();
    if (days.isEmpty) return 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    // 오늘 또는 어제에 세션 있으면 카운트 시작.
    DateTime cursor = todayDate;
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

  /// 최장 streak — 전체 기록 중 최장 연속 일수.
  int _longestStreak() {
    final days = _uniqueDays().toList()..sort();
    if (days.isEmpty) return 0;
    int best = 1;
    int current = 1;
    for (int i = 1; i < days.length; i++) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _countsByDay();
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
    final totalCells = ((firstWeekday + daysInMonth) / 7).ceil() * 7;
    final today = DateTime.now();
    final attendedDays = counts.keys.length;
    final attendancePct = daysInMonth > 0
        ? (attendedDays / daysInMonth * 100).round()
        : 0;
    final totalLifetime = records.length;
    final uniqueDays = _uniqueDays().length;
    final currentStreak = _currentStreak();
    final longestStreak = _longestStreak();

    return ListView(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      children: [
        // 1. TOTAL — 평생 누적 세션
        const Text('TOTAL SESSIONS', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$totalLifetime', style: FacingTokens.displayCompact),
            const SizedBox(width: FacingTokens.sp2),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('sessions · $uniqueDays days',
                  style: FacingTokens.caption),
            ),
          ],
        ),
        const SizedBox(height: FacingTokens.sp5),

        // 2. STREAK — 현재·최장 연속 출석
        const Text('STREAK', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        Row(
          children: [
            Expanded(child: _StatBlock(label: 'CURRENT', value: '$currentStreak', unit: '일')),
            Expanded(child: _StatBlock(label: 'LONGEST', value: '$longestStreak', unit: '일')),
          ],
        ),
        const SizedBox(height: FacingTokens.sp2),
        if (currentStreak == 0)
          const Text('오늘 세션하면 streak 시작.', style: FacingTokens.caption)
        else if (currentStreak == longestStreak && currentStreak > 1)
          const Text('최장 streak 갱신 중. 멈추지 말 것.',
              style: FacingTokens.caption)
        else if (currentStreak >= 7)
          Text('$currentStreak일 연속. 페이스 유지.', style: FacingTokens.caption)
        else
          Text('$currentStreak일 연속.', style: FacingTokens.caption),
        const SizedBox(height: FacingTokens.sp5),

        // 3. MILESTONES — 단계별 진행도
        const Text('MILESTONES', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp3),
        _MilestoneRow(
          title: '7-day attendance',
          subtitle: '7일 연속 출석',
          current: longestStreak.clamp(0, 7),
          target: 7,
        ),
        _MilestoneRow(
          title: '30-day attendance',
          subtitle: '30일 연속 출석',
          current: longestStreak.clamp(0, 30),
          target: 30,
        ),
        _MilestoneRow(
          title: '50 sessions',
          subtitle: '평생 누적 50회',
          current: totalLifetime.clamp(0, 50),
          target: 50,
        ),
        _MilestoneRow(
          title: '100 sessions',
          subtitle: '평생 누적 100회',
          current: totalLifetime.clamp(0, 100),
          target: 100,
        ),
        _MilestoneRow(
          title: '365 sessions',
          subtitle: '평생 누적 365회',
          current: totalLifetime.clamp(0, 365),
          target: 365,
        ),
        const SizedBox(height: FacingTokens.sp5),

        // 4. THIS MONTH — 월별 요약 (기존 캘린더)
        const Text('THIS MONTH', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        Text('$attendedDays / $daysInMonth 일 · $attendancePct%',
            style: FacingTokens.body),
        const SizedBox(height: FacingTokens.sp3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrevMonth,
            ),
            Text(
              '${month.year}.${month.month.toString().padLeft(2, '0')}',
              style: FacingTokens.h3,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onNextMonth,
            ),
          ],
        ),
        const SizedBox(height: FacingTokens.sp2),
        Row(
          children: const [
            _WeekdayLabel('일'),
            _WeekdayLabel('월'),
            _WeekdayLabel('화'),
            _WeekdayLabel('수'),
            _WeekdayLabel('목'),
            _WeekdayLabel('금'),
            _WeekdayLabel('토'),
          ],
        ),
        const SizedBox(height: FacingTokens.sp2),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (_, i) {
            final dayNum = i - firstWeekday + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const SizedBox.shrink();
            }
            final count = counts[dayNum] ?? 0;
            final isToday = today.year == month.year &&
                today.month == month.month &&
                today.day == dayNum;
            return _DayCell(day: dayNum, count: count, isToday: isToday);
          },
        ),
      ],
    );
  }

}

/// v1.16: Streak 숫자 블록 (CURRENT · LONGEST).
class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _StatBlock({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: FacingTokens.micro.copyWith(
              color: FacingTokens.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            )),
        const SizedBox(height: FacingTokens.sp1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value,
                style: FacingTokens.h1.copyWith(
                  fontSize: 36,
                  fontFeatures: FacingTokens.tabular,
                )),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(unit, style: FacingTokens.caption),
            ),
          ],
        ),
      ],
    );
  }
}

/// v1.16: 마일스톤 row — 진행 바 + 해금 여부.
class _MilestoneRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final int current;
  final int target;
  const _MilestoneRow({
    required this.title,
    required this.subtitle,
    required this.current,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = current >= target;
    final pct = (current / target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: FacingTokens.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: unlocked ? FacingTokens.fg : FacingTokens.muted,
                  ),
                ),
              ),
              Text(
                unlocked ? 'UNLOCKED' : '$current / $target',
                style: FacingTokens.micro.copyWith(
                  color: unlocked ? FacingTokens.accent : FacingTokens.muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  fontFeatures: FacingTokens.tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp1),
          Text(subtitle, style: FacingTokens.caption),
          const SizedBox(height: FacingTokens.sp2),
          ClipRRect(
            borderRadius: BorderRadius.circular(FacingTokens.r1),
            child: Stack(
              children: [
                Container(height: 4, color: FacingTokens.border),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 4,
                    color: unlocked
                        ? FacingTokens.accent
                        : FacingTokens.accent.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(label,
            style: FacingTokens.micro.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            )),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final int count;
  final bool isToday;
  const _DayCell({
    required this.day,
    required this.count,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final hasSession = count > 0;
    final sessionLabel = hasSession ? '$count 세션' : '세션 없음';
    final todayLabel = isToday ? ', 오늘' : '';
    return Semantics(
      label: '$day일$todayLabel, $sessionLabel',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: hasSession
              ? FacingTokens.accent.withValues(alpha: 0.15)
              : FacingTokens.surface,
          border: Border.all(
            color: isToday ? FacingTokens.fg : FacingTokens.border,
            width: isToday ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(FacingTokens.r2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: FacingTokens.body.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: hasSession ? FacingTokens.fg : FacingTokens.muted,
              ),
            ),
            if (hasSession)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: FacingTokens.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(FacingTokens.sp5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: FacingTokens.body, textAlign: TextAlign.center),
          const SizedBox(height: FacingTokens.sp4),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
