import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/haptic.dart';
import '../../core/level_system.dart';
import '../../core/pr_detector.dart';
import '../../core/streak_freeze.dart';
import '../../core/theme.dart';
import '../../core/wod_session_bus.dart';
import '../../models/achievement.dart';
import '../../widgets/inbox_bell.dart';
import '../achievement/achievement_section.dart';
import '../achievement/achievement_state.dart';
import '../history/history_models.dart';
import '../history/history_repository.dart';
import '../profile/profile_state.dart';

/// v1.15.3: 출석률 — 월별 WOD 완료 기록 캘린더.
/// 데이터 소스: /api/v1/history/wod. 세션 있는 날은 accent dot + 횟수.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  /// QA B-PF-6: 매직 200 제거. ~6개월 일일 1세션 가정 — 캘린더 + streak 계산에 충분.
  /// 200 초과 사용자는 페이지네이션 도입 시점 (Phase 2.5 backlog).
  static const int _kHistoryLimit = 200;

  late final HistoryRepository _repo;
  WodSessionBus? _bus;
  Future<List<WodHistoryItem>>? _future;
  /// /go Tier 3: Streak Freeze 통합 — 마지막 사용일을 _currentStreak 계산 시 활용.
  DateTime? _freezeUse;

  @override
  void initState() {
    super.initState();
    _repo = HistoryRepository(context.read<ApiClient>());
    _reload();
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
      _future = _repo.listWodHistory(limit: _kHistoryLimit);
    });
    StreakFreezeStore.lastUse().then((dt) {
      if (!mounted) return;
      setState(() => _freezeUse = dt);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // v1.21: ATTEND = 출석 + 레벨 + 해금 + 업적 통합 ("쌓아온 것").
        title: const Text('ATTEND'),
        actions: [
          const InboxBellAction(),
          IconButton(
            tooltip: 'Refresh',
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
              freezeUse: _freezeUse,
            );
          },
        ),
      ),
    );
  }
}

