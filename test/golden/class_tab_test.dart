// 회원 수업 탭 통합 한 줄 — 회귀 게이트 (D111 · 2026-09-04 사용자 "1안").
//
// 사용자 진단: "수업은 수업대로 보고, 예약은 예약대로 … 가독성·레이아웃 통일성이
// 떨어져서 반응 유도도 어려울 것 같은데". 회원의 결정은 하나("20:00 SWEAT 에 가서
// 이걸 한다")인데 두 칸이 동기와 버튼을 갈랐다 — 이제 요일 띠 + 수업 줄 하나.
//
// 못 박는 것 (정의는 전부 week_board.dart 의 순수 함수 한 곳):
//   1) 줄 순서 = 시작 시각 순
//   2) 여닫기는 사람만 — 날짜를 눌러 들어오면 전부 닫힘, 이름 옆 화살표·줄 탭으로 열고 닫음,
//      날짜를 옮기면 다시 전부 닫힘 (D112)
//   3) 어디에도 안 붙는 글은 '프로그램' 라벨 밑에 (글이 사라지지 않는다)
//   4) 접힌 줄 = 시각·이름·정원·배지만, 펼친 줄엔 파트 본문 (머리 없음)
//   5) 요일 띠 점 = 내 예약 / 수업 있음 / 없음
//   6) 두 칸 세그먼트는 없다 (되돌림 감지)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/classes/class_line.dart';
import 'package:hyphen_app/features/gym/box_wod_screen.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/gym/week_board.dart';
import 'package:hyphen_app/features/gym/wod_row.dart';
import 'package:hyphen_app/models/class_session.dart';
import 'package:hyphen_app/models/gym.dart';
import 'package:hyphen_app/widgets/hkit.dart';

import 'fakes.dart';
import 'harness.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

ClassSessionDto _c(
  int id,
  DateTime at, {
  int? tid,
  bool reserved = false,
  int? waitlist,
}) => ClassSessionDto(
  id: id,
  gymId: 1,
  startAt: at,
  durationMinutes: 60,
  title: 'C$id',
  capacity: 12,
  waitlistCapacity: 4,
  reservedCount: 1,
  waitlistCount: 0,
  status: 'open',
  templateId: tid,
  myReservation: reserved
      ? const MyReservationDto(
          reservationId: 1,
          status: 'confirmed',
          promotedFromWaitlist: false,
        )
      : null,
  myWaitlistPosition: waitlist,
);

GymWodPost _p(int id, {int? tid, String? name, String summary = ''}) =>
    GymWodPost(
      id: id,
      postDate: '2026-08-12',
      wodType: 'custom',
      wodTypeLabel: '수업',
      content: '내용 $id',
      createdAt: DateTime(2026, 8, 12, 5),
      templateId: tid,
      templateName: name,
      displayName: name,
      summary: summary,
    );

Future<GymState> _pumpTab(WidgetTester tester, {Map<String, dynamic>? world}) async {
  phone(tester);
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final api = FakeApi(world ?? memberWorld());
  final gym = GymState(GymRepository(api), sse: FakeSse());
  await gym.loadMine();
  await tester.pumpWidget(
    harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      gym: gym,
      home: const BoxWodScreen(),
    ),
  );
  await tester.pumpAndSettle();
  return gym;
}

