import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../widgets/hero_background.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pc = PageController();
  int _page = 0;

  // v1.15: 각 페이지에 hero 이미지 + stickman SVG (Motivation → Discipline → Obsession)
  static const List<_IntroPage> _pages = [
    _IntroPage(
      title: 'Split defines rank.',
      body: '첫 1분 all-out은 마지막 5분을 부순다.\n'
          '논문 공식으로 Split과 Burst 시점을 계산한다.',
      heroAsset: 'assets/images/hero_intro_1.jpg',
      stickmanAsset: 'assets/icons/stickman_motivation.svg',
    ),
    _IntroPage(
      title: '6 metrics.\nMeasure Engine.',
      body: 'Body · Power · Olympic · Gymnastics · Cardio · Metcon\n'
          '아는 것만 입력. 빈 칸은 자동 추론.',
      heroAsset: 'assets/images/hero_intro_2.jpg',
      stickmanAsset: 'assets/icons/stickman_discipline.svg',
    ),
    _IntroPage(
      title: 'Start.',
      body: 'Profile은 언제든 수정 가능.\n'
          'WOD 붙이면 즉시 전략 출력.',
      heroAsset: 'assets/images/hero_intro_3.jpg',
      stickmanAsset: 'assets/icons/stickman_obsession.svg',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/onboarding/basic');
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
    return Scaffold(
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
                    child: TextButton(
                      onPressed: _finish,
                      child: const Text('Skip',
                          style: TextStyle(color: FacingTokens.muted)),
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
                    onPressed: _next,
                    child: Text(isLast ? 'Start' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPage {
  final String title;
  final String body;
  final String heroAsset;
  final String stickmanAsset;
  const _IntroPage({
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: FacingTokens.sp7),
              // stickman (서사 시각화)
              Center(
                child: SvgPicture.asset(
                  page.stickmanAsset,
                  width: 140,
                  height: 140,
                  colorFilter: const ColorFilter.mode(
                    FacingTokens.fg,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const Spacer(),
              Text(page.title, style: FacingTokens.h1Serif),
              const SizedBox(height: FacingTokens.sp4),
              Text(page.body, style: FacingTokens.lead),
              const SizedBox(height: FacingTokens.sp8 + FacingTokens.sp7),
            ],
          ),
        ),
      ),
    );
  }
}
