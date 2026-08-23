// v1.20 Phase 2: Panel B 50-title 카탈로그 (클라이언트 로컬).
//
// reference/gamification.md §2 Panel B — 칭호.
// 백엔드 trigger 통합은 Phase 2.5. 현재는 ProfileState/HistoryItem/Achievement 기반
// 로컬 추론. 추론 불가능한 신호(WOD 기록·외부 자격)는 잠금 유지.
//
// 정책:
// - v3.12 (2026-08-23): 칭호 이름은 한글 명사형. 구 '영문 라벨' 원칙은
//   v1.29 한글 기본 전환으로 폐기됐는데 이 파일만 옛 원칙에 머물러 있었다.
//   도메인 고정어(PR·Streak)는 그대로 둔다 (DESIGN-SSOT §7).
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
    label: '백 번의 수업',
    captionKo: '총 세션 100회 누적.',
    rarity: 'Common',
    requirement: '100 sessions',
    sortOrder: 10,
  ),
  PanelBTitle(
    code: 'PB_BOX_MEMBER',
    label: '입문',
    captionKo: '체육관 가입 완료.',
    rarity: 'Common',
    requirement: 'gym membership active',
    sortOrder: 30,
  ),
  PanelBTitle(
    code: 'PB_EARLY_BIRD',
    label: '새벽반',
    captionKo: '06:00 이전 세션 10회.',
    rarity: 'Common',
    requirement: '10 sessions before 06:00',
    sortOrder: 40,
  ),
  PanelBTitle(
    code: 'PB_NIGHT_OWL',
    label: '야간반',
    captionKo: '22:00 이후 세션 10회.',
    rarity: 'Common',
    requirement: '10 sessions after 22:00',
    sortOrder: 50,
  ),
  PanelBTitle(
    code: 'PB_WEEKEND',
    label: '주말반',
    captionKo: '주말 세션 20회.',
    rarity: 'Common',
    requirement: '20 weekend sessions',
    sortOrder: 60,
  ),
  PanelBTitle(
    code: 'PB_FIRST_WOD',
    label: '첫 수업',
    captionKo: '첫 수업 기록 완료.',
    rarity: 'Common',
    requirement: '1 session',
    sortOrder: 70,
  ),
  PanelBTitle(
    code: 'PB_TEN_WODS',
    label: '열 번의 수업',
    captionKo: '수업 기록 10회 누적.',
    rarity: 'Common',
    requirement: '10 sessions',
    sortOrder: 75,
  ),
  PanelBTitle(
    code: 'PB_FIFTY_WODS',
    label: '쉰 번의 수업',
    captionKo: '수업 기록 50회 누적.',
    rarity: 'Common',
    requirement: '50 sessions',
    sortOrder: 80,
  ),
  PanelBTitle(
    code: 'PB_WARM_UP',
    label: 'Streak 7일',
    captionKo: 'Streak 7일.',
    rarity: 'Common',
    requirement: '7-day streak',
    sortOrder: 90,
  ),
  PanelBTitle(
    code: 'PB_COMMITTED',
    label: 'Streak 14일',
    captionKo: 'Streak 14일.',
    rarity: 'Common',
    requirement: '14-day streak',
    sortOrder: 92,
  ),
  PanelBTitle(
    code: 'PB_DEDICATED',
    label: 'Streak 30일',
    captionKo: 'Streak 30일.',
    rarity: 'Common',
    requirement: '30-day streak',
    sortOrder: 95,
  ),
  PanelBTitle(
    code: 'PB_FRESH_START',
    label: '새해 첫 수업',
    captionKo: '신년 첫 수업 기록 (1/1~1/7).',
    rarity: 'Common',
    requirement: 'session in Jan 1~7',
    sortOrder: 97,
  ),
  PanelBTitle(
    code: 'PB_PHOTO_FINISH',
    label: '기록 공유',
    captionKo: 'SNS 공유 1회.',
    rarity: 'Common',
    requirement: 'shared 1+',
    sortOrder: 99,
  ),

  // ===== Rare (20) =====
  PanelBTitle(
    code: 'PB_TEACHER',
    label: '먼저 묻는 사람',
    captionKo: '코치 노트 10건 발송.',
    rarity: 'Rare',
    requirement: '10 coach notes sent',
    sortOrder: 160,
  ),
  PanelBTitle(
    code: 'PB_STUDENT',
    label: '배우는 사람',
    captionKo: '코치 노트 10건 수령.',
    rarity: 'Rare',
    requirement: '10 coach notes received',
    sortOrder: 170,
  ),
  PanelBTitle(
    code: 'PB_PR_HUNTER',
    label: 'PR 5회',
    captionKo: 'PR 5회 누적.',
    rarity: 'Rare',
    requirement: '5 PRs logged',
    sortOrder: 185,
  ),
  PanelBTitle(
    code: 'PB_PR_MACHINE',
    label: 'PR 10회',
    captionKo: 'PR 10회 누적.',
    rarity: 'Rare',
    requirement: '10 PRs logged',
    sortOrder: 190,
  ),
  PanelBTitle(
    code: 'PB_DOUBLE_DAY',
    label: '하루 두 번',
    captionKo: '하루 2 세션 5회.',
    rarity: 'Rare',
    requirement: '2 sessions/day x5',
    sortOrder: 213,
  ),

  // ===== Epic (10) =====

  // ===== Legendary (5) =====
  // ===== Epic (5) — v3.12 (2026-08-23) 신설 =====
  // 구 Epic·Legendary 15종은 벤치마크·대회 기록 기반이라 전멸했다. 그 자리를
  // 지금 실제로 쌓이는 데이터(수업 누적·Streak·PR·1RM 보드)로 다시 채운다.
  PanelBTitle(
    code: 'PB_LIFT_100',
    label: '세 자리',
    captionKo: '1RM 보드 최고 100kg 달성.',
    rarity: 'Epic',
    requirement: 'best lift 100kg+',
    sortOrder: 300,
  ),
  PanelBTitle(
    code: 'PB_LIFT_VARIETY',
    label: '다섯 가지 리프트',
    captionKo: '1RM 보드에 동작 5종 기록.',
    rarity: 'Epic',
    requirement: '5 lifts on board',
    sortOrder: 310,
  ),
  PanelBTitle(
    code: 'PB_TWO_HUNDRED',
    label: '이백 번의 수업',
    captionKo: '수업 기록 200회 누적.',
    rarity: 'Epic',
    requirement: '200 sessions',
    sortOrder: 320,
  ),
  PanelBTitle(
    code: 'PB_STREAK_60',
    label: 'Streak 60일',
    captionKo: 'Streak 60일.',
    rarity: 'Epic',
    requirement: '60 day streak',
    sortOrder: 330,
  ),
  PanelBTitle(
    code: 'PB_PR_25',
    label: 'PR 25회',
    captionKo: 'PR 25회 누적.',
    rarity: 'Epic',
    requirement: '25 PRs',
    sortOrder: 340,
  ),
  // ===== Legendary (3) =====
  PanelBTitle(
    code: 'PB_LIFT_150',
    label: '백오십',
    captionKo: '1RM 보드 최고 150kg 달성.',
    rarity: 'Legendary',
    requirement: 'best lift 150kg+',
    sortOrder: 400,
  ),
  PanelBTitle(
    code: 'PB_YEAR_ROUND',
    label: '한 해를 채운 사람',
    captionKo: '수업 기록 365회 누적.',
    rarity: 'Legendary',
    requirement: '365 sessions',
    sortOrder: 410,
  ),
  PanelBTitle(
    code: 'PB_STREAK_100',
    label: 'Streak 100일',
    captionKo: 'Streak 100일.',
    rarity: 'Legendary',
    requirement: '100 day streak',
    sortOrder: 420,
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
  // v3.12 (2026-08-23): 1RM 보드에서 오는 신호 2종. 상위 등급(Epic·Legendary)이
  // 전멸한 자리를 **지금 실제로 쌓이는 데이터**로 채우기 위해 신설했다.
  // 소스 = GET /api/v1/gyms/{id}/strength-board (Strength 수업 결과 집계).
  // 동작 이름은 수업 내용에서 파생돼 표기가 흔들리므로 이름으로 판정하지
  // 않는다 — '가장 무겁게 든 무게'와 '기록된 동작 수'만 본다.
  final double maxLiftKg;
  final int liftMovementCount;
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
    this.maxLiftKg = 0,
    this.liftMovementCount = 0,
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
    if (s.hasGym) out.add('PB_BOX_MEMBER');
    if (s.sessionsBefore6am >= 10) out.add('PB_EARLY_BIRD');
    if (s.sessionsAfter10pm >= 10) out.add('PB_NIGHT_OWL');
    if (s.weekendSessions >= 20) out.add('PB_WEEKEND');
    if (s.totalSessions >= 1) out.add('PB_FIRST_WOD');
    if (s.totalSessions >= 10) out.add('PB_TEN_WODS');
    if (s.totalSessions >= 50) out.add('PB_FIFTY_WODS');
    if (s.streakDays >= 7) out.add('PB_WARM_UP');
    if (s.streakDays >= 14) out.add('PB_COMMITTED');
    if (s.streakDays >= 30) out.add('PB_DEDICATED');
    if (s.freshStartSession) out.add('PB_FRESH_START');
    if (s.shareCount >= 1) out.add('PB_PHOTO_FINISH');

    // Rare
    if (s.coachNotesSent >= 10) out.add('PB_TEACHER');
    if (s.coachNotesReceived >= 10) out.add('PB_STUDENT');
    if (s.prCount >= 5) out.add('PB_PR_HUNTER');
    if (s.prCount >= 10) out.add('PB_PR_MACHINE');
    if (s.deadlift1rmKg != null &&
        s.bodyWeightKg != null &&
        s.deadlift1rmKg! >= s.bodyWeightKg! * 2) {
    }
    if (s.pressStrict1rmKg != null &&
        s.bodyWeightKg != null &&
        s.pressStrict1rmKg! >= s.bodyWeightKg!) {
    }
    if (s.burpee100Sec != null && s.burpee100Sec! < 300) {
    }
    if (s.doubleSessionDayCount >= 5) out.add('PB_DOUBLE_DAY');
    // v3.12 — Epic·Legendary. 1RM 보드·누적 기록만 본다 (입력 경로가 살아있는 값).
    if (s.maxLiftKg >= 100) out.add('PB_LIFT_100');
    if (s.liftMovementCount >= 5) out.add('PB_LIFT_VARIETY');
    if (s.totalSessions >= 200) out.add('PB_TWO_HUNDRED');
    if (s.streakDays >= 60) out.add('PB_STREAK_60');
    if (s.prCount >= 25) out.add('PB_PR_25');
    if (s.maxLiftKg >= 150) out.add('PB_LIFT_150');
    if (s.totalSessions >= 365) out.add('PB_YEAR_ROUND');
    if (s.streakDays >= 100) out.add('PB_STREAK_100');

    // Epic
    if (s.deadlift1rmKg != null &&
        s.bodyWeightKg != null &&
        s.deadlift1rmKg! >= s.bodyWeightKg! * 3) {
    }
    if (s.filthyFiftySec != null && s.filthyFiftySec! < 1500) {
    }

    // Legendary
    if (s.murphRxSec != null && s.murphRxSec! < 2400) {
    }
    return out;
  }
}
