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

class _BenchmarkSheet extends StatefulWidget {
  final CategoryBenchmark bench;
  const _BenchmarkSheet({required this.bench});

  @override
  State<_BenchmarkSheet> createState() => _BenchmarkSheetState();
}

class _BenchmarkSheetState extends State<_BenchmarkSheet> {
  bool _female = false;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final metrics = widget.bench.metrics;
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
          // Header + gender toggle
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FacingTokens.sp4,
              vertical: FacingTokens.sp3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(widget.bench.displayName, style: FacingTokens.h2),
                    ),
                    _GenderToggle(
                      female: _female,
                      onChanged: (v) => setState(() => _female = v),
                    ),
                  ],
                ),
                const SizedBox(height: FacingTokens.sp2),
                Text(widget.bench.description, style: FacingTokens.caption),
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
                ...metrics.map((m) => _MetricRow(metric: m, female: _female)),
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
                      Text(widget.bench.sourceShort, style: FacingTokens.micro),
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

class _GenderToggle extends StatelessWidget {
  final bool female;
  final ValueChanged<bool> onChanged;
  const _GenderToggle({required this.female, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip('M', !female, () => onChanged(false)),
        const SizedBox(width: 6),
        _chip('F', female, () => onChanged(true)),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        backgroundColor: selected
            ? FacingTokens.accent.withValues(alpha: 0.15)
            : Colors.transparent,
        side: BorderSide(
          color: selected ? FacingTokens.accent : FacingTokens.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        foregroundColor: selected ? FacingTokens.accent : FacingTokens.muted,
        overlayColor: FacingTokens.accent.withValues(alpha: 0.1),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: FacingTokens.micro.copyWith(
          color: selected ? FacingTokens.accent : FacingTokens.muted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _TierHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 110),
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
  final bool female;
  const _MetricRow({required this.metric, required this.female});

  @override
  Widget build(BuildContext context) {
    final values = metric.valuesFor(female);
    final note = metric.noteFor(female);
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
                if (note != null)
                  Text(
                    note,
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
                  values[i],
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
