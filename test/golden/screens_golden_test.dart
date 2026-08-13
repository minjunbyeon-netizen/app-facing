import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/core/quotes.dart';
import 'package:hyphen_app/features/boss/boss_dashboard_screen.dart';
import 'package:hyphen_app/features/auth/auth_state.dart';
import 'package:hyphen_app/features/auth/signup_screen.dart';
import 'package:hyphen_app/features/boss/boss_login_screen.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/history/history_screen.dart';
import 'package:hyphen_app/features/intro/intro_screen.dart';
import 'package:hyphen_app/features/onboarding/onboarding_basic.dart';
import 'package:hyphen_app/features/mypage/mypage_screen.dart';
import 'package:hyphen_app/features/profile/profile_state.dart';
import 'package:hyphen_app/features/shell/main_shell.dart';
import 'package:hyphen_app/features/signup/self_signup_screen.dart';
import 'package:hyphen_app/features/splash/splash_screen.dart';

import 'fakes.dart';
import 'harness.dart';

/// 전 화면 골든 캡처 — 갱신: flutter test --update-goldens test/golden
/// 산출물: test/golden/goldens/*.png (갤러리: python tool/golden_gallery.py)
///
/// 골든스탠다드(writeplz-app) 규칙:
/// - 가짜 백엔드(fakes.dart) 로 네트워크 0, 실물 픽셀 렌더 (갤S22 급 360×780·2x)
/// - --update-goldens 없이 실행하면 회귀 게이트 (1픽셀 차이도 실패)
/// - 기능을 넣으면 그 상태의 캡처도 같이 넣는다 (골든 없는 기능 = 골든스탠다드 미달)

/// 회원가입 완료 + RX 등급 확정 상태의 로컬 프로필.
/// v2.2 (2026-08-12): 앱에서 페르소나·데모 화면을 전부 걷어내면서
/// `_debug/persona_debug_data.dart` 가 사라졌다 — 골든이 쓰던 값만 여기로 옮긴다.
/// (프로덕션 코드가 아니라 캡처용 고정 입력이므로 테스트 쪽에 두는 것이 맞다.)
const Map<String, dynamic> _kRxGrade = {
  'overall_number': 3,
  'overall_score': 3.3,
  'overall': 'RX',
  'overall_label_ko': 'RX',
  'power': {'score': 3.1},
  'olympic': {'score': 3.0},
  'gymnastics': {'score': 3.3},
  'cardio': {'score': 3.5},
  'metcon': {'score': 3.4},
  'body_composition': {'score': 3.2},
};

const Map<String, double> _kRxBenchmarks = {
  'back_squat_1rm_lb': 285.0,
  'deadlift_1rm_lb': 375.0,
  'clean_1rm_lb': 205.0,
  'strict_pull_up_max_ub': 15.0,
  'run_mile_sec': 420.0,
};

ProfileState rxProfile() {
  final p = ProfileState();
  p.applyPersonaSnapshot(
    bodyWeightKg: 78.0,
    heightCm: 175.0,
    ageYears: 26.0,
    gender: 'male',
    experienceYears: 3.0,
    benchmarks: _kRxBenchmarks,
    gradeResult: _kRxGrade,
  );
  return p;
}

/// 소셜 로그인 완료 상태 AuthState. 호출 전 setMockInitialValues 필수.
Future<AuthState> signedInAuth() async {
  final a = AuthState();
  await a.load();
  return a;
}

Map<String, Object> signedInPrefs() => {
      'auth_signed_in': true,
      'auth_provider': 'naver',
      'auth_display_name': '김민준',
      'auth_signed_at': '2026-07-01T09:00:00Z',
      'intro_seen': true,
      'shell_tab_hint_shown_v6': true,
    };

