import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/streak_freeze.dart';
import '../../core/theme.dart';
import '../../core/wod_session_bus.dart';
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
  WodSessionBus? _bus;
  Future<List<WodHistoryItem>>? _future;
  late DateTime _month; // 1일 00:00 기준

  @override
  void initState() {
    super.initState();
    _repo = HistoryRepository(context.read<ApiClient>());
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _reload();
    // WOD 완료 이벤트 구독 → 즉시 reload.
    _bus = context.read<WodSessionBus>();
    _bus?.addListener(_onSessionBump);
  }

  void _onSessionBump() {
    if (!mounted) return;
    _reload();
  }

  @override
  void dispose() {
    _bus?.removeListener(_onSessionBump);
    super.dispose();
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

  /// v1.16 Sprint 8 U3: 이달 세션 수 (챌린지 진행도용).
  int currentMonthSessionsCount(List<WodHistoryItem> rs) {
    final now = DateTime.now();
    return rs.where((r) {
      final d = r.createdAt.toLocal();
      return d.year == now.year && d.month == now.month;
    }).length;
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

    final streakNote = currentStreak == 0
        ? '오늘 세션하면 streak 시작.'
        : (currentStreak == longestStreak && currentStreak > 1)
            ? '최장 streak 갱신 중. 멈추지 말 것.'
            : currentStreak >= 7
                ? '$currentStreak일 연속. 페이스 유지.'
                : '$currentStreak일 연속.';

    // v1.16 Sprint 16: 월별 최대 세션 수 (heatmap 강도 normalizer).
    int maxCount = 1;
    for (final v in counts.values) {
      if (v > maxCount) maxCount = v;
    }

    return ListView(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      children: [
        // v1.16 Sprint 16: 월 헤더 대형화 + "N일 출석" 뿌듯 강조.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 24),
              onPressed: onPrevMonth,
            ),
            Column(
              children: [
                Text(
                  '${month.year}.${month.month.toString().padLeft(2, '0')}',
                  style: FacingTokens.h3.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$attendedDays일 · $attendancePct%',
                  style: FacingTokens.caption.copyWith(
                    color: FacingTokens.accent,
                    fontWeight: FontWeight.w800,
                    fontFeatures: FacingTokens.tabular,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 24),
              onPressed: onNextMonth,
            ),
          ],
        ),
        const SizedBox(height: FacingTokens.sp3),
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
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
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
            return _DayCell(
              day: dayNum,
              count: count,
              isToday: isToday,
              maxCount: maxCount,
            );
          },
        ),
        const SizedBox(height: FacingTokens.sp3),
        // v1.16 Sprint 16: Heatmap 범례.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('LESS',
                style: FacingTokens.micro.copyWith(
                  color: FacingTokens.muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                )),
            const SizedBox(width: FacingTokens.sp2),
            ...List.generate(4, (i) {
              final intensity = (i + 1) * 0.25;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: FacingTokens.accent.withValues(alpha: intensity),
                    borderRadius: BorderRadius.circular(FacingTokens.r1),
                  ),
                ),
              );
            }),
            const SizedBox(width: FacingTokens.sp2),
            Text('MORE',
                style: FacingTokens.micro.copyWith(
                  color: FacingTokens.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                )),
          ],
        ),
        const SizedBox(height: FacingTokens.sp5),

        // 2. STATS — 캘린더 하단 label·value ROW
        const Text('STATS', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        _StatLine(
          label: 'THIS MONTH',
          value: '$attendedDays / $daysInMonth 일',
          trailing: '$attendancePct%',
        ),
        _StatLine(
          label: 'TOTAL',
          value: '$totalLifetime sessions',
          trailing: '$uniqueDays days',
        ),
        _StatLine(
          label: 'CURRENT STREAK',
          value: '$currentStreak 일',
          trailing: null,
        ),
        _StatLine(
          label: 'LONGEST STREAK',
          value: '$longestStreak 일',
          trailing: null,
          isLast: true,
        ),
        const SizedBox(height: FacingTokens.sp2),
        Text(streakNote, style: FacingTokens.caption),
        const SizedBox(height: FacingTokens.sp4),
        // v1.20 Phase 2.5: Streak Freeze 버튼.
        const _StreakFreezeRow(),
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

        // v1.16 Sprint 8 U3: 월별 챌린지 mock 3건.
        const Text('CHALLENGES', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp1),
        Text('${DateTime.now().month}월. 매월 자동 리셋.',
            style: FacingTokens.caption),
        const SizedBox(height: FacingTokens.sp3),
        _ChallengeRow(
          title: '10 SESSIONS THIS MONTH',
          subtitle: '이달 WOD 10회 완주',
          current: currentMonthSessionsCount(records),
          target: 10,
        ),
        _ChallengeRow(
          title: 'HIT 3 CATEGORIES',
          subtitle: '카테고리별 WOD 고르게 1회 이상',
          current: (totalLifetime / 10).clamp(0, 3).round(),
          target: 3,
        ),
        _ChallengeRow(
          title: '7-DAY STREAK',
          subtitle: '7일 연속 출석',
          current: currentStreak.clamp(0, 7),
          target: 7,
        ),
        const SizedBox(height: FacingTokens.sp1),
        Text('* 챌린지는 가상 데이터. 실제 집계 연결은 Phase 2.',
            style: FacingTokens.micro),
      ],
    );
  }

}

