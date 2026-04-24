import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/tier.dart';

/// CrossFit Tier 라벨 배지. v1.15.3: 배경 pill 제거 — tier 색 텍스트만.
class TierBadge extends StatelessWidget {
  final Tier tier;
  final double fontSize;
  const TierBadge({super.key, required this.tier, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    // v1.15 P1-3: Semantics — 스크린리더 "Tier: ELITE" 형식 안내.
    return Semantics(
      label: 'Tier ${tier.label}',
      child: Text(
        tier.label,
        style: FacingTokens.tierLabel.copyWith(
          color: tier.color,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
