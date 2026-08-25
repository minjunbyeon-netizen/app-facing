import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/auth/auth_state.dart';
import 'package:hyphen_app/features/profile/profile_state.dart';
import 'package:hyphen_app/features/splash/splash_screen.dart';

import 'fakes.dart';
import 'harness.dart';

/// 스플래시 C안 연출을 단계별로 고정한다 (2026-08-22 대표 확정).
/// 연출이 2.45초 안에 다 지나가서 한 장짜리 캡처로는 "카드만 나오는 구간"과
/// "로고만 남는 구간"이 갈렸는지 확인할 수 없다 — 실제 스플래시 화면을
/// 시점만 달리해 찍는다 (위젯 단독 렌더는 배치가 달라 쓸 수 없다).
void main() {
  Future<void> shot(WidgetTester tester, String name, Duration at) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      harness(
        api: FakeApi(memberWorld()),
        auth: AuthState(),
        profile: ProfileState(),
        home: const SplashScreen(),
      ),
    );
    // 이미지 디코딩을 먼저 끝낸다 — 안 하면 카드가 빈 칸으로 찍힌다.
    await precacheAllImages(tester);
    await tester.pump(at);
    await expectLater(
      find.byType(SplashScreen),
      matchesGoldenFile('goldens/$name.png'),
    );
    // splashMin(2.5s) 타이머 flush — 스텁 라우트로 전환시켜 pending timer 제거.
    await tester.pump(const Duration(seconds: 4));
  }

  testWidgets('스플래시 C안 ① 카드만 (로고 없음)', (tester) async {
    await shot(tester, 'splash_c1_deck', const Duration(milliseconds: 1150));
  });

  testWidgets('스플래시 C안 ② 중앙으로 빨려듦', (tester) async {
    await shot(tester, 'splash_c2_suck', const Duration(milliseconds: 1520));
  });

  testWidgets('스플래시 C안 ③ 로고만', (tester) async {
    await shot(tester, 'splash_c3_logo', const Duration(milliseconds: 2050));
  });
}
