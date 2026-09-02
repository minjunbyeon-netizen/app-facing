// v1.16.2 (2026-05-24) — 락커 DTO.
// /api/v1/member/me/locker 응답 1 행 매핑.

class Locker {
  final int gymId;
  final String lockerNo; // "A-07" 등 자유 string
  final int? memberId;
  final String? startDate;
  final String? endDate;
  final String? memo;
  final int? dDay;
  final String? dDayLabel;

  const Locker({
    required this.gymId,
    required this.lockerNo,
    this.memberId,
    this.startDate,
    this.endDate,
    this.memo,
    this.dDay,
    this.dDayLabel,
  });

  factory Locker.fromJson(Map<String, dynamic> j) => Locker(
        gymId: (j['gym_id'] as num).toInt(),
        lockerNo: (j['locker_no'] ?? '').toString(),
        memberId: (j['member_id'] as num?)?.toInt(),
        startDate: j['start_date']?.toString(),
        endDate: j['end_date']?.toString(),
        memo: j['memo']?.toString(),
        dDay: (j['d_day'] as num?)?.toInt(),
        dDayLabel: j['d_day_label']?.toString(),
      );

  /// 락커 만료 D-day — 서버 `d_day` 그대로 (2026-09-02 이원화 정리, 정본
  /// api/_membership.membership_dday — 회원권 카드 membership.dart 와 같은 결).
  /// null 이면 미지정 (회원권 만료일 자동).
  int? get daysUntilExpiry => dDay;
}
