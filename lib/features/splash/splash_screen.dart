import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/app_mode.dart';
import '../../core/device_id.dart';
import '../../core/haptic.dart';
import '../../core/quotes.dart';
import '../../core/theme.dart';
import '../../widgets/hero_background.dart';
import '../../widgets/quote_card.dart';
import '../auth/auth_state.dart';
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

  /// v1.16 Sprint 8 U1: 자동 진입 복원. 버튼 없이 backend health 준비 후 1.2s 뒤 자동 전환.
  Future<void> _bootstrap() async {
    final api = context.read<ApiClient>();

    try {
      await DeviceIdService.get();
    } catch (_) {
      // device_id 생성 실패해도 ApiClient 인터셉터가 재시도 가능. UI는 진행.
    }
    if (!mounted) return;

    try {
      await api.get('/health').timeout(const Duration(seconds: 2));
    } catch (_) {
      // health 실패해도 UI는 진행. 오프라인 배너가 알려줌.
    }
    if (!mounted) return;

    // /go Tier 3: intro_seen 사전 로드 (IntroScreen dead route 해소).
    bool introSeen = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      introSeen = prefs.getBool('intro_seen') ?? false;
    } catch (_) {
      // prefs 로드 실패 시 intro 스킵 (이전 동작 유지).
      introSeen = true;
    }
    if (!mounted) return;

    // app_mode 사전 로드 (Tier 부여 후 ModeSelect 분기용).
    AppMode? mode;
    try {
      mode = await AppModeStore.get();
    } catch (_) {
      mode = null;
    }
    if (!mounted) return;

    // 준비 후 1.2s 추가 대기하여 로고·카피 노출 보장 후 자동 전환.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    _onStart(introSeen: introSeen, mode: mode);
  }

  /// v1.16: 로그인 상태 분기. 비로그인 → /signup (데모 OAuth).
  /// 로그인 + grade 있음 + mode 있음 → /shell.
  /// 로그인 + grade 있음 + mode 없음 → /onboarding/mode (3 모드 선택).
  /// 로그인 + grade 없음 → /onboarding/basic. intro 미시청 시 /intro 우선.
  void _onStart({required bool introSeen, required AppMode? mode}) {
    final profile = context.read<ProfileState>();
    final auth = context.read<AuthState>();
    Haptic.medium();
    final String next;
    if (!auth.isSignedIn) {
      next = '/signup';
    } else if (profile.hasGrade) {
      next = mode == null ? '/onboarding/mode' : '/shell';
    } else if (!introSeen) {
      next = '/intro';
    } else {
      next = '/onboarding/basic';
    }
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
                Text('FACING', style: FacingTokens.brandLogo),
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
                // v1.16 Sprint 8 U1: 자동 진입. 로딩 spinner만 노출.
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: FacingTokens.muted,
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
