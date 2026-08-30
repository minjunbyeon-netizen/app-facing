import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/core/app_clock.dart';
import 'package:hyphen_app/features/classes/class_flows.dart';
import 'package:hyphen_app/core/notification_service.dart';
import 'package:hyphen_app/core/quotes.dart';
import 'package:hyphen_app/features/achievement/achievements_screen.dart';
import 'package:hyphen_app/features/announcements/announcements_state.dart';
import 'package:hyphen_app/features/auth/auth_state.dart';
import 'package:hyphen_app/features/auth/login_screen.dart';
import 'package:hyphen_app/features/boss/boss_dashboard_screen.dart';
import 'package:hyphen_app/features/gym/box_wod_screen.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/gym/wod_result_sheet.dart';
import 'package:hyphen_app/models/gym.dart';
import 'package:hyphen_app/features/history/history_screen.dart';
import 'package:hyphen_app/features/profile/profile_state.dart';
import 'package:hyphen_app/features/home/home_screen.dart';
import 'package:hyphen_app/features/inbox/inbox_screen.dart';
import 'package:hyphen_app/features/mypage/mypage_screen.dart';
import 'package:hyphen_app/features/shell/coach_shell.dart';
import 'package:hyphen_app/features/signup/self_signup_screen.dart';
import 'package:hyphen_app/features/shell/main_shell.dart';

