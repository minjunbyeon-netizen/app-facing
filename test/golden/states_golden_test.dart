import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/core/app_clock.dart';
import 'package:hyphen_app/core/goals_state.dart';
import 'package:hyphen_app/core/quotes.dart';
import 'package:hyphen_app/features/auth/auth_state.dart';
import 'package:hyphen_app/features/auth/member_login_screen.dart';
import 'package:hyphen_app/features/classes/classes_screen.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/history/history_screen.dart';
import 'package:hyphen_app/features/profile/profile_state.dart';
import 'package:hyphen_app/features/home/home_screen.dart';
import 'package:hyphen_app/features/shell/main_shell.dart';

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
  // ── 종료 수업 — 버튼 숨김 + '종료' 배지 (2026-08-24 CLASS_ENDED 게이트 UX) ──
  testWidgets('state: classes ended card', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      ...memberWorld(),
      '/api/v1/member/classes': memberClassesWithEnded(),
    });
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: const ClassesScreen()));
    await capture(tester, 'state_07_class_ended');
  });

  // ── 대기 취소 다이얼로그 — 대기자 이탈 경로 (G30 픽스, 2026-08-24) ──
  // 종전엔 대기 카드 '취소' 버튼이 예약 행이 없어 조용히 무동작이었다.
  testWidgets('state: waitlist cancel dialog', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      ...memberWorld(),
      '/api/v1/member/classes': memberClassesWaitlisted(),
    });
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: const ClassesScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('대기를 취소할까요?'), findsOneWidget);
    await capture(tester, 'state_08_waitlist_cancel_dialog');
  });

  _wornTitleGoldens();
  _rememberedLoginGolden();
}

// ── v3.18 (2026-08-25) 아이디 기억하기 ──
// 30일 안에 로그인한 적이 있으면 아이디가 채워진 채 열린다 (비밀번호는 저장 X).
// 체크가 켜진 상태를 고정해 둔다 — 빈 로그인 화면은 boss_01·common_08 이 이미 있다.
void _rememberedLoginGolden() {
  testWidgets('state: login remembered id', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({
      'remembered_login_id_member': 'seojun',
      'remembered_login_until_member':
          appClock.now().add(const Duration(days: 30)).millisecondsSinceEpoch,
    });
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
      api: api,
      auth: AuthState(),
      profile: ProfileState(),
      home: const MemberLoginScreen(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('아이디 기억하기 (30일)'), findsOneWidget);
    await capture(tester, 'state_09_login_remembered');
  });
}

// ── v3.12 (2026-08-23) 착용 칭호 ──
// 업적 화면에서 고른 칭호가 내 정보 이름 아래에 붙는지의 시각 게이트.
// 고르는 자리는 있는데 드러나는 자리가 없어 아무도 못 보던 값이라,
// 노출을 붙이면서 캡처도 같이 남긴다 (골든 없는 기능 = 골든스탠다드 미달).
void _wornTitleGoldens() {
  testWidgets('state: profile worn title', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    final goals = GoalsState();
    await goals.load();
    await goals.setWornTitle('PB_WEEKEND'); // '주말반'
    await tester.pumpWidget(harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      gym: gym,
      goals: goals,
      home: const MainShell(),
    ));
    await tapTab(tester, '내 정보');
    await capture(tester, 'state_06_worn_title');
  });
}
