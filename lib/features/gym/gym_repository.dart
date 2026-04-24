import '../../core/api_client.dart';
import '../../models/announcement.dart';
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
    String? scaledVersion,
    String? beginnerVersion,
    String? scaleGuide,
    List<WodRoundItem> roundsData = const [],
    int? rounds,
    int? timeCapSec,
  }) async {
    final data = await api.post('/api/v1/gyms/$gymId/wods', {
      'post_date': postDate,
      'wod_type': wodType,
      'content': content,
      if (scaledVersion != null && scaledVersion.isNotEmpty)
        'scaled_version': scaledVersion,
      if (beginnerVersion != null && beginnerVersion.isNotEmpty)
        'beginner_version': beginnerVersion,
      if (scaleGuide != null && scaleGuide.isNotEmpty) 'scale_guide': scaleGuide,
      if (roundsData.isNotEmpty)
        'rounds_data': roundsData.map((r) => r.toJson()).toList(),
      if (rounds != null) 'rounds': rounds,
      if (timeCapSec != null) 'time_cap_sec': timeCapSec,
    });
    return (data['wod_post_id'] as num).toInt();
  }

  // ---- v1.16 Sprint 16: 박스 내 리더보드 + 댓글 ----

  Future<List<GymWodResult>> listWodResults(int gymId, int wodId) async {
    final list = await api.getList(
      '/api/v1/gyms/$gymId/wods/$wodId/results',
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map(GymWodResult.fromJson)
        .toList();
  }

  Future<int> submitWodResult({
    required int gymId,
    required int wodId,
    int? timeSec,
    int? rounds,
    int? extraReps,
    String scaleLevel = 'rx',
    String notes = '',
  }) async {
    final data = await api.post('/api/v1/gyms/$gymId/wods/$wodId/results', {
      if (timeSec != null) 'time_sec': timeSec,
      if (rounds != null) 'rounds': rounds,
      if (extraReps != null) 'extra_reps': extraReps,
      'scale_level': scaleLevel,
      'notes': notes,
    });
    return (data['result_id'] as num).toInt();
  }

  Future<List<GymWodComment>> listWodComments(int gymId, int wodId) async {
    final list = await api.getList(
      '/api/v1/gyms/$gymId/wods/$wodId/comments',
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map(GymWodComment.fromJson)
        .toList();
  }

  Future<int> postWodComment({
    required int gymId,
    required int wodId,
    required String body,
  }) async {
    final data = await api.post(
      '/api/v1/gyms/$gymId/wods/$wodId/comments',
      {'body': body},
    );
    return (data['comment_id'] as num).toInt();
  }

  Future<void> deleteWodComment({
    required int gymId,
    required int wodId,
    required int commentId,
  }) async {
    await api.delete(
      '/api/v1/gyms/$gymId/wods/$wodId/comments/$commentId',
    );
  }

  // ---- v1.16 Sprint 15: 공지·메시지 ----

  Future<List<GymAnnouncement>> listAnnouncements(int gymId) async {
    final list = await api.getList('/api/v1/gyms/$gymId/announcements');
    return list
        .whereType<Map<String, dynamic>>()
        .map(GymAnnouncement.fromJson)
        .toList();
  }

  Future<int> postAnnouncement({
    required int gymId,
    required String title,
    required String body,
    String priority = 'normal',
  }) async {
    final data = await api.post('/api/v1/gyms/$gymId/announcements', {
      'title': title,
      'body': body,
      'priority': priority,
    });
    return (data['announcement_id'] as num).toInt();
  }

  Future<void> deleteAnnouncement(int gymId, int id) async {
    await api.delete('/api/v1/gyms/$gymId/announcements/$id');
  }

  Future<List<GymMessageItem>> listMessages(int gymId, {String? withHash}) async {
    final qs = withHash == null || withHash.isEmpty
        ? ''
        : '?with=${Uri.encodeQueryComponent(withHash)}';
    final list = await api.getList('/api/v1/gyms/$gymId/messages$qs');
    return list
        .whereType<Map<String, dynamic>>()
        .map(GymMessageItem.fromJson)
        .toList();
  }

  Future<int> sendMessage({
    required int gymId,
    required String toHash,
    required String body,
  }) async {
    final data = await api.post('/api/v1/gyms/$gymId/messages', {
      'to_hash': toHash,
      'body': body,
    });
    return (data['message_id'] as num).toInt();
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
