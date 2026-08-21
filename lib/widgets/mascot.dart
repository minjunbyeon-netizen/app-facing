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
/// 그 순간 온보딩·스낵바·업적 해금·홈 레벨카드가 **동시에** 살아난다.
/// 화면마다 경로를 적는 순간 이원화이므로, 경로 문자열은 이 파일 밖에 두지 않는다.
enum MascotMood {
  /// 웃는 얼굴 — 잘된 일. 완료 스낵바 · 업적 해금 · 온보딩 첫 인사 · 홈 레벨카드.
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
