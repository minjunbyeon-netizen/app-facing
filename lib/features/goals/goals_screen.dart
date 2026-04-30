// v1.16 Sprint 13: 목표 관리 화면 — 주간/월간 세션 타겟, PR 목표, 시즌 목표.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/goals_state.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../history/history_models.dart';
import '../history/history_repository.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  Future<List<WodHistoryItem>>? _history;

  @override
  void initState() {
    super.initState();
    final repo = HistoryRepository(context.read<ApiClient>());
    _history = repo.listWodHistory(limit: 200);
  }

  int _sessionsThisWeek(List<WodHistoryItem> list) {
    // v1.19 차수 5 (B-LW-12): attendance(일요일 시작)와 통일.
    // DateTime.weekday: 1=Mon..7=Sun. weekday%7: Sun→0 → 이번주 시작.
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final weekStartDate =
        DateTime(weekStart.year, weekStart.month, weekStart.day);
    return list
        .where((w) => w.createdAt.toLocal().isAfter(weekStartDate))
        .length;
  }

  int _sessionsThisMonth(List<WodHistoryItem> list) {
    final now = DateTime.now();
    return list.where((w) {
      final d = w.createdAt.toLocal();
      return d.year == now.year && d.month == now.month;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalsState>();
    return Scaffold(
      appBar: AppBar(title: const Text('GOALS')),
      body: SafeArea(
        child: FutureBuilder<List<WodHistoryItem>>(
          future: _history,
          builder: (ctx, snap) {
            final list = snap.data ?? const <WodHistoryItem>[];
            final weekCount = _sessionsThisWeek(list);
            final monthCount = _sessionsThisMonth(list);
            return ListView(
              padding: const EdgeInsets.all(FacingTokens.sp4),
              children: [
                // Weekly
                const Text('THIS WEEK', style: FacingTokens.sectionLabel),
                const SizedBox(height: FacingTokens.sp2),
                _ProgressRow(
                  label: '세션',
                  current: weekCount,
                  target: goals.weeklyTargetSessions,
                  unit: '회',
                ),
                const SizedBox(height: FacingTokens.sp3),
                _TargetSlider(
                  label: '주간 타겟 · ${goals.weeklyTargetSessions}회',
                  value: goals.weeklyTargetSessions.toDouble(),
                  min: 1,
                  max: 10,
                  onChanged: (v) => goals.setWeeklyTarget(v.round()),
                ),
                const SizedBox(height: FacingTokens.sp5),

                // Monthly
                const Text('THIS MONTH', style: FacingTokens.sectionLabel),
                const SizedBox(height: FacingTokens.sp2),
                _ProgressRow(
                  label: '세션',
                  current: monthCount,
                  target: goals.monthlyTargetSessions,
                  unit: '회',
                ),
                const SizedBox(height: FacingTokens.sp3),
                _TargetSlider(
                  label: '월간 타겟 · ${goals.monthlyTargetSessions}회',
                  value: goals.monthlyTargetSessions.toDouble(),
                  min: 4,
                  max: 30,
                  onChanged: (v) => goals.setMonthlyTarget(v.round()),
                ),
                const SizedBox(height: FacingTokens.sp5),

                // PR Goals
                const Text('PR GOALS', style: FacingTokens.sectionLabel),
                const SizedBox(height: FacingTokens.sp2),
                _PrGoalRow(
                  label: 'Fran',
                  valueLabel: goals.franPrDisplay,
                  onTap: () => _editFran(context, goals),
                ),
                _PrGoalRow(
                  label: 'Back Squat 1RM',
                  valueLabel: goals.backSquatKg == 0
                      ? '-'
                      : '${goals.backSquatKg.toStringAsFixed(0)} kg',
                  onTap: () => _editBackSquat(context, goals),
                ),
                const SizedBox(height: FacingTokens.sp5),

                // Target Tier
                const Text('TARGET TIER', style: FacingTokens.sectionLabel),
                const SizedBox(height: FacingTokens.sp2),
                Wrap(
                  spacing: FacingTokens.sp2,
                  children: const ['RX', 'RX+', 'Elite', 'Games']
                      .map((t) => ChoiceChip(
                            label: Text(t),
                            selected: goals.targetTier == t,
                            backgroundColor: FacingTokens.surface,
                            selectedColor: FacingTokens.accent,
                            onSelected: (_) {
                              Haptic.selection();
                              goals.setTargetTier(t);
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: FacingTokens.sp5),

                // Season goal
                const Text('SEASON GOAL', style: FacingTokens.sectionLabel),
                const SizedBox(height: FacingTokens.sp2),
                _SeasonGoalField(
                  initial: goals.seasonGoal,
                  onSave: (v) => goals.setSeasonGoal(v),
                ),
                const SizedBox(height: FacingTokens.sp4),
                const Text(
                  '목표·진행률은 이 기기에 저장됩니다.',
                  style: FacingTokens.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _editFran(BuildContext context, GoalsState goals) {
    // QA B-ML-8: ctrl dispose 보장.
    final ctrl = TextEditingController(text: goals.franPrDisplay);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FacingTokens.surfaceOverlay,
        title: const Text('Fran PR Target'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '2:00 (분:초)',
            labelText: 'Target Time',
          ),
          keyboardType: TextInputType.datetime,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final m = RegExp(r'^(\d+):(\d{1,2})$').firstMatch(ctrl.text);
              if (m != null) {
                final sec =
                    int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
                goals.setFranPrSec(sec);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(ctrl.dispose);
  }

  void _editBackSquat(BuildContext context, GoalsState goals) {
    final ctrl = TextEditingController(
        text: goals.backSquatKg == 0 ? '' : '${goals.backSquatKg.toInt()}');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FacingTokens.surfaceOverlay,
        title: const Text('Back Squat Target (kg)'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '140'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null) goals.setBackSquatKg(v);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(ctrl.dispose);
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final String unit;
  const _ProgressRow({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final pct = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    final done = current >= target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: FacingTokens.body)),
            Text(
              done ? 'ACHIEVED' : '$current / $target $unit',
              style: FacingTokens.micro.copyWith(
                color: done ? FacingTokens.accent : FacingTokens.muted,
                fontWeight: FontWeight.w800,
                fontFeatures: FacingTokens.tabular,
              ),
            ),
          ],
        ),
        const SizedBox(height: FacingTokens.sp1),
        ClipRRect(
          borderRadius: BorderRadius.circular(FacingTokens.r1),
          child: Stack(
            children: [
              Container(height: 6, color: FacingTokens.border),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  height: 6,
                  color: done
                      ? FacingTokens.accent
                      : FacingTokens.accent.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TargetSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final void Function(double) onChanged;
  const _TargetSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FacingTokens.caption),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: FacingTokens.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PrGoalRow extends StatelessWidget {
  final String label;
  final String valueLabel;
  final VoidCallback onTap;
  const _PrGoalRow({
    required this.label,
    required this.valueLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp3),
        child: Row(
          children: [
            Expanded(child: Text(label, style: FacingTokens.body)),
            Text(valueLabel,
                style: FacingTokens.body.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: FacingTokens.tabular,
                )),
            const SizedBox(width: FacingTokens.sp2),
            const Icon(Icons.chevron_right,
                color: FacingTokens.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SeasonGoalField extends StatefulWidget {
  final String initial;
  final void Function(String) onSave;
  const _SeasonGoalField({required this.initial, required this.onSave});

  @override
  State<_SeasonGoalField> createState() => _SeasonGoalFieldState();
}

class _SeasonGoalFieldState extends State<_SeasonGoalField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      decoration: const InputDecoration(
        labelText: '시즌 목표',
        hintText: 'Q2 Regionals 진출 · Fran sub-2:00 · Snatch 95kg',
      ),
      maxLines: 2,
      maxLength: 200,
      onChanged: widget.onSave,
    );
  }
}
