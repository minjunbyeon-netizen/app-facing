import '../../core/api_client.dart';
import '../../models/class_session.dart';

/// PHASE4 §1.1 — 클래스 예약 회원 측 repository.
class ClassesRepository {
  final ApiClient _api;
  ClassesRepository(this._api);

  /// 자기 박스 클래스 list. from/to ISO 8601 미지정 시 백엔드가 오늘~+14일 default.
  Future<List<ClassSessionDto>> listClasses({
    DateTime? from,
    DateTime? to,
  }) async {
    final qs = <String, String>{};
    if (from != null) qs['from'] = from.toUtc().toIso8601String();
    if (to != null) qs['to'] = to.toUtc().toIso8601String();
    final path = qs.isEmpty
        ? '/api/v1/member/classes'
        : '/api/v1/member/classes?${qs.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    final raw = await _api.getList(path);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ClassSessionDto.fromJson)
        .toList();
  }

  /// 본인 예약+waitlist 목록.
  Future<List<MyReservationItem>> listMyReservations({
    bool includePast = false,
  }) async {
    final path = includePast
        ? '/api/v1/member/reservations?include_past=1'
        : '/api/v1/member/reservations';
    final raw = await _api.getList(path);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(MyReservationItem.fromJson)
        .toList();
  }

  /// 클래스 예약 — 정원 초과 시 자동 waitlist.
  /// 응답: {status: 'confirmed'|'waitlisted', reservation_id?, position?}
  Future<Map<String, dynamic>> reserve(int classSessionId) async {
    return await _api.post(
      '/api/v1/member/classes/$classSessionId/reservations',
      const {},
    );
  }

  /// 취소 미리보기 (D96 · 2026-08-30) — 지금 취소하면 어떤 기록이 남는지 **서버가 판정**한 한 줄.
  /// 응답: {notice: String|null, tier: {...}|null}. 제때 취소면 notice 가 null.
  /// (구 앱 상수 kLateCancelMinutes=20 판정 폐기 — 체육관마다 규칙이 다르다.)
  Future<String?> cancelPreview(int reservationId) async {
    final d = await _api.get(
      '/api/v1/member/reservations/$reservationId/cancel-preview',
    );
    final n = d['notice'];
    return (n == null || n.toString().trim().isEmpty) ? null : n.toString();
  }

  /// 본인 예약 취소. 백엔드가 waitlist 1번 자동 승격.
  /// 응답: {cancelled, late_cancel, session_charged, message} — D57 횟수권
  /// 취소 문구(차감 여부)는 서버가 정본이라 스낵바가 그대로 보여준다.
  Future<Map<String, dynamic>> cancel(int reservationId) async {
    return await _api.delete('/api/v1/member/reservations/$reservationId');
  }

  /// 본인 대기열 이탈 (G30, 2026-08-24). 대기자는 예약 행이 없어 cancel()
  /// 로는 못 나간다 — 수업 id 로 미승격 대기행을 지우는 전용 경로.
  Future<void> cancelWaitlist(int classSessionId) async {
    await _api.delete('/api/v1/member/classes/$classSessionId/waitlist');
  }
}
