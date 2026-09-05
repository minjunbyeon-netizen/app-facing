// 완료 시트의 '수업 내용' 은 **파트를 잘라 먹지 않는다** (2026-09-05 실사용 검증에서 발견).
//
// 코치가 A·B 파트로 짠 수업을 회원이 완료하려고 시트를 열면, 아래 '내 기록' 에는
// B 파트 동작(Thruster·Pull-up·Box Jump)이 입력 칸으로 서는데 위 '수업 내용' 은
// 넉 줄에서 잘려 **A 파트만** 보였다. 자기가 지금 적는 것이 무엇인지 못 보는 화면이다.
// (`maxLines: 4` 는 파트가 생기기 전 D109 이전의 값이었다.)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/gym/wod_result_sheet.dart';
import 'package:hyphen_app/models/gym.dart';

import 'golden/fakes.dart';
import 'golden/harness.dart';
import 'golden/screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

void main() {
  testWidgets('완료 시트 — A·B 파트가 모두 보인다 (넉 줄에서 안 잘린다)', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();

    // 실제로 코치가 짠 모양 — 파트 둘, 동작 넷, 메모 한 줄.
    final raw = Map<String, dynamic>.from(
      gymWods().firstWhere((p) => p['id'] == 31),
    );
    raw['content'] = 'AWAKE\n'
        'A 파트 · 15분 · STRENGTH · 5라운드\n'
        'Back Squat 5-5-5-5-5회 · 60kg\n'
        '\n'
        'B 파트 · 20분 · AMRAP · 캡 20분\n'
        'Thruster 12회 · 40kg\n'
        'Pull-up 9회\n'
        'Box Jump 15회\n'
        '\n'
        'A 파트는 무게를 올리며 5라운드.';
    final post = GymWodPost.fromJson(raw);

    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: Scaffold(
          body: SingleChildScrollView(child: WodResultSheet(wod: post)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final content = tester.widget<Text>(
      find.byKey(WodResultSheet.kWodContent),
    );
    expect(
      content.maxLines,
      isNull,
      reason: '수업 내용에 줄 수 제한이 걸려 있다 — 파트가 잘린다',
    );
    // 실제로 그려진 글자에도 B 파트가 있는지 본다 (제한만 푸는 것으로는 부족).
    expect(find.textContaining('B 파트'), findsWidgets);
    expect(find.textContaining('Box Jump 15회'), findsWidgets);
  });
}
