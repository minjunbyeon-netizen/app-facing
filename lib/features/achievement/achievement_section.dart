import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/achievement.dart';
import 'achievement_card.dart';
import 'achievement_state.dart';
import 'achievements_screen.dart';

/// 업적 그리드 섹션 — 픽토그램 아이콘 + InkWell + 바텀시트 상세.
class AchievementSection extends StatefulWidget {
  const AchievementSection({super.key});

  @override
  State<AchievementSection> createState() => _AchievementSectionState();
}

class _AchievementSectionState extends State<AchievementSection> {
  bool _showLocked = false;

  // 코드 접두사/정확 매핑 → 픽토그램 아이콘
  static IconData _iconFor(String code) {
    if (code == 'FIRST_ENGINE') return Icons.bolt_outlined;
    if (code == 'ALL_CAT_80') return Icons.all_inclusive_outlined;
    if (code == 'WOD_50') return Icons.fitness_center_outlined;
    if (code.startsWith('REACH_')) return Icons.military_tech_outlined;
    if (code.startsWith('SCORE_')) return Icons.analytics_outlined;
    if (code.startsWith('STREAK_')) return Icons.local_fire_department_outlined;
    if (code.startsWith('GIRLS_')) return Icons.emoji_events_outlined;
    if (code.startsWith('HEROES_')) return Icons.shield_outlined;
    if (code.startsWith('GAMES_')) return Icons.sports_score_outlined;
    if (code.startsWith('TITLE_')) return Icons.workspace_premium_outlined;
    if (code.startsWith('SEASON_')) return Icons.wb_sunny_outlined;
    if (code.startsWith('EGG_')) return Icons.auto_awesome_outlined;
    if (code.startsWith('PR_')) return Icons.trending_up_outlined;
    if (code.startsWith('VOL_')) return Icons.bar_chart_outlined;
    return Icons.star_outline;
  }

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'Rare':
        return FacingTokens.accent;
      case 'Epic':
        return FacingTokens.tierElite;
      case 'Legendary':
        return FacingTokens.tierGames;
      default:
        return FacingTokens.muted;
    }
  }

  void _showDetail(
    BuildContext context,
    AchievementCatalog catalog,
    AchievementUnlock? unlock,
  ) {
    Haptic.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: FacingTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(FacingTokens.r3)),
      ),
      builder: (_) => _DetailSheet(
        catalog: catalog,
        unlock: unlock,
        icon: _iconFor(catalog.code),
        rarityColor: _rarityColor(catalog.rarity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AchievementState>();
    final snap = state.snapshot;
    final total = snap.visibleCount;
    final unlocked = snap.unlockedCount;

    final unlockedList = snap.catalog
        .where((c) => snap.isUnlocked(c.code))
        .toList()
      ..sort((a, b) {
        final ua = snap.unlocked[a.code]?.unlockedAt;
        final ub = snap.unlocked[b.code]?.unlockedAt;
        if (ua == null && ub == null) return 0;
        if (ua == null) return 1;
        if (ub == null) return -1;
        return ub.compareTo(ua);
      });

    final lockedList = snap.catalog
        .where((c) => !snap.isUnlocked(c.code))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 헤더
        Row(
          children: [
            const Expanded(
              child: Text('ACHIEVEMENTS', style: FacingTokens.sectionLabel),
            ),
            Text('$unlocked / $total', style: FacingTokens.caption),
            const SizedBox(width: FacingTokens.sp2),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: FacingTokens.accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: FacingTokens.sp2),
              ),
              onPressed: () {
                Haptic.light();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AchievementsScreen(),
                ));
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: FacingTokens.sp3),

        if (snap.catalog.isEmpty)
          const Text('No catalog. Pull to refresh.',
              style: FacingTokens.caption)
        else ...[
          if (unlockedList.isNotEmpty)
            _buildGrid(context, unlockedList, snap, isUnlocked: true),

          if (lockedList.isNotEmpty) ...[
            const SizedBox(height: FacingTokens.sp2),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: FacingTokens.muted,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                Haptic.light();
                setState(() => _showLocked = !_showLocked);
              },
              child: Text(
                _showLocked
                    ? 'Hide locked'
                    : 'Show locked (${lockedList.length})',
              ),
            ),
            if (_showLocked) ...[
              const SizedBox(height: FacingTokens.sp2),
              _buildGrid(context, lockedList, snap, isUnlocked: false),
            ],
          ],
        ],
      ],
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<AchievementCatalog> items,
    AchievementSnapshot snap, {
    required bool isUnlocked,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: FacingTokens.sp2,
        mainAxisSpacing: FacingTokens.sp2,
        childAspectRatio: 0.92,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final c = items[i];
        final rc = isUnlocked ? _rarityColor(c.rarity) : FacingTokens.border;
        return _GridTile(
          catalog: c,
          unlock: isUnlocked ? snap.unlocked[c.code] : null,
          rarityColor: rc,
          icon: _iconFor(c.code),
          isUnlocked: isUnlocked,
          onTap: () => _showDetail(context, c, snap.unlocked[c.code]),
        );
      },
    );
  }
}

