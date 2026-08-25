// GENERATED — mapping/achievement_pictogram_map.json 이 정본.
// 손으로 고치지 말고 JSON 을 고친 뒤 `python src/build_dart.py` 를 다시 돌리십시오.
//
// 쓰는 법 (3줄):
//   final shape = HyphenPictogram.shapeFor(catalog.code);
//   final asset = HyphenPictogram.assetFor(catalog.code, locked: !unlocked);
//   AchievementBadge(code: catalog.code, rarity: catalog.rarity, size: 56, locked: !unlocked)
//
// pubspec.yaml 에 아래가 이미 있어야 합니다 (flutter_svg 는 이미 선언돼 있음):
//   flutter:
//     assets:
//       - assets/pictograms/

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 인증 방식 3분류. 등급이 아니라 "어떻게 따는가" 다 — 서열 없음.
enum PictoShape {
  /// 자동 집계 — 서버가 세기만 하면 되는 것 (출석·누적·시즌·이스터에그)
  circle,

  /// 기록 대조 — 이전 기록·점수와 비교해야 판정되는 것 (PR·Engine·Tier·카테고리)
  squircle,

  /// 사람 판정 — 코치/운영이 확인해야 하는 것 (벤치마크 WOD 완주)
  shield,
}

/// 희귀도 팔레트. 앱의 기존 rarity 문자열(Common/Rare/Epic/Legendary)을 그대로 받는다.
@immutable
class RarityPalette {
  const RarityPalette({
    required this.ko,
    required this.plate,
    required this.border,
    required this.lip,
    required this.light,
    required this.dark,
    required this.text,
  });

  /// 한글 표기 — 색맹 대비용 텍스트 라벨. 색만으로 등급을 표시하면 안 된다(WCAG).
  final String ko;

  /// 판 바탕
  final Color plate;

  /// 판 테두리
  final Color border;

  /// 판 아래 두께감 (3px 아래로 깔리는 면)
  final Color lip;

  /// 아이콘 밝은 면
  final Color light;

  /// 아이콘 그늘 면
  final Color dark;

  /// 라벨 글자색
  final Color text;

  static const Map<String, RarityPalette> byName = {
    'Common': RarityPalette(
      ko: '일반',
      plate: Color(0xFFF4F4F5),
      border: Color(0xFFDEDEE2),
      lip: Color(0xFFD6D6DB),
      light: Color(0xFF8E96A3),
      dark: Color(0xFF5B6270),
      text: Color(0xFF71717A),
    ),
    'Rare': RarityPalette(
      ko: '희귀',
      plate: Color(0xFFFDECEC),
      border: Color(0xFFF2C4C4),
      lip: Color(0xFFEDBFBF),
      light: Color(0xFFD93B3B),
      dark: Color(0xFF8E1D1C),
      text: Color(0xFFCC1F1F),
    ),
    'Epic': RarityPalette(
      ko: '에픽',
      plate: Color(0xFFFBF3DE),
      border: Color(0xFFE8D5A0),
      lip: Color(0xFFE0CB96),
      light: Color(0xFFC08F14),
      dark: Color(0xFF77590A),
      text: Color(0xFF92700A),
    ),
    'Legendary': RarityPalette(
      ko: '전설',
      plate: Color(0xFF1C1C1F),
      border: Color(0xFF3E3E46),
      lip: Color(0xFF0E0E10),
      light: Color(0xFFEBC65F),
      dark: Color(0xFFA07A1B),
      text: Color(0xFF1C1C1F),
    ),
  };

  static RarityPalette of(String rarity) => byName[rarity] ?? byName['Common']!;

  /// 잠긴 배지 — 채도를 뺀 회색 판.
  static const RarityPalette locked = RarityPalette(
    ko: '잠김',
    plate: Color(0xFFFAFAFA),
    border: Color(0xFFE4E4E7),
    lip: Color(0xFFEFEFF1),
    light: Color(0xFFC4C4CB),
    dark: Color(0xFFA1A1AA),
    text: Color(0xFFA1A1AA),
  );
}

/// 업적 코드 → 픽토그램 파일 + 판 모양.
class HyphenPictogram {
  const HyphenPictogram._();

  static const String basePath = 'assets/pictograms/';

  /// SVG 파일에 박혀 있는 두 색. ColorMapper 가 이 값을 찾아서 치환한다.
  static const Color sentinelLight = Color(0xFF8E96A3);
  static const Color sentinelDark = Color(0xFF5B6270);

