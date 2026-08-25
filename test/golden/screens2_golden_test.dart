import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/core/quotes.dart';
import 'package:hyphen_app/features/achievement/achievements_screen.dart';
import 'package:hyphen_app/features/auth/auth_state.dart';
import 'package:hyphen_app/features/auth/login_screen.dart';
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
  // 결함 수정 4 (2026-08-20): 이 변형은 기존 기록(my_result) 있는 상태 —
  // 카드 배지 '기록 105kg×3' + 시트 프리필 + 덮어쓰기 안내를 한 캡처로.
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
    // HkBadge 는 라벨을 대문자로 렌더한다 (105kg → 105KG).
    await tester.tap(find.textContaining('기록 105KG×3').first);
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

  // ── 회원: 도전 카드 인증 시트 (홈 → 도전 [인증하기]) — P3 ──
  testWidgets('member: challenge log sheet', (tester) async {
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
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    // 도전 카드는 홈 리스트 하단 — 스크롤로 끌어올린 뒤 [인증하기].
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('인증하기'));
    await tester.pumpAndSettle();
    await capture(tester, 'member_21_challenge_log_sheet');
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

  // ── 회원: 전자계약 상세 (항목 이름 한글화 2026-08-25) ──
  testWidgets('member: contract detail', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      ...memberWorld(),
      '/api/v1/member/contracts/2': memberContractDetail,
    });
    await tester.pumpWidget(harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const ContractDetailScreen(contractId: 2)));
    await tester.pumpAndSettle();
    // raw 키('member name')가 아니라 서버 사전의 한글 이름이 떠야 한다.
    expect(find.text('회원 이름'), findsOneWidget);
    expect(find.text('결제 수단'), findsOneWidget);
    await capture(tester, 'member_22_contract_detail');
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
  // v3.19 (2026-08-25) 창구 통합 — 회원·코치가 같은 화면으로 들어온다.
  // 로고 없음 + 제목 '로그인' + 역할 선택 없음이 이 캡처의 요점.
  testWidgets('common: login', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
        api: api,
        auth: AuthState(),
        profile: ProfileState(),
        home: const LoginScreen()));
    await capture(tester, 'common_08_login');
  });

  // ── 코치 셸 3탭 (v3.4) — 예약 현황 · 수업 · 쪽지 ──
  testWidgets('coach: shell 3 tabs', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    // 코치 기기는 mine 이 role=owner 로 내려온다 (백엔드 is_staff_device 폴백)
    // — 쪽지 탭이 코치 시점(회원에게 발신)으로 찍히도록 역할만 덮는다.
    final api = FakeApi({
      ...memberWorld(),
      '/api/v1/gyms/mine': {...gymsMine, 'role': 'owner'},
    });
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
    await tapTab(tester, '쪽지');
    await capture(tester, 'coach_03_shell_messages');
  });

}