import 'fakes.dart';
import 'harness.dart';
import 'login_states.dart';
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
    // v3.40 — 수업 탭 기본 진입이 '프로그램'. 취소 줄은 옆 칸에 있다.
    await tapSchedulePane(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('대기를 취소할까요?'), findsOneWidget);
    await capture(tester, 'state_08_waitlist_cancel_dialog');
  });

  // ── 늦은 취소 확인 — 시작 20분 전을 지난 예약 (2026-08-28 테스터 확정) ──
  // 막지 않는다. 대신 차감될 수 있다는 사실을 누르기 전에 한 줄로 알린다.
  // 안내가 없는 구간(20분 전까지)은 state_23 이 짝으로 찍는다 — 두 캡처를
  // 나란히 보면 안내 한 줄이 붙고 빠지는 차이만 남는다.
  testWidgets('state: late cancel dialog', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      // D96 — 안내 문구는 서버 판정 (미리보기 키는 취소 키보다 앞에).
      '/api/v1/member/reservations/56/cancel-preview': cancelPreviewLate(),
      ...memberWorld(),
      '/api/v1/member/classes': memberClassesLateCancel(),
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
    // v3.40 — 수업 탭 기본 진입이 '프로그램'. 취소 줄은 옆 칸에 있다.
    await tapSchedulePane(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('예약을 취소할까요?'), findsOneWidget);
    expect(find.textContaining('늦은 취소로 기록됩니다'), findsOneWidget);
    await capture(tester, 'state_22_late_cancel_dialog');
  });

  // ── 평상시 취소 확인 — 시작 20분 전까지 (안내 없음) ──
  // 늦은 취소(state_22)의 짝. 흔한 쪽이 캡처에 없으면 안내 자리가 평소에
  // 어떻게 보이는지를 아무도 못 본다.
  testWidgets('state: cancel dialog', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      '/api/v1/member/reservations/55/cancel-preview': cancelPreviewOnTime(),
      ...memberWorld(),
      '/api/v1/member/classes': memberClassesReserved(),
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
    // v3.40 — 수업 탭 기본 진입이 '프로그램'. 취소 줄은 옆 칸에 있다.
    await tapSchedulePane(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('예약을 취소할까요?'), findsOneWidget);
    expect(find.textContaining('늦은 취소'), findsNothing);
    await capture(tester, 'state_23_cancel_dialog');
  });

  // ── 늦은 취소 성사 순간 — 서버 토스트 (D100 · 2026-08-30) ──
  // state_22 의 다이얼로그에서 '취소' 를 눌러 끝까지 간다. 문장(달·몇 회째)은 DELETE
  // 응답 `notice.toast` 그대로 — 앱이 세지 않는다. 폭죽 없음, 우는 캐릭터.
  // DELETE 키는 미리보기 키 뒤·목록 키 앞 (FakeApi 는 startsWith 로 앞에서부터 맞춘다).
  testWidgets('state: late cancel done', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      '/api/v1/member/reservations/56/cancel-preview': cancelPreviewLate(),
      '/api/v1/member/reservations/56': cancelLateResult(),
      ...memberWorld(),
      '/api/v1/member/classes': memberClassesLateCancel(),
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
    await tapSchedulePane(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('예약을 취소할까요?'), findsOneWidget);
    // 다이얼로그의 '취소'(확정) — 목록의 '취소' 버튼보다 트리 뒤에 있다.
    await tester.tap(find.text('취소').last);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.textContaining('레이트 캔슬입니다'), findsOneWidget);
    expect(find.text('이 내용은 코치에게 전송됩니다.'), findsOneWidget);
    await capture(tester, 'state_30_late_cancel_done');
    // 스낵바가 스스로 걷힐 때까지 — pending timer 없이 끝낸다.
    await tester.pump(const Duration(seconds: 6));
  });

  _achievementsLoadingGolden();
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

  // ── 로그인 상태 4종 (v3.33 · 2026-08-27 고정 레이아웃) ──────────────────
  // 절차 정본 = login_states.dart — 같은 절차를 layout_stability_test.dart 가
  // y 좌표로도 잰다. 이 넉 장은 "상태가 달라도 안 밀린다" 의 픽셀 증거다.
  testWidgets('state: login remembered id', (tester) async {
    phone(tester);
    await loginRemembered(tester);
    expect(find.text('아이디 기억하기 (30일)'), findsOneWidget);
    await capture(tester, 'state_09_login_remembered');
  });

  // ── 로그인 실패 — 예약된 안내 슬롯에 서버 문구가 들어온다 ──
  testWidgets('state: login failed', (tester) async {
    phone(tester);
    await loginFailed(tester);
    expect(find.text('아이디 또는 비밀번호가 올바르지 않습니다.'), findsOneWidget);
    await capture(tester, 'state_17_login_error');
  });

  // ── 빈 칸 제출 — 두 입력칸 검증 에러가 **예약된 줄** 안에서만 뜬다 ──
  testWidgets('state: login validation errors', (tester) async {
    phone(tester);
    await loginValidationErrors(tester);
    expect(find.text('아이디를 입력해 주세요.'), findsOneWidget);
    expect(find.text('비밀번호를 입력해 주세요.'), findsOneWidget);
    await capture(tester, 'state_18_login_validation');
  });

  // ── 쪽지함 '코치' 칸 — 사람이 쓴 대화만 (D72 · 자동 통보는 '활동' 칸) ──
  // 기본 memberWorld 의 쪽지함은 비어 있어(member_11) 마케팅 캡처로는 빈 화면이라
  // 꽉 찬 실물을 별도 상태로 고정한다. 공지 슬롯도 함께 채운다.
  testWidgets('state: inbox threads filled', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      ...memberWorld(),
      '/api/v1/gym/1/threads': {'items': memberThreads()},
      '/api/v1/member/announcements': memberAnnouncements(),
    });
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: const MessagingScreen(),
      ),
    );
    // 공지 슬롯은 홈 화면이 채우는 상태라 여기서 직접 불러온다 (홈과 같은 소스).
    await Provider.of<AnnouncementsState>(
      tester.element(find.byType(MessagingScreen)),
      listen: false,
    ).refresh(GymRepository(api));
    await tester.pumpAndSettle();
    expect(find.text('김코치'), findsOneWidget);
    expect(find.text('휴관 안내'), findsOneWidget);
    // 자동 통보는 이 칸에 없다 — 있으면 D72 이전으로 되돌아간 것이다.
    expect(find.textContaining('HYPHEN 알림'), findsNothing);
    await capture(tester, 'state_20_inbox_threads');
  });

  // ── 쪽지함 '활동' 칸 — 자동 통보만 시간순 (D72 · 2026-08-29) ──
  testWidgets('state: inbox activity pane', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      ...memberWorld(),
      '/api/v1/gym/1/threads': {'items': memberThreads()},
      '/api/v1/gym/1/activity': {'items': memberActivity(), 'unread': 2},
      '/api/v1/member/announcements': memberAnnouncements(),
    });
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: const MessagingScreen(),
      ),
    );
    await Provider.of<AnnouncementsState>(
      tester.element(find.byType(MessagingScreen)),
      listen: false,
    ).refresh(GymRepository(api));
    await tester.pumpAndSettle();
    await tester.tap(find.text(MessagingFeed.paneActivity));
    await tester.pumpAndSettle();
    expect(find.text('예약 확정'), findsOneWidget);
    expect(find.text('업적 달성'), findsOneWidget);
    // 코치 대화는 이 칸에 없다.
    expect(find.text('김코치'), findsNothing);
    await capture(tester, 'state_26_inbox_activity');
  });

  // ── 로딩 중 — 버튼을 치우지 않고 그 자리에서 스피너만 돈다 ──
  testWidgets('state: login busy', (tester) async {
    phone(tester);
    await loginBusy(tester);
    await capture(tester, 'state_19_login_busy');
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
    await tapSchedulePane(tester);
    await tester.pumpAndSettle();
    expect(find.text('회원권 필요'), findsWidgets);
    await capture(tester, 'state_11_class_membership_required');
  });

  // ── 예약 오픈 전 — '예약' 을 누르면 캐릭터 스낵바 '예약 가능한 시간이 아니에요'
  //    (D58 전날 11시 오픈 · D82 2026-08-29 버튼은 살려 두고 누르면 안내) ──
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
    await tapSchedulePane(tester);
    await tester.pumpAndSettle();
    // 모레 날짜 행을 펼친다 — 요일 헤더 텍스트는 날짜에 따라 달라 AWAKE 수업이 든 날을 찾는다.
    final dayAfter = appClock.now().add(const Duration(days: 2));
    await tester.tap(find.text('${dayAfter.day}').first);
    await tester.pumpAndSettle();
    // D82 — 배지는 '예약' 그대로(잠그지 않는다). 누르면 서버를 두드리지 않고
    // 담담한 캐릭터 스낵바. 문구 정본 = class_flows.dart kBookingNotOpenSnack.
    expect(find.text('오픈 전'), findsNothing);
    final tomorrow = appClock.now().add(const Duration(days: 1));
    await tester.tap(find.text('예약'.toUpperCase()).last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(
        '$kBookingNotOpenSnack\n${tomorrow.month}/${tomorrow.day} 11:00 부터',
      ),
      findsOneWidget,
    );
    await capture(tester, 'state_15_class_booking_not_open');
  });

  // ── 예약 성사 순간 — 세 줄 토스트 + 화면 중앙 폭죽 (D86 · 2026-08-29) ──
  // POST 응답 키를 **먼저** 넣는다 — FakeApi 는 startsWith 로 앞에서부터 맞추므로
  // '/api/v1/member/classes' 목록 키가 먼저 오면 POST 가 목록을 받아 깨진다.
  // 폭죽은 고정 시드라 350ms 시점 프레임이 늘 같다.
  testWidgets('state: reservation done', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      // 끝 슬래시 — 목록 GET('…/classes?from=')은 안 맞고, 어느 수업 id 의 POST 든 맞는다.
      '/api/v1/member/classes/': const {
        'status': 'confirmed',
        'reservation_id': 9001,
      },
      ...memberWorld(),
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
    await tapSchedulePane(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('예약'.toUpperCase()).first);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text(kReservedTitle), findsOneWidget);
    await capture(tester, 'state_27_reservation_done');
    // 폭죽 오버레이가 스스로 걷힐 때까지 — pending timer 없이 끝낸다.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 5));
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

  // ── 코치 세션 만료 → 로그인 화면 자동 이동 (D59 · 2026-08-26) ──
  // 예약 현황 탭이 401 UNAUTHORIZED 를 받으면 에러 상태에 갇히지 않고
  // 진입 화면 위 로그인 화면으로 넘어가며 사유 한 줄을 띄운다.
  testWidgets('state: coach session expired', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi({
      ...memberWorld(),
      '/api/v1/gyms/mine': {...gymsMine, 'role': 'owner'},
      '/api/v1/gyms/1/members': gymMembersList(),
    });
    final bossAuth = FakeBossAuth();
    final bossApi = FakeBossApi(
      {'/api/v1/admin/gyms/1/classes': memberClasses()},
      unauthorizedPaths: {'/api/v1/admin/gyms/1/dashboard'},
    )..bindAuth(bossAuth);
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        bossAuth: bossAuth,
        bossApi: bossApi,
        routes: {'/login': (_) => const LoginScreen()},
        home: const CoachShell(),
      ),
    );
    await tester.pumpAndSettle();
    expect(bossAuth.isLoggedIn, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(LoginScreen.noticeSessionExpired), findsOneWidget);
    await capture(tester, 'state_16_coach_session_expired');
  });

  // ── '알림 받기' 한 줄 (2026-08-28 사용자 확정 — 켜거나 끄거나 하나) ──
  //
  // 두 캡처가 짝이다. 켜짐이 흔한 쪽이고, 차단됨은 폰 설정에서 막아 둔 사람이
  // 보는 화면이다 — 스위치만 켜져 '받는 중' 처럼 보이면 화면이 거짓말을 하므로
  // 그 상태가 눈에 보이는지를 픽셀로 고정한다. 행 높이는 두 상태가 같다
  // (좌표 검사 = stability_mypage_test.dart).
  Future<void> notificationsGolden(
    WidgetTester tester, {
    required bool granted,
    required String name,
  }) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    NotificationService.instance.debugUseSink(
      FakeNotificationSink(granted: granted),
    );
    addTearDown(NotificationService.instance.debugReset);
    await NotificationService.instance.setEnabled(true);
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
    await tester.pumpAndSettle();
    await tapTab(tester, '내 정보');
    // 알림 줄은 화면 아래쪽이라 그대로는 프레임 밖이다 — 끝까지 올린다.
    final scroll = find
        .descendant(
          of: find.byType(MyPageScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(find.text('알림 받기'), 300, scrollable: scroll);
    await tester.ensureVisible(find.text('알림 받기'));
    await tester.pumpAndSettle();
    await capture(tester, name);
  }

  testWidgets('state: notifications on', (tester) async {
    await notificationsGolden(
      tester,
      granted: true,
      name: 'state_24_notifications_on',
    );
    expect(find.text('쪽지 · 수업 시작 1시간 전 알림을 받습니다.'), findsOneWidget);
  });

  testWidgets('state: notifications blocked by phone settings', (tester) async {
    await notificationsGolden(
      tester,
      granted: false,
      name: 'state_25_notifications_blocked',
    );
    expect(find.text('폰 설정에서 알림이 차단되어 있습니다.'), findsOneWidget);
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

void _achievementsLoadingGolden() {
  // ── 업적 목록 로딩 — 스켈레톤 (v3.35 E 안: 요약·3칸·분류 라벨·행 자리 예약) ──
  testWidgets('state: achievements loading skeleton', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld(), hangPaths: {'/api/v1/achievements'});
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        home: const AchievementsScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await capture(tester, 'state_21_achievements_loading');
  });

  // ── 완료 시트 — 동작별 기록 (D94 · 2026-08-30 "다 하고 1"): 한 횟수·무게 kg 칸이
  //    코치가 정한 값(21-15-9 · 42.5kg)으로 미리 채워져 있다. 요약·판정은 서버. ──
  testWidgets('state: result sheet movement values', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    // 구조화 동작(Thruster 42.5kg · Pull-up)이 든 글 = 31 (Fran).
    final post = GymWodPost.fromJson(
      gymWods().firstWhere((p) => p['id'] == 31),
    );
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: Scaffold(
          body: SingleChildScrollView(child: WodResultSheet(wod: post)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('동작별 기록'), findsOneWidget);
    expect(find.text('42.5'), findsOneWidget);
    await capture(tester, 'state_28_result_sheet_movements');
  });

  // ── 완료 시트 — 저장 중 (2026-08-30 사용자 "수업을 저장중이에요 로딩바"): '저장' 을
  //    누르면 버튼은 자리 그대로 busy, 아래에 굵은 제목 + 가로 로딩바 토스트. 서버 응답을
  //    붙들어(hang) 그 순간을 찍는다. 밀림 검사 = stability_result_sheet_test.dart. ──
  testWidgets('state: result sheet saving', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(
      memberWorld(),
      hangPaths: {'/api/v1/gyms/1/wods/31/results'},
    );
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    final post = GymWodPost.fromJson(
      gymWods().firstWhere((p) => p['id'] == 31),
    );
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: Scaffold(
          body: SingleChildScrollView(child: WodResultSheet(wod: post)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 시트가 화면보다 길다 — 버튼을 보이게 내린 뒤 누른다 (안 보이는 곳은 탭이 안 닿는다).
    await tester.ensureVisible(find.byKey(kWodSaveButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(kWodSaveButton));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(kWodSavingTitle), findsOneWidget);
    await capture(tester, 'state_29_result_sheet_saving');
  });

}
