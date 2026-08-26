import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/core/app_clock.dart';
import 'package:hyphen_app/core/goals_state.dart';
import 'package:hyphen_app/core/quotes.dart';
import 'package:hyphen_app/features/auth/auth_state.dart';
import 'package:hyphen_app/features/auth/login_screen.dart';
import 'package:hyphen_app/features/boss/boss_dashboard_screen.dart';
import 'package:hyphen_app/features/gym/box_wod_screen.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/history/history_screen.dart';
import 'package:hyphen_app/features/profile/profile_state.dart';
import 'package:hyphen_app/features/home/home_screen.dart';
import 'package:hyphen_app/features/shell/coach_shell.dart';
import 'package:hyphen_app/features/signup/self_signup_screen.dart';
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
    final api = FakeApi(memberWorld(), errorPaths: {'/api/v1/gyms/1/wods'});
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: const MainShell(),
      ),
    );
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
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: const MainShell(),
      ),
    );
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
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: const MainShell(),
      ),
    );
    await capture(tester, 'state_05_pending');
  });

  // ── 오프라인 배너 — Home 화면 상단 OFFLINE 밴드 ──
  testWidgets('state: home offline', (tester) async {
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
        connectivity: OfflineConnectivity(),
        home: const HomeScreen(),
      ),
    );
    await capture(tester, 'state_03_home_offline');
  });

  // ── 이력 로드 실패 — 네트워크 에러 ──
  testWidgets('state: history error', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    // 두 탭 모두 에러 — retainError(core/futures.dart) 적용 전엔 숨은 WOD 탭
    // future 가 unhandled 로 테스트를 죽였다. 이 캡처가 그 픽스의 회귀 게이트.
    final api = FakeApi(memberWorld(), errorPaths: {'/api/v1/history'});
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const HistoryScreen(),
      ),
    );
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
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: const BoxWodScreen(),
      ),
    );
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
  // ── 수업 시작 전 명단 — 출석·노쇼 배지 잠금 (S3 픽스, 2026-08-26) ──
  // 서버 CLASS_NOT_STARTED 409 와 짝. 시작 전엔 상태 라벨만 보이고 안내 한 줄.
  testWidgets('state: class roster before start', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    final api = FakeApi(memberWorld());
    final bossApi = FakeBossApi({
      '/api/v1/admin/gyms/1/dashboard': bossDashboard(),
      '/api/v1/admin/gyms/1/classes': memberClasses(),
      '/api/v1/admin/classes/101/reservations': classRosterUpcoming(),
    });
    await tester.pumpWidget(
      harness(
        api: api,
        auth: AuthState(),
        profile: ProfileState(),
        bossAuth: FakeBossAuth(),
        bossApi: bossApi,
        home: const BossDashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('WOD Class').first);
    await tester.pumpAndSettle();
    expect(find.text('출석 체크는 수업 시작 후'), findsOneWidget);
    await capture(tester, 'state_10_roster_before_start');
  });

  testWidgets('state: login remembered id', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({
      'remembered_login_id': 'seojun',
      'remembered_login_until': appClock
          .now()
          .add(const Duration(days: 30))
          .millisecondsSinceEpoch,
    });
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(
      harness(
        api: api,
        auth: AuthState(),
        profile: ProfileState(),
        home: const LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('아이디 기억하기 (30일)'), findsOneWidget);
    await capture(tester, 'state_09_login_remembered');
  });

  // ── 회원권 없음 — 예약 배지가 '회원권 필요' (S5 · 2026-08-26 MEMBERSHIP_REQUIRED) ──
  testWidgets('state: classes membership required', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      ...memberWorld(),
      '/api/v1/member/me/memberships': memberMembershipsExpired(),
    });
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
    expect(find.text('회원권 필요'), findsWidgets);
    await capture(tester, 'state_11_class_membership_required');
  });

  // ── 예약 오픈 전 — 모레 수업 배지가 '오픈 전' (D58 · 2026-08-26 전날 11시 오픈) ──
  testWidgets('state: classes booking not open', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      ...memberWorld(),
      '/api/v1/member/classes': memberClassesBookingNotOpen(),
    });
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
    // 모레 날짜 행을 펼친다 — 요일 헤더 텍스트는 날짜에 따라 달라 AWAKE 수업이 든 날을 찾는다.
    final dayAfter = appClock.now().add(const Duration(days: 2));
    await tester.tap(find.text('${dayAfter.day}').first);
    await tester.pumpAndSettle();
    expect(find.text('오픈 전'), findsOneWidget);
    await capture(tester, 'state_15_class_booking_not_open');
  });

  // ── 횟수권 — 내 정보 회원권 카드 잔여·면제 표시 (D57 · 2026-08-26) ──
  testWidgets('state: mypage session pass', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      ...memberWorld(),
      '/api/v1/member/me/memberships': memberMembershipsSessionPass(),
    });
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: const MainShell(),
      ),
    );
    await tester.pumpAndSettle();
    await tapTab(tester, '내 정보');
    expect(find.textContaining('2회 남음'), findsWidgets);
    // 아코디언을 펼쳐 카드(사용/잔여 막대 · 면제 잔여)까지 보이게.
    await tester.tap(find.text('회원권').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('노쇼 면제 1회'), findsOneWidget);
    await capture(tester, 'state_14_mypage_session_pass');
  });

  // ── 코치 로그아웃 확인 다이얼로그 (S10 · 2026-08-26) ──
  testWidgets('state: coach logout dialog', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      ...memberWorld(),
      '/api/v1/gyms/mine': {...gymsMine, 'role': 'owner'},
      '/api/v1/gyms/1/members': gymMembersList(),
    });
    final bossApi = FakeBossApi({
      '/api/v1/admin/gyms/1/dashboard': bossDashboard(),
      '/api/v1/admin/gyms/1/classes': memberClasses(),
    });
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        bossAuth: FakeBossAuth(),
        bossApi: bossApi,
        home: const CoachShell(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('로그아웃'));
    await tester.pumpAndSettle();
    expect(find.text('로그아웃하면 이 기기와 코치 연결이 끊깁니다.\n'
        '다시 로그인하면 그대로 이어집니다.'), findsOneWidget);
    await capture(tester, 'state_12_coach_logout_dialog');
  });

  // ── 가입 폼 BACK — 입력이 있으면 '작성을 그만둘까요?' (S6 · 2026-08-26) ──
  testWidgets('state: signup back dialog', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(
      harness(
        api: api,
        auth: AuthState(),
        profile: ProfileState(),
        home: const SelfSignupScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '김서준');
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(Scaffold))).maybePop();
    await tester.pumpAndSettle();
    expect(find.text('작성을 그만둘까요?'), findsOneWidget);
    await capture(tester, 'state_13_signup_back_dialog');
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
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        goals: goals,
        home: const MainShell(),
      ),
    );
    await tapTab(tester, '내 정보');
    await capture(tester, 'state_06_worn_title');
  });
}
