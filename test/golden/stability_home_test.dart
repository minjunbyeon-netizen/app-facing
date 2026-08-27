import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/achievement/achievement_section.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/home/home_screen.dart';
import 'package:hyphen_app/features/shell/main_shell.dart';
import 'package:hyphen_app/widgets/hkit.dart';
import 'package:hyphen_app/widgets/offline_banner.dart';

import 'fakes.dart';
import 'harness.dart';
import 'layout_stability.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

/// 홈 레이아웃 안정성(layout stability) 회귀 게이트 — DESIGN-SSOT §레이아웃 안정성.
///
/// 홈은 밀림이 네 겹으로 쌓여 있던 화면이다. 공지·업적·출석·오프라인 배너가 각각
/// 따로 도착하며 그 아래를 통째로 밀어냈다. v3.34 에서 넷 다 자리를 미리 잡았고,
/// 이 테스트가 그것을 **좌표로** 증명한다 — 어느 상태에서 재도 앵커의 y 가 같다.
///
/// 실패하면 넷 중 무엇이 되살아났는지부터 본다:
///   1. 오프라인 배너를 다시 Column 에 넣었나 (OfflineBannerOverlay 이탈)
///   2. 공지 카드가 다시 `if (isEmpty) SizedBox.shrink()` 로 사라지나
///   3. 업적 표가 예약 높이(AchievementSection.kBodyH)를 넘거나 안 지키나
///   4. 출석 행이 다시 `if (attendDays != null)` 로 조건부가 됐나
///
/// PNG 는 만들지 않는다 — 위치 증명은 좌표가 정확하고 빠르다.

/// 무한 애니메이션(스피너)이 있어도 안전한 정착 — pumpAndSettle 금지.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// 홈 탭을 띄운다. 실제 진입 경로 그대로 셸을 태우고 '홈' 탭으로 이동한다
/// (셸이 공지를 첫 프레임 뒤에 바인딩하는 순서까지 그대로 재현된다).
Future<void> _pumpHome(
  WidgetTester tester, {
  Map<String, dynamic>? world,
  Set<String> hangPaths = const {},
  bool offline = false,
}) async {
  // 상태를 이어서 잴 때 **트리를 완전히 버리고** 다시 세운다. 같은 모양의
  // 위젯을 다시 pump 하면 Flutter 가 Element 를 재사용해 provider 안의
  // AchievementState 가 앞 상태의 것으로 남는다 (로딩 상태를 재려는데 앞
  // 상태에서 이미 다 불러온 객체가 그대로 살아 있게 된다).
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final api = FakeApi(world ?? memberWorld(), hangPaths: hangPaths);
  final gym = GymState(GymRepository(api), sse: FakeSse());
  await gym.loadMine();
  await tester.pumpWidget(
    harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      gym: gym,
      connectivity: offline ? OfflineConnectivity() : null,
      home: const MainShell(),
    ),
  );
  await _settle(tester);
  await tapTab(tester, '홈');
  await _settle(tester);
}

/// 업적 카탈로그는 그대로, 해금만 0건 — "아직 업적 없음" 상태.
Map<String, dynamic> _achievementsNoneUnlocked() {
  final base = Map<String, dynamic>.from(achievementsSnapshot);
  return {
    'catalog': base['catalog'],
    'unlocked': const <dynamic>[],
    'unlocked_count': 0,
    'visible_count': base['visible_count'],
  };
}

/// (a) 로딩 중 — 기록은 왔지만 공지·업적·출석이 아직 오지 않은 순간.
/// 홈이 실제로 가장 오래 머무는 상태다.
Future<void> homeLoading(WidgetTester tester) => _pumpHome(
  tester,
  hangPaths: {
    '/api/v1/achievements',
    '/api/v1/member/attendances',
    '/api/v1/member/announcements',
  },
);

/// (b) 데이터 있음 — 공지 3건 + 해금 2건 + 출석 기록.
Future<void> homeLoaded(WidgetTester tester) {
  final world = memberWorld();
  world['/api/v1/member/announcements'] = memberAnnouncements();
  return _pumpHome(tester, world: world);
}

/// (c) 데이터 없음 — 공지 0건 · 업적 0건 · 출석 0건.
Future<void> homeEmpty(WidgetTester tester) {
  final world = memberWorld();
  world['/api/v1/member/announcements'] = const <dynamic>[];
  world['/api/v1/member/attendances'] = const <dynamic>[];
  world['/api/v1/achievements'] = _achievementsNoneUnlocked();
  return _pumpHome(tester, world: world);
}

/// (d) 오프라인 — 배너가 떠 있는 상태. 배너는 겹쳐 뜨므로 본문은 그대로여야 한다.
Future<void> homeOffline(WidgetTester tester) =>
    _pumpHome(tester, offline: true);

Map<String, ScreenState> homeStates() => {
  '데이터 있음': homeLoaded,
  '로딩 중': homeLoading,
  '데이터 없음': homeEmpty,
  '오프라인': homeOffline,
};

/// 상태가 바뀌어도 y 가 움직이면 안 되는 요소들 (위 → 아래 순).
Map<String, Key> homeAnchors() => {
  '공지': HomeScreen.kNotice,
  '레벨카드': HomeScreen.kLevel,
  '업적': HomeScreen.kAchievements,
  '마일스톤라벨': HomeScreen.kMilestoneLabel,
  '마일스톤표': HomeScreen.kMilestoneCard,
};

void main() {
  testWidgets('홈 — 4 상태에서 앵커 y 좌표가 전부 같다', (tester) async {
    phone(tester);
    final table = await expectStableAnchorY(
      tester,
      states: homeStates(),
      anchors: homeAnchors(),
    );
    // ignore: avoid_print — 표를 그대로 보고에 쓴다.
    print(formatAnchorTable(table));
    final out = File('build/home_layout_anchors.json');
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(table));
  });

  testWidgets('오프라인 배너는 본문 위에 겹친다 — 아래를 밀지 않는다', (tester) async {
    phone(tester);
    await homeLoaded(tester);
    expect(find.byKey(OfflineBanner.kBanner), findsNothing);
    final onlineY = tester.getTopLeft(find.byKey(HomeScreen.kNotice)).dy;

    await homeOffline(tester);
    expect(find.byKey(OfflineBanner.kBanner), findsOneWidget);
    final offlineY = tester.getTopLeft(find.byKey(HomeScreen.kNotice)).dy;

    expect(
      offlineY,
      closeTo(onlineY, 0.01),
      reason:
          '오프라인 배너가 본문을 밀어냈습니다 — 배너는 Column 이 아니라 '
          'OfflineBannerOverlay(Stack 오버레이)로 얹습니다.',
    );
    // 배너는 본문 맨 위를 덮는다 (가리는 것은 스크롤로 드러난다).
    expect(
      tester.getTopLeft(find.byKey(OfflineBanner.kBanner)).dy,
      lessThanOrEqualTo(offlineY),
    );
  });

  testWidgets('업적 표는 로딩 중 스켈레톤으로 자리를 채운다', (tester) async {
    phone(tester);
    await homeLoading(tester);
    expect(
      find.byType(HkSkeletonRow),
      findsNWidgets(AchievementSection.kRows),
      reason:
          '로딩 중에는 예약한 자리를 스켈레톤이 채워야 합니다 — 빈 상태로 그렸다가 '
          '데이터가 오면 표가 커지며 아래를 밀어냅니다.',
    );

    await homeLoaded(tester);
    expect(find.byType(HkSkeletonRow), findsNothing);
  });
}
