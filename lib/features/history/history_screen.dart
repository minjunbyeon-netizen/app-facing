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
import 'history_search.dart';

/// 히스토리 — 내 수업 기록 목록 + 검색 (D84 · 2026-08-29).
///
/// 검색 칸은 **항상** 맨 위에 서 있다(로딩·빈 상태·에러에도) — 상태가 바뀌어도
/// 목록의 y 가 움직이지 않는다 (DESIGN-SSOT §레이아웃 안정성). 검색어가 비면 최근순,
/// 치면 연관도순 — 순위 규칙은 `history_search.dart` 한 곳.
class HistoryScreen extends StatefulWidget {
  /// 회원 셸 4번째 탭으로 얹힐 때는 자기 AppBar 를 그리지 않는다 — 상단바는 셸 하나
  /// (D85 · 2026-08-29 사용자 "하단 4번째 탭으로도 좀 줘"). 내 정보 메뉴에서 열면 false.
  final bool embedded;

  const HistoryScreen({super.key, this.embedded = false});

  /// 골든·안정성 검사 앵커.
  static const Key kSearch = Key('history-search');

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryRepository _repo;
  Future<List<WodHistoryItem>>? _wodFuture;
  final _searchCtrl = TextEditingController();
  String _query = '';

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
      // D84: 검색은 폰에서 고르므로 20건 창이 아니라 전부 받는다.
      _wodFuture = retainError(_repo.listAllWodHistory());
    });
  }

  @override
  void dispose() {
    _bus?.removeListener(_onSessionBump);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded ? null : const HkAppBar(title: '히스토리'),
      body: Column(
        children: [
          Padding(
            key: HistoryScreen.kSearch,
            padding: const EdgeInsets.fromLTRB(
              HyphenTokens.sp4,
              HyphenTokens.sp3,
              HyphenTokens.sp4,
              HyphenTokens.sp2,
            ),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: '기록 검색 — 동작 · 수업 · 날짜',
                prefixIcon: const Icon(Icons.search, size: 20),
                // 지울 자리는 늘 확보 — 글자가 생기고 사라져도 칸 폭이 안 흔들린다.
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: '지우기',
                  color: _query.isEmpty
                      ? Colors.transparent
                      : HyphenTokens.muted,
                  onPressed: _query.isEmpty
                      ? null
                      : () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                ),
              ),
            ),
          ),
          Expanded(
            child: _HistoryList(
              future: _wodFuture,
              query: _query,
              onRetry: _reload,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final Future<List<WodHistoryItem>>? future;
  final String query;
  final VoidCallback onRetry;
  const _HistoryList({
    required this.future,
    required this.query,
    required this.onRetry,
  });

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
        final all = snap.data ?? const [];
        if (all.isEmpty) {
          return const HkEmptyState(
            title: '수업 기록 없음',
            caption:
                '수업 기록 저장 시 자동 표시.\n'
                '결과·일시 전부 보존.',
          );
        }
        final rows = rankHistory(query, all);
        if (rows.isEmpty) {
          return HkEmptyState(
            title: '검색 결과 없음',
            caption: "'${query.trim()}' 에 맞는 기록 없음.",
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: HyphenTokens.sp2),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final r = rows[i];
            return InkWell(
              onTap: () => Navigator.of(
                context,
              ).pushNamed('/history/detail', arguments: r.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: HyphenTokens.sp4,
                  vertical: HyphenTokens.sp3,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // D84 — 제목은 검색이 보는 요약(수업 내용 첫 줄). 찾은
                          // 이유가 줄에서 바로 읽히도록 종류는 아랫줄로.
                          Text(
                            r.notes.trim().isEmpty
                                ? wodTypeLabel(r.wodType)
                                : r.summary,
                            style: HyphenTokens.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${wodTypeLabel(r.wodType)} · ${_formatDate(r.createdAt)}',
                            style: HyphenTokens.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: HyphenTokens.sp2),
                    Text(
                      r.estimatedTotalDisplay,
                      style: HyphenTokens.h3.copyWith(
                        fontFeatures: HyphenTokens.tabular,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: HyphenTokens.muted,
                      size: 20,
                    ),
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
