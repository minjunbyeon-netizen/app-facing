import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/core/app_clock.dart';
import 'package:hyphen_app/core/exception.dart';
import 'package:hyphen_app/features/auth/auth_state.dart';
import 'package:hyphen_app/features/auth/login_screen.dart';
import 'package:hyphen_app/features/profile/profile_state.dart';

import 'fakes.dart';
import 'harness.dart';
import 'layout_stability.dart';

/// 로그인 화면이 가질 수 있는 상태 전부 (v3.33 · 2026-08-27).
///
/// **골든(픽셀)과 y 좌표 검사가 같은 절차를 공유한다** — 한쪽만 고쳐 두 검증이
/// 서로 다른 화면을 보게 되는 일을 막는다 (글로벌 §0-B). 상태를 늘리면
/// `states_golden_test.dart` 의 캡처와 `layout_stability_test.dart` 의 y 검사가
/// 자동으로 같이 늘어난다.

/// 로딩 상태를 붙잡아 두는 문 — 완료되지 않는다 (타이머가 아니라 미완료 future).
final Completer<void> loginHold = Completer<void>();

/// 무한 애니메이션(스피너)이 있어도 안전한 정착 — pumpAndSettle 금지.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpLogin(
  WidgetTester tester, {
  Map<String, Object> prefs = const <String, Object>{},
  FakeBossApi? bossApi,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  await tester.pumpWidget(
    harness(
      api: FakeApi(memberWorld()),
      auth: AuthState(),
      profile: ProfileState(),
      bossApi: bossApi,
      home: const LoginScreen(),
    ),
  );
  await _settle(tester);
}

Future<void> _fill(WidgetTester tester) async {
  await tester.enterText(find.byKey(LoginScreen.kIdField), 'seojun');
  await tester.pump();
  await tester.enterText(find.byKey(LoginScreen.kPwField), 'hyphen1234');
  await tester.pump();
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.byKey(LoginScreen.kSubmit));
  await _settle(tester);
}

/// (a) 기본 — 앱을 처음 열었을 때.
Future<void> loginDefault(WidgetTester tester) => _pumpLogin(tester);

/// (b) 아이디 기억 — 30일 안에 로그인한 적이 있어 아이디가 채워진 상태.
Future<void> loginRemembered(WidgetTester tester) => _pumpLogin(
  tester,
  prefs: {
    'remembered_login_id': 'seojun',
    'remembered_login_until': appClock
        .now()
        .add(const Duration(days: 30))
        .millisecondsSinceEpoch,
  },
);

/// (c) 세션 만료 안내 — 코치 셸이 401 을 받고 사유와 함께 밀어 넣은 화면 (D59).
/// 여기서는 **뒤로 갈 곳이 있는** 경로로 띄운다 — 상단 띠에 화살표가 생겨도
/// 본문이 밀리지 않는지까지 같이 본다.
Future<void> loginSessionExpired(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  await tester.pumpWidget(
    harness(
      api: FakeApi(memberWorld()),
      auth: AuthState(),
      profile: ProfileState(),
      home: const Scaffold(body: SizedBox.shrink()),
    ),
  );
  await tester.pump();
  Navigator.of(tester.element(find.byType(Scaffold))).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(
        name: '/login',
        arguments: {
          LoginScreen.argNotice: LoginScreen.noticeSessionExpired,
        },
      ),
      builder: (_) => const LoginScreen(),
    ),
  );
  await _settle(tester);
  await _settle(tester);
}

/// (d) 로그인 실패 — 서버가 아이디·비밀번호 불일치를 돌려준 상태.
Future<void> loginFailed(WidgetTester tester) async {
  await _pumpLogin(
    tester,
    bossApi: FakeBossApi(
      const {},
      failures: {
        '/api/v1/auth/login': AppException(
          '아이디 또는 비밀번호가 올바르지 않습니다.',
          code: 'INVALID_CREDENTIALS',
          statusCode: 401,
        ),
      },
    ),
  );
  await _fill(tester);
  await _submit(tester);
}

/// (e) 빈 칸 제출 — 두 입력칸의 검증 에러가 동시에 뜬 상태.
Future<void> loginValidationErrors(WidgetTester tester) async {
  await _pumpLogin(tester);
  await _submit(tester);
}

/// (f) 로딩 중 — 서버 응답을 기다리는 동안. 버튼 자리는 그대로다.
Future<void> loginBusy(WidgetTester tester) async {
  await _pumpLogin(
    tester,
    bossApi: FakeBossApi(const {}, hold: loginHold.future),
  );
  await _fill(tester);
  await _submit(tester);
}

/// 6 상태 — 골든과 y 검사가 함께 도는 목록.
Map<String, ScreenState> loginStates() => {
  '기본': loginDefault,
  '아이디 기억': loginRemembered,
  '세션 만료 안내': loginSessionExpired,
  '로그인 실패': loginFailed,
  '입력 검증 에러': loginValidationErrors,
  '로딩 중': loginBusy,
};

/// 상태가 바뀌어도 y 가 움직이면 안 되는 요소들.
Map<String, Key> loginAnchors() => {
  '아이디칸': LoginScreen.kIdField,
  '비밀번호칸': LoginScreen.kPwField,
  '로그인버튼': LoginScreen.kSubmit,
  '가입신청': LoginScreen.kSignup,
  '약관': LoginScreen.kLegal,
};
