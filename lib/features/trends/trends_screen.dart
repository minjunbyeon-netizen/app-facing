import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/level_system.dart';
import '../../core/theme.dart';
import '../../models/achievement.dart';
import '../achievement/achievement_card.dart';
import '../achievement/achievement_state.dart';
import '../history/history_models.dart';
import '../history/history_repository.dart';
import '../profile/profile_state.dart';

/// v1.16: TRENDS = Achievement 갤러리 전용.
/// 점수·스파크라인·MOMENTUM은 Profile로 이관됨.
/// 15개 배지 (해금 + 미해금) 카드 리스트. 데모 해금 포함.
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  bool _showLocked = true;
  Future<List<WodHistoryItem>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AchievementState>().load();
    });
    final repo = HistoryRepository(context.read<ApiClient>());
    _historyFuture = repo.listWodHistory(limit: 200);
  }

  int _currentStreakDays(List<WodHistoryItem> list) {
    if (list.isEmpty) return 0;
    final days = <DateTime>{};
    for (final w in list) {
      final d = w.createdAt.toLocal();
      days.add(DateTime(d.year, d.month, d.day));
    }
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
    final state = context.watch<AchievementState>();
    final snap = state.snapshot;

    // 해금·미해금 분리. 데모 해금 포함.
    final unlocked = <AchievementCatalog>[];
    final locked = <AchievementCatalog>[];
    for (final c in snap.catalog) {
      if (state.isUnlockedInUi(c.code)) {
        unlocked.add(c);
      } else {
        locked.add(c);
      }
    }
    unlocked.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    locked.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      // v1.16 Sprint 9a: EARN으로 이름 변경 (Achievement 갤러리 의미 일치).
      appBar: AppBar(
        title: const Text('LEVEL & TITLES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AchievementState>().load(),
          ),
        ],
      ),
      body: SafeArea(
        child: state.isLoading && snap.catalog.isEmpty
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: FacingTokens.muted),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(FacingTokens.sp4),
                children: [
                  // v1.16 Sprint 14: LEVEL 카드 — Panel A 기조.
                  FutureBuilder<List<WodHistoryItem>>(
                    future: _historyFuture,
                    builder: (ctx, snap) {
                      // QA B-FB-3: 로딩 중에도 빈 배열로 처리되어 streak=0 표시되는 문제.
                      if (snap.connectionState != ConnectionState.done) {
                        return const SizedBox(height: 100);
                      }
                      final history = snap.data ?? const <WodHistoryItem>[];
                      final streak = _currentStreakDays(history);
                      final p = context.watch<ProfileState>();
                      final g = p.gradeResult;
                      final num? n = g?['overall_number'] is num
                          ? g!['overall_number'] as num
                          : null;
                      final tierNum = (n ?? 0).toInt();
                      final bd = LevelSystem.compute(
                        totalSessions: history.length,
                        currentStreakDays: streak,
                        tierNumber: tierNum,
                      );
                      return _LevelCard(bd: bd);
                    },
                  ),
                  const SizedBox(height: FacingTokens.sp4),
                  const Divider(height: 1, color: FacingTokens.border),
                  const SizedBox(height: FacingTokens.sp3),

                  // v1.16 Sprint 9a: Profile 점수·Radar 진입 브릿지.
                  InkWell(
                    onTap: () =>
                        Navigator.of(context).pushNamed('/mypage'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: FacingTokens.sp2),
                      child: Row(
                        children: [
                          const Icon(Icons.show_chart,
                              size: 18, color: FacingTokens.muted),
                          const SizedBox(width: FacingTokens.sp2),
                          const Expanded(
                            child: Text(
                              'Engine Score · Radar · 카테고리 추이는 Profile',
                              style: FacingTokens.caption,
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 16, color: FacingTokens.muted),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: FacingTokens.border),
                  const SizedBox(height: FacingTokens.sp3),

                  // Summary header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${unlocked.length}',
                          style: FacingTokens.displayCompact),
                      const SizedBox(width: FacingTokens.sp2),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '/ ${snap.catalog.length + _hiddenLockedCount(snap, state)} titles',
                          style: FacingTokens.caption,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FacingTokens.sp1),
                  const Text('TITLES UNLOCKED',
                      style: FacingTokens.sectionLabel),
                  const SizedBox(height: FacingTokens.sp5),

                  // Unlocked
                  if (unlocked.isEmpty) ...[
                    const Text('해금된 배지 없음. Engine 측정부터 시작.',
                        style: FacingTokens.caption),
                  ] else ...[
                    const Text('UNLOCKED', style: FacingTokens.sectionLabel),
                    const SizedBox(height: FacingTokens.sp2),
                    ...unlocked.map((c) => _BadgeCard(
                          catalog: c,
                          unlocked: true,
                          isDemo: AchievementState.demoUnlockedCodes
                              .contains(c.code),
                        )),
                  ],
                  const SizedBox(height: FacingTokens.sp5),

                  // Locked toggle + list
                  if (locked.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'LOCKED (${locked.length})',
                            style: FacingTokens.sectionLabel,
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: FacingTokens.muted,
                          ),
                          onPressed: () =>
                              setState(() => _showLocked = !_showLocked),
                          child: Text(_showLocked ? 'Hide' : 'Show'),
                        ),
                      ],
                    ),
                    if (_showLocked) ...[
                      const SizedBox(height: FacingTokens.sp2),
                      ...locked.map((c) => _BadgeCard(
                            catalog: c,
                            unlocked: false,
                          )),
                    ],
                  ],
                ],
              ),
      ),
    );
  }

  /// hidden 배지는 해금 전 catalog에서 제외되어 visible 카운트에 포함 안됨.
  /// 총합 카운트 보정 위해 대략 추가. 정확한 총 15개 고정값 노출해도 OK.
  int _hiddenLockedCount(AchievementSnapshot snap, AchievementState state) {
    // 총합 고정 15로 표기.
    final visibleTotal = snap.catalog.length;
    return (15 - visibleTotal).clamp(0, 15);
  }
}

