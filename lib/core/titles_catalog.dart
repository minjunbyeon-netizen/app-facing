// v1.20 Phase 2: Panel B 20-title 카탈로그 (클라이언트 로컬).
//
// reference/gamification.md §2 Panel B — 칭호.
// 백엔드 trigger 통합은 Phase 2.5. 현재는 ProfileState/HistoryItem/Achievement 기반
// 로컬 추론.
//
// 정책:
// - 모든 칭호는 영문 라벨 (V8 단어 1개 / V11 명사+마침표). 부연은 한글 캡션 (V10).
// - rarity: Common < Rare < Epic < Legendary.
// - 착용은 1개 (worn_title_store). 해금은 누적.

class PanelBTitle {
  final String code;
  final String label;       // 영문 단어/구문 (V8/V11)
  final String captionKo;   // 한글 캡션 (V10 패턴)
  final String rarity;      // Common | Rare | Epic | Legendary
  final String requirement; // 사람이 읽는 해금 조건 설명
  final int sortOrder;

  const PanelBTitle({
    required this.code,
    required this.label,
    required this.captionKo,
    required this.rarity,
    required this.requirement,
    required this.sortOrder,
  });
}

/// Panel B 20-title 마스터 카탈로그.
const List<PanelBTitle> kPanelBTitles = [
  // ===== Common (대중 6) =====
  PanelBTitle(
    code: 'PB_GRINDER',
    label: 'THE GRINDER',
    captionKo: '총 세션 100회 누적.',
    rarity: 'Common',
    requirement: '100 sessions',
    sortOrder: 10,
  ),
  PanelBTitle(
    code: 'PB_METRIC_DEVOTEE',
    label: 'METRIC DEVOTEE',
    captionKo: '벤치마크 5종 입력.',
    rarity: 'Common',
    requirement: '5 benchmarks logged',
    sortOrder: 20,
  ),
  PanelBTitle(
    code: 'PB_BOX_MEMBER',
    label: 'BOX MEMBER',
    captionKo: '박스 가입 완료.',
    rarity: 'Common',
    requirement: 'gym membership active',
    sortOrder: 30,
  ),
  PanelBTitle(
    code: 'PB_EARLY_BIRD',
    label: 'COFFEE BREW',
    captionKo: '06:00 이전 세션 10회.',
    rarity: 'Common',
    requirement: '10 sessions before 06:00',
    sortOrder: 40,
  ),
  PanelBTitle(
    code: 'PB_NIGHT_OWL',
    label: 'LATE NIGHT',
    captionKo: '22:00 이후 세션 10회.',
    rarity: 'Common',
    requirement: '10 sessions after 22:00',
    sortOrder: 50,
  ),
  PanelBTitle(
    code: 'PB_WEEKEND',
    label: 'WEEKEND WARRIOR',
    captionKo: '주말 세션 20회.',
    rarity: 'Common',
    requirement: '20 weekend sessions',
    sortOrder: 60,
  ),

  // ===== Rare (중간 8) =====
  PanelBTitle(
    code: 'PB_IRON_LUNG',
    label: 'IRON LUNG',
    captionKo: 'Engine 80+ 5회.',
    rarity: 'Rare',
    requirement: 'Engine score 80+ logged 5 times',
    sortOrder: 110,
  ),
  PanelBTitle(
    code: 'PB_UNBROKEN',
    label: 'UNBROKEN',
    captionKo: 'UB 50+ 3회.',
    rarity: 'Rare',
    requirement: 'UB 50+ in 3 separate sessions',
    sortOrder: 120,
  ),
  PanelBTitle(
    code: 'PB_DOUBLE_UNDER',
    label: 'DOUBLE-UNDER',
    captionKo: '더블 언더 50회 unbroken.',
    rarity: 'Rare',
    requirement: 'DU 50 unbroken',
    sortOrder: 130,
  ),
  PanelBTitle(
    code: 'PB_RUNNER',
    label: 'RUNNER',
    captionKo: '러닝 5km sub-25:00.',
    rarity: 'Rare',
    requirement: '5km < 25:00',
    sortOrder: 140,
  ),
  PanelBTitle(
    code: 'PB_ROWER',
    label: 'ROWER',
    captionKo: '로잉 2km sub-7:30.',
    rarity: 'Rare',
    requirement: '2km row < 7:30',
    sortOrder: 150,
  ),
  PanelBTitle(
    code: 'PB_TEACHER',
    label: 'THE TEACHER',
    captionKo: '코치 노트 10건 발송.',
    rarity: 'Rare',
    requirement: '10 coach notes sent',
    sortOrder: 160,
  ),
  PanelBTitle(
    code: 'PB_STUDENT',
    label: 'THE STUDENT',
    captionKo: '코치 노트 10건 수령.',
    rarity: 'Rare',
    requirement: '10 coach notes received',
    sortOrder: 170,
  ),
  PanelBTitle(
    code: 'PB_HSPU',
    label: 'HSPU MASTER',
    captionKo: '핸드스탠드 푸쉬업 10회 unbroken.',
    rarity: 'Rare',
    requirement: 'HSPU 10 unbroken',
    sortOrder: 180,
  ),

  // ===== Epic (어려움 4) =====
  PanelBTitle(
    code: 'PB_HEAVY',
    label: 'HEAVY',
    captionKo: '백 스쿼트 1RM 200kg+.',
    rarity: 'Epic',
    requirement: 'BS 1RM ≥ 200kg',
    sortOrder: 210,
  ),
  PanelBTitle(
    code: 'PB_THRUSTER',
    label: 'THRUSTER LORD',
    captionKo: '프랜 sub-3:00 달성.',
    rarity: 'Epic',
    requirement: 'Fran < 3:00',
    sortOrder: 220,
  ),
  PanelBTitle(
    code: 'PB_RING',
    label: 'RING',
    captionKo: '머슬업 5회 unbroken.',
    rarity: 'Epic',
    requirement: 'MUS 5 unbroken',
    sortOrder: 230,
  ),
  PanelBTitle(
    code: 'PB_COMPETITOR',
    label: 'COMPETITOR',
    captionKo: 'CrossFit Open 등록.',
    rarity: 'Epic',
    requirement: 'Open registered',
    sortOrder: 240,
  ),

  // ===== Legendary (최상위 2) =====
  PanelBTitle(
    code: 'PB_PRINCIPAL',
    label: 'PRINCIPAL',
    captionKo: '프론트 스쿼트 1RM 150kg+.',
    rarity: 'Legendary',
    requirement: 'FS 1RM ≥ 150kg',
    sortOrder: 310,
  ),
  PanelBTitle(
    code: 'PB_SNATCH_KING',
    label: 'SNATCH KING',
    captionKo: '스내치 1RM 100kg+.',
    rarity: 'Legendary',
    requirement: 'Snatch 1RM ≥ 100kg',
    sortOrder: 320,
  ),
];

