import '../../core/api_client.dart';
import '../../core/exception.dart';
import 'history_models.dart';

/// HistoryRepository -- /api/v1/history/* 엔드포인트 래퍼.
/// 오프라인 시 AppException(code=NETWORK) 발생 → UI에서 fallback 처리.
class HistoryRepository {
  final ApiClient api;
  HistoryRepository(this.api);

  Future<List<EngineSnapshotRecord>> listEngineSnapshots({int limit = 50}) async {
    final list = await api.getList('/api/v1/history/engine?limit=$limit');
    return list
        .whereType<Map<String, dynamic>>()
        .map(EngineSnapshotRecord.fromJson)
        .toList();
  }

  Future<int> saveEngineSnapshot(Map<String, dynamic> body) async {
    final data = await api.post('/api/v1/history/engine', body);
    return (data['record_id'] as num?)?.toInt() ?? 0;
  }

  Future<List<WodHistoryItem>> listWodHistory({int limit = 20}) async {
    final list = await api.getList('/api/v1/history/wod?limit=$limit');
    return list
        .whereType<Map<String, dynamic>>()
        .map(WodHistoryItem.fromJson)
        .toList();
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
