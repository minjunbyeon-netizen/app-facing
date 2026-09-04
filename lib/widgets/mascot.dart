import 'package:flutter/material.dart';

/// HYPHEN 마스코트 SSOT — "캐릭터가 어디에 어떤 표정으로 나오는가" 의 단일 진원지.
///
/// 위치 근거: 브랜드 로고 SSOT(`brand_logo.dart`) 와 같은 층위다.
/// appkit(`tools/appkit`) 에는 넣지 않는다 — 거기는 workcheck·writeplz 까지
/// 상속하는 3앱 공통 조상이고, 마스코트는 HYPHEN 전용 브랜드 자산이다.
///
/// **표정은 딱 3종이고 전 화면이 돌려 쓴다** (2026-08-21 사용자 결정).
/// 화면마다 전용 그림을 두면 그림 수가 화면 수만큼 늘고, 하나를 바꿀 때
/// 어디까지 바꿔야 하는지 알 수 없게 된다. 성격(잘됨·안됨·중립)에만 대응시킨다.
///
/// 캐릭터는 **사용자가 직접 지정·허용한 것만** `assets/character/` 에 들어간다
/// (규칙·파일명 표 = 그 폴더의 README.md). Claude 가 캐릭터를 만들지 않는다.
///
/// **그림이 도착하기 전까지 모든 슬롯은 아무것도 그리지 않는다** — 자리도
/// 차지하지 않으므로(SizedBox.shrink) 지금 화면은 예전 그대로다.
/// 도착하면 할 일은 두 줄뿐이다:
///   1. `pubspec.yaml` 의 `- assets/character/` 주석 해제
///   2. 아래 [_assets] 맵 채우기
/// **적용 범위 = 스낵바뿐이다** (2026-08-21 사용자 지시 "딱 스낵바부분만").
/// 온보딩·홈 레벨 옆 그림은 별도 그림을 받아 나중에 붙인다 — 그때 mood 를
/// 추가하고 그 그림을 물린다. 지금 3장을 그 자리에 돌려 쓰지 않는다.
/// 화면마다 경로를 적는 순간 이원화이므로, 경로 문자열은 이 파일 밖에 두지 않는다.
enum MascotMood {
  /// 웃는 얼굴 — 잘된 일. 완료 스낵바 · 업적 해금 알림(스낵바).
  happy,

  /// 우는 얼굴 — 안된 일. 실패 스낵바 전용.
  sad,

  /// 담담한 얼굴 — 잘잘못이 아닌 상태 안내. 안내 스낵바.
  neutral,
}

class HyphenMascot extends StatelessWidget {
  /// 어떤 성격의 표정인지.
  final MascotMood mood;

  /// 정사각 기준 한 변. 슬롯마다 다르게 준다 (온보딩 크게, 스낵바 작게).
  final double size;

  const HyphenMascot({super.key, required this.mood, this.size = 88});

  // ── 에셋 매핑 (단일 진원지) ────────────────────────────────────────────
  // 지금은 비어 있다 = 캐릭터 미도착. 채우는 순간 전 슬롯이 켜진다.
  static const Map<MascotMood, String> _assets = {
    MascotMood.happy: 'assets/character/happy.png',
    MascotMood.sad: 'assets/character/sad.png',
    MascotMood.neutral: 'assets/character/neutral.png',
  };

  /// mood → 에셋 경로. 없으면 null (= 아직 캐릭터 없음).
  static String? assetFor(MascotMood mood) => _assets[mood];

  /// 이 표정의 그림이 준비됐는지. 호출부는 이 값으로 "슬롯을 열지 말지"를
  /// 판단한다 (여백·테두리까지 같이 접으려면 필요).
  static bool has(MascotMood mood) => _assets.containsKey(mood);

  @override
  Widget build(BuildContext context) {
    final path = _assets[mood];
    if (path == null) return const SizedBox.shrink();
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // 파일이 빠졌을 때 화면이 깨지는 대신 조용히 접힌다.
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}

/// 스플래시 등장 연출용 전신 액션. 스낵바 표정([MascotMood])과 별개다 —
/// 저쪽은 "성격 3종을 전 화면이 돌려 쓴다", 이쪽은 "한 번에 다 나오는 한 벌"이다.
/// 값·순서 정본 = `docs/SPLASH-INTRO-HANDOFF.md` (2026-08-21 대표 확정).
enum HypeeAction {
  hesitate,
  stretch,
  jumprope,
  kettlebell,
  battlerope,
  wallball,
  boxjump,
  rest,
  scale,
  thumbsup,
  cheer,
}

class HypeeActions {
  const HypeeActions._();

