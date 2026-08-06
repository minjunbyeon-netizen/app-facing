// InboxScreen(재활 가이드) 렌더 회귀 위젯 테스트.
//
// 2026-07-28 재작성 2차: 원 테스트는 v1.22 에서 폐지된 4탭(ALL/NOTES/ASSIGNMENTS/
// OUTBOX) UI 를 검증하고 있었다 — 현행 계약(NOTICE 단일 피드)으로 갱신.
// 래핑도 자체 최소 provider → 골든 하네스(main.dart 미러) 재사용으로 교체:
// 화면이 읽는 provider 가 늘 때마다 깨지던 구조(ProviderNotFound·가짜 repo 구멍
// → 실 dio 대기 10분 타임아웃)를 제거.
//
// 검증:
// - 코치(owner)·멤버(approved) 모두 화면 build 통과 (예외 0)
// - AppBar '재활 가이드' 노출 (2026-08-06 제목 정정 — 쪽지·공지는 알림함이 담당)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:facing_app/features/auth/auth_state.dart';
import 'package:facing_app/features/gym/gym_repository.dart';
import 'package:facing_app/features/gym/gym_state.dart';
import 'package:facing_app/features/inbox/inbox_screen.dart';
import 'package:facing_app/features/profile/profile_state.dart';

import 'golden/fakes.dart';
import 'golden/harness.dart';

Future<GymState> _loadedGym(FakeApi api) async {
  final gym = GymState(GymRepository(api), sse: FakeSse());
  await gym.loadMine();
  return gym;
}

Future<void> _pumpNotice(WidgetTester tester, FakeApi api) async {
  phone(tester);
  await tester.pumpWidget(harness(
      api: api,
      auth: AuthState(),
      profile: ProfileState(),
      gym: await _loadedGym(api),
      home: const InboxScreen()));
  // pumpAndSettle 금지 — 끝나지 않는 애니메이션이 있어 타임아웃. 유한 pump.
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('InboxScreen(재활 가이드) 렌더', () {
    testWidgets('코치 (owner) → 재활 가이드 build 통과', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final world = memberWorld()
        ..['/api/v1/gyms/mine'] = {...gymsMine, 'role': 'owner'};
      await _pumpNotice(tester, FakeApi(world));

      expect(
          find.descendant(
              of: find.byType(AppBar), matching: find.text('재활 가이드')),
          findsOneWidget);
    });

    testWidgets('멤버 (approved) → 재활 가이드 build 통과', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpNotice(tester, FakeApi(memberWorld())); // 기본 = member/approved

      expect(
          find.descendant(
              of: find.byType(AppBar), matching: find.text('재활 가이드')),
          findsOneWidget);
    });
  });
}

