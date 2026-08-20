import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/core/quotes.dart';
import 'package:hyphen_app/features/achievement/achievements_screen.dart';
import 'package:hyphen_app/features/auth/auth_state.dart';
import 'package:hyphen_app/features/auth/member_login_screen.dart';
import 'package:hyphen_app/features/boss/boss_dashboard_screen.dart';
import 'package:hyphen_app/features/classes/classes_screen.dart';
import 'package:hyphen_app/features/contracts/member_contracts_screen.dart';
import 'package:hyphen_app/features/goals/goals_screen.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/inbox/inbox_screen.dart';
import 'package:hyphen_app/features/mypage/edit_profile_screen.dart';
import 'package:hyphen_app/features/mypage/strength_board_screen.dart';
import 'package:hyphen_app/features/mypage/faq_screen.dart';
import 'package:hyphen_app/features/mypage/privacy_screen.dart';
import 'package:hyphen_app/features/mypage/terms_screen.dart';
import 'package:hyphen_app/features/profile/profile_state.dart';
import 'package:hyphen_app/features/shell/coach_shell.dart';
import 'package:hyphen_app/features/shell/main_shell.dart';

import 'fakes.dart';
import 'harness.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

/// 전 화면 골든 2부 — 2026-08-19 "선택 가능한 모든 화면" 확장 (사용자 지시).
/// 1부(screens_golden_test.dart)의 셸·진입 캡처에 이어, 셸에서 한 단계 더
/// 들어가는 화면(예약·상세·쪽지·업적 전체·프로필 수정·계약·목표·FAQ·약관)과
/// 코치 셸 2탭, 명단 시트 하단(수업 취소), 날짜 선택 다이얼로그를 덮는다.
/// 규칙은 1부와 동일 — 진입점이 있는 화면만, 실도달 경로 우선.

