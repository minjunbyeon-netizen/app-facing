import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../widgets/tier_badge.dart';
import 'history_models.dart';
import 'history_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tc;
  late final HistoryRepository _repo;
  Future<List<EngineSnapshotRecord>>? _engineFuture;
  Future<List<WodHistoryItem>>? _wodFuture;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
    _repo = HistoryRepository(context.read<ApiClient>());
    _reload();
  }

  void _reload() {
    setState(() {
      _engineFuture = _repo.listEngineSnapshots(limit: 50);
      _wodFuture = _repo.listWodHistory(limit: 20);
    });
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tc,
          labelColor: FacingTokens.fg,
          unselectedLabelColor: FacingTokens.muted,
          indicatorColor: FacingTokens.accent,
          tabs: const [
            Tab(text: 'Engine'),
            Tab(text: 'WOD'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tc,
        children: [
          _EngineTab(future: _engineFuture, onRetry: _reload),
          _WodTab(future: _wodFuture, onRetry: _reload),
        ],
      ),
    );
  }
}

class _EngineTab extends StatelessWidget {
  final Future<List<EngineSnapshotRecord>>? future;
  final VoidCallback onRetry;
  const _EngineTab({required this.future, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EngineSnapshotRecord>>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: Text('Loading', style: FacingTokens.body));
        }
        if (snap.hasError) {
          return _ErrorView(error: snap.error, onRetry: onRetry);
        }
        final rows = snap.data ?? const [];
        if (rows.isEmpty) {
          return const _EmptyView(
            title: 'No Engine history',
            body: '등급 계산 후 자동 저장.\n'
                '다음 Engine 측정부터 시계열 축적.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
          itemCount: rows.length + 1,
          separatorBuilder: (_, i) => i == 0
              ? const SizedBox(height: FacingTokens.sp2)
              : const Divider(height: 1, color: FacingTokens.border),
          itemBuilder: (_, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.all(FacingTokens.sp4),
                child: _EngineSparkline(records: rows),
              );
            }
            return _EngineRow(record: rows[i - 1]);
          },
        );
      },
    );
  }
}

class _EngineSparkline extends StatelessWidget {
  final List<EngineSnapshotRecord> records;
  const _EngineSparkline({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();
    // records는 scored_at DESC. sparkline은 시간 오름차순으로 뒤집어 사용.
    final ordered = records.reversed.toList();
    final scores = ordered.map((r) => r.overallScore).toList();
    final minV = scores.reduce((a, b) => a < b ? a : b);
    final maxV = scores.reduce((a, b) => a > b ? a : b);
    final latest = ordered.last;
    return Container(
      padding: const EdgeInsets.all(FacingTokens.sp4),
      decoration: BoxDecoration(
        color: FacingTokens.surface,
        borderRadius: BorderRadius.circular(FacingTokens.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('OVERALL SCORE', style: FacingTokens.micro),
              Text('${records.length} points', style: FacingTokens.micro),
            ],
          ),
          const SizedBox(height: FacingTokens.sp2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(latest.overallScore.toStringAsFixed(1),
                  style: FacingTokens.display),
              const SizedBox(width: FacingTokens.sp2),
              Text('latest', style: FacingTokens.caption),
            ],
          ),
          const SizedBox(height: FacingTokens.sp3),
          SizedBox(
            height: 56,
            child: CustomPaint(
              painter: _SparkPainter(
                points: scores,
                minV: minV,
                maxV: maxV == minV ? minV + 1 : maxV,
              ),
              size: const Size(double.infinity, 56),
            ),
          ),
          const SizedBox(height: FacingTokens.sp2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('min ${minV.toStringAsFixed(1)}',
                  style: FacingTokens.micro),
              Text('max ${maxV.toStringAsFixed(1)}',
                  style: FacingTokens.micro),
            ],
          ),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> points;
  final double minV;
  final double maxV;
  _SparkPainter({required this.points, required this.minV, required this.maxV});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      // 단일 포인트 → 가운데 점
      final p = Paint()
        ..color = FacingTokens.accent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 3, p);
      return;
    }
    final range = maxV - minV;
    final stepX = size.width / (points.length - 1);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final norm = (points[i] - minV) / range;
      final y = size.height - norm * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final line = Paint()
      ..color = FacingTokens.accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, line);

    final dot = Paint()
      ..color = FacingTokens.accent
      ..style = PaintingStyle.fill;
    final lastX = (points.length - 1) * stepX;
    final lastNorm = (points.last - minV) / range;
    final lastY = size.height - lastNorm * size.height;
    canvas.drawCircle(Offset(lastX, lastY), 3.5, dot);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.points != points || old.minV != minV || old.maxV != maxV;
}

class _EngineRow extends StatelessWidget {
  final EngineSnapshotRecord record;
  const _EngineRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final tier = Tier.fromOverallNumber(record.overallNumber);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: FacingTokens.sp4, vertical: FacingTokens.sp3),
      child: Row(
        children: [
          TierBadge(tier: tier),
          const SizedBox(width: FacingTokens.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score ${record.overallScore.toStringAsFixed(1)}',
                    style: FacingTokens.body.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 2),
                Text(_formatDate(record.scoredAt),
                    style: FacingTokens.caption),
              ],
            ),
          ),
          Text('${record.itemsUsed} items', style: FacingTokens.micro),
        ],
      ),
    );
  }
}

class _WodTab extends StatelessWidget {
  final Future<List<WodHistoryItem>>? future;
  final VoidCallback onRetry;
  const _WodTab({required this.future, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WodHistoryItem>>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: Text('Loading', style: FacingTokens.body));
        }
        if (snap.hasError) {
          return _ErrorView(error: snap.error, onRetry: onRetry);
        }
        final rows = snap.data ?? const [];
        if (rows.isEmpty) {
          return const _EmptyView(
            title: 'No WOD records',
            body: 'WOD 계산 후 자동 저장.\n'
                'Split · Burst · 예상 완주 시간 전부 보존.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp2),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final r = rows[i];
            return InkWell(
              onTap: () => Navigator.of(context)
                  .pushNamed('/history/detail', arguments: r.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: FacingTokens.sp4,
                    vertical: FacingTokens.sp3),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.wodType.toUpperCase(),
                              style: FacingTokens.body.copyWith(
                                fontWeight: FontWeight.w800,
                              )),
                          const SizedBox(height: 2),
                          Text(_formatDate(r.createdAt),
                              style: FacingTokens.caption),
                        ],
                      ),
                    ),
                    Text(r.estimatedTotalDisplay, style: FacingTokens.h3),
                    const Icon(Icons.chevron_right,
                        color: FacingTokens.muted, size: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String title;
  final String body;
  const _EmptyView({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FacingTokens.sp5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: FacingTokens.h3),
            const SizedBox(height: FacingTokens.sp2),
            Text(body,
                style: FacingTokens.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final msg = error is AppException
        ? (error as AppException).messageKo
        : '로딩 실패.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FacingTokens.sp5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg, style: FacingTokens.body),
            const SizedBox(height: FacingTokens.sp3),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  final local = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