/// 클라이언트-사이드 해금 추론.
/// signals: 호출부가 가공한 현재 사용자 상태 (서버 PR 플래그 없이도 즉시 작동).
class TitleUnlockSignals {
  final int totalSessions;
  final int benchmarkCount;
  final bool hasGym;
  final int sessionsBefore6am;
  final int sessionsAfter10pm;
  final int weekendSessions;
  final int engineScore80PlusCount;
  final int ub50PlusSessions;
  final bool du50Unbroken;
  final bool fiveKmSub25;
  final bool twoKmRowSub730;
  final int coachNotesSent;
  final int coachNotesReceived;
  final bool hspu10Unbroken;
  final double? backSquat1rmKg;
  final double? frontSquat1rmKg;
  final double? snatch1rmKg;
  final int? franSec; // Fran 기록 초
  final bool mus5Unbroken;
  final bool openRegistered;

  const TitleUnlockSignals({
    this.totalSessions = 0,
    this.benchmarkCount = 0,
    this.hasGym = false,
    this.sessionsBefore6am = 0,
    this.sessionsAfter10pm = 0,
    this.weekendSessions = 0,
    this.engineScore80PlusCount = 0,
    this.ub50PlusSessions = 0,
    this.du50Unbroken = false,
    this.fiveKmSub25 = false,
    this.twoKmRowSub730 = false,
    this.coachNotesSent = 0,
    this.coachNotesReceived = 0,
    this.hspu10Unbroken = false,
    this.backSquat1rmKg,
    this.frontSquat1rmKg,
    this.snatch1rmKg,
    this.franSec,
    this.mus5Unbroken = false,
    this.openRegistered = false,
  });
}

class PanelBUnlocker {
  PanelBUnlocker._();

  /// 입력 signals 로 해금된 칭호 code 집합 반환.
  /// O(20) 단순 분기.
  static Set<String> unlockedCodes(TitleUnlockSignals s) {
    final out = <String>{};
    if (s.totalSessions >= 100) out.add('PB_GRINDER');
    if (s.benchmarkCount >= 5) out.add('PB_METRIC_DEVOTEE');
    if (s.hasGym) out.add('PB_BOX_MEMBER');
    if (s.sessionsBefore6am >= 10) out.add('PB_EARLY_BIRD');
    if (s.sessionsAfter10pm >= 10) out.add('PB_NIGHT_OWL');
    if (s.weekendSessions >= 20) out.add('PB_WEEKEND');

    if (s.engineScore80PlusCount >= 5) out.add('PB_IRON_LUNG');
    if (s.ub50PlusSessions >= 3) out.add('PB_UNBROKEN');
    if (s.du50Unbroken) out.add('PB_DOUBLE_UNDER');
    if (s.fiveKmSub25) out.add('PB_RUNNER');
    if (s.twoKmRowSub730) out.add('PB_ROWER');
    if (s.coachNotesSent >= 10) out.add('PB_TEACHER');
    if (s.coachNotesReceived >= 10) out.add('PB_STUDENT');
    if (s.hspu10Unbroken) out.add('PB_HSPU');

    if ((s.backSquat1rmKg ?? 0) >= 200) out.add('PB_HEAVY');
    if (s.franSec != null && s.franSec! < 180) out.add('PB_THRUSTER');
    if (s.mus5Unbroken) out.add('PB_RING');
    if (s.openRegistered) out.add('PB_COMPETITOR');

    if ((s.frontSquat1rmKg ?? 0) >= 150) out.add('PB_PRINCIPAL');
    if ((s.snatch1rmKg ?? 0) >= 100) out.add('PB_SNATCH_KING');
    return out;
  }
}
