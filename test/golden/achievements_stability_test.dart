import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/achievement/achievements_screen.dart';

import 'fakes.dart';
import 'harness.dart';
import 'layout_stability.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

/// 업적 목록(v3.35 E 안) 레이아웃 안정성 게이트 — DESIGN-SSOT §레이아웃 안정성.
///
/// 로딩(스켈레톤) → 완료로 바뀌어도 요약 카드·3칸 전환·첫 분류 라벨·첫 행의 y 가
/// 같아야 한다. 실패하면 스켈레톤과 실제 행의 높이가 어긋났다는 뜻이다 —
/// `_AchievementsScreenState.kRowH`·`_Summary.height`·`HkSegment.height`·
/// `AchievementGroupLabel.height` 중 한쪽만 바뀌었는지부터 본다.
void main() {
  testWidgets('업적 목록 — 로딩·완료 두 상태에서 앵커 y 좌표가 같다', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());

    Future<void> mount(WidgetTester t, FakeApi api) async {
      await t.pumpWidget(
        harness(
          api: api,
          auth: await signedInAuth(),
          profile: rxProfile(),
          home: const AchievementsScreen(),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
    }

    final states = <String, ScreenState>{
      'loading': (t) =>
          mount(t, FakeApi(memberWorld(), hangPaths: {'/api/v1/achievements'})),
      'ready': (t) => mount(t, FakeApi(memberWorld())),
    };
    final table = await expectStableAnchorY(
      tester,
      states: states,
      anchors: {
        'summary': AchievementsAnchors.summary,
        'segment': AchievementsAnchors.segment,
        'group0': AchievementsAnchors.firstGroup,
        'row0': AchievementsAnchors.firstRow,
      },
    );
    // ignore: avoid_print — 표를 그대로 보고용으로 남긴다.
    print(formatAnchorTable(table));
  });
}
