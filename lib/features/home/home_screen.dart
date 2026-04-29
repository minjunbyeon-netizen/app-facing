import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/scoring.dart';
import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/tier_badge.dart';
import '../history/history_models.dart';
import '../history/history_repository.dart';
import '../presets/presets_screen.dart';
import '../profile/profile_state.dart';
import '../wod_builder/wod_builder_screen.dart';

/// v1.21: 5탭 Home — Tier · Engine Score · Trend sparkline + WOD 카테고리 4버튼.
/// 격상 전 Calc 탭의 4버튼(Girls/Hero/Games/Custom) 컨텐츠 + 상단 점수 카드 통합.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<EngineSnapshotRecord>>? _future;

  @override
  void initState() {
    super.initState();
    final repo = HistoryRepository(context.read<ApiClient>());
    _future = repo.listEngineSnapshots(limit: 12);
  }

  void _reload() {
    final repo = HistoryRepository(context.read<ApiClient>());
    setState(() {
      _future = repo.listEngineSnapshots(limit: 12);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HOME'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(FacingTokens.sp4),
                children: [
                  _TierEngineCard(future: _future),
                  const SizedBox(height: FacingTokens.sp5),
                  const Text('CALCULATE WOD',
                      style: FacingTokens.sectionLabel),
                  const SizedBox(height: FacingTokens.sp1),
                  const Text(
                    'Pick a category. Split · Burst auto-calc.',
                    style: FacingTokens.caption,
                  ),
                  const SizedBox(height: FacingTokens.sp3),
                  _CategoryRow(
                    title: 'Girls',
                    subtitle: 'Fran · Grace · Helen · Diane',
                    onTap: () => _openPreset(context, 'girl', 'GIRLS WODS'),
                  ),
                  const Divider(height: 1, color: FacingTokens.border),
                  _CategoryRow(
                    title: 'Heroes',
                    subtitle: 'Murph · DT · JT · Michael',
                    onTap: () => _openPreset(context, 'hero', 'HERO WODS'),
                  ),
                  const Divider(height: 1, color: FacingTokens.border),
                  _CategoryRow(
                    title: 'Games',
                    subtitle: 'Amanda .45 · Jackie Pro · 2421 ...',
                    onTap: () => _openPreset(context, 'games', 'GAMES WODS'),
                  ),
                  const Divider(height: 1, color: FacingTokens.border),
                  _CategoryRow(
                    title: 'Custom',
                    subtitle: 'Build movements/reps. For Time only.',
                    onTap: () {
                      Haptic.medium();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const WodBuilderScreen(),
                      ));
                    },
                  ),
                  const Divider(height: 1, color: FacingTokens.border),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPreset(BuildContext context, String filter, String title) {
    Haptic.medium();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PresetsScreen(
        initialFilter: filter,
        lockFilter: true,
        titleOverride: title,
      ),
    ));
  }
}

/// 상단 카드: TierBadge + display Score + 30일 sparkline.
class _TierEngineCard extends StatelessWidget {
  final Future<List<EngineSnapshotRecord>>? future;
  const _TierEngineCard({required this.future});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final g = p.gradeResult;
    final num? n =
        g?['overall_number'] is num ? g!['overall_number'] as num : null;
    final tier = Tier.fromOverallNumber(n);
    final rawScore = g?['overall_score'];
    final score100 = engineScoreTo100(rawScore);
    final hasScore = score100 > 0;

    return Container(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: Border.all(color: FacingTokens.border),
        borderRadius: BorderRadius.circular(FacingTokens.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (n == null) ...[
            const Text('CURRENT TIER', style: FacingTokens.sectionLabel),
            const SizedBox(height: FacingTokens.sp2),
            const Text(
              '온보딩 완료 후 표시.',
              style: FacingTokens.caption,
            ),
            const SizedBox(height: FacingTokens.sp3),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/onboarding/basic'),
              child: const Text('Start Onboarding'),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TierBadge(tier: tier, fontSize: 14),
                const Spacer(),
                Text('LV ${n.toInt()}/6',
                    style: FacingTokens.microLabel),
              ],
            ),
            const SizedBox(height: FacingTokens.sp3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(hasScore ? '$score100' : '—',
                    style: FacingTokens.display),
                const SizedBox(width: FacingTokens.sp2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('/ 100',
                      style: FacingTokens.caption.copyWith(
                        color: FacingTokens.muted,
                      )),
                ),
                const Spacer(),
                Text('ENGINE',
                    style: FacingTokens.microLabel),
              ],
            ),
            const SizedBox(height: FacingTokens.sp3),
            FutureBuilder<List<EngineSnapshotRecord>>(
              future: future,
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SizedBox(height: 56);
                }
                if (snap.hasError) {
                  return Container(
                    height: 56,
                    alignment: Alignment.centerLeft,
                    child: Text('Trend 로딩 실패. 다시 시도.',
                        style: FacingTokens.caption),
                  );
                }
                final records = snap.data ?? const <EngineSnapshotRecord>[];
                if (records.length < 2) {
                  return Container(
                    height: 56,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      records.isEmpty
                          ? 'No history. Measure Engine.'
                          : 'Need 2+ snapshots for trend.',
                      style: FacingTokens.caption,
                    ),
                  );
                }
                final sorted = [...records]
                  ..sort((a, b) => a.scoredAt.compareTo(b.scoredAt));
                final values = sorted
                    .map((r) => engineScoreTo100(r.overallScore))
                    .toList();
                final delta = values.last - values.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 56,
                      child: CustomPaint(
                        painter: _SparklinePainter(values: values),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    const SizedBox(height: FacingTokens.sp1),
                    Text(
                      delta > 0
                          ? '▲ +$delta · ${values.length} snapshots'
                          : (delta < 0
                              ? '▼ $delta · ${values.length} snapshots'
                              : 'Hold · ${values.length} snapshots'),
                      style: FacingTokens.caption.copyWith(
                        color: delta > 0
                            ? FacingTokens.success
                            : (delta < 0
                                ? FacingTokens.warning
                                : FacingTokens.muted),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> values;
  _SparklinePainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final span = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final dx = size.width / (values.length - 1);

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final ratio = (values[i] - minV) / span;
      final x = dx * i;
      final y = size.height - (size.height * ratio);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = FacingTokens.accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    final lastRatio = (values.last - minV) / span;
    final lastX = dx * (values.length - 1);
    final lastY = size.height - (size.height * lastRatio);
    canvas.drawCircle(
      Offset(lastX, lastY),
      4,
      Paint()..color = FacingTokens.accent,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values;
}

class _CategoryRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _CategoryRow({
    required this.title,
    required this.subtitle,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FacingTokens.h3.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: FacingTokens.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: FacingTokens.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
