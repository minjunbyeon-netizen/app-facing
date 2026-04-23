import 'package:flutter/material.dart';

import 'theme.dart';

/// CrossFit Tier 시스템. 백엔드 `overall_number` (1~6) → 5 티어 매핑.
/// CLAUDE.md "티어 시스템" 섹션이 SSOT.
enum Tier {
  scaled('SCALED', FacingTokens.tierScaled),
  rx('RX', FacingTokens.tierRx),
  rxPlus('RX+', FacingTokens.tierRxPlus),
  elite('ELITE', FacingTokens.tierElite),
  games('GAMES', FacingTokens.tierGames);

  final String label;
  final Color color;
  const Tier(this.label, this.color);

  /// `overall_number` 1~6 → Tier 매핑.
  /// 1-2: Scaled · 3: RX · 4: RX+ · 5: Elite · 6: Games.
  static Tier fromOverallNumber(num? n) {
    if (n == null) return Tier.scaled;
    final v = n.round();
    if (v <= 2) return Tier.scaled;
    if (v == 3) return Tier.rx;
    if (v == 4) return Tier.rxPlus;
    if (v == 5) return Tier.elite;
    return Tier.games;
  }
}
