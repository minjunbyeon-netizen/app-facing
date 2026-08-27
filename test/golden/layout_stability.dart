/// 레이아웃 안정성(layout stability) 검사 헬퍼 — 정본 규칙 = `docs/DESIGN-SSOT.md`
/// §레이아웃 안정성 — 공간 예약.
///
/// 문제의 이름은 **레이아웃 시프트(layout shift)** 다: 안내·에러·로딩처럼 상태에
/// 따라 생겼다 사라지는 것이 있으면 그 아래 요소가 통째로 밀린다. 사람이 누르려던
/// 버튼이 손가락 아래에서 도망가고, 화면이 상태마다 다른 물건처럼 보인다.
/// 해결 기법은 **공간 예약(space reservation)** — 변할 자리를 고정 높이로 미리
/// 잡아 두고 내용만 갈아 끼운다.
///
/// 이 파일은 그 결과를 **픽셀이 아니라 좌표로** 검증한다. 골든 PNG 비교는 "달라졌다"
/// 까지만 말해 주지만, 여기서는 "어느 앵커가 몇 px 밀렸다" 를 바로 짚는다.
/// (PNG 스캔보다 정확하고 빠르다 — 글자 안티에일리어싱·색 변화에 흔들리지 않는다.)
///
/// 로그인 화면 적용 = `layout_stability_test.dart`. 다른 화면도 같은 방식으로
/// 상태 목록 + 앵커 키만 주면 된다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 한 상태를 화면에 올려놓는 절차 — `pumpWidget` 부터 필요한 조작(입력·탭)까지.
typedef ScreenState = Future<void> Function(WidgetTester tester);

/// 상태 이름 → (앵커 이름 → 화면 위 y 좌표).
typedef AnchorTable = Map<String, Map<String, double>>;

/// [states] 를 하나씩 렌더하며 [anchors] 의 y 좌표를 잰다.
Future<AnchorTable> measureAnchorY(
  WidgetTester tester, {
  required Map<String, ScreenState> states,
  required Map<String, Key> anchors,
}) async {
  final table = <String, Map<String, double>>{};
  for (final state in states.entries) {
    await state.value(tester);
    final row = <String, double>{};
    for (final anchor in anchors.entries) {
      final finder = find.byKey(anchor.value);
      expect(
        finder,
        findsOneWidget,
        reason: "앵커 '${anchor.key}' 를 찾지 못했습니다 (상태 '${state.key}')",
      );
      row[anchor.key] = tester.getTopLeft(finder).dy;
    }
    table[state.key] = row;
  }
  return table;
}

/// **상태가 바뀌어도 앵커의 y 는 같아야 한다.** 하나라도 다르면 실패하고,
/// 어떤 앵커가 어느 상태에서 몇 px 밀렸는지 표로 보여 준다.
///
/// [tolerance] 는 부동소수 오차용이다 — 1px 밀림도 실패로 잡는다.
Future<AnchorTable> expectStableAnchorY(
  WidgetTester tester, {
  required Map<String, ScreenState> states,
  required Map<String, Key> anchors,
  double tolerance = 0.01,
}) async {
  final table = await measureAnchorY(
    tester,
    states: states,
    anchors: anchors,
  );
  final baseName = states.keys.first;
  final base = table[baseName]!;
  final drifts = <String>[];
  for (final anchor in anchors.keys) {
    for (final state in states.keys) {
      final delta = (table[state]![anchor]! - base[anchor]!).abs();
      if (delta > tolerance) {
        drifts.add(
          "$anchor: '$state' 가 '$baseName' 대비 "
          '${delta.toStringAsFixed(1)}px 밀렸습니다 '
          '(${base[anchor]!.toStringAsFixed(1)} → '
          '${table[state]![anchor]!.toStringAsFixed(1)})',
        );
      }
    }
  }
  expect(
    drifts,
    isEmpty,
    reason:
        '레이아웃 시프트가 생겼습니다 — 변하는 것은 고정 높이 자리 안에서만 '
        '바뀌어야 합니다 (DESIGN-SSOT §레이아웃 안정성):\n'
        '${drifts.join('\n')}\n\n${formatAnchorTable(table)}',
  );
  return table;
}

/// 사람이 읽을 표로. 테스트 실패 사유와 확인용 HTML 양쪽에서 쓴다.
String formatAnchorTable(AnchorTable table) {
  if (table.isEmpty) return '(빈 표)';
  final anchors = table.values.first.keys.toList();
  final nameWidth = table.keys
      .map((k) => k.length)
      .fold<int>('상태'.length, (a, b) => a > b ? a : b);
  final buffer = StringBuffer()
    ..write('상태'.padRight(nameWidth))
    ..write('  ')
    ..writeln(anchors.map((a) => a.padLeft(14)).join('  '));
  for (final row in table.entries) {
    buffer
      ..write(row.key.padRight(nameWidth))
      ..write('  ')
      ..writeln(
        anchors
            .map((a) => row.value[a]!.toStringAsFixed(1).padLeft(14))
            .join('  '),
      );
  }
  return buffer.toString();
}
