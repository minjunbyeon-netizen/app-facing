import 'package:flutter/material.dart';
import 'dart:ui';

/// facing 디자인 토큰 단일 진원지 (v1.11.0 CrossFit Elite / Dark).
/// 규칙: apps/facing-app/CLAUDE.md "디자인 시스템" 섹션 SSOT.
class FacingTokens {
  FacingTokens._();

  // ---- 기본 팔레트 (다크) ----
  static const Color bg = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color fg = Color(0xFFF5F5F5);
  static const Color muted = Color(0xFF8A8A8A);
  static const Color border = Color(0xFF2A2A2A);
  static const Color accent = Color(0xFFEE2B2B);
  static const Color accentPressed = Color(0xFFCC2020);

  // ---- 상태 ----
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEE2B2B);

  // ---- Tier 색상 (Scaled < RX < RX+ < Elite < Games) ----
  static const Color tierScaled = Color(0xFF5A5A5A);
  static const Color tierRx = Color(0xFFEE2B2B);
  static const Color tierRxPlus = Color(0xFFFF6B00);
  static const Color tierElite = Color(0xFFC8A84B);
  static const Color tierGames = Color(0xFFE8E8E8);

  static const String fontFamily = 'Pretendard';

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

  static const TextStyle micro = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.40,
    letterSpacing: 0.4,
    color: muted,
  );

  /// 티어 배지 전용 라벨. 대문자 tracking.
  static const TextStyle tierLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: 1.8,
    color: fg,
  );

  /// v1.14.0 신규 — 섹션 구분 라벨 전용. 코드에서 toUpperCase 필수.
  /// micro·caption·inline body.w800을 섹션 헤더로 쓰는 것 금지.
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.20,
    letterSpacing: 1.6,
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
  static const TextStyle bannerLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 1.2,
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

  static const double touchMin = 44;
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
