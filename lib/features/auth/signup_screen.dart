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

                // v1.16 Sprint 7a: 이메일 가입 placeholder (Phase 2).
                const SizedBox(height: FacingTokens.sp3),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('이메일 가입은 Phase 2에서 지원 예정.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                  child: const Text('이메일로 시작 (Coming soon)'),
                ),

                const SizedBox(height: FacingTokens.sp4),
                const Text(
                  'Beta Preview · 정식 출시 시 실제 OAuth 연결',
                  style: FacingTokens.caption,
                  textAlign: TextAlign.center,
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
                        body: '이용약관 본문은 정식 출시 시 업데이트됩니다.\n'
                            '현재 Beta Preview 단계 — 데이터는 로컬에만 저장됩니다.',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: FacingTokens.muted,
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('이용약관',
                          style: TextStyle(fontSize: 12)),
                    ),
                    const Text(' · ',
                        style: TextStyle(color: FacingTokens.muted)),
                    TextButton(
                      onPressed: () => _showLegalSheet(
                        context,
                        title: '개인정보처리방침',
                        body: '개인정보처리방침 본문은 정식 출시 시 업데이트됩니다.\n'
                            'Beta Preview: device_id·프로필은 로컬 저장. '
                            '서버 전송 데이터는 없습니다.',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: FacingTokens.muted,
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('개인정보처리방침',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: FacingTokens.sp2),
              ],
            ),
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
