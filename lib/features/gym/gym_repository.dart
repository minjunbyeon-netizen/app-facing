import '../../core/api_client.dart';
import '../../models/gym.dart';

/// v1.15.3: /api/v1/gyms/* 래퍼.
class GymRepository {
  final ApiClient api;
  GymRepository(this.api);

  Future<GymMembership> getMine() async {
    final data = await api.get('/api/v1/gyms/mine');
    return GymMembership.fromJson(data);
  }

  Future<List<GymSummary>> search(String query) async {
    final qs = Uri.encodeQueryComponent(query);
    final data = await api.getList('/api/v1/gyms/search?q=$qs');
    return data
        .whereType<Map<String, dynamic>>()
        .map(GymSummary.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> createGym({
    required String name,
    String location = '',
  }) {
    return api.post('/api/v1/gyms', {'name': name, 'location': location});
  }

  Future<String> join(int gymId) async {
    final data = await api.post('/api/v1/gyms/$gymId/join', {});
    return (data['status'] ?? 'pending').toString();
  }

  Future<List<GymMember>> listMembers(int gymId) async {
    final data = await api.getList('/api/v1/gyms/$gymId/members');
    return data
        .whereType<Map<String, dynamic>>()
        .map(GymMember.fromJson)
        .toList();
  }

  Future<String> decideMember({
    required int gymId,
    required int memberId,
    required String action, // approve | reject
  }) async {
    final data = await api.patch(
      '/api/v1/gyms/$gymId/members/$memberId',
      {'action': action},
    );
    return (data['status'] ?? '').toString();
  }

  Future<int> postWod({
    required int gymId,
    required String postDate,
    required String wodType,
    required String content,
    String? scaleGuide,
    int? rounds,
    int? timeCapSec,
  }) async {
    final data = await api.post('/api/v1/gyms/$gymId/wods', {
      'post_date': postDate,
      'wod_type': wodType,
      'content': content,
      if (scaleGuide != null && scaleGuide.isNotEmpty) 'scale_guide': scaleGuide,
      if (rounds != null) 'rounds': rounds,
      if (timeCapSec != null) 'time_cap_sec': timeCapSec,
    });
    return (data['wod_post_id'] as num).toInt();
  }

  Future<List<GymWodPost>> listWods({required int gymId, String? date}) async {
    final qs = date != null && date.isNotEmpty ? '?date=$date' : '';
    final data = await api.getList('/api/v1/gyms/$gymId/wods$qs');
    return data
        .whereType<Map<String, dynamic>>()
        .map(GymWodPost.fromJson)
        .toList();
  }

  Future<void> deleteWod({required int gymId, required int wodId}) async {
    await api.delete('/api/v1/gyms/$gymId/wods/$wodId');
  }
}
