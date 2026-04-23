import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/quotes.dart';
import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../widgets/quote_card.dart';
import '../../widgets/tier_badge.dart';
import '../profile/profile_state.dart';

class OnboardingGradeScreen extends StatelessWidget {
  const OnboardingGradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final grade = p.gradeResult;
    if (grade == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Tier')),
        body: const Center(child: Text('No data.', style: FacingTokens.body)),
      );
    }
    final overallNumber = grade['overall_number'];
    final tier = Tier.fromOverallNumber(
        overallNumber is num ? overallNumber : null);
    final score = grade['overall_score'];
    final quote = stableQuote(
        (overallNumber is num ? overallNumber.round() : 0) * 7 + 3);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Tier'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(FacingTokens.sp4),
                children: [
                  const SizedBox(height: FacingTokens.sp3),
                  QuoteCard(quote: quote, compact: true),
                  const SizedBox(height: FacingTokens.sp6),
                  const Text('OVERALL', style: FacingTokens.micro),
                  const SizedBox(height: FacingTokens.sp2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TierBadge(tier: tier, fontSize: 18),
                      const SizedBox(width: FacingTokens.sp3),
                      Text('$overallNumber/6',
                          style: FacingTokens.h2.copyWith(
                            color: FacingTokens.muted,
                          )),
                    ],
                  ),
                  const SizedBox(height: FacingTokens.sp2),
                  Text('Score $score', style: FacingTokens.caption),
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
                    '언제든 Profile에서 수정.',
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
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/home', (_) => false),
                  child: const Text('Start WOD'),
                ),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(FacingTokens.sp4),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: Border.all(color: FacingTokens.border),
        borderRadius: BorderRadius.circular(FacingTokens.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: FacingTokens.body.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              )),
              TierBadge(tier: tier),
            ],
          ),
          const SizedBox(height: FacingTokens.sp2),
          Row(
            children: [
              Text('Score $score', style: FacingTokens.caption),
              const SizedBox(width: FacingTokens.sp3),
              Text('$itemsUsed items', style: FacingTokens.caption),
            ],
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: FacingTokens.sp2),
            Text('${missing.length} more input → higher accuracy',
                style: FacingTokens.micro),
          ],
        ],
      ),
    );
  }
}
