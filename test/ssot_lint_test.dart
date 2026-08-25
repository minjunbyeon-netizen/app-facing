// v3.24 (2026-08-25 사용자 지시 "인라인으로 되어 있거나 이원화된 것 찾아서 전부
// 통일") — 상단바·다이얼로그·바텀시트·입력칸 스타일을 HKit/테마 한 곳으로
// 끌어올린 뒤, 화면 코드에 다시 인라인이 생기지 못하게 막는 게이트.
//
// 정본: 상단바 = HkAppBar · 다이얼로그 = HkDialog · 시트 = HkSheet ·
// 입력칸 모양 = theme.dart inputDecorationTheme (화면은 hintText 만 준다).
// 버튼은 button_lint_test.dart 가 따로 지킨다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// (금지 패턴, 설명) — lib/features/** 에서 0건이어야 한다.
const List<(String, String)> _forbidden = [
  (r'(?<![A-Za-z_])AppBar\(', '상단바는 HkAppBar 만 (widgets/hkit.dart)'),
  (r'AlertDialog\(', '다이얼로그는 HkDialog.confirm/info/custom 만'),
  (r'showModalBottomSheet', '바텀시트는 HkSheet.show 만'),
  (r'(?<![A-Za-z_])NavigationBar\(', '하단 탭바는 HkTabBar 만 — 셸 두 벌 금지'),
  (r'CircularProgressIndicator\(', '스피너는 HkLoading 만'),
  (r'style: HyphenTokens\.sectionLabel[,)]', '섹션 라벨은 HkSectionLabel 만 (copyWith 변형만 예외)'),
  (r'String _(fmt|hhmm|ymd|dateShort)\w*\(', '날짜·시각 표기는 core/time_format.dart 만'),
  (r'InputDecoration _\w+\(', '입력칸 스타일은 테마 한 벌 — 화면별 _deco 금지'),
  (r'OutlineInputBorder\(', '입력칸 테두리는 theme.dart inputDecorationTheme 만'),
  (r'danger\.withValues\(alpha: ?0\.12\)', '인라인 에러 박스 금지 — HkInlineError'),
];

void main() {
  test('화면 코드에 인라인 상단바·다이얼로그·시트·입력칸 스타일 0건 (HKit SSOT)',
      () {
    final files = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    final hits = <String>[];
    for (final f in files) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        for (final (pattern, why) in _forbidden) {
          if (RegExp(pattern).hasMatch(line)) {
            final rel = f.path.replaceAll('\\', '/');
            hits.add('$rel:${i + 1}: ${line.trim()}  ← $why');
          }
        }
      }
    }
    expect(hits, isEmpty,
        reason: '인라인 UI 골격이 다시 생겼습니다 — HKit 정본을 쓰십시오:\n'
            '${hits.join('\n')}');
  });
}
