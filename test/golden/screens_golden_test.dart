import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/core/quotes.dart';
import 'package:hyphen_app/features/boss/boss_dashboard_screen.dart';
import 'package:hyphen_app/features/auth/auth_state.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/history/history_detail_screen.dart';
import 'package:hyphen_app/features/history/history_screen.dart';
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
  p.applyProfileSnapshot(
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
    await tester.pumpWidget(
      harness(
        api: api,
        auth: AuthState(),
        profile: ProfileState(),
        home: const SplashScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await capture(tester, 'common_01_splash'); // 애니메이션 완료(1.3s) 시점
    // splashMin(2.5s) 타이머 flush — 스텁 라우트로 자동 전환시켜 pending timer 제거.
    await tester.pump(const Duration(seconds: 4));
  });

  // v3.3 (2026-08-21 사용자 지시): 인트로 2p 골든(common_02·common_03) 삭제 —
  // 화면 코드째 제거 (README §제거된 기능 대장).

  // v3.31 (2026-08-27 사용자 지시): 진입 갈림길 골든(common_05_signup) 삭제 —
  // 화면 코드째 제거하고 로그인 화면 하나로 합쳤다 (README §제거된 기능 대장 31).

  // ── 공통: 가입 신청서 (v2.8 — 이름·생년월일·성별·연락처·경력·종목·부상) ──
  // 한 화면에 다 안 들어가 위·아래 두 장으로 나눠 찍는다.
  testWidgets('common: self signup', (tester) async {
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
    await capture(tester, 'common_06_self_signup');
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -420),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await capture(tester, 'common_07_self_signup_scrolled');
  });

  // ── 온보딩: 기본 정보 → Benchmarks → Tier 결과 ──
  testWidgets('onboarding: basic', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: ProfileState(),
        home: const OnboardingBasicScreen(),
      ),
    );
    await capture(tester, 'onb_01_basic');
  });

  // v2.6 (2026-08-13): Benchmarks·Tier 결과 화면은 진입점이 없어졌다
  // (프로필 수정에서 Benchmarks 카드 삭제 — D34 의 연장). 화면 코드는 살아
  // 있으나 회원이 도달할 수 없으므로 골든에서 뺀다. 진입점을 되살리면 이 두
  // 캡처도 같이 되살릴 것.

  // D85 (2026-08-29): 4탭 — 홈 · 수업 · 히스토리 · 내 정보.
  testWidgets('member: shell 4 tabs', (tester) async {
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
        home: const MainShell(),
      ),
    );
    await capture(tester, 'member_01_shell_wod');
    await tapTab(tester, '홈');
    await capture(tester, 'member_02_shell_home');
    // D85 — 히스토리 탭 (셸 상단바 하나 + 검색 칸 + 목록). 기본 world 는 기록 0건.
    await tapTab(tester, '히스토리');
    await tester.pumpAndSettle();
    await capture(tester, 'member_27_shell_history');
    await tapTab(tester, '내 정보');
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
    await tester.scrollUntilVisible(
      find.text('메뉴'),
      300,
      scrollable: profileScroll,
    );
    await tester.ensureVisible(find.text('메뉴'));
    await tester.pump(const Duration(milliseconds: 100));
    // D83 (2026-08-29): 메뉴는 항상 펼쳐져 있다 — 표 전체(체육관 정보 ~ 이용약관,
    // '알림 받기' 포함)가 이 한 장에 다 들어온다. 펼침 캡처(member_05)는 같은 그림이라
    // 삭제. v3.10 (2026-08-22) 의 설정 아코디언 캡처(member_04b) 삭제와 같은 이유.
    expect(find.text('알림 받기'), findsOneWidget);
    await capture(tester, 'member_04_profile_menu');
  });

  // ── 홈 공지 아코디언 (R7 · 2026-08-21 — 소스를 AnnouncementsState 로 교체) ──
  // 기본 world 는 공지 0건이라 아코디언이 아예 안 그려진다 (member_02 유지).
  // 공지 3건(핀 1)을 주입해 접힘·펼침 두 상태 캡처 — 리워드 통지가 아닌
  // 진짜 공지만 나오는지의 시각 게이트.
  testWidgets('member: home notice accordion', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final world = memberWorld();
    world['/api/v1/member/announcements'] = memberAnnouncements();
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
    await tapTab(tester, '홈');
    await capture(tester, 'member_02b_home_notice');
    await tester.tap(find.text('공지'));
    // ExpansionTile 펼침 애니메이션 — 프로필 메뉴와 같은 다중 pump.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await capture(tester, 'member_02c_home_notice_open');
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
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: const MainShell(),
      ),
    );
    // v3.37: 프로그램은 수업 탭 '프로그램' 칸에 있다 (기본 진입은 '수업 시간').
    await tester.pump(const Duration(milliseconds: 300));
    await tapProgramPane(tester);
    await tester.tap(find.text('완료 표시').first);
    await tester.pumpAndSettle();
    await capture(tester, 'member_06_result_sheet');
  });

  // ── 사장 대시보드 ──
  testWidgets('boss: dashboard', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    final api = FakeApi(memberWorld());
    final bossApi = FakeBossApi({
      '/api/v1/admin/gyms/1/dashboard': bossDashboard(),
      '/api/v1/admin/gyms/1/classes': memberClasses(),
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
    await capture(tester, 'boss_02_dashboard');
  });

  // ── 수업 예약자 명단 시트 (D29) ──
  testWidgets('boss: class roster sheet', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    final api = FakeApi(memberWorld());
    final bossApi = FakeBossApi({
      '/api/v1/admin/gyms/1/dashboard': bossDashboard(),
      '/api/v1/admin/gyms/1/classes': memberClasses(),
      '/api/v1/admin/classes/101/reservations': classRoster(),
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
    // 오늘 수업 첫 카드(class 101) 탭 → 명단 시트.
    await tester.tap(find.text('SWEAT').first);
    await tester.pumpAndSettle();
    await capture(tester, 'boss_03_class_roster');
  });

  // ── 이력 (빈 상태) ──
  testWidgets('history: empty', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const HistoryScreen(),
      ),
    );
    await capture(tester, 'hist_01_empty');
  });

  // ── 이력 목록 + 검색 (D84 · 2026-08-29 "검색이 되는 거고 연관도순으로") ──
  // hist_02 = 검색어 없음(최근순) · hist_03 = 'squat' 를 치면 Back Squat · Front Squat
  // 두 건만 남고 최근 것이 위. 순위 규칙 정본 = **서버** services/history_search.py (D95,
  // 검사 tests/test_e2e_sessions_flow_d89.py::test_13) — 가짜는 서버가 세워 준 결과를 돌려준다.
  // 골든은 검색 칸이 목록 위에 늘 서 있음을 찍는다.
  testWidgets('history: list and search', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final all = wodHistoryList();
    final api = FakeApi({
      // 검색 키가 목록 키보다 앞에 서야 한다 (startsWith).
      '/api/v1/history/wod?q=squat': [all[0], all[3]],
      ...memberWorld(),
      '/api/v1/history/wod': all,
    });
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const HistoryScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Back Squat'), findsOneWidget);
    await capture(tester, 'hist_02_list');
    await tester.enterText(find.byType(TextField), 'squat');
    await tester.pump(const Duration(milliseconds: 400)); // 300ms 디바운스
    await tester.pumpAndSettle();
    expect(find.textContaining('Squat'), findsNWidgets(2));
    expect(find.textContaining('Fran'), findsNothing);
    await capture(tester, 'hist_03_search');
  });

  // ── 이력 상세 (D91 · 2026-08-30) — 목록과 같은 줄을 펼친다: 점수 라벨·난도·메모·수업 내용 ──
  testWidgets('history: detail', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    // 상세 키를 먼저 넣는다 — FakeApi 는 startsWith 로 맞추므로 목록 키보다 앞에 서야 한다.
    final api = FakeApi({
      '/api/v1/history/wod/502': wodHistoryDetail(),
      ...memberWorld(),
    });
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const HistoryDetailScreen(recordId: 502),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('6:52'), findsOneWidget);
    expect(find.text('SCALED'), findsOneWidget);
    await capture(tester, 'hist_04_detail');
  });

  // ── 이력 상세 — 점수 없는 v3.45 기록 (2026-09-02 E2E 실검증 발견) ──
  // 완료 입력에서 점수·난도를 없애 label 이 빈 기록은 히어로 점수 줄을 숨긴다
  // (종전엔 '-' 를 64sp 로 그려 검은 막대처럼 보였다). 동작별 기록이 곧 기록.
  testWidgets('history: detail without score', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      '/api/v1/history/wod/502': wodHistoryDetailNoScore(),
      ...memberWorld(),
    });
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const HistoryDetailScreen(recordId: 502),
      ),
    );
    await tester.pumpAndSettle();
    // 점수 히어로도 난도 배지도 없다 — 동작별 기록만.
    expect(find.text('-'), findsNothing);
    expect(find.text('SCALED'), findsNothing);
    expect(find.text('동작별 기록'), findsOneWidget);
    await capture(tester, 'hist_06_detail_no_score');
  });

  // ── 동작 필터 (2026-09-02) — 상세 '동작별 기록 보기' 배지 탭 → 목록이 그 동작만.
  // 판정·필터는 서버 `?movement_id=` (program_lines.result_movement_ids 한 곳) —
  // 가짜는 서버가 거른 결과를 돌려주고, 폰은 받은 순서 그대로 그린다 (6-b).
  // 필터가 켜지면 검색 칸 자리에 같은 규격의 읽기 전용 칸이 서므로 목록 y 불변.
  testWidgets('history: movement filter', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final all = wodHistoryList();
    final api = FakeApi({
      '/api/v1/history/wod/502': wodHistoryDetail(),
      // 필터 키가 목록 키보다 앞에 서야 한다 (startsWith).
      '/api/v1/history/wod?movement_id=50': [all[1]],
      ...memberWorld(),
      '/api/v1/history/wod': all,
    });
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const HistoryScreen(),
        routes: {
          '/history/detail': (ctx) => HistoryDetailScreen(
            recordId: ModalRoute.of(ctx)!.settings.arguments as int,
          ),
        },
      ),
    );
    await tester.pumpAndSettle();
    // D109 — 제목이 'SWEAT' 인 행이 둘(502 · 505). 최근순이라 첫 행이 502(Fran).
    await tester.tap(find.text('SWEAT').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('THRUSTER')); // 배지 (HkBadge 는 대문자로 그린다)
    await tester.pumpAndSettle();
    // 목록으로 돌아와 Thruster 가 든 기록(502)만 — 필터 칸에 동작 이름이 서 있다.
    expect(find.text('동작: Thruster'), findsOneWidget);
    expect(find.text('6:52'), findsOneWidget);
    expect(find.textContaining('Back Squat'), findsNothing);
    await capture(tester, 'hist_05_movement_filter');
    await tester.tap(find.byTooltip('필터 해제'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Back Squat'), findsOneWidget);
  });

  // ── 사장 로그인 ──
  // v3.19 (2026-08-25): 'boss: login' 캡처 삭제 — 코치 전용 로그인 화면이
  // 없어졌다. 로그인은 common_08_login 한 장으로 통합 (README §제거된 기능 대장).
}
