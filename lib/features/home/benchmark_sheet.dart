import 'package:flutter/material.dart';

import '../../core/benchmark_data.dart';
import '../../core/theme.dart';

/// 카테고리 탭 → 티어별 벤치마크 비교표 Bottom Sheet.
void showBenchmarkSheet(BuildContext context, String categoryKey) {
  final bench = kBenchmarks[categoryKey];
  if (bench == null) return;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: FacingTokens.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _BenchmarkSheet(bench: bench),
  );
}

class _BenchmarkSheet extends StatelessWidget {
  final CategoryBenchmark bench;
  const _BenchmarkSheet({required this.bench});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, sc) => Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: FacingTokens.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FacingTokens.sp4,
              vertical: FacingTokens.sp3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bench.displayName, style: FacingTokens.h2),
                const SizedBox(height: FacingTokens.sp2),
                Text(bench.description, style: FacingTokens.caption),
              ],
            ),
          ),
          const Divider(height: 1, color: FacingTokens.border),
          // Table — scrollable
          Expanded(
            child: ListView(
              controller: sc,
              padding: const EdgeInsets.all(FacingTokens.sp4),
              children: [
                _TierHeaderRow(),
                const SizedBox(height: FacingTokens.sp2),
                ...bench.metrics.map((m) => _MetricRow(metric: m)),
                const SizedBox(height: FacingTokens.sp5),
                // Source
                Container(
                  padding: const EdgeInsets.all(FacingTokens.sp3),
                  decoration: BoxDecoration(
                    border: Border.all(color: FacingTokens.border),
                    borderRadius: BorderRadius.circular(FacingTokens.r2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SOURCE', style: FacingTokens.sectionLabel),
                      const SizedBox(height: 4),
                      Text(bench.sourceShort, style: FacingTokens.micro),
                    ],
                  ),
                ),
                SizedBox(height: mq.viewInsets.bottom + FacingTokens.sp4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 110), // metric label column
        ...List.generate(kTierLabels.length, (i) {
          final color = _tierColor(i);
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                kTierLabels[i],
                textAlign: TextAlign.center,
                style: FacingTokens.micro.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final BenchmarkMetric metric;
  const _MetricRow({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: FacingTokens.sp2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: FacingTokens.caption.copyWith(
                    color: FacingTokens.fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (metric.note != null)
                  Text(
                    metric.note!,
                    style: FacingTokens.micro.copyWith(color: FacingTokens.muted),
                  ),
              ],
            ),
          ),
          ...List.generate(kTierLabels.length, (i) {
            final color = _tierColor(i);
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Text(
                  metric.tierValues[i],
                  textAlign: TextAlign.center,
                  style: FacingTokens.micro.copyWith(
                    color: i == 0 ? color : FacingTokens.fg,
                    fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

Color _tierColor(int index) {
  switch (index) {
    case 0:
      return FacingTokens.tierGames;
    case 1:
      return FacingTokens.tierElite;
    case 2:
      return FacingTokens.tierRxPlus;
    case 3:
      return FacingTokens.tierRx;
    case 4:
    default:
      return FacingTokens.tierScaled;
  }
}
