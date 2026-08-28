// v1.16.2 (2026-05-24) — 박스 코치 프로필 DTO.
// ARCHITECTURE_BRIEF §11.6 / docs/GYM_PROFILE_SCHEMA.md §2.
// 체육관 정보 카드(gym_info_card "코치" 구역) + 쪽지함 발신자 이름에서 사용.

import 'dart:convert';

class CoachProfile {
  final int id;
  final int coachUserId;
  final int gymId;
  final String name;
  final String? photoUrl;
  final String? career;
  final String? certifications;
  final String? specialty;
  final String? competitionRecords;
  final String? demoVideoUrl;
  final String? snsUrl;
  final bool ptBookable;
  final List<String> offDays;
  final String? hiredAt;
  final int displayOrder;

  const CoachProfile({
    required this.id,
    required this.coachUserId,
    required this.gymId,
    required this.name,
    this.photoUrl,
    this.career,
    this.certifications,
    this.specialty,
    this.competitionRecords,
    this.demoVideoUrl,
    this.snsUrl,
    this.ptBookable = false,
    this.offDays = const [],
    this.hiredAt,
    this.displayOrder = 0,
  });

  factory CoachProfile.fromJson(Map<String, dynamic> j) {
    List<String> parseOffDays(dynamic raw) {
      if (raw == null) return const [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
      return const [];
    }

    return CoachProfile(
      id: (j['id'] as num).toInt(),
      coachUserId: (j['coach_user_id'] as num).toInt(),
      gymId: (j['gym_id'] as num).toInt(),
      name: (j['name'] ?? '').toString(),
      photoUrl: _s(j['photo_url']),
      career: _s(j['career']),
      certifications: _s(j['certifications']),
      specialty: _s(j['specialty']),
      competitionRecords: _s(j['competition_records']),
      demoVideoUrl: _s(j['demo_video_url']),
      snsUrl: _s(j['sns_url']),
      ptBookable: j['pt_bookable'] == true,
      offDays: parseOffDays(j['off_days_json'] ?? j['off_days']),
      hiredAt: _s(j['hired_at']),
      displayOrder: ((j['display_order'] ?? 0) as num).toInt(),
    );
  }

  static String? _s(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }
}
