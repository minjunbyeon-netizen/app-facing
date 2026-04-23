import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/unit_state.dart';
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
      title: '파워 (Powerlifting + OHP)',
      hint: 'SBD + OHP 1RM',
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
      title: '역도 (Olympic Lifting)',
      hint: '클린/스내치 5종',
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
      title: '짐내스틱',
      hint: 'Max Unbroken / 1분 max',
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
      title: '카디오',
      hint: '런 + 로잉 + Cooper',
      fields: [
        'run_mile_sec',
        'row_500m_sec',
        'row_2km_sec',
        'cooper_12min_meters',
      ],
    ),
    _Category(
      key: 'metcon',
      title: '메타콘 (멘탈)',
      hint: '1분 max',
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
    // 파워
    'back_squat_1rm_lb':
        ('백스쿼트 1RM', 'lb', '예: 315', '전 근력 기초'),
    'front_squat_1rm_lb':
        ('프론트스쿼트 1RM', 'lb', '예: 255', '클린 받기 자세'),
    'bench_press_1rm_lb':
        ('벤치프레스 1RM', 'lb', '예: 225', '상체 푸시'),
    'deadlift_1rm_lb':
        ('데드리프트 1RM', 'lb', '예: 405', '포스 능력'),
    'ohp_1rm_lb':
        ('OHP 1RM', 'lb', '예: 135', '오버헤드 프레스 (strict)'),
    // 역도
    'clean_1rm_lb':
        ('클린 1RM', 'lb', '예: 225', 'Squat 받기'),
    'clean_and_jerk_1rm_lb':
        ('클린 앤 저크 1RM', 'lb', '예: 215', '전체 lift'),
    'snatch_1rm_lb':
        ('스내치 1RM', 'lb', '예: 165', 'Squat 받기 (한 번)'),
    'power_clean_1rm_lb':
        ('파워 클린 1RM', 'lb', '예: 195', 'High catch'),
    'power_snatch_1rm_lb':
        ('파워 스내치 1RM', 'lb', '예: 145', 'High catch'),
    // 짐내스틱
    'strict_pull_up_max_ub':
        ('Strict 풀업 Max', '회', '예: 12', 'kipping X 순수 strict'),
    'chest_to_bar_max_ub':
        ('체투바 (CTB) Max', '회', '예: 18', '가슴 닿는 풀업'),
    'hspu_max_ub':
        ('HSPU Max', '회', '예: 10', '핸드스탠드 푸쉬업'),
    'bar_muscle_up_max_ub':
        ('바 머슬업 Max', '회', '예: 8', '바 머슬업'),
    'ring_muscle_up_max_ub':
        ('링 머슬업 Max', '회', '예: 5', '링 머슬업'),
    'toes_to_bar_max_ub':
        ('T2B Max', '회', '예: 25', '코어 지구력'),
    'push_up_per_min':
        ('푸시업 1분 Max', '회', '예: 45', '신체 밸런스 (보조)'),
    // 카디오
    'run_mile_sec':
        ('1마일 런 (초)', '초', '예: 360 (6:00)', '달리기 핵심'),
    'row_500m_sec':
        ('500m 로잉 (초)', '초', '예: 95 (1:35)', '파워 카디오'),
    'row_2km_sec':
        ('2km 로잉 (초)', '초', '예: 440 (7:20)', '카디오 지구력'),
    'cooper_12min_meters':
        ('Cooper 12분 거리 (m)', 'm', '예: 2800', '12분 동안 달린 거리'),
    // 메타콘
    'burpee_per_min':
        ('버피 1분 Max', '회', '예: 22', '전신 메콘'),
    'double_under_per_min':
        ('더블언더 1분 Max', '회', '예: 110', '코디네이션'),
    'assault_bike_per_min':
        ('어썰트바이크 1분 cal', 'cal', '예: 22', '카디오 + 멘탈'),
    'wall_ball_per_min':
        ('월볼 1분 Max', '회', '예: 22', '@20lb / 14lb'),
    'box_jump_per_min':
        ('박스점프 1분 Max', '회', '예: 18', '@24" / 20"'),
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
      await minShow;
      if (mounted) {
        _hideLoadingOverlay();
        Navigator.of(context).pushReplacementNamed('/onboarding/grade');
      }
    } catch (_) {
      await minShow;
      if (mounted) {
        _hideLoadingOverlay();
        setState(() =>
            _error = '등급 계산에 실패했습니다. 잠시 후 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
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
      appBar: AppBar(title: Text('$stepNumber / 6 · ${_categories[_page].title}')),
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
                        '$stepNumber / 6 단계',
                        style: FacingTokens.caption,
                      ),
                      Text('$pct% 완료', style: FacingTokens.caption),
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
                          child: const Text('← 이전'),
                        ),
                      ),
                    if (_page > 0) const SizedBox(width: FacingTokens.sp3),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _next,
                        child: Text(
                          _submitting
                              ? '계산 중...'
                              : (_isLastPage
                                  ? (_anyFilled ? '등급 확인하기' : '건너뛰고 결과 보기')
                                  : '다음 →'),
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
          '아는 만큼만 입력하세요. 빈 칸은 자동 추론됩니다.',
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
    // "예: 315" → lb 숫자를 대략 kg로 치환. 힌트라 반올림 허용.
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
            color: FacingTokens.bg,
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
              Text('능력치 분석 중...', style: FacingTokens.body),
              SizedBox(height: FacingTokens.sp1),
              Text('6개 카테고리 점수 계산 중',
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
                child: const Text('모름',
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
