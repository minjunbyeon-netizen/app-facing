import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/device_id.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../core/app_mode.dart';
import '../gym/gym_state.dart';
import '../profile/profile_state.dart';
import 'auth_state.dart';
import 'demo_accounts.dart';
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
        const SnackBar(content: Text('Login failed. Retry.')),
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

  /// v1.16 Sprint 8 U1: 데모 계정 선택 → 프로필 프리로드 + grade 계산 + Shell 진입.
  Future<void> _useDemo(DemoAccount demo) async {
    if (_busy) return;
    setState(() => _busy = true);
    Haptic.heavy();
    // QA B-AS-1: await 전 context.read 일괄 캡처. mounted 체크 정확화.
    final auth = context.read<AuthState>();
    final profile = context.read<ProfileState>();
    final api = context.read<ApiClient>();
    GymState? gymState;
    try {
      gymState = context.read<GymState>();
    } catch (_) {}
    // v1.22 회의 데모: deviceIdSeed 있으면 device_id 강제 교체 → 백엔드 페르소나 자동 진입.
    if (demo.deviceIdSeed != null) {
      await DeviceIdService.overrideForDebug(demo.deviceIdSeed!);
    }
    // v1.16.2 — IdentityCard 3 줄 분리: name(personName) + gym·role(GymState) + location. nameLabel 통문자열 X.
    await auth.signIn('demo', displayName: demo.personName);
    if (!mounted) return;
    profile.setBasic(
      bodyWeightKg: demo.bodyWeightKg,
      heightCm: demo.heightCm.toDouble(),
      ageYears: demo.ageYears.toDouble(),
      gender: demo.gender,
      experienceYears: demo.experienceYears,
    );
    for (final entry in demo.benchmarks.entries) {
      profile.setBenchmark(entry.key, entry.value);
    }
    // Grade 계산 시도 (실패해도 Shell 진입).
    try {
      final result = await api
          .post('/api/v1/profile/grade', profile.toGradePayload())
          .timeout(const Duration(seconds: 5));
      profile.setGradeResult(result);
    } catch (_) {
      // 백엔드 미가동 시에도 onboarding으로 유도.
    }
    // v1.22 회의 데모: device_id 교체 후 박스 멤버십 hydrate.
    if (demo.deviceIdSeed != null && gymState != null) {
      try {
        await gymState.loadMine();
      } catch (_) {}
    }
    if (!mounted) return;
    // D26: 데모 계정은 role 을 이미 알고 있으므로 role-entry 없이 바로 분기.
    final mode = switch (demo.role) {
      'coach' => AppMode.coach,
      'solo' => AppMode.solo,
      _ => AppMode.member, // member · pending
    };
    await AppModeStore.set(mode);
    if (!mounted) return;
    final next = profile.hasGrade ? '/shell' : '/onboarding/basic';
    Navigator.of(context).pushNamedAndRemoveUntil(next, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    // v1.20: HeroBackground 제거 → Splash 와 동일한 단색 검정 배경 (일관성).
    return Scaffold(
      backgroundColor: FacingTokens.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FacingTokens.sp5),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: FacingTokens.sp5),
                // v1.21: 베타 피드백 — 상단 브랜드/태그라인 블록 중앙정렬.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('FACING',
                        style: FacingTokens.brandLogo,
                        textAlign: TextAlign.center),
                    const SizedBox(height: FacingTokens.sp2),
                  ],
                ),
                const SizedBox(height: FacingTokens.sp5),

                // Naver
                _SocialButton(
                  label: '네이버로 시작',
                  background: _naverGreen,
                  foreground: Colors.white,
                  markText: 'N',
                  onPressed:
                      _busy ? null : () => _signIn(SocialProvider.naver),
                ),
                const SizedBox(height: FacingTokens.sp3),

                // Google
                _SocialButton(
                  label: '구글로 시작',
                  background: _googleSurface,
                  foreground: Colors.black,
                  markText: 'G',
                  markColor: _googleBlue,
                  onPressed:
                      _busy ? null : () => _signIn(SocialProvider.google),
                ),

                const SizedBox(height: FacingTokens.sp5),
                // D26: 사장도 소셜 로그인으로 통일 — 별도 ID/PW 버튼 제거.
                // 실 OAuth 시 social → role=boss 응답이면 boss 세션 수립.
                // 사장 ID/PW 진입은 전환기 동안만 하단 작은 링크로 유지.
                // v1.16 Sprint 8 U1: 데모 계정 5개 빠른 진입.
                const Text('DEMO ACCOUNTS',
                    style: FacingTokens.sectionLabel),
                const SizedBox(height: FacingTokens.sp2),
                ...kDemoAccounts.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: FacingTokens.sp1),
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => _useDemo(d),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: FacingTokens.sp4,
                            vertical: FacingTokens.sp3,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(d.nameLabel,
                                      style: FacingTokens.body.copyWith(
                                        fontWeight: FontWeight.w700,
                                      )),
                                  const SizedBox(height: 2),
                                  Text(d.hintTier,
                                      style: FacingTokens.caption),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: FacingTokens.muted, size: 18),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: FacingTokens.sp3),
                // A-4 (2026-06-10): 신규 회원 박스 가입 신청 진입 — /signup/self
                // 고아 라우트 해소 (PHASE5 F4 화면이 어디서도 push 되지 않던 버그).
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () {
                          Haptic.light();
                          Navigator.of(context).pushNamed('/signup/self');
                        },
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(double.infinity, FacingTokens.buttonH),
                    side: const BorderSide(color: FacingTokens.primary),
                    foregroundColor: FacingTokens.primary,
                  ),
                  child: const Text('박스 가입 신청'),
                ),
                const SizedBox(height: FacingTokens.sp2),
                // v1.16 Sprint 7a: 약관·개인정보 placeholder 링크.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _showLegalSheet(
                        context,
                        title: '이용약관',
                        body: '이용약관 본문은 정식 출시 시 업데이트됩니다.',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: FacingTokens.muted,
                        minimumSize: const Size(0, 32),
                      ),
                      child: Text('이용약관', style: FacingTokens.caption),
                    ),
                    const Text(' · ',
                        style: TextStyle(color: FacingTokens.muted)),
                    TextButton(
                      onPressed: () => _showLegalSheet(
                        context,
                        title: '개인정보처리방침',
                        body: '개인정보처리방침 본문은 정식 출시 시 업데이트됩니다.\n'
                            'device_id·프로필은 로컬 저장. 서버 전송 데이터는 없습니다.',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: FacingTokens.muted,
                        minimumSize: const Size(0, 32),
                      ),
                      child: Text('개인정보처리방침', style: FacingTokens.caption),
                    ),
                  ],
                ),
                const SizedBox(height: FacingTokens.sp1),
                // D26 전환기: 사장 ID/PW 진입 (실 OAuth 활성 시 제거).
                // BossLoginScreen → BossAuthState.save() → main.dart listener 가
                // staffPush.start() 트리거 (가입 신청 SSE 알림 수신).
                Center(
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).pushNamed('/boss/login'),
                    style: TextButton.styleFrom(
                      foregroundColor: FacingTokens.muted,
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text('사장 로그인 (전환기)', style: FacingTokens.caption),
                  ),
                ),
                const SizedBox(height: FacingTokens.sp2),
              ],
            ),
          ),
        ),
    );
  }
}

void _showLegalSheet(
  BuildContext context, {
  required String title,
  required String body,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: FacingTokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(FacingTokens.r3)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(FacingTokens.sp5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: FacingTokens.h2),
            const SizedBox(height: FacingTokens.sp3),
            Text(body, style: FacingTokens.body),
            const SizedBox(height: FacingTokens.sp4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final String markText;
  final Color? markColor;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.markText,
    required this.onPressed,
    this.markColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: FacingTokens.buttonH,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(FacingTokens.r3),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(FacingTokens.r3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                markText,
                style: FacingTokens.h3.copyWith(
                  color: markColor ?? foreground,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: FacingTokens.body.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}
