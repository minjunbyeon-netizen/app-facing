import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/engine_decay.dart';
import '../../core/exception.dart';
import '../../core/scoring.dart';
import '../../core/theme.dart';
import '../../core/tier.dart';
import '../../core/wod_session_bus.dart';
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
  /// /go Tier 3: WOD 세션 종료 시 자동 reload — attendance_screen 패턴 동일.
  WodSessionBus? _bus;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
    _repo = HistoryRepository(context.read<ApiClient>());
    _reload();
    _bus = context.read<WodSessionBus>();
    _bus?.addListener(_onSessionBump);
  }

  void _onSessionBump() {
    if (!mounted) return;
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
    _bus?.removeListener(_onSessionBump);
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

/// v1.16 Sprint 7b U3: 시간축 Engine 라인차트.
/// 기존 56px sparkline → 160px 정식 차트 (0~100 스케일 · 날짜 라벨).
class _EngineSparkline extends StatelessWidget {
  final List<EngineSnapshotRecord> records;
  const _EngineSparkline({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();
    final ordered = [...records]
      ..sort((a, b) => a.scoredAt.compareTo(b.scoredAt));
    final scores100 =
        ordered.map((r) => engineScoreTo100(r.overallScore)).toList();
    final firstDate = ordered.first.scoredAt.toLocal();
    final lastDate = ordered.last.scoredAt.toLocal();
    final latest = ordered.last;
    final first = ordered.first;
    final deltaFromStart =
        engineScoreTo100(latest.overallScore) -
            engineScoreTo100(first.overallScore);

    // v1.20 Phase 2.5: EngineDecay 표시. 최신 측정 30일 초과 시 STALE + 감산 안내.
    final daysSinceLast = DateTime.now()
        .toUtc()
        .difference(latest.scoredAt.toUtc())
        .inDays;
    final decayLabel = EngineDecay.statusLabel(daysSinceLast);
    final decayCaption = EngineDecay.statusCaption(daysSinceLast);

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
              const Text('ENGINE SCORE', style: FacingTokens.sectionLabel),
              Row(
                children: [
                  if (decayLabel != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: FacingTokens.warning, width: 1),
                        borderRadius: BorderRadius.circular(FacingTokens.r1),
                      ),
                      child: Text(
                        decayLabel,
                        style: FacingTokens.microLabel.copyWith(
                          color: FacingTokens.warning,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: FacingTokens.sp2),
                  ],
                  Text('${records.length} points',
                      style: FacingTokens.micro),
                ],
              ),
            ],
          ),
          if (decayCaption != null) ...[
            const SizedBox(height: 2),
            Text(decayCaption, style: FacingTokens.caption),
          ],
          const SizedBox(height: FacingTokens.sp2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${engineScoreTo100(latest.overallScore)}',
                  style: FacingTokens.display),
              const SizedBox(width: FacingTokens.sp2),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('/ 100', style: FacingTokens.caption),
              ),
              const Spacer(),
              if (records.length > 1)
                Text(
                  // v1.19 차수 5 (B-LW-9): V4 그래픽 기호 → 화살표만 허용.
                  deltaFromStart > 0
                      ? '→ +$deltaFromStart'
                      : (deltaFromStart < 0
                          ? '→ $deltaFromStart'
                          : 'Hold.'),
                  style: FacingTokens.caption.copyWith(
                    color: deltaFromStart > 0
                        ? FacingTokens.success
                        : (deltaFromStart < 0
                            ? FacingTokens.warning
                            : FacingTokens.muted),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: FacingTokens.sp4),
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _TimeSeriesPainter(points: scores100),
              size: const Size(double.infinity, 160),
            ),
          ),
          const SizedBox(height: FacingTokens.sp2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatShort(firstDate), style: FacingTokens.micro),
              Text('since start', style: FacingTokens.micro),
              Text(_formatShort(lastDate), style: FacingTokens.micro),
            ],
          ),
        ],
      ),
    );
  }

  String _formatShort(DateTime d) =>
      '${d.year.toString().substring(2)}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

/// v1.16 Sprint 7b U3: 고정 0~100 스케일 시간축 차트.
/// 기준선(0·50·100) + 외곽 그리드 + accent 라인 + 최신 포인트 강조.
class _TimeSeriesPainter extends CustomPainter {
  final List<int> points;
  _TimeSeriesPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = FacingTokens.border
      ..strokeWidth = 0.5;
    for (final v in [0, 50, 100]) {
      final y = size.height - (v / 100 * size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (points.isEmpty) return;
    if (points.length == 1) {
      final y = size.height - (points[0] / 100 * size.height);
      canvas.drawCircle(
        Offset(size.width / 2, y),
        4,
        Paint()..color = FacingTokens.accent,
      );
      return;
    }
    final stepX = size.width / (points.length - 1);
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = stepX * i;
      final y = size.height - (points[i] / 100 * size.height);
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
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // 최신 포인트 강조
    final lastX = stepX * (points.length - 1);
    final lastY = size.height - (points.last / 100 * size.height);
    canvas.drawCircle(
        Offset(lastX, lastY), 4, Paint()..color = FacingTokens.accent);
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
  bool shouldRepaint(covariant _TimeSeriesPainter old) {
    // QA B-PF-3: 리스트 참조(==) 비교 시 매 build 마다 새 List 가 들어와 항상 repaint.
    // 동일 길이 + 모든 원소 동일 시 skip.
    if (identical(old.points, points)) return false;
    if (old.points.length != points.length) return true;
    for (var i = 0; i < points.length; i++) {
      if (old.points[i] != points[i]) return true;
    }
    return false;
  }
}

// v1.16 Sprint 7b U3: _SparkPainter 제거 — _TimeSeriesPainter로 대체.

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
                      fontFeatures: FacingTokens.tabular,
                    )),
                const SizedBox(height: FacingTokens.sp1),
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
          separatorBuilder: (_, _) => const Divider(height: 1),
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
                    Text(r.estimatedTotalDisplay,
                        style: FacingTokens.h3.copyWith(
                          fontFeatures: FacingTokens.tabular,
                        )),
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
