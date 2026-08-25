import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/appkit.gen.dart';
import '../../core/device_id.dart';
import '../../core/haptic.dart';
import '../../core/notification_service.dart';
import '../../core/theme.dart';
import '../../widgets/hkit.dart';
import '../../widgets/hypee_intro.dart';
import '../auth/auth_state.dart';
import '../boss/boss_auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // v3.8 (2026-08-22): 로고가 연출 위젯(HypeeIntroDeck)으로 옮겨가면서 슬라이드
  // 등장이 필요한 요소가 사라졌다 — 남은 것은 하단 로더 페이드(_fadeOnly)뿐이다.
  // 6 슬롯 Interval 은 그대로 두되 실제로 쓰는 것은 슬롯 2 하나다.
  late final List<Animation<double>> _opacities;

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

    await Future.delayed(AppKit.splashMin);
    if (!mounted) return;
    _onStart();
  }

  /// v1.16 + PHASE5: 로그인 상태 분기.
  /// boss 세션 살아있으면 → /boss/dashboard 직행.
  /// 아니면 기존 회원·코치 플로우.
  /// v2.3 (2026-08-12 사용자 지시): 첫 실행 인트로 3장을 없앴다. 앱을 켜면
  /// 로그인 화면이 바로 뜬다. v3.3 (2026-08-21 사용자 지시): 남겨 뒀던
  /// 인트로 화면·라우트 코드도 삭제 (README §제거된 기능 대장).
  /// 등급(Tier) 유무로 온보딩에 붙잡아 두던 분기도 뺐다. 성별·경력은 가입
  /// 직후 한 번만 묻고, 이미 로그인한 사람은 언제나 홈으로 들어간다.
  void _onStart() {
    final auth = context.read<AuthState>();
    final bossAuth = context.read<BossAuthState>();
    Haptic.medium();
    // PHASE5 §1.1: 사장 자동 로그인 우선
    if (bossAuth.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/boss/dashboard');
      return;
    }
    Navigator.of(
      context,
    ).pushReplacementNamed(auth.isSignedIn ? '/shell' : '/signup');
  }

  Widget _fadeOnly(int slot, Widget child) =>
      FadeTransition(opacity: _opacities[slot], child: child);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HyphenTokens.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HyphenTokens.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // v3.8 (2026-08-22 대표 확정 — C안): 캐릭터가 나올 때는 캐릭터만
              // 보이고, 카드가 가운데로 빨려든 뒤 그 자리에서 로고가 떴다 사라진다.
              // 그래서 **로고 슬롯을 여기서 걷었다** — 로고는 연출 위젯 안에 있다.
              //   · 구 v3.7 은 로고가 위에 계속 떠 있었다(A안).
              //   · HkEntryLogoGap(로그인과 로고 자리 맞춤, v3.3)도 함께 뺐다.
              //     로고가 사라진 뒤 화면이 넘어가므로 자리를 맞출 대상이 없다.
              // 전체 2450ms < AppKit.splashMin 2500ms — 타이밍은 위젯 안에서만 조정.
              const Expanded(child: HypeeIntroDeck()),
              // v2.3 (2026-08-12 사용자 지시): 하단 명언 카드 삭제.
              // 로딩 화면에 뜻 모를 영문 문구가 붙어 있어 로고·로더만 남긴다.
              // QuoteCard 위젯 자체는 등급 결과·계산 로딩에서 계속 쓴다.
              _fadeOnly(2, const HkLoading()),
              const SizedBox(height: HyphenTokens.sp3),
            ],
          ),
        ),
      ),
    );
  }
}
