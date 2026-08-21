import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/achievement/confetti_overlay.dart';

import 'package:hyphen_app/features/achievement/achievements_screen.dart';
import 'package:hyphen_app/features/achievement/unlock_toast.dart';
import 'package:hyphen_app/models/achievement.dart';

import 'fakes.dart';
import 'harness.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

/// 업적 등급·판 모양이 실제로 구분돼 보이는지 픽셀로 고정한다.
/// 팩 체크리스트(README §11): 전설이 검은 판인지 · 32px 이하에서도 원/둥근네모/
/// 방패가 갈리는지 · 잠긴 배지가 회색인지 · 숨김이 자물쇠인지.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(signedInPrefs());
    // 폭죽이 매번 다른 자리에 떨어지면 골든이 못 고정된다 — 시드 고정.
    confettiRandom = math.Random(42);
  });

  tearDown(() {
    confettiRandom = null;
  });

  testWidgets('업적 — 등급 4단 + 판 3모양 (전부 해금)', (tester) async {
    phone(tester);
    final api = FakeApi({
      ...memberWorld(),
      '/api/v1/achievements': achievementsAllRarities,
    });
    await tester.pumpWidget(harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      home: const AchievementsScreen(),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await capture(tester, 'ach_01_rarities');
  });

  testWidgets('업적 해금 축하 — 전설 토스트 + 컨페티', (tester) async {
    phone(tester);
    final api = FakeApi(memberWorld());
    await tester.pumpWidget(harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      home: const AchievementsScreen(),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    final ctx = tester.element(find.byType(AchievementsScreen));
    // showAll 은 순차 대기가 있어 await 하면 타이머가 남는다 — 발사만 하고 픽셀을 본다.
    unawaitedShow(ctx);
    await tester.pump(const Duration(milliseconds: 400));
    await capture(tester, 'ach_02_unlock_toast');
    // 남은 스낵바·컨페티 타이머 정리
    await tester.pump(const Duration(seconds: 3));
  });
}

void unawaitedShow(dynamic ctx) {
  UnlockToast.showAll(ctx, const [
    AchievementUnlockResult(
      code: 'GAMES_1',
      name: 'Games Finisher.',
      rarity: 'Legendary',
    ),
  ]);
}
