// v1.16 Sprint 13: 목표 관리 화면 — 주간/월간 세션 타겟, PR 목표, 시즌 목표.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/goals_state.dart';
import '../../core/theme.dart';
import '../history/history_models.dart';
import '../history/history_repository.dart';
import '../../core/app_clock.dart';
import '../../widgets/hkit.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  Future<List<WodHistoryItem>>? _history;
  // dispose 시점엔 context 로 provider 를 못 읽는다 — 미리 잡아 둔다.
  GoalsState? _goals;

  @override
  void initState() {
    super.initState();
    final repo = HistoryRepository(context.read<ApiClient>());
    _history = repo.listWodHistory(limit: 200);
    // v3.11 (2026-08-23): 화면에 들어올 때마다 서버 값을 다시 읽는다.
    // 앱 부팅의 load() 한 번만으로는 부족하다 — 그 시점엔 아직 로그인 전이라
    // 기기 식별값이 로그인 뒤와 달라, 갓 설치한 폰에서 남의(=익명) 목표를
    // 읽고 끝났다. 실기에서 재설치 후 로그인하니 서버에 있는 값 대신
    // 기본값(주4·월16)이 떠서 발견 (2026-08-23 에뮬레이터 검증).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GoalsState>().pull();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _goals = context.read<GoalsState>();
  }

  @override
  void dispose() {
    // v3.11 (2026-08-23): 화면을 떠날 때 서버에 통째로 올린다.
    // 슬라이더는 놓는 순간(onChangeEnd)에도 올리지만, 시즌 목표는 글자마다
    // 보낼 수 없어 여기서 마무리한다. 실패는 GoalsState 가 삼키고 로컬
    // 캐시에 남겨 다음 진입의 pull·sync 에서 만회한다.
    _goals?.sync();
    super.dispose();
  }

  int _sessionsThisWeek(List<WodHistoryItem> list) {
    // v1.19 차수 5 (B-LW-12): attendance(일요일 시작)와 통일.
    // DateTime.weekday: 1=Mon..7=Sun. weekday%7: Sun→0 → 이번주 시작.
    final now = appClock.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final weekStartDate =
        DateTime(weekStart.year, weekStart.month, weekStart.day);
    return list
        .where((w) => w.createdAt.toLocal().isAfter(weekStartDate))
        .length;
  }

  int _sessionsThisMonth(List<WodHistoryItem> list) {
    final now = appClock.now();
    return list.where((w) {
      final d = w.createdAt.toLocal();
      return d.year == now.year && d.month == now.month;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalsState>();
    return Scaffold(
      appBar: AppBar(title: const Text('목표')),
      body: SafeArea(
        child: FutureBuilder<List<WodHistoryItem>>(
          future: _history,
          builder: (ctx, snap) {
            final list = snap.data ?? const <WodHistoryItem>[];
            final weekCount = _sessionsThisWeek(list);
            final monthCount = _sessionsThisMonth(list);
            return ListView(
              padding: const EdgeInsets.all(HyphenTokens.sp4),
              children: [
                // Weekly
                const Text('이번 주', style: HyphenTokens.sectionLabel),
                const SizedBox(height: HyphenTokens.sp2),
                _ProgressRow(
                  label: '세션',
                  current: weekCount,
                  target: goals.weeklyTargetSessions,
                  unit: '회',
                ),
                const SizedBox(height: HyphenTokens.sp3),
                _TargetSlider(
                  label: '주간 타겟 · ${goals.weeklyTargetSessions}회',
                  value: goals.weeklyTargetSessions.toDouble(),
                  min: 1,
                  max: 10,
                  onChanged: (v) => goals.setWeeklyTarget(v.round()),
                  onChangeEnd: (_) => goals.sync(),
                ),
                const SizedBox(height: HyphenTokens.sp5),

                // Monthly
                const Text('이번 달', style: HyphenTokens.sectionLabel),
                const SizedBox(height: HyphenTokens.sp2),
                _ProgressRow(
                  label: '세션',
                  current: monthCount,
                  target: goals.monthlyTargetSessions,
                  unit: '회',
                ),
                const SizedBox(height: HyphenTokens.sp3),
                _TargetSlider(
                  label: '월간 타겟 · ${goals.monthlyTargetSessions}회',
                  value: goals.monthlyTargetSessions.toDouble(),
                  min: 4,
                  max: 30,
                  onChanged: (v) => goals.setMonthlyTarget(v.round()),
                  onChangeEnd: (_) => goals.sync(),
                ),
                const SizedBox(height: HyphenTokens.sp5),

                // PR Goals
                const Text('PR 목표', style: HyphenTokens.sectionLabel),
                const SizedBox(height: HyphenTokens.sp2),
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
                const SizedBox(height: HyphenTokens.sp5),

                // v3.2 (2026-08-20): '목표 Tier' 섹션 삭제 — Tier 사다리는 앱에서
                // 소멸했고(D34·D36), 회원 레벨(SCALED·RXD·ELITE)은 경력으로만
                // 정해져 목표로 고를 수도 없다. RX+·Games 는 회원 레벨에 없는 값
                // (GLOSSARY §3). GoalsState.targetTier 도 같은 날 삭제
                // (README §제거된 기능 대장).

                // Season goal
                const Text('시즌 목표', style: HyphenTokens.sectionLabel),
                const SizedBox(height: HyphenTokens.sp2),
                _SeasonGoalField(
                  initial: goals.seasonGoal,
                  onSave: (v) => goals.setSeasonGoal(v),
                ),
                const SizedBox(height: HyphenTokens.sp4),
                // v3.11 (2026-08-23): 구 문구 '목표·진행률은 이 기기에
                // 저장됩니다' 는 두 군데가 틀렸다 — 진행률은 서버 히스토리에서
                // 세는 값이고, 목표도 이제 서버에 저장된다(member_goals).
                // 서버 저장이 실패한 동안만 '이 기기에만' 이라고 알린다.
                Text(
                  goals.isServerDown
                      ? '지금은 이 기기에만 저장됩니다. 연결되면 자동으로 올라갑니다.'
                      : '목표는 계정에 저장되어 폰을 바꿔도 따라옵니다.',
                  style: HyphenTokens.caption,
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
    HkDialog.custom<void>(
      context,
      title: 'Fran PR 목표',
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '2:00 (분:초)',
          labelText: 'Target Time',
        ),
        keyboardType: TextInputType.datetime,
      ),
      actions: (ctx) => [
        HkButton.tertiary('취소',
            neutral: true, onPressed: () => Navigator.pop(ctx)),
        HkButton.tertiary('저장', onPressed: () {
          final m = RegExp(r'^(\d+):(\d{1,2})$').firstMatch(ctrl.text);
          if (m != null) {
            final sec =
                int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
            goals.setFranPrSec(sec).then((_) => goals.sync());
          }
          Navigator.pop(ctx);
        }),
      ],
    ).whenComplete(ctrl.dispose);
  }

  void _editBackSquat(BuildContext context, GoalsState goals) {
    final ctrl = TextEditingController(
        text: goals.backSquatKg == 0 ? '' : '${goals.backSquatKg.toInt()}');
    HkDialog.custom<void>(
      context,
      title: 'Back Squat Target (kg)',
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(hintText: '140'),
      ),
      actions: (ctx) => [
        HkButton.tertiary('취소',
            neutral: true, onPressed: () => Navigator.pop(ctx)),
        HkButton.tertiary('저장', onPressed: () {
          final v = double.tryParse(ctrl.text);
          if (v != null) goals.setBackSquatKg(v).then((_) => goals.sync());
          Navigator.pop(ctx);
        }),
      ],
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
            Expanded(child: Text(label, style: HyphenTokens.body)),
            Text(
              done ? 'ACHIEVED' : '$current / $target $unit',
              style: HyphenTokens.micro.copyWith(
                color: done ? HyphenTokens.accent : HyphenTokens.muted,
                fontWeight: FontWeight.w800,
                fontFeatures: HyphenTokens.tabular,
              ),
            ),
          ],
        ),
        const SizedBox(height: HyphenTokens.sp1),
        ClipRRect(
          borderRadius: BorderRadius.circular(HyphenTokens.r1),
          child: Stack(
            children: [
              Container(height: 6, color: HyphenTokens.border),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  height: 6,
                  color: done
                      ? HyphenTokens.accent
                      : HyphenTokens.accent.withValues(alpha: 0.55),
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
  /// 드래그를 놓는 순간 1회. 서버 저장은 여기서만 한다 — onChanged 는
  /// 드래그 내내 수십 번 불려 그대로 보내면 요청 폭주다.
  final void Function(double)? onChangeEnd;
  const _TargetSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: HyphenTokens.caption),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: HyphenTokens.accent,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
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
        padding: const EdgeInsets.symmetric(vertical: HyphenTokens.sp3),
        child: Row(
          children: [
            Expanded(child: Text(label, style: HyphenTokens.body)),
            Text(valueLabel,
                style: HyphenTokens.body.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: HyphenTokens.tabular,
                )),
            const SizedBox(width: HyphenTokens.sp2),
            const Icon(Icons.chevron_right,
                color: HyphenTokens.muted, size: 18),
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
