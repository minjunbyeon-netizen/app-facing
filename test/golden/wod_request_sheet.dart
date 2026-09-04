/// 수업 상세 '코치에게 요청' 시트를 띄우는 **상태 절차** — 골든과 좌표 검사가
/// 같은 길로 들어가게 한다 (로그인의 `login_states.dart` 와 같은 결).
///
/// D118 (2026-09-05) — 이 시트는 `stability_wod_test` 의 앵커 밖이라 밀림 후보
/// 4번이 미검사로 남아 있었다. 시트는 화면이 아니라 **모달**이라 pumpWidget 한
/// 번으로는 못 만든다: 상세 화면을 세우고 → '코치에게 요청' 을 누르고 → 시트가
/// 뜨기를 기다린다. 그 세 걸음을 여기 한 곳에 둔다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/gym/wod_detail_screen.dart';

import 'fakes.dart';
import 'harness.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

/// 시트를 띄울 수업 — 골든 세계(`gymWods()`)의 SWEAT 한 건.
const int wodId = 31;

/// 앞 상태의 State 를 확실히 버린다. `pumpWidget` 은 같은 타입의 트리를 만나면
/// 갱신만 해서 State(=시트 안 입력값·에러)를 그대로 물려준다 — 그러면 상태를
/// 바꿔 끼워도 화면이 앞 상태 그대로라 검사가 헛돈다.
Future<void> _reset(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

/// 수업 상세 한 판. 시트가 뜰 바탕이다.
Future<void> pumpWodDetail(WidgetTester tester) async {
  await _reset(tester);
  phone(tester);
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final api = FakeApi(memberWorld());
  final gym = GymState(GymRepository(FakeApi(memberWorld())), sse: FakeSse());
  await gym.loadMine();
  final wod = gym.wods.firstWhere((w) => w.id == wodId);
  await tester.pumpWidget(
    harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      gym: gym,
      home: WodDetailScreen(wod: wod),
    ),
  );
  await tester.pumpAndSettle();
}

/// 상세 → '코치에게 요청' 탭 → 시트가 올라온 상태.
Future<void> openRequestSheet(WidgetTester tester) async {
  await pumpWodDetail(tester);
  // 상세는 한 화면보다 길다 — 목록을 내려 버튼을 실제로 보이게 한 뒤 누른다.
  await tester.ensureVisible(find.byKey(WodDetailScreen.kRequestOpen));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(WodDetailScreen.kRequestOpen));
  await tester.pumpAndSettle();
}

/// (a) 갓 열린 시트 — 아직 아무것도 안 눌렀다.
Future<void> requestSheetIdle(WidgetTester tester) async {
  await openRequestSheet(tester);
  expect(find.byKey(WodDetailScreen.kRequestSend), findsOneWidget);
  expect(find.text(WodDetailScreen.requestEmptyBody), findsNothing);
}

/// (b) 내용을 비운 채 보내기 — 검증 실패 문구가 뜬 시트.
///
/// 사람이 가장 쉽게 만나는 실패다: 제목만 적고 보내기를 누른다.
Future<void> requestSheetEmptyError(WidgetTester tester) async {
  await openRequestSheet(tester);
  await tester.enterText(find.byKey(WodDetailScreen.kRequestSubject), '어깨 대체');
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(WodDetailScreen.kRequestSend));
  await tester.pumpAndSettle();
  // 정말 그 상태인지 못 박는다 — 아니면 두 상태가 사실 같은 그림이다.
  expect(find.text(WodDetailScreen.requestEmptyBody), findsOneWidget);
}
