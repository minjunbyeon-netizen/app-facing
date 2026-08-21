import 'package:flutter/material.dart';

/// HYPHEN 마스코트 SSOT — "캐릭터가 어디에 어떤 표정으로 나오는가" 의 단일 진원지.
///
/// 위치 근거: 브랜드 로고 SSOT(`brand_logo.dart`) 와 같은 층위다.
/// appkit(`tools/appkit`) 에는 넣지 않는다 — 거기는 workcheck·writeplz 까지
/// 상속하는 3앱 공통 조상이고, 마스코트는 HYPHEN 전용 브랜드 자산이다.
///
/// 2026-08-21 사용자 지시: 구 `mascot.png`(헬스장 사진이 배경에 박힌 1종) 폐기.
/// 캐릭터는 **사용자가 직접 지정·허용한 것만** `assets/character/` 에 들어간다
/// (규칙·파일명 표 = 그 폴더의 README.md). Claude 가 캐릭터를 만들지 않는다.
/// **새 캐릭터 에셋이 도착하기 전까지 모든 슬롯은 아무것도 그리지 않는다** —
/// 자리도 차지하지 않으므로(SizedBox.shrink) 지금 화면은 예전 그대로다.
///
/// 에셋이 오면 할 일은 두 줄뿐이다:
///   1. `pubspec.yaml` 의 `- assets/character/` 주석 해제
///   2. 아래 [_assets] 맵 채우기
/// 그 순간 온보딩·스낵바·업적 해금·홈 레벨카드가 **동시에** 살아난다.
/// 화면마다 경로를 적는 순간 이원화이므로, 경로 문자열은 이 파일 밖에 두지 않는다.
enum MascotMood {
  /// 온보딩 — 처음 맞이하는 인사.
  welcome,

  /// 업적 해금 — 축하.
  celebrate,

  /// 스낵바 — 저장·완료 등 격려성 알림.
  cheer,

  /// 홈 레벨 카드 — 레벨대별 진화. [HyphenMascot.level] 을 함께 넘긴다.
  level,
}

class HyphenMascot extends StatelessWidget {
  /// 어떤 상황의 표정인지.
  final MascotMood mood;

  /// [MascotMood.level] 일 때만 쓰는 회원 레벨. 다른 mood 에선 무시된다.
  final int? level;

  /// 정사각 기준 한 변. 슬롯마다 다르게 준다 (온보딩 크게, 스낵바 작게).
  final double size;

  const HyphenMascot({
    super.key,
    required this.mood,
    this.level,
    this.size = 88,
  });

  // ── 에셋 매핑 (단일 진원지) ────────────────────────────────────────────
  // key 규칙: welcome · celebrate · cheer · level1~level5.
  // 지금은 비어 있다 = 캐릭터 미도착. 채우는 순간 전 슬롯이 켜진다.
  static const Map<String, String> _assets = {
    // 'welcome':   'assets/character/welcome.png',
    // 'celebrate': 'assets/character/celebrate.png',
    // 'cheer':     'assets/character/cheer.png',
    // 'level1':    'assets/character/level1.png',
    // 'level2':    'assets/character/level2.png',
    // 'level3':    'assets/character/level3.png',
    // 'level4':    'assets/character/level4.png',
    // 'level5':    'assets/character/level5.png',
  };

  /// 레벨 → 진화 단계(1~5). 구 home_screen 의 private `_mascotForLevel` 이
  /// 쓰던 경계(11·21·31·41)를 그대로 가져왔다 — 경계 숫자는 여기에만 있다.
  static int tierOfLevel(int level) {
    if (level >= 41) return 5;
    if (level >= 31) return 4;
    if (level >= 21) return 3;
    if (level >= 11) return 2;
    return 1;
  }

  /// mood(+level) → 에셋 경로. 없으면 null (= 아직 캐릭터 없음).
  static String? assetFor(MascotMood mood, {int? level}) {
    final key = mood == MascotMood.level
        ? 'level${tierOfLevel(level ?? 1)}'
        : mood.name;
    return _assets[key];
  }

  /// 캐릭터 에셋이 하나라도 준비됐는지. 호출부가 "슬롯을 열지 말지"를
  /// 이 값으로 판단한다 (여백·구분선까지 같이 접으려면 필요).
  static bool has(MascotMood mood, {int? level}) =>
      assetFor(mood, level: level) != null;

  @override
  Widget build(BuildContext context) {
    final path = assetFor(mood, level: level);
    if (path == null) return const SizedBox.shrink();
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // 에셋 파일이 빠졌을 때 화면이 깨지는 대신 조용히 접힌다.
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
