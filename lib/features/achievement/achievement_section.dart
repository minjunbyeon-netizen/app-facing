import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/achievement.dart';
import 'achievement_card.dart';
import 'achievement_state.dart';
import 'achievements_screen.dart';

/// 업적 그리드 섹션 — 3열 배지 타일. 해금 먼저, 잠금 토글.
class AchievementSection extends StatefulWidget {
  const AchievementSection({super.key});

  @override
  State<AchievementSection> createState() => _AchievementSectionState();
}

class _AchievementSectionState extends State<AchievementSection> {
  bool _showLocked = false;

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
                padding: const EdgeInsets.symmetric(horizontal: FacingTokens.sp2),
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
          const Text('No catalog. Pull to refresh.', style: FacingTokens.caption)
        else ...[
          // 해금 그리드
          if (unlockedList.isNotEmpty)
            _buildGrid(unlockedList, snap, isUnlocked: true),

          // 잠금 토글
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
              _buildGrid(lockedList, snap, isUnlocked: false),
            ],
          ],
        ],
      ],
    );
  }

  Widget _buildGrid(
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
        childAspectRatio: 1.05,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final c = items[i];
        final rc = isUnlocked ? _rarityColor(c.rarity) : FacingTokens.border;
        return _GridTile(
          catalog: c,
          rarityColor: rc,
          isUnlocked: isUnlocked,
        );
      },
    );
  }
}

class _GridTile extends StatelessWidget {
  final AchievementCatalog catalog;
  final Color rarityColor;
  final bool isUnlocked;

  const _GridTile({
    required this.catalog,
    required this.rarityColor,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.38,
      child: Container(
        decoration: BoxDecoration(
          color: FacingTokens.surface,
          border: Border(
            left: BorderSide(color: rarityColor, width: isUnlocked ? 2.5 : 1),
            top: BorderSide(color: FacingTokens.border, width: 1),
            right: BorderSide(color: FacingTokens.border, width: 1),
            bottom: BorderSide(color: FacingTokens.border, width: 1),
          ),
          borderRadius: BorderRadius.circular(FacingTokens.r2),
        ),
        padding: const EdgeInsets.all(FacingTokens.sp2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AchievementCard.koreanTitle(catalog.code),
              style: FacingTokens.micro.copyWith(
                color: isUnlocked ? FacingTokens.fg : FacingTokens.muted,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              catalog.rarity.toUpperCase(),
              style: FacingTokens.micro.copyWith(
                color: rarityColor,
                fontSize: 9,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
