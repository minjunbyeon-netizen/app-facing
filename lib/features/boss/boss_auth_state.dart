import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// PHASE5 §1.1 — 사장·매니저 폰 로그인 상태.
/// 백엔드 쿠키 세션을 flutter_secure_storage 에 캐시.
/// ApiClient 의 BossAuthInterceptor 가 매 요청에 Cookie 헤더 주입.
class BossAuthState extends ChangeNotifier {
  static const _store = FlutterSecureStorage();
  static const _kLoginId   = 'boss_login_id';
  static const _kName      = 'boss_name';
  static const _kRole      = 'boss_role';
  static const _kGymId     = 'boss_gym_id';
  static const _kGymName   = 'boss_gym_name';
  static const _kCsrf      = 'boss_csrf_token';
  static const _kCookie    = 'boss_session_cookie';

  bool _loggedIn = false;
  String? _loginId;
  String? _name;
  String? _role;
  int?    _gymId;
  String? _gymName;
  String? _csrfToken;
  String? _sessionCookie; // "session=xxxx" raw header value

  bool get isLoggedIn     => _loggedIn;
  String? get loginId     => _loginId;
  String? get name        => _name;
  String? get role        => _role;
  int?    get gymId       => _gymId;
  String? get gymName     => _gymName;
  String? get csrfToken   => _csrfToken;
  String? get sessionCookie => _sessionCookie;

  Future<void> load() async {
    _loginId = await _store.read(key: _kLoginId);
    _name    = await _store.read(key: _kName);
    _role    = await _store.read(key: _kRole);
    final gid = await _store.read(key: _kGymId);
    _gymId   = gid == null ? null : int.tryParse(gid);
    _gymName = await _store.read(key: _kGymName);
    _csrfToken = await _store.read(key: _kCsrf);
    _sessionCookie = await _store.read(key: _kCookie);
    _loggedIn = _loginId != null && _sessionCookie != null;
    notifyListeners();
  }

  Future<void> save({
    required String loginId,
    required String name,
    required String role,
    required int gymId,
    required String gymName,
    required String csrfToken,
    required String sessionCookie,
  }) async {
    _loginId = loginId;
    _name = name;
    _role = role;
    _gymId = gymId;
    _gymName = gymName;
    _csrfToken = csrfToken;
    _sessionCookie = sessionCookie;
    _loggedIn = true;
    await Future.wait([
      _store.write(key: _kLoginId, value: loginId),
      _store.write(key: _kName,    value: name),
      _store.write(key: _kRole,    value: role),
      _store.write(key: _kGymId,   value: gymId.toString()),
      _store.write(key: _kGymName, value: gymName),
      _store.write(key: _kCsrf,    value: csrfToken),
      _store.write(key: _kCookie,  value: sessionCookie),
    ]);
    notifyListeners();
  }

  Future<void> clear() async {
    _loggedIn = false;
    _loginId = _name = _role = _gymName = _csrfToken = _sessionCookie = null;
    _gymId = null;
    await Future.wait([
      _store.delete(key: _kLoginId),
      _store.delete(key: _kName),
      _store.delete(key: _kRole),
      _store.delete(key: _kGymId),
      _store.delete(key: _kGymName),
      _store.delete(key: _kCsrf),
      _store.delete(key: _kCookie),
    ]);
    notifyListeners();
  }
}
