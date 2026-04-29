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
import '../../widgets/inbox_bell.dart';
import '../achievement/achievement_section.dart';
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
    final totalLifetime = records.length;
    final currentStreak = _currentStreak();
    final longestStreak = _longestStreak();

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

  /// v1.22 rev4: 대표 캐릭터 (HYPHEN mascot).
  /// 단일 이미지 사용. 레벨대별 변화는 테두리/배경 강도로 표현.
  static const String _mascotAsset = 'assets/images/character/mascot.png';

  /// 레벨대별 캐릭터 강조 색 — 회색 → 흰 → 탠 (테두리/배경 그라데이션).
  Color _colorForLevel(int level) {
    if (level <= 7) return FacingTokens.muted;
    if (level <= 14) return FacingTokens.fg;
    return FacingTokens.accent;
  }

  /// 레벨대별 격려 한 줄. 친근한 톤.
  String _captionForLevel(int level) {
    if (level <= 3) return '좋은 출발. 페이스 유지.';
    if (level <= 7) return '체력 쌓이는 중.';
    if (level <= 11) return '단단해지는 중.';
    if (level <= 14) return 'Discipline 진입.';
    if (level <= 17) return 'Obsession 시작.';
    return '경지에 올랐다.';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final num? n = p.gradeResult?['overall_number'] is num
        ? p.gradeResult!['overall_number'] as num
        : null;
    final tierNum = (n ?? 1).toInt();
    final bd = LevelSystem.compute(
      totalSessions: totalSessions,
      currentStreakDays: currentStreakDays,
      tierNumber: tierNum,
      prCount: prCount,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 캐릭터 + LV 숫자 + XP
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 가상 캐릭터 — HYPHEN 대표 mascot.
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: FacingTokens.accentSoft.withValues(
                    alpha: bd.level >= 8 ? 1.0 : 0.4,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: charColor.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: Image.asset(
                  _mascotAsset,
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: FacingTokens.sp4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LEVEL',
                        style: FacingTokens.sectionLabel),
                    const SizedBox(height: 2),
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp3),
          // 격려 캡션 — 친근한 톤.
          Text(
            _captionForLevel(bd.level),
            style: FacingTokens.body.copyWith(
              color: charColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: FacingTokens.sp3),
          ClipRRect(
            borderRadius: BorderRadius.circular(FacingTokens.r1),
            child: Stack(
              children: [
                Container(height: 6, color: FacingTokens.border),
                FractionallySizedBox(
                  widthFactor: bd.progress,
                  child:
                      Container(height: 6, color: FacingTokens.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: FacingTokens.sp2),
          Text(
            isMax
                ? 'MAX LEVEL'
                : '$pct% · next Lv${bd.level + 1} · ${bd.xpToNext} XP',
            style: FacingTokens.caption,
          ),
          const SizedBox(height: FacingTokens.sp3),
          _XpInline(label: 'Sessions', value: bd.sessionXp),
          _XpInline(label: 'Streak', value: bd.streakXp),
          _XpInline(label: 'Tier', value: bd.tierXp),
          if (bd.prXp > 0) _XpInline(label: 'PRs', value: bd.prXp),
        ],
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