// ─── 그리드 타일 ────────────────────────────────────────────────────────────

class _GridTile extends StatelessWidget {
  final AchievementCatalog catalog;
  final AchievementUnlock? unlock;
  final Color rarityColor;
  final IconData icon;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _GridTile({
    required this.catalog,
    required this.unlock,
    required this.rarityColor,
    required this.icon,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.40,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FacingTokens.r2),
        child: Material(
          color: FacingTokens.surface,
          child: InkWell(
            onTap: onTap,
            splashColor: rarityColor.withValues(alpha: 0.15),
            highlightColor: rarityColor.withValues(alpha: 0.08),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                      color: rarityColor, width: isUnlocked ? 2.5 : 1),
                  top: const BorderSide(color: FacingTokens.border, width: 1),
                  right:
                      const BorderSide(color: FacingTokens.border, width: 1),
                  bottom:
                      const BorderSide(color: FacingTokens.border, width: 1),
                ),
                borderRadius: BorderRadius.circular(FacingTokens.r2),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: FacingTokens.sp2,
                vertical: FacingTokens.sp3,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 26,
                    color: isUnlocked ? rarityColor : FacingTokens.muted,
                  ),
                  const SizedBox(height: FacingTokens.sp1),
                  Text(
                    AchievementCard.koreanTitle(catalog.code),
                    style: FacingTokens.micro.copyWith(
                      color:
                          isUnlocked ? FacingTokens.fg : FacingTokens.muted,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    catalog.rarity.toUpperCase(),
                    style: FacingTokens.micro.copyWith(
                      color: rarityColor,
                      fontSize: 9,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 상세 바텀시트 ───────────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final AchievementCatalog catalog;
  final AchievementUnlock? unlock;
  final IconData icon;
  final Color rarityColor;

  const _DetailSheet({
    required this.catalog,
    required this.unlock,
    required this.icon,
    required this.rarityColor,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = unlock != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FacingTokens.sp5,
          FacingTokens.sp4,
          FacingTokens.sp5,
          FacingTokens.sp5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: FacingTokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: FacingTokens.sp4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(FacingTokens.r2),
                    border: Border.all(color: rarityColor, width: 1.5),
                  ),
                  child: Icon(icon, size: 28, color: rarityColor),
                ),
                const SizedBox(width: FacingTokens.sp3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AchievementCard.koreanTitle(catalog.code),
                        style: FacingTokens.h3.copyWith(
                          color: isUnlocked
                              ? FacingTokens.fg
                              : FacingTokens.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        catalog.name,
                        style: FacingTokens.caption,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: FacingTokens.sp2, vertical: 4),
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(FacingTokens.r1),
                  ),
                  child: Text(
                    catalog.rarity.toUpperCase(),
                    style: FacingTokens.micro.copyWith(
                      color: rarityColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: FacingTokens.sp4),
            Container(height: 1, color: FacingTokens.border),
            const SizedBox(height: FacingTokens.sp4),
            Text(
              isUnlocked ? catalog.description : _hint(),
              style: FacingTokens.body,
            ),
            if (isUnlocked) ...[
              const SizedBox(height: FacingTokens.sp3),
              Text(
                'Unlocked ${_fmt(unlock!.unlockedAt)}',
                style: FacingTokens.caption
                    .copyWith(color: FacingTokens.accent),
              ),
            ],
            const SizedBox(height: FacingTokens.sp2),
          ],
        ),
      ),
    );
  }

  String _hint() => catalog.isHidden
      ? '· · · (조건 공개 안 됨)'
      : AchievementCard.triggerHint(catalog.code);

  String _fmt(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-'
        '${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')}';
  }
}
