// v1.16 Sprint 8 U4: CrossFit 시즌 판별 (mock).
// ⚠️ **가상 데이터** — 공식 일정은 매년 공개. 현재는 고정 더미.
// 실제 CrossFit Open·Quarterfinals·Semifinals·Games 날짜는 매년 variable.
// Phase 2에서 백엔드 `/api/v1/season/current` 로 대체.

enum CrossFitSeason {
  offseason,
  open,
  quarterfinals,
  semifinals,
  games,
}

class SeasonInfo {
  final CrossFitSeason current;
  final String label;
  final String description;
  final DateTime? endDate;

  const SeasonInfo({
    required this.current,
    required this.label,
    required this.description,
    this.endDate,
  });

  bool get isActive => current != CrossFitSeason.offseason;
}

/// ⚠️ 가상 일정 — 실제 CrossFit 공식 일정과 무관.
/// 매년 2월 말~3월 초 Open / 4월 Quarterfinals / 5-6월 Semifinals / 7-8월 Games 패턴.
SeasonInfo currentSeason([DateTime? now]) {
  final n = now ?? DateTime.now();
  final month = n.month;
  final day = n.day;

  // Open: 2/22 ~ 3/15 (가상)
  if (month == 2 && day >= 22) {
    return SeasonInfo(
      current: CrossFitSeason.open,
      label: 'OPEN SEASON',
      description: 'CrossFit Open 진행 중 · 매주 Open WOD 발표.',
      endDate: DateTime(n.year, 3, 15),
    );
  }
  if (month == 3 && day <= 15) {
    return SeasonInfo(
      current: CrossFitSeason.open,
      label: 'OPEN SEASON',
      description: 'CrossFit Open 진행 중 · 매주 Open WOD 발표.',
      endDate: DateTime(n.year, 3, 15),
    );
  }
  // Quarterfinals: 4월 전체 (가상)
  if (month == 4) {
    return SeasonInfo(
      current: CrossFitSeason.quarterfinals,
      label: 'QUARTERFINALS',
      description: '쿼터파이널 · 상위 10% 대상.',
      endDate: DateTime(n.year, 4, 30),
    );
  }
  // Semifinals: 5~6월 (가상)
  if (month == 5 || month == 6) {
    return SeasonInfo(
      current: CrossFitSeason.semifinals,
      label: 'SEMIFINALS',
      description: '세미파이널 · 지역 Top 선수들 대회.',
      endDate: DateTime(n.year, 6, 30),
    );
  }
  // Games: 7월 말 ~ 8월 초 (가상)
  if ((month == 7 && day >= 25) || (month == 8 && day <= 5)) {
    return SeasonInfo(
      current: CrossFitSeason.games,
      label: 'GAMES',
      description: 'CrossFit Games 본선 · 세계 최고 이벤트.',
      endDate: DateTime(n.year, 8, 5),
    );
  }
  return const SeasonInfo(
    current: CrossFitSeason.offseason,
    label: 'OFFSEASON',
    description: '오프시즌 · 약점 보강 · 기본기 다지기.',
  );
}
