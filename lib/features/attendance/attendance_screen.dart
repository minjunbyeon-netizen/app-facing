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

  @override
  Widget build(BuildContext context) {
    final counts = _countsByDay();
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    // DateTime.weekday: 월=1 ~ 일=7. 캘린더 1열=일요일 기준 정렬.
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7; // 0=Sun
    final totalCells = ((firstWeekday + daysInMonth) / 7).ceil() * 7;
    final today = DateTime.now();
    final attendedDays = counts.keys.length;
    final totalSessions = counts.values.fold<int>(0, (a, b) => a + b);
    final attendancePct = daysInMonth > 0
        ? (attendedDays / daysInMonth * 100).round()
        : 0;

    return ListView(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      children: [
        const SizedBox(height: FacingTokens.sp2),
        // 상단 요약
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$attendancePct%', style: FacingTokens.displayCompact),
            const SizedBox(width: FacingTokens.sp2),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$attendedDays / $daysInMonth 일',
                      style: FacingTokens.caption),
                  Text('총 $totalSessions 세션',
                      style: FacingTokens.caption),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: FacingTokens.sp4),
        // 월 네비
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
        const SizedBox(height: FacingTokens.sp3),
        // 요일 헤더 (일~토)
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
        // 날짜 그리드
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
        const SizedBox(height: FacingTokens.sp5),
        const Text('이번 달 세션', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        ..._monthSessions(counts, month),
      ],
    );
  }

  List<Widget> _monthSessions(Map<int, int> counts, DateTime month) {
    if (counts.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
          child: Text('세션 없음', style: FacingTokens.caption),
        ),
      ];
    }
    final days = counts.keys.toList()..sort();
    return days.map((d) {
      final c = counts[d]!;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text('$d일',
                  style: FacingTokens.body.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
            ),
            const SizedBox(width: FacingTokens.sp3),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: FacingTokens.accent.withValues(alpha: 0.25),
                  borderRadius:
                      BorderRadius.circular(FacingTokens.r1.toDouble()),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (c / 3).clamp(0.15, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: FacingTokens.accent,
                      borderRadius:
                          BorderRadius.circular(FacingTokens.r1.toDouble()),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: FacingTokens.sp3),
            Text('$c',
                style: FacingTokens.body.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: FacingTokens.tabular,
                )),
          ],
        ),
      );
    }).toList();
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