class _AttendanceBody extends StatelessWidget {
  final List<WodHistoryItem> records;
  /// /go Tier 3: 이번 주 freeze 사용 기록. 있으면 streak 1일 보호.
  final DateTime? freezeUse;
  const _AttendanceBody({
    required this.records,
    required this.freezeUse,
  });

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
  /// /go Tier 3: freezeUse 가 있으면 missing day 1일 보호 (streak 카운트에 포함).
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
    bool freezeAvailable = freezeUse != null;
    int count = 0;
    while (true) {
      if (days.contains(cursor)) {
        count++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (freezeAvailable) {
        // freeze 1회 적용: 이 missing day 를 streak 1일로 보호 + skip.
        freezeAvailable = false;
        count++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return count;
  }


  @override
  Widget build(BuildContext context) {
    final totalLifetime = records.length;
    final currentStreak = _currentStreak();
    final now = DateTime.now();
    final thisMonthCount = records.where((r) {
      final d = r.createdAt.toLocal();
      return d.year == now.year && d.month == now.month;
    }).length;
    final daysElapsed = now.day;
    final achState = context.watch<AchievementState>();
    final unlockedCount = achState.snapshot.unlocked.length;
    final int nextMilestone;
    if (totalLifetime < 50) {
      nextMilestone = 50;
    } else if (totalLifetime < 100) {
      nextMilestone = 100;
    } else {
      nextMilestone = 365;
    }

    return ListView(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      children: [
        // v1.22 rev3: Attend = 게이미피케이션 전용. 캘린더+stats Profile 로 이관.
        // LEVEL 카드 = 캐릭터 + 진화. 화면 최상단.
        _LevelCard(
          totalSessions: totalLifetime,
          currentStreakDays: currentStreak,
          prCount: PrDetector.countPrs(records),
        ),
        const SizedBox(height: FacingTokens.sp4),
        const _StreakFreezeRow(),
        const SizedBox(height: FacingTokens.sp5),

        // 3. MILESTONES — 3종 요약 진행바
        const Text('MILESTONES', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp3),
        _ProgressStat(
          title: 'Attendance',
          subtitle: '이번 달 출석 · $thisMonthCount / $daysElapsed days',
          value: daysElapsed > 0 ? (thisMonthCount / daysElapsed).clamp(0.0, 1.0) : 0.0,
          trailing: daysElapsed > 0 ? '${(thisMonthCount / daysElapsed * 100).round()}%' : '0%',
        ),
        _ProgressStat(
          title: 'Sessions',
          subtitle: '누적 $totalLifetime회 → $nextMilestone 목표',
          value: (totalLifetime / nextMilestone).clamp(0.0, 1.0),
          trailing: totalLifetime >= 365 ? 'MAX' : '$totalLifetime / $nextMilestone',
        ),
        _ProgressStat(
          title: 'Achievements',
          subtitle: '업적 해금',
          value: (unlockedCount / 96).clamp(0.0, 1.0),
          trailing: '$unlockedCount / 96',
        ),
        const SizedBox(height: FacingTokens.sp5),

        // v1.22 rev2: CHALLENGES 섹션 제거 — mock 데이터 + MILESTONES 와 중복.
        // 업적 + 해금 갤러리.
        const AchievementSection(),
      ],
    );
  }
}

/// v1.22 rev2: LEVEL 카드 — 친근한 캐릭터 + 격려 캡션 추가.
/// 레벨대별 stickman 진화 (motivation → discipline → obsession).
class _LevelCard extends StatelessWidget {
  final int totalSessions;
  final int currentStreakDays;
  final int prCount;
  const _LevelCard({
    required this.totalSessions,
    required this.currentStreakDays,
    required this.prCount,
  });

  /// v1.22 rev6: 레벨대별 캐릭터 진화. lv2/lv3 자산 없으면 mascot.png 폴백.
  /// 5 단계로 분기 — 추후 mascot_lv{2,3,4,5}.png 추가 시 자동 적용.
  String _mascotForLevel(int level) {
    if (level >= 41) return 'assets/images/character/mascot_lv5.png';
    if (level >= 31) return 'assets/images/character/mascot_lv4.png';
    if (level >= 21) return 'assets/images/character/mascot_lv3.png';
    if (level >= 11) return 'assets/images/character/mascot_lv2.png';
    return 'assets/images/character/mascot.png';
  }

  static const String _mascotFallback = 'assets/images/character/mascot.png';

  /// 레벨대별 캐릭터 강조 색 — 회색 → 흰 → 탠 (5 단계).
  Color _colorForLevel(int level) {
    if (level >= 41) return FacingTokens.accent;
    if (level >= 31) return FacingTokens.accent;
    if (level >= 21) return FacingTokens.fg;
    if (level >= 11) return FacingTokens.fg;
    return FacingTokens.muted;
  }

  /// 레벨대별 격려 한 줄. 친근한 톤.
  String _captionForLevel(int level) {
    if (level <= 5) return '좋은 출발. 페이스 유지.';
    if (level <= 10) return '체력 쌓이는 중.';
    if (level <= 15) return '단단해지는 중.';
    if (level <= 20) return 'Discipline 진입.';
    if (level <= 30) return 'Obsession 시작.';
    if (level <= 40) return '베테랑.';
    return '경지에 올랐다.';
  }

  /// v1.22 rev6: 업적 등급별 XP 합산.
  int _computeAchievementXp(AchievementSnapshot snap) {
    if (snap.unlocked.isEmpty) return 0;
    final byCode = <String, AchievementCatalog>{
      for (final c in snap.catalog) c.code: c,
    };
    int total = 0;
    for (final code in snap.unlocked.keys) {
      final c = byCode[code];
      final xp = LevelSystem.rarityXp[c?.rarity ?? 'Common'] ?? 20;
      total += xp;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final num? n = p.gradeResult?['overall_number'] is num
        ? p.gradeResult!['overall_number'] as num
        : null;
    final tierNum = (n ?? 1).toInt();
    final achState = context.watch<AchievementState>();
    final achXp = _computeAchievementXp(achState.snapshot);
    final bd = LevelSystem.compute(
      totalSessions: totalSessions,
      currentStreakDays: currentStreakDays,
      tierNumber: tierNum,
      prCount: prCount,
      achievementXp: achXp,
    );
    final pct = (bd.progress * 100).round();
    final isMax = bd.level >= LevelSystem.maxLevel;
    final charColor = _colorForLevel(bd.level);

    return Container(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: Border.all(color: FacingTokens.border),
        borderRadius: BorderRadius.circular(FacingTokens.r3),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 좌측 절반 — 캐릭터 (카드 높이만큼 크게).
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: FacingTokens.accentSoft.withValues(
                    alpha: bd.level >= 8 ? 0.6 : 0.3,
                  ),
                  borderRadius: BorderRadius.circular(FacingTokens.r2),
                  border: Border.all(
                    color: charColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  _mascotForLevel(bd.level),
                  fit: BoxFit.cover,
                  // v1.22 rev6: lv2/lv3/4/5 자산 미존재 시 mascot.png 폴백.
                  errorBuilder: (_, _, _) => Image.asset(
                    _mascotFallback,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: FacingTokens.sp4),
            // 우측 절반 — LEVEL/캡션/progress/XP rows.
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LEVEL', style: FacingTokens.sectionLabel),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${bd.level}',
                        style: FacingTokens.displayCompact.copyWith(
                          color: FacingTokens.accent,
                        ),
                      ),
                      const SizedBox(width: FacingTokens.sp2),
                      Text(
                        '${bd.totalXp} XP',
                        style: FacingTokens.caption.copyWith(
                          fontFeatures: FacingTokens.tabular,
                          color: FacingTokens.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FacingTokens.sp2),
                  Text(
                    _captionForLevel(bd.level),
                    style: FacingTokens.caption.copyWith(
                      color: charColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: FacingTokens.sp2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(FacingTokens.r1),
                    child: Stack(
                      children: [
                        Container(height: 5, color: FacingTokens.border),
                        FractionallySizedBox(
                          widthFactor: bd.progress,
                          child: Container(
                              height: 5, color: FacingTokens.accent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: FacingTokens.sp1),
                  Text(
                    isMax
                        ? 'MAX LEVEL'
                        : '$pct% · next Lv${bd.level + 1} · ${bd.xpToNext} XP',
                    style: FacingTokens.micro,
                  ),
                  const SizedBox(height: FacingTokens.sp2),
                  _XpInline(label: 'Sessions', value: bd.sessionXp),
                  _XpInline(label: 'Streak', value: bd.streakXp),
                  _XpInline(label: 'Tier', value: bd.tierXp),
                  if (bd.prXp > 0) _XpInline(label: 'PRs', value: bd.prXp),
                  if (bd.achievementXp > 0)
                    _XpInline(
                        label: 'Achievements',
                        value: bd.achievementXp),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XpInline extends StatelessWidget {
  final String label;
  final int value;
  const _XpInline({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: FacingTokens.caption)),
          Text(
            '+$value',
            style: FacingTokens.caption.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: FacingTokens.tabular,
              color: FacingTokens.fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// MILESTONES 3종 요약 진행바 (Attendance / Sessions / Achievements).
class _ProgressStat extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value; // 0.0 ~ 1.0
  final String trailing;
  const _ProgressStat({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final done = value >= 1.0;
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
                  style: FacingTokens.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                trailing,
                style: FacingTokens.micro.copyWith(
                  color: done ? FacingTokens.accent : FacingTokens.muted,
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
                  widthFactor: value,
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

// v1.22 rev3: _WeekdayLabel / _DayCell 제거 — 캘린더가 Profile 로 이관됨.

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
                          ? '1 free / week. Saves this week\'s streak.'
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
