import 'package:flutter/material.dart';

import '../core/theme.dart';

/// HYPHEN 브랜드 로고 — 사용자 제공 원본(2026-07-28, docs/brand/hyphen-logo-source.png)을
/// 코드로 재현한 워드마크. 사진 목업 대신 벡터 렌더라 어떤 배경·크기에서도 선명하고
/// 테마 색을 따른다. 모티프 = 바벨/스카이라인 바 클러스터 + 수평 라인, 아래 HYPHEN.
class BrandLogo extends StatelessWidget {
  final double width;
  final Color color;
  const BrandLogo({super.key, this.width = 220, this.color = FacingTokens.fg});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(width, width * 0.17),
          painter: _MotifPainter(color),
        ),
        SizedBox(height: width * 0.055),
        Text(
          'HYPHEN',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: FacingTokens.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: width * 0.155,
            letterSpacing: width * 0.040,
            height: 1.0,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// 수평 라인 + 양끝 대칭 바 클러스터 (원본 로고 상단 모티프).
class _MotifPainter extends CustomPainter {
  final Color color;
  const _MotifPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final t = (w * 0.018).clamp(2.0, 6.0); // 획 두께
    final baseline = h; // 모티프 하단이 기준선

    // 수평 라인 (전체 폭)
    canvas.drawRect(
        Rect.fromLTWH(0, baseline - t, w, t), paint);

    // 바 클러스터 — 바깥→안쪽 [낮음, 최고, 중간, 낮음] 높이 비율. 좌우 대칭.
    const fracs = [0.0, 0.035, 0.07, 0.105];
    const heights = [0.38, 1.0, 0.62, 0.30];
    for (var i = 0; i < fracs.length; i++) {
      final bh = (h - t) * heights[i];
      // 좌측
      canvas.drawRect(
          Rect.fromLTWH(w * fracs[i], baseline - t - bh, t, bh), paint);
      // 우측 (미러)
      canvas.drawRect(
          Rect.fromLTWH(w - w * fracs[i] - t, baseline - t - bh, t, bh),
          paint);
    }
  }

  @override
  bool shouldRepaint(_MotifPainter old) => old.color != color;
}
