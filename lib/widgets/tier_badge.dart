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
    final compact = fontSize <= 12;
    // v1.15 P1-3: Semantics — 스크린리더 "Tier: ELITE" 형식 안내.
    return Semantics(
      label: 'Tier ${tier.label}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? FacingTokens.sp2 : FacingTokens.sp3,
          vertical: compact ? FacingTokens.sp1 - 1 : FacingTokens.sp2 - 2,
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
          ),
        ),
      ),
    );
  }
}
