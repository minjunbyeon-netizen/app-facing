import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/auth/auth_state.dart';
import 'package:hyphen_app/features/onboarding/onboarding_basic.dart';
import 'package:hyphen_app/features/profile/profile_state.dart';
import 'package:hyphen_app/features/signup/self_signup_screen.dart';

import 'fakes.dart';
import 'harness.dart';
import 'layout_stability.dart';

/// 레이아웃 안정성(layout stability) 회귀 게이트 — 가입 신청 폼 · 온보딩 내 정보.
/// 규격 정본 = `docs/DESIGN-SSOT.md` §레이아웃 안정성 — 공간 예약.
///
/// 이 앱에서 입력칸이 가장 많은 두 화면이다. 가입 폼은
/// `AutovalidateMode.onUserInteraction` 이라 **타이핑 도중** 검증이 돌아, 에러 줄
/// 자리를 예약해 두지 않으면 한 칸에서 경고가 뜰 때마다 그 아래 칸과 버튼이 한 줄씩
/// 밀린다 (입력 중에 칸이 움직이면 오타를 부른다). 이 테스트가 실패하면
/// 조건부 블록·검증 에러 줄·로딩 교체 셋 중 하나가 되살아났는지부터 본다.
void main() {
  testWidgets('가입 신청 — 5 상태에서 앵커 y 좌표가 전부 같다', (tester) async {
    _tallPhone(tester);
    final table = await expectStableAnchorY(
      tester,
      states: {
        '빈 폼': _signupEmpty,
        '생년월일만 에러': _signupOneError,
        '여러 칸 동시 에러': _signupManyErrors,
        '경력 선택 후': _signupBandPicked,
        '신청 중': _signupBusy,
      },
      anchors: {
        '연락처칸': SelfSignupScreen.kPhoneField,
        '아이디칸': SelfSignupScreen.kIdField,
        '비밀번호칸': SelfSignupScreen.kPwField,
        '비밀번호확인칸': SelfSignupScreen.kPw2Field,
        '신청버튼': SelfSignupScreen.kSubmit,
        '안내문구': SelfSignupScreen.kFooter,
      },
    );
    // ignore: avoid_print — 표를 그대로 보고에 쓴다.
    print(formatAnchorTable(table));
  });

  testWidgets('온보딩 내 정보 — 4 상태에서 앵커 y 좌표가 전부 같다', (tester) async {
    _tallPhone(tester);
    final table = await expectStableAnchorY(
      tester,
      states: {
        '기본': _onbDefault,
        '생년월일 에러': _onbBirthError,
        '경력 선택 후': _onbBandPicked,
        '에러 + 경력 선택': _onbBirthErrorWithBand,
      },
      anchors: {
        '전화칸': OnboardingBasicScreen.kPhoneField,
        '성별': OnboardingBasicScreen.kGender,
        '경력뱃지': OnboardingBasicScreen.kBands,
        '시작버튼': OnboardingBasicScreen.kSubmit,
      },
    );
    // ignore: avoid_print
    print(formatAnchorTable(table));
  });
}

/// 두 화면 다 폰 한 화면(780)보다 길다. 스크롤이 섞이면 y 가 스크롤 오프셋만큼
/// 달라져 **밀림이 아닌 것을 밀림으로** 읽으므로, 전체가 한 번에 들어오는 높은
/// 뷰포트에서 잰다 (폭은 갤S22 그대로 360 — 줄바꿈 조건을 실물과 같게 둔다).
void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(720, 2800);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// 무한 애니메이션(스피너)이 있어도 안전한 정착 — pumpAndSettle 금지.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

// ── 가입 신청 폼 ──────────────────────────────────────────────────────────

Future<void> _pumpSignup(WidgetTester tester, {FakeApi? api}) async {
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  await tester.pumpWidget(
    harness(
      api: api ?? FakeApi(memberWorld()),
      auth: AuthState(),
      profile: ProfileState(),
      // 상태마다 새 key = 새 State. 같은 타입을 그대로 다시 pump 하면 Flutter 가
      // element 를 재사용해 **앞 상태의 입력값·선택이 그대로 남는다** — 상태가
      // 서로 오염되면 y 표가 무엇을 잰 것인지 알 수 없다.
      home: SelfSignupScreen(key: UniqueKey()),
    ),
  );
  await _settle(tester);
}

/// (a) 빈 폼 — 화면에 막 들어왔을 때. 나머지 상태의 기준선이다.
Future<void> _signupEmpty(WidgetTester tester) => _pumpSignup(tester);

