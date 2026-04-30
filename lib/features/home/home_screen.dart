import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/haptic.dart';
import '../../core/level_system.dart';
import '../../core/scoring.dart';
import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../core/titles_catalog.dart';
import '../../core/weak_insight.dart';
import '../../core/worn_title_store.dart';
import '../../widgets/inbox_bell.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/tier_badge.dart';
import '../achievement/achievement_state.dart';
import '../auth/auth_state.dart';
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
  Future<int>? _sessionCountFuture;
  String? _wornTitleCode;

  @override
  void initState() {
    super.initState();
    final repo = HistoryRepository(context.read<ApiClient>());
    _engineFuture = repo.listEngineSnapshots(limit: 12);
    _sessionCountFuture = repo.listWodHistory(limit: 9999).then((r) => r.length);
    WornTitleStore.get().then((code) {
      if (mounted) setState(() => _wornTitleCode = code);
    });
  }

  void _reload() {
    final repo = HistoryRepository(context.read<ApiClient>());
    setState(() {
      _engineFuture = repo.listEngineSnapshots(limit: 12);
      _sessionCountFuture = repo.listWodHistory(limit: 9999).then((r) => r.length);
    });
    WornTitleStore.get().then((code) {
      if (mounted) setState(() => _wornTitleCode = code);
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
                  // v1.22 rev2: LEVEL 섹션 → Attend 로 이관.
                  _HeroCard(
                    engineFuture: _engineFuture,
                    sessionCountFuture: _sessionCountFuture,
                    wornTitleCode: _wornTitleCode,
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

/// v1.22 rev11: Hero 카드 — Athlete Identity Header + Tier-colored Radar.
/// 레이더 위: 닉네임 · 레벨 · 칭호. 레이더 채움: tier 컬러.
class _HeroCard extends StatelessWidget {
  final Future<List<EngineSnapshotRecord>>? engineFuture;
  final Future<int>? sessionCountFuture;
  final String? wornTitleCode;

  const _HeroCard({
    required this.engineFuture,
    this.sessionCountFuture,
    this.wornTitleCode,
  });

  int _catScore(Map<String, dynamic>? grade, String key) {
    if (grade == null) return 0;
    final data = grade[key];
    if (data is! Map) return 0;
    final s = data['score'];
    if (s is! num) return 0;
    return engineScoreTo100(s);
  }

  static PanelBTitle? _findTitle(String? code) {
    if (code == null) return null;
    for (final t in kPanelBTitles) {
      if (t.code == code) return t;
    }
    return null;
  }

  static Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'Rare':
        return FacingTokens.accent;
      case 'Epic':
        return FacingTokens.tierElite;
      case 'Legendary':
        return FacingTokens.tierGames;
      default:
        return FacingTokens.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final p = context.watch<ProfileState>();
    final achState = context.watch<AchievementState>();
    final g = p.gradeResult;
    final num? n =
        g?['overall_number'] is num ? g!['overall_number'] as num : null;
    final tier = Tier.fromOverallNumber(n);
    final rawScore = g?['overall_score'];
    final score100 = engineScoreTo100(rawScore);
    final hasScore = score100 > 0;
    final tierNum = n?.round() ?? 0;

    final radarValues = <_RadarAxis>[
      _RadarAxis('POWER', _catScore(g, 'power')),
      _RadarAxis('OLYMPIC', _catScore(g, 'olympic')),
      _RadarAxis('GYMNASTICS', _catScore(g, 'gymnastics')),
      _RadarAxis('CARDIO', _catScore(g, 'cardio')),
      _RadarAxis('METCON', _catScore(g, 'metcon')),
      _RadarAxis('BODY', _catScore(g, 'body_composition')),
    ];
    final hasRadarData = radarValues.any((a) => a.value > 0);
    final titleObj = _findTitle(wornTitleCode);

    // achievement XP for level computation
    final achXp = achState.snapshot.unlocked.values.fold<int>(0, (sum, u) {
      final cat = achState.snapshot.catalog
          .where((c) => c.code == u.code)
          .toList();
      if (cat.isEmpty) return sum;
      return sum + (LevelSystem.rarityXp[cat.first.rarity] ?? 20);
    });

    return Container(
      // 외부: tier 컬러 배경 (top accent bar로 노출)
      decoration: BoxDecoration(
        color: tier.color,
        borderRadius: BorderRadius.circular(FacingTokens.r3),
        border: Border.all(color: tier.color.withValues(alpha: 0.60), width: 1),
      ),
      child: Padding(
        // top 3px → tier 컬러 accent bar 노출
        padding: const EdgeInsets.only(top: 3),
        child: Container(
          decoration: BoxDecoration(
            color: FacingTokens.surface,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(FacingTokens.r3 - 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            FacingTokens.sp4,
            FacingTokens.sp3,
            FacingTokens.sp4,
            FacingTokens.sp4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (n == null) ...[
                const Text('CURRENT TIER', style: FacingTokens.sectionLabel),
                const SizedBox(height: FacingTokens.sp2),
                const Text('온보딩 완료 후 표시.', style: FacingTokens.caption),
                const SizedBox(height: FacingTokens.sp3),
                OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/onboarding/basic'),
                  child: const Text('Start Onboarding'),
                ),
              ] else ...[
                // ── Athlete Identity Header ──────────────────────────────
                FutureBuilder<int>(
                  future: sessionCountFuture,
                  builder: (_, snap) {
                    final sessions = snap.data ?? 0;
                    final bd = LevelSystem.compute(
                      totalSessions: sessions,
                      currentStreakDays: 0,
                      tierNumber: tierNum,
                      achievementXp: achXp,
                    );
                    return _IdentityRow(
                      displayName: auth.displayName,
                      level: bd.level,
                      title: titleObj,
                      tierColor: tier.color,
                      rarityColor:
                          titleObj != null ? _rarityColor(titleObj.rarity) : null,
                    );
                  },
                ),
                const SizedBox(height: FacingTokens.sp3),
                // ── Tier + Engine Score row ──────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TierBadge(tier: tier, fontSize: 14),
                    const Spacer(),
                    if (hasScore) ...[
                      Text(
                        'Engine · $score100',
                        style: FacingTokens.caption.copyWith(
                          color: tier.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: FacingTokens.sp3),
                // ── Radar (tier-colored fill) ────────────────────────────
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
                            fillColor: tier.color,
                            strokeColor: tier.color,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      Container(
                        width: 124,
                        height: 124,
                        decoration: BoxDecoration(
                          color: FacingTokens.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tier.color.withValues(alpha: 0.30),
                            width: 1.5,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasScore ? '$score100' : '—',
                            style: FacingTokens.display.copyWith(
                              color: tier.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text('ENGINE / 100', style: FacingTokens.microLabel),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: FacingTokens.sp3),
                // ── Sparkline ────────────────────────────────────────────
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
                    final records =
                        snap.data ?? const <EngineSnapshotRecord>[];
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
                            painter: _SparklinePainter(
                              values: values,
                              lineColor: tier.color,
                            ),
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
        ),
      ),
    );
  }
}

/// Athlete identity: 닉네임 + 레벨 배지 + 칭호 배지.
class _IdentityRow extends StatelessWidget {
  final String? displayName;
  final int level;
  final PanelBTitle? title;
  final Color tierColor;
  final Color? rarityColor;

  const _IdentityRow({
    required this.displayName,
    required this.level,
    required this.tierColor,
    this.title,
    this.rarityColor,
  });

  @override
  Widget build(BuildContext context) {
    final name = (displayName?.trim().isNotEmpty == true)
        ? displayName!.trim().toUpperCase()
        : 'ATHLETE';
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: FacingTokens.h3.copyWith(
              color: FacingTokens.fg,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: FacingTokens.sp2),
        _Pill(
          label: 'LV $level',
          bg: tierColor.withValues(alpha: 0.18),
          border: tierColor.withValues(alpha: 0.55),
          fg: tierColor,
        ),
        if (title != null) ...[
          const SizedBox(width: 6),
          _Pill(
            label: title!.label,
            bg: (rarityColor ?? FacingTokens.muted).withValues(alpha: 0.15),
            border: (rarityColor ?? FacingTokens.muted).withValues(alpha: 0.45),
            fg: rarityColor ?? FacingTokens.muted,
            fontSize: 9,
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color border;
  final Color fg;
  final double fontSize;

  const _Pill({
    required this.label,
    required this.bg,
    required this.border,
    required this.fg,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: FacingTokens.micro.copyWith(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// v1.22 rev2: _XpInline / _currentStreakDays 제거 — LEVEL 섹션 Attend 로 이관.

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
  final bool clearCenter;
  final Color fillColor;
  final Color strokeColor;
  _RadarPainter({
    required this.axes,
    this.clearCenter = false,
    this.fillColor = FacingTokens.accent,
    this.strokeColor = FacingTokens.accent,
  });

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
        ..color = fillColor.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      userPath,
      Paint()
        ..color = strokeColor
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
        Paint()..color = strokeColor,
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
    if (old.fillColor != fillColor) return true;
    if (old.strokeColor != strokeColor) return true;
    for (int i = 0; i < axes.length; i++) {
      if (old.axes[i].value != axes[i].value) return true;
      if (old.axes[i].label != axes[i].label) return true;
    }
    return false;
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> values;
  final Color lineColor;
  _SparklinePainter({required this.values, this.lineColor = FacingTokens.accent});

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
        ..color = lineColor
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
      Paint()..color = lineColor,
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