/// v1.16: 캘린더 하단 통계를 label · value(· trailing) 한 줄씩 깔끔히.
class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  final String? trailing;
  final bool isLast;
  const _StatLine({
    required this.label,
    required this.value,
    this.trailing,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : FacingTokens.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: FacingTokens.micro.copyWith(
                color: FacingTokens.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: FacingTokens.body.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: FacingTokens.tabular,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: FacingTokens.body.copyWith(
                color: FacingTokens.muted,
                fontFeatures: FacingTokens.tabular,
              ),
            ),
        ],
      ),
    );
  }
}

/// v1.16 Sprint 8 U3: 월별 챌린지 row (마일스톤과 동일 시각, 다른 이름).
class _ChallengeRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final int current;
  final int target;
  const _ChallengeRow({
    required this.title,
    required this.subtitle,
    required this.current,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final done = current >= target;
    final pct = (current / target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: FacingTokens.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: done ? FacingTokens.fg : FacingTokens.muted,
                    )),
              ),
              Text(done ? 'COMPLETE' : '$current / $target',
                  style: FacingTokens.micro.copyWith(
                    color: done ? FacingTokens.accent : FacingTokens.muted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontFeatures: FacingTokens.tabular,
                  )),
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
                    color: done
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

/// v1.16 Sprint 16: Heatmap 강도 + 굵은 숫자 + Today 강조 + 다중 세션 체크.
/// "출석한 날은 정말 뿌듯하게 보이도록" — 페르소나 요구.
class _DayCell extends StatelessWidget {
  final int day;
  final int count;
  final bool isToday;
  final int maxCount;
  const _DayCell({
    required this.day,
    required this.count,
    required this.isToday,
    required this.maxCount,
  });

