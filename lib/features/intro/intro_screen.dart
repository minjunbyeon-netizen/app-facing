import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../widgets/hero_background.dart';
import '../auth/auth_state.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pc = PageController();
  int _page = 0;

  // B-3 (2026-06-10): v1.16.2 포지셔닝 동기화 — Primary value(수업·박스 운영) 2p
  // + 페이싱 엔진(+α 차별점) 1p. 카피 확정 (2026-06-10 사용자 승인 — CLAUDE.md 카피 템플릿 동기화됨).
  static const List<_IntroPage> _pages = [
    _IntroPage(
      stage: 'MANAGE',
      title: 'One app.\nEvery class.',
      body: '예약 · 출석 · 공지 · 전자계약.\n박스의 하루를 한 곳에 담는다.',
      heroAsset: 'assets/images/hero_intro_1.jpg',
      stickmanAsset: 'assets/icons/stickman_motivation.svg',
    ),
    _IntroPage(
      stage: 'TRAIN',
      title: 'Book. Train. Track.',
      body: '수업 예약부터 QR 출석까지.\n기록은 자동 저장.',
      heroAsset: 'assets/images/hero_intro_2.jpg',
      stickmanAsset: 'assets/icons/stickman_discipline.svg',
    ),
    _IntroPage(
      stage: 'EDGE',
      title: 'Pull your Split.',
      body: '논문 공식으로 Split과 Burst 자동 계산.\nFACING 만의 페이싱 엔진.',
      heroAsset: 'assets/images/hero_intro_3.jpg',
      stickmanAsset: 'assets/icons/stickman_obsession.svg',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);
    if (!mounted) return;
    // B-2: 첫 실행 인트로는 로그인 전에 노출됨 — 로그인 여부로 목적지 분기.
    final signedIn = context.read<AuthState>().isSignedIn;
    Navigator.of(context)
        .pushReplacementNamed(signedIn ? '/onboarding/basic' : '/signup');
  }

  void _next() {
    if (_page >= _pages.length - 1) {
      _finish();
      return;
    }
    _pc.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page >= _pages.length - 1;
    return PopScope(
      // v1.19 차수 5 (B-LW-10): 뒤로가기로 Splash 복귀 차단. Intro 종료는 Skip/Next.
      canPop: false,
      child: Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pc,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _IntroPageView(page: _pages[i]),
          ),
          // UI 오버레이 (Skip + dots + Next)
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FacingTokens.sp3,
                      vertical: FacingTokens.sp2,
                    ),
                    // v1.15 P1-15: Skip 48dp 터치 타겟 + P2-4 토큰 사용.
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(
                            FacingTokens.touchMin, FacingTokens.touchMin),
                        foregroundColor: FacingTokens.muted,
                      ),
                      onPressed: () {
                        Haptic.light();
                        _finish();
                      },
                      child: const Text('Skip'),
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(
                          horizontal: FacingTokens.sp1),
                      height: FacingTokens.sp2 - 2,
                      width:
                          active ? FacingTokens.sp5 - 2 : FacingTokens.sp2 - 2,
                      decoration: BoxDecoration(
                        color:
                            active ? FacingTokens.accent : FacingTokens.border,
                        borderRadius: BorderRadius.circular(FacingTokens.r1),
                      ),
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.all(FacingTokens.sp4),
                  child: ElevatedButton(
                    onPressed: () {
                      Haptic.light();
                      _next();
                    },
                    child: Text(isLast ? 'Start' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _IntroPage {
  /// v1.15 P2-5: 3단계 서사 라벨 (MOTIVATION / DISCIPLINE / OBSESSION).
  final String stage;
  final String title;
  final String body;
  final String heroAsset;
  final String stickmanAsset;
  const _IntroPage({
    required this.stage,
    required this.title,
    required this.body,
    required this.heroAsset,
    required this.stickmanAsset,
  });
}

class _IntroPageView extends StatelessWidget {
  final _IntroPage page;
  const _IntroPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return HeroBackground(
      imageAsset: page.heroAsset,
      strongGrain: true,
      darkenStrength: 0.55,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FacingTokens.sp5,
            vertical: FacingTokens.sp5,
          ),
          // v1.21: 베타 피드백 — 인트로 텍스트 중앙정렬.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: FacingTokens.sp7),
              // stickman (서사 시각화)
              SvgPicture.asset(
                page.stickmanAsset,
                width: 140,
                height: 140,
                colorFilter: const ColorFilter.mode(
                  FacingTokens.fg,
                  BlendMode.srcIn,
                ),
              ),
              const Spacer(),
              Text(page.stage,
                  style: FacingTokens.sectionLabel,
                  textAlign: TextAlign.center),
              const SizedBox(height: FacingTokens.sp2),
              Text(page.title,
                  style: FacingTokens.h1,
                  textAlign: TextAlign.center),
              const SizedBox(height: FacingTokens.sp4),
              Text(page.body,
                  style: FacingTokens.lead,
                  textAlign: TextAlign.center),
              const SizedBox(height: FacingTokens.sp8 + FacingTokens.sp7),
            ],
          ),
        ),
      ),
    );
  }
}
