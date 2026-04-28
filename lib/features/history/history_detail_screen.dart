import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/exception.dart';
import '../../core/theme.dart';
import 'history_repository.dart';

class HistoryDetailScreen extends StatefulWidget {
  final int recordId;
  const HistoryDetailScreen({super.key, required this.recordId});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    final repo = HistoryRepository(context.read<ApiClient>());
    _future = repo.getWodDetail(widget.recordId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Record #${widget.recordId}')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: Text('Loading', style: FacingTokens.body));
          }
          if (snap.hasError) {
            // /go 전수조사: 원본 exception toString 노출 차단.
            final e = snap.error;
            final msg = e is AppException ? e.messageKo : '기록 로딩 실패.';
            return Padding(
              padding: const EdgeInsets.all(FacingTokens.sp4),
              child: Text(msg, style: FacingTokens.body),
            );
          }
          // QA B-FB-4: snap.data null 방어.
          final d = snap.data;
          if (d == null) {
            return const Padding(
              padding: EdgeInsets.all(FacingTokens.sp4),
              child: Text('History 데이터 없음.', style: FacingTokens.body),
            );
          }
          final wodRaw = d['wod'];
          if (wodRaw is! Map<String, dynamic>) {
            return const Padding(
              padding: EdgeInsets.all(FacingTokens.sp4),
              child: Text('History 형식 오류.', style: FacingTokens.body),
            );
          }
          final wod = wodRaw;
          final plan = d['plan'] is Map<String, dynamic>
              ? d['plan'] as Map<String, dynamic>
              : null;
          return ListView(
            padding: const EdgeInsets.all(FacingTokens.sp4),
            children: [
              Text((wod['wod_type'] ?? '').toString().toUpperCase(),
                  style: FacingTokens.h3),
              const SizedBox(height: FacingTokens.sp1),
              Text(_formatDate(wod['created_at']?.toString()),
                  style: FacingTokens.caption),
              const SizedBox(height: FacingTokens.sp4),
              if (plan != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(_fmtTime(plan['estimated_total_sec']),
                        style: FacingTokens.display),
                    const SizedBox(width: FacingTokens.sp2),
                    const Text('예상', style: FacingTokens.caption),
                  ],
                ),
                if (plan['grade'] != null)
                  Text('Grade ${plan['grade']}',
                      style: FacingTokens.caption),
                const SizedBox(height: FacingTokens.sp5),
                ...((plan['segments'] as List? ?? const []))
                    .whereType<Map<String, dynamic>>()
                    .map((s) => _SegmentCard(seg: s)),
              ] else
                const Text('페이싱 플랜 없음.',
                    style: FacingTokens.caption),
              const SizedBox(height: FacingTokens.sp5),
              const Text('ITEMS', style: FacingTokens.sectionLabel),
              const SizedBox(height: FacingTokens.sp2),
              ...((wod['items'] as List? ?? const []))
                  .whereType<Map<String, dynamic>>()
                  .map((it) => _ItemLine(it: it)),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentCard extends StatelessWidget {
  final Map<String, dynamic> seg;
  const _SegmentCard({required this.seg});

  @override
  Widget build(BuildContext context) {
    final isExplosion = seg['is_explosion'] == true;
    final splits = (seg['split_pattern'] as List? ?? const [])
        .whereType<num>()
        .map((n) => n.toInt())
        .toList();
    return Container(
      margin: const EdgeInsets.only(bottom: FacingTokens.sp3),
      padding: const EdgeInsets.all(FacingTokens.sp4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isExplosion ? FacingTokens.accent : FacingTokens.border,
          width: isExplosion ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(FacingTokens.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text((seg['movement_slug'] ?? '').toString(),
                  style: FacingTokens.h3),
              Text(_fmtTime(seg['estimated_sec']), style: FacingTokens.lead),
            ],
          ),
          const SizedBox(height: FacingTokens.sp3),
          if (splits.isNotEmpty)
            Text(splits.join('-'), style: FacingTokens.h1),
          if (seg['target_pace_sec_per_500m'] != null)
            Text('${seg['target_pace_sec_per_500m']}s / 500m',
                style: FacingTokens.h3),
          const SizedBox(height: FacingTokens.sp2),
          Text((seg['rationale_ko'] ?? '').toString(),
              style: FacingTokens.caption),
        ],
      ),
    );
  }
}

class _ItemLine extends StatelessWidget {
  final Map<String, dynamic> it;
  const _ItemLine({required this.it});

  @override
  Widget build(BuildContext context) {
    final name = (it['movement_name_en'] ?? it['movement_slug'] ?? '').toString();
    final reps = it['reps'];
    final dist = it['distance_m'];
    final load = it['load_value'];
    final unit = (it['load_unit'] ?? '').toString();
    final parts = <String>[];
    if (reps != null) parts.add('$reps reps');
    if (dist != null) parts.add('${dist}m');
    if (load != null) parts.add('$load $unit');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FacingTokens.sp1),
      child: Row(
        children: [
          Expanded(
              child: Text(name,
                  style: FacingTokens.body
                      .copyWith(fontWeight: FontWeight.w700))),
          Text(parts.join(' · '), style: FacingTokens.caption),
        ],
      ),
    );
  }
}

String _fmtTime(dynamic sec) {
  if (sec is! num) return '-';
  final m = sec.toInt() ~/ 60;
  final s = sec.toInt() % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String _formatDate(String? iso) {
  if (iso == null) return '';
  try {
    final dt = DateTime.parse(iso).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  } catch (_) {
    return iso;
  }
}
