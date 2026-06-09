import '../../core/api_client.dart';
import '../../models/announcement.dart';
import '../../models/coach_feedback.dart';
import '../../models/coach_profile.dart';
import '../../models/gym.dart';
import '../../models/locker.dart';
import '../../models/membership.dart';

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

  /// v1.22: 체육관 부가정보 업데이트 (코치 owner 만).
  /// body 에 포함된 키만 갱신 — 빈 문자열은 명시적 비우기.
  Future<GymProfile> updateGymProfile({
    required int gymId,
    String? phone,
    String? coachName,
    String? coachBio,
    String? classSchedule,
    String? motto,
    String? instagram,
    // v1.16.2 (2026-05-24) — 박스 프로필 페이지 9 필드
    String? priceSummary,
    String? paymentMethods,
    String? receiptInfo,
    String? parkingInfo,
    String? firstVisitGuide,
    String? attireGuide,
    String? wifiInfo,
    String? contactKakao,
    String? freeNotice,
  }) async {
    final body = <String, dynamic>{};
    if (phone != null) body['phone'] = phone;
    if (coachName != null) body['coach_name'] = coachName;
    if (coachBio != null) body['coach_bio'] = coachBio;
    if (classSchedule != null) body['class_schedule'] = classSchedule;
    if (motto != null) body['motto'] = motto;
    if (instagram != null) body['instagram'] = instagram;
    if (priceSummary != null) body['price_summary'] = priceSummary;
    if (paymentMethods != null) body['payment_methods'] = paymentMethods;
    if (receiptInfo != null) body['receipt_info'] = receiptInfo;
    if (parkingInfo != null) body['parking_info'] = parkingInfo;
    if (firstVisitGuide != null) body['first_visit_guide'] = firstVisitGuide;
    if (attireGuide != null) body['attire_guide'] = attireGuide;
    if (wifiInfo != null) body['wifi_info'] = wifiInfo;
    if (contactKakao != null) body['contact_kakao'] = contactKakao;
    if (freeNotice != null) body['free_notice'] = freeNotice;
    final data = await api.patch('/api/v1/gyms/$gymId/profile', body);
    final profileRaw = data['profile'];
    if (profileRaw is Map<String, dynamic>) {
      return GymProfile.fromJson(profileRaw);
    }
    return const GymProfile();
  }

  // v1.16.2 (2026-05-24) — 코치 프로필 endpoint 5개.
  // ARCHITECTURE_BRIEF §11.6 / docs/GYM_PROFILE_SCHEMA.md §3.
  Future<List<CoachProfile>> listCoaches(int gymId) async {
    final data = await api.get('/api/v1/gyms/$gymId/coaches');
    final raw = data['coaches'];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(CoachProfile.fromJson)
          .toList();
    }
    return const [];
  }

  Future<CoachProfile> getCoach(int gymId, int coachId) async {
    final data = await api.get('/api/v1/gyms/$gymId/coaches/$coachId');
    return CoachProfile.fromJson(data);
  }

  Future<CoachProfile> updateCoach({
    required int gymId,
    required int coachId,
    String? name,
    String? photoUrl,
    String? career,
    String? certifications,
    String? specialty,
    String? competitionRecords,
    String? demoVideoUrl,
    String? snsUrl,
    bool? ptBookable,
    int? displayOrder,
    List<String>? offDays,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (photoUrl != null) body['photo_url'] = photoUrl;
    if (career != null) body['career'] = career;
    if (certifications != null) body['certifications'] = certifications;
    if (specialty != null) body['specialty'] = specialty;
    if (competitionRecords != null) {
      body['competition_records'] = competitionRecords;
    }
    if (demoVideoUrl != null) body['demo_video_url'] = demoVideoUrl;
    if (snsUrl != null) body['sns_url'] = snsUrl;
    if (ptBookable != null) body['pt_bookable'] = ptBookable;
    if (displayOrder != null) body['display_order'] = displayOrder;
    if (offDays != null) body['off_days'] = offDays;
    final data = await api.patch(
      '/api/v1/gyms/$gymId/coaches/$coachId',
      body,
    );
    return CoachProfile.fromJson(data);
  }

  Future<List<String>> getCoachOffDays(int gymId, int coachId) async {
    final data =
        await api.get('/api/v1/gyms/$gymId/coaches/$coachId/off-days');
    final raw = data['off_days'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  // v1.16.2 (2026-05-24) — 본인 회원권·락커.
  Future<List<Membership>> listMyMemberships() async {
    final data = await api.getList('/api/v1/member/me/memberships');
    return data
        .whereType<Map<String, dynamic>>()
        .map(Membership.fromJson)
        .toList();
  }

  Future<List<Locker>> listMyLockers() async {
    final data = await api.getList('/api/v1/member/me/locker');
    return data
        .whereType<Map<String, dynamic>>()
        .map(Locker.fromJson)
        .toList();
  }

  Future<CoachProfile> createCoach({
    required int gymId,
    required int coachUserId,
    required String name,
  }) async {
    final data = await api.post(
      '/api/v1/admin/gyms/$gymId/coaches',
      {
        'coach_user_id': coachUserId,
        'name': name,
      },
    );
    return CoachProfile.fromJson(data);
  }

  Future<void> leaveGym(int gymId) async {
    await api.delete('/api/v1/gyms/$gymId/leave');
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
      'rounds': ?rounds,
      'time_cap_sec': ?timeCapSec,
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

  Future<({int resultId, int pointsAwarded})> submitWodResult({
    required int gymId,
    required int wodId,
    int? timeSec,
    int? rounds,
    int? extraReps,
    String scaleLevel = 'rx',
    String notes = '',
  }) async {
    final data = await api.post('/api/v1/gyms/$gymId/wods/$wodId/results', {
      'time_sec': ?timeSec,
      'rounds': ?rounds,
      'extra_reps': ?extraReps,
      'scale_level': scaleLevel,
      'notes': notes,
    });
    return (
      resultId: (data['result_id'] as num).toInt(),
      pointsAwarded: (data['points_awarded'] as num?)?.toInt() ?? 0,
    );
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

  // ---- v1.16 Sprint 15: 공지·메시지 (v1.19 P2 마케팅 피드 강화) ----

  Future<List<GymAnnouncement>> listAnnouncements(int gymId) async {
    final list = await api.getList('/api/v1/gyms/$gymId/announcements');
    return list
        .whereType<Map<String, dynamic>>()
        .map(GymAnnouncement.fromJson)
        .toList();
  }

  /// 회원 폰 타임라인 — 활성 공지만, 핀고정 우선 (v1.19 P2).
  Future<List<GymAnnouncement>> listMemberAnnouncements() async {
    final list = await api.getList('/api/v1/member/announcements');
    return list
        .whereType<Map<String, dynamic>>()
        .map(GymAnnouncement.fromJson)
        .toList();
  }

  Future<GymAnnouncement> postAnnouncementRich({
    required int gymId,
    required String title,
    required String body,
    String priority = 'normal',
    String category = 'notice',
    String visibleTo = 'all',
    String? ctaLabel,
    String? ctaUrl,
    bool pinned = false,
    String? startAt,
    String? endAt,
  }) async {
    final data = await api.post('/api/v1/coach/gyms/$gymId/announcements', {
      'title': title,
      'body': body,
      'priority': priority,
      'category': category,
      'visible_to': visibleTo,
      'cta_label': ?ctaLabel,
      'cta_url': ?ctaUrl,
      'pinned': pinned.toString(),
      'start_at': ?startAt,
      'end_at': ?endAt,
    });
    return GymAnnouncement.fromJson(data);
  }

  /// 레거시 호환 — 기존 코드에서 사용. 내부적으로 postAnnouncementRich 호출.
  Future<int> postAnnouncement({
    required int gymId,
    required String title,
    required String body,
    String priority = 'normal',
  }) async {
    final ann = await postAnnouncementRich(
      gymId: gymId,
      title: title,
      body: body,
      priority: priority,
    );
    return ann.id;
  }

  Future<GymAnnouncement> patchAnnouncement({
    required int id,
    String? title,
    String? body,
    String? priority,
    String? category,
    String? visibleTo,
    String? ctaLabel,
    String? ctaUrl,
    bool? pinned,
    String? endAt,
  }) async {
    final payload = <String, dynamic>{
      'title': ?title,
      'body': ?body,
      'priority': ?priority,
      'category': ?category,
      'visible_to': ?visibleTo,
      'cta_label': ?ctaLabel,
      'cta_url': ?ctaUrl,
      if (pinned != null) 'pinned': pinned.toString(),
      'end_at': ?endAt,
    };
    final data = await api.patch('/api/v1/coach/announcements/$id', payload);
    return GymAnnouncement.fromJson(data);
  }

  Future<void> deleteAnnouncement(int gymId, int id) async {
    await api.delete('/api/v1/coach/announcements/$id');
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

  // ---- v1.16 Sprint 17: Coach Feedback ----

  Future<List<CoachFeedback>> listCoachFeedback(int gymId, int wodId) async {
    final list = await api.getList(
      '/api/v1/gyms/$gymId/wods/$wodId/feedback',
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map(CoachFeedback.fromJson)
        .toList();
  }

  Future<int> upsertCoachFeedback({
    required int gymId,
    required int wodId,
    required String memberHash,
    required String body,
  }) async {
    final data = await api.post(
      '/api/v1/gyms/$gymId/wods/$wodId/feedback',
      {'member_hash': memberHash, 'body': body},
    );
    return (data['feedback_id'] as num).toInt();
  }

  Future<void> deleteCoachFeedback({
    required int gymId,
    required int wodId,
    required int feedbackId,
  }) async {
    await api
        .delete('/api/v1/gyms/$gymId/wods/$wodId/feedback/$feedbackId');
  }

  // ---- v1.16 Sprint 17: Member Requests ----

  Future<List<MemberRequest>> listMemberRequests(
    int gymId, {
    String? status,
  }) async {
    final qs = (status == null || status.isEmpty) ? '' : '?status=$status';
    final list = await api.getList('/api/v1/gyms/$gymId/requests$qs');
    return list
        .whereType<Map<String, dynamic>>()
        .map(MemberRequest.fromJson)
        .toList();
  }

  Future<int> sendMemberRequest({
    required int gymId,
    required String subject,
    required String body,
    int? wodPostId,
  }) async {
    final data = await api.post('/api/v1/gyms/$gymId/requests', {
      'subject': subject,
      'body': body,
      'wod_post_id': ?wodPostId,
    });
    return (data['request_id'] as num).toInt();
  }

  Future<void> respondMemberRequest({
    required int gymId,
    required int requestId,
    String? coachResponse,
    String? status,
  }) async {
    await api.patch('/api/v1/gyms/$gymId/requests/$requestId', {
      'coach_response': ?coachResponse,
      'status': ?status,
    });
  }

  /// 회원 → 코치 자유 메시지. 코치 NOTICE 탭 인박스에 note로 수신됨.
  /// [to] 지정 시 그 코치에게 (다중 코치). 미지정 시 박스 오너에게.
  Future<void> memberReport({
    required int gymId,
    required String message,
    int? wodId,
    String? to,
  }) async {
    await api.post('/api/v1/gym/$gymId/member-report', {
      'message': message,
      'wod_id': ?wodId,
      if (to != null && to.isNotEmpty) 'to': to,
    });
  }
}
