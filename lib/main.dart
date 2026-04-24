import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/connectivity_state.dart';
import 'core/movements_repository.dart';
import 'core/theme.dart';
import 'core/unit_state.dart';
import 'features/home/home_screen.dart';
import 'features/intro/intro_screen.dart';
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
import 'features/mypage/mypage_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/wod_builder/wod_builder_screen.dart';
import 'features/wod_builder/wod_draft_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final api = ApiClient.create();
  final profile = ProfileState();
  final unit = UnitState();
  final connectivity = ConnectivityState();
  await Future.wait([
    profile.load(),
    unit.load(),
    connectivity.init(),
  ]);
  connectivity.bindRetryQueue(api);

  runApp(FacingApp(
    api: api,
    profile: profile,
    unit: unit,
    connectivity: connectivity,
  ));
}

class FacingApp extends StatelessWidget {
  final ApiClient api;
  final ProfileState profile;
  final UnitState unit;
  final ConnectivityState connectivity;
  const FacingApp({
    super.key,
    required this.api,
    required this.profile,
    required this.unit,
    required this.connectivity,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        Provider<MovementsRepository>(create: (_) => MovementsRepository(api)),
        ChangeNotifierProvider<ProfileState>.value(value: profile),
        ChangeNotifierProvider<UnitState>.value(value: unit),
        ChangeNotifierProvider<ConnectivityState>.value(value: connectivity),
        ChangeNotifierProvider<WodDraftState>(create: (_) => WodDraftState()),
      ],
      child: MaterialApp(
        title: 'FACING',
        theme: FacingTheme.light,
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/intro': (_) => const IntroScreen(),
          '/onboarding/basic': (_) => const OnboardingBasicScreen(),
          '/onboarding/benchmarks': (_) => const OnboardingBenchmarksScreen(),
          '/onboarding/grade': (_) => const OnboardingGradeScreen(),
          '/home': (_) => const HomeScreen(),
          '/shell': (_) => const MainShell(),
          '/profile': (_) => const ProfileScreen(),
          '/mypage': (_) => const MyPageScreen(),
          '/history': (_) => const HistoryScreen(),
          '/builder': (_) => const WodBuilderScreen(),
          '/presets': (_) => const PresetsScreen(),
          '/result': (_) => const ResultScreen(),
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
    );
  }
}
