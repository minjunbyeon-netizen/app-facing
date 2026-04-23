import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/device_id.dart';
import '../../core/theme.dart';
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
    return const Scaffold(
      backgroundColor: FacingTokens.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('facing',
                  style: TextStyle(
                    fontFamily: FacingTokens.fontFamily,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.0,
                    color: FacingTokens.fg,
                  )),
              SizedBox(height: FacingTokens.sp2),
              Text('WOD 페이싱 전략 계산기',
                  style: FacingTokens.caption),
              SizedBox(height: FacingTokens.sp6),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: FacingTokens.fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
