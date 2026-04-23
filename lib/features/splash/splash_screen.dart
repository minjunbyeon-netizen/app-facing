import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/device_id.dart';
import '../../core/quotes.dart';
import '../../core/theme.dart';
import '../../widgets/hero_background.dart';
import '../../widgets/quote_card.dart';
import '../profile/profile_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final minShow = Future<void>.delayed(const Duration(milliseconds: 1200));
    final api = context.read<ApiClient>();
    final profile = context.read<ProfileState>();

    try {
      await DeviceIdService.get();
    } catch (_) {}

    try {
      await api.get('/health').timeout(const Duration(seconds: 2));
    } catch (_) {
      // health 실패해도 UI는 진행. 오프라인 배너가 알려줌.
    }

    final prefs = await SharedPreferences.getInstance();
    final introSeen = prefs.getBool('intro_seen') ?? false;

    await minShow;
    if (!mounted) return;

    final String nextRoute;
    if (profile.hasGrade) {
      nextRoute = '/home';
    } else if (!introSeen) {
      nextRoute = '/intro';
    } else {
      nextRoute = '/onboarding/basic';
    }
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final q = randomQuote();
    return Scaffold(
      backgroundColor: FacingTokens.bg,
      body: HeroBackground(
        imageAsset: 'assets/images/hero_splash.jpg',
        strongGrain: true,
        darkenStrength: 0.65,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(FacingTokens.sp5),
            child: Column(
              children: [
                const Spacer(),
                Text('FACING', style: FacingTokens.brandSerif),
                const SizedBox(height: FacingTokens.sp2),
                const Text('Engine · Split · Burst',
                    style: FacingTokens.micro),
                const SizedBox(height: FacingTokens.sp6),
                const SizedBox(
                  width: 22,
                  height: 22,
                  // v1.15 P2-4: 로딩=중립 → accent red 대신 muted (심리 부담 완화).
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: FacingTokens.muted,
                  ),
                ),
                const Spacer(),
                QuoteCard(quote: q, compact: true),
                const SizedBox(height: FacingTokens.sp3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
