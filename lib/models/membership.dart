// v1.16.2 (2026-05-24) — 회원권 DTO.
// /api/v1/member/me/memberships 응답 1 행 매핑.

import '../core/app_clock.dart';

class Membership {
  final int id;
  final int gymId;
  final int memberId;
  final String? planName;
  final String? startDate; // 'YYYY-MM-DD'
  final String? endDate;
  final int? price;
  final String status; // active / expired / refunded / scheduled / ...

  const Membership({
    required this.id,
    required this.gymId,
    required this.memberId,
    this.planName,
    this.startDate,
    this.endDate,
    this.price,
    this.status = 'active',
  });

  factory Membership.fromJson(Map<String, dynamic> j) => Membership(
        id: (j['id'] as num).toInt(),
        gymId: (j['gym_id'] as num).toInt(),
        memberId: (j['member_id'] as num).toInt(),
        planName: j['plan_name']?.toString(),
        startDate: j['start_date']?.toString(),
        endDate: j['end_date']?.toString(),
        price: (j['price'] as num?)?.toInt(),
        status: (j['status'] ?? 'active').toString(),
      );

  /// 만료까지 남은 일수. end_date 가 없으면 null.
  /// 음수면 이미 만료.
  int? get daysUntilExpiry {
    if (endDate == null) return null;
    try {
      final end = DateTime.parse(endDate!);
      final now = appClock.now();
      final endDay = DateTime(end.year, end.month, end.day);
      final today = DateTime(now.year, now.month, now.day);
      return endDay.difference(today).inDays;
    } catch (_) {
      return null;
    }
  }

  /// 진행률 0.0~1.0 (시작 대비 경과). end·start 둘 다 있어야 함.
  double? get progress {
    if (startDate == null || endDate == null) return null;
    try {
      final start = DateTime.parse(startDate!);
      final end = DateTime.parse(endDate!);
      final now = appClock.now();
      final total = end.difference(start).inSeconds;
      if (total <= 0) return null;
      final elapsed = now.difference(start).inSeconds;
      final p = elapsed / total;
      if (p < 0) return 0;
      if (p > 1) return 1;
      return p;
    } catch (_) {
      return null;
    }
  }

  bool get isActive => status == 'active';
}
