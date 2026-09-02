import '../../core/api_client.dart';
import 'history_models.dart';

/// HistoryRepository -- `/api/v1/history/wod*` 읽기 래퍼 (D91 · 2026-08-30).
///
/// **읽기만 한다.** 결과 저장 창구는 `GymRepository.submitWodResult`
/// (`POST /gyms/<g>/wods/<post>/results`) 하나 — 서버의 그 결과 행이 곧 히스토리다.
/// (구 `saveWodHistory`/`deleteWodRecord` — 엔진 표에 따로 쓰던 길 — 는 삭제.)
/// 오프라인 시 AppException(code=NETWORK) 발생 → UI에서 fallback 처리.
class HistoryRepository {
  final ApiClient api;
  HistoryRepository(this.api);

  /// 첫 페이지 + meta(total·pr_count·streak_days). 홈 레벨 카드가 쓴다.
  Future<WodHistoryPage> listWodHistory({int limit = 20}) async {
    return _page('/api/v1/history/wod?limit=$limit');
  }

  /// 전부 읽기 — 서버 상한(limit ≤ 100) 만큼씩 끝까지 넘긴다. 짧은 페이지가 오면 끝.
  ///
  /// D95 (2026-08-30 사용자 "동작 검색을 서버가 하게"): `query` 가 있으면 서버가 **연관도순**으로
  /// 세워 준다 (정의 = 서버 `services/history_search.py` 하나 — 동작 사전 번호로도 맞춘다).
  /// `movementId`(2026-09-02) 는 동작 사전 번호 **직접 필터** — 그 동작이 든 기록만, 판정은
  /// 서버 `program_lines.result_movement_ids` 한 곳. 폰은 받은 순서 그대로 보여 준다.
  /// 필터·검색 키를 맨 앞에 두는 것은 골든 가짜(startsWith) 규약.
  Future<List<WodHistoryItem>> listAllWodHistory({
    String query = '',
    int? movementId,
  }) async {
    const page = 100;
    final q = query.trim();
    final params = [
      if (movementId != null) 'movement_id=$movementId',
      if (q.isNotEmpty) 'q=${Uri.encodeQueryComponent(q)}',
    ];
    final head = params.isEmpty
        ? '/api/v1/history/wod?'
        : '/api/v1/history/wod?${params.join('&')}&';
    final all = <WodHistoryItem>[];
    for (var offset = 0; ; offset += page) {
      final p = await _page('${head}limit=$page&offset=$offset');
      all.addAll(p.items);
      if (p.items.length < page) break;
    }
    return all;
  }

  Future<Map<String, dynamic>> getWodDetail(int resultId) {
    return api.get('/api/v1/history/wod/$resultId');
  }

  Future<WodHistoryPage> _page(String path) async {
    final r = await api.getPage(path);
    final items = r.items
        .whereType<Map<String, dynamic>>()
        .map(WodHistoryItem.fromJson)
        .toList();
    int n(String k) => (r.meta[k] as num?)?.toInt() ?? 0;
    return WodHistoryPage(
      items: items,
      total: r.meta.containsKey('total') ? n('total') : items.length,
      prCount: n('pr_count'),
      streakDays: n('streak_days'),
    );
  }
}
