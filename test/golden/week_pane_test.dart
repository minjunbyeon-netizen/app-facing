import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/classes/class_line.dart';
import 'package:hyphen_app/features/gym/box_wod_screen.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/gym/week_board.dart';
import 'package:hyphen_app/features/gym/wod_row.dart';

import 'fakes.dart';
import 'harness.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

/// 수업 탭 두 칸 회귀 게이트 (v3.37 · 2026-08-29 테스터 지시 "수업에는 수업
/// 시간표에 대한 내용만 있어야 합니다. 프로그램과 수업은 분리시킵니다").
///
/// 지키는 약속은 셋이다.
/// 1. 수업 시간 칸에는 프로그램이 **안 나온다** — 예약하러 온 사람이 운동 설명을
///    지나칠 일이 없다.
/// 2. 프로그램 칸에는 수업 시간 줄이 **안 나온다** — 두 칸이 다시 한 덩어리로
///    합쳐지는 것을 막는다.
/// 3. 칸을 바꿔도 보던 주가 유지된다 — 주는 두 칸이 함께 쓴다.
///
/// 되돌림 확인 (2026-08-29): 칸을 나누기 전 코드(한 카드에 프로그램+수업 시간을
/// 세로로 쌓던 week_board.dart)로 되돌리면 1번이 `WodRow` 를 찾아내 실패한다.

/// 고정 시계 = 2026-08-12(수) 10:30 → 그 주 월요일은 8.10, 일요일은 8.16.
const String _thisWeekLabel = '8.10 – 8.16';
const String _lastWeekLabel = '8.3 – 8.9';

Future<void> _pumpTab(WidgetTester tester) async {
  phone(tester);
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final api = FakeApi(memberWorld());
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
}

/// 칸은 이름으로 누른다 — 사람이 화면에서 하는 것과 같은 조작.
Future<void> _tapPane(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(WeekBoard.kPaneSwitch),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('수업 시간 칸 — 수업 줄만 있고 프로그램은 없다', (tester) async {
    await _pumpTab(tester);

    // 기본 진입이 수업 시간이다 (예약이 이 탭의 주 목적).
    expect(find.byType(ClassLine), findsWidgets);
    // 프로그램은 옆 칸의 것 — 한 조각도 새어 나오지 않아야 한다.
    expect(find.byType(WodRow), findsNothing);
    expect(find.byType(LockedWodBanner), findsNothing);
    expect(find.textContaining('Thruster'), findsNothing);
  });

  testWidgets('프로그램 칸 — 프로그램만 있고 수업 시간 줄은 없다', (tester) async {
    await _pumpTab(tester);
    await _tapPane(tester, WeekBoard.paneProgram);

    expect(find.byType(WodRow), findsWidgets);
    // 수업 시간 줄(과 그 오른쪽 예약 배지)은 옆 칸의 것.
    expect(find.byType(ClassLine), findsNothing);
    expect(find.text('예약'), findsNothing);
    expect(find.text('대기'), findsNothing);
  });

  testWidgets('칸을 바꿔도 보던 주가 유지된다', (tester) async {
    await _pumpTab(tester);
    expect(find.text(_thisWeekLabel), findsOneWidget);

    // 지난주로 이동 → 그 주를 보는 채로 칸만 바꾼다.
    await tester.tap(find.byTooltip('이전 주'));
    await tester.pumpAndSettle();
    expect(find.text(_lastWeekLabel), findsOneWidget);

    await _tapPane(tester, WeekBoard.paneProgram);
    expect(find.text(_lastWeekLabel), findsOneWidget);
    expect(find.text(_thisWeekLabel), findsNothing);

    // 돌아와도 마찬가지 — 주는 두 칸이 함께 쓴다.
    await _tapPane(tester, WeekBoard.paneSchedule);
    expect(find.text(_lastWeekLabel), findsOneWidget);
  });
}
