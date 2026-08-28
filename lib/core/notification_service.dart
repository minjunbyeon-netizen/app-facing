import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// OS 알림을 **실제로 내보내는 창구**. 플랫폼 분기와 플러그인 호출은 전부
/// 이 뒤에 있다.
///
/// [NotificationService] 는 정책(알림 받기 스위치 · 지난 시각 판정 · 이벤트별
/// 문구)만 판단하고 실행은 여기로 내린다. 갈아 끼울 수 있는 자리가 하나뿐이라
/// "껐을 때 정말 아무것도 안 나갔는지" 를 기기 없이 증명할 수 있다
/// (`test/notification_gate_test.dart`).
abstract class NotificationSink {
  /// 이 기기에서 로컬 알림을 다룰 수 있는가 (Android·iOS 만).
  bool get supported;

  Future<void> show(
    int id,
    String title,
    String body,
    NotificationDetails details, {
    String? payload,
  });

  Future<void> schedule(
    int id,
    String title,
    String body,
    tz.TZDateTime when,
    NotificationDetails details,
  );

  Future<void> cancel(int id);

  Future<void> cancelAll();

  Future<bool> requestPermission();

  Future<bool> isPermissionGranted();
}

/// 실제 창구 — flutter_local_notifications + permission_handler.
class _PluginSink implements NotificationSink {
  _PluginSink(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  bool get supported => Platform.isAndroid || Platform.isIOS;

  @override
  Future<void> show(
    int id,
    String title,
    String body,
    NotificationDetails details, {
    String? payload,
  }) => _plugin.show(id, title, body, details, payload: payload);

  @override
  Future<void> schedule(
    int id,
    String title,
    String body,
    tz.TZDateTime when,
    NotificationDetails details,
  ) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // 정확 알람 권한이 없는 기기 등 — 알림이 없다고 예약 자체가 실패하면 안 된다.
      debugPrint('[NOTIF] reminder schedule failed: $e');
    }
  }

  @override
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('[NOTIF] cancel failed: $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('[NOTIF] cancelAll failed: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!supported) return false;
    final status = await Permission.notification.request();
    debugPrint('[NOTIF] permission=$status');
    return status.isGranted;
  }

  @override
  Future<bool> isPermissionGranted() async {
    if (!supported) return false;
    return Permission.notification.isGranted;
  }
}

