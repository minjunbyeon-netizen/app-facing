import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../widgets/hero_background.dart';
import '../profile/profile_state.dart';
import 'auth_state.dart';

/// v1.16: 최초 진입 회원가입 화면.
/// 데모: Naver·Kakao 버튼 탭 시 AuthState.signIn만 기록하고 다음 단계로 이동.
/// 실제 OAuth는 Phase 2.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _busy = false;

  static const Color _naverGreen = Color(0xFF03C75A);
  static const Color _kakaoYellow = Color(0xFFFEE500);
  static const Color _kakaoBrown = Color(0xFF191600);

  Future<void> _signIn(String provider) async {
    if (_busy) return;
    setState(() => _busy = true);
    Haptic.medium();
    final auth = context.read<AuthState>();
    await auth.signIn(provider);
    if (!mounted) return;
    final profile = context.read<ProfileState>();
    final next = profile.hasGrade ? '/shell' : '/onboarding/basic';
    Navigator.of(context).pushReplacementNamed(next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacingTokens.bg,
      body: HeroBackground(
        imageAsset: 'assets/images/hero_splash.jpg',
        strongGrain: true,
        darkenStrength: 0.72,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(FacingTokens.sp5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Text('FACING', style: FacingTokens.brandSerif),
                const SizedBox(height: FacingTokens.sp2),
                const Text(
                  'Engine · Split · Burst',
                  style: FacingTokens.micro,
                ),
                const SizedBox(height: FacingTokens.sp3),
                const Text(
                  'CrossFit Games-Player 전용\nWOD Pacing Intelligence',
                  style: FacingTokens.caption,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),

                // Naver
                _SocialButton(
                  label: '네이버로 시작',
                  background: _naverGreen,
                  foreground: Colors.white,
                  markText: 'N',
                  onPressed: _busy ? null : () => _signIn('naver'),
                ),
                const SizedBox(height: FacingTokens.sp3),

                // Kakao
                _SocialButton(
                  label: '카카오로 시작',
                  background: _kakaoYellow,
                  foreground: _kakaoBrown,
                  markText: 'K',
                  onPressed: _busy ? null : () => _signIn('kakao'),
                ),

                const SizedBox(height: FacingTokens.sp4),
                const Text(
                  '(데모 — 버튼 탭 즉시 가입 처리)',
                  style: FacingTokens.caption,
                  textAlign: TextAlign.center,
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

class _SocialButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final String markText;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.markText,
    required this.onPressed,
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
            children: [
              SizedBox(
                width: 48,
                child: Center(
                  child: Text(
                    markText,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
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