  static const Map<String, String> _icon = {
    'FIRST_ENGINE': 'bolt',
    'REACH_SCALED': 'arrow-up',
    'REACH_INTERMEDIATE': 'chart-up',
    'REACH_RX': 'medal',
    'REACH_RX_PLUS': 'ribbon',
    'REACH_ELITE': 'trophy',
    'REACH_GAMES': 'crown',
    'SCORE_50_OVERALL': 'battery',
    'SCORE_60_OVERALL': 'target',
    'SCORE_70_OVERALL': 'mountain',
    'SCORE_80_OVERALL': 'star',
    'SCORE_90_OVERALL': 'certificate',
    'SCORE_95_OVERALL': 'crown',
    'ALL_CAT_60': 'athlete',
    'ALL_CAT_80': 'athlete',
    'HOLY_TRINITY': 'podium',
    'VOL_EQUAL': 'band',
    'CAT_POWER_RX': 'barbell',
    'CAT_OLYMPIC_RX': 'plate',
    'CAT_GYMN_RX': 'rings',
    'CAT_CARDIO_RX': 'heart',
    'CAT_METCON_RX': 'flame',
    'CAT_BODY_RX': 'muscle',
    'PR_FIRST': 'stopwatch',
    'PR_HUNTER': 'chart-up',
    'PR_25': 'arrow-up',
    'PR_LIFT_KING': 'barbell',
    'PR_ENGINE': 'bike',
    'PR_DEADLIFT_2X': 'plate',
    'PR_SQUAT_2X': 'kettlebell',
    'PR_SNATCH_BW': 'dumbbell',
    'PR_BODY_IRON': 'muscle',
    'TITLE_SCHOLAR': 'chart-up',
    'TITLE_UNDEFEATED': 'target',
    'TITLE_POLYMATH': 'athlete',
    'WOD_10': 'check-in',
    'WOD_25': 'calendar-check',
    'WOD_50': 'stamp',
    'WOD_75': 'stamp',
    'VOL_100_WODS': 'certificate',
    'VOL_200_WODS': 'certificate',
    'STREAK_3': 'flame',
    'STREAK_7': 'flame',
    'STREAK_10': 'flame',
    'STREAK_30': 'calendar',
    'STREAK_60': 'calendar',
    'STREAK_90': 'hourglass',
    'TITLE_RELENTLESS': 'flame',
    'TITLE_OBSESSED': 'hourglass',
    'VOL_TRIPLE_STREAK': 'calendar-check',
    'VOL_COMEBACK': 'sunrise',
    'VOL_COMEBACK_60': 'sunrise',
    'SEASON_SPRING': 'sunrise',
    'SEASON_SUMMER': 'bolt',
    'SEASON_FALL': 'mountain',
    'SEASON_WINTER': 'moon',
    'SEASON_YEAREND': 'bell',
    'CF_OPEN_SURVIVOR': 'flag',
    'CF_QUARTERFINAL_GRINDER': 'route',
    'CF_SEMIFINAL_WATCH': 'camera',
    'EGG_WITCHING': 'moon',
    'EGG_DOOMSDAY': 'alarm',
    'EGG_SUNDAY': 'clock',
    'EGG_PI': 'coin',
    'EGG_TRIPLE': 'rings',
    'GIRLS_5_COMPLETE': 'ribbon',
    'GIRLS_ALL': 'crown',
    'HEROES_3': 'flag',
    'HEROES_5': 'medal',
    'GAMES_1': 'finish',
  };

