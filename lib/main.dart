import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/connectivity_state.dart';
import 'core/movements_repository.dart';
import 'core/sse_client.dart';
import 'core/theme.dart';
import 'core/goals_state.dart';
import 'core/shell_nav_bus.dart';
import 'core/ui_prefs_state.dart';
import 'core/unit_state.dart';
import 'core/wod_session_bus.dart';
import 'features/home/home_screen.dart';
import 'features/intro/intro_screen.dart';
import 'features/onboarding/create_gym_screen.dart';
import 'features/onboarding/mode_select_screen.dart';
import 'features/onboarding/onboarding_basic.dart';
import 'features/onboarding/onboarding_benchmarks.dart';
import 'features/onboarding/onboarding_grade.dart';
import 'features/pacing_result/result_screen.dart';
import 'features/presets/presets_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/profile_state.dart';
import 'features/splash/splash_screen.dart';
import 'features/history/history_detail_screen.dart';
import 'features/history/history_screen.dart';
import 'features/achievement/achievement_repository.dart';
import 'features/achievement/achievement_state.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/signup_screen.dart';
import 'features/gym/gym_repository.dart';
import 'features/gym/gym_search_screen.dart';
import 'features/gym/gym_state.dart';
import 'features/inbox/inbox_repository.dart';
import 'features/inbox/inbox_state.dart';
import 'features/mypage/mypage_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/wod_builder/wod_builder_screen.dart';
import 'features/wod_builder/wod_draft_state.dart';
import 'features/boss/boss_auth_state.dart';
import 'features/boss/boss_api_client.dart';
import 'features/boss/boss_login_screen.dart';
import 'features/boss/boss_dashboard_screen.dart';
import 'features/boss/role_entry_screen.dart';
import 'features/classes/classes_screen.dart';

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

  runApp(FacingApp(
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

class FacingApp extends StatelessWidget {
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
  const FacingApp({
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
        Provider<MovementsRepository>(create: (_) => MovementsRepository(api)),
        Provider<GymRepository>(create: (_) => GymRepository(api)),
        Provider<InboxRepository>(create: (_) => InboxRepository(api)),
        ChangeNotifierProvider<ProfileState>.value(value: profile),
        ChangeNotifierProvider<UnitState>.value(value: unit),
        ChangeNotifierProvider<ConnectivityState>.value(value: connectivity),
        ChangeNotifierProvider<WodDraftState>(create: (_) => WodDraftState()),
        ChangeNotifierProvider<GymState>(
          create: (ctx) => GymState(GymRepository(api), sse: sse)..loadMine(),
        ),
        ChangeNotifierProvider<InboxState>(
          create: (_) => InboxState(InboxRepository(api)),
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
        title: 'FACING',
        theme: FacingTheme.light,
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
          '/onboarding/benchmarks': (_) => const OnboardingBenchmarksScreen(),
          '/onboarding/grade': (_) => const OnboardingGradeScreen(),
          '/onboarding/mode': (_) => const ModeSelectScreen(),
          '/onboarding/create-gym': (_) => const CreateGymScreen(),
          '/onboarding/find-gym': (_) => const GymSearchScreen(),
          '/home': (_) => const HomeScreen(),
          '/shell': (_) => const MainShell(),
          '/profile': (_) => const ProfileScreen(),
          '/mypage': (_) => const MyPageScreen(),
          '/history': (_) => const HistoryScreen(),
          '/builder': (_) => const WodBuilderScreen(),
          '/presets': (_) => const PresetsScreen(),
          '/result': (_) => const ResultScreen(),
          // PHASE5 §1.1·§1.2: 사장 폰 로그인·대시보드
          '/role-entry': (_) => const RoleEntryScreen(),
          '/boss/login': (_) => const BossLoginScreen(),
          '/boss/dashboard': (_) => const BossDashboardScreen(),
          // PHASE4 §1.1: 회원 폰 클래스 일정·예약
          '/classes': (_) => const ClassesScreen(),
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
