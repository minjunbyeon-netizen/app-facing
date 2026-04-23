import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/tier.dart';

/// CrossFit Tier 라벨 배지. 2px solid border + 대문자 라벨.
class TierBadge extends StatelessWidget {
  final Tier tier;
  final double fontSize;
  const TierBadge({super.key, required this.tier, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: FacingTokens.sp3,
        vertical: fontSize <= 12 ? 4 : 6,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: tier.color, width: 2),
        borderRadius: BorderRadius.circular(FacingTokens.r1),
      ),
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