  static const Map<String, PictoShape> _shape = {
    'FIRST_ENGINE': PictoShape.squircle,
    'REACH_SCALED': PictoShape.squircle,
    'REACH_INTERMEDIATE': PictoShape.squircle,
    'REACH_RX': PictoShape.squircle,
    'REACH_RX_PLUS': PictoShape.squircle,
    'REACH_ELITE': PictoShape.squircle,
    'REACH_GAMES': PictoShape.squircle,
    'SCORE_50_OVERALL': PictoShape.squircle,
    'SCORE_60_OVERALL': PictoShape.squircle,
    'SCORE_70_OVERALL': PictoShape.squircle,
    'SCORE_80_OVERALL': PictoShape.squircle,
    'SCORE_90_OVERALL': PictoShape.squircle,
    'SCORE_95_OVERALL': PictoShape.squircle,
    'ALL_CAT_60': PictoShape.squircle,
    'ALL_CAT_80': PictoShape.squircle,
    'HOLY_TRINITY': PictoShape.squircle,
    'VOL_EQUAL': PictoShape.squircle,
    'CAT_POWER_RX': PictoShape.squircle,
    'CAT_OLYMPIC_RX': PictoShape.squircle,
    'CAT_GYMN_RX': PictoShape.squircle,
    'CAT_CARDIO_RX': PictoShape.squircle,
    'CAT_METCON_RX': PictoShape.squircle,
    'CAT_BODY_RX': PictoShape.squircle,
    'PR_FIRST': PictoShape.squircle,
    'PR_HUNTER': PictoShape.squircle,
    'PR_25': PictoShape.squircle,
    'PR_LIFT_KING': PictoShape.squircle,
    'PR_ENGINE': PictoShape.squircle,
    'PR_DEADLIFT_2X': PictoShape.squircle,
    'PR_SQUAT_2X': PictoShape.squircle,
    'PR_SNATCH_BW': PictoShape.squircle,
    'PR_BODY_IRON': PictoShape.squircle,
    'TITLE_SCHOLAR': PictoShape.squircle,
    'TITLE_UNDEFEATED': PictoShape.squircle,
    'TITLE_POLYMATH': PictoShape.squircle,
    'WOD_10': PictoShape.circle,
    'WOD_25': PictoShape.circle,
    'WOD_50': PictoShape.circle,
    'WOD_75': PictoShape.circle,
    'VOL_100_WODS': PictoShape.circle,
    'VOL_200_WODS': PictoShape.circle,
    'STREAK_3': PictoShape.circle,
    'STREAK_7': PictoShape.circle,
    'STREAK_10': PictoShape.circle,
    'STREAK_30': PictoShape.circle,
    'STREAK_60': PictoShape.circle,
    'STREAK_90': PictoShape.circle,
    'TITLE_RELENTLESS': PictoShape.circle,
    'TITLE_OBSESSED': PictoShape.circle,
    'VOL_TRIPLE_STREAK': PictoShape.circle,
    'VOL_COMEBACK': PictoShape.circle,
    'VOL_COMEBACK_60': PictoShape.circle,
    'SEASON_SPRING': PictoShape.circle,
    'SEASON_SUMMER': PictoShape.circle,
    'SEASON_FALL': PictoShape.circle,
    'SEASON_WINTER': PictoShape.circle,
    'SEASON_YEAREND': PictoShape.circle,
    'CF_OPEN_SURVIVOR': PictoShape.circle,
    'CF_QUARTERFINAL_GRINDER': PictoShape.circle,
    'CF_SEMIFINAL_WATCH': PictoShape.circle,
    'EGG_WITCHING': PictoShape.circle,
    'EGG_DOOMSDAY': PictoShape.circle,
    'EGG_SUNDAY': PictoShape.circle,
    'EGG_PI': PictoShape.circle,
    'EGG_TRIPLE': PictoShape.circle,
    'GIRLS_5_COMPLETE': PictoShape.shield,
    'GIRLS_ALL': PictoShape.shield,
    'HEROES_3': PictoShape.shield,
    'HEROES_5': PictoShape.shield,
    'GAMES_1': PictoShape.shield,
  };

  /// 코드가 _icon 에 없을 때 접두사로 폴백. 순서 중요 (ALL_CAT_ 가 CAT_ 보다 앞).
  static const List<(String, String, PictoShape)> _prefix = [
    ('GIRLS_', 'ribbon', PictoShape.shield),
    ('HEROES_', 'flag', PictoShape.shield),
    ('GAMES_', 'finish', PictoShape.shield),
    ('REACH_', 'medal', PictoShape.squircle),
    ('SCORE_', 'chart-up', PictoShape.squircle),
    ('ALL_CAT_', 'athlete', PictoShape.squircle),
    ('CAT_', 'athlete', PictoShape.squircle),
    ('PR_', 'chart-up', PictoShape.squircle),
    ('WOD_', 'stamp', PictoShape.circle),
    ('STREAK_', 'flame', PictoShape.circle),
    ('VOL_', 'certificate', PictoShape.circle),
    ('SEASON_', 'sunrise', PictoShape.circle),
    ('CF_', 'flag', PictoShape.circle),
    ('EGG_', 'star', PictoShape.circle),
    ('TITLE_', 'crown', PictoShape.squircle),
  ];

  static const String _defaultIcon = 'star';
  static const PictoShape _defaultShape = PictoShape.circle;

  /// 숨김 업적이면서 아직 안 딴 것 — 자물쇠로 덮는다.
  static const String hiddenIcon = 'lock';

  static String iconNameFor(
    String code, {
    bool hiddenLocked = false,
    String? override,
  }) {
    if (hiddenLocked) return hiddenIcon;
    // 코치가 PC 업적 설정에서 고른 이름이 최우선. 팩에 없는 이름이면 무시한다.
    if (override != null && override.isNotEmpty && hasIcon(override)) {
      return override;
    }
    final direct = _icon[code];
    if (direct != null) return direct;
    for (final (p, icon, _) in _prefix) {
      if (code.startsWith(p)) return icon;
    }
    return _defaultIcon;
  }

  /// SvgPicture.asset 에 그대로 넣을 경로.
  static String assetFor(
    String code, {
    bool hiddenLocked = false,
    String? override,
  }) =>
      '$basePath${iconNameFor(code, hiddenLocked: hiddenLocked, override: override)}.svg';

