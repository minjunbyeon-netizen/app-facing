import '../../core/api_client.dart';
import '../../models/announcement.dart';
import '../../models/coach_feedback.dart';
import '../../models/coach_profile.dart';
import '../../models/class_template.dart';
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

  // 2026-08-27 — search() 삭제. 체육관 검색 화면은 v3.2 에서 제거됐고
  // (README §제거된 기능 대장 7) 이 메서드 호출처가 0건이었다.
  // 서버 라우트 GET /api/v1/gyms/search 는 sanity_check·페르소나 테스트가
  // 아직 쓰므로 백엔드에는 남아 있다.

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

  /// 회원 실제 출석을 일자별로 조회 (gym_attendances 기반).
  /// 개인 페이싱 계산 기록(/history/wod)이 아닌 진짜 체크인. v1.25 (2026-06-09).
  /// 반환: 날짜(local 자정) → 그 날 체크인 횟수.
  Future<Map<DateTime, int>> listMyAttendances() async {
    final list = await api.getList('/api/v1/member/attendances');
    final map = <DateTime, int>{};
    for (final e in list.whereType<Map<String, dynamic>>()) {
      final ds = (e['date'] as String?)?.split('-');
      if (ds == null || ds.length != 3) continue;
      final y = int.tryParse(ds[0]);
      final m = int.tryParse(ds[1]);
      final d = int.tryParse(ds[2]);
      if (y == null || m == null || d == null) continue;
      map[DateTime(y, m, d)] = (e['count'] as num?)?.toInt() ?? 0;
    }
    return map;
  }

  // 2026-08-27 — updateGymProfile 삭제. PATCH /api/v1/gyms/{id}/profile 은
  // 살아 있지만 부르는 창구는 PC 코치 웹 하나다. 폰에는 편집 화면이 없어
  // 이 메서드와 GymState.updateGymProfile 둘 다 호출처가 0건이었다.

  // v1.16.2 (2026-05-24) — 코치 프로필 endpoint 5개.
  // ARCHITECTURE_BRIEF §11.6 / docs/GYM_PROFILE_SCHEMA.md §3.
  /// 수업 안내(수업 종류) — D79 (2026-08-29). 서버는 원래 주고 있었고
  /// 부르는 곳만 없었다. 사용중(is_active)인 것만 온다.
  Future<List<ClassTemplate>> listClassTemplates(int gymId) async {
    final data = await api.get('/api/v1/member/gyms/$gymId/class-templates');
    final raw = data['items'];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(ClassTemplate.fromJson)
          .toList();
    }
    return const [];
  }

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
    final data = await api.patch('/api/v1/gyms/$gymId/coaches/$coachId', body);
    return CoachProfile.fromJson(data);
  }

  Future<List<String>> getCoachOffDays(int gymId, int coachId) async {
    final data = await api.get('/api/v1/gyms/$gymId/coaches/$coachId/off-days');
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
    return data.whereType<Map<String, dynamic>>().map(Locker.fromJson).toList();
  }

  Future<CoachProfile> createCoach({
    required int gymId,
    required int coachUserId,
    required String name,
  }) async {
    // 코치 '프로필'(공개 소개 카드) 생성. 코치 '계정' 생성
    // (POST /api/v1/admin/gyms/<id>/coaches) 과는 다른 엔드포인트다 —
    // 2026-08-12 백엔드에서 두 기능의 URL 충돌을 풀며 이쪽이 /api/v1/gyms/ 로 이동.
    final data = await api.post('/api/v1/gyms/$gymId/coaches', {
      'coach_user_id': coachUserId,
      'name': name,
    });
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
    final data = await api.patch('/api/v1/gyms/$gymId/members/$memberId', {
      'action': action,
    });
    return (data['status'] ?? '').toString();
  }

  // ---- v1.16 Sprint 16: 박스 내 리더보드 + 댓글 ----

  Future<List<GymWodResult>> listWodResults(int gymId, int wodId) async {
    final list = await api.getList('/api/v1/gyms/$gymId/wods/$wodId/results');
    return list
        .whereType<Map<String, dynamic>>()
        .map(GymWodResult.fromJson)
        .toList();
  }

  /// v3.4 — strength 무게(+reps) 전송, 서버 비교 메시지·PR 판정 수신.
  /// comparisonMessage 는 서버가 완성한 한 문장 ("지난 기록보다 42초 단축 — PR!").
  /// 첫 기록이면 null (계산은 전부 백엔드 — 앱 계산 0 원칙).
  /// (구 points_awarded 첫 제출 100P 는 2026-08-24 서버와 함께 폐기.)
  /// attendanceAdded — 이번 저장이 오늘 출석 행을 **새로** 만들었는지 (서버 `attended_on`
  /// 판정, 하루 1회). 앱은 이 값이 true 일 때만 '출석 +1' 이라고 말한다 (2026-08-30 2차 검증).
  Future<({int resultId, bool isPr, String? comparisonMessage, bool attendanceAdded})>
  submitWodResult({
    required int gymId,
    required int wodId,
    int? timeSec,
    int? rounds,
    int? extraReps,
    double? weightKg,
    int? weightReps,
    String? movement,
    String scaleLevel = 'rx',
    String notes = '',
    // D94 — 동작별 완료 값 [{movement_id, name, reps, load_kg, scaled}]. null 이면 키를
    // 보내지 않는다(서버가 종전 값 유지). 판정은 서버 normalize_result_movements 한 곳.
    List<Map<String, dynamic>>? movements,
  }) async {
    final data = await api.post('/api/v1/gyms/$gymId/wods/$wodId/results', {
      'time_sec': ?timeSec,
      'rounds': ?rounds,
      'extra_reps': ?extraReps,
      'weight_kg': ?weightKg,
      'weight_reps': ?weightReps,
      'movement': ?movement,
      'scale_level': scaleLevel,
      'notes': notes,
      'movements': ?movements,
    });
    final comparison = data['comparison'];
    return (
      resultId: (data['result_id'] as num).toInt(),
      isPr: data['is_pr'] == true,
      comparisonMessage: (comparison is Map<String, dynamic>)
          ? comparison['message']?.toString()
          : null,
      attendanceAdded: data['attendance_added'] == true,
    );
  }

  /// Q3 (v3.4) — 이 수업과 같은 비교 그룹의 내 과거 기록 (라벨 서버 완성).
  Future<({String kind, List<WodMyHistoryItem> items})> wodMyHistory(
    int gymId,
    int wodId,
  ) async {
    final data = await api.get('/api/v1/gyms/$gymId/wods/$wodId/my-history');
    final raw = data['items'];
    final items = (raw is List)
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(WodMyHistoryItem.fromJson)
              .toList()
        : <WodMyHistoryItem>[];
    return (kind: (data['kind'] ?? '').toString(), items: items);
  }

  /// Q3 (v3.4) — 1RM 보드 (리프트별 역대 최고 무게, 서버 집계).
  Future<List<StrengthBoardEntry>> strengthBoard(int gymId) async {
    final list = await api.getList('/api/v1/gyms/$gymId/strength-board');
    return list
        .whereType<Map<String, dynamic>>()
        .map(StrengthBoardEntry.fromJson)
        .toList();
  }

  /// P3 — 도전 카드: 활성 규칙별 이번 주기 진행률·대기 건수 (서버 완성).
  Future<List<RewardProgress>> rewardProgress() async {
    final list = await api.getList('/api/v1/member/me/reward-progress');
    return list
        .whereType<Map<String, dynamic>>()
        .map(RewardProgress.fromJson)
        .toList();
  }

  /// P3 — [인증하기]: custom 행동 인증 (1일 1회 — 중복은 409 AppException).
  Future<({String status, List<int> grantedRules})> logRewardAction(
    int ruleId, {
    String note = '',
  }) async {
    final data = await api.post('/api/v1/member/reward-rules/$ruleId/log', {
      'note': note,
    });
    final raw = data['granted_rules'];
    final granted = (raw is List)
        ? raw.whereType<num>().map((e) => e.toInt()).toList()
        : <int>[];
    return (status: (data['status'] ?? '').toString(), grantedRules: granted);
  }

  Future<List<GymWodComment>> listWodComments(int gymId, int wodId) async {
    final list = await api.getList('/api/v1/gyms/$gymId/wods/$wodId/comments');
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
    final data = await api.post('/api/v1/gyms/$gymId/wods/$wodId/comments', {
      'body': body,
    });
    return (data['comment_id'] as num).toInt();
  }

  Future<void> deleteWodComment({
    required int gymId,
    required int wodId,
    required int commentId,
  }) async {
    await api.delete('/api/v1/gyms/$gymId/wods/$wodId/comments/$commentId');
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

  // ---- v1.16 Sprint 17: Coach Feedback ----

  Future<List<CoachFeedback>> listCoachFeedback(int gymId, int wodId) async {
    final list = await api.getList('/api/v1/gyms/$gymId/wods/$wodId/feedback');
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
    final data = await api.post('/api/v1/gyms/$gymId/wods/$wodId/feedback', {
      'member_hash': memberHash,
      'body': body,
    });
    return (data['feedback_id'] as num).toInt();
  }

  Future<void> deleteCoachFeedback({
    required int gymId,
    required int wodId,
    required int feedbackId,
  }) async {
    await api.delete('/api/v1/gyms/$gymId/wods/$wodId/feedback/$feedbackId');
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
