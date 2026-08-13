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
        return HyphenTokens.accent;
      case 'Epic':
        return HyphenTokens.tierElite;
      case 'Legendary':
        return HyphenTokens.tierGames;
      case 'Common':
      default:
        return HyphenTokens.muted;
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
      // v1.19+ reference/gamification.md §6-3 (HWPO 톤, 조용한 만족감).
      // Common/Rare = light haptic 1회 (조용)
      // Epic/Legendary = light + heavy 80ms (강조) + confetti
      final isEmphasize = u.rarity == 'Epic' || u.rarity == 'Legendary';
      // unawaited — toast 와 동시 진행.
      Haptic.achievementUnlock(emphasize: isEmphasize);
      if (isEmphasize) {
        ConfettiOverlay.burst(context, rarity: u.rarity);
      }
      messenger.showSnackBar(SnackBar(
        // v1.19+ duration 3s → 2s (reference §6-3: 짧게)
        duration: const Duration(seconds: 2),
        backgroundColor: HyphenTokens.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
          side: BorderSide(color: color, width: 2),
        ),
        content: Row(
          children: [
            Container(width: 4, height: 20, color: color),
            const SizedBox(width: HyphenTokens.sp3),
            Expanded(
              child: Text(
                // v1.19+ "Earned." 간결화. 영문 마침표 1개.
                '${u.name} Earned.',
                style: HyphenTokens.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              u.rarity.toUpperCase(),
              style: HyphenTokens.micro.copyWith(
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
