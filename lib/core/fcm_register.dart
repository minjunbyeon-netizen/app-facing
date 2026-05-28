// PHASE5 §6-3 — FCM 토큰 register 헬퍼.
//
// 현재 구현: firebase_messaging 패키지 미도입 상태라 placeholder 토큰 사용.
// 진짜 Firebase 연동 시:
//   1. pubspec.yaml 에 firebase_core + firebase_messaging 추가
//   2. android/app/google-services.json 배치
//   3. 아래 `_obtainToken()` 을 `FirebaseMessaging.instance.getToken()` 으로 교체
//
// 동작:
//   - App launch 후 한 번 backend `POST /api/v1/devices/fcm-token` 호출
//   - 같은 device + 같은 token 으로 24시간 안에 중복 호출 방지 (SharedPreferences)
//   - 실패해도 silent (notification 없어도 앱은 동작)
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class FcmRegister {
  static const _lastRegisteredKey = 'fcm_last_registered_at_ms';
  static const _lastTokenKey = 'fcm_last_registered_token';
  static const _registerInterval = Duration(hours: 24);

  // App launch 시 호출. 백엔드에 토큰 등록.
  static Future<void> registerIfNeeded(ApiClient api) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await _obtainToken();
      if (token == null || token.isEmpty) return;

      final lastMs = prefs.getInt(_lastRegisteredKey) ?? 0;
      final lastTok = prefs.getString(_lastTokenKey) ?? '';
      final age = DateTime.now().millisecondsSinceEpoch - lastMs;
      if (lastTok == token && age < _registerInterval.inMilliseconds) {
        return; // 최근 24h 안 같은 토큰이면 skip
      }

      final res = await api.post('/api/v1/devices/fcm-token', {'fcm_token': token});
      if (res['ok'] == true) {
        await prefs.setInt(_lastRegisteredKey, DateTime.now().millisecondsSinceEpoch);
        await prefs.setString(_lastTokenKey, token);
      }
    } catch (_) {
      // silent — 푸시 안 와도 앱 동작 영향 X
    }
  }

  // firebase_messaging 미도입 — placeholder 토큰 (device 고유).
  // 진짜 통합 시: `await FirebaseMessaging.instance.getToken()` 으로 교체.
  static Future<String?> _obtainToken() async {
    final prefs = await SharedPreferences.getInstance();
    var t = prefs.getString('fcm_placeholder_token');
    if (t == null || t.isEmpty) {
      // 한 번만 만들고 SharedPreferences 에 고정 — 같은 device 는 같은 토큰
      t = 'PLACEHOLDER_${DateTime.now().millisecondsSinceEpoch}_${_rand6()}';
      await prefs.setString('fcm_placeholder_token', t);
    }
    return t;
  }

  static String _rand6() {
    final n = DateTime.now().microsecondsSinceEpoch & 0xFFFFFF;
    return n.toRadixString(16).padLeft(6, '0');
  }
}
