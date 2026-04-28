import 'package:flutter/material.dart';

/// v1.15 halftone grain overlay.
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
    // QA B-PF-1: Opacity 위젯은 항상 별도 합성 레이어 → 큰 화면에 grain 깔면 비용 ↑.
    // ColorFiltered + modulate 로 알파만 곱해 레이어 1개 절감.
    // RepaintBoundary 로 grain 자체는 재합성 안 되도록 격리.
    return IgnorePointer(
      child: RepaintBoundary(
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            const Color(0xFFFFFFFF).withValues(alpha: opacity),
            BlendMode.modulate,
          ),
          child: Image.asset(
            asset,
            repeat: ImageRepeat.repeat,
            fit: BoxFit.none,
            filterQuality: FilterQuality.none,
          ),
        ),
      ),
    );
  }
}
