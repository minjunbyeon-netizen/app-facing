// Algorithm 투명성 화면.
// SSOT: ~/.claude/reference/study/fitness/ 5 sub-file (290 출처, T1 50%+).
//   power.md / olympic-lifting.md / cardio.md / gymnastics.md / physical-norms.md
// 폐기: services/facing/docs/refer/* (2026-04-28) + 단일 fitness.md (2026-04-29).

import 'package:flutter/material.dart';

import '../../core/formula_references.dart';
import '../../core/theme.dart';

class AlgorithmScreen extends StatelessWidget {
  const AlgorithmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ALGORITHM')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(FacingTokens.sp4),
          children: [
            const Text('ENGINE SCORE', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            const Text('6 카테고리 개별 점수(1.0-6.0)의 가중 평균.',
                style: FacingTokens.body),
            const SizedBox(height: FacingTokens.sp2),
            const _FormulaLine(
                label: 'Overall', value: 'weighted_avg(gymnastics·weightlifting·cardio·power·olympic·metcon)'),
            const _FormulaLine(
                label: 'Scale', value: '1.0 (Untrained) → 6.0 (Elite/Games)'),
            const _FormulaLine(
                label: 'Source', value: 'fitness/power.md §A3 + olympic-lifting.md §5 (Strength Level 2024 + IWF)'),
            const _FormulaLine(
                label: 'UI MAP', value: '0–100 선형 매핑 (engineScoreTo100)'),
            const SizedBox(height: FacingTokens.sp5),

            const Text('TIER MAPPING', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            const _TierRow(num: '1', tier: 'Scaled', color: FacingTokens.tierScaled),
            const _TierRow(num: '2', tier: 'Scaled', color: FacingTokens.tierScaled),
            const _TierRow(num: '3', tier: 'RX', color: FacingTokens.tierRx),
            const _TierRow(num: '4', tier: 'RX+', color: FacingTokens.tierRxPlus),
            const _TierRow(num: '5', tier: 'Elite', color: FacingTokens.tierElite),
            const _TierRow(num: '6', tier: 'Games', color: FacingTokens.tierGames),
            const SizedBox(height: FacingTokens.sp5),

            const Text('SPLIT · BURST', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            const Text(
              '동작별 예상시간 → 내림차순 분할(Split) + 후반 공격지점(Burst) 계산.',
              style: FacingTokens.body,
            ),
            const SizedBox(height: FacingTokens.sp2),
            const _FormulaLine(
                label: 'Split',
                value: 'N-(N-Δ)-(N-2Δ)... 피로 증가 반영'),
            const _FormulaLine(
                label: 'Burst',
                value: 'W-prime 85% 소진 시점(Noakes/Skiba 기반)'),
            const _FormulaLine(
                label: 'Rest',
                value: '세트 간 5-15초, 페이스 ≤ 임계 LT2'),
            const SizedBox(height: FacingTokens.sp5),

            const Text('SCALED WEIGHTING', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            const Text(
              'Scaled 기록은 Tier 반영 시 감산 가중치 적용 (Phase 2 확정 — 현재 mock).',
              style: FacingTokens.body,
            ),
            const SizedBox(height: FacingTokens.sp5),

            const Text('REFERENCES', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp3),
            ...kFormulaReferences.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: FacingTokens.sp3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title,
                        style: FacingTokens.body.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 2),
                    Text(r.authors, style: FacingTokens.caption),
                    const SizedBox(height: 2),
                    Text(r.relevance, style: FacingTokens.caption),
                    const SizedBox(height: 2),
                    Text(r.section,
                        style: FacingTokens.micro.copyWith(
                            color: FacingTokens.muted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: FacingTokens.sp4),
            const Text(
              'SSOT: ~/.claude/reference/study/fitness/ (5 sub-file)',
              style: FacingTokens.micro,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FacingTokens.sp1),
            const Text(
              'Beta Preview · Split 시뮬레이터는 Phase 2 예정.',
              style: FacingTokens.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormulaLine extends StatelessWidget {
  final String label;
  final String value;
  const _FormulaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: FacingTokens.micro.copyWith(
                color: FacingTokens.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Text(value,
                style: FacingTokens.caption.copyWith(color: FacingTokens.fg)),
          ),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  final String num;
  final String tier;
  final Color color;
  const _TierRow({required this.num, required this.tier, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(num,
                style: FacingTokens.body.copyWith(
                  fontFeatures: FacingTokens.tabular,
                  fontWeight: FontWeight.w700,
                )),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FacingTokens.sp2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(FacingTokens.r1),
            ),
            child: Text(
              tier.toUpperCase(),
              style: FacingTokens.micro.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
