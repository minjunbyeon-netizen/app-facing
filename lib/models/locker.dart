// v1.16.2 (2026-05-24) — 락커 DTO.
// /api/v1/member/me/locker 응답 1 행 매핑.

class Locker {
  final int gymId;
  final String lockerNo; // "A-07" 등 자유 string
  final int? memberId;
  final String? startDate;
  final String? endDate;
  final String? memo;

  const Locker({
    required this.gymId,
    required this.lockerNo,
    this.memberId,
    this.startDate,
    this.endDate,
    this.memo,
  });

  factory Locker.fromJson(Map<String, dynamic> j) => Locker(
        gymId: (j['gym_id'] as num).toInt(),
        lockerNo: (j['locker_no'] ?? '').toString(),
        memberId: (j['member_id'] as num?)?.toInt(),
        startDate: j['start_date']?.toString(),
        endDate: j['end_date']?.toString(),
        memo: j['memo']?.toString(),
      );

  /// 락커 만료 D-day. null 이면 미지정 (회원권 만료일 자동).
  int? get daysUntilExpiry {
    if (endDate == null || endDate!.isEmpty) return null;
    try {
      final end = DateTime.parse(endDate!);
      final now = DateTime.now();
      final endDay = DateTime(end.year, end.month, end.day);
      final today = DateTime(now.year, now.month, now.day);
      return endDay.difference(today).inDays;
    } catch (_) {
      return null;
    }
  }
}
