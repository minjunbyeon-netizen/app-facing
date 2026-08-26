// v1.15.3: 박스/코치 WOD 피드 DTO.

import '../core/app_clock.dart';
import '../core/time_format.dart';

class GymSummary {
  final int id;
  final String name;
  final String location;
  final int memberCount;
  final bool isOfficial;
  // v1.20 (E1 fix): 회원 시점 코치-DM 자동 thread 시작용. 백엔드가 응답에 포함.
  // null이면 회원이 코치 thread 시작 불가 (E1 BLOCKER 잔존).
  final String? ownerHash;
  // v1.22: 체육관 부가정보 (전화·코치·수업시간·모토). 미등록이면 null.
  final GymProfile? profile;

  const GymSummary({
    required this.id,
    required this.name,
    required this.location,
    required this.memberCount,
    this.isOfficial = false,
    this.ownerHash,
    this.profile,
  });

  factory GymSummary.fromJson(Map<String, dynamic> j) => GymSummary(
        id: (j['id'] as num).toInt(),
        name: (j['name'] ?? '').toString(),
        location: (j['location'] ?? '').toString(),
        memberCount: ((j['member_count'] ?? 0) as num).toInt(),
        isOfficial: (j['is_official'] == true) ||
            ((j['name'] ?? '').toString() == 'HYPHEN HQ'),
        ownerHash: j['owner_hash']?.toString(),
        profile: j['profile'] is Map<String, dynamic>
            ? GymProfile.fromJson(j['profile'] as Map<String, dynamic>)
            : null,
      );
}

/// v1.22: 체육관 부가정보. NOTICE 탭 + v1.16.2 박스 프로필 페이지 렌더용.
/// 모든 필드 nullable — 미등록 시 카드에서 빈 슬롯 처리.
class GymProfile {
  final String? phone;
  final String? coachName;
  final String? coachBio;
  final String? classSchedule;
  final String? motto;
  final String? instagram;
  final String? logoUrl;
  // v1.16.2 (2026-05-24) — 박스 프로필 페이지 9 필드 확장
  final String? priceSummary;
  final String? paymentMethods;
  final String? receiptInfo;
  final String? parkingInfo;
  final String? firstVisitGuide;
  final String? attireGuide;
  final String? wifiInfo;
  final String? contactKakao;
  final String? freeNotice;

  const GymProfile({
    this.phone,
    this.coachName,
    this.coachBio,
    this.classSchedule,
    this.motto,
    this.instagram,
    this.logoUrl,
    this.priceSummary,
    this.paymentMethods,
    this.receiptInfo,
    this.parkingInfo,
    this.firstVisitGuide,
    this.attireGuide,
    this.wifiInfo,
    this.contactKakao,
    this.freeNotice,
  });

  bool get isEmpty =>
      (phone ?? '').isEmpty &&
      (coachName ?? '').isEmpty &&
      (coachBio ?? '').isEmpty &&
      (classSchedule ?? '').isEmpty &&
      (motto ?? '').isEmpty &&
      (priceSummary ?? '').isEmpty &&
      (firstVisitGuide ?? '').isEmpty &&
      (freeNotice ?? '').isEmpty;

  factory GymProfile.fromJson(Map<String, dynamic> j) => GymProfile(
        phone: _s(j['phone']),
        coachName: _s(j['coach_name']),
        coachBio: _s(j['coach_bio']),
        classSchedule: _s(j['class_schedule']),
        motto: _s(j['motto']),
        instagram: _s(j['instagram']),
        logoUrl: _s(j['logo_url']),
        priceSummary: _s(j['price_summary']),
        paymentMethods: _s(j['payment_methods']),
        receiptInfo: _s(j['receipt_info']),
        parkingInfo: _s(j['parking_info']),
        firstVisitGuide: _s(j['first_visit_guide']),
        attireGuide: _s(j['attire_guide']),
        wifiInfo: _s(j['wifi_info']),
        contactKakao: _s(j['contact_kakao']),
        freeNotice: _s(j['free_notice']),
      );

