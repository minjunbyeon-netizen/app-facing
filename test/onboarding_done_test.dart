// 온보딩 완료 서버 판정 (2026-08-19 — 잔존 갭 '온보딩 완료 영속 서버화').
//
// GET /api/v1/member/me/profile 응답으로 완료를 판정하는 규칙 고정:
// 이름 + level(경력에서 서버가 계산) 둘 다 있어야 완료. 코치가 PC 에서
// 대신 적어준 경우도 완료로 본다 (다시 묻지 않기 위한 기능이므로).

import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_app/features/profile/profile_state.dart';

void main() {
  test('이름+level 있으면 완료', () {
    expect(
      ProfileState.onboardingDoneFrom(
          {'name': '김도윤', 'level': 'RXD', 'gender': '남'}),
      isTrue,
    );
  });

  test('level 없으면 미완료 — 경력 질문에 답한 적 없음', () {
    expect(
      ProfileState.onboardingDoneFrom(
          {'name': '김도윤', 'level': null, 'gender': '남'}),
      isFalse,
    );
  });

  test('이름 없으면 미완료 — 온보딩 필수 입력', () {
    expect(
      ProfileState.onboardingDoneFrom({'name': '', 'level': 'Scaled'}),
      isFalse,
    );
  });

  test('키 자체가 없는 응답(구버전 서버)도 미완료로 안전 폴백', () {
    expect(ProfileState.onboardingDoneFrom(const {}), isFalse);
  });
}
