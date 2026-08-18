import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/connectivity_state.dart';
import 'core/notification_service.dart';
import 'core/sse_client.dart';
import 'core/staff_push_service.dart';
import 'core/theme.dart';
import 'core/goals_state.dart';
import 'core/shell_nav_bus.dart';
import 'core/ui_prefs_state.dart';
import 'core/unit_state.dart';
import 'core/wod_session_bus.dart';
import 'features/home/home_screen.dart';
import 'features/intro/intro_screen.dart';
// 결정2 (2026-06-10): create-gym 비활성 — 라우트 주석과 함께 복구.
// import 'features/onboarding/create_gym_screen.dart';
import 'features/onboarding/onboarding_basic.dart';
import 'features/profile/profile_state.dart';
import 'features/splash/splash_screen.dart';
import 'features/history/history_detail_screen.dart';
import 'features/history/history_screen.dart';
import 'features/achievement/achievement_repository.dart';
import 'features/achievement/achievement_state.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/member_login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/staff_link_screen.dart';
import 'features/signup/self_signup_screen.dart';
import 'features/gym/gym_repository.dart';
import 'features/gym/gym_state.dart';
import 'features/announcements/announcements_state.dart';
import 'features/inbox/inbox_repository.dart';
import 'features/inbox/inbox_state.dart';
import 'features/mypage/mypage_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/boss/boss_auth_state.dart';
import 'features/boss/boss_api_client.dart';
import 'features/boss/boss_login_screen.dart';
import 'features/shell/coach_shell.dart';
import 'features/boss/settings_screen.dart';
import 'features/classes/classes_screen.dart';
import 'features/wod/wod_today_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final api = ApiClient.create();
  final sse = SseClient(api);
  final profile = ProfileState();
  final unit = UnitState();
  final connectivity = ConnectivityState();
  final auth = AuthState();
  final uiPrefs = UiPrefsState();
  final goals = GoalsState();
  // PHASE5 §1.1: 사장 폰 로그인 상태
  final bossAuth = BossAuthState();
  final bossApi = BossApiClient.create();
  await Future.wait([
    profile.load(),
    unit.load(),
    connectivity.init(),
    auth.load(),
    uiPrefs.load(),
    goals.load(),
    bossAuth.load(),
  ]);
  connectivity.bindRetryQueue(api);
  bossApi.bindAuth(bossAuth);

  // v1.17 로컬 푸시 — 알림 채널 초기화. 권한 요청은 첫 진입 화면에서 (사용자 동의 후).
  await NotificationService.instance.init();

  // (구 PHASE5 §6-3 FCM 토큰 register 는 2026-08-14 죽은 덩어리 정리로 삭제 —
  //  placeholder 토큰이라 실푸시 도달 0 (백엔드 G17 동시 제거). 알림 실채널은
  //  SSE + 로컬 알림(NotificationService) 하나다.)

  // v1.17 사장·코치 폰 SSE — 로그인 상태에 따라 자동 start/stop.
  final staffPush = StaffPushService();
  if (bossAuth.isLoggedIn) staffPush.start();
  bossAuth.addListener(() {
    if (bossAuth.isLoggedIn) {
      staffPush.start();
    } else {
      staffPush.stop();
    }
  });

  runApp(HyphenApp(
    api: api,
    sse: sse,
    profile: profile,
    unit: unit,
    connectivity: connectivity,
    auth: auth,
    uiPrefs: uiPrefs,
    goals: goals,
    bossAuth: bossAuth,
    bossApi: bossApi,
  ));
}

