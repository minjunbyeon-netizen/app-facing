import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/appkit.gen.dart';
import '../../core/device_id.dart';
import '../../core/haptic.dart';
import '../../core/notification_service.dart';
import '../../core/quotes.dart';
import '../../core/theme.dart';
import '../../widgets/quote_card.dart';
import '../auth/auth_state.dart';
import '../boss/boss_auth_state.dart';
import '../profile/profile_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // 6 슬롯: 0=FACING / 1=tagline / 2=body / 3=caption / 4=quote / 5=loader
  late final List<Animation<double>> _opacities;
  // 슬라이드는 앞 5개만 (loader는 fade만)
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 각 슬롯 시작/끝 (fraction of 1500ms)
    const List<double> s = [0.00, 0.13, 0.25, 0.35, 0.50, 0.60];
    const List<double> e = [0.33, 0.40, 0.52, 0.62, 0.73, 0.80];

    _opacities = List.generate(
      6,
      (i) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(s[i], e[i], curve: Curves.easeOut),
      ),
    );

    _slides = List.generate(
      5,
      (i) => Tween<Offset>(
        begin: const Offset(0, -0.6),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(s[i], e[i], curve: Curves.easeOutCubic),
      )),
    );

    _ctrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// v1.16 Sprint 8 U1: 자동 진입 복원. 버튼 없이 backend health 준비 후 2.5s 뒤 자동 전환.
  Future<void> _bootstrap() async {
    final api = context.read<ApiClient>();

    try {
      await DeviceIdService.get();
    } catch (_) {}
    if (!mounted) return;

    // v1.17 로컬 푸시 — 알림 권한 요청 (Android 13+ 다이얼로그, 그 이하는 자동 grant).
    // 거부되어도 앱 동작은 그대로. 나중에 설정에서 켤 수 있음.
    try {
      final granted = await NotificationService.instance.isPermissionGranted();
      if (!granted) {
        await NotificationService.instance.requestPermission();
      }
    } catch (_) {}
    if (!mounted) return;

    try {
      await api.get('/health').timeout(const Duration(seconds: 2));
    } catch (_) {}
    if (!mounted) return;

    bool introSeen = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      introSeen = prefs.getBool('intro_seen') ?? false;
    } catch (_) {
      introSeen = true;
    }
    if (!mounted) return;

    await Future.delayed(AppKit.splashMin);
    if (!mounted) return;
    _onStart(introSeen: introSeen);
  }

  /// v1.16 + PHASE5: 로그인 상태 분기.
  /// boss 세션 살아있으면 → /boss/dashboard 직행.
  /// 아니면 기존 회원·코치 플로우.
  void _onStart({required bool introSeen}) {
    final profile  = context.read<ProfileState>();
    final auth     = context.read<AuthState>();
    final bossAuth = context.read<BossAuthState>();
    Haptic.medium();
    // PHASE5 §1.1: 사장 자동 로그인 우선
    if (bossAuth.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/boss/dashboard');
      return;
    }
    final String next;
    if (!introSeen) {
      // B-2 (2026-06-10): 첫 실행은 로그인 여부 무관 서비스 소개 먼저.
      // (기존엔 미로그인 → /signup 직행이라 신규 유저가 인트로를 영영 못 봄)
      next = '/intro';
    } else if (!auth.isSignedIn) {
      next = '/signup'; // 미로그인 → 소셜 로그인 화면
    } else if (profile.hasGrade) {
      // D26: 역할은 로그인 시 결정됨 — 수동 mode-select 폐기. shell 직행.
      next = '/shell';
    } else {
      next = '/onboarding/basic';
    }
    Navigator.of(context).pushReplacementNamed(next);
  }

  Widget _fadeSlide(int slot, Widget child) => SlideTransition(
        position: _slides[slot],
        child: FadeTransition(opacity: _opacities[slot], child: child),
      );

  Widget _fadeOnly(int slot, Widget child) =>
      FadeTransition(opacity: _opacities[slot], child: child);

  @override
  Widget build(BuildContext context) {
    final q = randomQuote();
    return Scaffold(
      backgroundColor: FacingTokens.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FacingTokens.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              _fadeSlide(
                0,
                Text(
                  'FACING',
                  style: FacingTokens.brandLogo,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: FacingTokens.sp5),
              const Spacer(),
              _fadeSlide(1, QuoteCard(quote: q, compact: true)),
              const SizedBox(height: FacingTokens.sp5),
              _fadeOnly(
                2,
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: FacingTokens.muted,
                  ),
                ),
              ),
              const SizedBox(height: FacingTokens.sp3),
            ],
          ),
        ),
      ),
    );
  }
}
