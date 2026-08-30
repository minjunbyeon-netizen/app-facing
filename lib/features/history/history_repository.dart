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

  /// 전부 읽기 — D84 검색은 폰에서 고르므로 목록이 잘려 있으면 안 된다. 서버 상한
  /// (limit ≤ 100) 만큼씩 끝까지 넘긴다. 짧은 페이지가 오면 끝.
  Future<List<WodHistoryItem>> listAllWodHistory() async {
    const page = 100;
    final all = <WodHistoryItem>[];
    for (var offset = 0; ; offset += page) {
      final p = await _page('/api/v1/history/wod?limit=$page&offset=$offset');
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
