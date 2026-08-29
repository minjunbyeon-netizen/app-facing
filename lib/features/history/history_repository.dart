import '../../core/api_client.dart';
import '../../core/exception.dart';
import 'history_models.dart';

/// HistoryRepository -- /api/v1/history/* 엔드포인트 래퍼.
/// 오프라인 시 AppException(code=NETWORK) 발생 → UI에서 fallback 처리.
class HistoryRepository {
  final ApiClient api;
  HistoryRepository(this.api);

  Future<List<WodHistoryItem>> listWodHistory({int limit = 20}) async {
    final list = await api.getList('/api/v1/history/wod?limit=$limit');
    return list
        .whereType<Map<String, dynamic>>()
        .map(WodHistoryItem.fromJson)
        .toList();
  }

  /// 전부 읽기 — D84 검색은 폰에서 고르므로 목록이 잘려 있으면 안 된다. 서버 상한
  /// (limit ≤ 100) 만큼씩 끝까지 넘긴다. 짧은 페이지가 오면 끝.
  Future<List<WodHistoryItem>> listAllWodHistory() async {
    const page = 100;
    final all = <WodHistoryItem>[];
    for (var offset = 0; ; offset += page) {
      final list = await api.getList(
        '/api/v1/history/wod?limit=$page&offset=$offset',
      );
      final items = list
          .whereType<Map<String, dynamic>>()
          .map(WodHistoryItem.fromJson)
          .toList();
      all.addAll(items);
      if (items.length < page) break;
    }
    return all;
  }

  Future<Map<String, dynamic>> getWodDetail(int recordId) {
    return api.get('/api/v1/history/wod/$recordId');
  }

  Future<int> saveWodHistory(Map<String, dynamic> body) async {
    final data = await api.post('/api/v1/history/wod', body);
    return (data['record_id'] as num?)?.toInt() ?? 0;
  }

  Future<void> deleteWodRecord(int recordId) async {
    // dio에 직접 DELETE 없으니 api_client 확장 필요. MVP는 skip or POST /delete.
    // 여기서는 그냥 throw -- UI에서 disabled로 숨김.
    throw AppException('Delete not supported.', code: 'NOT_IMPLEMENTED');
  }
}
