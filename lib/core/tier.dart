import 'package:flutter/material.dart';

import 'theme.dart';

/// CrossFit Tier 시스템. 백엔드 `overall_number` (1~6) → 5 티어 매핑.
/// v1.15부터: 명도 재배치(어둠→빛) + motivation/discipline/obsession 서브타이틀.
enum Tier {
  scaled('SCALED', 'Motivation.', FacingTokens.tierScaled, FacingTokens.fg),
  rx('RX', 'Discipline.', FacingTokens.tierRx, FacingTokens.fg),
  rxPlus('RX+', 'Discipline+.', FacingTokens.tierRxPlus, FacingTokens.bg),
  elite('ELITE', 'Obsession.', FacingTokens.tierElite, FacingTokens.bg),
  games('GAMES', 'Obsession.', FacingTokens.tierGames, FacingTokens.bg);

  final String label;

  /// v1.15: Tier별 철학 서브타이틀 (Cormorant/Bodoni italic 권장 표시).
  final String subtitle;
  final Color color;

  /// fill 배지용 전경 텍스트 색 (배경=color일 때 대비색).
  final Color textColor;
  const Tier(this.label, this.subtitle, this.color, this.textColor);

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

  /// **회원 레벨 = 크로스핏 경력** (2026-08-12 사용자 지시 · BRIEF D36).
  ///
  /// 1년 미만 → SCALED · 1~3년 → RXD(=rx) · 3년 이상 → ELITE.
  /// 경계 숫자는 **여기 한 곳**에만 둔다 — 화면마다 다시 쓰면 기준이 갈린다.
  /// 입력값은 가입 직후 온보딩(`onboarding_basic.dart`)이 저장하는 대표 연차.
  /// 사다리는 셋뿐이라 RX+·Games 는 이 함수에서 나오지 않는다.
  static Tier fromExperienceYears(double years) {
    if (years < 1) return Tier.scaled;
    if (years < 3) return Tier.rx;
    return Tier.elite;
  }

  /// 회원 레벨 표기 — RX 는 'RXD' 로 쓴다 (2026-05-30 통일 · GLOSSARY §3).
  String get memberLevelLabel => this == Tier.rx ? 'RXD' : label;

  /// Tier별 고정 명언.
  String get quote {
    switch (this) {
      case Tier.scaled:
        return 'The only way out is through.';
      case Tier.rx:
        return 'Do the work. Every day.';
      case Tier.rxPlus:
        return 'Comfort is the enemy of progress.';
      case Tier.elite:
        return "Impossible isn't far.";
      case Tier.games:
        return 'Everyone wants to win. Not everyone wants to prepare.';
    }
  }

  /// v1.15 P2-1: Tier별 고정 명언의 저자 (QuoteCard author 표시용).
  String get quoteAuthor {
    switch (this) {
      case Tier.scaled:
        return 'Robert Frost';
      case Tier.rx:
        return 'Rich Froning Jr.';
      case Tier.rxPlus:
        return 'P.T. Barnum';
      case Tier.elite:
        return 'Camille Leblanc-Bazinet';
      case Tier.games:
        return 'Mat Fraser';
    }
  }
}
