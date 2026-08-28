// '알림 받기' 관문 회귀 게이트 (2026-08-28 사용자 확정 — 켜거나 끄거나 하나).
//
// 지키는 것 셋:
//   1. 기본값은 **켜짐** — 업데이트만으로 조용히 못 받게 되면 안 된다.
//   2. 끄면 **즉시 알림(쪽지 등)도 수업 1시간 전 알림도** 나가지 않는다.
//      막는 자리는 NotificationService 안 한 곳뿐이다 (화면마다 검사하면
//      언젠가 한 곳이 빠진다).
//   3. **끌 때 이미 걸어 둔 예약분도 지운다** — 안 그러면 껐는데도 울린다.
//
// 기기 없이 증명하려고 [NotificationSink] 를 대역([FakeNotificationSink])으로
// 갈아 끼운다. 대역은 OS 로 아무것도 내보내지 않고 무엇이 나갔는지만 적는다.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:hyphen_app/core/notification_service.dart';
import 'package:hyphen_app/features/classes/today_reservations.dart';
import 'package:hyphen_app/models/class_session.dart';

import 'golden/fakes.dart';

/// 쪽지 도착 이벤트 한 건 — 회원이 가장 급하게 받는 알림.
Future<void> _sendNote(NotificationService svc) => svc.showFromSseEvent(
  eventType: 'note.new',
  payload: {
    'payload': {'note_id': 11, 'sender_name': '박지훈', 'preview': '오늘 수업 확인 바랍니다.'},
  },
);

/// 3시간 뒤 수업 1건 예약 — 1시간 전 알림이 걸릴 수 있는 시각.
Future<void> _scheduleClass(NotificationService svc, {int id = 501}) =>
    svc.scheduleClassReminder(
      reservationId: id,
      title: 'WOD Class',
      startAt: DateTime.now().add(const Duration(hours: 3)),
    );

/// 앞으로의 예약 1건 + 대기 1건 + 지난 수업 1건.
List<MyReservationItem> _myReservations() {
  final now = DateTime.now();
  MyReservationItem item(int id, String kind, Duration offset) =>
      MyReservationItem(
        kind: kind,
        id: id,
        classSessionId: id,
        startAt: now.add(offset),
        durationMinutes: 60,
        title: 'WOD Class',
        status: 'reserved',
      );
  return [
    item(601, 'reservation', const Duration(hours: 3)),
    item(602, 'waitlist', const Duration(hours: 4)),
    item(603, 'reservation', const Duration(hours: -3)),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  final svc = NotificationService.instance;
  late FakeNotificationSink sink;

  void install({Map<String, Object> prefs = const {}}) {
    SharedPreferences.setMockInitialValues(prefs);
    sink = FakeNotificationSink();
    svc.debugUseSink(sink);
  }

  tearDown(svc.debugReset);

  test('기본값은 켜짐 — 저장된 값이 없으면 알림이 나간다', () async {
    install();
    expect(await svc.isEnabled(), isTrue);
    await _sendNote(svc);
    await _scheduleClass(svc);
    expect(sink.shown, hasLength(1));
    expect(sink.scheduled, hasLength(1));
  });

  test('끄면 즉시 알림이 나가지 않는다', () async {
    install();
    await svc.setEnabled(false);
    await _sendNote(svc);
    expect(sink.shown, isEmpty);
  });

  test('끄면 수업 1시간 전 알림도 걸리지 않는다', () async {
    install();
    await svc.setEnabled(false);
    await _scheduleClass(svc);
    expect(sink.scheduled, isEmpty);
  });

  test('끌 때 이미 걸어 둔 예약분을 지운다', () async {
    install();
    await _scheduleClass(svc);
    expect(sink.scheduled, hasLength(1));
    expect(sink.cancelAllCount, 0);
    await svc.setEnabled(false);
    expect(sink.cancelAllCount, 1);
  });

  test('다시 켜면 둘 다 되살아난다', () async {
    install();
    await svc.setEnabled(false);
    await _sendNote(svc);
    await _scheduleClass(svc);
    expect(sink.shown, isEmpty);
    expect(sink.scheduled, isEmpty);

    await svc.setEnabled(true);
    await _sendNote(svc);
    await _scheduleClass(svc);
    expect(sink.shown, hasLength(1));
    expect(sink.scheduled, hasLength(1));
  });

  test('꺼 둔 값은 다음 실행에도 남는다 (기기 저장)', () async {
    install();
    await svc.setEnabled(false);
    // 앱을 다시 켠 상황 — 캐시를 버리고 저장소만 읽는다.
    svc.debugUseSink(sink);
    expect(await svc.isEnabled(), isFalse);
    await _sendNote(svc);
    expect(sink.shown, isEmpty);
  });

  test('저장소에 켜짐으로 있으면 그대로 나간다', () async {
    install(prefs: {NotificationService.prefsKey: true});
    expect(await svc.isEnabled(), isTrue);
    await _sendNote(svc);
    expect(sink.shown, hasLength(1));
  });

  // 껐다 켜면 지운 예약분이 되살아나야 한다. 홈과 내 정보가 **같은 절차**
  // (restoreClassReminders)를 쓰는지의 게이트 — 두 벌이 되면 한쪽만 고쳐진다.
  test('복원 절차는 앞으로의 예약만 다시 건다 (대기·지난 수업 제외)', () async {
    install();
    await restoreClassReminders(_myReservations());
    expect(sink.scheduled, [svc.reminderId(601)]);
  });

  test('꺼져 있으면 복원 절차를 돌려도 아무것도 안 걸린다', () async {
    install();
    await svc.setEnabled(false);
    await restoreClassReminders(_myReservations());
    expect(sink.scheduled, isEmpty);

    // 다시 켜고 복원하면 그 자리에서 걸린다 (홈이 다시 뜨기를 기다리지 않는다).
    await svc.setEnabled(true);
    await restoreClassReminders(_myReservations());
    expect(sink.scheduled, [svc.reminderId(601)]);
  });

  test('꺼져 있어도 예약 취소는 알림을 지운다 (관문은 내보내는 쪽만)', () async {
    install();
    await svc.setEnabled(false);
    await svc.cancelClassReminder(501);
    expect(sink.canceled, [svc.reminderId(501)]);
  });
}
