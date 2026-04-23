import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/unit_state.dart';
import '../history/history_repository.dart';
import '../profile/profile_state.dart';

/// v1.10.0 위저드 — 5 카테고리(파워/역도/짐내/카디오/메타콘) PageView.
/// 신체(Step 1)는 onboarding_basic.dart에서 별도 입력.
class OnboardingBenchmarksScreen extends StatefulWidget {
  const OnboardingBenchmarksScreen({super.key});

  @override
  State<OnboardingBenchmarksScreen> createState() =>
      _OnboardingBenchmarksScreenState();
}

class _OnboardingBenchmarksScreenState
    extends State<OnboardingBenchmarksScreen> {
  late final Map<String, TextEditingController> _ctrls;
  final PageController _pc = PageController();
  int _page = 0;
  bool _submitting = false;
  String? _error;

  // v1.10.0 5 카테고리 — 1 화면 = 1 카테고리
  static const List<_Category> _categories = [
    _Category(
      key: 'power',
      title: 'POWER',
      hint: 'SBD + OHP · 1RM',
      fields: [
        'back_squat_1rm_lb',
        'front_squat_1rm_lb',
        'bench_press_1rm_lb',
        'deadlift_1rm_lb',
        'ohp_1rm_lb',
      ],
    ),
    _Category(
      key: 'olympic',
      title: 'OLYMPIC',
      hint: 'Clean · Snatch · 1RM',
      fields: [
        'clean_1rm_lb',
        'clean_and_jerk_1rm_lb',
        'snatch_1rm_lb',
        'power_clean_1rm_lb',
        'power_snatch_1rm_lb',
      ],
    ),
    _Category(
      key: 'gymnastics',
      title: 'GYMNASTICS',
      hint: 'Max Unbroken · 1-min Max',
      fields: [
        'strict_pull_up_max_ub',
        'chest_to_bar_max_ub',
        'hspu_max_ub',
        'bar_muscle_up_max_ub',
        'ring_muscle_up_max_ub',
        'toes_to_bar_max_ub',
        'push_up_per_min',
      ],
    ),
    _Category(
      key: 'cardio',
      title: 'CARDIO',
      hint: 'Run · Row · Cooper · Engine',
      fields: [
        'run_mile_sec',
        'row_500m_sec',
        'row_2km_sec',
        'cooper_12min_meters',
      ],
    ),
    _Category(
      key: 'metcon',
      title: 'METCON',
      hint: '1-min Max · Capacity',
      fields: [
        'burpee_per_min',
        'double_under_per_min',
        'assault_bike_per_min',
        'wall_ball_per_min',
        'box_jump_per_min',
      ],
    ),
  ];

  static const Map<String, (String label, String suffix, String hint, String help)>
      _meta = {
    // Power
    'back_squat_1rm_lb':
        ('Back Squat 1RM', 'lb', 'e.g. 315', 'Base strength.'),
    'front_squat_1rm_lb':
        ('Front Squat 1RM', 'lb', 'e.g. 255', 'Clean receive position.'),
    'bench_press_1rm_lb':
        ('Bench Press 1RM', 'lb', 'e.g. 225', 'Upper-body push.'),
    'deadlift_1rm_lb':
        ('Deadlift 1RM', 'lb', 'e.g. 405', 'Posterior chain force.'),
    'ohp_1rm_lb':
        ('OHP 1RM', 'lb', 'e.g. 135', 'Strict overhead press.'),
    // Olympic
    'clean_1rm_lb':
        ('Clean 1RM', 'lb', 'e.g. 225', 'Full squat catch.'),
    'clean_and_jerk_1rm_lb':
        ('Clean & Jerk 1RM', 'lb', 'e.g. 215', 'Full lift.'),
    'snatch_1rm_lb':
        ('Snatch 1RM', 'lb', 'e.g. 165', 'Full squat catch, one motion.'),
    'power_clean_1rm_lb':
        ('Power Clean 1RM', 'lb', 'e.g. 195', 'High catch.'),
    'power_snatch_1rm_lb':
        ('Power Snatch 1RM', 'lb', 'e.g. 145', 'High catch.'),
    // Gymnastics
    'strict_pull_up_max_ub':
        ('Strict Pull-up Max', 'reps', 'e.g. 12', 'No kip. Pure strict.'),
    'chest_to_bar_max_ub':
        ('Chest-to-Bar Max', 'reps', 'e.g. 18', 'Chest touches the bar.'),
    'hspu_max_ub':
        ('HSPU Max', 'reps', 'e.g. 10', 'Handstand push-up.'),
    'bar_muscle_up_max_ub':
        ('Bar Muscle-up Max', 'reps', 'e.g. 8', 'Bar muscle-up.'),
    'ring_muscle_up_max_ub':
        ('Ring Muscle-up Max', 'reps', 'e.g. 5', 'Ring muscle-up.'),
    'toes_to_bar_max_ub':
        ('T2B Max', 'reps', 'e.g. 25', 'Core endurance.'),
    'push_up_per_min':
        ('Push-up 1-min Max', 'reps', 'e.g. 45', 'Auxiliary balance metric.'),
    // Cardio
    'run_mile_sec':
        ('1-mile Run', 'sec', 'e.g. 360 (6:00)', 'Running benchmark.'),
    'row_500m_sec':
        ('500m Row', 'sec', 'e.g. 95 (1:35)', 'Power cardio.'),
    'row_2km_sec':
        ('2km Row', 'sec', 'e.g. 440 (7:20)', 'Cardio endurance.'),
    'cooper_12min_meters':
        ('Cooper 12-min (m)', 'm', 'e.g. 2800', 'Distance in 12 min.'),
    // Metcon
    'burpee_per_min':
        ('Burpee 1-min Max', 'reps', 'e.g. 22', 'Whole-body metcon.'),
    'double_under_per_min':
        ('Double-under 1-min Max', 'reps', 'e.g. 110', 'Coordination.'),
    'assault_bike_per_min':
        ('Assault Bike 1-min', 'cal', 'e.g. 22', 'Cardio + mental.'),
    'wall_ball_per_min':
        ('Wall Ball 1-min Max', 'reps', 'e.g. 22', '@20lb / 14lb.'),
    'box_jump_per_min':
        ('Box Jump 1-min Max', 'reps', 'e.g. 18', '@24" / 20".'),
  };

  static List<String> get _allFields =>
      _categories.expand((c) => c.fields).toList(growable: false);

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileState>();
    final unit = context.read<UnitState>();
    _ctrls = {
      for (final k in _allFields)
        k: TextEditingController(
          text: _initText(p.getBenchmark(k), k, unit),
        ),
    };
  }

  String _initText(double? stored, String key, UnitState unit) {
    if (stored == null) return '';
    if (key.endsWith('_lb')) {
      final disp = unit.lbToDisplay(stored);
      return disp == null ? '' : _fmt(disp);
    }
    return _fmt(stored);
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  bool get _anyFilled {
    for (final k in _allFields) {
      final v = double.tryParse(_ctrls[k]!.text.trim());
      if (v != null && v > 0) return true;
    }
    return false;
  }

  bool get _isLastPage => _page >= _categories.length - 1;

  void _next() {
    if (_isLastPage) {
      _compute();
      return;
    }
    _pc.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _prev() {
    if (_page == 0) return;
    _pc.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _compute() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    // 계산 로딩 오버레이 (최소 800ms 보장)
    final minShow = Future<void>.delayed(const Duration(milliseconds: 800));
    _showLoadingOverlay();
    try {
      final p = context.read<ProfileState>();
      final unit = context.read<UnitState>();
      for (final k in _allFields) {
        final disp = double.tryParse(_ctrls[k]!.text.trim());
        double? stored;
        if (disp == null || disp <= 0) {
          stored = null;
        } else if (k.endsWith('_lb')) {
          stored = unit.displayToLb(disp);
        } else {
          stored = disp;
        }
        p.setBenchmark(k, stored);
      }
      final api = context.read<ApiClient>();
      final result =
          await api.post('/api/v1/profile/grade', p.toGradePayload());
      p.setGradeResult(result);

      // fire-and-forget: Engine snapshot 저장. 실패해도 UX 진행.
      unawaited(_saveEngineSnapshot(api, result));

      await minShow;
      if (mounted) {
        _hideLoadingOverlay();
        Navigator.of(context).pushReplacementNamed('/onboarding/grade');
      }
    } catch (_) {
      await minShow;
      if (mounted) {
        _hideLoadingOverlay();
        setState(() => _error = 'Calc failed. Retry.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _saveEngineSnapshot(ApiClient api, Map<String, dynamic> result) async {
    try {
      final repo = HistoryRepository(api);
      double? catScore(String key) {
        final c = result[key];
        if (c is Map && c['score'] is num) return (c['score'] as num).toDouble();
        return null;
      }
      int itemsUsed = 0;
      for (final key in const ['gymnastics', 'weightlifting', 'cardio',
                                'power', 'olympic', 'metcon']) {
        final c = result[key];
        if (c is Map && c['items_used'] is num) {
          itemsUsed += (c['items_used'] as num).toInt();
        }
      }
      await repo.saveEngineSnapshot({
        'overall_score': result['overall_score'],
        'overall_number': result['overall_number'],
        'overall_label': result['overall'],
        'gymnastics_score': catScore('gymnastics'),
        'weightlifting_score': catScore('weightlifting'),
        'cardio_score': catScore('cardio'),
        'power_score': catScore('power'),
        'olympic_score': catScore('olympic'),
        'metcon_score': catScore('metcon'),
        'items_used': itemsUsed,
      });
    } catch (_) {
      // 저장 실패는 로그만. UX는 영향 없음.
    }
  }

  bool _overlayShown = false;
  void _showLoadingOverlay() {
    if (_overlayShown || !mounted) return;
    _overlayShown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => const _ComputeLoadingDialog(),
    );
  }

  void _hideLoadingOverlay() {
    if (!_overlayShown) return;
    _overlayShown = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    // 전체 위저드 6단계 중 benchmarks는 2~6번 (신체=1, 등급=결과화면).
    final stepNumber = _page + 2;
    final progress = stepNumber / 6;
    final pct = (progress * 100).round();
    return Scaffold(
      appBar: AppBar(title: Text('Step $stepNumber / 6 · ${_categories[_page].title}')),
      body: SafeArea(
        child: Column(
          children: [
            // 진행률
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FacingTokens.sp4,
                FacingTokens.sp3,
                FacingTokens.sp4,
                FacingTokens.sp2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step $stepNumber / 6',
                        style: FacingTokens.caption,
                      ),
                      Text('$pct%', style: FacingTokens.caption),
                    ],
                  ),
                  const SizedBox(height: FacingTokens.sp1),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: FacingTokens.border,
                    color: FacingTokens.fg,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _categories.length,
                itemBuilder: (ctx, i) => _buildPage(_categories[i]),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: FacingTokens.sp4),
                child: Container(
                  padding: const EdgeInsets.all(FacingTokens.sp3),
                  decoration: BoxDecoration(
                    border: Border.all(color: FacingTokens.fg),
                    borderRadius: BorderRadius.circular(FacingTokens.r2),
                  ),
                  child: Text(_error!, style: FacingTokens.body),
                ),
              ),
            // 하단 nav
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(FacingTokens.sp4),
                child: Row(
                  children: [
                    if (_page > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting ? null : _prev,
                          child: const Text('← Back'),
                        ),
                      ),
                    if (_page > 0) const SizedBox(width: FacingTokens.sp3),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _next,
                        child: Text(
                          _submitting
                              ? 'Calculating'
                              : (_isLastPage
                                  ? (_anyFilled ? 'Measure Engine' : 'Skip · See Tier')
                                  : 'Next'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_Category cat) {
    final unit = context.watch<UnitState>();
    return ListView(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      children: [
        Text(cat.title, style: FacingTokens.h2),
        const SizedBox(height: FacingTokens.sp1),
        Text(cat.hint, style: FacingTokens.caption),
        const SizedBox(height: FacingTokens.sp1),
        const Text(
          '아는 것만 입력. 빈 칸은 자동 추론.',
          style: FacingTokens.caption,
        ),
        const SizedBox(height: FacingTokens.sp4),
        ...cat.fields.map((k) {
          final m = _meta[k]!;
          final isWeight = k.endsWith('_lb');
          final suffix = isWeight ? unit.weightSuffix : m.$2;
          final hint = isWeight && unit.isKg
              ? _lbHintToKgHint(m.$3)
              : m.$3;
          return _BenchmarkRow(
            label: m.$1,
            suffix: suffix,
            hint: hint,
            help: m.$4,
            controller: _ctrls[k]!,
            onChanged: (_) => setState(() {}),
          );
        }),
      ],
    );
  }

  String _lbHintToKgHint(String lbHint) {
    // "e.g. 315" → lb 숫자를 대략 kg로 치환. 힌트라 반올림 허용.
    final match = RegExp(r'(\d+)').firstMatch(lbHint);
    if (match == null) return lbHint;
    final lb = int.parse(match.group(1)!);
    final kg = (lb * 0.4536).round();
    return lbHint.replaceFirst(RegExp(r'\d+'), '$kg');
  }

  @override
  void dispose() {
    _pc.dispose();
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }
}

class _ComputeLoadingDialog extends StatelessWidget {
  const _ComputeLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(FacingTokens.sp5),
          decoration: BoxDecoration(
            color: FacingTokens.surface,
            border: Border.all(color: FacingTokens.border),
            borderRadius: BorderRadius.circular(FacingTokens.r3),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: FacingTokens.accent,
                ),
              ),
              SizedBox(height: FacingTokens.sp3),
              Text('Calculating.', style: FacingTokens.body),
              SizedBox(height: FacingTokens.sp1),
              Text('Engine · 6 categories · Tier',
                  style: FacingTokens.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _Category {
  final String key;
  final String title;
  final String hint;
  final List<String> fields;
  const _Category({
    required this.key,
    required this.title,
    required this.hint,
    required this.fields,
  });
}

class _BenchmarkRow extends StatefulWidget {
  final String label;
  final String suffix;
  final String hint;
  final String help;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _BenchmarkRow({
    required this.label,
    required this.suffix,
    required this.hint,
    required this.help,
    required this.controller,
    required this.onChanged,
  });

  @override
  State<_BenchmarkRow> createState() => _BenchmarkRowState();
}

class _BenchmarkRowState extends State<_BenchmarkRow> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(widget.label,
                    style: FacingTokens.body
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(
                      horizontal: FacingTokens.sp2),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  widget.controller.clear();
                  widget.onChanged('');
                  setState(() {});
                },
                child: const Text('Unknown',
                    style: TextStyle(
                        fontSize: 12, color: FacingTokens.muted)),
              ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp1),
          Text(widget.help, style: FacingTokens.caption),
          const SizedBox(height: FacingTokens.sp2),
          TextField(
            controller: widget.controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                final dots = '.'.allMatches(newValue.text).length;
                if (dots > 1) return oldValue;
                return newValue;
              }),
            ],
            decoration: InputDecoration(
              hintText: widget.hint,
              suffixText: widget.suffix.isEmpty ? null : widget.suffix,
              isDense: true,
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: FacingTokens.border),
                borderRadius: BorderRadius.circular(FacingTokens.r2),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: FacingTokens.fg),
                borderRadius: BorderRadius.circular(FacingTokens.r2),
              ),
            ),
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }
}