  /// 0 → 투명 · 1 → 0.45 · 2 → 0.70 · 3+ → 1.0 (full accent).
  double _intensity() {
    if (count <= 0) return 0;
    if (count == 1) return 0.45;
    if (count == 2) return 0.70;
    if (count == 3) return 0.88;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final hasSession = count > 0;
    final intensity = _intensity();
    final fillColor = hasSession
        ? FacingTokens.accent.withValues(alpha: intensity)
        : FacingTokens.surface;
    final textColor = hasSession
        ? FacingTokens.fg
        : (isToday ? FacingTokens.fg : FacingTokens.muted);
    final sessionLabel = hasSession ? '$count 세션' : '세션 없음';
    final todayLabel = isToday ? ', 오늘' : '';

    return Semantics(
      label: '$day일$todayLabel, $sessionLabel',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: fillColor,
          border: Border.all(
            color: isToday
                ? FacingTokens.fg
                : (hasSession ? Colors.transparent : FacingTokens.border),
            width: isToday ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(FacingTokens.r2),
          boxShadow: hasSession && count >= 2
              ? [
                  BoxShadow(
                    color: FacingTokens.accent.withValues(alpha: 0.35),
                    blurRadius: 6,
                    spreadRadius: -1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 큰 일자 숫자 — 출석 시 굵게 흰색.
            Text(
              '$day',
              style: (hasSession ? FacingTokens.body : FacingTokens.caption)
                  .copyWith(
                fontWeight:
                    hasSession ? FontWeight.w800 : FontWeight.w500,
                color: textColor,
                fontFeatures: FacingTokens.tabular,
              ),
            ),
            // 2+ 세션일 때 왼쪽 상단 체크 아이콘.
            if (count >= 2)
              Positioned(
                top: 2,
                left: 2,
                child: Icon(
                  Icons.check_circle,
                  size: 10,
                  color: FacingTokens.fg.withValues(alpha: 0.9),
                ),
              ),
            // 세션 수 라벨 — 1 이상일 때 우측 하단에 "×N".
            if (count > 1)
              Positioned(
                right: 3,
                bottom: 2,
                child: Text(
                  '×$count',
                  style: FacingTokens.sectionLabel.copyWith(
                    fontWeight: FontWeight.w800,
                    color: FacingTokens.fg.withValues(alpha: 0.95),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            // 오늘 표시 — 좌상단 accent dot.
            if (isToday)
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  width: 6,
                  height: 6,
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

/// v1.20 Phase 2.5: 주 1회 무료 Streak Freeze 토큰 사용 UI.
class _StreakFreezeRow extends StatefulWidget {
  const _StreakFreezeRow();

  @override
  State<_StreakFreezeRow> createState() => _StreakFreezeRowState();
}

class _StreakFreezeRowState extends State<_StreakFreezeRow> {
  Future<bool>? _availableFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _availableFuture = StreakFreezeStore.available();
    });
  }

  Future<void> _useFreeze() async {
    Haptic.medium();
    final ok = await StreakFreezeStore.consume();
    if (!mounted) return;
    if (ok) {
      Haptic.achievementUnlock();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Freeze used. Streak protected this week.'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Already used this week. Refills Monday.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    _refresh();
  }

  String _refillLabel(DateTime next) {
    return 'Refills ${next.year}-'
        '${next.month.toString().padLeft(2, '0')}-'
        '${next.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _availableFuture,
      builder: (ctx, snap) {
        final available = snap.data ?? false;
        final next = StreakFreezeStore.nextRefill();
        return Container(
          padding: const EdgeInsets.all(FacingTokens.sp3),
          decoration: BoxDecoration(
            color: FacingTokens.surface,
            border: Border.all(
              color: available ? FacingTokens.accent : FacingTokens.border,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(FacingTokens.r2),
          ),
          child: Row(
            children: [
              Icon(
                Icons.ac_unit_outlined,
                size: 18,
                color: available ? FacingTokens.accent : FacingTokens.muted,
              ),
              const SizedBox(width: FacingTokens.sp2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STREAK FREEZE',
                      style: FacingTokens.sectionLabel.copyWith(
                        color: available
                            ? FacingTokens.fg
                            : FacingTokens.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      available
                          ? '주 1회 무료. 사용 시 이번 주 streak 보호.'
                          : _refillLabel(next),
                      style: FacingTokens.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FacingTokens.sp2),
              ElevatedButton(
                onPressed: available ? _useFreeze : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(96, 40),
                  backgroundColor: available
                      ? FacingTokens.accent
                      : FacingTokens.border,
                  foregroundColor: available
                      ? FacingTokens.fg
                      : FacingTokens.muted,
                ),
                child: Text(available ? 'Use' : 'Used'),
              ),
            ],
          ),
        );
      },
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
