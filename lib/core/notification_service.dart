import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

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

  static const String _channelStaffId = 'facing_staff';
  static const String _channelStaffName = 'FACING 사장·코치 알림';
  static const String _channelStaffDesc = '신규 가입 신청·결제·예약 등 운영 알림';

  static const String _channelMemberId = 'facing_member';
  static const String _channelMemberName = 'FACING 회원 알림';
  static const String _channelMemberDesc = '회원권 만료·공지·코치 메시지';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

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
    }
    _initialized = true;
    debugPrint('[NOTIF] initialized');
  }

  /// 권한 요청. Android 13 이상에서만 dialog 띄움, 그 이하는 자동 grant.
  /// 거부되어도 앱 동작은 막지 않음 — 사용자가 나중에 설정에서 켤 수 있음.
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    final status = await Permission.notification.request();
    debugPrint('[NOTIF] permission=$status');
    return status.isGranted;
  }

  Future<bool> isPermissionGranted() async {
    if (!Platform.isAndroid) return false;
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

    await _plugin.show(
      spec.id,
      spec.title,
      spec.body,
      NotificationDetails(android: androidDetails),
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
          title: '[FACING] 새 가입 신청',
          body: '회원이 박스 가입을 신청했어요. 앱에서 승인해주세요.',
          importance: Importance.high,
          priority: Priority.high,
        );
      case 'member.created':
        return _NotifSpec(
          id: _idFor('created', inner['member_id']),
          channelId: _channelStaffId,
          title: '[FACING] 신규 회원 등록',
          body: '${inner['name'] ?? '새 회원'} 님이 추가됐어요.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
      case 'membership.issued':
        return _NotifSpec(
          id: _idFor('issued', inner['member_id']),
          channelId: _channelStaffId,
          title: '[FACING] 회원권 발급',
          body: '${inner['plan_name'] ?? '회원권'} 발급 완료.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
      case 'attendance_checked':
        return null; // 너무 잦아서 silent.
      // ─ 회원 채널 ────────────────────────────────────
      case 'announcement.posted':
        return _NotifSpec(
          id: _idFor('announce', inner['announcement_id']),
          channelId: _channelMemberId,
          title: '[FACING] 새 공지',
          body: (inner['title'] ?? '공지가 올라왔어요.') as String,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
      case 'wod.posted':
        return _NotifSpec(
          id: _idFor('wod', inner['wod_id']),
          channelId: _channelMemberId,
          title: '[FACING] 오늘의 WOD',
          body: (inner['title'] ?? '새 WOD 가 올라왔어요.') as String,
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