void main() {
  group('leftoverPrograms · programFor — 글이 어느 줄에 붙나', () {
    final sweat = _p(32, tid: 2, name: 'SWEAT', summary: 'Back Squat 5회');
    final build = _p(33, tid: 3, name: 'BUILD');
    final single = _p(40); // 종류 없는 단발 글
    final classes = [_c(101, DateTime(2026, 8, 12, 20), tid: 2), _c(102, DateTime(2026, 8, 12, 21))];

    test('수업 줄에는 같은 종류의 글이, 종류 없는 수업에는 아무 글도 안 붙는다', () {
      expect(programFor(classes[0], [build, sweat])?.id, 32);
      expect(programFor(classes[1], [build, sweat]), isNull);
    });

    test('수업이 없는 종류의 글과 단발 글은 남는다 — 사라지지 않는다', () {
      expect(leftoverPrograms([sweat, build, single], classes).map((w) => w.id), [33, 40]);
    });

    test('같은 종류 글이 둘이면 첫 글만 (종류당 한 글)', () {
      final dup = _p(35, tid: 2, name: 'SWEAT');
      expect(programFor(classes[0], [dup, sweat])?.id, 35);
    });
  });

  group('dayMark — 요일 띠 점', () {
    test('내 예약이 있으면 주색, 수업만 있으면 회색, 없으면 없음', () {
      final at = DateTime(2026, 8, 12, 20);
      expect(dayMark([_c(1, at, reserved: true)]), HkDayMark.reserved);
      expect(dayMark([_c(1, at, waitlist: 2)]), HkDayMark.reserved);
      expect(dayMark([_c(1, at)]), HkDayMark.hasClass);
      expect(dayMark(const []), HkDayMark.none);
    });
  });

  testWidgets('수업 탭 — 날짜를 누르면 줄만, 화살표를 눌러야 운동이 열린다', (tester) async {
    await _pumpTab(tester);

    // 6) 두 칸 세그먼트는 없다 (되돌림 감지).
    expect(find.byType(HkSegment), findsNothing);
    expect(find.text('수업 시간'), findsNothing);
    expect(find.byKey(WeekBoard.kDayStrip), findsOneWidget);
    for (var i = 0; i < 7; i++) {
      expect(find.byKey(WeekBoard.dayKey(i)), findsOneWidget);
    }

    // 1) 오늘(수 12) 줄 = 20:00 SWEAT · 21:00 Olympic Lifting, 시작 시각 순.
    final lines = tester.widgetList<ClassLine>(find.byType(ClassLine)).toList();
    expect(lines.map((l) => l.timeLabel), ['20:00', '21:00']);
    expect(lines.map((l) => l.title), ['SWEAT', 'Olympic Lifting']);

    // 2) 들어오면 전부 닫혀 있다 — 자동으로 열리는 줄은 없다 (D112).
    expect(lines.every((l) => !l.expanded), isTrue);
    expect(find.byType(WodRow).evaluate().where((e) =>
        (e.widget as WodRow).headerless).isEmpty, isTrue);
    // 접힌 줄에는 시각·이름·정원·배지만 — 요약 줄이 없다.
    expect(find.textContaining('Back Squat 5-5-5회 · 100kg · KB Swing'), findsNothing);

    // 이름 옆 화살표(∨)가 줄마다 하나씩 — 누르면 그 줄이 열린다.
    expect(
      find.descendant(of: find.byType(ClassLine), matching: find.byIcon(Icons.expand_more)),
      findsNWidgets(2),
    );
    await tester.tap(find.byKey(WeekBoard.rowKey(101)));
    await tester.pumpAndSettle();

    // 4) 펼친 줄 = 파트 본문 (머리 없음 — 이름표 'SWEAT' 는 수업 줄이 이미 말했다).
    final headerless = tester.widgetList<WodRow>(find.byType(WodRow)).where((w) => w.headerless).toList();
    expect(headerless.length, 1);
    expect(headerless.single.wod.displayName, 'SWEAT');
    expect(find.text('A 파트 · 15분 · STRENGTH'.toUpperCase()), findsOneWidget);
    expect(find.textContaining('Plank 60초'), findsWidgets);
    expect(find.text('마지막 파트는 쿨다운.'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(ClassLine), matching: find.byIcon(Icons.expand_less)),
      findsOneWidget,
      reason: '열린 줄의 화살표는 ∧',
    );

    // 3) 오늘 수업이 없는 종류(AWAKE·BUILD)의 글은 '프로그램' 라벨 밑에 머리 포함 카드로.
    expect(find.text(WeekBoard.leftoverLabel.toUpperCase()), findsOneWidget);
    final cards = tester.widgetList<WodRow>(find.byType(WodRow)).where((w) => !w.headerless).toList();
    expect(cards.map((w) => w.wod.displayName ?? w.wod.templateName), ['AWAKE', 'BUILD']);
    expect(cards.every((w) => w.initiallyExpanded == false), isTrue,
        reason: 'D112 — 이 날의 모든 것은 닫힌 채로 시작한다');

    // 종류 없는 수업(Olympic Lifting)을 펼치면 글이 없다고 말한다.
    await tester.tap(find.byKey(WeekBoard.rowKey(102)));
    await tester.pumpAndSettle();
    expect(find.text('게시된 프로그램 없음.'), findsOneWidget);
    // 다시 누르면 닫힌다.
    await tester.tap(find.byKey(WeekBoard.rowKey(101)));
    await tester.pumpAndSettle();
    expect(find.text('A 파트 · 15분 · STRENGTH'.toUpperCase()), findsNothing);
  });

  testWidgets('내 예약이 있어도 자동으로 열리지 않는다 — 요일 띠 점만 주색', (tester) async {
    await _pumpTab(tester, world: {
      ...memberWorld(),
      '/api/v1/member/classes': memberClassesReserved(),
    });
    final lines = tester.widgetList<ClassLine>(find.byType(ClassLine)).toList();
    expect(lines.every((l) => !l.expanded), isTrue, reason: '예약이 있어도 닫힌 채로 (D112)');
    expect(find.text('예약됨'.toUpperCase()), findsOneWidget);
    // 오늘 칸(수 12)은 예약 점 — 칸 안 점의 색은 오늘 채움이라 흰색이지만 mark 는 reserved.
    final strip = tester.widget<HkDayStrip>(find.byKey(WeekBoard.kDayStrip));
    expect(strip.cells[2].mark, HkDayMark.reserved);
    expect(strip.cells[3].mark, HkDayMark.hasClass, reason: '목 13 AWAKE 06:00 — 수업만');
    expect(strip.cells[0].mark, HkDayMark.none);
  });

  testWidgets('날짜를 옮기면 전부 닫히고, 열어야 글이 보인다', (tester) async {
    await _pumpTab(tester);
    // 오늘 한 줄을 열어 둔 채로 날짜를 옮긴다 — 새 날은 다시 전부 닫혀 있어야 한다.
    await tester.tap(find.byKey(WeekBoard.rowKey(101)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(WeekBoard.dayKey(3)));
    await tester.pumpAndSettle();
    final lines = tester.widgetList<ClassLine>(find.byType(ClassLine)).toList();
    expect(lines.map((l) => l.title), ['AWAKE']);
    expect(lines.single.expanded, isFalse, reason: '날짜를 옮기면 닫힌 채로');
    // 오늘 열어 둔 줄로 돌아와도 닫혀 있다.
    await tester.tap(find.byKey(WeekBoard.dayKey(2)));
    await tester.pumpAndSettle();
    expect(tester.widgetList<ClassLine>(find.byType(ClassLine))
        .every((l) => !l.expanded), isTrue);
    await tester.tap(find.byKey(WeekBoard.dayKey(3)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(WeekBoard.rowKey(103)));
    await tester.pumpAndSettle();
    expect(find.text('아직 게시 전.'), findsOneWidget);
    expect(find.text(WeekBoard.leftoverLabel.toUpperCase()), findsNothing,
        reason: '내일은 글이 없다');
    // 주 이동 줄·요일 띠는 그대로 있다.
    expect(find.byKey(WeekBoard.kWeekNav), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
  });
}
