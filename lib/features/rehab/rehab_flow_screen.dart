// 재활 감별 플로우 (상태머신).
//
// 노드: 질문(q) → 선택지 next 따라 → 질문(q)/테스트(test)/원인(cause)/위험(danger).
//   - q:<id>     다음 질문
//   - test:<id>  자가 테스트 (통과/실패로 원인 분기)
//   - cause:<id> 원인 + 6단계 재활 루트 (종착)
//   - danger     즉시 중단 경고 (종착)
//
// 데이터는 rahap1 흡수본(assets/data/rehab). 지침: docs/ADDITIONAL_SOURCE_GUIDE.md
// 우리는 정보만 받아 우리 UI 로 재구현한다 — 계산·판정 로직은 데이터의 next 그래프를 그대로 탐색.

import 'package:flutter/material.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import 'rehab_models.dart';

class RehabFlowScreen extends StatefulWidget {
  final String movementId;
  final String painSiteId;

  const RehabFlowScreen({
    super.key,
    required this.movementId,
    required this.painSiteId,
  });

  @override
  State<RehabFlowScreen> createState() => _RehabFlowScreenState();
}

class _RehabFlowScreenState extends State<RehabFlowScreen> {
  final _repo = RehabRepository();
  late Future<RehabPainSiteDetail> _future;

  /// 노드 참조 스택 (마지막 = 현재).
  final List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<RehabPainSiteDetail> _load() async {
    final d = await _repo.loadPainSiteDetail(widget.movementId, widget.painSiteId);
    if (_history.isEmpty) _history.add(d.entryRef);
    return d;
  }

  String get _currentRef => _history.isEmpty ? '' : _history.last;

  void _go(String ref) {
    Haptic.light();
    setState(() => _history.add(ref));
  }

  void _restart(RehabPainSiteDetail d) {
    Haptic.light();
    setState(() {
      _history
        ..clear()
        ..add(d.entryRef);
    });
  }

