import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/device_id.dart';
import '../../core/haptic.dart';
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
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  /// v1.15.2: auto-advance 제거. backend health + device id 준비 후 '시작하기' 버튼 활성화.
  Future<void> _bootstrap() async {
    final api = context.read<ApiClient>();

    try {
      await DeviceIdService.get();
    } catch (_) {}

    try {
      await api.get('/health').timeout(const Duration(seconds: 2));
    } catch (_) {
      // health 실패해도 UI는 진행. 오프라인 배너가 알려줌.
    }

    if (!mounted) return;
    setState(() => _ready = true);
  }

  /// v1.15.2: '시작하기' 탭 → grade 있으면 홈, 없으면 바로 onboarding (intro 3장 bypass).
  void _onStart() {
    final profile = context.read<ProfileState>();
    Haptic.medium();
    final next = profile.hasGrade ? '/home' : '/onboarding/basic';
    Navigator.of(context).pushReplacementNamed(next);
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
                const SizedBox(height: FacingTokens.sp3),
                // v1.15.2: 앱 정체성 한 줄 (Games-Player 전용).
                const Text(
                  'CrossFit Games-Player 전용\nWOD Pacing Intelligence',
                  style: FacingTokens.caption,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                QuoteCard(quote: q, compact: true),
                const SizedBox(height: FacingTokens.sp5),
                // v1.15.2: auto-advance 제거. 준비 전엔 spinner, 준비되면 '시작하기' CTA.
                if (!_ready)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: FacingTokens.muted,
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onStart,
                      child: const Text('시작하기'),
                    ),
                  ),
                const SizedBox(height: FacingTokens.sp3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
