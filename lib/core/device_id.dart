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

  /// v1.19 차수 5+ (트랙 A): 디버그용 페르소나 강제 주입.
  /// 동작은 [adopt] 와 같다 — 호출 의도 구분을 위해 이름만 유지.
  static Future<void> overrideForDebug(String newDeviceId) => adopt(newDeviceId);

  /// 캐시된 device_id (없으면 null). 동기 조회 — 로딩 후 사용.
  static String? get cached => _cached;
}