/// v1.17 로컬 푸시 코어 — Firebase 없이 SSE + 로컬 알림으로 폰 알림 제공.
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

  // ─── 알림 받기 스위치 (2026-08-28 사용자 확정) ────────────────────────────
  //
  // > "첫 앱 설치 때 알림을 허용할까요? 그때 체크 혹은 내 정보 설정에서 알림 허용
  // >  칸 토글로 허용 으로 하고 (일괄로 처리)"
  //
  // **종류별로 나누지 않는다 — 켜거나 끄거나 하나다.** 값은 기기에만 둔다
  // (서버는 아직 알림을 보내지 않는다 — 앱이 살아 있을 때만 뜬다).

  /// 기기 저장 키. 화면(내 정보 '알림 받기')과 같은 값을 쓴다 (§0-B).
  static const String prefsKey = 'notifications_enabled';

  /// 기본값 = **켜짐**. 지금까지 알림을 받던 회원이 업데이트만으로 조용히
  /// 못 받게 되면 안 된다 (설치 직후에도 마찬가지 — 첫 진입 권한 요청이 곧 동의다).
  static const bool defaultEnabled = true;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// 실행 창구. 테스트만 [debugUseSink] 로 갈아 끼운다.
  late NotificationSink _sink = _PluginSink(_plugin);

  bool _initialized = false;

  /// 읽어 둔 스위치 값. null = 아직 안 읽음.
  bool? _enabled;

  /// 테스트 전용 — 창구를 갈아 끼우고 초기화 완료 상태로 둔다.
  @visibleForTesting
  void debugUseSink(NotificationSink sink) {
    _sink = sink;
    _initialized = true;
    _enabled = null;
  }

  /// 테스트 전용 — 실제 창구로 되돌리고 캐시를 비운다.
  @visibleForTesting
  void debugReset() {
    _sink = _PluginSink(_plugin);
    _initialized = false;
    _enabled = null;
  }

  /// 이 기기가 로컬 알림을 다룰 수 있는가 (Android·iOS). 데스크톱·테스트에서는
  /// false — 그때는 '폰 설정에서 차단됨' 안내를 띄우지 않는다 (풀 수 없는 것을
  /// 풀라고 말하지 않는다).
  bool get supported => _sink.supported;

  /// 이미 읽어 둔 스위치 값 (아직 안 읽었으면 [defaultEnabled]).
  /// 화면 첫 프레임용 — 정확한 값은 [isEnabled] 로 확인한다.
  bool get enabledNow => _enabled ?? defaultEnabled;

  /// 알림 받기 스위치 상태. 저장된 값이 없으면 [defaultEnabled].
  Future<bool> isEnabled() async {
    final cached = _enabled;
    if (cached != null) return cached;
    bool value = defaultEnabled;
    try {
      final sp = await SharedPreferences.getInstance();
      value = sp.getBool(prefsKey) ?? defaultEnabled;
    } catch (e) {
      // 저장소를 못 읽는다고 알림을 끄지 않는다 — 기본값(켜짐)으로 간다.
      debugPrint('[NOTIF] prefs read failed: $e');
    }
    _enabled = value;
    return value;
  }

  /// 알림 받기 스위치를 바꾼다.
  ///
  /// **끄면 걸어 둔 예약분도 함께 지운다** — 안 그러면 껐는데도 이미 기기에
  /// 잡혀 있던 수업 1시간 전 알림이 그대로 울린다 (껐다는 화면이 거짓말이 된다).
  /// 다시 켜면 홈 진입 때 `TodayReservationsCard._restoreReminders()` 가
  /// 앞으로의 예약을 훑어 알림을 다시 건다.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(prefsKey, value);
    } catch (e) {
      debugPrint('[NOTIF] prefs write failed: $e');
    }
    if (!value) await cancelAll();
  }

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
  /// 거부되어도 앱 동작은 막지 않는다 — 폰 설정에서 나중에 허용할 수 있고,
  /// 내 정보 '알림 받기' 줄이 그 사실을 계속 알려 준다.
  /// (iOS 는 Podfile `PERMISSION_NOTIFICATIONS=1` 매크로가 켜져 있어야 실제 팝업이 뜬다.)
  Future<bool> requestPermission() => _sink.requestPermission();

  Future<bool> isPermissionGranted() => _sink.isPermissionGranted();

  /// SSE 이벤트 → OS 알림 변환.
  /// staff (코치) 채널: 가입 신청·결제·예약 같은 운영 트리거.
  /// member 채널: 회원권 만료·공지·쪽지 같은 회원 트리거.
  Future<void> showFromSseEvent({
    required String eventType,
    required Map<String, dynamic> payload,
  }) async {
    // ── 관문 (2026-08-28) ──
    // 알림 받기가 꺼져 있으면 여기서 끝. 호출부(SSE·쪽지·체육관 상태 변화)마다
    // 각자 검사하면 언젠가 한 곳이 빠지므로 관문은 이 파일 안 두 곳뿐이다.
    if (!await isEnabled()) return;
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

    await _sink.show(
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
      // ─ 코치 운영 채널 ─────────────────────────────
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
    // ── 관문 (2026-08-28) — 즉시 알림과 같은 자리에서 막는다 ──
    if (!await isEnabled()) return;
    if (!_sink.supported) return;
    if (!_initialized) await init();
    final when = tz.TZDateTime.from(startAt, tz.local)
        .subtract(const Duration(minutes: reminderLeadMinutes));
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
    final hh = startAt.hour.toString().padLeft(2, '0');
    final mm = startAt.minute.toString().padLeft(2, '0');
    await _sink.schedule(
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
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
    );
    debugPrint('[NOTIF] reminder set resv=$reservationId at $when');
  }

  /// 예약을 취소했으면 걸어 둔 알림도 지운다 (안 오는 수업을 알리지 않는다).
  /// 지우는 쪽은 스위치와 무관하게 언제나 동작한다.
  Future<void> cancelClassReminder(int reservationId) async {
    if (!_initialized) return;
    await _sink.cancel(reminderId(reservationId));
  }

  Future<void> cancelAll() => _sink.cancelAll();
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
