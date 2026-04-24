import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/quotes.dart';
import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../widgets/grain_overlay.dart';
import '../../widgets/quote_card.dart';
import '../../widgets/tier_badge.dart';
import '../profile/profile_state.dart';

/// v1.15.3: 백엔드 점수 스케일(1.0~6.0) → 0~100 만점 환산.
/// 1.0=0, 6.0=100 기준 선형 매핑. 음수 방지 clamp.
int _to100(dynamic raw) {
  if (raw is! num) return 0;
  final s = raw.toDouble();
  final pct = ((s - 1.0) / 5.0 * 100).round();
  return pct.clamp(0, 100);
}

class OnboardingGradeScreen extends StatelessWidget {
  const OnboardingGradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final grade = p.gradeResult;
    if (grade == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('YOUR TIER')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(FacingTokens.sp5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('1RM 없음.', style: FacingTokens.h2),
                const SizedBox(height: FacingTokens.sp2),
                const Text('먼저 입력. Benchmarks 완료하면 Tier 확정.',
                    style: FacingTokens.caption),
                const SizedBox(height: FacingTokens.sp6),
                ElevatedButton(
                  onPressed: () {
                    Haptic.light();
                    Navigator.of(context)
                        .pushReplacementNamed('/onboarding/basic');
                  },
                  child: const Text('Start Onboarding'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final overallNumber = grade['overall_number'];
    final tier = Tier.fromOverallNumber(
        overallNumber is num ? overallNumber : null);
    final score = grade['overall_score'];
    // v1.15 P2-1: Tier별 고정 명언 (저자 포함).
    final quote = Quote(tier.quote, tier.quoteAuthor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('YOUR TIER'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // v1.15 P1-8: Grade 화면 배경 — hero + 하단 darken gradient로 카드 텍스트 가독성 보장.
          Image.asset(
            'assets/images/hero_grade.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            opacity: const AlwaysStoppedAnimation(0.28),
          ),
          // 하단→중간 어두움 gradient (P1-8 카드 가독성).
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  FacingTokens.bg.withValues(alpha: 0.40),
                  FacingTokens.bg.withValues(alpha: 0.72),
                  FacingTokens.bg.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          const GrainOverlay.subtle(),
          SafeArea(
            child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(FacingTokens.sp4),
                children: [
                  const SizedBox(height: FacingTokens.sp3),
                  // v1.15.3: 'YOUR TIER' 대문자 + 마침표 제거. serif 헤드라인 유지.
                  Text('YOUR TIER', style: FacingTokens.h1Serif),
                  const SizedBox(height: FacingTokens.sp4),
                  QuoteCard(quote: quote, compact: true),
                  const SizedBox(height: FacingTokens.sp6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TierBadge(tier: tier, fontSize: 24),
                      const SizedBox(width: FacingTokens.sp4),
                      Text('Score ${_to100(score)} / 100',
                          style: FacingTokens.body.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: FacingTokens.tabular,
                          )),
                    ],
                  ),
                  const SizedBox(height: FacingTokens.sp6),
                  // v1.10.0 6 카테고리 분리 표시
                  if (grade['power'] != null) ...[
                    _CategoryCard(title: 'POWER', data: grade['power']),
                    const SizedBox(height: FacingTokens.sp3),
                  ],
                  if (grade['olympic'] != null) ...[
                    _CategoryCard(title: 'OLYMPIC', data: grade['olympic']),
                    const SizedBox(height: FacingTokens.sp3),
                  ],
                  _CategoryCard(title: 'GYMNASTICS', data: grade['gymnastics']),
                  const SizedBox(height: FacingTokens.sp3),
                  _CategoryCard(title: 'CARDIO', data: grade['cardio']),
                  if (grade['metcon'] != null) ...[
                    const SizedBox(height: FacingTokens.sp3),
                    _CategoryCard(title: 'METCON', data: grade['metcon']),
                  ],
                  const SizedBox(height: FacingTokens.sp6),
                  const Text(
                    'Tier에 맞춰 Split과 Burst 자동 조정.\n'
                    '언제든 Profile에서 수정 가능.',
                    style: FacingTokens.caption,
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(FacingTokens.sp4),
                child: ElevatedButton(
                  onPressed: () {
                    Haptic.medium();
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/shell', (_) => false);
                  },
                  child: const Text('Start WOD'),
                ),
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

class _CategoryCard extends StatelessWidget {
  final String title;
  final dynamic data;
  const _CategoryCard({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final m = data is Map ? data as Map : const {};
    final score = m['score'];
    final itemsUsed = m['items_used'] ?? 0;
    final missing = (m['missing'] as List?) ?? const [];
    final num? catNum = m['number'] is num ? m['number'] as num : null;
    final tier = Tier.fromOverallNumber(catNum);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        FacingTokens.sp4, FacingTokens.sp3, FacingTokens.sp4, FacingTokens.sp3,
      ),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: tier.color, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: FacingTokens.sectionLabel),
              TierBadge(tier: tier),
            ],
          ),
          const SizedBox(height: FacingTokens.sp2),
          // v1.15.3: Score 1~6 → 0~100 환산. "NN / 100" 표기 통일.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${_to100(score)}',
                  style: FacingTokens.body.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    fontFeatures: FacingTokens.tabular,
                  )),
              const SizedBox(width: FacingTokens.sp1),
              const Text('/ 100', style: FacingTokens.caption),
              const SizedBox(width: FacingTokens.sp3),
              Text('$itemsUsed items', style: FacingTokens.caption),
            ],
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: FacingTokens.sp1),
            // v1.15 P1-11: micro(11sp) → caption(13sp) — Masters 노안 대응.
            Text('입력 ${missing.length}개 추가 시 정확도 향상',
                style: FacingTokens.caption),
          ],
        ],
      ),
    );
  }
}
