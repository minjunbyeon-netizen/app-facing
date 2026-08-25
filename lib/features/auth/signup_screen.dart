import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/hkit.dart';
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
  // **실제 회원가입(회원 가입 신청)** 을 주 동선으로 올린다. 실 OAuth 키가 없어
  // stub(가짜 로그인)만 도는 상태였고, 가입 신청은 백엔드까지 실제로 배선돼 있다.
  // 프로젝트 룰 "숨김 = 코드 보존" — 화면·라우트·서비스는 그대로 두고 이 상수만
  // false. 실 OAuth 키 확보 후 true 한 줄로 원복.
  static const bool _kShowSocialLogin = false;

  // v3.19 (2026-08-25 사용자 지시): '코치 로그인' 별도 진입 삭제 (_kShowBossEntry 폐기).
  // 창구는 하나다 — 코치도 아래 '로그인' 으로 들어오고, 코치인지 회원인지는
  // 서버가 판정해 화면을 가른다 (backend api/auth_login.py).

  // D26: stub ↔ real 자동 선택 (USE_REAL_AUTH 플래그). 실 OAuth 는 ApiClient 의존
  // 이라 const 불가 — _signIn 에서 context 로 ApiClient 받아 resolve.
  static const Color _naverGreen = HyphenTokens.naverGreen;
  static const Color _googleSurface = HyphenTokens.googleSurface;
  static const Color _googleBlue = HyphenTokens.googleBlue;

  /// D26: provider 탭 → SocialAuthService → 서버 role 로 자동 분기.
  /// (현재 stub: role=solo 반환. 실 OAuth 시 박스 연결로 boss/coach/member 결정.)
  Future<void> _signIn(SocialProvider provider) async {
    if (_busy) return;
    setState(() => _busy = true);
    Haptic.medium();
    final auth = context.read<AuthState>();
    final profile = context.read<ProfileState>();
    final social = resolveSocialAuthService(context.read<ApiClient>());
    final messenger = HkSnack.of(context);
    final navigator = Navigator.of(context);
    try {
      final result = await social.signIn(provider);
      await auth.signIn(provider.wireName, displayName: result.displayName);
      if (!mounted) return;
      await _routeByRole(navigator, result.role, profile);
    } on SocialAuthException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.fail(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.fail('로그인 실패. 다시 시도해 주세요.');
    }
  }

  /// 서버가 내려준 role 로 직접 분기 — 수동 mode_select·role_entry 화면 폐기 (D26).
  Future<void> _routeByRole(
    NavigatorState navigator,
    SocialRole role,
    ProfileState profile,
  ) async {
    if (role == SocialRole.boss) {
      // 코치: 실 OAuth 시 서버 세션 수립 후 대시보드. stub 전환기엔 통합 ID/PW 창구로.
      navigator.pushNamed('/login');
      return;
    }
    // 온보딩 완료 판정 (2026-08-19 서버 영속화): 로컬 등급이 있으면 그대로
    // 통과(구 Tier 완주자 fast path), 없으면 서버 프로필로 판정한다 — 기기를
    // 바꿔도 이미 마친 사람(코치가 PC 에서 적어준 경우 포함)은 다시 안 묻는다.
    // 미가입(data:null → PROTOCOL 예외)·네트워크 실패는 종전 로컬 판정 유지.
    var done = profile.hasGrade;
    if (!done) {
      try {
        final data =
            await context.read<ApiClient>().get('/api/v1/member/me/profile');
        done = ProfileState.onboardingDoneFrom(data);
      } catch (_) {}
    }
    final next = done ? '/shell' : '/onboarding/basic';
    navigator.pushNamedAndRemoveUntil(next, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    // v1.29: 로그인 진행 중 = 전면 로딩 규격 (DESIGN-SSOT §6 — 스플래시와 동일 골격).
    if (_busy) {
      return const Scaffold(
        backgroundColor: HyphenTokens.bg,
        body: SafeArea(child: HkLoadingScreen(caption: '로그인 중')),
      );
    }
    // v1.20: HeroBackground 제거 → Splash 와 동일한 단색 배경 (일관성).
    return Scaffold(
      backgroundColor: HyphenTokens.bg,
      body: SafeArea(
        // 베타 피드백 (2026-06-11): 콘텐츠를 화면 상하좌우 정중앙에 배치.
        // 작은 화면에서는 minHeight 가 콘텐츠보다 작아져 기존 스크롤 동작 유지.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(HyphenTokens.sp5),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - HyphenTokens.sp5 * 2)
                  .clamp(0.0, double.infinity),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // v3.3 (2026-08-21 사용자 지시 "로고 위치 고정"): 블록째
                // 세로 중앙(콘텐츠 높이 따라 로고가 움직임) → 스플래시와 같은
                // 고정 오프셋 (HkEntryLogoGap, DESIGN-SSOT §6).
                // v1.29: 로고 폭 = BrandLogo 기본 220 (진입 화면 통일).
                const HkEntryLogoGap(),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BrandLogo(),
                    SizedBox(height: HyphenTokens.sp2),
                  ],
                ),
                const SizedBox(height: HyphenTokens.sp5),

                // v1.33: 소셜 로그인 블록 — 실 OAuth 키 확보 전까지 숨김.
                if (_kShowSocialLogin) ...[
                  // 네이버 (실서비스 1순위 — 실 로그인 배선: RealSocialAuthService)
                  HkSocialButton(
                    label: '네이버 아이디로 로그인',
                    background: _naverGreen,
                    foreground: Colors.white,
                    markText: 'N',
                    onPressed:
                        _busy ? null : () => _signIn(SocialProvider.naver),
                  ),
                  const SizedBox(height: HyphenTokens.sp3),

                  // 구글
                  HkSocialButton(
                    label: '구글로 시작',
                    background: _googleSurface,
                    foreground: Colors.black,
                    markText: 'G',
                    markColor: _googleBlue,
                    onPressed:
                        _busy ? null : () => _signIn(SocialProvider.google),
                  ),
                  const SizedBox(height: HyphenTokens.sp5),
                ],

                // 주 CTA — 아이디를 받은 사람 전원(회원·코치)의 단일 진입로.
                // v3.19: '아이디로 로그인' → '로그인'. 역할을 고르는 자리가
                // 없어졌으니 수식어도 뺀다 (backend api/auth_login.py).
                ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () {
                          Haptic.light();
                          Navigator.of(context).pushNamed('/login');
                        },
                  child: const Text('로그인'),
                ),
                const SizedBox(height: HyphenTokens.sp3),

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
                  // v2.3: 그냥 '가입 신청' 이면 무엇에 신청하는지가 없어 뜻이
                  // 통하지 않았다. 실제 동작(박스를 골라 등록을 신청)을 라벨에 넣는다.
                  child: const Text('회원 가입 신청'),
                ),
                // v2.7 (2026-08-13 사용자 지시) — '가입 코드 입력' 삭제.
                // 코드로 기기를 잇는 길과 신청서로 들어오는 길이 갈려 있어서,
                // 코드로 들어온 회원은 아이디·비밀번호를 만들 자리가 없었다.
                // 가입은 위 '회원 가입 신청' 하나로만 한다.

                const SizedBox(height: HyphenTokens.sp3),
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
                        foregroundColor: HyphenTokens.fgSecondary,
                        minimumSize: const Size(0, HyphenTokens.touchMin),
                      ),
                      child: Text('이용약관', style: HyphenTokens.caption),
                    ),
                    const Text(' · ',
                        style: TextStyle(color: HyphenTokens.muted)),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const PrivacyScreen()),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: HyphenTokens.fgSecondary,
                        minimumSize: const Size(0, HyphenTokens.touchMin),
                      ),
                      child: Text('개인정보처리방침', style: HyphenTokens.caption),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

// v1.29: _SocialButton → HkSocialButton (FKit SSOT 이동, DESIGN-SSOT §5).