class HyphenApp extends StatelessWidget {
  final ApiClient api;
  final SseClient sse;
  final ProfileState profile;
  final UnitState unit;
  final ConnectivityState connectivity;
  final AuthState auth;
  final UiPrefsState uiPrefs;
  final GoalsState goals;
  final BossAuthState bossAuth;
  final BossApiClient bossApi;
  const HyphenApp({
    super.key,
    required this.api,
    required this.sse,
    required this.profile,
    required this.unit,
    required this.connectivity,
    required this.auth,
    required this.uiPrefs,
    required this.goals,
    required this.bossAuth,
    required this.bossApi,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        Provider<SseClient>.value(value: sse),
        Provider<GymRepository>(create: (_) => GymRepository(api)),
        Provider<InboxRepository>(create: (_) => InboxRepository(api)),
        ChangeNotifierProvider<ProfileState>.value(value: profile),
        ChangeNotifierProvider<UnitState>.value(value: unit),
        ChangeNotifierProvider<ConnectivityState>.value(value: connectivity),
        ChangeNotifierProvider<GymState>(
          create: (ctx) => GymState(GymRepository(api), sse: sse)..loadMine(),
        ),
        ChangeNotifierProvider<InboxState>(
          create: (_) => InboxState(InboxRepository(api)),
        ),
        ChangeNotifierProvider<AnnouncementsState>(
          create: (_) => AnnouncementsState(),
        ),
        Provider<AchievementRepository>(
          create: (_) => AchievementRepository(api),
        ),
        ChangeNotifierProvider<AchievementState>(
          // QA B-PF-4: AchievementRepository 단일 인스턴스 공유.
          create: (ctx) =>
              AchievementState(ctx.read<AchievementRepository>())..load(),
        ),
        ChangeNotifierProvider<AuthState>.value(value: auth),
        ChangeNotifierProvider<UiPrefsState>.value(value: uiPrefs),
        // PHASE5 §1.1: 사장 폰 로그인
        ChangeNotifierProvider<BossAuthState>.value(value: bossAuth),
        Provider<BossApiClient>.value(value: bossApi),
        ChangeNotifierProvider<WodSessionBus>(create: (_) => WodSessionBus()),
        ChangeNotifierProvider<ShellNavBus>(create: (_) => ShellNavBus()),
        ChangeNotifierProvider<GoalsState>.value(value: goals),
      ],
      child: Consumer<UiPrefsState>(
        builder: (ctx, ui, _) => MaterialApp(
        // v1.28 (2026-07-28): 리브랜딩 FACING → HYPHEN (로고·앱명 통일).
        title: 'HYPHEN',
        theme: HyphenTheme.light,
        debugShowCheckedModeBanner: false,
        // v1.16 Sprint 9a: 폰트 확대 옵션 (Masters 접근성).
        builder: (ctx2, child) => MediaQuery(
          data: MediaQuery.of(ctx2).copyWith(
            textScaler: TextScaler.linear(ui.textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/signup': (_) => const SignupScreen(),
          '/intro': (_) => const IntroScreen(),
          '/onboarding/basic': (_) => const OnboardingBasicScreen(),
          // 결정2 (2026-06-10 LAUNCH-CHECKLIST): create-gym 명시적 비활성.
          // 박스 개설은 웹 admin 경로로만 운영 (무분별 박스 생성 방지).
          // 재활성 시 이 라우트 + CreateGymScreen import 복구.
          // '/onboarding/create-gym': (_) => const CreateGymScreen(),
          // v2.6 (2026-08-13 사용자 지시): 1인 샵 전용이라 '박스 찾기'도 폐기.
          // 버튼은 이미 없앴지만 라우트가 살아 있으면 딥링크로 열린다.
          // 재활성 시 이 라우트 + GymSearchScreen import 복구
          // (화면 파일 features/gym/gym_search_screen.dart 는 보존 — "숨김 = 코드 보존").
          // '/onboarding/find-gym': (_) => const GymSearchScreen(),
          // PHASE5 Sprint1 F4 — 신규 회원 박스 선택 + 자동 가입 신청
          '/signup/self': (_) => const SelfSignupScreen(),
          // 회원 아이디·비밀번호 로그인 (backend api/member_auth.py)
          '/login/member': (_) => const MemberLoginScreen(),
          '/home': (_) => const HomeScreen(),
          '/shell': (_) => const MainShell(),
          '/mypage': (_) => const MyPageScreen(),
          '/history': (_) => const HistoryScreen(),
          // PHASE5 §1.1·§1.2: 사장 폰 로그인·대시보드
          '/boss/login': (_) => const BossLoginScreen(),
          '/auth/link-staff': (_) => const StaffLinkScreen(),
          // v3.3 (2026-08-18 사용자 지시) — 코치 앱 = 간단 2탭 셸
          // (예약 현황 · 수업). 대시보드는 예약 현황 탭으로 임베드.
          '/boss/dashboard': (_) => const CoachShell(),
          '/boss/settings': (_) => const BossSettingsScreen(),
          // PHASE4 §1.1: 회원 폰 클래스 일정·예약
          '/classes': (_) => const ClassesScreen(),
          '/wod/today': (_) => const WodTodayScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/history/detail') {
            final id = settings.arguments is int
                ? settings.arguments as int
                : 0;
            return MaterialPageRoute(
              builder: (_) => HistoryDetailScreen(recordId: id),
              settings: settings,
            );
          }
          return null;
        },
      ),
      ),
    );
  }
}