  /// true = 화면 안에서 뒤로(이전 노드), false = 화면 자체를 닫아야 함.
  bool _stepBack() {
    if (_history.length <= 1) return false;
    setState(() => _history.removeLast());
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _history.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stepBack();
      },
      child: Scaffold(
        backgroundColor: FacingTokens.bg,
        appBar: AppBar(
          title: const Text('재활 감별'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (!_stepBack()) Navigator.of(context).pop();
            },
          ),
        ),
        body: SafeArea(
          child: FutureBuilder<RehabPainSiteDetail>(
            future: _future,
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: FacingTokens.muted, strokeWidth: 2),
                );
              }
              final d = snap.data;
              if (snap.hasError || d == null || !d.isReady) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(FacingTokens.sp5),
                    child: Text('이 부위 감별은 준비 중이에요.',
                        style: FacingTokens.caption),
                  ),
                );
              }
              return _NodeView(
                key: ValueKey(_currentRef),
                detail: d,
                ref: _currentRef,
                step: _history.length,
                onGo: _go,
                onRestart: () => _restart(d),
                onClose: () => Navigator.of(context).pop(),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 노드 디스패치
// ─────────────────────────────────────────────────────────────

class _NodeView extends StatelessWidget {
  final RehabPainSiteDetail detail;
  final String ref;
  final int step;
  final void Function(String ref) onGo;
  final VoidCallback onRestart;
  final VoidCallback onClose;

  const _NodeView({
    super.key,
    required this.detail,
    required this.ref,
    required this.step,
    required this.onGo,
    required this.onRestart,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final (kind, id) = _parse(ref);
    Widget child;
    switch (kind) {
      case 'q':
        final q = detail.questions[id];
        child = q == null
            ? _fallback()
            : _QuestionView(detail: detail, question: q, step: step, onGo: onGo);
        break;
      case 'test':
        final t = detail.tests[id];
        child = t == null
            ? _fallback()
            : _TestView(detail: detail, test: t, onGo: onGo);
        break;
      case 'cause':
        final c = detail.causes[id];
        child = c == null
            ? _fallback()
            : _CauseView(detail: detail, cause: c, onRestart: onRestart);
        break;
      case 'danger':
        child = _DangerView(
            detail: detail, onRestart: onRestart, onClose: onClose);
        break;
      default:
        child = _fallback();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          FacingTokens.sp4, FacingTokens.sp4, FacingTokens.sp4, FacingTokens.sp7),
      child: child,
    );
  }

  static (String, String) _parse(String ref) {
    final i = ref.indexOf(':');
    if (i < 0) return (ref, '');
    return (ref.substring(0, i), ref.substring(i + 1));
  }

  Widget _fallback() => const Padding(
        padding: EdgeInsets.symmetric(vertical: FacingTokens.sp6),
        child: Text('다음 단계 데이터를 찾지 못했어요.',
            style: FacingTokens.caption),
      );
}

/// 현재 동작·부위 컨텍스트 한 줄.
class _ContextLine extends StatelessWidget {
  final RehabPainSiteDetail detail;
  const _ContextLine({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Text('${detail.movementName} · ${detail.painSiteName}',
        style: FacingTokens.sectionLabel);
  }
}

// ─────────────────────────────────────────────────────────────
// 질문 노드
// ─────────────────────────────────────────────────────────────

class _QuestionView extends StatelessWidget {
  final RehabPainSiteDetail detail;
  final RehabQuestion question;
  final int step;
  final void Function(String ref) onGo;

  const _QuestionView({
    required this.detail,
    required this.question,
    required this.step,
    required this.onGo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ContextLine(detail: detail),
        const SizedBox(height: FacingTokens.sp4),
        Text(question.text, style: FacingTokens.h3),
        if (question.sub != null && question.sub!.isNotEmpty) ...[
          const SizedBox(height: FacingTokens.sp2),
          Text(question.sub!, style: FacingTokens.caption),
        ],
        const SizedBox(height: FacingTokens.sp5),
        for (final c in question.choices)
          _ChoiceButton(label: c.text, onTap: () => onGo(c.next)),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ChoiceButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FacingTokens.sp3),
      child: Material(
        color: FacingTokens.surface,
        borderRadius: BorderRadius.circular(FacingTokens.r2),
        child: InkWell(
          borderRadius: BorderRadius.circular(FacingTokens.r2),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: FacingTokens.border),
              borderRadius: BorderRadius.circular(FacingTokens.r2),
            ),
            padding: const EdgeInsets.all(FacingTokens.sp4),
            child: Row(
              children: [
                Expanded(child: Text(label, style: FacingTokens.body)),
                const SizedBox(width: FacingTokens.sp2),
                const Icon(Icons.chevron_right,
                    size: 20, color: FacingTokens.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 테스트 노드
// ─────────────────────────────────────────────────────────────

class _TestView extends StatelessWidget {
  final RehabPainSiteDetail detail;
  final RehabTest test;
  final void Function(String ref) onGo;

  const _TestView({
    required this.detail,
    required this.test,
    required this.onGo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ContextLine(detail: detail),
        const SizedBox(height: FacingTokens.sp4),
        Text('자가 테스트', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        Text(test.name, style: FacingTokens.h3),
        if (test.purpose.isNotEmpty) ...[
          const SizedBox(height: FacingTokens.sp3),
          Text(test.purpose, style: FacingTokens.body),
        ],
        const SizedBox(height: FacingTokens.sp4),
        _NumberedSteps(steps: test.steps),
        if (test.note != null && test.note!.isNotEmpty) ...[
          const SizedBox(height: FacingTokens.sp4),
          _NoteBox(text: test.note!),
        ],
        const SizedBox(height: FacingTokens.sp5),
        Text('결과를 선택하세요', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp3),
        _OutcomeButton(
          label: test.passText,
          color: FacingTokens.success,
          onTap: () => onGo(test.passNext),
        ),
        const SizedBox(height: FacingTokens.sp3),
        _OutcomeButton(
          label: test.failText,
          color: FacingTokens.warning,
          onTap: () => onGo(test.failNext),
        ),
      ],
    );
  }
}

class _OutcomeButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OutcomeButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FacingTokens.surface,
      borderRadius: BorderRadius.circular(FacingTokens.r2),
      child: InkWell(
        borderRadius: BorderRadius.circular(FacingTokens.r2),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(FacingTokens.r2),
          ),
          padding: const EdgeInsets.all(FacingTokens.sp4),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: FacingTokens.sp3),
              Expanded(child: Text(label, style: FacingTokens.body)),
              const Icon(Icons.chevron_right,
                  size: 20, color: FacingTokens.muted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 위험 노드
// ─────────────────────────────────────────────────────────────

class _DangerView extends StatelessWidget {
  final RehabPainSiteDetail detail;
  final VoidCallback onRestart;
  final VoidCallback onClose;

  const _DangerView({
    required this.detail,
    required this.onRestart,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final d = detail.danger;
    final title = d?.title ?? '지금 바로 트레이닝을 멈추세요';
    final reason = d?.reason ?? '';
    final action = d?.action ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(FacingTokens.sp4),
          decoration: BoxDecoration(
            color: FacingTokens.danger.withValues(alpha: 0.12),
            border: Border.all(color: FacingTokens.danger.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(FacingTokens.r2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 22, color: FacingTokens.danger),
                  const SizedBox(width: FacingTokens.sp2),
                  Expanded(
                    child: Text(title,
                        style: FacingTokens.h3
                            .copyWith(color: FacingTokens.danger)),
                  ),
                ],
              ),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: FacingTokens.sp3),
                Text(reason, style: FacingTokens.body),
              ],
            ],
          ),
        ),
        if (action.isNotEmpty) ...[
          const SizedBox(height: FacingTokens.sp4),
          Text('권장 조치', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          Container(
            padding: const EdgeInsets.all(FacingTokens.sp4),
            decoration: BoxDecoration(
              color: FacingTokens.surface,
              border: Border.all(color: FacingTokens.border),
              borderRadius: BorderRadius.circular(FacingTokens.r2),
            ),
            child: Text(action, style: FacingTokens.body),
          ),
        ],
        const SizedBox(height: FacingTokens.sp6),
        OutlinedButton(
          onPressed: onRestart,
          child: const Text('처음부터 다시'),
        ),
        const SizedBox(height: FacingTokens.sp2),
        TextButton(
          onPressed: onClose,
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 원인 + 6단계 루트 노드 (종착)
// ─────────────────────────────────────────────────────────────

class _CauseView extends StatelessWidget {
  final RehabPainSiteDetail detail;
  final RehabCause cause;
  final VoidCallback onRestart;

  const _CauseView({
    required this.detail,
    required this.cause,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ContextLine(detail: detail),
        const SizedBox(height: FacingTokens.sp4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: FacingTokens.sp2, vertical: 3),
              decoration: BoxDecoration(
                color: FacingTokens.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(FacingTokens.r1),
              ),
              child: Text(
                cause.label.isEmpty ? '원인' : cause.label,
                style: FacingTokens.micro.copyWith(
                    color: FacingTokens.primary, fontWeight: FontWeight.w700),
              ),
            ),
            if (cause.tag.isNotEmpty) ...[
              const SizedBox(width: FacingTokens.sp2),
              Flexible(
                child: Text(cause.tag,
                    style: FacingTokens.micro, overflow: TextOverflow.ellipsis),
              ),
            ],
          ],
        ),
        const SizedBox(height: FacingTokens.sp3),
        Text(cause.name, style: FacingTokens.h3),
        if (cause.description.isNotEmpty) ...[
          const SizedBox(height: FacingTokens.sp3),
          Text(cause.description, style: FacingTokens.body),
        ],
        if (cause.priorityNote != null && cause.priorityNote!.isNotEmpty) ...[
          const SizedBox(height: FacingTokens.sp4),
          Container(
            padding: const EdgeInsets.all(FacingTokens.sp3),
            decoration: BoxDecoration(
              color: FacingTokens.info.withValues(alpha: 0.1),
              border: Border.all(color: FacingTokens.info.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(FacingTokens.r2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.priority_high_rounded,
                    size: 18, color: FacingTokens.info),
                const SizedBox(width: FacingTokens.sp2),
                Expanded(
                  child: Text(cause.priorityNote!, style: FacingTokens.caption),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: FacingTokens.sp5),
        Text('재활 루트', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp3),
        for (var i = 0; i < cause.stages.length; i++)
          _StageCard(index: i + 1, stage: cause.stages[i]),
        const SizedBox(height: FacingTokens.sp5),
        OutlinedButton(
          onPressed: onRestart,
          child: const Text('처음부터 다시'),
        ),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  final int index;
  final RehabStage stage;

  const _StageCard({required this.index, required this.stage});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: FacingTokens.sp3),
      padding: const EdgeInsets.all(FacingTokens.sp4),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: Border.all(color: FacingTokens.border),
        borderRadius: BorderRadius.circular(FacingTokens.r2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FacingTokens.surfaceMax,
                  borderRadius: BorderRadius.circular(FacingTokens.r1),
                ),
                child: Text('$index',
                    style: FacingTokens.micro
                        .copyWith(color: FacingTokens.fg)),
              ),
              const SizedBox(width: FacingTokens.sp3),
              Expanded(child: Text(stage.name, style: FacingTokens.h3)),
              if (stage.duration != null && stage.duration!.isNotEmpty)
                Text(stage.duration!, style: FacingTokens.micro),
            ],
          ),
          const SizedBox(height: FacingTokens.sp3),
          ..._body(),
        ],
      ),
    );
  }

  List<Widget> _body() {
    switch (stage.kind) {
      case RehabStageKind.exercise:
        return [
          for (final e in stage.exercises) _ExerciseTile(exercise: e),
        ];
      case RehabStageKind.reassessment:
        return [
          for (final item in stage.checklist)
            Padding(
              padding: const EdgeInsets.only(bottom: FacingTokens.sp2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 18, color: FacingTokens.success),
                  const SizedBox(width: FacingTokens.sp2),
                  Expanded(child: Text(item, style: FacingTokens.body)),
                ],
              ),
            ),
          if (stage.passNote != null && stage.passNote!.isNotEmpty) ...[
            const SizedBox(height: FacingTokens.sp2),
            Text(stage.passNote!,
                style: FacingTokens.caption
                    .copyWith(color: FacingTokens.success)),
          ],
          if (stage.failNote != null && stage.failNote!.isNotEmpty) ...[
            const SizedBox(height: FacingTokens.sp1),
            Text(stage.failNote!,
                style: FacingTokens.caption
                    .copyWith(color: FacingTokens.warning)),
          ],
        ];
      case RehabStageKind.tips:
        return [
          for (final t in stage.tips)
            Padding(
              padding: const EdgeInsets.only(bottom: FacingTokens.sp3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title,
                      style: FacingTokens.body
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(t.body, style: FacingTokens.caption),
                ],
              ),
            ),
        ];
    }
  }
}

