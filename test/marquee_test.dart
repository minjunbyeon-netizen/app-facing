// HkMarquee 회귀 (v3.42 · 2026-08-29).
//
// 사용자 지시: "공지 칸만 좌에서 우로 안에 내용이 TEXT 가 슬라이드 돌아가게".
//
// 골든은 정지 프레임이라 '흐른다' 를 못 잡는다. 여기서 못 박는 것:
//   1) 칸에 다 들어가는 글은 **움직이지 않는다** (짧은 글까지 흔들면 시선만 뺏는다)
//   2) 넘치는 글은 시간이 지나면 **왼쪽으로 이동해 있다** (좌→우 방향으로 읽힘)
//   3) 시스템 '애니메이션 줄이기' 면 넘쳐도 서 있고 `…` 로 자른다
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hyphen_app/widgets/hkit.dart';

const _style = TextStyle(fontSize: 14, fontFamily: 'Pretendard');

Future<void> _pump(WidgetTester tester, String text,
    {double width = 200, bool reduce = false, bool fill = false}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: width,
            child: HkMarquee(text, style: _style, fill: fill,
                pauseAtStart: const Duration(milliseconds: 200)),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

double _firstTextLeft(WidgetTester tester) =>
    tester.getTopLeft(find.byType(Text).first).dx;

void main() {
  testWidgets('칸에 들어가는 글은 서 있다 — 한 벌만 그려지고 안 움직인다', (tester) async {
    await _pump(tester, '짧은 공지');
    expect(find.byType(Text), findsOneWidget);
    final before = _firstTextLeft(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(_firstTextLeft(tester), before);
  });

  testWidgets('넘치는 글은 시간이 지나면 왼쪽으로 이동해 있다', (tester) async {
    await _pump(tester,
        '8월 15일 광복절 휴관 안내입니다. 당일 예약 수업은 자동 취소되며 다음 주 정상 운영합니다.');
    // 두 벌이 이어 붙어 있다 (끊김 없는 반복)
    expect(find.byType(Text), findsNWidgets(2));
    final start = _firstTextLeft(tester);
    // 시작 멈춤(200ms) 안에는 제자리
    await tester.pump(const Duration(milliseconds: 100));
    expect(_firstTextLeft(tester), start);
    // 그 뒤로는 왼쪽(−x)으로 이동
    await tester.pump(const Duration(milliseconds: 1500));
    expect(_firstTextLeft(tester), lessThan(start),
        reason: '좌→우로 읽히려면 글이 왼쪽으로 흘러야 한다');
  });

  testWidgets("'애니메이션 줄이기' 면 넘쳐도 서 있고 … 로 자른다", (tester) async {
    await _pump(tester,
        '8월 15일 광복절 휴관 안내입니다. 당일 예약 수업은 자동 취소되며 다음 주 정상 운영합니다.',
        reduce: true);
    expect(find.byType(Text), findsOneWidget);
    final t = tester.widget<Text>(find.byType(Text));
    expect(t.overflow, TextOverflow.ellipsis);
    final before = _firstTextLeft(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(_firstTextLeft(tester), before);
  });

  // ── fill 모드 (v3.43 · 홈 공지 검정 전광판) ───────────────────────────────

  testWidgets('fill — 짧은 글도 이어 붙여 줄을 꽉 채우고 흐른다', (tester) async {
    await _pump(tester, 'eeeee', fill: true);
    // 한 벌로는 칸(200)이 안 차니 여러 벌이 이어져 있다
    expect(tester.widgetList(find.byType(Text)).length, greaterThan(2));
    final start = _firstTextLeft(tester);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(_firstTextLeft(tester), lessThan(start),
        reason: '짧은 글이 서 있으면 검정 전광판이 죽어 보인다');
  });

  testWidgets('fill — 빈 글은 흐르지 않는다 (없는 것을 흐르게 하면 거짓 신호)', (tester) async {
    await _pump(tester, '   ', fill: true);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets("fill — '애니메이션 줄이기' 면 서 있다", (tester) async {
    await _pump(tester, 'eeeee', fill: true, reduce: true);
    expect(find.byType(Text), findsOneWidget);
    final before = _firstTextLeft(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(_firstTextLeft(tester), before);
  });
}
