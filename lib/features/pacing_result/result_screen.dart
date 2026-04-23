import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/theme.dart';
import '../../models/pacing_plan.dart';
import '../history/history_repository.dart';
import '../profile/profile_state.dart';
import '../wod_builder/wod_draft_state.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final Future<PacingPlan> _future;

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
    // v1.15 P1-9: 8s clientside timeout (Dio receiveTimeout 외 보강).
    final data = await api
        .post('/api/v1/pacing/calculate', body)
        .timeout(const Duration(seconds: 8));
    // fire-and-forget: WOD history 저장
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
      // 저장 실패 무시. 계산 결과 표시는 정상 진행.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pacing Strategy')),
      body: FutureBuilder<PacingPlan>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            // v1.15 P1-7: 카피 일관성 — 'Calculating.' 영문 단독.
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: FacingTokens.muted,
                    ),
                  ),
                  SizedBox(height: FacingTokens.sp3),
                  Text('Calculating.', style: FacingTokens.body),
                ],
              ),
            );
          }
          if (snap.hasError) {
            final e = snap.error;
            final msg = e is AppException
                ? e.messageKo
                : 'Calc failed. Retry.';
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
                    child: Text(msg, style: FacingTokens.body),
                  ),
                  const SizedBox(height: FacingTokens.sp3),
                  OutlinedButton(
                    onPressed: () {
                      // v1.15 P1-9: mounted 가드 (FutureBuilder setState 안전).
                      if (!mounted) return;
                      setState(() {
                        _future = _calculate();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final plan = snap.data!;
          final draft = context.read<WodDraftState>();
          final profile = context.read<ProfileState>();
          final contextParts = <String>[
            draft.type.labelKo,
            if (draft.rounds != null) '${draft.rounds} Rounds',
            if (profile.overallGrade != null) profile.overallGrade!.toUpperCase(),
          ];
          return ListView(
            padding: const EdgeInsets.all(FacingTokens.sp4),
            children: [
              Text(contextParts.join(' · '),
                  style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(plan.estimatedTotalDisplay, style: FacingTokens.display),
                  const SizedBox(width: FacingTokens.sp2),
                  const Text('예상', style: FacingTokens.caption),
                ],
              ),
              const SizedBox(height: FacingTokens.sp1),
              const Text('예상 완주 시간 · 레스트 포함',
                  style: FacingTokens.caption),
              const SizedBox(height: FacingTokens.sp5),
              ...plan.segments.map((s) => _SegmentCard(segment: s)),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentCard extends StatelessWidget {
  final PacingSegment segment;
  const _SegmentCard({required this.segment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: FacingTokens.sp3),
      padding: const EdgeInsets.all(FacingTokens.sp4),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: segment.isExplosion
            ? Border.all(color: FacingTokens.accent, width: 2)
            : null,
        borderRadius: BorderRadius.circular(FacingTokens.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (segment.isExplosion) ...[
            Text('BURST',
                style: FacingTokens.sectionLabel.copyWith(
                  color: FacingTokens.accent,
                )),
            const SizedBox(height: FacingTokens.sp1),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_prettifySlug(segment.movementSlug),
                  style: FacingTokens.h3),
              Text(segment.estimatedDisplay,
                  style: FacingTokens.lead.copyWith(
                    fontFeatures: FacingTokens.tabular,
                  )),
            ],
          ),
          const SizedBox(height: FacingTokens.sp3),
          if (segment.splitPattern.isNotEmpty) ...[
            _SplitText(
              splits: segment.splitPattern,
              lastIsExplosion: segment.isExplosion,
            ),
            const SizedBox(height: FacingTokens.sp1),
            Text(
              '세트 간 휴식 ${segment.restBetweenSec}초',
              style: FacingTokens.caption,
            ),
          ],
          if (segment.targetPaceSecPer500m != null)
            Text(
              _formatPace(segment.targetPaceSecPer500m!),
              style: FacingTokens.h3.copyWith(
                fontFeatures: FacingTokens.tabular,
              ),
            ),
          const SizedBox(height: FacingTokens.sp3),
          Text(segment.rationaleKo, style: FacingTokens.caption),
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
