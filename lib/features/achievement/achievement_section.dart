import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/achievement.dart';
import 'achievement_card.dart';
import 'achievement_state.dart';
import 'achievements_screen.dart';

/// 업적 섹션 — 최근 해금 최대 6칸 고정 그리드.
/// 6개 초과 시 마지막 칸을 "+N more" 오버플로우 타일로 대체.
/// Locked 항목은 이 섹션에서 제거 → AchievementsScreen 전용.
class AchievementSection extends StatelessWidget {
  const AchievementSection({super.key});

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

  static Color _rarityColor(String rarity) {
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

  void _goAll(BuildContext context) {
    Haptic.light();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const AchievementsScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AchievementState>();
    final snap = state.snapshot;
    final totalVisible = snap.visibleCount;
    final unlockedCount = snap.unlockedCount;

    // 최근 해금 순 정렬
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

    // 6칸 고정: >6이면 5개 타일 + 오버플로우 타일
    const int kMax = 6;
    final bool hasOverflow = unlockedList.length > kMax;
    final displayItems =
        hasOverflow ? unlockedList.take(kMax - 1).toList() : unlockedList;
    final overflowCount = unlockedCount - (kMax - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 헤더
        Row(
          children: [
            const Expanded(
              child: Text('ACHIEVEMENTS', style: FacingTokens.sectionLabel),
            ),
            Text('$unlockedCount / $totalVisible', style: FacingTokens.caption),
            const SizedBox(width: FacingTokens.sp2),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: FacingTokens.accent,
                padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp2),
              ),
              onPressed: () => _goAll(context),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: FacingTokens.sp3),

        if (unlockedList.isEmpty)
          // 빈 상태 — 아직 해금 없음
          _EmptyState(onTap: () => _goAll(context))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: FacingTokens.sp2,
              mainAxisSpacing: FacingTokens.sp2,
              childAspectRatio: 0.92,
            ),
            itemCount: displayItems.length + (hasOverflow ? 1 : 0),
            itemBuilder: (_, i) {
              // 마지막 칸: 오버플로우
              if (hasOverflow && i == displayItems.length) {
                return _OverflowTile(
                  count: overflowCount,
                  onTap: () => _goAll(context),
                );
              }
              final c = displayItems[i];
              final rc = _rarityColor(c.rarity);
              return _GridTile(
                catalog: c,
                unlock: snap.unlocked[c.code],
                rarityColor: rc,
                icon: _iconFor(c.code),
                onTap: () => _showDetail(context, c, snap.unlocked[c.code]),
              );
            },
          ),
      ],
    );
  }
}

// ─── 빈 상태 ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp4),
        decoration: BoxDecoration(
          border: Border.all(color: FacingTokens.border, width: 0.8),
          borderRadius: BorderRadius.circular(FacingTokens.r2),
        ),
        child: Column(
          children: [
            Icon(Icons.military_tech_outlined,
                size: 28, color: FacingTokens.muted),
            const SizedBox(height: FacingTokens.sp2),
            Text(
              'No achievements yet.',
              style: FacingTokens.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              'Complete a WOD to start.',
              style: FacingTokens.micro,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 오버플로우 타일 (+N more) ──────────────────────────────────────────────

class _OverflowTile extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _OverflowTile({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FacingTokens.r2),
      child: Material(
        color: FacingTokens.surface,
        child: InkWell(
          onTap: onTap,
          splashColor: FacingTokens.accent.withValues(alpha: 0.12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: FacingTokens.border, width: 0.8),
              borderRadius: BorderRadius.circular(FacingTokens.r2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '+$count',
                  style: FacingTokens.h3.copyWith(
                    color: FacingTokens.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'more',
                  style: FacingTokens.micro.copyWith(
                    color: FacingTokens.muted,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 그리드 타일 ─────────────────────────────────────────────────────────────

class _GridTile extends StatelessWidget {
  final AchievementCatalog catalog;
  final AchievementUnlock? unlock;
  final Color rarityColor;
  final IconData icon;
  final VoidCallback onTap;

  const _GridTile({
    required this.catalog,
    required this.unlock,
    required this.rarityColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FacingTokens.r2),
      child: Material(
        color: rarityColor.withValues(alpha: 0.10),
        child: InkWell(
          onTap: onTap,
          splashColor: rarityColor.withValues(alpha: 0.20),
          highlightColor: rarityColor.withValues(alpha: 0.12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: rarityColor.withValues(alpha: 0.50), width: 1),
              borderRadius: BorderRadius.circular(FacingTokens.r2),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: FacingTokens.sp2,
              vertical: FacingTokens.sp3,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: rarityColor),
                const SizedBox(height: FacingTokens.sp1),
                Text(
                  AchievementCard.koreanTitle(catalog.code),
                  style: FacingTokens.micro.copyWith(
                    color: FacingTokens.fg,
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
    );
  }
}

// ─── 상세 바텀시트 ────────────────────────────────────────────────────────────

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
                          color: FacingTokens.fg,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(catalog.name, style: FacingTokens.caption),
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
                style: FacingTokens.caption.copyWith(color: FacingTokens.accent),
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
