import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/movements_repository.dart';
import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_basic.dart';
import 'features/onboarding/onboarding_benchmarks.dart';
import 'features/onboarding/onboarding_grade.dart';
import 'features/pacing_result/result_screen.dart';
import 'features/presets/presets_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/profile_state.dart';
import 'features/wod_builder/wod_builder_screen.dart';
import 'features/wod_builder/wod_draft_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final api = ApiClient.create();
  final profile = ProfileState();
  await profile.load();

  runApp(FacingApp(api: api, profile: profile));
}

class FacingApp extends StatelessWidget {
  final ApiClient api;
  final ProfileState profile;
  const FacingApp({super.key, required this.api, required this.profile});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        Provider<MovementsRepository>(create: (_) => MovementsRepository(api)),
        ChangeNotifierProvider<ProfileState>.value(value: profile),
        ChangeNotifierProvider<WodDraftState>(create: (_) => WodDraftState()),
      ],
      child: MaterialApp(
        title: 'facing',
        theme: FacingTheme.light,
        debugShowCheckedModeBanner: false,
        initialRoute: profile.hasGrade ? '/home' : '/onboarding/basic',
        routes: {
          '/onboarding/basic': (_) => const OnboardingBasicScreen(),
          '/onboarding/benchmarks': (_) => const OnboardingBenchmarksScreen(),
          '/onboarding/grade': (_) => const OnboardingGradeScreen(),
          '/home': (_) => const HomeScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/builder': (_) => const WodBuilderScreen(),
          '/presets': (_) => const PresetsScreen(),
          '/result': (_) => const ResultScreen(),
        },
      ),
    );
  }
}