void main() {
  setUp(() {
    quoteRandom = Random(7);
  });

  // ── 회원: 수업 예약 화면 (내 정보 탭 '수업' 버튼 → /classes) ──
  testWidgets('member: classes reserve list', (tester) async {
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
        home: const ClassesScreen()));
    await capture(tester, 'member_07_classes');
  });

  // ── 회원: 예약 확정 상태 (예약됨 배지 + 취소 진입) ──
  testWidgets('member: classes reserved state', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      ...memberWorld(),
      '/api/v1/member/classes': memberClassesReserved(),
    });
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: const ClassesScreen()));
    await capture(tester, 'member_08_classes_reserved');
  });

  // ── 회원: 결과 시트 — Strength(무게 측정일) 분기 (v3.4) ──
  // 오늘 WOD 가 strength 면 시간·라운드 대신 최고 무게(kg)+reps 입력이 뜬다.
  // 1부 member_06 과 같은 실도달 경로 (수업 탭 → 완료 표시 탭).
  testWidgets('member: wod result sheet strength', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      ...memberWorld(),
      '/api/v1/gyms/1/wods': gymWodsStrengthToday(),
    });
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
    await capture(tester, 'member_06b_result_sheet_strength');
  });

  // ── 회원: 1RM 보드 (내 정보 → 메뉴 → 최고 기록) — Q3 v3.4 ──
  testWidgets('member: strength board', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      ...memberWorld(),
      '/api/v1/gyms/1/strength-board': strengthBoard(),
    });
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: const StrengthBoardScreen()));
    await tester.pumpAndSettle();
    await capture(tester, 'member_20_strength_board');
  });

  // ── 회원: 수업 상세 (수업 탭 오늘 행 '자세히' 배지 → WodDetailScreen) ──
  testWidgets('member: wod detail', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('자세히').first);
    await tester.tap(find.text('자세히').first);
    await tester.pump(const Duration(milliseconds: 400));
    await capture(tester, 'member_09_wod_detail');
  });

  // ── 회원: 코치에게 질문 시트 (수업 탭 오늘 행 '메시지' 배지) ──
  testWidgets('member: coach ask sheet', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('메시지').first);
    await tester.tap(find.text('메시지').first);
    await tester.pump(const Duration(milliseconds: 400));
    await capture(tester, 'member_10_coach_ask_sheet');
  });

  // ── 회원: 쪽지·공지 피드 (홈 '더 보기 →' / 수업 탭 종 → MessagingScreen) ──
  testWidgets('member: messaging feed', (tester) async {
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
        home: const MessagingScreen()));
    await capture(tester, 'member_11_messaging');
  });

  // ── 회원: 업적 전체 (홈 업적 카드 '전체 보기' → AchievementsScreen) ──
  testWidgets('member: achievements all', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const AchievementsScreen()));
    await capture(tester, 'member_12_achievements_all');
  });

  // ── 회원: 업적 상세 시트 (홈 탭 해금 카드 탭) ──
  testWidgets('member: achievement detail sheet', (tester) async {
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
    await tapTab(tester, '홈');
    final homeScroll = find.byType(Scrollable).first;
    // v3.2: fakes 카탈로그 실시드 교체 — 해금 1번 = WOD_10, 행 표기는
    // 한글 칭호 '첫 열 번' (AchievementCard.displayTitle).
    await tester.scrollUntilVisible(find.text('첫 열 번').first, 300,
        scrollable: homeScroll);
    await tester.ensureVisible(find.text('첫 열 번').first);
    await tester.tap(find.text('첫 열 번').first);
    await tester.pump(const Duration(milliseconds: 400));
    await capture(tester, 'member_13_achievement_detail');
  });

  // ── 회원: 프로필 수정 (내 정보 이름 줄 연필 아이콘) ──
  testWidgets('member: edit profile', (tester) async {
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
        home: const EditProfileScreen()));
    await capture(tester, 'member_14_edit_profile');
  });

  // ── 회원: 전자계약 목록 (내 정보 메뉴 '계약') ──
  testWidgets('member: contracts list', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      ...memberWorld(),
      '/api/v1/member/me/contracts': memberContracts,
    });
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const MemberContractsScreen()));
    await capture(tester, 'member_15_contracts');
  });

  // ── 회원: 목표 (내 정보 메뉴 '목표') ──
  testWidgets('member: goals', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const GoalsScreen()));
    await capture(tester, 'member_16_goals');
  });

  // ── 회원: FAQ (내 정보 메뉴 'FAQ') ──
  testWidgets('member: faq', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const FaqScreen()));
    await capture(tester, 'member_17_faq');
  });

  // ── 회원: 이용약관 (내 정보 메뉴) ──
  testWidgets('member: terms', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const TermsScreen()));
    await capture(tester, 'member_18_terms');
  });

  // ── 회원: 개인정보처리방침 (내 정보 메뉴) ──
  testWidgets('member: privacy', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const PrivacyScreen()));
    await capture(tester, 'member_19_privacy');
  });

  // ── 공통: 회원 아이디 로그인 (로그인 화면 '아이디로 로그인') ──
  testWidgets('common: member id login', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: AuthState(),
        profile: ProfileState(),
        home: const MemberLoginScreen()));
    await capture(tester, 'common_08_member_login');
  });

  // ── 코치 셸 2탭 (v3.3) — 예약 현황 · 수업 ──
  testWidgets('coach: shell 2 tabs', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
    final bossApi =
        FakeBossApi({'/api/v1/admin/gyms/1/dashboard': bossDashboard()});
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        bossAuth: FakeBossAuth(),
        bossApi: bossApi,
        home: const CoachShell()));
    await capture(tester, 'coach_01_shell_reservations');
    await tapTab(tester, '수업');
    await capture(tester, 'coach_02_shell_board');
  });

  // ── 코치: 명단 시트 하단 — 수업 취소 버튼 (G24, 폴드 아래) ──
  testWidgets('boss: roster sheet cancel button', (tester) async {
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
    await tester.tap(find.text('WOD Class').first);
    await tester.pumpAndSettle();
    final sheetScroll = find
        .descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(find.text('수업 취소'), 200,
        scrollable: sheetScroll);
    await tester.pump(const Duration(milliseconds: 200));
    await capture(tester, 'boss_05_roster_cancel');
  });

  // ── 코치: 수업 등록 — 날짜 선택 다이얼로그 ──
  testWidgets('boss: compose date picker', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    final api = FakeApi(memberWorld());
    final bossApi = FakeBossApi({
      '/api/v1/admin/gyms/1/dashboard': bossDashboard(),
      '/api/v1/admin/gyms/1/classes': const {'id': 999},
    });
    await tester.pumpWidget(harness(
        api: api,
        auth: AuthState(),
        profile: ProfileState(),
        bossAuth: FakeBossAuth(),
        bossApi: bossApi,
        home: const BossDashboardScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수업 등록'));
    await tester.pumpAndSettle();
    // kTestClock 고정(2026-08-12) — 시트 기본 날짜 라벨. 대시보드의 오늘
    // 날짜 텍스트와 겹치므로 바텀시트 내부로 한정해 잡는다.
    await tester.tap(find.descendant(
        of: find.byType(BottomSheet), matching: find.text('2026-08-12')));
    await tester.pumpAndSettle();
    await capture(tester, 'boss_06_compose_datepicker');
  });

  // ── 코치: 수업 수정 시트 — 명단 시트 '수업 수정' (G24 2차, 프리필 상태) ──
  testWidgets('boss: class edit sheet', (tester) async {
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
    await tester.tap(find.text('WOD Class').first);
    await tester.pumpAndSettle();
    final sheetScroll = find
        .descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        )
        .first;
    // 맨 아래 '수업 취소'까지 스크롤해야 그 위 '수업 수정'의 중심이 화면 안에
    // 들어온다 — '수업 수정' 기준 스크롤은 버튼이 하단에 걸쳐 탭이 안 닿았다.
    await tester.scrollUntilVisible(find.text('수업 취소'), 200,
        scrollable: sheetScroll);
    await tester.tap(find.text('수업 수정'));
    await tester.pumpAndSettle();
    // 수정 시트가 실제로 떴는지 — 프리필 값(트랙 RX)·저장 CTA 로 확인.
    expect(find.text('저장'), findsOneWidget);
    expect(find.text('변경 내용은 회원 화면에 바로 반영됩니다.'), findsOneWidget);
    await capture(tester, 'boss_07_class_edit');
  });
}
