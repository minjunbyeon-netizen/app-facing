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
}