/// (b) 한 칸만 에러 — 생년월일에 없는 연도를 넣어 그 칸만 빨개진 상태.
Future<void> _signupOneError(WidgetTester tester) async {
  await _pumpSignup(tester);
  await tester.enterText(find.byKey(SelfSignupScreen.kBirthField), '20991231');
  await _settle(tester);
  expect(find.text('연도를 확인해 주세요.'), findsOneWidget);
}

/// (c) 여러 칸 동시 에러 — 빈 폼으로 제출을 눌러 이름·아이디·비밀번호가
/// 한꺼번에 빨개진 상태 (버튼을 누르는 것과 같은 경로 = FormState.validate).
Future<void> _signupManyErrors(WidgetTester tester) async {
  await _pumpSignup(tester);
  await tester.tap(find.byKey(SelfSignupScreen.kSubmit));
  await _settle(tester);
  expect(find.text('이름을 입력해 주세요.'), findsOneWidget);
  expect(find.text('아이디는 4자 이상 입력해 주세요.'), findsOneWidget);
  expect(find.text('비밀번호는 4자 이상 입력해 주세요.'), findsOneWidget);
}

/// (d) 경력 선택 후 — '내 레벨' 미리보기가 안내 한 줄을 밀어내고 들어온 상태.
Future<void> _signupBandPicked(WidgetTester tester) async {
  await _pumpSignup(tester);
  await _pickFirstBand(tester);
  expect(find.text('내 레벨'), findsOneWidget);
  expect(find.text('경력을 고르면 레벨이 표시됩니다.'), findsNothing);
}

/// (e) 신청 중 — 서버 응답을 기다리는 동안. 버튼 자리는 그대로다.
Future<void> _signupBusy(WidgetTester tester) async {
  await _pumpSignup(
    tester,
    // 가입 신청 POST 만 영원히 보류 — 체육관 조회(gyms-list)는 그대로 통과.
    api: FakeApi(memberWorld(), hangPaths: const {'/api/v1/member/gyms/'}),
  );
  await tester.enterText(find.byKey(SelfSignupScreen.kNameField), '김서준');
  await tester.enterText(find.byKey(SelfSignupScreen.kIdField), 'seojun');
  await tester.enterText(find.byKey(SelfSignupScreen.kPwField), 'hyphen1234');
  await tester.enterText(find.byKey(SelfSignupScreen.kPw2Field), 'hyphen1234');
  await _settle(tester);
  await tester.tap(find.byKey(SelfSignupScreen.kSubmit));
  await _settle(tester);
  // 버튼이 스피너로 바뀌었는지 = 실제로 신청 중인지.
  expect(
    find.descendant(
      of: find.byKey(SelfSignupScreen.kSubmit),
      matching: find.byType(CircularProgressIndicator),
    ),
    findsOneWidget,
  );
}

// ── 온보딩 내 정보 ────────────────────────────────────────────────────────

Future<void> _pumpOnboarding(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  await tester.pumpWidget(
    harness(
      api: FakeApi(memberWorld()),
      auth: AuthState(),
      profile: ProfileState(),
      // 가입 폼과 같은 이유로 상태마다 새 key (앞 상태 오염 차단).
      home: OnboardingBasicScreen(key: UniqueKey()),
    ),
  );
  await _settle(tester);
}

Future<void> _onbDefault(WidgetTester tester) => _pumpOnboarding(tester);

Future<void> _onbBirthError(WidgetTester tester) async {
  await _pumpOnboarding(tester);
  await _enterBadBirth(tester);
}

Future<void> _onbBandPicked(WidgetTester tester) async {
  await _pumpOnboarding(tester);
  await _pickFirstBand(tester);
  expect(find.text('내 레벨'), findsOneWidget);
}

Future<void> _onbBirthErrorWithBand(WidgetTester tester) async {
  await _pumpOnboarding(tester);
  await _enterBadBirth(tester);
  await _pickFirstBand(tester);
  expect(find.text('연도를 확인해 주세요.'), findsOneWidget);
  expect(find.text('내 레벨'), findsOneWidget);
}

Future<void> _enterBadBirth(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(OnboardingBasicScreen.kBirthField),
    '20991231',
  );
  await _settle(tester);
  expect(find.text('연도를 확인해 주세요.'), findsOneWidget);
}

/// 경력 구간 첫 뱃지를 고른다 — 두 화면이 같은 `Tier.bands` 를 쓴다.
Future<void> _pickFirstBand(WidgetTester tester) async {
  await tester.tap(find.text('1년 미만'));
  await _settle(tester);
}
