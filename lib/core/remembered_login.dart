import 'package:shared_preferences/shared_preferences.dart';

import 'app_clock.dart';

/// v3.18 (2026-08-25 사용자 요청) — 로그인 화면 '아이디 기억하기 (30일)'.
///
/// **아이디만** 기억한다. 비밀번호는 저장하지 않는다 — 폰을 빌려주거나 잃어버렸을
/// 때 그대로 계정이 넘어가기 때문이다. 기억한 아이디는 30일이 지나면 스스로
/// 사라진다 (다음 로그인 화면 진입 때 정리).
///
/// 화면(회원·코치)마다 따로 저장한다 — 한 폰에서 코치 계정과 본인 회원 계정을
/// 번갈아 쓰는 경우가 실제로 있다.
class RememberedLogin {
  RememberedLogin._();

  /// 회원 로그인 화면.
  static const String member = 'member';

  /// 코치 로그인 화면.
  static const String coach = 'coach';

  /// 기억 기간. 화면 문구('30일')와 같은 값을 써야 한다 (§0-B).
  static const int days = 30;

  static String _idKey(String scope) => 'remembered_login_id_$scope';
  static String _untilKey(String scope) => 'remembered_login_until_$scope';

  /// 기억해 둔 아이디. 없거나 30일이 지났으면 null (지난 값은 지우고 반환).
  static Future<String?> load(String scope) async {
    final sp = await SharedPreferences.getInstance();
    final id = sp.getString(_idKey(scope));
    if (id == null || id.isEmpty) return null;
    final until = sp.getInt(_untilKey(scope)) ?? 0;
    if (until <= appClock.now().millisecondsSinceEpoch) {
      await clear(scope);
      return null;
    }
    return id;
  }

  /// 로그인 성공 시점부터 30일간 기억.
  static Future<void> save(String scope, String loginId) async {
    final id = loginId.trim();
    if (id.isEmpty) return;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_idKey(scope), id);
    await sp.setInt(
      _untilKey(scope),
      appClock.now().add(const Duration(days: days)).millisecondsSinceEpoch,
    );
  }

  /// 체크를 풀고 로그인했을 때 — 남아 있던 값도 같이 지운다.
  static Future<void> clear(String scope) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_idKey(scope));
    await sp.remove(_untilKey(scope));
  }
}
