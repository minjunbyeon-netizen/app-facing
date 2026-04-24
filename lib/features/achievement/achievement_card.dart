import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/achievement.dart';

/// v1.16: Achievement 배지 카드. 텍스트 전용 · rarity 색 border만.
class AchievementCard extends StatelessWidget {
  final AchievementCatalog catalog;
  final AchievementUnlock? unlock; // null이면 미해금

  const AchievementCard({
    super.key,
    required this.catalog,
    this.unlock,
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
    final unlocked = unlock != null;
    final color = unlocked ? _rarityColor() : FacingTokens.border;
    return Container(
      margin: const EdgeInsets.only(bottom: FacingTokens.sp3),
      padding: const EdgeInsets.fromLTRB(
        FacingTokens.sp4, FacingTokens.sp3, FacingTokens.sp4, FacingTokens.sp3,
      ),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: Border(
          left: BorderSide(color: color, width: 3),
          top: BorderSide(color: FacingTokens.border, width: 1),
          right: BorderSide(color: FacingTokens.border, width: 1),
          bottom: BorderSide(color: FacingTokens.border, width: 1),
        ),
        borderRadius: BorderRadius.circular(FacingTokens.r2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  catalog.name,
                  style: FacingTokens.h3.copyWith(
                    color: unlocked ? FacingTokens.fg : FacingTokens.muted,
                  ),
                ),
              ),
              Text(
                catalog.rarity.toUpperCase(),
                style: FacingTokens.micro.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp1),
          Text(
            unlocked ? catalog.description : '· · ·',
            style: FacingTokens.caption,
          ),
          if (unlocked) ...[
            const SizedBox(height: FacingTokens.sp1),
            Text(
              _formatDate(unlock!.unlockedAt),
              style: FacingTokens.micro.copyWith(color: FacingTokens.muted),
            ),
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
