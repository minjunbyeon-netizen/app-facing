import 'package:flutter/material.dart';

/// facing 디자인 토큰 (HWPO + Strava 하이브리드 — v1.22).
/// 컬러: HWPO 검정 + 탠 액센트 (#B97A4A).
/// 폰트: 이중 모드 — HWPO 임팩트(영혼 숫자 1~2회/화면) + Strava 본문(나머지 전체).
/// 규칙: ~/.claude/reference/{mobile,ux,design}.md + 프로젝트 CLAUDE.md.
class FacingTokens {
  FacingTokens._();

  // ==== 컬러 팔레트 (HWPO 채택, v1.22) ====
  static const Color bg = Color(0xFF0A0A0A);
  /// v1.22: HWPO 톤 살짝 올림 (#141414 → #1A1A1A) — 카드 hierarchy 가독성.
  static const Color surface = Color(0xFF1A1A1A);
  /// v1.22: surface 따라 함께 올림. 모달·바텀시트 L2.
  static const Color surfaceOverlay = Color(0xFF242424);
  static const Color fg = Color(0xFFF5F5F5);
  static const Color muted = Color(0xFF9E9E9E);
  static const Color border = Color(0xFF2A2A2A);

  /// v1.22 메인 변경 — CF Red(#EE2B2B) → HWPO 탠(#B97A4A).
  /// CrossFit 정체성은 tierRx에만 잔류. accent 1색 = brand action 전용.
  static const Color accent = Color(0xFFB97A4A);
  static const Color accentPressed = Color(0xFFA26536);
  /// v1.22 신규 — 탠 어두운 배경 (hover/카드 강조용).
  static const Color accentSoft = Color(0xFF3A2A1F);

  // ==== 상태 ====
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  /// v1.22: error는 CF Red 잔류 (실패 토스트·경고 — 탠과 분리되어야 함).
  static const Color error = Color(0xFFEE2B2B);
  static const Color overdue = Color(0xFFF59E0B);

  // ==== 외부 브랜드 색 (소셜 로그인 전용) ====
  static const Color naverGreen = Color(0xFF03C75A);
  static const Color kakaoYellow = Color(0xFFFEE500);

  // ==== Tier 색상 (흑백 그라데이션 + RX만 유채색) ====
  static const Color tierScaled = Color(0xFF4A4A4A);
  /// CF Red 잔류 — RX 정체성 단일 위치.
  static const Color tierRx = Color(0xFFEE2B2B);
  static const Color tierRxPlus = Color(0xFF929292);
  static const Color tierElite = Color(0xFFC8C8C8);
  static const Color tierGames = Color(0xFFF5F5F5);

  static const String fontFamily = 'Pretendard';
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  // =========================================================
  //   HWPO 임팩트 모드 — 페이지의 "영혼 숫자" 전용
  //   화면당 등장 ≤ 1~2회. 텍스트 X, 숫자/등급명 O.
  //   적용 7곳:
  //     1) Splash "FACING" → brandLogo
  //     2) Home Engine Score 숫자 → display
  //     3) Home Tier 배지 (등급명) → tierLabel
  //     4) Home LEVEL 숫자 → displayCompact
  //     5) Result 총 시간 → display
  //     6) History PR 표시 → pr
  //     7) Onboarding 1RM 결과 → displayCompact
  // =========================================================

