// 수업 줄의 오른쪽 자리는 **누를 게 없으면 비운다** (2026-09-05 사용자 지시
// "날짜가 지나면 굳이 종료라고 버튼 해서 지저분하게 하지말고 … 걍 깨끗한 화면").
//
// 지난 수업의 '종료' 배지와, 하루·주 한도에 걸린 수업의 '오늘/이번 주 예약 완료'
// 배지를 없앤다. 다만 **줄 높이는 그대로** 둔다 — 배지가 사라진다고 줄이 짧아지면
// 목록이 들쭉날쭉해지고, 상태가 바뀔 때 아래가 밀린다
// (docs/DESIGN-SSOT.md §레이아웃 안정성).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hyphen_app/core/theme.dart';
import 'package:hyphen_app/features/classes/class_line.dart';
import 'package:hyphen_app/models/class_session.dart';

import 'golden/fakes.dart';

Widget _app(Widget child) => MaterialApp(
  theme: HyphenTheme.light,
  home: Scaffold(body: Center(child: child)),
);

ClassSessionDto _byId(List<Map<String, dynamic>> rows, int id) =>
    ClassSessionDto.fromJson(rows.firstWhere((r) => r['id'] == id));

Future<Size> _rowSize(
  WidgetTester tester,
  ClassSessionDto session, {
  bool isPastDay = false,
}) async {
  tester.view.physicalSize = const Size(720, 1560);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(
      SizedBox(
        width: 360,
        child: ClassLine.member(
          key: const ValueKey<String>('row'),
          session: session,
          isPastDay: isPastDay,
          onReserve: () {},
          onCancel: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.getSize(find.byKey(const ValueKey<String>('row')));
}

void main() {
  testWidgets('지난 수업 — 종료 배지 없이 비어 있다', (tester) async {
    // memberClassesWithEnded 의 100 번은 테스트 시계(10:30) 기준 09:00 에 끝났다.
    final ended = _byId(memberClassesWithEnded(), 100);
    await _rowSize(tester, ended);

    expect(find.text('종료'), findsNothing, reason: "'종료' 배지가 아직 남아 있다");
  });

  testWidgets('하루 한도 — 예약 완료 문구 없이 비어 있다', (tester) async {
    final limited = _byId(memberClassesDailyLimit(), 102);
    expect(limited.reserveLimitReached, 'daily', reason: '전제가 깨졌다');
    await _rowSize(tester, limited);

    expect(find.text('오늘 예약 완료'), findsNothing);
    expect(find.text('이번 주 예약 완료'), findsNothing);
    expect(find.text('예약'), findsNothing, reason: '한도에 걸린 수업에 예약이 서 있다');
  });

  testWidgets('줄 높이 — 예약 가능·지난 수업·한도 도달이 모두 같다', (tester) async {
    final open = _byId(memberClassesDailyLimit(), 103); // 내일 수업, 여유 있음
    final ended = _byId(memberClassesWithEnded(), 100);
    final limited = _byId(memberClassesDailyLimit(), 102);

    final hOpen = await _rowSize(tester, open);
    final hEnded = await _rowSize(tester, ended);
    final hLimited = await _rowSize(tester, limited);

    expect(
      hEnded.height,
      moreOrLessEquals(hOpen.height, epsilon: 1),
      reason: '지난 수업 줄이 ${hOpen.height} → ${hEnded.height} 로 달라졌다',
    );
    expect(
      hLimited.height,
      moreOrLessEquals(hOpen.height, epsilon: 1),
      reason: '한도 도달 줄이 ${hOpen.height} → ${hLimited.height} 로 달라졌다',
    );
  });
}
