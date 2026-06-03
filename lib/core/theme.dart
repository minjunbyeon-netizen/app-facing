import 'package:flutter/material.dart';

/// facing 디자인 토큰 (v2.0.0 — 라이트 톤 전면 개편, PC facing-admin 팔레트 통합).
/// 컬러: 라이트 배경 + CrossFit red 액센트 (WCAG AA 보장).
/// 폰트: 이중 모드 — HWPO 임팩트(영혼 숫자 1~2회/화면) + Strava 본문(나머지 전체).
/// 규칙: ~/.claude/reference/{mobile,ux,design}.md + 프로젝트 CLAUDE.md.
///
/// v2.0.0 BREAKING — 라이트 톤 전환 (2026-05-24):
///   - bg #0A0A0A → #FAFAFA, surface 흑색 → 흰색
///   - fg #FFFFFF → #18181B (검정 텍스트)
///   - HWPO/NOBULL 강한 톤은 weight + uppercase + letterSpacing으로 유지
///   - 다크 대비 잃지 않도록 tierRx #EE2B2B → #CC1F1F (라이트 배경 4.5:1)
class FacingTokens {
  FacingTokens._();

  // ==== 컬러 팔레트 (v2.0.0 라이트 — PC facing-admin 동기화) ====
  /// 기본 배경 (라이트).
  static const Color bg = Color(0xFFFAFAFA);
  /// 카드·시트 배경 (순백).
  static const Color surface = Color(0xFFFFFFFF);
  /// 카드 보조 표면 (intro·hover 기반).
  static const Color surfaceAlt = Color(0xFFF5F5F5);
  /// hover/pressed 상태 표면.
  static const Color surfaceHover = Color(0xFFF0F0F0);
  /// 호환 alias — surfaceAlt 사용 권장.
  static const Color surfaceHigh = surfaceAlt;
  static const Color surfaceMax = surfaceHover;
  /// @deprecated v2.1에서 제거 — surfaceAlt 사용.
  static const Color surfaceOverlay = surfaceAlt;

  /// 본문 텍스트 (zinc-900).
  static const Color fg = Color(0xFF18181B);
  /// 보조 텍스트 (zinc-600).
  static const Color fgSecondary = Color(0xFF52525B);
  /// 흐린 텍스트 (zinc-500).
  static const Color muted = Color(0xFF71717A);
  /// 더 강한 muted (zinc-700).
  static const Color mutedStrong = Color(0xFF3F3F46);
  /// 구분선 (zinc-200).
  static const Color border = Color(0xFFE4E4E7);
  /// 강조 구분선 (zinc-300).
  static const Color borderStrong = Color(0xFFD4D4D8);

  /// v2.0: accent = primary CrossFit red 통합.
  /// @deprecated v2.1에서 제거 — primary 사용.
  static const Color accent = Color(0xFFEE2B2B);
  static const Color accentPressed = Color(0xFFB91C1C);
  /// 탠 어두운 배경 → 라이트에서 #FEF2F2 (red-50) 으로 대체.
  static const Color accentSoft = Color(0xFFFEF2F2);

  // ==== 액센트 4색 ====
  /// CrossFit Red — 기본 CTA·강조.
  static const Color primary = Color(0xFFEE2B2B);
  static const Color primaryPressed = Color(0xFFB91C1C);
  /// v2.0 신규 — primary/danger 등 컬러 배경 위 텍스트 (항상 흰색).
  /// 라이트 톤 전환 시 fg(=검정) 사용하면 콘트라스트 미달 → 이 토큰 사용 강제.
  static const Color onColor = Color(0xFFFFFFFF);
  /// PR 달성·성공. emerald-500.
  static const Color success = Color(0xFF10B981);
  /// 만료 임박·주의. amber-500.
  static const Color warning = Color(0xFFF59E0B);
  /// 정보·툴팁·링크. blue-500.
  static const Color info = Color(0xFF3B82F6);
  /// 해지·에러. red-600.
  static const Color danger = Color(0xFFDC2626);

  /// @deprecated v2.1에서 제거 — danger 사용.
  static const Color error = danger;
  /// @deprecated v2.1에서 제거 — warning 사용.
  static const Color overdue = warning;