/// v1.16 Sprint 14: Level 카드 — Panel A 스펙.
class _LevelCard extends StatelessWidget {
  final LevelXpBreakdown bd;
  const _LevelCard({required this.bd});

  @override
  Widget build(BuildContext context) {
    final pct = (bd.progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        borderRadius: BorderRadius.circular(FacingTokens.r3),
        border: Border.all(color: FacingTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('LEVEL ${bd.level}',
                  style: FacingTokens.h1.copyWith(
                    fontFeatures: FacingTokens.tabular,
                  )),
              const Spacer(),
              Text('${bd.totalXp} XP',
                  style: FacingTokens.body.copyWith(
                    fontFeatures: FacingTokens.tabular,
                    color: FacingTokens.muted,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: FacingTokens.sp2),
          ClipRRect(
            borderRadius: BorderRadius.circular(FacingTokens.r1),
            child: Stack(
              children: [
                Container(height: 8, color: FacingTokens.border),
                FractionallySizedBox(
                  widthFactor: bd.progress,
                  child: Container(height: 8, color: FacingTokens.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: FacingTokens.sp2),
          Text(
            bd.level >= LevelSystem.maxLevel
                ? 'MAX LEVEL'
                : '$pct% · next Lv${bd.level + 1} · ${bd.xpToNext} XP 남음',
            style: FacingTokens.caption,
          ),
          const SizedBox(height: FacingTokens.sp4),
          const Text('XP SOURCES', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          _XpLine(label: 'Sessions', value: bd.sessionXp),
          _XpLine(label: 'Streak', value: bd.streakXp),
          _XpLine(label: 'Tier', value: bd.tierXp),
          if (bd.weeklyXp > 0)
            _XpLine(label: 'Weekly Goals', value: bd.weeklyXp),
          const SizedBox(height: FacingTokens.sp2),
          Text(
            '* XP는 현재 세션·Streak·Tier로 파생 계산. PR·주간목표 자동 연동은 Phase 2.',
            style: FacingTokens.micro.copyWith(color: FacingTokens.muted),
          ),
        ],
      ),
    );
  }
}

class _XpLine extends StatelessWidget {
  final String label;
  final int value;
  const _XpLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: FacingTokens.caption)),
          Text('+$value',
              style: FacingTokens.caption.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: FacingTokens.tabular,
                color: FacingTokens.fg,
              )),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final AchievementCatalog catalog;
  final bool unlocked;
  final bool isDemo;

  const _BadgeCard({
    required this.catalog,
    required this.unlocked,
    this.isDemo = false,
  });

  Color _rarityColor() {
    switch (catalog.rarity) {
      case 'Rare':
        return FacingTokens.accent;
      case 'Epic':
        return FacingTokens.tierElite;
      case 'Legendary':
        return FacingTokens.tierGames;
      case 'Common':
      default:
        return FacingTokens.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? _rarityColor() : FacingTokens.border;
    return Container(
      margin: const EdgeInsets.only(bottom: FacingTokens.sp3),
      padding: const EdgeInsets.fromLTRB(
          FacingTokens.sp4, FacingTokens.sp3, FacingTokens.sp4, FacingTokens.sp3),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color, width: unlocked ? 3 : 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AchievementCard.koreanTitle(catalog.code),
                      style: FacingTokens.h3.copyWith(
                        color:
                            unlocked ? FacingTokens.fg : FacingTokens.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      catalog.name,
                      style: FacingTokens.micro.copyWith(
                        color: FacingTokens.muted,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                catalog.rarity.toUpperCase(),
                style: FacingTokens.micro.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp1),
          Text(
            unlocked
                ? catalog.description
                : (catalog.isHidden
                    ? '· · · (조건 공개 안 됨)'
                    : AchievementCard.triggerHint(catalog.code)),
            style: FacingTokens.caption,
          ),
          if (isDemo) ...[
            const SizedBox(height: FacingTokens.sp1),
            Text(
              'demo sample',
              style: FacingTokens.micro.copyWith(
                color: FacingTokens.muted,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
