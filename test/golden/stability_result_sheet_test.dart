// 완료 시트 레이아웃 안정성 — 저장 버튼·고지 줄이 '저장 중' 으로 바뀌어도 밀리지 않는다.
//
// 2026-08-30 저장 중 토스트를 붙이며 버튼을 `HkLoading` 스왑(높이 22)에서 자리 그대로
// busy(높이 52)로 바꿨다 — 종전엔 누르는 순간 아래 고지 줄이 30px 위로 튀었다.
// 정본 규칙 = docs/DESIGN-SSOT.md §레이아웃 안정성 (로딩 스왑 밀림 금지).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/gym/wod_result_sheet.dart';
import 'package:hyphen_app/models/gym.dart';

import 'fakes.dart';
import 'harness.dart';
import 'layout_stability.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

void main() {
  const resultsPath = '/api/v1/gyms/1/wods/31/results';

  Future<void> mount(
    WidgetTester tester, {
    bool hang = false,
    bool fail = false,
  }) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(
      memberWorld(),
      hangPaths: hang ? {resultsPath} : const {},
      errorPaths: fail ? {resultsPath} : const {},
    );
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    final post = GymWodPost.fromJson(
      gymWods().firstWhere((p) => p['id'] == 31),
    );
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: Scaffold(
          body: SingleChildScrollView(child: WodResultSheet(wod: post)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 시트가 화면보다 길다 — 두 상태 모두 같은 만큼 내려 버튼을 보이게 한 뒤 잰다.
    await tester.ensureVisible(find.byKey(kWodSaveButton));
    await tester.pumpAndSettle();
  }

  testWidgets('완료 시트: 저장 버튼·고지 줄은 저장 중에도 같은 y', (tester) async {
    await expectStableAnchorY(
      tester,
      states: {
        '대기': (t) => mount(t),
        '저장 중': (t) async {
          await mount(t, hang: true);
          await t.tap(find.byKey(kWodSaveButton));
          await t.pump(const Duration(milliseconds: 300));
          expect(find.text(kWodSavingTitle), findsOneWidget);
        },
      },
      anchors: {
        '저장 버튼': kWodSaveButton,
        '고지 줄': kWodSaveCaption,
      },
    );
  });

  // D117 (2026-09-04) — 에러 상태가 검사 밖이었다.
  // 저장이 실패하면 `if (_error != null) ...[` 블록이 **저장 버튼 바로 위**에 생겨
  // 버튼과 고지 줄을 통째로 밀어 내린다. 사람이 다시 누르려던 버튼이 손가락
  // 아래에서 도망간다 — 실패 직후가 가장 다시 누르기 쉬운 순간인데 그렇다.
  // 정본 규칙 = docs/DESIGN-SSOT.md §레이아웃 안정성 (밀림 2번 — 조건부 블록).
  testWidgets('완료 시트: 저장이 실패해도 버튼·고지 줄은 같은 y', (tester) async {
    await expectStableAnchorY(
      tester,
      states: {
        '대기': (t) => mount(t),
        '저장 실패': (t) async {
          await mount(t, fail: true);
          await t.tap(find.byKey(kWodSaveButton));
          await t.pumpAndSettle();
          // 실패 문구가 실제로 떠 있는 상태에서 재야 의미가 있다
          expect(find.byKey(kWodSaveButton), findsOneWidget);
        },
      },
      anchors: {
        '저장 버튼': kWodSaveButton,
        '고지 줄': kWodSaveCaption,
      },
    );
  });
}
