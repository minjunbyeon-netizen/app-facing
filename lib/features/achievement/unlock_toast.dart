import 'package:flutter/material.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/achievement.dart';
import '../../widgets/mascot.dart';
import 'confetti_overlay.dart';

/// v1.16: unlock 순간 알림. 이모지 없음. 여러 건이면 스택 (0.5초 간격).
/// v3.3 (2026-08-20 사용자 지시): 모든 해금에 기본 픽토그램 + 컨페티 캐논,
/// 노출 2초.
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
      // v3.3 (2026-08-20 사용자 지시): 등급 무관 모든 해금에 컨페티 캐논.
      // haptic 강조는 Epic/Legendary 유지 (§6-3 톤).
      final isEmphasize = u.rarity == 'Epic' || u.rarity == 'Legendary';
      // unawaited — toast 와 동시 진행.
      Haptic.achievementUnlock(emphasize: isEmphasize);
      ConfettiOverlay.burst(context, rarity: u.rarity);
      messenger.showSnackBar(SnackBar(
        // 노출 2초 (2026-08-20 사용자 지정).
        duration: const Duration(seconds: 2),
        backgroundColor: HyphenTokens.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HyphenTokens.r2),
          side: BorderSide(color: color, width: 2),
        ),
        content: Row(
          children: [
            // 2026-08-21 — 캐릭터 슬롯. 축하 마스코트가 준비되면 그걸 쓰고,
            // 아직이면 기존 트로피 배지를 그대로 쓴다 (경로 판단은 SSOT 한 곳).
            if (HyphenMascot.has(MascotMood.celebrate))
              const HyphenMascot(mood: MascotMood.celebrate, size: 32)
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(HyphenTokens.r1),
                ),
                child:
                    Icon(Icons.emoji_events_outlined, size: 18, color: color),
              ),
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
