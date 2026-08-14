import 'package:flutter/material.dart';

import 'theme.dart';

/// 경력 구간 하나. 사용자가 말한 경계(1년·3년)를 그대로 쓰되 서로 겹치지 않게 나눴다.
/// [years] 는 서버·등급 로직이 쓰는 대표값이다. 목록은 [Tier.bands].
class ExperienceBand {
  final String label;
  final double years;
  const ExperienceBand(this.label, this.years);
}

/// CrossFit Tier 시스템. 백엔드 `overall_number` (1~6) → 5 티어 매핑.
/// v1.15부터: 명도 재배치(어둠→빛) + motivation/discipline/obsession 서브타이틀.
enum Tier {
  scaled('SCALED', 'Motivation.', HyphenTokens.tierScaled, HyphenTokens.fg),
  rx('RX', 'Discipline.', HyphenTokens.tierRx, HyphenTokens.fg),
  rxPlus('RX+', 'Discipline+.', HyphenTokens.tierRxPlus, HyphenTokens.bg),
  elite('ELITE', 'Obsession.', HyphenTokens.tierElite, HyphenTokens.bg),
  games('GAMES', 'Obsession.', HyphenTokens.tierGames, HyphenTokens.bg);

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

  /// **회원 레벨 = 운동 경력** (2026-08-12 사용자 지시 · BRIEF D36).
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

  /// 경력을 고르는 화면이 쓰는 구간 목록. 라벨과 대표 연차를 짝지어 둔다.
  ///
  /// v2.8 (2026-08-13): 가입 신청서와 프로필 수정 두 화면이 같은 구간을 물어서
  /// 각자 상수를 들고 있었다. 한쪽만 고치면 같은 질문에 답이 갈리므로
  /// [fromExperienceYears] 바로 옆으로 옮긴다 (글로벌 §0-B 이름 일원화).
  static const List<ExperienceBand> bands = [
    ExperienceBand('1년 미만', 0.5),
    ExperienceBand('1~3년', 2),
    ExperienceBand('3년 이상', 5),
  ];

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
