// v1.20 Phase 2: Panel B 50-title 카탈로그 (클라이언트 로컬).
//
// reference/gamification.md §2 Panel B — 칭호.
// 백엔드 trigger 통합은 Phase 2.5. 현재는 ProfileState/HistoryItem/Achievement 기반
// 로컬 추론. 추론 불가능한 신호(WOD 기록·외부 자격)는 잠금 유지.
//
// 정책:
// - 모든 칭호는 영문 라벨 (V8 단어 1개 / V11 명사+마침표). 부연은 한글 캡션 (V10).
// - rarity: Common < Rare < Epic < Legendary.
// - 착용은 1개 (worn_title_store). 해금은 누적.
// - 분포 (50): Common 15 / Rare 20 / Epic 10 / Legendary 5.

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

/// Panel B 50-title 마스터 카탈로그.
const List<PanelBTitle> kPanelBTitles = [
  // ===== Common (15) =====
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
  PanelBTitle(
    code: 'PB_FIRST_WOD',
    label: 'FIRST WOD',
    captionKo: '첫 WOD 완료.',
    rarity: 'Common',
    requirement: '1 session',
    sortOrder: 70,
  ),
  PanelBTitle(
    code: 'PB_TEN_WODS',
    label: 'DECA',
    captionKo: 'WOD 10회 누적.',
    rarity: 'Common',
    requirement: '10 sessions',
    sortOrder: 75,
  ),
  PanelBTitle(
    code: 'PB_FIFTY_WODS',
    label: 'HALF CENTURY',
    captionKo: 'WOD 50회 누적.',
    rarity: 'Common',
    requirement: '50 sessions',
    sortOrder: 80,
  ),
  PanelBTitle(
    code: 'PB_PROFILE_COMPLETE',
    label: 'PROFILE READY',
    captionKo: '프로필 + 5 벤치마크 입력.',
    rarity: 'Common',
    requirement: 'profile complete + 5 benchmarks',
    sortOrder: 85,
  ),
  PanelBTitle(
    code: 'PB_WARM_UP',
    label: 'WARM UP',
    captionKo: 'Streak 7일.',
    rarity: 'Common',
    requirement: '7-day streak',
    sortOrder: 90,
  ),
  PanelBTitle(
    code: 'PB_COMMITTED',
    label: 'COMMITTED',
    captionKo: 'Streak 14일.',
    rarity: 'Common',
    requirement: '14-day streak',
    sortOrder: 92,
  ),
  PanelBTitle(
    code: 'PB_DEDICATED',
    label: 'DEDICATED',
    captionKo: 'Streak 30일.',
    rarity: 'Common',
    requirement: '30-day streak',
    sortOrder: 95,
  ),
  PanelBTitle(
    code: 'PB_FRESH_START',
    label: 'FRESH START',
    captionKo: '신년 첫 WOD (1/1~1/7).',
    rarity: 'Common',
    requirement: 'session in Jan 1~7',
    sortOrder: 97,
  ),
  PanelBTitle(
    code: 'PB_PHOTO_FINISH',
    label: 'SHARE',
    captionKo: 'SNS 공유 1회.',
    rarity: 'Common',
    requirement: 'shared 1+',
    sortOrder: 99,
  ),

  // ===== Rare (20) =====
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
    captionKo: 'HSPU 10회 unbroken.',
    rarity: 'Rare',
    requirement: 'HSPU 10 unbroken',
    sortOrder: 180,
  ),
  PanelBTitle(
    code: 'PB_PR_HUNTER',
    label: 'PR HUNTER',
    captionKo: 'PR 5회 누적.',
    rarity: 'Rare',
    requirement: '5 PRs logged',
    sortOrder: 185,
  ),
  PanelBTitle(
    code: 'PB_PR_MACHINE',
    label: 'PR MACHINE',
    captionKo: 'PR 10회 누적.',
    rarity: 'Rare',
    requirement: '10 PRs logged',
    sortOrder: 190,
  ),
  PanelBTitle(
    code: 'PB_DEADLIFT_DOUBLE',
    label: 'DEADLIFT DOUBLE',
    captionKo: '데드리프트 1RM 체중 2배.',
    rarity: 'Rare',
    requirement: 'DL 1RM ≥ 2x BW',
    sortOrder: 195,
  ),
  PanelBTitle(
    code: 'PB_PRESS_BODYWEIGHT',
    label: 'SHOULDER STRONG',
    captionKo: '스트릭트 프레스 1RM 체중.',
    rarity: 'Rare',
    requirement: 'Strict Press 1RM ≥ BW',
    sortOrder: 200,
  ),
  PanelBTitle(
    code: 'PB_KIPPING_PULLUP',
    label: 'KIPPING',
    captionKo: '키핑 풀업 30회 unbroken.',
    rarity: 'Rare',
    requirement: 'kipping pullup 30 unbroken',
    sortOrder: 205,
  ),
  PanelBTitle(
    code: 'PB_TOES_TO_BAR',
    label: 'T2B PRO',
    captionKo: 'T2B 30회 unbroken.',
    rarity: 'Rare',
    requirement: 'T2B 30 unbroken',
    sortOrder: 207,
  ),
  PanelBTitle(
    code: 'PB_WALL_BALL',
    label: 'WALL BALL',
    captionKo: '월볼 100회 unbroken.',
    rarity: 'Rare',
    requirement: 'WB 100 unbroken',
    sortOrder: 209,
  ),
  PanelBTitle(
    code: 'PB_BURPEE',
    label: 'BURPEE',
    captionKo: '버피 100회 sub-5:00.',
    rarity: 'Rare',
    requirement: '100 burpees < 5:00',
    sortOrder: 211,
  ),
  PanelBTitle(
    code: 'PB_DOUBLE_DAY',
    label: 'DOUBLE DAY',
    captionKo: '하루 2 세션 5회.',
    rarity: 'Rare',
    requirement: '2 sessions/day x5',
    sortOrder: 213,
  ),
  PanelBTitle(
    code: 'PB_OPEN_ROOKIE',
    label: 'OPEN ROOKIE',
    captionKo: 'CrossFit Open 첫 참가.',
    rarity: 'Rare',
    requirement: 'first Open registered',
    sortOrder: 215,
  ),
  PanelBTitle(
    code: 'PB_GRACE_FAST',
    label: 'GRACE FAST',
    captionKo: 'Grace 2분 이내.',
    rarity: 'Rare',
    requirement: 'Grace < 2:00',
    sortOrder: 217,
  ),
  PanelBTitle(
    code: 'PB_SPLIT_MASTER',
    label: 'SPLIT MASTER',
    captionKo: '페이싱 정확도 95%+ 10회.',
    rarity: 'Rare',
    requirement: 'pacing accuracy 95% x10',
    sortOrder: 219,
  ),

  // ===== Epic (10) =====
  PanelBTitle(
    code: 'PB_HEAVY',
    label: 'HEAVY',
    captionKo: '백 스쿼트 1RM 200kg+.',
    rarity: 'Epic',
    requirement: 'BS 1RM ≥ 200kg',
    sortOrder: 310,
  ),
  PanelBTitle(
    code: 'PB_THRUSTER',
    label: 'THRUSTER LORD',
    captionKo: 'Fran 3분 이내.',
    rarity: 'Epic',
    requirement: 'Fran < 3:00',
    sortOrder: 320,
  ),
  PanelBTitle(
    code: 'PB_RING',
    label: 'RING',
    captionKo: '머슬업 5회 unbroken.',
    rarity: 'Epic',
    requirement: 'MUS 5 unbroken',
    sortOrder: 330,
  ),
  PanelBTitle(
    code: 'PB_COMPETITOR',
    label: 'COMPETITOR',
    captionKo: 'CrossFit Open 등록.',
    rarity: 'Epic',
    requirement: 'Open registered',
    sortOrder: 340,
  ),
  PanelBTitle(
    code: 'PB_DEADLIFT_TRIPLE',
    label: 'DEADLIFT TRIPLE',
    captionKo: '데드리프트 1RM 체중 3배.',
    rarity: 'Epic',
    requirement: 'DL 1RM ≥ 3x BW',
    sortOrder: 345,
  ),
  PanelBTitle(
    code: 'PB_HELEN_FAST',
    label: 'HELEN',
    captionKo: 'Helen 9분 이내.',
    rarity: 'Epic',
    requirement: 'Helen < 9:00',
    sortOrder: 350,
  ),
  PanelBTitle(
    code: 'PB_DT_SUB_8',
    label: 'DT',
    captionKo: 'DT 8분 이내.',
    rarity: 'Epic',
    requirement: 'DT < 8:00',
    sortOrder: 355,
  ),
  PanelBTitle(
    code: 'PB_FILTHY_FIFTY',
    label: 'FILTHY FIFTY',
    captionKo: 'Filthy Fifty 25분 이내.',
    rarity: 'Epic',
    requirement: 'F50 < 25:00',
    sortOrder: 360,
  ),
  PanelBTitle(
    code: 'PB_MURPH_SCALED',
    label: 'MURPH',
    captionKo: 'Murph scaled 완료.',
    rarity: 'Epic',
    requirement: 'Murph any scale',
    sortOrder: 365,
  ),
  PanelBTitle(
    code: 'PB_QF_QUALIFIER',
    label: 'QF QUALIFIER',
    captionKo: 'Quarterfinals 통과.',
    rarity: 'Epic',
    requirement: 'QF qualified',
    sortOrder: 370,
  ),

  // ===== Legendary (5) =====
  PanelBTitle(
    code: 'PB_PRINCIPAL',
    label: 'PRINCIPAL',
    captionKo: '프론트 스쿼트 1RM 150kg+.',
    rarity: 'Legendary',
    requirement: 'FS 1RM ≥ 150kg',
    sortOrder: 410,
  ),
  PanelBTitle(
    code: 'PB_SNATCH_KING',
    label: 'SNATCH KING',
    captionKo: '스내치 1RM 100kg+.',
    rarity: 'Legendary',
    requirement: 'Snatch 1RM ≥ 100kg',
    sortOrder: 420,
  ),
  PanelBTitle(
    code: 'PB_GAMES',
    label: 'GAMES',
    captionKo: 'CrossFit Games 진출.',
    rarity: 'Legendary',
    requirement: 'Games qualified',
    sortOrder: 430,
  ),
  PanelBTitle(
    code: 'PB_REGIONAL_CHAMP',
    label: 'REGIONAL CHAMP',
    captionKo: '지역 1위.',
    rarity: 'Legendary',
    requirement: 'regional #1',
    sortOrder: 440,
  ),
  PanelBTitle(
    code: 'PB_HERO_MURPH',
    label: 'HERO',
    captionKo: 'Murph RX 40분 이내.',
    rarity: 'Legendary',
    requirement: 'Murph RX < 40:00',
    sortOrder: 450,
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

  // v1.21 신규 신호 (50-title 확장).
  final int streakDays;            // 현재 Streak 일수
  final int prCount;               // PR 누적 수
  final bool profileComplete;      // 프로필 + 5 벤치마크
  final bool freshStartSession;    // 1/1~1/7 세션 1회+
  final int shareCount;            // SNS 공유 누적
  final double? deadlift1rmKg;
  final double? pressStrict1rmKg;
  final double? bodyWeightKg;
  final int kippingPullupUnbroken;
  final int t2bUnbrokenMax;
  final int wbUnbrokenMax;
  final int? burpee100Sec;
  final int doubleSessionDayCount;
  final int? graceSec;
  final int pacingAccuracy95Count;
  final int? helenSec;
  final int? dtSec;
  final int? filthyFiftySec;
  final bool murphAnyScale;
  final int? murphRxSec;
  final bool qfQualified;
  final bool gamesQualified;
  final bool regionalChampion;

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
    this.streakDays = 0,
    this.prCount = 0,
    this.profileComplete = false,
    this.freshStartSession = false,
    this.shareCount = 0,
    this.deadlift1rmKg,
    this.pressStrict1rmKg,
    this.bodyWeightKg,
    this.kippingPullupUnbroken = 0,
    this.t2bUnbrokenMax = 0,
    this.wbUnbrokenMax = 0,
    this.burpee100Sec,
    this.doubleSessionDayCount = 0,
    this.graceSec,
    this.pacingAccuracy95Count = 0,
    this.helenSec,
    this.dtSec,
    this.filthyFiftySec,
    this.murphAnyScale = false,
    this.murphRxSec,
    this.qfQualified = false,
    this.gamesQualified = false,
    this.regionalChampion = false,
  });
}