  /// HWPO #1 — Engine Score, 총 시간 등 페이지 핵심 숫자.
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 72,
    fontWeight: FontWeight.w900,
    height: 1.0,
    letterSpacing: -2.4,
    fontFeatures: tabular,
    color: fg,
  );

  /// HWPO #2 — Tier 배지 내 숫자, LEVEL 숫자.
  /// display 다음 단계 임팩트 (히어로 보조).
  static const TextStyle displayCompact = TextStyle(
    fontFamily: fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w900,
    height: 1.0,
    letterSpacing: -1.8,
    fontFeatures: tabular,
    color: fg,
  );

  /// HWPO #3 — Splash "FACING" 브랜드 로고 전용.
  static const TextStyle brandLogo = TextStyle(
    fontFamily: fontFamily,
    fontSize: 80,
    fontWeight: FontWeight.w900,
    height: 1.0,
    letterSpacing: -2.8,
    color: fg,
  );

  /// HWPO #4 — Tier 등급명 ALLCAPS ("GAMES" "ELITE").
  /// 코드에서 toUpperCase 필수.
  static const TextStyle tierLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w900,
    height: 1.0,
    letterSpacing: 1.6,
    color: fg,
  );

  /// HWPO #5 — PR 신기록 표시 ("+5kg PR" 등).
  static const TextStyle pr = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -0.4,
    fontFeatures: tabular,
    color: fg,
  );

  // =========================================================
  //   Strava 차분 모드 — 본문 전체
  //   weight w400~w600 위주. 사이즈 모바일 친화 (32/22/17/15).
  // =========================================================

  /// 화면 헤드라인 ("Today's WOD"). Strava 32px/600 등가.
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.18,
    letterSpacing: -0.4,
    color: fg,
  );

  /// 섹션 타이틀.
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.2,
    color: fg,
  );

  /// 카드 타이틀, AppBar title (theme 기본).
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.30,
    letterSpacing: 0,
    color: fg,
  );

  /// Intro body 등 큰 본문.
  static const TextStyle lead = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0.2,
    color: fg,
  );

  /// 본문.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.50,
    letterSpacing: 0.3,
    color: fg,
  );

  /// 부연 설명.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: muted,
  );

  /// 수치 보조 (페이지 작은 메트릭 라벨).
  static const TextStyle micro = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.40,
    letterSpacing: 0.4,
    color: muted,
  );

  /// 섹션 구분 라벨 ALLCAPS. 코드에서 toUpperCase 필수.
  /// v1.22: 11sp/700 → 12sp/600 (Strava 톤 + 1px↑).
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.20,
    letterSpacing: 1.4,
    color: muted,
  );

  /// Offline 등 단어 라벨.
  static const TextStyle bannerLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 1.0,
    color: fg,
  );

  /// 영어 명언용 italic.
  static const TextStyle quote = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    height: 1.50,
    letterSpacing: 0.1,
    color: muted,
  );

  /// micro 강조 변형. 인라인 letterSpacing override 금지 — 이 토큰 사용.
  static const TextStyle microLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.40,
    letterSpacing: 1.2,
    color: muted,
  );

  /// 수식·코드 블록 (RATIONALE 페이싱 공식 등).
  static const TextStyle codeBlock = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: muted,
  );

  // ==== 스페이싱 ====
  static const double sp1 = 4;
  static const double sp2 = 8;
  static const double sp3 = 12;
  static const double sp4 = 16;
  static const double sp5 = 24;
  static const double sp6 = 32;
  static const double sp7 = 48;
  static const double sp8 = 64;

  // ==== 모서리 (v1.22: 버튼만 r4 Strava pill 채택) ====
  static const double r1 = 4;
  static const double r2 = 8;
  static const double r3 = 12;
  static const double r4 = 16;
  /// 모달 시트 등 large radius (M3 Shape xl).
  static const double r5 = 28;

  static const double touchMin = 48;
  static const double buttonH = 52;
  static const double appBarH = 52;
}

class FacingTheme {
  FacingTheme._();

  static ThemeData get light => dark; // 라이트 모드 미지원. alias.

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: FacingTokens.bg,
    colorScheme: const ColorScheme.dark(
      surface: FacingTokens.bg,
      onSurface: FacingTokens.fg,
      surfaceContainerHighest: FacingTokens.surface,
      primary: FacingTokens.accent,
      onPrimary: FacingTokens.fg,
      secondary: FacingTokens.fg,
      onSecondary: FacingTokens.bg,
      outline: FacingTokens.border,
      onSurfaceVariant: FacingTokens.muted,
      error: FacingTokens.error,
      onError: FacingTokens.fg,
    ),
    fontFamily: FacingTokens.fontFamily,
    textTheme: const TextTheme(
      displayLarge: FacingTokens.display,
      headlineLarge: FacingTokens.h1,
      headlineMedium: FacingTokens.h2,
      headlineSmall: FacingTokens.h3,
      titleLarge: FacingTokens.lead,
      bodyMedium: FacingTokens.body,
      labelMedium: FacingTokens.caption,
      labelSmall: FacingTokens.micro,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: FacingTokens.bg,
      foregroundColor: FacingTokens.fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: FacingTokens.appBarH,
      titleTextStyle: FacingTokens.h3,
      shape: Border(
        bottom: BorderSide(color: FacingTokens.border, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(
          const Size(double.infinity, FacingTokens.buttonH),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return FacingTokens.border;
          if (states.contains(WidgetState.pressed)) return FacingTokens.accentPressed;
          return FacingTokens.accent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return FacingTokens.muted;
          return FacingTokens.fg;
        }),
        // v1.22: Strava sentence-case 톤 — w600 + letterSpacing 0.
        textStyle: WidgetStateProperty.all(
          FacingTokens.body.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        // v1.22: r3 → r4 (Strava pill).
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FacingTokens.r4),
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: FacingTokens.sp5,
            vertical: FacingTokens.sp4,
          ),
        ),
        elevation: WidgetStateProperty.all(0),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(
          const Size(double.infinity, FacingTokens.buttonH),
        ),
        foregroundColor: WidgetStateProperty.all(FacingTokens.fg),
        side: WidgetStateProperty.all(
          const BorderSide(color: FacingTokens.border, width: 1),
        ),
        textStyle: WidgetStateProperty.all(
          FacingTokens.body.copyWith(fontWeight: FontWeight.w600),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FacingTokens.r4),
          ),
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: FacingTokens.border,
      thickness: 1,
      space: 0,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
