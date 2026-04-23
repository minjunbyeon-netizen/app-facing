import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/tier.dart';

/// CrossFit Tier 라벨 배지. v1.13부터 fill 방식 — tier 색 배경 + 대비 텍스트.
class TierBadge extends StatelessWidget {
  final Tier tier;
  final double fontSize;
  const TierBadge({super.key, required this.tier, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize <= 12 ? 8 : 12,
        vertical: fontSize <= 12 ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: tier.color,
        borderRadius: BorderRadius.circular(FacingTokens.r2),
      ),
      child: Text(
        tier.label,
        style: FacingTokens.tierLabel.copyWith(
          color: tier.textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
