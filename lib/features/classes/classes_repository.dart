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
    if (from != null) qs['from'] = from.toIso8601String();
    if (to != null) qs['to'] = to.toIso8601String();
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

  /// 본인 예약 취소. 백엔드가 waitlist 1번 자동 승격.
  Future<void> cancel(int reservationId) async {
    await _api.delete('/api/v1/member/reservations/$reservationId');
  }
}