class PanelBUnlocker {
  PanelBUnlocker._();

  /// 입력 signals 로 해금된 칭호 code 집합 반환.
  /// O(50) 단순 분기.
  static Set<String> unlockedCodes(TitleUnlockSignals s) {
    final out = <String>{};
    // Common
    if (s.totalSessions >= 100) out.add('PB_GRINDER');
    if (s.benchmarkCount >= 5) out.add('PB_METRIC_DEVOTEE');
    if (s.hasGym) out.add('PB_BOX_MEMBER');
    if (s.sessionsBefore6am >= 10) out.add('PB_EARLY_BIRD');
    if (s.sessionsAfter10pm >= 10) out.add('PB_NIGHT_OWL');
    if (s.weekendSessions >= 20) out.add('PB_WEEKEND');
    if (s.totalSessions >= 1) out.add('PB_FIRST_WOD');
    if (s.totalSessions >= 10) out.add('PB_TEN_WODS');
    if (s.totalSessions >= 50) out.add('PB_FIFTY_WODS');
    if (s.profileComplete) out.add('PB_PROFILE_COMPLETE');
    if (s.streakDays >= 7) out.add('PB_WARM_UP');
    if (s.streakDays >= 14) out.add('PB_COMMITTED');
    if (s.streakDays >= 30) out.add('PB_DEDICATED');
    if (s.freshStartSession) out.add('PB_FRESH_START');
    if (s.shareCount >= 1) out.add('PB_PHOTO_FINISH');

    // Rare
    if (s.engineScore80PlusCount >= 5) out.add('PB_IRON_LUNG');
    if (s.ub50PlusSessions >= 3) out.add('PB_UNBROKEN');
    if (s.du50Unbroken) out.add('PB_DOUBLE_UNDER');
    if (s.fiveKmSub25) out.add('PB_RUNNER');
    if (s.twoKmRowSub730) out.add('PB_ROWER');
    if (s.coachNotesSent >= 10) out.add('PB_TEACHER');
    if (s.coachNotesReceived >= 10) out.add('PB_STUDENT');
    if (s.hspu10Unbroken) out.add('PB_HSPU');
    if (s.prCount >= 5) out.add('PB_PR_HUNTER');
    if (s.prCount >= 10) out.add('PB_PR_MACHINE');
    if (s.deadlift1rmKg != null &&
        s.bodyWeightKg != null &&
        s.deadlift1rmKg! >= s.bodyWeightKg! * 2) {
      out.add('PB_DEADLIFT_DOUBLE');
    }
    if (s.pressStrict1rmKg != null &&
        s.bodyWeightKg != null &&
        s.pressStrict1rmKg! >= s.bodyWeightKg!) {
      out.add('PB_PRESS_BODYWEIGHT');
    }
    if (s.kippingPullupUnbroken >= 30) out.add('PB_KIPPING_PULLUP');
    if (s.t2bUnbrokenMax >= 30) out.add('PB_TOES_TO_BAR');
    if (s.wbUnbrokenMax >= 100) out.add('PB_WALL_BALL');
    if (s.burpee100Sec != null && s.burpee100Sec! < 300) {
      out.add('PB_BURPEE');
    }
    if (s.doubleSessionDayCount >= 5) out.add('PB_DOUBLE_DAY');
    if (s.openRegistered) out.add('PB_OPEN_ROOKIE');
    if (s.graceSec != null && s.graceSec! < 120) out.add('PB_GRACE_FAST');
    if (s.pacingAccuracy95Count >= 10) out.add('PB_SPLIT_MASTER');

    // Epic
    if ((s.backSquat1rmKg ?? 0) >= 200) out.add('PB_HEAVY');
    if (s.franSec != null && s.franSec! < 180) out.add('PB_THRUSTER');
    if (s.mus5Unbroken) out.add('PB_RING');
    if (s.openRegistered) out.add('PB_COMPETITOR');
    if (s.deadlift1rmKg != null &&
        s.bodyWeightKg != null &&
        s.deadlift1rmKg! >= s.bodyWeightKg! * 3) {
      out.add('PB_DEADLIFT_TRIPLE');
    }
    if (s.helenSec != null && s.helenSec! < 540) out.add('PB_HELEN_FAST');
    if (s.dtSec != null && s.dtSec! < 480) out.add('PB_DT_SUB_8');
    if (s.filthyFiftySec != null && s.filthyFiftySec! < 1500) {
      out.add('PB_FILTHY_FIFTY');
    }
    if (s.murphAnyScale) out.add('PB_MURPH_SCALED');
    if (s.qfQualified) out.add('PB_QF_QUALIFIER');

    // Legendary
    if ((s.frontSquat1rmKg ?? 0) >= 150) out.add('PB_PRINCIPAL');
    if ((s.snatch1rmKg ?? 0) >= 100) out.add('PB_SNATCH_KING');
    if (s.gamesQualified) out.add('PB_GAMES');
    if (s.regionalChampion) out.add('PB_REGIONAL_CHAMP');
    if (s.murphRxSec != null && s.murphRxSec! < 2400) {
      out.add('PB_HERO_MURPH');
    }
    return out;
  }
}
