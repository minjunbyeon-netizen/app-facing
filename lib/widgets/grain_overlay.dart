import 'package:flutter/material.dart';

/// v1.15 halftone grain overlay. VISUAL_CONCEPT.md §5.
///
/// 일상 배경: `GrainOverlay.subtle()` opacity 0.04
/// 드라마틱 순간: `GrainOverlay.strong()` opacity 0.12
///
/// 투명 PNG 텍스처를 ImageRepeat.repeat 로 타일링. IgnorePointer 필수.
class GrainOverlay extends StatelessWidget {
  final String asset;
  final double opacity;

  const GrainOverlay({
    super.key,
    required this.asset,
    required this.opacity,
  });

  const GrainOverlay.subtle({super.key})
      : asset = 'assets/textures/grain_subtle.png',
        opacity = 0.04;

  const GrainOverlay.strong({super.key})
      : asset = 'assets/textures/grain_strong.png',
        opacity = 0.12;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Image.asset(
          asset,
          repeat: ImageRepeat.repeat,
          fit: BoxFit.none,
          filterQuality: FilterQuality.none,
        ),
      ),
    );
  }
}