  // ==== 외부 브랜드 색 (소셜 로그인 전용) ====
  static const Color naverGreen = Color(0xFF03C75A);
  static const Color kakaoYellow = Color(0xFFFEE500);
  /// Google 버튼 — 흰 배경 + 어두운 텍스트 (Google 브랜드 가이드). G 마크 파랑.
  static const Color googleSurface = Color(0xFFFFFFFF);
  static const Color googleBlue = Color(0xFF4285F4);

  // ==== Tier 색상 (라이트 배경에서 WCAG AA, PC facing-admin 동기화) ====
  /// Scaled — neutral zinc-600.
  static const Color tierScaled = Color(0xFF52525B);
  /// RX — CrossFit red 어둡게 (라이트 배경 4.5:1).
  static const Color tierRx = Color(0xFFCC1F1F);
  /// RX+ — orange-700.
  static const Color tierRxPlus = Color(0xFFC05000);
  /// Elite — amber-700 (gold tone darker).
  static const Color tierElite = Color(0xFF92700A);
  /// Games — neutral gray darker.
  static const Color tierGames = Color(0xFF606060);

  static const String fontFamily = 'Pretendard';
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  // =========================================================
  //   HWPO 임팩트 모드 — 페이지의 "영혼 숫자" 전용
  //   화면당 등장 ≤ 1~2회. 텍스트 X, 숫자/등급명 O.
  //   v2.0: 검정 텍스트 (fg=#18181B). weight·letterSpacing 으로 임팩트 유지.
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

  /// HWPO #4 — Tier 등급명 ALLCAPS.
  static const TextStyle tierLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w900,
    height: 1.0,
    letterSpacing: 1.6,
    color: fg,
  );

  /// HWPO #5 — PR 신기록 표시.
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
  // =========================================================

  /// 화면 헤드라인.
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

  /// 수치 보조.
  static const TextStyle micro = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.40,
    letterSpacing: 0.4,
    color: muted,
  );

  /// 섹션 구분 라벨 ALLCAPS. 코드에서 toUpperCase 필수.
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

  /// micro 강조 변형.
  static const TextStyle microLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.40,
    letterSpacing: 1.2,
    color: muted,
  );

  /// 수식·코드 블록.
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

  // ==== 모서리 ====
  static const double r1 = 4;
  static const double r2 = 8;
  static const double r3 = 12;
  static const double r4 = 16;
  static const double r5 = 28;

  static const double touchMin = 48;
  static const double buttonH = 52;
  static const double appBarH = 52;
}

class FacingTheme {
  FacingTheme._();

  /// v2.0: dark 는 light alias (라이트 톤 전면 전환).
  static ThemeData get dark => light;

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: FacingTokens.bg,
    colorScheme: const ColorScheme.light(
      surface: FacingTokens.surface,
      onSurface: FacingTokens.fg,
      surfaceContainer: FacingTokens.surface,
      surfaceContainerHigh: FacingTokens.surfaceAlt,
      surfaceContainerHighest: FacingTokens.surfaceHover,
      primary: FacingTokens.primary,
      onPrimary: Color(0xFFFFFFFF),
      secondary: FacingTokens.primary,
      onSecondary: Color(0xFFFFFFFF),
      tertiary: FacingTokens.info,
      onTertiary: Color(0xFFFFFFFF),
      outline: FacingTokens.border,
      outlineVariant: FacingTokens.borderStrong,
      onSurfaceVariant: FacingTokens.muted,
      error: FacingTokens.danger,
      onError: Color(0xFFFFFFFF),
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
          if (states.contains(WidgetState.disabled)) return FacingTokens.surfaceHover;
          if (states.contains(WidgetState.pressed)) return FacingTokens.primaryPressed;
          return FacingTokens.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return FacingTokens.muted;
          return const Color(0xFFFFFFFF);
        }),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            fontFamily: FacingTokens.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            height: 1.50,
            color: Color(0xFFFFFFFF),
          ),
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
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
          const BorderSide(color: FacingTokens.borderStrong, width: 1),
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
    cardTheme: CardThemeData(
      color: FacingTokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      // 라이트 단일 box-shadow (design-block.md 다중 금지).
      shadowColor: const Color(0x14000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FacingTokens.r3),
        side: const BorderSide(color: FacingTokens.border, width: 1),
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
