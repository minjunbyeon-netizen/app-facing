import 'package:flutter/material.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';

/// PHASE5 §1.1 — Splash 이후 진입 분기 화면.
/// "회원·코치" (device_hash 기존 플로우) vs "사장·매니저" (ID/PW 로그인).
/// 이미 boss 세션 있으면 이 화면 건너뜀 (SplashScreen 에서 분기).
class RoleEntryScreen extends StatelessWidget {
  const RoleEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacingTokens.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: FacingTokens.sp5, vertical: FacingTokens.sp6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text('FACING', style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp1),
              Text('Select.', style: FacingTokens.h1),
              const SizedBox(height: FacingTokens.sp2),
              Text(
                '박스 역할에 맞게 진입.',
                style: FacingTokens.caption,
              ),
              const SizedBox(height: FacingTokens.sp6),

              // ─── 회원·코치 카드 ──────────────────────────────────────
              _RoleCard(
                label: 'ATHLETE / COACH',
                title: 'Athlete & Coach.',
                lines: const [
                  '박스 가입 · Engine 측정 · WOD Pacing',
                  '코치 WOD 게시 · 인박스 · 달력',
                ],
                onTap: () {
                  Haptic.medium();
                  // 기존 signup/intro 플로우로 진입
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/signup', (_) => false);
                },
              ),
              const SizedBox(height: FacingTokens.sp4),

              // ─── 사장·매니저 카드 ─────────────────────────────────────
              _RoleCard(
                label: 'BOSS / MANAGER',
                title: 'Operate Box.',
                accent: true,
                lines: const [
                  '회원 관리 · 수업 운영 · 공지',
                  'PC 어드민과 동일 ID·PW',
                ],
                onTap: () {
                  Haptic.medium();
                  Navigator.of(context).pushNamed('/boss/login');
                },
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final String title;
  final List<String> lines;
  final bool accent;
  final VoidCallback onTap;
  const _RoleCard({
    required this.label,
    required this.title,
    required this.lines,
    this.accent = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(FacingTokens.sp4),
          decoration: BoxDecoration(
            color: FacingTokens.surface,
            border: Border.all(
              color: accent ? FacingTokens.primary : FacingTokens.border,
              width: accent ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: FacingTokens.sectionLabel.copyWith(
                color: accent ? FacingTokens.primary : FacingTokens.muted,
              )),
              const SizedBox(height: FacingTokens.sp1),
              Text(title, style: FacingTokens.h3),
              const SizedBox(height: FacingTokens.sp2),
              ...lines.map((l) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('· $l', style: FacingTokens.caption),
                  )),
            ],
          ),
        ),
      );
}
