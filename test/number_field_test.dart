// HkNumberField — 숫자 전용 칸의 규격 게이트 (D125 · 2026-09-06 가시성 점검).
//
// 완료 시트의 1~3자리 숫자 칸이 전폭 TextField 라 값이 왼쪽 구석에 묻히고 칸 이름은
// placeholder 색뿐이었다 (docs/audit-visibility-2026-09-06.html). 여기서 **실제로 그려서**
// 재는 것: 상자 폭·높이(48) · 단위가 칸 밖 오른쪽 · 라벨이 위에 · 빈 라벨('')이 자리를
// 예약해 옆 칸과 y 가 같음 · 힌트·키보드·정렬. 상수 비교로는 Row 가 실제로 몇 px 를
// 주는지 알 수 없다 (button_busy_width_test 와 같은 방식).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hyphen_app/core/theme.dart';
import 'package:hyphen_app/widgets/hkit.dart';

Widget _app(Widget child) => MaterialApp(
  theme: HyphenTheme.light,
  home: Scaffold(
    body: Align(alignment: Alignment.topLeft, child: child),
  ),
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(720, 1560);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(child));
  await tester.pump();
}

const _k = ValueKey<String>('nf-a');
const _k2 = ValueKey<String>('nf-b');

void main() {
  testWidgets('상자 = width × touchMin(48)', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await _pump(
      tester,
      HkNumberField(fieldKey: _k, controller: c, width: 96, unit: 'kg'),
    );
    final size = tester.getSize(find.byKey(_k));
    expect(size.width, 96);
    expect(size.height, HyphenTokens.touchMin);
  });

  testWidgets('폭은 인자대로 — 72 를 주면 72', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await _pump(tester, HkNumberField(fieldKey: _k, controller: c, width: 72));
    expect(tester.getSize(find.byKey(_k)).width, 72);
  });

  testWidgets('단위 글자는 상자 오른쪽 바깥', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await _pump(
      tester,
      HkNumberField(fieldKey: _k, controller: c, unit: 'kg'),
    );
    final box = tester.getRect(find.byKey(_k));
    final unit = tester.getRect(find.text('kg'));
    expect(unit.left, greaterThan(box.right));
    // 세로로는 상자와 같은 줄에 선다.
    expect(unit.center.dy, closeTo(box.center.dy, 1));
  });

  testWidgets('단위가 없으면 단위 글자도 없다', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await _pump(tester, HkNumberField(fieldKey: _k, controller: c));
    expect(find.text('kg'), findsNothing);
  });

  testWidgets('라벨은 상자 위에 선다', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await _pump(
      tester,
      HkNumberField(fieldKey: _k, controller: c, label: '무게'),
    );
    final label = tester.getRect(find.text('무게'));
    final box = tester.getRect(find.byKey(_k));
    expect(label.bottom, lessThanOrEqualTo(box.top));
    expect(label.left, closeTo(box.left, 1));
  });

  testWidgets('라벨이 null 이면 라벨 줄 자체가 없다 — 상자가 맨 위', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await _pump(tester, HkNumberField(fieldKey: _k, controller: c));
    final field = tester.getRect(find.byType(HkNumberField));
    final box = tester.getRect(find.byKey(_k));
    expect(box.top, field.top);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets("빈 라벨('')은 자리를 예약해 옆 칸과 상자 y 가 같다", (tester) async {
    final a = TextEditingController();
    final b = TextEditingController();
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    await _pump(
      tester,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HkNumberField(fieldKey: _k, controller: a, label: '무게', unit: 'kg'),
          const SizedBox(width: 8),
          HkNumberField(fieldKey: _k2, controller: b, label: '', unit: '회'),
        ],
      ),
    );
    final left = tester.getRect(find.byKey(_k));
    final right = tester.getRect(find.byKey(_k2));
    expect(right.top, left.top);
    expect(right.height, left.height);
  });

  testWidgets('hintText 는 그대로 TextField 로', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await _pump(
      tester,
      HkNumberField(fieldKey: _k, controller: c, hint: '21 미만'),
    );
    expect(
      tester.widget<TextField>(find.byKey(_k)).decoration?.hintText,
      '21 미만',
    );
  });

  testWidgets('키보드 — 기본은 소수점 숫자, numeric:false 면 글자', (tester) async {
    final a = TextEditingController();
    final b = TextEditingController();
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    await _pump(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HkNumberField(fieldKey: _k, controller: a),
          HkNumberField(fieldKey: _k2, controller: b, numeric: false),
        ],
      ),
    );
    expect(
      tester.widget<TextField>(find.byKey(_k)).keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    expect(
      tester.widget<TextField>(find.byKey(_k2)).keyboardType,
      TextInputType.text,
    );
  });

  testWidgets('값은 오른쪽 정렬 · 세미볼드 h3 · 고정폭 숫자', (tester) async {
    final c = TextEditingController(text: '100');
    addTearDown(c.dispose);
    await _pump(tester, HkNumberField(fieldKey: _k, controller: c));
    final tf = tester.widget<TextField>(find.byKey(_k));
    expect(tf.textAlign, TextAlign.right);
    expect(tf.style?.fontSize, HyphenTokens.h3.fontSize);
    expect(tf.style?.fontWeight, FontWeight.w600);
    expect(tf.style?.fontFeatures, HyphenTokens.tabular);
  });

  testWidgets('enabled:false 면 TextField 도 잠긴다', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await _pump(
      tester,
      HkNumberField(fieldKey: _k, controller: c, enabled: false),
    );
    expect(tester.widget<TextField>(find.byKey(_k)).enabled, isFalse);
  });

  group('HkSectionLabel(strong)', () {
    testWidgets('strong 은 대문자 강제 없이 body 세미볼드', (tester) async {
      await _pump(
        tester,
        const HkSectionLabel('A 파트 · 15분 · Strength', strong: true),
      );
      expect(find.text('A 파트 · 15분 · Strength'), findsOneWidget);
      expect(find.text('A 파트 · 15분 · STRENGTH'), findsNothing);
      final t = tester.widget<Text>(find.byType(Text));
      expect(t.style?.fontSize, HyphenTokens.body.fontSize);
      expect(t.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('기본형은 종전대로 대문자 sectionLabel', (tester) async {
      await _pump(tester, const HkSectionLabel('내 기록 abc'));
      expect(find.text('내 기록 ABC'), findsOneWidget);
      final t = tester.widget<Text>(find.byType(Text));
      expect(t.style?.fontSize, HyphenTokens.sectionLabel.fontSize);
    });
  });
}
