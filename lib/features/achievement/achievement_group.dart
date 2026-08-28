import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// 업적 분류 — 전체 목록의 구획과 트로피 룸의 "같은 분류"가 **같은 규칙**을 쓴다
/// (§0-B 이름 일원화). v3.35 (2026-08-28 사용자 확정 E 안) 에서 구
/// `AchievementsScreen._category` 를 끌어올렸다.
///
/// 키는 서버 코드 접두어로 판정한다 (카탈로그에 분류 필드가 없다 — API 변경 없이
/// 앱이 나눈다). 어느 접두어에도 안 걸리면 '기타'.
class AchievementGroup {
  const AchievementGroup._();

  /// 목록 표시 순서와 한글 이름.
  static const List<(String, String)> ordered = [
    ('STREAK', '연속'),
    ('PR', 'PR'),
    ('VOLUME', '누적'),
    ('SEASON', '시즌'),
    ('EASTER', '숨김'),
    ('ETC', '기타'),
  ];

  static String of(String code) {
    if (code.startsWith('STREAK_') ||
        code == 'TITLE_OBSESSED' ||
        code == 'TITLE_RELENTLESS' ||
        code == 'VOL_TRIPLE_STREAK' ||
        code == 'VOL_QUINTUPLE_STREAK' ||
        code.startsWith('VOL_COMEBACK')) {
      return 'STREAK';
    }
    if (code.startsWith('PR_')) return 'PR';
    if (code.startsWith('SEASON_') || code.startsWith('CF_')) return 'SEASON';
    if (code.startsWith('EGG_')) return 'EASTER';
    if (code.startsWith('VOL_') ||
        code.startsWith('WOD_') ||
        code == 'TITLE_UNDEFEATED' ||
        code.startsWith('GIRLS_') ||
        code.startsWith('HEROES_') ||
        code == 'GAMES_1') {
      return 'VOLUME';
    }
    return 'ETC';
  }

  static String label(String key) {
    for (final (k, name) in ordered) {
      if (k == key) return name;
    }
    return '기타';
  }
}

/// 분류 구획 라벨 한 줄 — "연속 · 달성 1 / 3". 목록과 트로피 룸이 같은 것을 쓴다.
/// 높이 고정([height]) — 자리 예약 계산과 스켈레톤이 같은 값을 쓴다.
class AchievementGroupLabel extends StatelessWidget {
  static const double height = 40;
  final String label;
  final int unlocked;
  final int total;
  const AchievementGroupLabel({
    super.key,
    required this.label,
    required this.unlocked,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          HyphenTokens.sp4,
          0,
          HyphenTokens.sp4,
          HyphenTokens.sp1 + 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: HyphenTokens.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: HyphenTokens.sp2),
            Text(
              '달성 $unlocked / $total',
              style: HyphenTokens.caption.copyWith(
                fontFeatures: HyphenTokens.tabular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
