import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:facing_app/core/quotes.dart';
import 'package:facing_app/features/boss/boss_dashboard_screen.dart';
import 'package:facing_app/features/_debug/persona_debug_data.dart';
import 'package:facing_app/features/auth/auth_state.dart';
import 'package:facing_app/features/auth/signup_screen.dart';
import 'package:facing_app/features/boss/boss_login_screen.dart';
import 'package:facing_app/features/gym/gym_repository.dart';
import 'package:facing_app/features/gym/gym_state.dart';
import 'package:facing_app/features/history/history_screen.dart';
import 'package:facing_app/features/intro/intro_screen.dart';
import 'package:facing_app/features/onboarding/onboarding_basic.dart';
import 'package:facing_app/features/onboarding/onboarding_benchmarks.dart';
import 'package:facing_app/features/onboarding/onboarding_grade.dart';
import 'package:facing_app/features/profile/profile_state.dart';
import 'package:facing_app/features/shell/main_shell.dart';
import 'package:facing_app/features/splash/splash_screen.dart';

import 'fakes.dart';
import 'harness.dart';

/// 전 화면 골든 캡처 — 갱신: flutter test --update-goldens test/golden
/// 산출물: test/golden/goldens/*.png (갤러리: python tool/golden_gallery.py)
///
/// 골든스탠다드(writeplz-app) 규칙:
/// - 가짜 백엔드(fakes.dart) 로 네트워크 0, 실물 픽셀 렌더 (갤S22 급 360×780·2x)
/// - --update-goldens 없이 실행하면 회귀 게이트 (1픽셀 차이도 실패)
/// - 기능을 넣으면 그 상태의 캡처도 같이 넣는다 (골든 없는 기능 = 골든스탠다드 미달)

/// 회원가입 완료 + RX 등급 확정 상태의 로컬 프로필 (persona 디버그 데이터 재사용).
ProfileState rxProfile() {
  final p = ProfileState();
  final body = kPersonaBodyMap['persona-member-kim-doyun-2026']!;
  p.applyPersonaSnapshot(
    bodyWeightKg: body.bodyWeightKg,
    heightCm: body.heightCm,
    ageYears: body.ageYears,
    gender: body.gender,
    experienceYears: body.experienceYears,
    benchmarks: body.benchmarks,
    gradeResult: tierGrade('RX'),
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

  // ── 공통: 인트로 3p (v1.27 3기둥 — BOARD → EARN → TIER, HYPHEN 로고) ──
  testWidgets('common: intro 3p', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: AuthState(),
        profile: ProfileState(),
        home: const IntroScreen()));
    await capture(tester, 'common_02_intro_board');
    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(milliseconds: 300));
    await capture(tester, 'common_03_intro_earn');
    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(milliseconds: 300));
    await capture(tester, 'common_04_intro_tier');
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

  testWidgets('onboarding: benchmarks', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: ProfileState(),
        home: const OnboardingBenchmarksScreen()));
    await capture(tester, 'onb_02_benchmarks');
  });

  testWidgets('onboarding: grade (RX)', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const OnboardingGradeScreen()));
    await capture(tester, 'onb_03_grade_rx');
    // 진입 1.2s 후 achievements/check 지연 호출 — 타이머 flush.
    await tester.pump(const Duration(seconds: 2));
  });

  // ── 회원 셸 3탭 (v1.27 3기둥 — 기본 = WOD 보드) ──
  // 페이싱 계산기(빌더·프리셋·결과) 캡처는 v1.27 기능 숨김과 함께 제거 —
  // 재노출 시 git 히스토리의 calc_01~04 테스트 복원.
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
    await tapTab(tester, 'Home');
    await capture(tester, 'member_02_shell_home');
    await tapTab(tester, 'Profile');
    await capture(tester, 'member_03_shell_profile');
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
