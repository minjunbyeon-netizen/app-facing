import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/scoring.dart';
import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../models/achievement.dart';
import '../../widgets/tier_badge.dart';
import '../achievement/achievement_state.dart';
import '../history/history_models.dart';
import '../history/history_repository.dart';

/// v1.16: TRENDS — 자극·모멘텀 중심. 상세 기록은 Profile 탭으로 이관.
/// 3블록: 점수+delta / 스파크라인 / NEXT + MOMENTUM.
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  late final HistoryRepository _repo;
  Future<List<EngineSnapshotRecord>>? _future;

  @override
  void initState() {
    super.initState();
    _repo = HistoryRepository(context.read<ApiClient>());
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _repo.listEngineSnapshots(limit: 30);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TRENDS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<EngineSnapshotRecord>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: FacingTokens.muted),
                ),
              );
            }
            if (snap.hasError) {
              final e = snap.error;
              final msg = e is AppException ? e.messageKo : 'Load failed.';
              return _ErrorState(message: msg, onRetry: _reload);
            }
            final records = snap.data ?? [];
            if (records.isEmpty) return const _EmptyState();
            return _TrendsBody(records: records);
          },
        ),
      ),
    );
  }
}

class _TrendsBody extends StatelessWidget {
  final List<EngineSnapshotRecord> records;
  const _TrendsBody({required this.records});

  @override
  Widget build(BuildContext context) {
    final sorted = [...records]
      ..sort((a, b) => a.scoredAt.compareTo(b.scoredAt));
    final latest = records.first;
    final prev = records.length > 1 ? records[1] : null;
    final tier = Tier.fromOverallNumber(latest.overallNumber);
    final current = engineScoreTo100(latest.overallScore);
    final delta =
        prev != null ? current - engineScoreTo100(prev.overallScore) : 0;
    final sessionsLast30 = _countRecent(records, const Duration(days: 30));

    return ListView(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      children: [
        // 1. 현재 점수 + delta chip + tier
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$current', style: FacingTokens.displayCompact),
            const SizedBox(width: FacingTokens.sp2),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('/ 100', style: FacingTokens.caption),
            ),
            const Spacer(),
            TierBadge(tier: tier, fontSize: 16),
          ],
        ),
        const SizedBox(height: FacingTokens.sp1),
        if (prev != null)
          Text(
            delta == 0
                ? 'Hold. 변화 없음.'
                : (delta > 0 ? '▲ +$delta · 전 측정 대비' : '▼ $delta · 전 측정 대비'),
            style: FacingTokens.caption.copyWith(
              color: delta > 0
                  ? FacingTokens.success
                  : (delta < 0 ? FacingTokens.warning : FacingTokens.muted),
              fontWeight: FontWeight.w700,
            ),
          ),
        const SizedBox(height: FacingTokens.sp4),

        // 2. 스파크라인 — 전체 폭, 키 증가.
        SizedBox(
          height: 160,
          child: Semantics(
            label: 'Engine 점수 추이, ${sorted.length}개 데이터',
            child: CustomPaint(
              painter: _SparklinePainter(
                values: sorted
                    .map((r) => engineScoreTo100(r.overallScore))
                    .toList(),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: FacingTokens.sp5),

        // 3. NEXT — 다음 목표 (미해금 배지 1개).
        const _NextTarget(),
        const SizedBox(height: FacingTokens.sp5),

        // 4. MOMENTUM — 최근 30일 세션 수.
        const Text('MOMENTUM', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$sessionsLast30',
                style: FacingTokens.h1.copyWith(fontSize: 36)),
            const SizedBox(width: FacingTokens.sp2),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('sessions · 30d', style: FacingTokens.caption),
            ),
          ],
        ),
        const SizedBox(height: FacingTokens.sp4),
        Text(
          '상세 기록은 Profile에서.',
          style: FacingTokens.caption.copyWith(color: FacingTokens.muted),
        ),
      ],
    );
  }

  int _countRecent(List<EngineSnapshotRecord> rs, Duration window) {
    final cutoff = DateTime.now().subtract(window);
    return rs.where((r) => r.scoredAt.isAfter(cutoff)).length;
  }
}

/// v1.16: 다음 목표 — AchievementState의 미해금 배지 중 sort_order 최저 1개.
class _NextTarget extends StatelessWidget {
  const _NextTarget();

  @override
  Widget build(BuildContext context) {
    final ach = context.watch<AchievementState>();
    final snap = ach.snapshot;
    AchievementCatalog? next;
    for (final c in snap.catalog) {
      if (!snap.isUnlocked(c.code)) {
        next = c;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('NEXT', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        if (next == null)
          Text('All visible unlocked. Hidden milestones remain.',
              style: FacingTokens.caption)
        else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(next.name, style: FacingTokens.h3),
              const SizedBox(width: FacingTokens.sp2),
              Text(next.rarity.toUpperCase(),
                  style: FacingTokens.micro.copyWith(
                    color: _rarityColor(next.rarity),
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
          const SizedBox(height: FacingTokens.sp1),
          Text(next.description, style: FacingTokens.caption),
        ],
      ],
    );
  }

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'Rare':
        return FacingTokens.accent;
      case 'Epic':
        return FacingTokens.tierElite;
      case 'Legendary':
        return FacingTokens.tierGames;
      case 'Common':
      default:
        return FacingTokens.muted;
    }
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> values;
  _SparklinePainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    // 기준선 3개 — 매우 얇게.
    final gridPaint = Paint()
      ..color = FacingTokens.border
      ..strokeWidth = 0.5;
    for (final v in [0, 50, 100]) {
      final y = size.height - (v / 100 * size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) return;

    if (values.length == 1) {
      final y = size.height - (values[0] / 100 * size.height);
      canvas.drawCircle(
        Offset(size.width / 2, y),
        4,
        Paint()..color = FacingTokens.accent,
      );
      return;
    }

    final stepX = size.width / (values.length - 1);
    final linePaint = Paint()
      ..color = FacingTokens.accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = stepX * i;
      final y = size.height - (values[i] / 100 * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    final lastX = stepX * (values.length - 1);
    final lastY = size.height - (values.last / 100 * size.height);
    canvas.drawCircle(
      Offset(lastX, lastY),
      4,
      Paint()..color = FacingTokens.accent,
    );
    canvas.drawCircle(
      Offset(lastX, lastY),
      7,
      Paint()
        ..color = FacingTokens.accent.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      !listEquals(old.values, values);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(FacingTokens.sp5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('NO ENGINE HISTORY', style: FacingTokens.sectionLabel),
          const SizedBox(height: FacingTokens.sp2),
          const Text(
            'Engine 측정 기록 없음. Benchmarks 완료 시 자동 저장.',
            style: FacingTokens.caption,
          ),
          const SizedBox(height: FacingTokens.sp5),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context).pushNamed('/onboarding/basic'),
            child: const Text('Enter 1RM'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(FacingTokens.sp5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: FacingTokens.body, textAlign: TextAlign.center),
          const SizedBox(height: FacingTokens.sp4),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
