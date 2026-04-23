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
        body: const Center(child: Text('데이터 없음.', style: FacingTokens.body)),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TierBadge(tier: tier, fontSize: 24),
                      const SizedBox(width: FacingTokens.sp4),
                      Text('Score $score',
                          style: FacingTokens.body.copyWith(
                            fontWeight: FontWeight.w700,
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
          const SizedBox(height: FacingTokens.sp1),
          Row(
            children: [
              Text('Score $score', style: FacingTokens.caption),
              const SizedBox(width: FacingTokens.sp3),
              Text('$itemsUsed items', style: FacingTokens.caption),
            ],
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: FacingTokens.sp1),
            Text('입력 ${missing.length}개 추가 시 정확도 향상',
                style: FacingTokens.micro),
          ],
        ],
      ),
    );
  }
}
