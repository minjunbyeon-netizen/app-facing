// 재활 가이드 진입 화면 (v1 — 동작·통증부위 브라우즈).
//
// 흐름: 동작 목록(manifest) → 통증부위 칩 → 탭하면 감별 미리보기 시트.
// 전체 감별 플로우(질문→원인→6단계 루트)는 다음 iteration.
// 데이터는 rahap1 흡수본(assets/data/rehab). 지침: docs/ADDITIONAL_SOURCE_GUIDE.md

import 'package:flutter/material.dart';

import '../../core/haptic.dart';
import '../../core/theme.dart';
import '../../widgets/hkit.dart';
import 'rehab_flow_screen.dart';
import 'rehab_models.dart';

class RehabScreen extends StatefulWidget {
  const RehabScreen({super.key});

  @override
  State<RehabScreen> createState() => _RehabScreenState();
}

class _RehabScreenState extends State<RehabScreen> {
  final _repo = RehabRepository();
  late Future<List<RehabMovement>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.loadManifest();
  }

  Future<void> _openPreview(RehabMovement mv, RehabPainSite site) async {
    Haptic.light();
    RehabPainSitePreview preview;
    try {
      preview = await _repo.loadPreview(mv.id, site.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('불러오기 실패. 다시 시도해 주세요.')),
      );
      return;
    }
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: HyphenTokens.surfaceHigh,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(HyphenTokens.r3)),
      ),
      builder: (_) => _PreviewSheet(
        preview: preview,
        onStart: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  RehabFlowScreen(movementId: mv.id, painSiteId: site.id),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HyphenTokens.bg,
      // v1.26: Rehab 탭 루트로 승격 — 타 탭 루트(HOME/WOD/PROFILE)와 표기 통일.
      appBar: AppBar(title: const Text('재활')),
      body: SafeArea(
        child: FutureBuilder<List<RehabMovement>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                    color: HyphenTokens.muted, strokeWidth: 2),
              );
            }
            if (snap.hasError || (snap.data?.isEmpty ?? true)) {
              return const Center(
                child: Text('가이드 로딩 실패.',
                    style: HyphenTokens.caption),
              );
            }
            final movements = snap.data!;
            return ListView(
              padding: const EdgeInsets.all(HyphenTokens.sp4),
              children: [
                const Text('통증 부위로 원인을 찾고 단계별 재활 진행.',
                    style: HyphenTokens.body),
                const SizedBox(height: HyphenTokens.sp2),
                const Text('동작 선택 후 아픈 부위 탭.',
                    style: HyphenTokens.caption),
                const SizedBox(height: HyphenTokens.sp5),
                for (final mv in movements)
                  _MovementCard(movement: mv, onTapSite: _openPreview),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  final RehabMovement movement;
  final void Function(RehabMovement, RehabPainSite) onTapSite;

  const _MovementCard({required this.movement, required this.onTapSite});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: HyphenTokens.sp3),
      padding: const EdgeInsets.all(HyphenTokens.sp4),
      decoration: BoxDecoration(
        color: HyphenTokens.surface,
        border: Border.all(color: HyphenTokens.border),
        borderRadius: BorderRadius.circular(HyphenTokens.r2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(movement.name, style: HyphenTokens.h3),
              if (movement.comingSoon) ...[
                const SizedBox(width: HyphenTokens.sp2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: HyphenTokens.sp2, vertical: 2),
                  decoration: BoxDecoration(
                    color: HyphenTokens.surfaceMax,
                    borderRadius: BorderRadius.circular(HyphenTokens.r1),
                  ),
                  child: Text('준비 중',
                      style: HyphenTokens.micro
                          .copyWith(color: HyphenTokens.muted)),
                ),
              ],
            ],
          ),
          const SizedBox(height: HyphenTokens.sp3),
          Wrap(
            spacing: HyphenTokens.sp2,
            runSpacing: HyphenTokens.sp2,
            children: [
              for (final site in movement.painSites)
                HkBadge(
                  site.name,
                  color: HyphenTokens.fg,
                  onTap: () => onTapSite(movement, site),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewSheet extends StatelessWidget {
  final RehabPainSitePreview preview;
  final VoidCallback onStart;

  const _PreviewSheet({required this.preview, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final hasDanger = preview.dangerTitle != null;
    final ready = preview.questionCount > 0 && !preview.comingSoon;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(HyphenTokens.sp5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${preview.movementName} · ${preview.painSiteName}',
                style: HyphenTokens.h3),
            const SizedBox(height: HyphenTokens.sp2),
            Text('감별 질문 ${preview.questionCount}개 · 원인 ${preview.causeCount}개',
                style: HyphenTokens.caption),
            if (hasDanger) ...[
              const SizedBox(height: HyphenTokens.sp4),
              Container(
                padding: const EdgeInsets.all(HyphenTokens.sp3),
                decoration: BoxDecoration(
                  color: HyphenTokens.danger.withValues(alpha: 0.12),
                  border: Border.all(
                      color: HyphenTokens.danger.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(HyphenTokens.r2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(preview.dangerTitle!,
                        style: HyphenTokens.body.copyWith(
                            color: HyphenTokens.danger,
                            fontWeight: FontWeight.w700)),
                    if (preview.dangerReason != null) ...[
                      const SizedBox(height: HyphenTokens.sp1),
                      Text(preview.dangerReason!,
                          style: HyphenTokens.caption),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: HyphenTokens.sp5),
            if (ready) ...[
              FilledButton(
                onPressed: onStart,
                child: const Text('감별 시작'),
              ),
              const SizedBox(height: HyphenTokens.sp2),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(HyphenTokens.sp3),
                decoration: BoxDecoration(
                  color: HyphenTokens.surface,
                  borderRadius: BorderRadius.circular(HyphenTokens.r2),
                ),
                child: const Text(
                  '이 부위 감별은 준비 중이에요.',
                  style: HyphenTokens.caption,
                ),
              ),
              const SizedBox(height: HyphenTokens.sp4),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
