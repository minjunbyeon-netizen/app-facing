import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/level_system.dart';
import '../../core/pr_detector.dart';
import '../../core/scoring.dart';
import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../core/weak_insight.dart';
import '../../widgets/inbox_bell.dart';
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
  Future<List<EngineSnapshotRecord>>? _engineFuture;
  Future<List<WodHistoryItem>>? _wodFuture;

  @override
  void initState() {
    super.initState();
    final repo = HistoryRepository(context.read<ApiClient>());
    _engineFuture = repo.listEngineSnapshots(limit: 12);
    _wodFuture = repo.listWodHistory(limit: 200);
  }

  void _reload() {
    final repo = HistoryRepository(context.read<ApiClient>());
    setState(() {
      _engineFuture = repo.listEngineSnapshots(limit: 12);
      _wodFuture = repo.listWodHistory(limit: 200);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HOME'),
        automaticallyImplyLeading: false,
        actions: [
          const InboxBellAction(),
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
                  // v1.22: Tier + Engine + Radar 통합 hero 카드 (안 C).
                  _HeroCard(
                    engineFuture: _engineFuture,
                    wodFuture: _wodFuture,
                  ),
                  const SizedBox(height: FacingTokens.sp3),
                  // v1.22: 약점 분석은 별도 inline (역할 분리).
                  const _WeaknessInsightInline(),
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

/// v1.22: Hero 카드 — Tier + Engine + Radar + Sparkline + LEVEL 통합.
/// 안 C 채택: Radar 주체 + 중앙 ENGINE 점수(HWPO display 72sp).
class _HeroCard extends StatelessWidget {
  final Future<List<EngineSnapshotRecord>>? engineFuture;
  final Future<List<WodHistoryItem>>? wodFuture;
  const _HeroCard({
    required this.engineFuture,
    required this.wodFuture,
  });

  int _catScore(Map<String, dynamic>? grade, String key) {
    if (grade == null) return 0;
    final data = grade[key];
    if (data is! Map) return 0;
    final s = data['score'];
    if (s is! num) return 0;
    return engineScoreTo100(s);
  }

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

    final radarValues = <_RadarAxis>[
      _RadarAxis('POWER', _catScore(g, 'power')),
      _RadarAxis('OLYMPIC', _catScore(g, 'olympic')),
      _RadarAxis('GYMNASTICS', _catScore(g, 'gymnastics')),
      _RadarAxis('CARDIO', _catScore(g, 'cardio')),
      _RadarAxis('METCON', _catScore(g, 'metcon')),
      _RadarAxis('BODY', _catScore(g, 'body_composition')),
    ];
    final hasRadarData = radarValues.any((a) => a.value > 0);

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
            // 상단 — TierBadge + LV indicator
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
            // v1.22: Radar + 중앙 ENGINE 점수 (HWPO 임팩트 #2 적용 위치).
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (hasRadarData)
                    CustomPaint(
                      painter: _RadarPainter(
                        axes: radarValues,
                        clearCenter: true,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  // 중앙 마스크 (radar 격자 가림)
                  Container(
                    width: 124,
                    height: 124,
                    decoration: const BoxDecoration(
                      color: FacingTokens.surface,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // 중앙 ENGINE 숫자 — HWPO display 72sp w900 + 탠 액센트
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasScore ? '$score100' : '—',
                        style: FacingTokens.display.copyWith(
                          color: FacingTokens.accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ENGINE / 100',
                        style: FacingTokens.microLabel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: FacingTokens.sp3),
            FutureBuilder<List<EngineSnapshotRecord>>(
              future: engineFuture,
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
            // v1.21: LEVEL 섹션 — Attend 하단에서 통합. WOD history 기반.
            const SizedBox(height: FacingTokens.sp3),
            const Divider(height: 1, color: FacingTokens.border),
            const SizedBox(height: FacingTokens.sp3),
            FutureBuilder<List<WodHistoryItem>>(
              future: wodFuture,
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SizedBox(height: 60);
                }
                if (snap.hasError) {
                  return Text('Level 데이터 로딩 실패. 다시 시도.',
                      style: FacingTokens.caption);
                }
                final history = snap.data ?? const <WodHistoryItem>[];
                final streak = _currentStreakDays(history);
                final tierNum = n.toInt();
                final prCount = PrDetector.countPrs(history);
                final bd = LevelSystem.compute(
                  totalSessions: history.length,
                  currentStreakDays: streak,
                  tierNumber: tierNum,
                  prCount: prCount,
                );
                final pct = (bd.progress * 100).round();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('LEVEL ${bd.level}',
                            style: FacingTokens.h3.copyWith(
                              fontWeight: FontWeight.w800,
                              fontFeatures: FacingTokens.tabular,
                            )),
                        const Spacer(),
                        Text('${bd.totalXp} XP',
                            style: FacingTokens.caption.copyWith(
                              fontFeatures: FacingTokens.tabular,
                              color: FacingTokens.muted,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                    const SizedBox(height: FacingTokens.sp2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(FacingTokens.r1),
                      child: Stack(
                        children: [
                          Container(height: 6, color: FacingTokens.border),
                          FractionallySizedBox(
                            widthFactor: bd.progress,
                            child: Container(
                                height: 6, color: FacingTokens.accent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: FacingTokens.sp2),
                    Text(
                      bd.level >= LevelSystem.maxLevel
                          ? 'MAX LEVEL'
                          : '$pct% · next Lv${bd.level + 1} · ${bd.xpToNext} XP',
                      style: FacingTokens.caption,
                    ),
                    const SizedBox(height: FacingTokens.sp2),
                    // XP 소스 한 줄씩 — 컴팩트 (Attend는 표 형태였음).
                    _XpInline(label: 'Sessions', value: bd.sessionXp),
                    _XpInline(label: 'Streak', value: bd.streakXp),
                    _XpInline(label: 'Tier', value: bd.tierXp),
                    if (bd.prXp > 0)
                      _XpInline(label: 'PRs', value: bd.prXp),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// 현재 streak — 오늘(또는 최근 세션일)부터 연속 일수.
  int _currentStreakDays(List<WodHistoryItem> list) {
    if (list.isEmpty) return 0;
    final days = <DateTime>{};
    for (final w in list) {
      final d = w.createdAt.toLocal();
      days.add(DateTime(d.year, d.month, d.day));
    }
    final today = DateTime.now();
    DateTime cursor = DateTime(today.year, today.month, today.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    int count = 0;
    while (days.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }
}

class _XpInline extends StatelessWidget {
  final String label;
  final int value;
  const _XpInline({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: FacingTokens.caption)),
          Text('+$value',
              style: FacingTokens.caption.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: FacingTokens.tabular,
                color: FacingTokens.fg,
              )),
        ],
      ),
    );
  }
}

/// v1.22: 약점 분석 inline — hero 카드 아래 작은 카드로 분리.
/// hero가 "지표"라면 이 카드는 "분석".
class _WeaknessInsightInline extends StatelessWidget {
  const _WeaknessInsightInline();

  int _catScore(Map<String, dynamic>? grade, String key) {
    if (grade == null) return 0;
    final data = grade[key];
    if (data is! Map) return 0;
    final s = data['score'];
    if (s is! num) return 0;
    return engineScoreTo100(s);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileState>();
    final g = p.gradeResult;
    final scores = {
      'POWER': _catScore(g, 'power'),
      'OLYMPIC': _catScore(g, 'olympic'),
      'GYMNASTICS': _catScore(g, 'gymnastics'),
      'CARDIO': _catScore(g, 'cardio'),
      'METCON': _catScore(g, 'metcon'),
      'BODY': _catScore(g, 'body_composition'),
    };
    final hasData = scores.values.any((v) => v > 0);
    if (!hasData) return const SizedBox.shrink();

    final insight = analyzeWeakness(scores);
    if (insight == null) return const SizedBox.shrink();
    final isBalanced = insight.weakestCategory == 'BALANCED';

    return Container(
      padding: const EdgeInsets.all(FacingTokens.sp3),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        border: Border.all(color: FacingTokens.border),
        borderRadius: BorderRadius.circular(FacingTokens.r3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 36,
            color: isBalanced
                ? FacingTokens.success
                : FacingTokens.accent,
          ),
          const SizedBox(width: FacingTokens.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBalanced
                      ? 'BALANCED'
                      : '${insight.weakestCategory} · WEAKEST',
                  style: FacingTokens.microLabel.copyWith(
                    color: isBalanced
                        ? FacingTokens.success
                        : FacingTokens.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(insight.comment, style: FacingTokens.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarAxis {
  final String label;
  final int value; // 0~100
  const _RadarAxis(this.label, this.value);
}

class _RadarPainter extends CustomPainter {
  final List<_RadarAxis> axes;
  /// v1.22: 중앙에 ENGINE 점수 오버레이 시 격자 비우기.
  final bool clearCenter;
  _RadarPainter({required this.axes, this.clearCenter = false});

  static const double _topAngle = -math.pi / 2;
  static const double _innerCutoffRatio = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final n = axes.length;
    if (n < 3) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 28;
    final angleStep = 2 * math.pi / n;

    final bgPaint = Paint()
      ..color = FacingTokens.border
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    // v1.22: clearCenter 시 가장 안쪽 ring(0.33) 생략.
    final ringRatios = clearCenter ? [0.66, 1.0] : [0.33, 0.66, 1.0];
    for (final ratio in ringRatios) {
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = _topAngle + angleStep * i;
        final x = center.dx + radius * ratio * math.cos(angle);
        final y = center.dy + radius * ratio * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, bgPaint);
    }

    final axisPaint = Paint()
      ..color = FacingTokens.border
      ..strokeWidth = 1;
    for (int i = 0; i < n; i++) {
      final angle = _topAngle + angleStep * i;
      // v1.22: clearCenter 시 축선은 안쪽 cutoff부터 시작 (중앙 비우기).
      final startRatio = clearCenter ? _innerCutoffRatio : 0.0;
      final sx = center.dx + radius * startRatio * math.cos(angle);
      final sy = center.dy + radius * startRatio * math.sin(angle);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(Offset(sx, sy), Offset(x, y), axisPaint);
    }

    final userPath = Path();
    for (int i = 0; i < n; i++) {
      final angle = _topAngle + angleStep * i;
      final ratio = (axes[i].value / 100).clamp(0.02, 1.0);
      final x = center.dx + radius * ratio * math.cos(angle);
      final y = center.dy + radius * ratio * math.sin(angle);
      if (i == 0) {
        userPath.moveTo(x, y);
      } else {
        userPath.lineTo(x, y);
      }
    }
    userPath.close();
    canvas.drawPath(
      userPath,
      Paint()
        ..color = FacingTokens.accent.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      userPath,
      Paint()
        ..color = FacingTokens.accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    for (int i = 0; i < n; i++) {
      final angle = _topAngle + angleStep * i;
      final ratio = (axes[i].value / 100).clamp(0.02, 1.0);
      final x = center.dx + radius * ratio * math.cos(angle);
      final y = center.dy + radius * ratio * math.sin(angle);
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = FacingTokens.accent,
      );
    }

    for (int i = 0; i < n; i++) {
      final angle = _topAngle + angleStep * i;
      final lx = center.dx + (radius + 16) * math.cos(angle);
      final ly = center.dy + (radius + 16) * math.sin(angle);
      final tp = TextPainter(
        text: TextSpan(
          text: axes[i].label,
          style: FacingTokens.sectionLabel.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 80);
      final offset = Offset(lx - tp.width / 2, ly - tp.height / 2);
      tp.paint(canvas, offset);
      final vp = TextPainter(
        text: TextSpan(
          text: '${axes[i].value}',
          style: FacingTokens.sectionLabel.copyWith(
            color: FacingTokens.fg,
            letterSpacing: 0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final vOffset = Offset(lx - vp.width / 2, ly + tp.height / 2 + 1);
      vp.paint(canvas, vOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) {
    if (old.axes.length != axes.length) return true;
    for (int i = 0; i < axes.length; i++) {
      if (old.axes[i].value != axes[i].value) return true;
      if (old.axes[i].label != axes[i].label) return true;
    }
    return false;
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
