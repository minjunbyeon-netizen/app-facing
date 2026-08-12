import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../core/app_mode.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/fkit.dart';
import '../mypage/privacy_screen.dart';
import '../mypage/terms_screen.dart';
import '../profile/profile_state.dart';
import 'auth_state.dart';
import 'social_auth_service.dart';

/// 최초 진입 로그인 화면 (D26 — 회원·코치·사장 전원 소셜 로그인 통일).
/// 현재는 [StubSocialAuthService] (가짜 버튼) — provider 탭 시 즉시 성공 흉내
/// 후 서버가 내려준 role 로 자동 분기. 실 OAuth 는 [RealSocialAuthService]
/// 1개 교체로 활성 (security.md OAuth 2.1 + PKCE).
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _busy = false;

  // v1.33 (2026-08-10 사용자 지시): 소셜 로그인·데모 계정을 진입점에서 내리고
  // **실제 회원가입(박스 가입 신청)** 을 주 동선으로 올린다. 실 OAuth 키가 없어
  // stub(가짜 로그인)만 도는 상태였고, 가입 신청은 백엔드까지 실제로 배선돼 있다.
  // 프로젝트 룰 "숨김 = 코드 보존" — 화면·라우트·서비스는 그대로 두고 이 상수만
  // false. 실 OAuth 키 확보 후 true 한 줄로 원복.
  static const bool _kShowSocialLogin = false;

  // D26: stub ↔ real 자동 선택 (USE_REAL_AUTH 플래그). 실 OAuth 는 ApiClient 의존
  // 이라 const 불가 — _signIn 에서 context 로 ApiClient 받아 resolve.
  static const Color _naverGreen = FacingTokens.naverGreen;
  static const Color _googleSurface = FacingTokens.googleSurface;
  static const Color _googleBlue = FacingTokens.googleBlue;

  /// D26: provider 탭 → SocialAuthService → 서버 role 로 자동 분기.
  /// (현재 stub: role=solo 반환. 실 OAuth 시 박스 연결로 boss/coach/member 결정.)
  Future<void> _signIn(SocialProvider provider) async {
    if (_busy) return;
    setState(() => _busy = true);
    Haptic.medium();
    final auth = context.read<AuthState>();
    final profile = context.read<ProfileState>();
    final social = resolveSocialAuthService(context.read<ApiClient>());
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final result = await social.signIn(provider);
      await auth.signIn(provider.wireName, displayName: result.displayName);
      if (!mounted) return;
      _routeByRole(navigator, result.role, profile);
    } on SocialAuthException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('로그인 실패. 다시 시도해 주세요.')),
      );
    }
  }

  /// 서버가 내려준 role 로 직접 분기 — 수동 mode_select·role_entry 화면 폐기 (D26).
  void _routeByRole(
    NavigatorState navigator,
    SocialRole role,
    ProfileState profile,
  ) {
    if (role == SocialRole.boss) {
      // 사장: 실 OAuth 시 서버 세션 수립 후 대시보드. stub 전환기엔 ID/PW fallback.
      navigator.pushNamed('/boss/login');
      return;
    }
    final mode = role.toAppMode();
    if (mode != null) AppModeStore.set(mode);
    // 프로필(등급) 없으면 온보딩, 있으면 바로 shell.
    final next = profile.hasGrade ? '/shell' : '/onboarding/basic';
    navigator.pushNamedAndRemoveUntil(next, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    // v1.29: 로그인 진행 중 = 전면 로딩 규격 (DESIGN-SSOT §6 — 스플래시와 동일 골격).
    if (_busy) {
      return const Scaffold(
        backgroundColor: FacingTokens.bg,
        body: SafeArea(child: FkLoadingScreen(caption: '로그인 중')),
      );
    }
    // v1.20: HeroBackground 제거 → Splash 와 동일한 단색 배경 (일관성).
    return Scaffold(
      backgroundColor: FacingTokens.bg,
      body: SafeArea(
        // 베타 피드백 (2026-06-11): 콘텐츠를 화면 상하좌우 정중앙에 배치.
        // 작은 화면에서는 minHeight 가 콘텐츠보다 작아져 기존 스크롤 동작 유지.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(FacingTokens.sp5),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - FacingTokens.sp5 * 2)
                  .clamp(0.0, double.infinity),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // v1.21: 베타 피드백 — 상단 브랜드/태그라인 블록 중앙정렬.
                // v1.29: 로고 폭 = BrandLogo 기본 220 (진입 화면 통일, DESIGN-SSOT §6).
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BrandLogo(),
                    SizedBox(height: FacingTokens.sp2),
                  ],
                ),
                const SizedBox(height: FacingTokens.sp5),

                // v1.33: 소셜 로그인 블록 — 실 OAuth 키 확보 전까지 숨김.
                if (_kShowSocialLogin) ...[
                  // 네이버 (실서비스 1순위 — 실 로그인 배선: RealSocialAuthService)
                  FkSocialButton(
                    label: '네이버 아이디로 로그인',
                    background: _naverGreen,
                    foreground: Colors.white,
                    markText: 'N',
                    onPressed:
                        _busy ? null : () => _signIn(SocialProvider.naver),
                  ),
                  const SizedBox(height: FacingTokens.sp3),

                  // 구글
                  FkSocialButton(
                    label: '구글로 시작',
                    background: _googleSurface,
                    foreground: Colors.black,
                    markText: 'G',
                    markColor: _googleBlue,
                    onPressed:
                        _busy ? null : () => _signIn(SocialProvider.google),
                  ),
                  const SizedBox(height: FacingTokens.sp5),
                ],

                // 2026-08-12 주 CTA — 이미 아이디를 받은 회원의 진입로.
                // 서버가 login_id ↔ device_id 를 이어 주므로 폰이 바뀌어도
                // 같은 회원 기록으로 들어온다 (backend api/member_auth.py).
                ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () {
                          Haptic.light();
                          Navigator.of(context).pushNamed('/login/member');
                        },
                  child: const Text('아이디로 로그인'),
                ),
                const SizedBox(height: FacingTokens.sp3),

                // v1.33 — 아직 아이디가 없는 신규 방문자. 박스 선택 → 실명·전화 →
                // 가입 신청(pending) → 사장 승인 → 회원 활성.
                // A-4 (2026-06-10): /signup/self 고아 라우트 해소 이력 유지.
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () {
                          Haptic.light();
                          Navigator.of(context).pushNamed('/signup/self');
                        },
                  child: const Text('가입 신청'),
                ),
                const SizedBox(height: FacingTokens.sp3),
                // 이음새 1 — PC 선등록 회원의 가입 코드 연결 진입점.
                // v1.33: 작은 텍스트 링크 → 보조 버튼으로 승격 (소셜 내린 자리).
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () {
                          Haptic.light();
                          Navigator.of(context).pushNamed('/signup/claim');
                        },
                  child: const Text('가입 코드로 연결'),
                ),

                const SizedBox(height: FacingTokens.sp3),
                // P0-1 (2026-06-10): placeholder 다이얼로그 → 본문 화면으로 교체.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const TermsScreen()),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: FacingTokens.fgSecondary,
                        minimumSize: const Size(0, FacingTokens.touchMin),
                      ),
                      child: Text('이용약관', style: FacingTokens.caption),
                    ),
                    const Text(' · ',
                        style: TextStyle(color: FacingTokens.muted)),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const PrivacyScreen()),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: FacingTokens.fgSecondary,
                        minimumSize: const Size(0, FacingTokens.touchMin),
                      ),
                      child: Text('개인정보처리방침', style: FacingTokens.caption),
                    ),
                  ],
                ),
                const SizedBox(height: FacingTokens.sp1),
                // D26 전환기: 사장 ID/PW 진입 (실 OAuth 활성 시 제거).
                // BossLoginScreen → BossAuthState.save() → main.dart listener 가
                // staffPush.start() 트리거 (가입 신청 SSE 알림 수신).
                // v2.2 (H9): 사장·코치가 들어오는 유일한 입구인데 화면 맨 아래
                // 흐린 회색 한 줄이라 약관 링크와 구분되지 않았다. 구분선으로
                // 약관 묶음과 떼고 본문색 + w600 으로 올린다. 내부 표기였던
                // '(전환기)' 는 사용자에게 뜻이 없어 뺀다 (3면 대전제 ①·③ —
                // 사장·코치는 PC 가 주지만 폰으로도 들어온다).
                const SizedBox(height: FacingTokens.sp2),
                const Divider(height: 1, color: FacingTokens.border),
                Center(
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).pushNamed('/boss/login'),
                    style: TextButton.styleFrom(
                      foregroundColor: FacingTokens.fg,
                      minimumSize: const Size(0, FacingTokens.touchMin),
                    ),
                    child: Text(
                      '코치·사장 로그인',
                      style: FacingTokens.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: FacingTokens.sp2),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

// v1.29: _SocialButton → FkSocialButton (FKit SSOT 이동, DESIGN-SSOT §5).
