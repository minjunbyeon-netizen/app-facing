// 수업 탭이 **불러오기 실패를 '체육관 미가입' 으로 말하지 않는다** (D118 · 2026-09-05).
//
// 실기(에뮬레이터) 확인에서 승인된 회원이 로그인 직후 '체육관 미가입' 을 봤다.
// 화면 코드가 `hasGym` 만 보고 있었기 때문이다 — 못 읽은 것과 소속이 없는 것이
// 같은 문장으로 나왔고, 다시 시도할 길도 없어 앱을 껐다 켜야 했다.
// 같은 병을 홈 도전 섹션에서도 고쳤다(D118 #7) — 제품 제1원칙: 화면은 거짓말하지 않는다.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/gym/box_wod_screen.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';

import 'fakes.dart';
import 'harness.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

void main() {
  Future<GymState> mount(WidgetTester tester, {required bool fail}) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(
      memberWorld(),
      errorPaths: fail ? {'/api/v1/gyms/mine'} : const {},
    );
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

  testWidgets('수업 탭 — 불러오기 실패는 에러로 말한다 (미가입 아님)', (tester) async {
    final gym = await mount(tester, fail: true);

    expect(gym.error, isNotNull, reason: '전제가 깨졌다 — 실패를 만들지 못했다');
    expect(
      find.text('체육관 미가입'),
      findsNothing,
      reason: '못 읽은 것을 소속이 없다고 말하고 있다 (화면이 거짓말한다)',
    );
    expect(find.text('다시 시도'), findsOneWidget, reason: '다시 시도할 길이 없다');
  });

  testWidgets('수업 탭 — 정말 소속이 없으면 그대로 미가입', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final world = memberWorld()..['/api/v1/gyms/mine'] = gymsMineEmpty;
    final api = FakeApi(world);
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

    expect(gym.error, isNull);
    expect(find.text('체육관 미가입'), findsOneWidget);
  });
}
