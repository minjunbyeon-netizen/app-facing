import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/futures.dart';
import '../../core/theme.dart';
import '../../core/wod_session_bus.dart';
import '../../widgets/hkit.dart';
import 'history_models.dart';
import 'history_repository.dart';
import '../../core/time_format.dart';

/// 히스토리 — 내 수업 기록 목록 + 검색 (D84 · 2026-08-29).
///
/// 검색 칸은 **항상** 맨 위에 서 있다(로딩·빈 상태·에러에도) — 상태가 바뀌어도
/// 목록의 y 가 움직이지 않는다 (DESIGN-SSOT §레이아웃 안정성). 검색어가 비면 최근순,
/// 치면 연관도순 — 순위 규칙은 **서버** `services/history_search.py` 한 곳 (D95 · 2026-08-30
/// "동작 검색을 서버가 하게" — 동작 사전 번호로 맞추므로 '스쿼트' 로 쳐도 Back Squat 가 잡힌다).
/// 폰은 300ms 뒤 한 번 묻고 받은 순서 그대로 그린다.
///
/// D91 (2026-08-30): 목록의 글자는 전부 서버가 완성한 것(제목·그날 운동 요약·종류 라벨·
/// 점수 라벨·PR). 원천은 수업 결과 표 한 벌 — 결과를 저장하면 그 행이 여기 그대로 선다.
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
  final _filterCtrl = TextEditingController();
  String _query = '';

  /// 동작 필터 (2026-09-02) — 상세의 '동작별 기록 보기' 탭이 걸어 준다.
  /// 켜지면 검색 칸 자리에 **같은 규격의 읽기 전용 칸**이 서므로 y 가 안 움직인다.
  int? _movementId;
  String _movementName = '';
  Timer? _debounce;

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
      // 전부 받는다 (100건씩) — 검색어·동작 필터가 있으면 서버가 세운 순서·범위 그대로.
      _wodFuture = retainError(
        _repo.listAllWodHistory(query: _query, movementId: _movementId),
      );
    });
  }

  /// 상세를 열고, 동작 배지를 탭해 돌아오면 그 동작으로 목록을 거른다.
  Future<void> _openDetail(WodHistoryItem item) async {
    final result = await Navigator.of(
      context,
    ).pushNamed('/history/detail', arguments: item.id);
    if (!mounted || result is! WodMovementRef || result.id == null) return;
    _searchCtrl.clear();
    _filterCtrl.text = '동작: ${result.name}';
    setState(() {
      _query = '';
      _movementId = result.id;
      _movementName = result.name;
    });
    _reload();
  }

  void _clearMovementFilter() {
    setState(() {
      _movementId = null;
      _movementName = '';
    });
    _reload();
  }

  /// 글자마다 서버를 두드리지 않는다 — 멈춘 뒤 300ms 에 한 번.
  void _onQueryChanged(String v) {
    setState(() => _query = v);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _reload);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _bus?.removeListener(_onSessionBump);
    _searchCtrl.dispose();
    _filterCtrl.dispose();
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
            // 동작 필터가 켜지면 같은 규격의 읽기 전용 칸으로 스왑 — 목록 y 불변.
            child: _movementId != null
                ? TextField(
                    controller: _filterCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.filter_alt, size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: '필터 해제',
                        color: HyphenTokens.muted,
                        onPressed: _clearMovementFilter,
                      ),
                    ),
                  )
                : TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onChanged: _onQueryChanged,
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
                                _onQueryChanged('');
                              },
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: _HistoryList(
              future: _wodFuture,
              query: _query,
              movementName: _movementName,
              onRetry: _reload,
              onOpenDetail: _openDetail,
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
  final String movementName;
  final VoidCallback onRetry;
  final ValueChanged<WodHistoryItem> onOpenDetail;
  const _HistoryList({
    required this.future,
    required this.query,
    required this.movementName,
    required this.onRetry,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WodHistoryItem>>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const HkLoading.slot();
        }
        if (snap.hasError) {
          return HkErrorState.fromError(snap.error, onRetry: onRetry);
        }
        final rows = snap.data ?? const [];
        if (rows.isEmpty) {
          if (movementName.isNotEmpty) {
            return HkEmptyState(
              title: '검색 결과 없음',
              caption: "'$movementName' 동작 기록 없음.",
            );
          }
          if (query.trim().isNotEmpty) {
            return HkEmptyState(
              title: '검색 결과 없음',
              caption: "'${query.trim()}' 에 맞는 기록 없음.",
            );
          }
          return const HkEmptyState(
            title: '수업 기록 없음',
            caption:
                '수업 기록 저장 시 자동 표시.\n'
                '결과·일시 전부 보존.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: HyphenTokens.sp2),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) =>
              _HistoryRow(item: rows[i], onOpenDetail: onOpenDetail),
        );
      },
    );
  }
}

/// 한 줄 = 수업 이름 / 그날 운동 요약 / 종류·일시, 오른쪽에 점수 라벨(+PR).
/// 세 줄은 어느 기록에서나 다 있다(요약이 비면 메모·종류 라벨로 채운다) — 행 높이가 같다.
class _HistoryRow extends StatelessWidget {
  final WodHistoryItem item;
  final ValueChanged<WodHistoryItem> onOpenDetail;
  const _HistoryRow({required this.item, required this.onOpenDetail});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onOpenDetail(item),
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
                  Text(
                    item.heading,
                    style: HyphenTokens.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // D91 — 동작 검색이 맞춘 줄이 바로 읽히도록 그날 운동 요약을 둘째 줄에.
                  // D122 §7 — 한 줄에서 잘리면 파트가 여럿인 수업의 뒷부분이 통째로
                  // 안 보인다. 두 줄까지 편다.
                  Text(
                    item.subheading,
                    style: HyphenTokens.caption.copyWith(color: HyphenTokens.fg),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.wodTypeLabel} · ${_formatDate(item.createdAt)}',
                    style: HyphenTokens.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: HyphenTokens.sp2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.scoreDisplay,
                  style: HyphenTokens.h3.copyWith(
                    fontFeatures: HyphenTokens.tabular,
                  ),
                ),
                // D122 §7 — 파트가 여럿인 수업의 점수는 **그중 한 파트**의 값이다.
                // 어느 파트인지 안 밝히면 수업 전체 기록처럼 읽힌다 (라벨은 서버).
                // 자리는 늘 잡아 둔다 — 있는 행과 없는 행의 높이가 같아야 한다.
                SizedBox(
                  height: 15,
                  child: item.headlinePartLabel == null
                      ? null
                      : Text(
                          item.headlinePartLabel!,
                          style: HyphenTokens.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                // PR 자리는 늘 잡아 둔다 — 배지가 생겨도 점수 줄이 위로 밀리지 않는다.
                SizedBox(
                  height: 22,
                  child: item.isPr
                      ? const HkBadge('PR', color: HyphenTokens.primary)
                      : null,
                ),
              ],
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
  }
}

// _EmptyView·_ErrorView 삭제 — HkEmptyState·HkErrorState(widgets/hkit.dart)로 대체 (v1.27 UI SSOT).

String _formatDate(DateTime dt) {
  final local = dt.gym();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