  /// 코치가 PC 에서 고른 이름이 있으면 그걸 쓴다 (코드 매핑보다 우선).
  /// 팩에 없는 이름이면 무시하고 코드 매핑으로 떨어진다 — 서버 어휘와
  /// 팩 어휘가 어긋나도 화면이 비지 않는다 (2026-08-21).
  static bool hasIcon(String name) => _allIcons.contains(name);

  /// 팩이 실제로 가진 아이콘 이름 전체 — override 유효성 검사용.
  static final Set<String> _allIcons = {
    ..._icon.values,
    ...[for (final (_, i, _) in _prefix) i],
    _defaultIcon,
    'lock',
  };

  static PictoShape shapeFor(String code) {
    final direct = _shape[code];
    if (direct != null) return direct;
    for (final (p, _, shape) in _prefix) {
      if (code.startsWith(p)) return shape;
    }
    return _defaultShape;
  }

  /// 인증 방식 한글 이름 — 툴팁·범례용.
  static String shapeLabel(PictoShape s) => switch (s) {
    PictoShape.circle => '자동 집계',
    PictoShape.squircle => '기록 대조',
    PictoShape.shield => '사람 판정',
  };
}

/// SVG 안의 sentinel 두 색을 희귀도 색으로 바꿔 끼운다.
/// const 로 만들어야 flutter_svg 가 결과를 캐시한다.
@immutable
class PictogramColorMapper extends ColorMapper {
  const PictogramColorMapper(this.light, this.dark);

  final Color light;
  final Color dark;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (color == HyphenPictogram.sentinelLight) return light;
    if (color == HyphenPictogram.sentinelDark) return dark;
    return color;
  }

  @override
  bool operator ==(Object other) =>
      other is PictogramColorMapper &&
      other.light == light &&
      other.dark == dark;

  @override
  int get hashCode => Object.hash(light, dark);
}

/// 판 + 아이콘. 이 위젯 하나로 그리드·상세·토스트를 다 덮는다.
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.code,
    required this.rarity,
    this.size = 56,
    this.locked = false,
    this.hidden = false,
    this.icon,
  });

  final String code;

  /// 코치가 PC 에서 고른 픽토그램 이름. 비면 코드 매핑을 쓴다 (2026-08-21).
  final String? icon;

  /// 서버 카탈로그의 rarity 문자열 — Common / Rare / Epic / Legendary
  final String rarity;
  final double size;
  final bool locked;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final pal = locked ? RarityPalette.locked : RarityPalette.of(rarity);
    final shape = HyphenPictogram.shapeFor(code);
    final asset = HyphenPictogram.assetFor(
      code,
      hiddenLocked: hidden && locked,
      override: icon,
    );
    final lip = size * 0.055;

    return SizedBox(
      width: size,
      height: size + lip,
      child: Stack(
        children: [
          Positioned(
            top: lip,
            child: CustomPaint(
              size: Size(size, size),
              painter: _PlatePainter(
                shape: shape,
                fill: pal.lip,
                stroke: pal.lip,
              ),
            ),
          ),
          CustomPaint(
            size: Size(size, size),
            painter: _PlatePainter(
              shape: shape,
              fill: pal.plate,
              stroke: pal.border,
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            width: size,
            height: size,
            child: Center(
              child: SvgPicture.asset(
                asset,
                width: size * 0.54,
                height: size * 0.54,
                colorMapper: PictogramColorMapper(pal.light, pal.dark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatePainter extends CustomPainter {
  const _PlatePainter({
    required this.shape,
    required this.fill,
    required this.stroke,
  });

  final PictoShape shape;
  final Color fill;
  final Color stroke;

  Path _path(double s) {
    switch (shape) {
      case PictoShape.circle:
        return Path()..addOval(
          Rect.fromCircle(center: Offset(s / 2, s / 2), radius: s / 2 - 1.5),
        );
      case PictoShape.squircle:
        return Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(1.5, 1.5, s - 3, s - 3),
            Radius.circular(s * 0.29),
          ),
        );
      case PictoShape.shield:
        return Path()
          ..moveTo(.500 * s, .055 * s)
          ..lineTo(.922 * s, .195 * s)
          ..lineTo(.922 * s, .516 * s)
          ..cubicTo(.922 * s, .738 * s, .738 * s, .885 * s, .500 * s, .961 * s)
          ..cubicTo(.262 * s, .885 * s, .078 * s, .738 * s, .078 * s, .516 * s)
          ..lineTo(.078 * s, .195 * s)
          ..close();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = _path(size.width);
    canvas.drawPath(p, Paint()..color = fill);
    canvas.drawPath(
      p,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.035,
    );
  }

  @override
  bool shouldRepaint(_PlatePainter old) =>
      old.shape != shape || old.fill != fill || old.stroke != stroke;
}
