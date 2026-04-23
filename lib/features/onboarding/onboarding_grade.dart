import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../profile/profile_state.dart';

class OnboardingGradeScreen extends StatelessWidget {
  const OnboardingGradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final grade = p.gradeResult;
    if (grade == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('결과 · 등급')),
        body: const Center(child: Text('등급 정보 없음', style: FacingTokens.body)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('결과 · 당신의 등급'),
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
                  const Text('종합 등급', style: FacingTokens.caption),
                  const SizedBox(height: FacingTokens.sp1),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        (grade['overall_label_ko'] ?? '').toString(),
                        style: FacingTokens.display.copyWith(
                          color: FacingTokens.accent,
                        ),
                      ),
                      const SizedBox(width: FacingTokens.sp2),
                      Text(
                        '${grade['overall_number']}/6',
                        style: FacingTokens.h2,
                      ),
                    ],
                  ),
                  const SizedBox(height: FacingTokens.sp2),
                  Text(
                    '점수 ${grade['overall_score']}',
                    style: FacingTokens.caption,
                  ),
                  const SizedBox(height: FacingTokens.sp6),
                  // v1.10.0 6 카테고리 분리 표시
                  if (grade['power'] != null) ...[
                    _CategoryCard(title: '파워', data: grade['power']),
                    const SizedBox(height: FacingTokens.sp3),
                  ],
                  if (grade['olympic'] != null) ...[
                    _CategoryCard(title: '역도', data: grade['olympic']),
                    const SizedBox(height: FacingTokens.sp3),
                  ],
                  _CategoryCard(title: '짐내스틱', data: grade['gymnastics']),
                  const SizedBox(height: FacingTokens.sp3),
                  _CategoryCard(title: '카디오', data: grade['cardio']),
                  if (grade['metcon'] != null) ...[
                    const SizedBox(height: FacingTokens.sp3),
                    _CategoryCard(title: '메타콘 (멘탈)', data: grade['metcon']),
                  ],
                  const SizedBox(height: FacingTokens.sp6),
                  const Text(
                    '이 등급에 맞춰 페이싱 강도가 자동 조정됩니다. 언제든 프로필에서 수정 가능합니다.',
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
                  child: const Text('시작하기'),
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
    final label = (m['label_ko'] ?? '').toString();
    final score = m['score'];
    final itemsUsed = m['items_used'] ?? 0;
    final missing = (m['missing'] as List?) ?? const [];
    return Container(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      decoration: BoxDecoration(
        border: Border.all(color: FacingTokens.border),
        borderRadius: BorderRadius.circular(FacingTokens.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: FacingTokens.body.copyWith(fontWeight: FontWeight.w700)),
              Text(label, style: FacingTokens.h3),
            ],
          ),
          const SizedBox(height: FacingTokens.sp1),
          Row(
            children: [
              Text('점수 $score', style: FacingTokens.caption),
              const SizedBox(width: FacingTokens.sp3),
              Text('측정 $itemsUsed개', style: FacingTokens.caption),
            ],
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: FacingTokens.sp2),
            Text('추가 측정하면 더 정확: ${missing.length}개',
                style: FacingTokens.micro),
          ],
        ],
      ),
    );
  }
}
