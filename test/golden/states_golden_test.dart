import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:facing_app/core/quotes.dart';
import 'package:facing_app/features/gym/gym_repository.dart';
import 'package:facing_app/features/gym/gym_state.dart';
import 'package:facing_app/features/history/history_screen.dart';
import 'package:facing_app/features/home/home_screen.dart';
import 'package:facing_app/features/shell/main_shell.dart';

import 'fakes.dart';
import 'harness.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

/// 상태 변형 골든 — 빈·에러·오프라인·미가입 (본편은 screens_golden_test.dart).
/// 골든스탠다드: 데이터 화면은 정상 외 상태도 실물 픽셀로 고정한다.
void main() {
  setUp(() {
    quoteRandom = Random(7);
  });

  // ── WOD 보드 로드 실패 — 박스는 있으나 wods 만 네트워크 에러 ──
  testWidgets('state: wod board error', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api =
        FakeApi(memberWorld(), errorPaths: {'/api/v1/gyms/1/wods'});
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: const MainShell()));
    await capture(tester, 'state_01_wod_error');
  });

  // ── 박스 미가입 — 신규 가입 직후 (gym=null) ──
  testWidgets('state: no gym', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final world = memberWorld()..['/api/v1/gyms/mine'] = gymsMineEmpty;
    final api = FakeApi(world);
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: const MainShell()));
    await capture(tester, 'state_02_wod_nogym');
  });

  // ── 승인 대기 — 신청은 냈고 코치 승인 전 (v2.8: 셸 전체가 이 화면으로 대체) ──
  testWidgets('state: pending approval', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final world = memberWorld()..['/api/v1/gyms/mine'] = gymsMinePending;
    final api = FakeApi(world);
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: const MainShell()));
    await capture(tester, 'state_05_pending');
  });

  // ── 오프라인 배너 — Home 화면 상단 OFFLINE 밴드 ──
  testWidgets('state: home offline', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        connectivity: OfflineConnectivity(),
        home: const HomeScreen()));
    await capture(tester, 'state_03_home_offline');
  });

  // ── 이력 로드 실패 — 네트워크 에러 ──
  testWidgets('state: history error', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    // 두 탭 모두 에러 — retainError(core/futures.dart) 적용 전엔 숨은 WOD 탭
    // future 가 unhandled 로 테스트를 죽였다. 이 캡처가 그 픽스의 회귀 게이트.
    final api = FakeApi(memberWorld(), errorPaths: {'/api/v1/history'});
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const HistoryScreen()));
    await capture(tester, 'state_04_history_error');
  });
}
