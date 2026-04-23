import 'package:flutter/material.dart';

import 'theme.dart';

/// CrossFit Tier 시스템. 백엔드 `overall_number` (1~6) → 5 티어 매핑.
/// CLAUDE.md "티어 시스템" 섹션이 SSOT.
enum Tier {
  scaled('SCALED', FacingTokens.tierScaled, FacingTokens.fg),
  rx('RX', FacingTokens.tierRx, FacingTokens.fg),
  rxPlus('RX+', FacingTokens.tierRxPlus, FacingTokens.bg),
  elite('ELITE', FacingTokens.tierElite, FacingTokens.bg),
  games('GAMES', FacingTokens.tierGames, FacingTokens.bg);

  final String label;
  final Color color;
  /// fill 배지용 전경 텍스트 색 (배경=tier.color 일 때 대비색).
  final Color textColor;
  const Tier(this.label, this.color, this.textColor);

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
