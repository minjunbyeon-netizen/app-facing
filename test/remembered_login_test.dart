// v3.18 (2026-08-25) — 로그인 '아이디 기억하기 (30일)' 회귀.
// v3.19 (같은 날, 로그인 창구 통합) — 회원/코치 두 칸 → 한 칸. 구 값 흡수 포함.
//
// 지키는 것: 아이디만 저장 · 30일 지나면 스스로 사라짐 · 구 두 칸을 한 번에 흡수.
import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_app/core/app_clock.dart';
import 'package:hyphen_app/core/remembered_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('저장한 아이디를 다시 읽는다', () async {
    await RememberedLogin.save('seojun');
    expect(await RememberedLogin.load(), 'seojun');
  });

  test('비밀번호는 저장하지 않는다 — 남는 키는 아이디·만료 2개뿐', () async {
    await RememberedLogin.save('coach1');
    final sp = await SharedPreferences.getInstance();
    expect(sp.getKeys(), {'remembered_login_id', 'remembered_login_until'});
  });

  test('30일이 지나면 사라진다 (읽는 김에 정리)', () async {
    final past = appClock
        .now()
        .subtract(const Duration(days: 1))
        .millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'remembered_login_id': 'seojun',
      'remembered_login_until': past,
    });
    expect(await RememberedLogin.load(), isNull);
    final sp = await SharedPreferences.getInstance();
    expect(sp.getKeys(), isEmpty); // 만료분은 남기지 않는다
  });

  test('만료 시각은 저장 시점 + 30일', () async {
    await RememberedLogin.save('seojun');
    final sp = await SharedPreferences.getInstance();
    final until = DateTime.fromMillisecondsSinceEpoch(
        sp.getInt('remembered_login_until')!);
    final expected = appClock.now().add(const Duration(days: 30));
    expect(until.difference(expected).inMinutes.abs(), lessThan(2));
  });

  test('체크를 풀고 로그인하면 지운다', () async {
    await RememberedLogin.save('seojun');
    await RememberedLogin.clear();
    expect(await RememberedLogin.load(), isNull);
  });

  // ── v3.19 창구 통합: 구 두 칸(회원·코치) 흡수 ────────────────────────
  test('구 회원 칸에 남아 있던 아이디를 그대로 이어받는다', () async {
    final until =
        appClock.now().add(const Duration(days: 10)).millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'remembered_login_id_member': 'seojun',
      'remembered_login_until_member': until,
    });
    expect(await RememberedLogin.load(), 'seojun');
    final sp = await SharedPreferences.getInstance();
    // 구 키는 흡수 후 남지 않는다.
    expect(sp.getKeys(), {'remembered_login_id', 'remembered_login_until'});
    expect(sp.getInt('remembered_login_until'), until); // 만료 시각도 그대로
  });

  test('구 두 칸이 다 있으면 더 최근에 로그인한 쪽이 이긴다', () async {
    final now = appClock.now();
    SharedPreferences.setMockInitialValues({
      'remembered_login_id_member': 'member1',
      'remembered_login_until_member':
          now.add(const Duration(days: 5)).millisecondsSinceEpoch,
      'remembered_login_id_coach': 'coach1',
      'remembered_login_until_coach':
          now.add(const Duration(days: 20)).millisecondsSinceEpoch,
    });
    expect(await RememberedLogin.load(), 'coach1');
  });

  test('새 칸에 값이 있으면 구 값은 버리고 새 값을 쓴다', () async {
    final now = appClock.now();
    SharedPreferences.setMockInitialValues({
      'remembered_login_id': 'newest',
      'remembered_login_until':
          now.add(const Duration(days: 30)).millisecondsSinceEpoch,
      'remembered_login_id_coach': 'coach1',
      'remembered_login_until_coach':
          now.add(const Duration(days: 20)).millisecondsSinceEpoch,
    });
    expect(await RememberedLogin.load(), 'newest');
    final sp = await SharedPreferences.getInstance();
    expect(sp.getKeys(), {'remembered_login_id', 'remembered_login_until'});
  });
}
