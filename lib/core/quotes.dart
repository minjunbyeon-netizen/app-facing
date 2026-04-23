import 'dart:math';

class Quote {
  final String text;
  final String author;
  const Quote(this.text, this.author);
}

/// 채택 명언 10개 (영문 원본 + 저자).
/// 선정 기준: 엘리트 athlete 인용 · 1줄 이내 · 동기부여보다 사실 진술 성격.
const List<Quote> kQuotes = [
  Quote('The only way out is through.', 'Robert Frost'),
  Quote('Do the work. Every day.', 'Rich Froning Jr.'),
  Quote('Train hard. Win easy.', 'CrossFit community'),
  Quote('Comfort is the enemy of progress.', 'P.T. Barnum'),
  Quote('Fatigue makes cowards of us all.', 'Vince Lombardi'),
  Quote('Earn it.', 'HWPO'),
  Quote(
      "You don't rise to the level of your goals. You fall to the level of your systems.",
      'James Clear'),
  Quote('Pain is temporary. The score is permanent.', 'CrossFit Games'),
  Quote("Impossible isn't far.", 'Camille Leblanc-Bazinet'),
  Quote(
      'Everyone wants to win. Not everyone wants to prepare to win.',
      'Mat Fraser'),
];

/// 완전 랜덤. splash / loading 용.
Quote randomQuote() {
  return kQuotes[Random().nextInt(kQuotes.length)];
}

/// seed 기반 결정론적 선택. 같은 등급이면 같은 명언을 고정 노출.
Quote stableQuote(int seed) {
  final i = seed.abs() % kQuotes.length;
  return kQuotes[i];
}
