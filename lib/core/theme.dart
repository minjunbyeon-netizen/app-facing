import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// facing 디자인 토큰 단일 진원지 (v1.11.0 CrossFit Elite / Dark).
/// 규칙: apps/facing-app/CLAUDE.md "디자인 시스템" 섹션 SSOT.
class FacingTokens {
  FacingTokens._();

  // ---- 기본 팔레트 (다크) ----
  static const Color bg = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  /// v1.14: 모달·바텀시트·로딩 다이얼로그 L2 표면. M3 tonal elevation.
  static const Color surfaceOverlay = Color(0xFF1E1E1E);
  static const Color fg = Color(0xFFF5F5F5);
  /// v1.14: muted 대비 상향 (#8A8A8A=4.9:1 경계 → #9E9E9E=6.1:1 통과 WCAG AA).
  static const Color muted = Color(0xFF9E9E9E);
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFFEE2B2B);
  static const Color accentPressed = Color(0xFFCC2020);

  // ---- 상태 ----
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEE2B2B);
  /// v1.19 페르소나 P2-22: OVERDUE 전용 (warning 활용, accent 와 분리).
  static const Color overdue = Color(0xFFF59E0B);

  // ---- Tier 색상 (v1.15 흑백 재배치) ----
  // 명도: 어두움(Motivation) → 빛(Obsession). RX만 유일한 유채색.
  // v1.15.1 P1-10: Elite↔Games 명도 격차 확대 (E0→C8, FF→F5). Masters 순백 피로 완화.
  static const Color tierScaled = Color(0xFF4A4A4A);  // Motivation
  static const Color tierRx = Color(0xFFEE2B2B);      // Discipline (유일 유채색, 기준선)
  static const Color tierRxPlus = Color(0xFF929292);  // Discipline+
  static const Color tierElite = Color(0xFFC8C8C8);   // Obsession (gap 확대)
  static const Color tierGames = Color(0xFFF5F5F5);   // Obsession (최상위, 순백 회피)

  static const String fontFamily = 'Pretendard';
  /// v1.15 — Bodoni Moda Italic (영문 선언 헤드라인 전용). Google Fonts SIL OFL.
  /// pubspec.yaml에 assets/fonts/BodoniModa/ 번들 필요.
  static const String fontFamilySerif = 'BodoniModa';

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 64,
    fontWeight: FontWeight.w800,
    height: 1.05,
    letterSpacing: -1.6,
    fontFeatures: tabular,
    color: fg,
  );

  /// v1.15.3 신규 — display(64sp) 대비 한 단계 작은 히어로 숫자.
  /// 화면당 1개, 카드 내 display 대체 시 사용 (Trends/Attendance 요약).
  static const TextStyle displayCompact = TextStyle(
    fontFamily: fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w800,
    height: 1.05,
    letterSpacing: -1.4,
    fontFeatures: tabular,
    color: fg,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 44,
    fontWeight: FontWeight.w800,
    height: 1.12,
    letterSpacing: -1.1,
    fontFeatures: tabular,
    color: fg,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.18,
    letterSpacing: -0.6,
    color: fg,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.30,
    letterSpacing: -0.2,
    color: fg,
  );

  static const TextStyle lead = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: fg,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.50,
    color: fg,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: muted,
  );

  /// v1.19 페르소나 P0-8 (M3 윤): 11sp 노안 가독성 부족 → 13sp 상향.
  /// letter-spacing 0.4 유지, 색상·height 동일.
  static const TextStyle micro = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.40,
    letterSpacing: 0.4,
    color: muted,
  );

  /// 티어 배지 전용 라벨. 대문자 tracking (v1.15.3 복원).
  /// 대문자 all-caps는 자간을 넓혀야 덩어리 인상 완화 — HWPO/NOBULL 기준.
  static const TextStyle tierLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: 1.4,
    color: fg,
  );

  /// v1.14.0 신규 — 섹션 구분 라벨 전용. 코드에서 toUpperCase 필수.
  /// micro·caption·inline body.w800을 섹션 헤더로 쓰는 것 금지.
  /// v1.15.3: 대문자 가독성 복원 — 0.2 → 1.2.
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.20,
    letterSpacing: 1.2,
    color: muted,
  );

  /// v1.14.0 신규 — Splash "FACING" 브랜드 로고 전용.
  static const TextStyle brandLogo = TextStyle(
    fontFamily: fontFamily,
    fontSize: 72,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -2.4,
    color: fg,
  );

  /// v1.14.0 신규 — Offline 배너 등 단어 라벨 전용.
  /// v1.15.3: 대문자 가독성 복원 — 0.2 → 1.0.
  static const TextStyle bannerLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 1.0,
    color: fg,
  );

  /// 영어 명언용 serif-ish (Pretendard 유지하되 italic).
  static const TextStyle quote = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    height: 1.50,
    letterSpacing: 0.1,
    color: muted,
  );

  // ---- v1.15 Serif 토큰 (Bodoni Moda Italic, Google Fonts 런타임 fetch) ----
  // 영문 선언 헤드라인·명언 전용. 한글·UI 라벨·숫자는 Pretendard 유지.
  // 주의: const 불가 (GoogleFonts 런타임 resolve). 호출 시점 반환.
  // QA B-LW-5: GoogleFonts 런타임 fetch 실패 시 Pretendard 로 즉시 폴백.
  // 오프라인/검열망/캐시 미스 상황에서 화면 안전 보장 — italic 유지 (Pretendard도 italic 합성).

  static const List<String> _serifFallback = [fontFamily];

  /// Splash "FACING" 세리프 대응 (기존 brandLogo와 교체 가능).
  static TextStyle get brandSerif => GoogleFonts.bodoniModa(
        fontSize: 72,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        height: 1.0,
        letterSpacing: -2.0,
        color: fg,
      ).copyWith(fontFamilyFallback: _serifFallback);

  /// 영문 hero 헤드라인 (Intro 1/2/3, Grade 'Your Tier.' 등).
  static TextStyle get h1Serif => GoogleFonts.bodoniModa(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        height: 1.12,
        letterSpacing: -0.8,
        color: fg,
      ).copyWith(fontFamilyFallback: _serifFallback);

  /// 히어로 숫자 (64sp display) serif 버전. tabular 고정.
  static TextStyle get displaySerif => GoogleFonts.bodoniModa(
        fontSize: 64,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        height: 1.05,
        letterSpacing: -1.2,
        color: fg,
        fontFeatures: tabular,
      ).copyWith(fontFamilyFallback: _serifFallback);

  /// 명언 카드용 serif italic.
  static TextStyle get quoteSerif => GoogleFonts.bodoniModa(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        height: 1.45,
        letterSpacing: 0.2,
        color: fg,
      ).copyWith(fontFamilyFallback: _serifFallback);

  static const double sp1 = 4;
  static const double sp2 = 8;
  static const double sp3 = 12;
  static const double sp4 = 16;
  static const double sp5 = 24;
  static const double sp6 = 32;
  static const double sp7 = 48;
  static const double sp8 = 64;

  static const double r1 = 4;
  static const double r2 = 8;
  static const double r3 = 12;
  static const double r4 = 16;
  /// v1.14: 모달 시트, 전체 화면 카드용 large radius (M3 Shape xl).
  static const double r5 = 28;

  /// v1.14: Material 3 표준(48dp)으로 상향. iOS HIG 44pt 상위 호환.
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
        textStyle: WidgetStateProperty.all(
          FacingTokens.body.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FacingTokens.r3),
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
          FacingTokens.body.copyWith(fontWeight: FontWeight.w700),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FacingTokens.r3),
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