  static String? _s(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }
}

/// 내 박스 소속 스냅샷. role ∈ {owner, member, null}. status ∈ {pending, approved, rejected, null}.
class GymMembership {
  final GymSummary? gym;
  final String? role;
  final String? status;
  /// 백엔드 gym_members.id — 클래스 예약·본인 식별용. owner 도 자기 row 있으면 채워짐.
  final int? memberId;
  /// PC 사장이 GymMemberProfile 에 입력한 본인 신원정보. 사장이 아직 등록 안 했으면 null.
  final MemberProfile? memberProfile;

  const GymMembership({
    this.gym,
    this.role,
    this.status,
    this.memberId,
    this.memberProfile,
  });

  bool get hasGym => gym != null;
  bool get isOwner => role == 'owner';
  bool get isApprovedMember => role == 'member' && status == 'approved';
  bool get isPending => role == 'member' && status == 'pending';
  bool get isRejected => role == 'member' && status == 'rejected';

  factory GymMembership.fromJson(Map<String, dynamic> j) {
    final gymRaw = j['gym'];
    final mp = j['member_profile'];
    return GymMembership(
      gym: gymRaw is Map<String, dynamic>
          ? GymSummary.fromJson(gymRaw)
          : null,
      role: j['role']?.toString(),
      status: j['status']?.toString(),
      memberId: (j['member_id'] as num?)?.toInt(),
      memberProfile: mp is Map<String, dynamic>
          ? MemberProfile.fromJson(mp)
          : null,
    );
  }

  static const GymMembership empty =
      GymMembership(gym: null, role: null, status: null);
}

/// PC 사장이 등록·편집한 회원 신원정보 (`gym_member_profiles` 테이블 mirror).
/// `/api/v1/gyms/mine` 응답의 `member_profile` 또는 `/api/v1/gyms/{id}/members[]` 항목에 포함.
class MemberProfile {
  final String? name;
  final String? gender;
  final String? birthDate; // YYYY-MM-DD
  final String? phone;
  final String? level;
  final String? preferredTimeSlot;
  final String? preferredCoachGender;
  final String? safetyNote;
  final String? note;
  final String? photoUrl;
  final String? email;
  final String? emergencyContact;
  final DateTime? updatedAt;

  const MemberProfile({
    this.name,
    this.gender,
    this.birthDate,
    this.phone,
    this.level,
    this.preferredTimeSlot,
    this.preferredCoachGender,
    this.safetyNote,
    this.note,
    this.photoUrl,
    this.email,
    this.emergencyContact,
    this.updatedAt,
  });

  bool get isEmpty =>
      (name ?? '').isEmpty &&
      (phone ?? '').isEmpty &&
      (level ?? '').isEmpty;

  factory MemberProfile.fromJson(Map<String, dynamic> j) => MemberProfile(
        name: _s(j['name']),
        gender: _s(j['gender']),
        birthDate: _s(j['birth_date']),
        phone: _s(j['phone']),
        level: _s(j['level']),
        preferredTimeSlot: _s(j['preferred_time_slot']),
        preferredCoachGender: _s(j['preferred_coach_gender']),
        safetyNote: _s(j['safety_note']),
        note: _s(j['note']),
        photoUrl: _s(j['photo_url']),
        email: _s(j['email']),
        emergencyContact: _s(j['emergency_contact']),
        updatedAt: j['updated_at'] == null
            ? null
            : tryParseServerTime(j['updated_at'].toString())?.toLocal(),
      );

  static String? _s(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }
}

class GymMember {
  final int id;
  final String deviceHashPrefix;
  final String? deviceHashFull; // v1.16 Sprint 15: 코치 조회 시만 전체 노출 (DM 송신용).
  final String status;
  final DateTime requestedAt;
  final DateTime? decidedAt;
  // v1.16 Sprint 12: 코치 대시보드 활동 통계.
  final DateTime? lastWodAt;
  final int totalSessions;
  final int streakDays;
  // PC 사장이 입력한 신원정보 (코치/owner 조회 시 1:1 매칭).
  final String? name;
  final String? level;
  final String? phone;
  final String? gender;
  final String? birthDate;
  final String? preferredTimeSlot;
  final String? preferredCoachGender;
  final String? safetyNote;
  final String? note;

