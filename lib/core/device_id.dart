import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const _key = 'device_id';
  static String? _cached;
  static Future<String>? _inFlight;

  static Future<String> get() async {
    if (_cached != null) return _cached!;
    // QA B-COR-7: race condition 방지. Splash + ApiClient interceptor 동시 호출 시
    // 단일 Future 공유.
    return _inFlight ??= _resolve();
  }

  static Future<String> _resolve() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(_key);
      if (id == null || id.isEmpty) {
        id = const Uuid().v4();
        await prefs.setString(_key, id);
      }
      _cached = id;
      return id;
    } finally {
      _inFlight = null;
    }
  }

  /// 서버가 확정한 회원 device_id 를 이 기기의 신원으로 채택한다.
  ///
  /// 아이디·비밀번호 로그인(`/api/v1/auth/member-login`)이 내려준 값을 저장하면
  /// 폰을 바꾸거나 앱을 다시 설치해도 같은 회원의 기록으로 이어진다.
  static Future<void> adopt(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, deviceId);
    _cached = deviceId;
    _inFlight = null;
  }

  /// 이 기기의 신원을 버리고 새 UUID 로 시작한다 — 로그아웃 전용.
  ///
  /// S1 (2026-08-26 에뮬 실주행): [adopt] 만 있고 되돌리는 길이 없어, 회원이
  /// 로그아웃한 뒤 같은 폰에서 낸 가입 신청이 X-Device-Id 로 기존 승인 회원
  /// 행에 붙었다 (서버는 같은 기기 = 같은 회원으로 본다). 로그아웃은 "이 기기는
  /// 더 이상 그 회원이 아니다" 이므로 신원도 같이 끊는다. 다시 로그인하면
  /// 서버가 내려주는 device_id 를 [adopt] 해 기록이 그대로 이어진다.
  static Future<String> reset() async {
    final prefs = await SharedPreferences.getInstance();
    final id = const Uuid().v4();
    await prefs.setString(_key, id);
    _cached = id;
    _inFlight = null;
    return id;
  }

  /// 캐시된 device_id (없으면 null). 동기 조회 — 로딩 후 사용.
  static String? get cached => _cached;
}
