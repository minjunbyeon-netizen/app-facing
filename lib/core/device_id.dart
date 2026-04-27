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

  /// v1.19 차수 5+ (트랙 A): 디버그용 페르소나 강제 주입.
  /// SharedPreferences device_id 덮어쓰기 + 메모리 캐시 갱신.
  /// 주의: kDebugMode 환경에서만 호출할 것 (Production guard 는 호출자 책임).
  static Future<void> overrideForDebug(String newDeviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, newDeviceId);
    _cached = newDeviceId;
    _inFlight = null;
  }

  /// 캐시된 device_id (없으면 null). 동기 조회 — 로딩 후 사용.
  static String? get cached => _cached;
}
