import '../../core/api_client.dart';
import '../../models/achievement.dart';

/// v1.16: /api/v1/achievements* 래퍼.
class AchievementRepository {
  final ApiClient api;
  AchievementRepository(this.api);

  Future<AchievementSnapshot> list() async {
    final data = await api.get('/api/v1/achievements');
    return AchievementSnapshot.fromJson(data);
  }

  Future<List<AchievementUnlockResult>> check() async {
    final data = await api.post('/api/v1/achievements/check', {});
    final list = (data['newly_unlocked'] as List? ?? const []);
    return list
        .whereType<Map<String, dynamic>>()
        .map(AchievementUnlockResult.fromJson)
        .toList();
  }
}
