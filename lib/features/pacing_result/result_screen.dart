import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/formula_references.dart';
import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../models/pacing_plan.dart';
import '../history/history_repository.dart';
import '../profile/profile_state.dart';
import '../wod_builder/wod_draft_state.dart';

/// v1.16: Preset/Custom WOD 계산 결과 + 전략 화면.
/// 로딩은 최소 1.8초 강제 대기 + 카피 3종 순환. 결과 공개 시 heavy haptic.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Future<PacingPlan> _future;
  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();
    _future = _calculate();
  }

  Future<PacingPlan> _calculate() async {
    final api = context.read<ApiClient>();
    final draft = context.read<WodDraftState>();
    final profile = context.read<ProfileState>();
    final wodJson = draft.toApiJson();
    final body = {
      'wod': wodJson,
      'profile_overrides': profile.toOverrides(),
      if (profile.overallGrade != null) 'grade': profile.overallGrade,
    };
    // 최소 1.8초 대기 — 프로필 맞춤 계산 체감 확보.
    final apiFuture = api
        .post('/api/v1/pacing/calculate', body)
        .timeout(const Duration(seconds: 8));
    final minDelay = Future.delayed(const Duration(milliseconds: 1800));
    final results = await Future.wait([apiFuture, minDelay]);
    final data = results[0] as Map<String, dynamic>;
    unawaited(_saveHistory(api, wodJson, data, profile.overallGrade));
    return PacingPlan.fromJson(data);
  }

  Future<void> _saveHistory(
      ApiClient api,
      Map<String, dynamic> wodJson,
      Map<String, dynamic> planData,
      String? grade) async {
    try {
      final repo = HistoryRepository(api);
      await repo.saveWodHistory({
        'wod': wodJson,
        'plan': {
          'formula_version': planData['formula_version'],
          'estimated_total_sec': planData['estimated_total_sec'],
          'grade': grade,
          'segments': planData['segments'],
        },
      });
    } catch (_) {
      // 저장 실패 무시.
    }
  }

  void _fireResultHaptic() {
    if (_hapticFired) return;
    _hapticFired = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => Haptic.heavy());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PACING STRATEGY'),
        actions: [
          // v1.16 Sprint 8 U2: 결과 공유 placeholder.
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share, size: 20),
            onPressed: () {
              Haptic.light();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('결과 카드 공유는 Phase 2에서 지원 예정.'),
                  duration: Duration(seconds: 2),
                ),
              );
              // TODO(go): Phase 2 — RepaintBoundary로 카드 캡처 + Share API 연결.
            },
          ),
        ],
      ),
      body: FutureBuilder<PacingPlan>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return _LoadingView(onCancel: () => Navigator.of(context).pop());
          }
          if (snap.hasError) {
            final e = snap.error;
            final msg = e is AppException
                ? e.messageKo
                : 'Calc failed. Retry.';
            return _ErrorView(
              message: msg,
              onRetry: () {
                if (!mounted) return;
                setState(() {
                  _hapticFired = false;
                  _future = _calculate();
                });
              },
            );
          }
          final plan = snap.data!;
          _fireResultHaptic();
          return _ResultBody(plan: plan);
        },
      ),
    );
  }
}

