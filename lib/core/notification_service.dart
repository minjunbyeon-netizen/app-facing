import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// v1.17 로컬 푸시 코어 — Firebase 없이 SSE + 로컬 알림으로 사장·코치 폰 알림 제공.
///
/// 흐름:
///   1. 앱 첫 진입 시 [requestPermission] 호출 (Android 13+ POST_NOTIFICATIONS)
///   2. SSE 이벤트 수신 시 [showFromSseEvent] 호출 → OS 알림바에 표시
///   3. Foreground Service 가 앱 종료 후에도 SSE 연결 유지 (foreground_service_handler.dart 참조)
///
/// Brief §14 D14 (FCM stub) 의 폰 측 대응. iOS 는 v2.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _channelStaffId = 'hyphen_staff';
  static const String _channelStaffName = 'HYPHEN 코치 알림';
  static const String _channelStaffDesc = '신규 가입 신청·결제·예약 등 운영 알림';

  /// 수업 시작 전 알림 채널 — 회원이 "오늘 몇 시에 예약했더라" 를 안 물어도 되게.
  static const String _channelReminderId = 'hyphen_reminder';
  static const String _channelReminderName = 'HYPHEN 수업 알림';
  static const String _channelReminderDesc = '예약한 수업 시작 전 알림';

  /// 수업 시작 몇 분 전에 알릴 것인가 (테스터 지시 2026-08-28 "1시간 전").
  static const int reminderLeadMinutes = 60;

  static const String _channelMemberId = 'hyphen_member';
  static const String _channelMemberName = 'HYPHEN 회원 알림';
  static const String _channelMemberDesc = '회원권 만료·공지·코치 메시지';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS (2026-08-28 App Store 준비) — 권한은 requestPermission 에서 한 번에
    // 묻는다 (초기화 시점 자동 팝업 금지: Apple 심사는 맥락 없는 권한 팝업을 지적).
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);
    // 예약 알림은 '그 체육관의 벽시계' 로 잡아야 한다 — 전 체육관 한국(KST 하나,
    // 브리프 §2-0 4번)이라 지역을 고정한다. 기기 시간대가 달라도 수업 시각은 KST.
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Android 8+ 알림 채널 생성 (한 번만 — 시스템이 중복 무시).
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelStaffId,
          _channelStaffName,
          description: _channelStaffDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelMemberId,
          _channelMemberName,
          description: _channelMemberDesc,
          importance: Importance.defaultImportance,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelReminderId,
          _channelReminderName,
          description: _channelReminderDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
    _initialized = true;
    debugPrint('[NOTIF] initialized');
  }

  /// 권한 요청. Android 13 이상·iOS 에서 dialog 띄움, 그 이하 Android 는 자동 grant.
  /// 거부되어도 앱 동작은 막지 않음 — 사용자가 나중에 설정에서 켤 수 있음.
  /// (iOS 는 Podfile `PERMISSION_NOTIFICATIONS=1` 매크로가 켜져 있어야 실제 팝업이 뜬다.)
  Future<bool> requestPermission() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return false;
    final status = await Permission.notification.request();
    debugPrint('[NOTIF] permission=$status');
    return status.isGranted;
  }

  Future<bool> isPermissionGranted() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return false;
    return Permission.notification.isGranted;
  }

  /// SSE 이벤트 → OS 알림 변환.
  /// staff (사장·코치) 채널: 가입 신청·결제·예약 같은 운영 트리거.
  /// member 채널: 회원권 만료·공지 같은 회원 트리거.
  Future<void> showFromSseEvent({
    required String eventType,
    required Map<String, dynamic> payload,
  }) async {
    if (!_initialized) await init();
    final spec = _resolveSpec(eventType, payload);
    if (spec == null) return; // 이 이벤트는 알림 안 띄움 (silent).

    final androidDetails = AndroidNotificationDetails(
      spec.channelId,
      spec.channelId == _channelStaffId
          ? _channelStaffName
          : _channelMemberName,
      channelDescription: spec.channelId == _channelStaffId
          ? _channelStaffDesc
          : _channelMemberDesc,
      importance: spec.importance,
      priority: spec.priority,
      ticker: spec.title,
      styleInformation: BigTextStyleInformation(spec.body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    await _plugin.show(
      spec.id,
      spec.title,
      spec.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: eventType,
    );
    debugPrint('[NOTIF] show id=${spec.id} title=${spec.title}');
  }

  _NotifSpec? _resolveSpec(String type, Map<String, dynamic> payload) {
    final inner = payload['payload'] is Map<String, dynamic>
        ? payload['payload'] as Map<String, dynamic>
        : payload;
    switch (type) {
      // ─ 사장·코치 운영 채널 ─────────────────────────────
      case 'member_join_request':
        return _NotifSpec(
          id: _idFor('join', inner['member_id']),
          channelId: _channelStaffId,
          title: '[HYPHEN] 새 가입 신청',
          body: '회원 가입 신청 도착. 앱에서 승인 필요.',
          importance: Importance.high,
          priority: Priority.high,
        );
      case 'member.created':
        return _NotifSpec(
          id: _idFor('created', inner['member_id']),
          channelId: _channelStaffId,
          title: '[HYPHEN] 신규 회원 등록',
          body: '${inner['name'] ?? '새 회원'} 등록 완료.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
      case 'membership.issued':
        return _NotifSpec(
          id: _idFor('issued', inner['member_id']),
          channelId: _channelStaffId,
          title: '[HYPHEN] 회원권 발급',
          body: '${inner['plan_name'] ?? '회원권'} 발급 완료.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
      case 'attendance_checked':
        return null; // 너무 잦아서 silent.
      // ─ 회원 채널 ────────────────────────────────────
      // 2026-08-13 — 가입 승인 알림. 회원이 가장 기다리는 소식인데 그동안
      // 앱을 열어 새로고침해야만 알 수 있었다 (승인 대기 화면 그대로).
      case 'member.decided':
        final approved = (inner['status'] ?? '') == 'approved';
        return _NotifSpec(
          id: _idFor('decided', inner['member_id']),
          channelId: _channelMemberId,
          title: approved ? '[HYPHEN] 가입 승인 완료' : '[HYPHEN] 가입 신청 결과',
          body: approved
              ? '이제 수업 예약과 수업 내용을 볼 수 있습니다.'
              : '가입 신청이 승인되지 않았습니다. 체육관에 문의해 주세요.',
          importance: Importance.high,
          priority: Priority.high,
        );
      // 2026-08-28 테스터 지시 — "쪽지가 왔을 때 직접적인 알람이 떠야 하는데 오지 않음".
      // 종전엔 note.new 에 spec 이 없어 조용히 버려졌다. 쪽지는 사람이 나에게
      // 보낸 것이라 공지·수업 내용보다 급하다 — high 로 띄운다.
      case 'note.new':
        final sender = (inner['sender_name'] ?? '').toString().trim();
        final preview = (inner['preview'] ?? '').toString().trim();
        return _NotifSpec(
          // 쪽지마다 따로 쌓이게 note_id 로 id 를 나눈다 (덮어쓰면 놓친다).
          id: _idFor('note', inner['note_id']),
          channelId: _channelMemberId,
          title: sender.isNotEmpty ? '[HYPHEN] $sender 코치' : '[HYPHEN] 새 쪽지',
          body: preview.isNotEmpty ? preview : '새 쪽지가 도착했습니다.',
          importance: Importance.high,
          priority: Priority.high,
        );
      case 'announcement.posted':
        return _NotifSpec(
          id: _idFor('announce', inner['announcement_id']),
          channelId: _channelMemberId,
          title: '[HYPHEN] 새 공지',
          body: (inner['title'] ?? '새 공지 등록.') as String,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
      case 'wod.posted':
        return _NotifSpec(
          id: _idFor('wod', inner['wod_id']),
          channelId: _channelMemberId,
          title: '[HYPHEN] 오늘의 수업',
          body: (inner['title'] ?? '새 수업 내용 등록.') as String,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
      default:
        return null;
    }
  }

  int _idFor(String prefix, dynamic suffix) {
    final s = '$prefix:$suffix';
    return s.hashCode & 0x7FFFFFFF;
  }

  // ─── 수업 예약 알림 (2026-08-28 테스터 지시) ──────────────────────────
  //
  // "오늘 몇 시 예약했더라 하고 까먹을 수도 있기 때문" — 시작 1시간 전에 폰이
  // 먼저 알린다. 서버 푸시(FCM) 없이 **기기에 예약**해 두는 로컬 알림이라
  // 오프라인이어도 뜬다. 예약을 취소하면 같은 id 로 지운다.

  /// 예약 1건의 알림 id — 예약 id 로 고정해야 취소·재예약에서 정확히 맞물린다.
  int reminderId(int reservationId) => _idFor('resv', reservationId);

  /// 수업 시작 [reminderLeadMinutes] 분 전 알림을 건다.
  /// 이미 그 시각이 지났으면 아무것도 하지 않는다 (지난 알림을 즉시 울리지 않게).
  Future<void> scheduleClassReminder({
    required int reservationId,
    required String title,
    required DateTime startAt,
  }) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    if (!_initialized) await init();
    final when = tz.TZDateTime.from(startAt, tz.local)
        .subtract(const Duration(minutes: reminderLeadMinutes));
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
    final hh = startAt.hour.toString().padLeft(2, '0');
    final mm = startAt.minute.toString().padLeft(2, '0');
    try {
      await _plugin.zonedSchedule(
        reminderId(reservationId),
        '[HYPHEN] $hh:$mm $title',
        '수업 시작 $reminderLeadMinutes분 전입니다.',
        when,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            _channelReminderId,
            _channelReminderName,
            channelDescription: _channelReminderDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true, presentBadge: false, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[NOTIF] reminder set resv=$reservationId at $when');
    } catch (e) {
      // 정확 알람 권한이 없는 기기 등 — 알림이 없다고 예약 자체가 실패하면 안 된다.
      debugPrint('[NOTIF] reminder schedule failed: $e');
    }
  }

  /// 예약을 취소했으면 걸어 둔 알림도 지운다 (안 오는 수업을 알리지 않는다).
  Future<void> cancelClassReminder(int reservationId) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(reminderId(reservationId));
    } catch (e) {
      debugPrint('[NOTIF] reminder cancel failed: $e');
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}

class _NotifSpec {
  final int id;
  final String channelId;
  final String title;
  final String body;
  final Importance importance;
  final Priority priority;
  const _NotifSpec({
    required this.id,
    required this.channelId,
    required this.title,
    required this.body,
    required this.importance,
    required this.priority,
  });
}
