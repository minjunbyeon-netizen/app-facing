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
  final String? pauseStart; // 'YYYY-MM-DD' — 일시정지 창 (2026-08-24 갭 해소)
  final String? pauseEnd;

  const Membership({
    required this.id,
    required this.gymId,
    required this.memberId,
    this.planName,
    this.startDate,
    this.endDate,
    this.price,
    this.status = 'active',
    this.pauseStart,
    this.pauseEnd,
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
        pauseStart: j['pause_start']?.toString(),
        pauseEnd: j['pause_end']?.toString(),
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

  /// 오늘이 일시정지 창 안인가 (pause_start ≤ 오늘 < pause_end —
  /// 해제일(pause_end)부터는 정지 아님, 서버 admin.py 판정과 동일 규약).
  bool get isPausedNow {
    if (pauseStart == null || pauseEnd == null) return false;
    try {
      final now = appClock.now();
      final today = DateTime(now.year, now.month, now.day);
      final ps = DateTime.parse(pauseStart!);
      final pe = DateTime.parse(pauseEnd!);
      return !today.isBefore(DateTime(ps.year, ps.month, ps.day)) &&
          today.isBefore(DateTime(pe.year, pe.month, pe.day));
    } catch (_) {
      return false;
    }
  }

  /// 그날 이 회원권으로 수업을 잡을 수 있는가 — S5 (2026-08-26) 서버
  /// `classes._membership_blocked` 와 같은 규칙: status active ·
  /// start_date ≤ 날 ≤ end_date · 정지 창(pause_start ≤ 날 < pause_end) 밖.
  /// 기준은 '오늘' 이 아니라 **수업일** — 미리 결제한 다음 달 권으로 다음 달
  /// 수업은 잡히고, 이번 달 권으로 만료 뒤 수업은 안 잡힌다.
  bool coversDay(DateTime day) {
    if (!isActive || startDate == null || endDate == null) return false;
    try {
      final d = DateTime(day.year, day.month, day.day);
      final s = DateTime.parse(startDate!);
      final e = DateTime.parse(endDate!);
      if (d.isBefore(DateTime(s.year, s.month, s.day))) return false;
      if (d.isAfter(DateTime(e.year, e.month, e.day))) return false;
      if (pauseStart != null && pauseEnd != null) {
        final ps = DateTime.parse(pauseStart!);
        final pe = DateTime.parse(pauseEnd!);
        final paused = !d.isBefore(DateTime(ps.year, ps.month, ps.day)) &&
            d.isBefore(DateTime(pe.year, pe.month, pe.day));
        if (paused) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 정지가 예약돼 있고 아직 시작 전인가.
  bool get isPauseScheduled {
    if (pauseStart == null || pauseEnd == null) return false;
    try {
      final now = appClock.now();
      final today = DateTime(now.year, now.month, now.day);
      final ps = DateTime.parse(pauseStart!);
      return today.isBefore(DateTime(ps.year, ps.month, ps.day));
    } catch (_) {
      return false;
    }
  }
}
