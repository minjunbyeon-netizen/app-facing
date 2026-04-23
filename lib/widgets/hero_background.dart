import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'grain_overlay.dart';

/// v1.15 HeroBackground — 화면 배경에 흑백 hero 이미지 + 하단 그라디언트 + halftone.
///
/// 구성 (Stack 아래→위):
///  1. hero jpg (cover fit)
///  2. 하단→중간 어두움 gradient (본문 가독성)
///  3. halftone grain overlay
///
/// child 는 gradient 위에 그려짐. Scaffold body 최상단에서 Stack으로 감싸 사용.
class HeroBackground extends StatelessWidget {
  final String imageAsset;
  final Widget child;
  final bool strongGrain;
  final Alignment imageAlignment;
  final double darkenStrength;

  const HeroBackground({
    super.key,
    required this.imageAsset,
    required this.child,
    this.strongGrain = false,
    this.imageAlignment = Alignment.center,
    this.darkenStrength = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. hero image
        Image.asset(
          imageAsset,
          fit: BoxFit.cover,
          alignment: imageAlignment,
        ),
        // 2. 하단으로 갈수록 어두워지는 gradient (읽기 레이어)
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                FacingTokens.bg.withValues(alpha: 0.25),
                FacingTokens.bg.withValues(alpha: darkenStrength),
                FacingTokens.bg.withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        // 3. halftone grain
        if (strongGrain) const GrainOverlay.strong() else const GrainOverlay.subtle(),
        // 4. content
        child,
      ],
    );
  }
}
