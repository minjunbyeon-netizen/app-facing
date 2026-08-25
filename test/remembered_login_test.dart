// v3.18 (2026-08-25) — 로그인 '아이디 기억하기 (30일)' 회귀.
//
// 지키는 것: 아이디만 저장 · 30일 지나면 스스로 사라짐 · 회원/코치 칸 분리.
import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_app/core/app_clock.dart';
import 'package:hyphen_app/core/remembered_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('저장한 아이디를 다시 읽는다', () async {
    await RememberedLogin.save(RememberedLogin.member, 'seojun');
    expect(await RememberedLogin.load(RememberedLogin.member), 'seojun');
  });

  test('비밀번호는 저장하지 않는다 — 남는 키는 아이디·만료 2개뿐', () async {
    await RememberedLogin.save(RememberedLogin.coach, 'coach1');
    final sp = await SharedPreferences.getInstance();
    expect(sp.getKeys(),
        {'remembered_login_id_coach', 'remembered_login_until_coach'});
  });

  test('회원·코치 칸은 서로 섞이지 않는다', () async {
    await RememberedLogin.save(RememberedLogin.member, 'member1');
    await RememberedLogin.save(RememberedLogin.coach, 'coach1');
    expect(await RememberedLogin.load(RememberedLogin.member), 'member1');
    expect(await RememberedLogin.load(RememberedLogin.coach), 'coach1');
  });

  test('30일이 지나면 사라진다 (읽는 김에 정리)', () async {
    final past = appClock
        .now()
        .subtract(const Duration(days: 1))
        .millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'remembered_login_id_member': 'seojun',
      'remembered_login_until_member': past,
    });
    expect(await RememberedLogin.load(RememberedLogin.member), isNull);
    final sp = await SharedPreferences.getInstance();
    expect(sp.getKeys(), isEmpty); // 만료분은 남기지 않는다
  });

  test('만료 시각은 저장 시점 + 30일', () async {
    await RememberedLogin.save(RememberedLogin.member, 'seojun');
    final sp = await SharedPreferences.getInstance();
    final until = DateTime.fromMillisecondsSinceEpoch(
        sp.getInt('remembered_login_until_member')!);
    final expected = appClock.now().add(const Duration(days: 30));
    expect(until.difference(expected).inMinutes.abs(), lessThan(2));
  });

  test('체크를 풀고 로그인하면 지운다', () async {
    await RememberedLogin.save(RememberedLogin.member, 'seojun');
    await RememberedLogin.clear(RememberedLogin.member);
    expect(await RememberedLogin.load(RememberedLogin.member), isNull);
  });
}
