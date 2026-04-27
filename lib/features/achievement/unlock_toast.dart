import 'package:flutter/material.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/achievement.dart';
import 'confetti_overlay.dart';

/// v1.16: unlock 순간 알림. 3초 자동 소멸, 이모지 없음.
/// 여러 건이면 스택 (위에서 아래로 0.5초 간격).
class UnlockToast {
  UnlockToast._();

  static Color _rarityColor(String rarity) {
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

  /// 여러 해금 건을 순차로 showSnackBar.
  static Future<void> showAll(
    BuildContext context,
    List<AchievementUnlockResult> unlocks,
  ) async {
    if (unlocks.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    for (int i = 0; i < unlocks.length; i++) {
      if (!context.mounted) return;
      final u = unlocks[i];
      final color = _rarityColor(u.rarity);
      // v1.17 Sprint 18 (Plan D): heavyImpact + confetti.
      // Epic/Legendary 등급에만 confetti 발사 (Common/Rare 은 toast + heavy haptic).
      Haptic.heavy();
      if (u.rarity == 'Epic' || u.rarity == 'Legendary') {
        // unawaited — toast 와 동시 진행.
        ConfettiOverlay.burst(context, rarity: u.rarity);
      }
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 3),
        backgroundColor: FacingTokens.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FacingTokens.r2),
          side: BorderSide(color: color, width: 2),
        ),
        content: Row(
          children: [
            Container(width: 4, height: 20, color: color),
            const SizedBox(width: FacingTokens.sp3),
            Expanded(
              child: Text(
                '${u.name} Unlocked.',
                style: FacingTokens.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              u.rarity.toUpperCase(),
              style: FacingTokens.micro.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ));
      if (i < unlocks.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }
}
