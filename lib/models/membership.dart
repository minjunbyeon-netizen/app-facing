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
  // D57 (2026-08-26) 횟수권 — 서버 session_summary 거울. 기간제는 전부 null/0.
  final int? sessionTotal;
  final int? sessionUsed;
  final int? sessionRemaining;
  final int freeNoShowLeft;
  final int freeLateCancelLeft;
  // 과제 4 (2026-08-30) — 날짜 판정은 서버 한 곳 (api/_membership.membership_calendar_fields).
  // 정지 중·정지 예정·D-day·대표권(is_current) 을 폰이 다시 세지 않는다 — 코치 명단·회원권
  // 목록과 같은 함수의 답이다 (규칙 6-b).
  final bool isPaused;
  final bool isPauseScheduled;
  final int? dDay;
  final String? dDayLabel;
  final bool isCurrent;

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
    this.sessionTotal,
    this.sessionUsed,
    this.sessionRemaining,
    this.freeNoShowLeft = 0,
    this.freeLateCancelLeft = 0,
    this.isPaused = false,
    this.isPauseScheduled = false,
    this.dDay,
    this.dDayLabel,
    this.isCurrent = false,
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
        sessionTotal: (j['session_total'] as num?)?.toInt(),
        sessionUsed: (j['session_used'] as num?)?.toInt(),
        sessionRemaining: (j['session_remaining'] as num?)?.toInt(),
        freeNoShowLeft: (j['free_no_show_left'] as num?)?.toInt() ?? 0,
        freeLateCancelLeft: (j['free_late_cancel_left'] as num?)?.toInt() ?? 0,
        isPaused: j['is_paused'] == true,
        isPauseScheduled: j['is_pause_scheduled'] == true,
        dDay: (j['d_day'] as num?)?.toInt(),
        dDayLabel: j['d_day_label']?.toString(),
        isCurrent: j['is_current'] == true,
      );

  /// 횟수권인가 (session_total 이 있음). 기간제는 false.
  bool get isSessionPass => sessionTotal != null;

  /// 횟수권 사용 비율 0.0~1.0 — 카드 진행 막대용.
  double get sessionProgress {
    final t = sessionTotal;
    if (t == null || t <= 0) return 0;
    final u = sessionUsed ?? 0;
    return (u / t).clamp(0, 1).toDouble();
  }

  /// 만료까지 남은 일수 — 서버 `d_day` 그대로 (음수면 이미 만료, 없으면 null).
  int? get daysUntilExpiry => dDay;

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

  /// 오늘이 일시정지 창 안인가 — 서버 `is_paused` 그대로 (pause_end 는 배타 경계,
  /// 정본 = api/_membership.is_paused_on). 그날 회원권 유무(구 coversDay)는 수업 목록의
  /// `membership_ok` 가 답한다 (ClassSessionDto.membershipOk).
  bool get isPausedNow => isPaused;
}
