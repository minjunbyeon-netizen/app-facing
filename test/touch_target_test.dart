// 손가락 영역 48 — 회귀 게이트 (D113 · 2026-09-04 사용자 "폭 48 적용시키자").
//
// DESIGN-SSOT §3 은 터치 48 을 요구하는데 배지는 **세로만** 48 이었고 가로는 글자
// 폭을 따라가 '예약' 두 글자가 42 였다 (페르소나 계측에서 실측). 요일 띠 칸은 45,
// 수업 줄 여닫기 화살표는 32 였다. 셋 다 48 을 갖는지 실물 렌더로 잰다.
//
// 잰다 = 화면에 그린 뒤 `tester.getSize` — 상수를 다시 적어 비교하지 않는다
// (상수만 보면 Row·Expanded 가 실제로 몇 px 를 주는지 알 수 없다).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hyphen_app/core/theme.dart';
import 'package:hyphen_app/features/gym/week_board.dart';
import 'package:hyphen_app/widgets/hkit.dart';

const double kTouch = 48; // = HyphenTokens.touchMin

Widget _app(Widget child) => MaterialApp(
  theme: HyphenTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('배지 — 누르는 배지는 가로·세로 둘 다 48 이상', (tester) async {
    tester.view.physicalSize = const Size(720, 1560);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final label in ['예약', '대기', '취소', '예약됨', '완료 표시'])
            HkBadge(label, color: HyphenTokens.accent, onTap: () {}),
        ],
      ),
    ));

    for (final label in ['예약', '대기', '취소', '예약됨', '완료 표시']) {
      final size = tester.getSize(find.widgetWithText(HkBadge, label));
      expect(size.width, greaterThanOrEqualTo(kTouch),
          reason: "'$label' 배지 가로가 손가락 기준(48) 미달");
      expect(size.height, greaterThanOrEqualTo(kTouch),
          reason: "'$label' 배지 세로가 손가락 기준(48) 미달");
    }
  });

  testWidgets('배지 — 못 누르는 배지는 종전 크기 그대로 (글자만큼)', (tester) async {
    await tester.pumpWidget(_app(
      const HkBadge('마감', color: HyphenTokens.muted),
    ));
    final size = tester.getSize(find.byType(HkBadge));
    // 2026-09-07 배지 글자 15sp — '마감' 두 글자도 자연 폭이 48 을 넘는다.
    // 재는 축을 높이로 바꾼다: 조작 배지는 48 상자에 담기고(세로 48), 표시 전용은
    // 글자만큼만 높다(약 31). "조작 배지만 48" 이라는 뜻은 그대로다.
    expect(size.height, lessThan(kTouch),
        reason: '표시 전용 배지까지 48 상자에 담으면 줄이 뚱뚱해진다 — 조작 배지만 48');
  });

  testWidgets('요일 띠 — 일곱 칸이 각자 48 이상 (360 폭 기준)', (tester) async {
    tester.view.physicalSize = const Size(720, 1560);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(
      SizedBox(
        width: 336, // 수업 탭에서 띠가 실제로 받는 폭 (360 - 좌우 12)
        child: HkDayStrip(
          cells: [
            for (var i = 0; i < 7; i++)
              HkDayCell(
                weekday: ['월', '화', '수', '목', '금', '토', '일'][i],
                day: 10 + i,
                isToday: i == 2,
                mark: HkDayMark.hasClass,
              ),
          ],
          selected: 2,
          onSelected: (_) {},
          cellKey: WeekBoard.dayKey,
        ),
      ),
    ));

    for (var i = 0; i < 7; i++) {
      final size = tester.getSize(find.byKey(WeekBoard.dayKey(i)));
      expect(size.width, greaterThanOrEqualTo(kTouch),
          reason: '요일 칸 $i 가로가 손가락 기준(48) 미달');
      expect(size.height, greaterThanOrEqualTo(kTouch),
          reason: '요일 칸 $i 세로가 손가락 기준(48) 미달');
    }
  });
}