  /// 등장 순서 = 운동 하루의 흐름 (망설임 → 준비 → 운동 → 휴식 → 결과 → 환호).
  /// 마지막 cheer 가 카드 덱 맨 앞에 선다 — 순서를 바꾸면 이야기가 깨진다.
  static const List<HypeeAction> introSequence = [
    HypeeAction.hesitate,
    HypeeAction.stretch,
    HypeeAction.jumprope,
    HypeeAction.kettlebell,
    HypeeAction.battlerope,
    HypeeAction.wallball,
    HypeeAction.boxjump,
    HypeeAction.rest,
    HypeeAction.scale,
    HypeeAction.thumbsup,
    HypeeAction.cheer,
  ];

  static const Map<HypeeAction, String> _assets = {
    HypeeAction.hesitate: 'assets/character/action/hypee_hesitate.webp',
    HypeeAction.stretch: 'assets/character/action/hypee_stretch.webp',
    HypeeAction.jumprope: 'assets/character/action/hypee_jumprope.webp',
    HypeeAction.kettlebell: 'assets/character/action/hypee_kettlebell.webp',
    HypeeAction.battlerope: 'assets/character/action/hypee_battlerope.webp',
    HypeeAction.wallball: 'assets/character/action/hypee_wallball.webp',
    HypeeAction.boxjump: 'assets/character/action/hypee_boxjump.webp',
    HypeeAction.rest: 'assets/character/action/hypee_rest.webp',
    HypeeAction.scale: 'assets/character/action/hypee_scale.webp',
    HypeeAction.thumbsup: 'assets/character/action/hypee_thumbsup.webp',
    HypeeAction.cheer: 'assets/character/action/hypee_cheer.webp',
  };

  static String assetFor(HypeeAction a) => _assets[a]!;

  /// 그림이 실제로 번들에 들어왔는지 (에셋 누락 시 연출을 통째로 접는 판단용).
  static bool get ready => _assets.length == HypeeAction.values.length;
}

/// 마감·인사용 전신 컷 (2026-09-04 도착). [HypeeAction] 과도 [MascotMood] 와도 별개다.
///
/// 왜 따로 두는가 — 액션 11종은 **스플래시에서 한 번에 다 나오는 한 벌**이라
/// 여기에 인사 컷을 섞으면 등장 순서가 곧 이야기인 연출이 깨진다([HypeeActions.introSequence]).
/// 표정 3종은 스낵바 아이콘(32px)이라 전신 컷을 그 자리에 넣을 수 없다.
/// 이쪽은 **필요한 화면이 한 장씩 골라 쓰는** 낱개 세트다.
///
/// 정본 그림·설정집 = `C:/dev/services/design/_작업/앱에셋` (여기 있는 건 사본).
/// 고칠 일은 항상 그쪽에서 하고 떨군다 — 이 앱 안에서 이미지를 편집하지 않는다.
enum HypeeGreeting {
  /// 꾸벅 인사 — 가입 감사 · 결제 완료 · 마무리 인사.
  bow,

  /// 손 흔들기 — 배웅 · 로그아웃 · 다음에 또.
  wave,

  /// 두 손 모아 — 감사 · 부탁 · 리뷰 요청.
  thanks,

  /// 머리 위 하트 — 고마움 · 즐겨찾기 · 추천.
  heart,

  /// 두 팔 엑스 — 마감 · 종료 · 모집 완료.
  cross,

  /// 머리 긁적 — 아쉬움 · 미안 · 빈 결과.
  sheepish,
}

class HypeeGreetings {
  const HypeeGreetings._();

  static const Map<HypeeGreeting, String> _assets = {
    HypeeGreeting.bow: 'assets/character/greeting/hypee_bow.webp',
    HypeeGreeting.wave: 'assets/character/greeting/hypee_wave.webp',
    HypeeGreeting.thanks: 'assets/character/greeting/hypee_thanks.webp',
    HypeeGreeting.heart: 'assets/character/greeting/hypee_heart.webp',
    HypeeGreeting.cross: 'assets/character/greeting/hypee_cross.webp',
    HypeeGreeting.sheepish: 'assets/character/greeting/hypee_sheepish.webp',
  };

  static String assetFor(HypeeGreeting g) => _assets[g]!;

  static bool get ready => _assets.length == HypeeGreeting.values.length;
}

/// 마감·인사 컷 한 장을 그린다. 전신이라 **높이**를 기준으로 잡는다 —
/// 컷마다 가로폭이 달라(`cross` 가 가장 좁고 `wave` 가 가장 넓다) 정사각으로 가두면
/// 어떤 컷은 여백만 남고 어떤 컷은 잘린다.
///
/// 1배율 원본이 높이 320이므로 그 이하로 쓰는 것이 기본이다.
class HypeeGreetingImage extends StatelessWidget {
  final HypeeGreeting greeting;

  /// 그림 높이(dp). 가로는 원본 비율대로 따라온다.
  final double height;

  const HypeeGreetingImage({
    super.key,
    required this.greeting,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      HypeeGreetings.assetFor(greeting),
      height: height,
      fit: BoxFit.contain,
      // 파일이 빠졌을 때 화면이 깨지는 대신 조용히 접힌다 ([HyphenMascot] 과 같은 규약).
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
