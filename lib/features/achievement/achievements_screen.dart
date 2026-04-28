// v1.17 Sprint 18: Achievements grid screen — FIFA-style 3x3 + featured panel.
//
// 레이아웃 차용 (FIFA Online):
//  - 좌측 대형 featured 배지 + 한글/영문 라벨 + 조건/날짜
//  - 우측 3열 grid 카드 (체크 / 진행 / 잠금)
//  - 카테고리 필터 chip row
//
// 비주얼 톤 (facing 흑백·Obsession):
//  - surface #141414 카드 + border 1px
//  - 단색 outline 아이콘 (Material Icons.outlined)
//  - 완료 체크 = success #22C55E, locked 카드 opacity 0.35
//  - rarity 4-tier 컬러 thin bar (Common=muted, Rare=accent, Epic=tierElite, Legendary=tierGames)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/achievement.dart';
import 'achievement_card.dart';
import 'achievement_state.dart';
import 'panel_b_screen.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _filter = 'ALL';
  String? _featuredCode;

  static const List<(String, String)> _filters = [
    ('ALL', 'All'),
    ('TIER', 'Tier'),
    ('STREAK', 'Streak'),
    ('PR', 'PR'),
    ('SEASON', 'Season'),
    ('VOLUME', 'Volume'),
    ('EASTER', 'Hidden'),
  ];

  static String _category(String code) {
    if (code.startsWith('REACH_') || code == 'TITLE_POLYMATH') return 'TIER';
    if (code.startsWith('STREAK_') ||
        code == 'TITLE_OBSESSED' ||
        code == 'TITLE_RELENTLESS') {
      return 'STREAK';
    }
    if (code.startsWith('PR_')) return 'PR';
    if (code.startsWith('SEASON_')) return 'SEASON';
    if (code.startsWith('EGG_')) return 'EASTER';
    if (code.startsWith('VOL_') ||
        code == 'WOD_50' ||
        code == 'TITLE_UNDEFEATED') {
      return 'VOLUME';
    }
    if (code.startsWith('GIRLS_') ||
        code.startsWith('HEROES_') ||
        code == 'GAMES_1') {
      return 'VOLUME';
    }
    return 'TIER';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AchievementState>();
    final snap = state.snapshot;
    final all = snap.catalog;
    final filtered = _filter == 'ALL'
        ? all
        : all.where((c) => _category(c.code) == _filter).toList();
    final unlockedCount =
        all.where((c) => state.isUnlockedInUi(c.code)).length;
    final totalCount = all.length;

    // featured: 명시 선택 → 없으면 첫 잠금해제 → 없으면 첫 카탈로그.
    AchievementCatalog featured = const AchievementCatalog(
      code: '',
      name: '',
      description: '',
      rarity: 'Common',
      isHidden: false,
      sortOrder: 0,
    );
    if (_featuredCode != null) {
      for (final c in all) {
        if (c.code == _featuredCode) {
          featured = c;
          break;
        }
      }
    }
    if (featured.code.isEmpty && all.isNotEmpty) {
      featured = all.firstWhere(
        (c) => state.isUnlockedInUi(c.code),
        orElse: () => all.first,
      );
    }

    // /go 전수조사: 로딩/에러 분기 — 이전엔 빈 catalog 로 stats '0/0' 표시되어
    // 사용자가 '업적 없음' 으로 오해.
    final isLoading = state.isLoading && all.isEmpty;
    final hasError = state.error != null && all.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ACHIEVEMENTS'),
        actions: [
          // v1.20 Phase 2.5: Panel B 20-title 진입.
          IconButton(
            tooltip: 'Panel B Titles',
            icon: const Icon(Icons.workspace_premium_outlined, size: 20),
            onPressed: () => openPanelB(context),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: FacingTokens.muted),
                ),
              )
            : hasError
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(FacingTokens.sp5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('업적 로딩 실패',
                              style: FacingTokens.sectionLabel),
                          const SizedBox(height: FacingTokens.sp2),
                          Text(state.error!, style: FacingTokens.caption),
                          const SizedBox(height: FacingTokens.sp3),
                          OutlinedButton(
                            onPressed: () => state.load(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
          children: [
            _StatsHeader(unlocked: unlockedCount, total: totalCount),
            _FilterRow(
              current: _filter,
              filters: _filters,
              onTap: (v) {
                Haptic.selection();
                setState(() => _filter = v);
              },
            ),
            const Divider(height: 1, color: FacingTokens.border),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('No achievements yet.',
                          style: FacingTokens.caption),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: featured.code.isEmpty
                              ? const SizedBox.shrink()
                              : _FeaturedPanel(
                                  catalog: featured,
                                  unlock: snap.unlocked[featured.code],
                                  unlockedInUi:
                                      state.isUnlockedInUi(featured.code),
                                ),
                        ),
                        const VerticalDivider(
                            width: 1, color: FacingTokens.border),
                        Expanded(
                          flex: 7,
                          child: _Grid(
                            items: filtered,
                            state: state,
                            featuredCode: featured.code,
                            onTap: (code) {
                              Haptic.light();
                              setState(() => _featuredCode = code);
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final int unlocked;
  final int total;
  const _StatsHeader({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (unlocked / total).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FacingTokens.sp4,
        FacingTokens.sp3,
        FacingTokens.sp4,
        FacingTokens.sp2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$unlocked', style: FacingTokens.h1),
              const SizedBox(width: FacingTokens.sp1),
              Text('/ $total',
                  style: FacingTokens.h3.copyWith(color: FacingTokens.muted)),
              const Spacer(),
              Text(
                '${(pct * 100).toInt()}%',
                style: FacingTokens.h3.copyWith(
                  fontFeatures: FacingTokens.tabular,
                  color: FacingTokens.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp1),
          Text('UNLOCKED', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          ClipRRect(
            borderRadius: BorderRadius.circular(FacingTokens.r1),
            child: Stack(children: [
              Container(height: 4, color: FacingTokens.border),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(height: 4, color: FacingTokens.accent),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String current;
  final List<(String, String)> filters;
  final void Function(String) onTap;
  const _FilterRow({
    required this.current,
    required this.filters,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: FacingTokens.sp4,
          vertical: FacingTokens.sp2,
        ),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: FacingTokens.sp2),
        itemBuilder: (ctx, i) {
          final (code, label) = filters[i];
          final selected = current == code;
          return InkWell(
            onTap: () => onTap(code),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FacingTokens.sp3,
                vertical: FacingTokens.sp1,
              ),
              decoration: BoxDecoration(
                color: selected ? FacingTokens.fg : Colors.transparent,
                border: Border.all(
                  color: selected ? FacingTokens.fg : FacingTokens.border,
                ),
                borderRadius: BorderRadius.circular(FacingTokens.r2),
              ),
              alignment: Alignment.center,
              child: Text(
                label.toUpperCase(),
                style: FacingTokens.micro.copyWith(
                  color: selected ? FacingTokens.bg : FacingTokens.muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedPanel extends StatelessWidget {
  final AchievementCatalog catalog;
  final AchievementUnlock? unlock;
  final bool unlockedInUi;
  const _FeaturedPanel({
    required this.catalog,
    required this.unlock,
    required this.unlockedInUi,
  });

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(catalog.rarity);
    final isHidden = catalog.isHidden && !unlockedInUi;
    final iconData = _AchievementIcon.iconFor(catalog.code, isHidden);
    return Padding(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: FacingTokens.surface,
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(FacingTokens.r3),
            ),
            padding: const EdgeInsets.all(FacingTokens.sp5),
            child: Center(
              child: Opacity(
                opacity: unlockedInUi ? 1.0 : 0.45,
                child: Icon(
                  iconData,
                  size: 96,
                  color: unlockedInUi ? FacingTokens.fg : FacingTokens.muted,
                ),
              ),
            ),
          ),
          const SizedBox(height: FacingTokens.sp3),
          Text(
            catalog.rarity.toUpperCase(),
            style: FacingTokens.micro.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: FacingTokens.sp1),
          Text(
            isHidden ? '???' : catalog.name,
            style: FacingTokens.h2.copyWith(
              color: unlockedInUi ? FacingTokens.fg : FacingTokens.muted,
            ),
          ),
          if (!isHidden) ...[
            const SizedBox(height: FacingTokens.sp1),
            Text(
              AchievementCard.koreanTitle(catalog.code),
              style: FacingTokens.body.copyWith(
                color: FacingTokens.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: FacingTokens.sp3),
          Text(
            isHidden
                ? '· · · 조건 비공개. 해금 후 공개.'
                : (unlockedInUi
                    ? catalog.description
                    : AchievementCard.triggerHint(catalog.code)),
            style: FacingTokens.caption,
          ),
          const Spacer(),
          if (unlockedInUi && unlock != null) ...[
            const Divider(height: 1, color: FacingTokens.border),
            const SizedBox(height: FacingTokens.sp2),
            Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 14, color: FacingTokens.success),
                const SizedBox(width: FacingTokens.sp1),
                Text(
                  'Earned · ${_formatDate(unlock!.unlockedAt)}',
                  style: FacingTokens.micro.copyWith(
                    color: FacingTokens.success,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ] else if (unlockedInUi) ...[
            // demoUnlocked (백엔드 trigger 미연동) — 'Demo' 표시.
            const Divider(height: 1, color: FacingTokens.border),
            const SizedBox(height: FacingTokens.sp2),
            Text('Demo unlocked.',
                style: FacingTokens.micro.copyWith(
                  color: FacingTokens.muted,
                  letterSpacing: 0.6,
                )),
          ] else ...[
            const Divider(height: 1, color: FacingTokens.border),
            const SizedBox(height: FacingTokens.sp2),
            Text('LOCKED',
                style: FacingTokens.micro.copyWith(
                  color: FacingTokens.muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                )),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
  }
}

class _Grid extends StatelessWidget {
  final List<AchievementCatalog> items;
  final AchievementState state;
  final String? featuredCode;
  final void Function(String) onTap;
  const _Grid({
    required this.items,
    required this.state,
    required this.featuredCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(FacingTokens.sp3),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: FacingTokens.sp2,
        crossAxisSpacing: FacingTokens.sp2,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final c = items[i];
        final unlocked = state.isUnlockedInUi(c.code);
        final selected = c.code == featuredCode;
        return _GridCell(
          catalog: c,
          unlocked: unlocked,
          selected: selected,
          onTap: () => onTap(c.code),
        );
      },
    );
  }
}

class _GridCell extends StatelessWidget {
  final AchievementCatalog catalog;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;
  const _GridCell({
    required this.catalog,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(catalog.rarity);
    final isHidden = catalog.isHidden && !unlocked;
    final iconData = _AchievementIcon.iconFor(catalog.code, isHidden);
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: FacingTokens.surface,
          border: Border.all(
            color: selected ? FacingTokens.fg : FacingTokens.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(FacingTokens.r2),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Opacity(
                      opacity: unlocked ? 1.0 : 0.32,
                      child: Icon(
                        iconData,
                        size: 36,
                        color:
                            unlocked ? FacingTokens.fg : FacingTokens.muted,
                      ),
                    ),
                  ),
                  if (unlocked)
                    const Positioned(
                      right: 4,
                      top: 4,
                      child: Icon(Icons.check_circle,
                          size: 14, color: FacingTokens.success),
                    ),
                ],
              ),
            ),
            Container(height: 2, color: color),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FacingTokens.sp1,
                vertical: FacingTokens.sp1,
              ),
              child: Text(
                isHidden ? '???' : catalog.name.toUpperCase(),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: FacingTokens.micro.copyWith(
                  color: unlocked ? FacingTokens.fg : FacingTokens.muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _rarityColor(String rarity) {
  switch (rarity) {
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

/// 코드 prefix → outline 아이콘 매핑.
class _AchievementIcon {
  _AchievementIcon._();

  static IconData iconFor(String code, bool hidden) {
    if (hidden) return Icons.help_outline;
    if (code.startsWith('REACH_') || code == 'TITLE_POLYMATH') {
      return Icons.military_tech_outlined;
    }
    if (code.startsWith('STREAK_') ||
        code == 'TITLE_OBSESSED' ||
        code == 'TITLE_RELENTLESS') {
      return Icons.local_fire_department_outlined;
    }
    if (code.startsWith('PR_')) return Icons.trending_up_outlined;
    if (code == 'SEASON_SPRING') return Icons.eco_outlined;
    if (code == 'SEASON_SUMMER') return Icons.wb_sunny_outlined;
    if (code == 'SEASON_FALL') return Icons.park_outlined;
    if (code == 'SEASON_WINTER') return Icons.ac_unit_outlined;
    if (code == 'SEASON_YEAREND') return Icons.celebration_outlined;
    if (code.startsWith('EGG_')) return Icons.auto_awesome_outlined;
    if (code.startsWith('VOL_')) return Icons.fitness_center_outlined;
    if (code == 'VOL_COMEBACK') return Icons.replay_outlined;
    if (code.startsWith('GIRLS_')) return Icons.female_outlined;
    if (code.startsWith('HEROES_')) return Icons.star_outline;
    if (code == 'GAMES_1') return Icons.sports_score_outlined;
    if (code.startsWith('SCORE_')) return Icons.speed_outlined;
    if (code == 'ALL_CAT_80') return Icons.donut_large_outlined;
    if (code == 'WOD_50') return Icons.fitness_center_outlined;
    if (code == 'FIRST_ENGINE') return Icons.bolt_outlined;
    if (code == 'TITLE_SCHOLAR') return Icons.science_outlined;
    if (code == 'TITLE_UNDEFEATED') return Icons.shield_outlined;
    return Icons.emoji_events_outlined;
  }
}
