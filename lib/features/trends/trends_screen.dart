import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/scoring.dart';
import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../widgets/tier_badge.dart';
import '../history/history_models.dart';
import '../history/history_repository.dart';

/// v1.15.3: 변화추이 — Engine 점수 시계열.
/// 데이터 소스: /api/v1/history/engine (기존 HistoryRepository 재활용).
/// 표시: 상단 최신 스냅샷 요약 + 스파크라인(CustomPainter) + 최근 5건 리스트.
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
            if (records.isEmpty) {
              return const _EmptyState();
            }
            return _TrendsBody(records: records, to100: engineScoreTo100);
          },
        ),
      ),
    );
  }
}

class _TrendsBody extends StatelessWidget {
  final List<EngineSnapshotRecord> records;
  final int Function(double) to100;
  const _TrendsBody({required this.records, required this.to100});

  @override
  Widget build(BuildContext context) {
    // 최신 → 과거 정렬 가정. 차트는 오래된→최신 순.
    final sorted = [...records]..sort((a, b) => a.scoredAt.compareTo(b.scoredAt));
    final latest = records.first;
    final prev = records.length > 1 ? records[1] : null;
    final tier = Tier.fromOverallNumber(latest.overallNumber);
    final currentScore = to100(latest.overallScore);
    final delta = prev != null
        ? currentScore - to100(prev.overallScore)
        : 0;

    return ListView(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      children: [
        const SizedBox(height: FacingTokens.sp2),
        const Text('ENGINE SCORE', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$currentScore', style: FacingTokens.displayCompact),
            const SizedBox(width: FacingTokens.sp2),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('/ 100', style: FacingTokens.caption),
            ),
            const Spacer(),
            TierBadge(tier: tier, fontSize: 18),
          ],
        ),
        const SizedBox(height: FacingTokens.sp1),
        if (prev != null)
          Text(
            delta == 0
                ? '변화 없음'
                : (delta > 0 ? '▲ +$delta' : '▼ $delta'),
            style: FacingTokens.caption.copyWith(
              color: delta > 0
                  ? FacingTokens.success
                  : (delta < 0 ? FacingTokens.warning : FacingTokens.muted),
              fontWeight: FontWeight.w700,
            ),
          ),
        const SizedBox(height: FacingTokens.sp5),
        const Text('최근 추이', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp3),
        SizedBox(
          height: 140,
          child: Semantics(
            label: 'Engine 점수 추이 차트, 최근 ${sorted.length}개 데이터',
            child: CustomPaint(
              painter: _SparklinePainter(
                values: sorted.map((r) => to100(r.overallScore)).toList(),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: FacingTokens.sp5),
        const Text('CATEGORY BREAKDOWN', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp3),
        ..._categoryRows(sorted),
        const SizedBox(height: FacingTokens.sp5),
        const Text('히스토리', style: FacingTokens.sectionLabel),
        const SizedBox(height: FacingTokens.sp2),
        ...records.take(10).map((r) => _RecordRow(r: r, to100: to100)),
      ],
    );
  }

  /// 카테고리별(5개) mini sparkline. 데이터 0건인 카테고리는 스킵.
  /// EngineSnapshotRecord의 category score 필드는 nullable — 누락은 제외.
  List<Widget> _categoryRows(List<EngineSnapshotRecord> sorted) {
    final specs = <_CategorySpec>[
      _CategorySpec('POWER', (r) => r.powerScore),
      _CategorySpec('OLYMPIC', (r) => r.olympicScore),
      _CategorySpec('GYMNASTICS', (r) => r.gymnasticsScore),
      _CategorySpec('CARDIO', (r) => r.cardioScore),
      _CategorySpec('METCON', (r) => r.metconScore),
    ];
    final widgets = <Widget>[];
    for (final spec in specs) {
      final values = sorted
          .map((r) => spec.extract(r))
          .where((v) => v != null)
          .map((v) => to100(v!))
          .toList();
      if (values.isEmpty) continue;
      widgets.add(_CategoryRow(title: spec.title, values: values));
    }
    if (widgets.isEmpty) {
      return [
        Text('카테고리 데이터 없음', style: FacingTokens.caption),
      ];
    }
    return widgets;
  }
}

class _CategorySpec {
  final String title;
  final double? Function(EngineSnapshotRecord) extract;
  const _CategorySpec(this.title, this.extract);
}

class _CategoryRow extends StatelessWidget {
  final String title;
  final List<int> values;
  const _CategoryRow({required this.title, required this.values});

  @override
  Widget build(BuildContext context) {
    final latest = values.last;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(title, style: FacingTokens.sectionLabel),
          ),
          Expanded(
            child: SizedBox(
              height: 28,
              child: Semantics(
                label: '$title 추이, ${values.length}개 데이터, 최신 $latest',
                child: CustomPaint(
                  painter: _SparklinePainter(values: values),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          const SizedBox(width: FacingTokens.sp3),
          SizedBox(
            width: 36,
            child: Text(
              '$latest',
              textAlign: TextAlign.right,
              style: FacingTokens.body.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: FacingTokens.tabular,
              ),
            ),
          ),
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
    final gridPaint = Paint()
      ..color = FacingTokens.border
      ..strokeWidth = 1;
    // 100·50·0 기준선
    for (final v in [0, 50, 100]) {
      final y = size.height - (v / 100 * size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) return;

    if (values.length == 1) {
      final y = size.height - (values[0] / 100 * size.height);
      final dotPaint = Paint()..color = FacingTokens.accent;
      canvas.drawCircle(Offset(size.width / 2, y), 4, dotPaint);
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

    // 최신 포인트 강조
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

class _RecordRow extends StatelessWidget {
  final EngineSnapshotRecord r;
  final int Function(double) to100;
  const _RecordRow({required this.r, required this.to100});

  @override
  Widget build(BuildContext context) {
    final tier = Tier.fromOverallNumber(r.overallNumber);
    final d = r.scoredAt.toLocal();
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
      child: Row(
        children: [
          Container(width: 3, height: 24, color: tier.color),
          const SizedBox(width: FacingTokens.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: FacingTokens.body),
                Text('${r.itemsUsed} items', style: FacingTokens.caption),
              ],
            ),
          ),
          TierBadge(tier: tier),
          const SizedBox(width: FacingTokens.sp3),
          Text(
            '${to100(r.overallScore)}',
            style: FacingTokens.body.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: FacingTokens.tabular,
            ),
          ),
        ],
      ),
    );
  }
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