/// 운동 1개 — 탭하면 why·cue·how 펼침.
class _ExerciseTile extends StatefulWidget {
  final RehabExercise exercise;
  const _ExerciseTile({required this.exercise});

  @override
  State<_ExerciseTile> createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<_ExerciseTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    return Container(
      margin: const EdgeInsets.only(bottom: FacingTokens.sp2),
      decoration: BoxDecoration(
        color: FacingTokens.surfaceHigh,
        borderRadius: BorderRadius.circular(FacingTokens.r2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(FacingTokens.r2),
            onTap: () {
              Haptic.light();
              setState(() => _open = !_open);
            },
            child: Padding(
              padding: const EdgeInsets.all(FacingTokens.sp3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name,
                            style: FacingTokens.body
                                .copyWith(fontWeight: FontWeight.w700)),
                        if (e.sets.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(e.sets, style: FacingTokens.micro),
                        ],
                      ],
                    ),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      size: 20, color: FacingTokens.muted),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(FacingTokens.sp3, 0,
                  FacingTokens.sp3, FacingTokens.sp3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (e.why.isNotEmpty) _Labeled(label: '왜', body: e.why),
                  if (e.cue.isNotEmpty) _Labeled(label: '큐', body: e.cue),
                  if (e.how.isNotEmpty) ...[
                    const SizedBox(height: FacingTokens.sp2),
                    Text('방법', style: FacingTokens.sectionLabel),
                    const SizedBox(height: FacingTokens.sp2),
                    _NumberedSteps(steps: e.how),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final String body;
  const _Labeled({required this.label, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FacingTokens.sp2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(label, style: FacingTokens.sectionLabel),
          ),
          const SizedBox(width: FacingTokens.sp2),
          Expanded(child: Text(body, style: FacingTokens.caption)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 공용
// ─────────────────────────────────────────────────────────────

class _NumberedSteps extends StatelessWidget {
  final List<String> steps;
  const _NumberedSteps({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: FacingTokens.sp2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}',
                    style: FacingTokens.micro
                        .copyWith(color: FacingTokens.muted)),
                const SizedBox(width: FacingTokens.sp3),
                Expanded(child: Text(steps[i], style: FacingTokens.caption)),
              ],
            ),
          ),
      ],
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String text;
  const _NoteBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FacingTokens.sp3),
      decoration: BoxDecoration(
        color: FacingTokens.surfaceHigh,
        borderRadius: BorderRadius.circular(FacingTokens.r2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: FacingTokens.muted),
          const SizedBox(width: FacingTokens.sp2),
          Expanded(child: Text(text, style: FacingTokens.caption)),
        ],
      ),
    );
  }
}
