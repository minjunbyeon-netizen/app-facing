import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
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

  // v1.15 P0-1: 사용자 취소 플래그. _compute 중 취소 시 true.
  bool _cancelled = false;

  // v1.15 P1-5: kg↔lb 토글 감지용 이전 상태 (unit listener).
  bool? _lastIsKg;

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
        ('Back Squat 1RM', 'lb', '예: 315', '기초 근력'),
    'front_squat_1rm_lb':
        ('Front Squat 1RM', 'lb', '예: 255', 'Clean 받기 자세'),
    'bench_press_1rm_lb':
        ('Bench Press 1RM', 'lb', '예: 225', '상체 푸시'),
    'deadlift_1rm_lb':
        ('Deadlift 1RM', 'lb', '예: 405', '후방 사슬 힘'),
    'ohp_1rm_lb':
        ('OHP 1RM', 'lb', '예: 135', 'Strict 오버헤드'),
    // Olympic
    'clean_1rm_lb':
        ('Clean 1RM', 'lb', '예: 225', 'Full squat 받기'),
    'clean_and_jerk_1rm_lb':
        ('Clean & Jerk 1RM', 'lb', '예: 215', '전체 lift'),
    'snatch_1rm_lb':
        ('Snatch 1RM', 'lb', '예: 165', '한 동작 Full squat'),
    'power_clean_1rm_lb':
        ('Power Clean 1RM', 'lb', '예: 195', 'High catch'),
    'power_snatch_1rm_lb':
        ('Power Snatch 1RM', 'lb', '예: 145', 'High catch'),
    // Gymnastics
    'strict_pull_up_max_ub':
        ('Strict Pull-up Max', 'reps', '예: 12', 'Kipping 없는 순수 strict'),
    'chest_to_bar_max_ub':
        ('Chest-to-Bar Max', 'reps', '예: 18', '가슴 닿는 풀업'),
    'hspu_max_ub':
        ('HSPU Max', 'reps', '예: 10', '핸드스탠드 푸시업'),
    'bar_muscle_up_max_ub':
        ('Bar Muscle-up Max', 'reps', '예: 8', '바 머슬업'),
    'ring_muscle_up_max_ub':
        ('Ring Muscle-up Max', 'reps', '예: 5', '링 머슬업'),
    'toes_to_bar_max_ub':
        ('T2B Max', 'reps', '예: 25', '코어 지구력'),
    'push_up_per_min':
        ('Push-up 1-min Max', 'reps', '예: 45', '보조 밸런스 지표'),
    // Cardio
    'run_mile_sec':
        ('1-mile Run', 'sec', '예: 360 (6:00)', '달리기 벤치마크'),
    'row_500m_sec':
        ('500m Row', 'sec', '예: 95 (1:35)', '파워 카디오'),
    'row_2km_sec':
        ('2km Row', 'sec', '예: 440 (7:20)', '카디오 지구력'),
    'cooper_12min_meters':
        ('Cooper 12-min (m)', 'm', '예: 2800', '12분 달린 거리'),
    // Metcon
    'burpee_per_min':
        ('Burpee 1-min Max', 'reps', '예: 22', '전신 메콘'),
    'double_under_per_min':
        ('Double-under 1-min Max', 'reps', '예: 110', '코디네이션'),
    'assault_bike_per_min':
        ('Assault Bike 1-min', 'cal', '예: 22', '카디오 + 멘탈'),
    'wall_ball_per_min':
        ('Wall Ball 1-min Max', 'reps', '예: 22', '@20lb / 14lb'),
    'box_jump_per_min':
        ('Box Jump 1-min Max', 'reps', '예: 18', '@24" / 20"'),
  };

  static List<String> get _allFields =>
      _categories.expand((c) => c.fields).toList(growable: false);

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileState>();
    final unit = context.read<UnitState>();
    _lastIsKg = unit.isKg;
    _ctrls = {
      for (final k in _allFields)
        k: TextEditingController(
          text: _initText(p.getBenchmark(k), k, unit),
        ),
    };
    // v1.15 P1-5: kg↔lb 토글 시 이미 입력된 weight 값을 즉시 재변환.
    unit.addListener(_onUnitChanged);
  }

  void _onUnitChanged() {
    if (!mounted) return;
    final unit = context.read<UnitState>();
    if (_lastIsKg == unit.isKg) return;
    // 현재 표시값(이전 단위 기준) → 다른 단위로 변환.
    const double kgPerLb = 0.45359237;
    for (final k in _allFields) {
      if (!k.endsWith('_lb')) continue;
      final raw = _ctrls[k]!.text.trim();
      final v = double.tryParse(raw);
      if (v == null || v <= 0) continue;
      final converted = unit.isKg ? v * kgPerLb : v / kgPerLb;
      _ctrls[k]!.text = _fmt(converted);
    }
    _lastIsKg = unit.isKg;
    setState(() {});
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
    _cancelled = false;
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
      // v1.15 P1-9: 8s 타임아웃 래핑 (Dio receiveTimeout 외 clientside 보강).
      final result = await api
          .post('/api/v1/profile/grade', p.toGradePayload())
          .timeout(const Duration(seconds: 8));
      if (_cancelled) return; // 취소 시 후속 작업 중단
      p.setGradeResult(result);

      // fire-and-forget: Engine snapshot 저장. 실패해도 UX 진행.
      unawaited(_saveEngineSnapshot(api, result));

      await minShow;
      if (mounted && !_cancelled) {
        _hideLoadingOverlay();
        Haptic.heavy(); // Tier 확정 결과 진입 — 결과 공개 피드백
        Navigator.of(context).pushReplacementNamed('/onboarding/grade');
      }
    } catch (_) {
      await minShow;
      if (mounted && !_cancelled) {
        _hideLoadingOverlay();
        setState(() => _error = 'Calc failed. Retry.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// v1.15 P0-1: 로딩 취소. 다이얼로그 닫고 에러 상태로 전환.
  void _cancelCompute() {
    _cancelled = true;
    _hideLoadingOverlay();
    if (mounted) {
      setState(() {
        _submitting = false;
        _error = 'Cancelled.';
      });
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
      builder: (_) => _ComputeLoadingDialog(onCancel: _cancelCompute),
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
      appBar: AppBar(title: Text('Step $stepNumber / 6')),
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
                    color: FacingTokens.surface,
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
                        child: OutlinedButton.icon(
                          onPressed: _submitting
                              ? null
                              : () {
                                  Haptic.light();
                                  _prev();
                                },
                          icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                          label: const Text('Back'),
                        ),
                      ),
                    if (_page > 0) const SizedBox(width: FacingTokens.sp3),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _submitting
                            ? null
                            : () {
                                Haptic.light();
                                _next();
                              },
                        // v1.15 P1-7: 버튼 카피 영문 단독 일관. 'Calculating.' / 'Next' / 'Skip' 3 상태.
                        child: Text(
                          _submitting
                              ? 'Calculating.'
                              : (_isLastPage
                                  ? (_anyFilled ? 'Measure Engine' : 'Skip')
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
    // v1.15 P1-5: unit 리스너 제거.
    try {
      context.read<UnitState>().removeListener(_onUnitChanged);
    } catch (_) {/* context already dead */}
    _pc.dispose();
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }
}

class _ComputeLoadingDialog extends StatelessWidget {
  /// v1.15 P0-1: 취소 콜백. null이면 취소 버튼 숨김.
  final VoidCallback? onCancel;
  const _ComputeLoadingDialog({this.onCancel});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // v1.15 P0-1: 시스템 Back 허용 → 취소 경로 제공. pop 시 onCancel 호출.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onCancel?.call();
      },
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(FacingTokens.sp5),
          decoration: BoxDecoration(
            color: FacingTokens.surfaceOverlay,
            borderRadius: BorderRadius.circular(FacingTokens.r3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: FacingTokens.muted,
                ),
              ),
              const SizedBox(height: FacingTokens.sp3),
              const Text('Calculating.', style: FacingTokens.body),
              const SizedBox(height: FacingTokens.sp1),
              const Text('6 카테고리 Engine 측정 중.',
                  style: FacingTokens.caption),
              if (onCancel != null) ...[
                const SizedBox(height: FacingTokens.sp4),
                TextButton(
                  onPressed: () {
                    Haptic.light();
                    onCancel!();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: FacingTokens.muted,
                    minimumSize: const Size(FacingTokens.touchMin,
                        FacingTokens.touchMin),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
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
              // v1.15 P1-4: 48dp 터치 타겟 준수 (Masters·손 떨림 페르소나 대응).
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(
                      FacingTokens.touchMin, FacingTokens.touchMin),
                  padding: const EdgeInsets.symmetric(
                      horizontal: FacingTokens.sp3),
                ),
                onPressed: () {
                  Haptic.light();
                  widget.controller.clear();
                  widget.onChanged('');
                  setState(() {});
                },
                child: const Text('모름', style: FacingTokens.caption),
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
              // v1.15 P1-6: 스크린리더 접근성.
              labelText: widget.label,
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
