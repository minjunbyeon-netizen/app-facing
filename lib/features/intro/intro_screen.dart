import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pc = PageController();
  int _page = 0;

  static const List<_IntroPage> _pages = [
    _IntroPage(
      title: 'Split이 순위를 만든다.',
      body: '첫 1분 all-out은 마지막 5분을 부순다.\n'
          '논문 공식으로 Split · Burst 시점을 계산한다.',
    ),
    _IntroPage(
      title: '6개 지표. Engine을 측정한다.',
      body: 'Body · Power · Olympic · Gymnastics · Cardio · Metcon.\n'
          '아는 것만. 빈 칸은 자동 추론.',
    ),
    _IntroPage(
      title: '시작해라.',
      body: '프로필은 언제든 수정 가능.\n'
          'WOD 붙이면 즉시 전략 출력.',
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
      body: SafeArea(
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
                  child: const Text('건너뛰기',
                      style: TextStyle(color: FacingTokens.muted)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _IntroPageView(page: _pages[i]),
              ),
            ),
            // dot indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: active ? 22 : 6,
                  decoration: BoxDecoration(
                    color: active ? FacingTokens.fg : FacingTokens.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(FacingTokens.sp4),
              child: ElevatedButton(
                onPressed: _next,
                child: Text(isLast ? '시작하기' : '다음'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage {
  final String title;
  final String body;
  const _IntroPage({required this.title, required this.body});
}

class _IntroPageView extends StatelessWidget {
  final _IntroPage page;
  const _IntroPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FacingTokens.sp5,
        vertical: FacingTokens.sp5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(page.title, style: FacingTokens.h1),
          const SizedBox(height: FacingTokens.sp4),
          Text(page.body, style: FacingTokens.lead),
        ],
      ),
    );
  }
}
