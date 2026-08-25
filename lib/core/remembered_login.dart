import 'package:shared_preferences/shared_preferences.dart';

import 'app_clock.dart';

/// v3.18 (2026-08-25 사용자 요청) — 로그인 화면 '아이디 기억하기 (30일)'.
///
/// **아이디만** 기억한다. 비밀번호는 저장하지 않는다 — 폰을 빌려주거나 잃어버렸을
/// 때 그대로 계정이 넘어가기 때문이다. 기억한 아이디는 30일이 지나면 스스로
/// 사라진다 (다음 로그인 화면 진입 때 정리).
///
/// v3.19 (2026-08-25 로그인 창구 통합): 회원·코치 두 칸이던 것을 한 칸으로 합쳤다.
/// 창구가 하나라 화면이 어느 쪽인지 미리 알 수 없고(계정 유형 판정은 서버가 한다),
/// 마지막에 로그인한 아이디 하나만 기억하면 된다. 구 두 칸에 남아 있던 값은
/// [load] 가 한 번 흡수해 옮긴다 — 어제 체크해 둔 사람이 다시 치지 않도록.
class RememberedLogin {
  RememberedLogin._();

  /// 기억 기간. 화면 문구('30일')와 같은 값을 써야 한다 (§0-B).
  static const int days = 30;

  static const String _idKey = 'remembered_login_id';
  static const String _untilKey = 'remembered_login_until';

  /// 구 두 칸 (v3.18 한정). 흡수 후 지운다.
  static const List<String> _legacyScopes = ['member', 'coach'];

  /// 기억해 둔 아이디. 없거나 30일이 지났으면 null (지난 값은 지우고 반환).
  static Future<String?> load() async {
    final sp = await SharedPreferences.getInstance();
    await _absorbLegacy(sp);
    final id = sp.getString(_idKey);
    if (id == null || id.isEmpty) return null;
    final until = sp.getInt(_untilKey) ?? 0;
    if (until <= appClock.now().millisecondsSinceEpoch) {
      await clear();
      return null;
    }
    return id;
  }

  /// 로그인 성공 시점부터 30일간 기억.
  static Future<void> save(String loginId) async {
    final id = loginId.trim();
    if (id.isEmpty) return;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_idKey, id);
    await sp.setInt(
      _untilKey,
      appClock.now().add(const Duration(days: days)).millisecondsSinceEpoch,
    );
  }

  /// 체크를 풀고 로그인했을 때 — 남아 있던 값도 같이 지운다.
  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_idKey);
    await sp.remove(_untilKey);
  }

  /// 구 회원/코치 칸 → 단일 칸. 만료 시각까지 그대로 옮기고 구 키는 지운다.
  /// 둘 다 남아 있으면 만료가 더 나중인 쪽(= 더 최근에 로그인한 쪽)이 이긴다.
  static Future<void> _absorbLegacy(SharedPreferences sp) async {
    String? bestId;
    int bestUntil = 0;
    var found = false;
    for (final scope in _legacyScopes) {
      final idKey = 'remembered_login_id_$scope';
      final untilKey = 'remembered_login_until_$scope';
      final id = sp.getString(idKey);
      if (id == null) continue;
      found = true;
      final until = sp.getInt(untilKey) ?? 0;
      if (id.isNotEmpty && until > bestUntil) {
        bestId = id;
        bestUntil = until;
      }
      await sp.remove(idKey);
      await sp.remove(untilKey);
    }
    if (!found) return;
    // 이미 새 칸에 값이 있으면 그쪽이 최신 — 구 값은 버린다.
    if (bestId != null && sp.getString(_idKey) == null) {
      await sp.setString(_idKey, bestId);
      await sp.setInt(_untilKey, bestUntil);
    }
  }
}