void main() {
  setUp(() {
    // 캡처 결정론 — 명언 랜덤을 시드 고정으로 교체.
    quoteRandom = Random(7);
  });

  // ── 공통: 스플래시 (자동 전환 전 로딩 상태) ──
  testWidgets('common: splash', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: AuthState(),
        profile: ProfileState(),
        home: const SplashScreen()));
    await tester.pump(const Duration(milliseconds: 900));
    await capture(tester, 'common_01_splash'); // 애니메이션 완료(1.3s) 시점
    // splashMin(2.5s) 타이머 flush — 스텁 라우트로 자동 전환시켜 pending timer 제거.
    await tester.pump(const Duration(seconds: 4));
  });

  // ── 공통: 인트로 2p (v2.6 — BOARD → EARN. TIER 는 폐기) ──
  testWidgets('common: intro 2p', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: AuthState(),
        profile: ProfileState(),
        home: const IntroScreen()));
    await capture(tester, 'common_02_intro_board');
    await tester.tap(find.text('다음'));
    await tester.pump(const Duration(milliseconds: 300));
    await capture(tester, 'common_03_intro_earn');
    // v2.6: 3p 'Tier' 는 화면에서 삭제됐다 (없는 기능 약속 제거).
  });

  // ── 공통: 소셜 로그인 ──
  testWidgets('common: signup', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: AuthState(),
        profile: ProfileState(),
        home: const SignupScreen()));
    await precacheAllImages(tester);
    await capture(tester, 'common_05_signup');
  });

  // ── 공통: 가입 신청서 (v2.8 — 이름·생년월일·성별·연락처·경력·종목·부상) ──
  // 한 화면에 다 안 들어가 위·아래 두 장으로 나눠 찍는다.
  testWidgets('common: self signup', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: AuthState(),
        profile: ProfileState(),
        home: const SelfSignupScreen()));
    await capture(tester, 'common_06_self_signup');
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -420));
    await tester.pump(const Duration(milliseconds: 200));
    await capture(tester, 'common_07_self_signup_scrolled');
  });


  // ── 온보딩: 기본 정보 → Benchmarks → Tier 결과 ──
  testWidgets('onboarding: basic', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: ProfileState(),
        home: const OnboardingBasicScreen()));
    await capture(tester, 'onb_01_basic');
  });

  // v2.6 (2026-08-13): Benchmarks·Tier 결과 화면은 진입점이 없어졌다
  // (프로필 수정에서 Benchmarks 카드 삭제 — D34 의 연장). 화면 코드는 살아
  // 있으나 회원이 도달할 수 없으므로 골든에서 뺀다. 진입점을 되살리면 이 두
  // 캡처도 같이 되살릴 것.

  testWidgets('member: shell 3 tabs', (tester) async {
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
        home: const MainShell()));
    await capture(tester, 'member_01_shell_wod');
    await tapTab(tester, '홈');
    await capture(tester, 'member_02_shell_home');
    await tapTab(tester, '프로필');
    await capture(tester, 'member_03_shell_profile');
    // v1.31 — 프로필 하단 메뉴. 접힘이 기본(헤더 한 줄) → 펼치면 표 1개.
    // 상단 캡처(member_03)는 프레임 밖이라 이 구역을 못 덮는다.
    // 2단 스크롤: ① scrollUntilVisible 로 sliver 가 이 구역을 build 하게 만들고
    // (아직 트리에 없으면 ensureVisible 은 "No element"), ② ensureVisible 로
    // 실제 뷰포트에 정렬한다 (scrollUntilVisible 은 build 되면 화면 밖이어도 멈춤).
    // .first = 세로 ListView — Engine 카테고리 등 가로 스크롤러가 같이 잡힌다.
    final profileScroll = find
        .descendant(
          of: find.byType(MyPageScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(find.text('메뉴'), 300,
        scrollable: profileScroll);
    await tester.ensureVisible(find.text('메뉴'));
    await tester.pump(const Duration(milliseconds: 100));
    await capture(tester, 'member_04_profile_menu');
    await tester.tap(find.text('메뉴'));
    // 펼침 애니메이션이 레이아웃에 반영될 때까지 프레임을 여러 번 돌린다.
    // 한 번만 pump 하면 maxScrollExtent 가 아직 안 늘어 드래그가 먹지 않는다.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // 표 하단(이용약관·데이터 초기화)까지 올린다. ensureVisible 은 여기서
    // 스크롤을 안 움직여(대상이 이미 build 된 상태) 고정 드래그로 처리.
    await tester.drag(profileScroll, const Offset(0, -420));
    await tester.pump(const Duration(milliseconds: 200));
    await capture(tester, 'member_05_profile_menu_open');
  });

  // ── WOD 결과 입력 시트 (v2.6 · 사용자 요청) ──
  // 회원이 실제로 도달하는 경로 그대로 탄다: WOD 탭 → 오늘 WOD(기본 펼침)의
  // '완료 표시' 배지 탭 → 바텀시트. 시트만 따로 pump 하면 진입점이 살아 있는지는
  // 증명하지 못한다 (명단 시트 golden 과 같은 방식).
  testWidgets('member: wod result sheet', (tester) async {
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
        home: const MainShell()));
    await tester.tap(find.text('완료 표시').first);
    await tester.pumpAndSettle();
    await capture(tester, 'member_06_result_sheet');
  });

  // ── 사장 대시보드 ──
  testWidgets('boss: dashboard', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    final api = FakeApi(memberWorld());
    final bossApi =
        FakeBossApi({'/api/v1/admin/gyms/1/dashboard': bossDashboard()});
    await tester.pumpWidget(harness(
        api: api,
        auth: AuthState(),
        profile: ProfileState(),
        bossAuth: FakeBossAuth(),
        bossApi: bossApi,
        home: const BossDashboardScreen()));
    await capture(tester, 'boss_02_dashboard');
  });

  // ── 수업 예약자 명단 시트 (D29) ──
  testWidgets('boss: class roster sheet', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    final api = FakeApi(memberWorld());
    final bossApi = FakeBossApi({
      '/api/v1/admin/gyms/1/dashboard': bossDashboard(),
      '/api/v1/admin/classes/101/reservations': classRoster(),
    });
    await tester.pumpWidget(harness(
        api: api,
        auth: AuthState(),
        profile: ProfileState(),
        bossAuth: FakeBossAuth(),
        bossApi: bossApi,
        home: const BossDashboardScreen()));
    await tester.pumpAndSettle();
    // 오늘 수업 첫 카드(class 101) 탭 → 명단 시트.
    await tester.tap(find.text('WOD Class').first);
    await tester.pumpAndSettle();
    await capture(tester, 'boss_03_class_roster');
  });

  // ── 이력 (빈 상태) ──
  testWidgets('history: empty', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const HistoryScreen()));
    await capture(tester, 'hist_01_empty');
  });

  // ── 사장 로그인 ──
  testWidgets('boss: login', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: AuthState(),
        profile: ProfileState(),
        home: const BossLoginScreen()));
    await capture(tester, 'boss_01_login');
  });
}

