import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/app_mode.dart';
import '../../core/device_id.dart';
import '../../core/haptic.dart';
import '../../core/quotes.dart';
import '../../core/theme.dart';
import '../../widgets/quote_card.dart';
import '../auth/auth_state.dart';
import '../profile/profile_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // 6글자(F-A-C-I-N-G) 각각 독립 애니메이션
  late final List<Animation<double>> _letterOpacity;
  late final List<Animation<Offset>> _letterSlide;
  late final List<Animation<Color?>> _letterColor;

  // 나머지 5요소: tagline / body / caption / quote / loader
  late final List<Animation<double>> _elOpacity;
  late final List<Animation<Offset>> _elSlide; // 앞 4개만 (loader 제외)

  // F(0), I(3) → fg→accent 컬러 전환. 나머지 → muted→fg.
  static const List<bool> _isAccent = [true, false, false, true, false, false];

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 글자 스태거: 80ms 간격, 각 350ms 애니메이션 (fraction of 2000ms)
    const double ls = 0.040; // 글자 간 스태거 (80ms)
    const double ld = 0.175; // 글자 1개 duration (350ms)

    _letterOpacity = List.generate(6, (i) => CurvedAnimation(
      parent: _ctrl,
      curve: Interval(i * ls, i * ls + ld, curve: Curves.easeOut),
    ));

    // easeOutBack = 살짝 바운스로 착지하는 효과
    _letterSlide = List.generate(6, (i) => Tween<Offset>(
      begin: const Offset(0, -1.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Interval(i * ls, i * ls + ld, curve: Curves.easeOutBack),
    )));

    // 컬러 전환: 글자가 착지한 직후 색 변경 (fade-in 55% 지점부터)
    _letterColor = List.generate(6, (i) {
      final cStart = (i * ls + ld * 0.55).clamp(0.0, 0.95);
      final cEnd = (cStart + 0.13).clamp(0.0, 1.0);
      return ColorTween(
        begin: _isAccent[i] ? FacingTokens.fg : FacingTokens.muted,
        end: _isAccent[i] ? FacingTokens.accent : FacingTokens.fg,
      ).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(cStart, cEnd, curve: Curves.easeIn),
      ));
    });

    // G가 완전히 착지(~0.40) 후 나머지 요소 등장
    const List<double> eS = [0.42, 0.52, 0.60, 0.70, 0.80];
    const List<double> eE = [0.58, 0.68, 0.76, 0.84, 0.92];

    _elOpacity = List.generate(5, (i) => CurvedAnimation(
      parent: _ctrl,
      curve: Interval(eS[i], eE[i], curve: Curves.easeOut),
    ));

    _elSlide = List.generate(4, (i) => Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Interval(eS[i], eE[i], curve: Curves.easeOutCubic),
    )));

    _ctrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 기존 bootstrap 로직 유지. 딜레이만 +25% (2500 → 3125ms).
  Future<void> _bootstrap() async {
    final api = context.read<ApiClient>();

    try {
      await DeviceIdService.get();
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

    AppMode? mode;
    try {
      mode = await AppModeStore.get();
    } catch (_) {
      mode = null;
    }
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 3125));
    if (!mounted) return;
    _onStart(introSeen: introSeen, mode: mode);
  }

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

  /// 글자 1개 위젯: 독립 슬라이드 + 페이드 + 컬러 전환.
  Widget _letterWidget(int i) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => FractionalTranslation(
        translation: _letterSlide[i].value,
        child: Opacity(
          opacity: _letterOpacity[i].value.clamp(0.0, 1.0),
          child: Text(
            'FACING'[i],
            style: FacingTokens.brandLogo.copyWith(color: _letterColor[i].value),
          ),
        ),
      ),
    );
  }

  /// 슬라이드 + 페이드 요소 (tagline/body/caption/quote).
  Widget _el(int i, Widget child) => SlideTransition(
        position: _elSlide[i],
        child: FadeTransition(opacity: _elOpacity[i], child: child),
      );

  /// 페이드만 (loader).
  Widget _elFade(Widget child) =>
      FadeTransition(opacity: _elOpacity[4], child: child);

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
              // FACING — 글자별 독립 애니메이션
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, _letterWidget),
              ),
              const SizedBox(height: FacingTokens.sp2),
              _el(0, const Text(
                'Engine · Split · Burst',
                style: FacingTokens.micro,
                textAlign: TextAlign.center,
              )),
              const SizedBox(height: FacingTokens.sp3),
              _el(1, const Text(
                'WOD Pacing Intelligence.',
                style: FacingTokens.body,
                textAlign: TextAlign.center,
              )),
              const SizedBox(height: FacingTokens.sp1),
              _el(2, const Text(
                'CrossFit Games-Player 전용.',
                style: FacingTokens.caption,
                textAlign: TextAlign.center,
              )),
              const Spacer(),
              _el(3, QuoteCard(quote: q, compact: true)),
              const SizedBox(height: FacingTokens.sp5),
              _elFade(const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: FacingTokens.muted,
                  ),
                ),
              )),
              const SizedBox(height: FacingTokens.sp3),
            ],
          ),
        ),
      ),
    );
  }
}
