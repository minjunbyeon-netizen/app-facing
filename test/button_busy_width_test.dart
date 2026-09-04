// 버튼이 '진행 중' 으로 바뀔 때 **폭이 튀지 않는다** — 회귀 게이트 (D118 · 2026-09-05).
//
// 전체폭이 아닌 버튼(`expand: false`)은 글자가 폭을 정한다. 종전엔 busy 일 때
// 글자를 `HkLoading`(= Center) 로 통째 갈아 끼웠는데, Center 는 남는 가로폭을
// 전부 먹는다 — '취소' 두 글자짜리 버튼이 눌리는 순간 화면 폭까지 벌어져
// 옆에 나란히 선 버튼을 밀어냈다 (docs/UI-INDEX.md §2-3 실측 49.6 → 360).
//
// 잰다 = 실제로 그린 뒤 `tester.getSize`. 상수 비교로는 Row·Stack 이 실제로
// 몇 px 를 주는지 알 수 없다. 규격 정본 = docs/DESIGN-SSOT.md §레이아웃 안정성.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hyphen_app/core/theme.dart';
import 'package:hyphen_app/widgets/hkit.dart';

Widget _app(Widget child) => MaterialApp(
  theme: HyphenTheme.light,
  home: Scaffold(body: Center(child: child)),
);

Future<Size> _measure(
  WidgetTester tester,
  Widget button,
  String label,
) async {
  tester.view.physicalSize = const Size(720, 1560);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(button));
  await tester.pump();
  return tester.getSize(find.byKey(ValueKey<String>('btn-$label')));
}

void main() {
  for (final kind in HkButtonKind.values) {
    testWidgets('버튼 ${kind.name} — 진행 중에도 폭·높이가 그대로', (tester) async {
      const label = '취소';
      const key = ValueKey<String>('btn-$label');

      HkButton make(bool busy) => switch (kind) {
        HkButtonKind.primary => HkButton(
          label,
          key: key,
          onPressed: () {},
          expand: false,
          busy: busy,
        ),
        HkButtonKind.secondary => HkButton.secondary(
          label,
          key: key,
          onPressed: () {},
          expand: false,
          busy: busy,
        ),
        HkButtonKind.tertiary => HkButton.tertiary(
          label,
          key: key,
          onPressed: () {},
          expand: false,
          busy: busy,
        ),
      };

      final idle = await _measure(tester, make(false), label);
      final busy = await _measure(tester, make(true), label);

      expect(
        busy.width,
        moreOrLessEquals(idle.width, epsilon: 1),
        reason:
            '${kind.name} 버튼 폭이 진행 중에 ${idle.width} → ${busy.width} 로 튄다',
      );
      expect(
        busy.height,
        moreOrLessEquals(idle.height, epsilon: 1),
        reason:
            '${kind.name} 버튼 높이가 진행 중에 ${idle.height} → ${busy.height} 로 튄다',
      );
    });
  }

  testWidgets('버튼 — 나란히 선 두 버튼은 한쪽이 진행 중이어도 서로 안 밀린다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1560);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    Widget pair(bool busy) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HkButton.secondary(
          '취소',
          key: const ValueKey<String>('pair-cancel'),
          onPressed: () {},
          expand: false,
        ),
        const SizedBox(width: HyphenTokens.sp2),
        HkButton(
          '저장',
          key: const ValueKey<String>('pair-save'),
          onPressed: () {},
          expand: false,
          busy: busy,
        ),
      ],
    );

    await tester.pumpWidget(_app(pair(false)));
    await tester.pump();
    final before = tester.getTopLeft(
      find.byKey(const ValueKey<String>('pair-cancel')),
    );

    await tester.pumpWidget(_app(pair(true)));
    await tester.pump();
    final after = tester.getTopLeft(
      find.byKey(const ValueKey<String>('pair-cancel')),
    );

    expect(
      after.dx,
      moreOrLessEquals(before.dx, epsilon: 1),
      reason: "'저장' 이 진행 중이 되자 옆의 '취소' 가 ${before.dx} → ${after.dx} 로 밀렸다",
    );
  });
}