  const GymMember({
    required this.id,
    required this.deviceHashPrefix,
    this.deviceHashFull,
    required this.status,
    required this.requestedAt,
    this.decidedAt,
    this.lastWodAt,
    this.totalSessions = 0,
    this.streakDays = 0,
    this.name,
    this.level,
    this.phone,
    this.gender,
    this.birthDate,
    this.preferredTimeSlot,
    this.preferredCoachGender,
    this.safetyNote,
    this.note,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  /// 오늘·어제 활동 여부. streak 끊김 경고용.
  int get daysSinceLastWod {
    if (lastWodAt == null) return 999;
    return appClock.now().difference(lastWodAt!).inDays;
  }

  bool get isDormant => isApproved && daysSinceLastWod >= 14;

  factory GymMember.fromJson(Map<String, dynamic> j) => GymMember(
        id: (j['id'] as num).toInt(),
        deviceHashPrefix: (j['device_hash_prefix'] ?? '').toString(),
        deviceHashFull: j['device_hash']?.toString(),
        status: (j['status'] ?? '').toString(),
        requestedAt: parseServerTime(j['requested_at'] as String).toLocal(),
        decidedAt: j['decided_at'] == null
            ? null
            : parseServerTime(j['decided_at'] as String).toLocal(),
        lastWodAt: j['last_wod_at'] == null
            ? null
            : parseServerTime(j['last_wod_at'] as String).toLocal(),
        totalSessions: ((j['total_sessions'] ?? 0) as num).toInt(),
        streakDays: ((j['streak_days'] ?? 0) as num).toInt(),
        name: _s(j['name']),
        level: _s(j['level']),
        phone: _s(j['phone']),
        gender: _s(j['gender']),
        birthDate: _s(j['birth_date']),
        preferredTimeSlot: _s(j['preferred_time_slot']),
        preferredCoachGender: _s(j['preferred_coach_gender']),
        safetyNote: _s(j['safety_note']),
        note: _s(j['note']),
      );

  /// 코치 화면 표시용 — 이름 있으면 이름, 없으면 device hash prefix.
  String get displayName => (name?.trim().isNotEmpty == true)
      ? name!.trim()
      : 'Member ${deviceHashPrefix.substring(0, deviceHashPrefix.length < 6 ? deviceHashPrefix.length : 6)}';

  static String? _s(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }
}

/// 라운드 내 동작 1개 (#3 동작 레벨 구조화, v1.25 2026-06-09).
/// 매그넘 레퍼런스의 "동작별 sets·reps·load·rest·영상" 행에 대응.
class WodMovementItem {
  final String name;
  final String slug;
  final int? sets;
  final String reps; // "10~12" · "21-15-9" 등 문자열
  final String loadValue;
  final String loadUnit;
  final int? restSec;
  final String videoUrl;

  const WodMovementItem({
    required this.name,
    this.slug = '',
    this.sets,
    this.reps = '',
    this.loadValue = '',
    this.loadUnit = '',
    this.restSec,
    this.videoUrl = '',
  });

  bool get hasVideo => videoUrl.isNotEmpty;

  /// "Barbell Reverse Lunge · 2×10~12 · 42kg · rest 60s" 형식 1줄.
  String get displayLine {
    final parts = <String>[name];
    if (sets != null && reps.isNotEmpty) {
      parts.add('$sets×$reps');
    } else if (sets != null) {
      parts.add('$sets sets');
    } else if (reps.isNotEmpty) {
      parts.add('$reps reps');
    }
    if (loadValue.isNotEmpty) parts.add('$loadValue$loadUnit');
    if (restSec != null) parts.add('rest ${restSec}s');
    return parts.join(' · ');
  }

  factory WodMovementItem.fromJson(Map<String, dynamic> j) => WodMovementItem(
        name: (j['name'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        sets: (j['sets'] as num?)?.toInt(),
        reps: (j['reps'] ?? '').toString(),
        loadValue: (j['load_value'] ?? '').toString(),
        loadUnit: (j['load_unit'] ?? '').toString(),
        restSec: (j['rest_sec'] as num?)?.toInt(),
        videoUrl: (j['video_url'] ?? '').toString(),
      );
}

class WodRoundItem {
  final String label;
  final String content;
  final int? timeCapSec;
  final List<WodMovementItem> movements;

  const WodRoundItem({
    required this.label,
    required this.content,
    this.timeCapSec,
    this.movements = const [],
  });

  bool get hasMovements => movements.isNotEmpty;

  factory WodRoundItem.fromJson(Map<String, dynamic> j) {
    final mvRaw = j['movements'];
    final mv = (mvRaw is List)
        ? mvRaw
            .whereType<Map<String, dynamic>>()
            .map(WodMovementItem.fromJson)
            .toList()
        : <WodMovementItem>[];
    return WodRoundItem(
      label: (j['label'] ?? '').toString(),
      content: (j['content'] ?? '').toString(),
      timeCapSec: (j['time_cap_sec'] as num?)?.toInt(),
      movements: mv,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'content': content,
        if (timeCapSec != null) 'time_cap_sec': timeCapSec,
      };
}

class GymWodPost {
  final int id;
  final String postDate; // YYYY-MM-DD
  final String wodType;
  final String content; // RX 버전
  final String? scaledVersion;
  final String? beginnerVersion;
  final String? scaleGuide;
  final List<WodRoundItem> roundsData;
  final int? rounds;
  final int? timeCapSec;
  // 결함 수정 4 (2026-08-20) — 이 수업의 내 기존 기록 요약 (서버 동봉).
  // null = 아직 기록 없음. 카드 '기록 완료' 배지 + 시트 프리필의 원천.
  final GymMyResult? myResult;
  final DateTime createdAt;
  // v1.23: 회원권 만료·미결제 잠금. true이면 content 비공개.
  // ('당일 공개' 미래 잠금은 v3.15 폐지 — 사유는 회원권 만료만.)
  final bool locked;

  // v3.16 (기록 UX 2·3) — 서버 추천: 기본 기록 종류 + 무게 동작 이름 후보.
  final String? scoreHint; // 'time' | 'rounds' | 'weight'
  final List<String> movementSuggestions;

  const GymWodPost({
    required this.id,
    required this.postDate,
    required this.wodType,
    required this.content,
    this.scaledVersion,
    this.beginnerVersion,
    this.scaleGuide,
    this.roundsData = const [],
    this.rounds,
    this.timeCapSec,
    this.myResult,
    required this.createdAt,
    this.locked = false,
    this.scoreHint,
    this.movementSuggestions = const [],
  });

  bool get hasVersions =>
      (scaledVersion != null && scaledVersion!.isNotEmpty) ||
      (beginnerVersion != null && beginnerVersion!.isNotEmpty);

  String get timeCapDisplay {
    if (timeCapSec == null) return '';
    final m = timeCapSec! ~/ 60;
    final s = timeCapSec! % 60;
    if (s == 0) return '${m}min cap';
    return '$m:${s.toString().padLeft(2, '0')} cap';
  }

  factory GymWodPost.fromJson(Map<String, dynamic> j) {
    final roundsRaw = j['rounds_data'];
    final rounds = (roundsRaw is List)
        ? roundsRaw
            .whereType<Map<String, dynamic>>()
            .map(WodRoundItem.fromJson)
            .toList()
        : <WodRoundItem>[];
    return GymWodPost(
      id: (j['id'] as num).toInt(),
      postDate: (j['post_date'] ?? '').toString(),
      wodType: (j['wod_type'] ?? '').toString(),
      content: (j['content'] ?? '').toString(),
      scaledVersion: j['scaled_version']?.toString(),
      beginnerVersion: j['beginner_version']?.toString(),
      scaleGuide: j['scale_guide']?.toString(),
      roundsData: rounds,
      rounds: (j['rounds'] as num?)?.toInt(),
      timeCapSec: (j['time_cap_sec'] as num?)?.toInt(),
      myResult: (j['my_result'] is Map<String, dynamic>)
          ? GymMyResult.fromJson(j['my_result'] as Map<String, dynamic>)
          : null,
      createdAt: parseServerTime(j['created_at'] as String).toLocal(),
      locked: j['locked'] == true,
      scoreHint: j['score_hint']?.toString(),
      movementSuggestions: (j['movement_suggestions'] is List)
          ? (j['movement_suggestions'] as List)
              .map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList()
          : const [],
    );
  }
}

/// v1.16 Sprint 16: WOD 리더보드 항목.
class GymWodResult {
  final int id;
  final int rank;
  final String deviceHashPrefix;
  final bool isMine;
  final int? timeSec;
  final int? rounds;
  final int? extraReps;
  // v3.4 — strength 최고 무게(+reps). 리더보드 표시 갭 수정 (2026-08-20 밤).
  final double? weightKg;
  final int? weightReps;
  final String scaleLevel; // rx · scaled · beginner
  final String notes;
  final DateTime createdAt;

  const GymWodResult({
    required this.id,
    required this.rank,
    required this.deviceHashPrefix,
    required this.isMine,
    this.timeSec,
    this.rounds,
    this.extraReps,
    this.weightKg,
    this.weightReps,
    required this.scaleLevel,
    required this.notes,
    required this.createdAt,
  });

  String get display {
    if (timeSec != null) {
      final m = timeSec! ~/ 60;
      final s = timeSec! % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    if (rounds != null) {
      final r = rounds!;
      final reps = extraReps ?? 0;
      if (reps > 0) return '$r+$reps';
      return '$r rounds';
    }
    if (weightKg != null && weightKg! > 0) {
      final w = weightKg!;
      final base =
          w == w.roundToDouble() ? '${w.toInt()}kg' : '${w}kg';
      return weightReps != null ? '$base×$weightReps' : base;
    }
    return '-';
  }

  factory GymWodResult.fromJson(Map<String, dynamic> j) => GymWodResult(
        id: (j['id'] as num).toInt(),
        rank: ((j['rank'] ?? 0) as num).toInt(),
        deviceHashPrefix: (j['device_hash_prefix'] ?? '').toString(),
        isMine: j['is_mine'] == true,
        timeSec: (j['time_sec'] as num?)?.toInt(),
        rounds: (j['rounds'] as num?)?.toInt(),
        extraReps: (j['extra_reps'] as num?)?.toInt(),
        weightKg: (j['weight_kg'] as num?)?.toDouble(),
        weightReps: (j['weight_reps'] as num?)?.toInt(),
        scaleLevel: (j['scale_level'] ?? 'rx').toString(),
        notes: (j['notes'] ?? '').toString(),
        createdAt: parseServerTime(j['created_at'] as String).toLocal(),
      );
}

/// v1.16 Sprint 16: WOD 댓글.
class GymWodComment {
  final int id;
  final String authorPrefix;
  final bool isMine;
  final String body;
  final DateTime createdAt;

  const GymWodComment({
    required this.id,
    required this.authorPrefix,
    required this.isMine,
    required this.body,
    required this.createdAt,
  });

  factory GymWodComment.fromJson(Map<String, dynamic> j) => GymWodComment(
        id: (j['id'] as num).toInt(),
        authorPrefix: (j['author_prefix'] ?? '').toString(),
        isMine: j['is_mine'] == true,
        body: (j['body'] ?? '').toString(),
        createdAt: parseServerTime(j['created_at'] as String).toLocal(),
      );
}

/// Q3 (v3.4 2026-08-20 승인) — 수업 상세 "내 이전 기록" 1건.
/// 라벨("4:18"·"105kg×3"·"10R+5")·PR 판정은 서버 완성 (앱 계산 0).
class WodMyHistoryItem {
  final int wodPostId;
  final String date; // YYYY-MM-DD
  final String label;
  final bool isPr;

  const WodMyHistoryItem({
    required this.wodPostId,
    required this.date,
    required this.label,
    required this.isPr,
  });

  factory WodMyHistoryItem.fromJson(Map<String, dynamic> j) =>
      WodMyHistoryItem(
        wodPostId: (j['wod_post_id'] as num?)?.toInt() ?? 0,
        date: (j['date'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        isPr: j['is_pr'] == true,
      );
}

/// Q3 (v3.4) — 1RM 보드 리프트 1행 (서버 집계 그대로).
class StrengthBoardEntry {
  final String movement;
  final double bestKg;
  final int? bestReps;
  final String? bestDate;
  final int count;

  const StrengthBoardEntry({
    required this.movement,
    required this.bestKg,
    this.bestReps,
    this.bestDate,
    required this.count,
  });

  factory StrengthBoardEntry.fromJson(Map<String, dynamic> j) =>
      StrengthBoardEntry(
        movement: (j['movement'] ?? '').toString(),
        bestKg: (j['best_kg'] as num?)?.toDouble() ?? 0,
        bestReps: (j['best_reps'] as num?)?.toInt(),
        bestDate: j['best_date']?.toString(),
        count: (j['count'] as num?)?.toInt() ?? 0,
      );
}

/// P3 (2026-08-20 — PLAN-reward-rules.md §6) — 도전 카드 1행.
/// 문장(sentence)·진행률·대기 건수는 서버 완성 (reward-progress API).
class RewardProgress {
  final int ruleId;
  final String label;
  final String trigger;
  final String sentence;
  final int progress;
  final int target;
  final int pending;
  final bool doneThisWindow;
  final bool canLog;

  const RewardProgress({
    required this.ruleId,
    required this.label,
    required this.trigger,
    required this.sentence,
    required this.progress,
    required this.target,
    required this.pending,
    required this.doneThisWindow,
    required this.canLog,
  });

  factory RewardProgress.fromJson(Map<String, dynamic> j) => RewardProgress(
        ruleId: (j['rule_id'] as num?)?.toInt() ?? 0,
        label: (j['label'] ?? '').toString(),
        trigger: (j['trigger'] ?? '').toString(),
        sentence: (j['sentence'] ?? '').toString(),
        progress: (j['progress'] as num?)?.toInt() ?? 0,
        target: (j['target'] as num?)?.toInt() ?? 1,
        pending: (j['pending'] as num?)?.toInt() ?? 0,
        doneThisWindow: j['done_this_window'] == true,
        canLog: j['can_log'] == true,
      );
}

/// 결함 수정 4 (2026-08-20) — 수업 카드·시트가 쓰는 "내 기존 기록" 요약.
/// display("105kg×3"·"4:18"·"10R+5")는 서버 완성 (앱 계산 0).
class GymMyResult {
  final int? timeSec;
  final int? rounds;
  final int? extraReps;
  final double? weightKg;
  final int? weightReps;

  /// 무게 기록의 동작 이름 (v3.15 — 재수정 시트 프리필용).
  final String? movement;
  final String scaleLevel;
  final String display;

  const GymMyResult({
    this.timeSec,
    this.rounds,
    this.extraReps,
    this.weightKg,
    this.weightReps,
    this.movement,
    required this.scaleLevel,
    required this.display,
  });

  factory GymMyResult.fromJson(Map<String, dynamic> j) => GymMyResult(
        timeSec: (j['time_sec'] as num?)?.toInt(),
        rounds: (j['rounds'] as num?)?.toInt(),
        extraReps: (j['extra_reps'] as num?)?.toInt(),
        weightKg: (j['weight_kg'] as num?)?.toDouble(),
        weightReps: (j['weight_reps'] as num?)?.toInt(),
        movement: j['movement'] as String?,
        scaleLevel: (j['scale_level'] ?? 'rx').toString(),
        display: (j['display'] ?? '').toString(),
      );
}