class _LoadingView extends StatefulWidget {
  final VoidCallback onCancel;
  const _LoadingView({required this.onCancel});

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView> {
  static const List<String> _captions = [
    'Calculating.',
    'Profiling Engine.',
    'Pulling Split.',
  ];
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _captions.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FacingTokens.sp5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: FacingTokens.muted,
              ),
            ),
            const SizedBox(height: FacingTokens.sp4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _captions[_index],
                key: ValueKey(_index),
                style: FacingTokens.h3,
              ),
            ),
            const SizedBox(height: FacingTokens.sp2),
            const Text(
              '프로필 기반 Split · Burst 계산 중.',
              style: FacingTokens.caption,
            ),
            const SizedBox(height: FacingTokens.sp6),
            TextButton(
              onPressed: widget.onCancel,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(FacingTokens.sp4),
            decoration: BoxDecoration(
              color: FacingTokens.surface,
              borderRadius: BorderRadius.circular(FacingTokens.r2),
            ),
            child: Text(message, style: FacingTokens.body),
          ),
          const SizedBox(height: FacingTokens.sp3),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  final PacingPlan plan;
  const _ResultBody({required this.plan});

  @override
  Widget build(BuildContext context) {
    final draft = context.read<WodDraftState>();
    final profile = context.read<ProfileState>();
    final wodLabel = draft.presetNameKo?.toUpperCase() ?? 'CUSTOM';
    final contextParts = <String>[
      wodLabel,
      draft.type.labelKo.toUpperCase(),
      if (profile.overallGrade != null) profile.overallGrade!.toUpperCase(),
    ];
    final strategyLines = plan.strategyLines();
    final burstPoints = plan.burstPointSummaries();
    final maxRest = plan.segments
        .map((s) => s.restBetweenSec)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      children: [
        // 1. WOD 헤더 + 총 시간 (Hero)
        Text(contextParts.join(' · '), style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(plan.estimatedTotalDisplay,
                style: FacingTokens.displayCompact),
            const SizedBox(width: FacingTokens.sp2),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('예상', style: FacingTokens.caption),
            ),
          ],
        ),
        const SizedBox(height: FacingTokens.sp1),
        const Text('예상 완주 시간. 레스트 포함.',
            style: FacingTokens.caption),
        const SizedBox(height: FacingTokens.sp4),

        // 2. PACE STRATEGY
        const Text('PACE STRATEGY', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        ...strategyLines.map((line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
              child: Text(line, style: FacingTokens.lead),
            )),
        const SizedBox(height: FacingTokens.sp4),

        // 3. SPLIT SEQUENCE
        const Text('SPLIT SEQUENCE', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp3),
        ...plan.segments.map((s) => _SegmentCard(segment: s)),
        const SizedBox(height: FacingTokens.sp3),

        // 4. BURST POINTS
        if (burstPoints.isNotEmpty) ...[
          const Text('BURST POINTS', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          ...burstPoints.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('·  ',
                        style: TextStyle(color: FacingTokens.accent)),
                    Expanded(
                        child: Text(p, style: FacingTokens.body)),
                  ],
                ),
              )),
          const SizedBox(height: FacingTokens.sp4),
        ],

        // 5. REST STRATEGY
        const Text('REST STRATEGY', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        Text(
          maxRest == 0
              ? '중간 레스트 없음. 전 세트 Unbroken.'
              : '세트 간 최대 $maxRest초. W-prime 회복 기준.',
          style: FacingTokens.caption,
        ),
        const SizedBox(height: FacingTokens.sp4),

        // 6. RATIONALE (collapsed) — v1.16 Sprint 7a: 수식·논문 확장.
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('RATIONALE', style: FacingTokens.sectionLabel),
            iconColor: FacingTokens.muted,
            collapsedIconColor: FacingTokens.muted,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: FacingTokens.sp4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 세그먼트별 근거.
                    Text(
                      plan.segments
                          .map((s) => '• ${s.rationaleKo}')
                          .where((t) => t.trim() != '•')
                          .join('\n'),
                      style: FacingTokens.caption,
                    ),
                    const SizedBox(height: FacingTokens.sp4),
                    // 핵심 공식 요약.
                    Text('PACING FORMULA',
                        style: FacingTokens.micro.copyWith(
                          color: FacingTokens.muted,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        )),
                    const SizedBox(height: FacingTokens.sp2),
                    Text(
                      'Split = max_ub × first_ratio × (descending_step)^n\n'
                      'Burst: T ≥ T_boundary (등급별 0.75~0.95)\n'
                      'Rest = base × phase × category × load × wod_type',
                      style: FacingTokens.caption.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: FacingTokens.sp4),
                    // 근거 논문·표준.
                    Text('REFERENCES',
                        style: FacingTokens.micro.copyWith(
                          color: FacingTokens.muted,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        )),
                    const SizedBox(height: FacingTokens.sp2),
                    ...kFormulaReferences.map((r) => Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: FacingTokens.sp1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${r.title} — ${r.authors}',
                                style: FacingTokens.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(r.relevance,
                                  style: FacingTokens.micro.copyWith(
                                    color: FacingTokens.muted,
                                  )),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FacingTokens.sp6),
        Text(
          'formula v${plan.formulaVersion}',
          style: FacingTokens.micro,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// v1.16: 박스 제거 — 좌측 1px 라인만. BURST는 accent 색.
class _SegmentCard extends StatelessWidget {
  final PacingSegment segment;
  const _SegmentCard({required this.segment});

  @override
  Widget build(BuildContext context) {
    final accent = segment.isExplosion;
    return Container(
      margin: const EdgeInsets.only(bottom: FacingTokens.sp4),
      padding: const EdgeInsets.only(
        left: FacingTokens.sp3,
      ),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: accent ? FacingTokens.accent : FacingTokens.border,
            width: accent ? 2 : 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(_prettifySlug(segment.movementSlug),
                    style: FacingTokens.h3),
              ),
              if (accent) ...[
                Text('BURST',
                    style: FacingTokens.micro.copyWith(
                      color: FacingTokens.accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    )),
                const SizedBox(width: FacingTokens.sp2),
              ],
              Text(segment.estimatedDisplay,
                  style: FacingTokens.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: FacingTokens.tabular,
                  )),
            ],
          ),
          if (segment.splitPattern.isNotEmpty) ...[
            const SizedBox(height: FacingTokens.sp2),
            _SplitText(
              splits: segment.splitPattern,
              lastIsExplosion: segment.isExplosion,
            ),
            const SizedBox(height: FacingTokens.sp1),
            Text(
              '세트 간 ${segment.restBetweenSec}초',
              style: FacingTokens.caption,
            ),
          ],
          if (segment.targetPaceSecPer500m != null) ...[
            const SizedBox(height: FacingTokens.sp1),
            Text(
              _formatPace(segment.targetPaceSecPer500m!),
              style: FacingTokens.body.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: FacingTokens.tabular,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatPace(int sec) {
  if (sec < 300) return '${sec}s / 500m';
  final m = sec ~/ 60;
  final s = sec % 60;
  return '$m:${s.toString().padLeft(2, '0')} / 500m';
}

String _prettifySlug(String slug) {
  if (slug.isEmpty) return slug;
  return slug
      .split('_')
      .map((w) => w.isEmpty
          ? w
          : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _SplitText extends StatelessWidget {
  final List<int> splits;
  final bool lastIsExplosion;
  const _SplitText({required this.splits, required this.lastIsExplosion});

  @override
  Widget build(BuildContext context) {
    final joined = splits.join('-');
    if (!lastIsExplosion) return Text(joined, style: FacingTokens.h1);
    final lastIndex = joined.lastIndexOf('-') + 1;
    final head = joined.substring(0, lastIndex);
    final tail = joined.substring(lastIndex);
    return Text.rich(
      TextSpan(
        style: FacingTokens.h1,
        children: [
          TextSpan(text: head),
          TextSpan(text: tail,
            style: const TextStyle(color: FacingTokens.accent),
          ),
        ],
      ),
    );
  }
}
