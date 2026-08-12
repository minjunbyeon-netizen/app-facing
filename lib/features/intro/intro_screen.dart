import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/appkit.gen.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../widgets/brand_logo.dart';
import '../auth/auth_state.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pc = PageController();
  int _page = 0;

  // v1.27 (2026-07-28): 3기둥 동기화 — WOD 보드 · 게이미피케이션 · Tier 프로필.
  // 사진 히어로·스틱맨 폐기, HYPHEN 로고(BrandLogo) 중심의 클린 레이아웃.
  // v1.29: 카피 한글 기본 전환 (DESIGN-SSOT §7 — 도메인 용어만 영문 유지).
  static const List<_IntroPage> _pages = [
    _IntroPage(
      stage: 'WOD 보드',
      title: '오늘의 WOD.',
      body: '코치가 올린 오늘의 WOD.\n박스 공지까지 한 곳에.',
    ),
    _IntroPage(
      stage: '레벨 · 업적',
      title: '기록이 레벨이 된다.',
      body: '기록할수록 쌓이는\n레벨 · 업적 · 마일스톤.',
    ),
    _IntroPage(
      stage: 'TIER',
      title: '내 Tier.',
      body: 'Benchmarks 기반 6단계 Tier.\n프로필에서 언제든 수정.',
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
        backgroundColor: FacingTokens.bg,
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
                          foregroundColor: FacingTokens.fgSecondary,
                        ),
                        onPressed: () {
                          Haptic.light();
                          _finish();
                        },
                        child: const Text(AppKit.strSkip),
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
                        width: active
                            ? FacingTokens.sp5 - 2
                            : FacingTokens.sp2 - 2,
                        decoration: BoxDecoration(
                          color: active
                              ? FacingTokens.accent
                              : FacingTokens.border,
                          borderRadius:
                              BorderRadius.circular(FacingTokens.r1),
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
                      child: Text(isLast ? AppKit.strStart : AppKit.strNext),
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
  final String stage;
  final String title;
  final String body;
  const _IntroPage({
    required this.stage,
    required this.title,
    required this.body,
  });
}

/// v1.27: 클린 페이지 — HYPHEN 로고 + stage 라벨 + 영문 헤드라인 + 한글 캡션 스택.
class _IntroPageView extends StatelessWidget {
  final _IntroPage page;
  const _IntroPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FacingTokens.sp5,
          vertical: FacingTokens.sp5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // v1.29: 로고 폭 = 기본 220 (진입 화면 통일, DESIGN-SSOT §6).
            const BrandLogo(),
            const Spacer(flex: 3),
            Text(page.stage,
                style: FacingTokens.sectionLabel,
                textAlign: TextAlign.center),
            const SizedBox(height: FacingTokens.sp2),
            Text(page.title,
                style: FacingTokens.h1, textAlign: TextAlign.center),
            const SizedBox(height: FacingTokens.sp4),
            Text(page.body,
                style: FacingTokens.lead, textAlign: TextAlign.center),
            const SizedBox(height: FacingTokens.sp8 + FacingTokens.sp7),
          ],
        ),
      ),
    );
  }
}
