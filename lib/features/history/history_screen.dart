import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/futures.dart';
import '../../core/theme.dart';
import '../../core/wod_session_bus.dart';
import '../../widgets/hkit.dart';
import '../gym/wod_type_label.dart';
import 'history_models.dart';
import 'history_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryRepository _repo;
  Future<List<WodHistoryItem>>? _wodFuture;
  /// /go Tier 3: WOD 세션 종료 시 자동 reload — attendance_screen 패턴 동일.
  WodSessionBus? _bus;

  @override
  void initState() {
    super.initState();
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
      // retainError: 숨은 탭 future 가 에러로 완료돼도 unhandled 로 새지 않게.
      _wodFuture = retainError(_repo.listWodHistory(limit: 20));
    });
  }

  @override
  void dispose() {
    _bus?.removeListener(_onSessionBump);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('히스토리'),
      ),
      body: _WodTab(future: _wodFuture, onRetry: _reload),
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
          return const HkLoading();
        }
        if (snap.hasError) {
          return HkErrorState.fromError(snap.error, onRetry: onRetry);
        }
        final rows = snap.data ?? const [];
        if (rows.isEmpty) {
          return const HkEmptyState(
            title: '수업 기록 없음',
            caption: '수업 기록 저장 시 자동 표시.\n'
                '결과·일시 전부 보존.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: HyphenTokens.sp2),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final r = rows[i];
            return InkWell(
              onTap: () => Navigator.of(context)
                  .pushNamed('/history/detail', arguments: r.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: HyphenTokens.sp4,
                    vertical: HyphenTokens.sp3),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(wodTypeLabel(r.wodType),
                              style: HyphenTokens.body.copyWith(
                                fontWeight: FontWeight.w800,
                              )),
                          const SizedBox(height: 2),
                          Text(_formatDate(r.createdAt),
                              style: HyphenTokens.caption),
                        ],
                      ),
                    ),
                    Text(r.estimatedTotalDisplay,
                        style: HyphenTokens.h3.copyWith(
                          fontFeatures: HyphenTokens.tabular,
                        )),
                    const Icon(Icons.chevron_right,
                        color: HyphenTokens.muted, size: 20),
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

// _EmptyView·_ErrorView 삭제 — HkEmptyState·HkErrorState(widgets/hkit.dart)로 대체 (v1.27 UI SSOT).

String _formatDate(DateTime dt) {
  final local = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
