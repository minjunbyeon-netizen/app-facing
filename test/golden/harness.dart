import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:facing_app/core/api_client.dart';
import 'package:facing_app/core/connectivity_state.dart';
import 'package:facing_app/core/goals_state.dart';
import 'package:facing_app/core/movements_repository.dart';
import 'package:facing_app/core/shell_nav_bus.dart';
import 'package:facing_app/core/sse_client.dart';
import 'package:facing_app/core/theme.dart';
import 'package:facing_app/core/ui_prefs_state.dart';
import 'package:facing_app/core/unit_state.dart';
import 'package:facing_app/core/wod_session_bus.dart';
import 'package:facing_app/features/achievement/achievement_repository.dart';
import 'package:facing_app/features/achievement/achievement_state.dart';
import 'package:facing_app/features/announcements/announcements_state.dart';
import 'package:facing_app/features/auth/auth_state.dart';
import 'package:facing_app/features/boss/boss_api_client.dart';
import 'package:facing_app/features/boss/boss_auth_state.dart';
import 'package:facing_app/features/gym/gym_repository.dart';
import 'package:facing_app/features/gym/gym_state.dart';
import 'package:facing_app/features/inbox/inbox_repository.dart';
import 'package:facing_app/features/inbox/inbox_state.dart';
import 'package:facing_app/features/profile/profile_state.dart';
import 'package:facing_app/features/wod_builder/wod_draft_state.dart';

import 'fakes.dart';

/// 골든 공용 하네스 — 골든스탠다드(writeplz-app) 패턴의 facing 판.
/// main.dart provider 트리의 축소판. SSE·플러그인(FCM·로컬푸시)은 무동작 대체.

/// 갤S22 급 화면 (논리 360×780, dpr 2 → PNG 720×1560).
void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(720, 1560);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// 앱과 동일한 provider·테마 배선. gym 을 넘기면 그 상태를 그대로 쓴다
/// (박스 소속 화면은 테스트에서 미리 loadMine() 을 끝내고 넘길 것).
Widget harness({
  required ApiClient api,
  required AuthState auth,
  required ProfileState profile,
  GymState? gym,
  ConnectivityState? connectivity,
  BossAuthState? bossAuth,
  BossApiClient? bossApi,
  WodDraftState? draft,
  required Widget home,
}) {
  final gymState = gym ?? GymState(GymRepository(api), sse: FakeSse());
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: api),
      Provider<SseClient>.value(value: FakeSse()),
      Provider<MovementsRepository>(create: (_) => MovementsRepository(api)),
      Provider<GymRepository>(create: (_) => GymRepository(api)),
      Provider<InboxRepository>(create: (_) => InboxRepository(api)),
      ChangeNotifierProvider<ProfileState>.value(value: profile),
      ChangeNotifierProvider<UnitState>(create: (_) => UnitState()),
      ChangeNotifierProvider<ConnectivityState>.value(
          value: connectivity ?? ConnectivityState()),
      ChangeNotifierProvider<WodDraftState>.value(
          value: draft ?? WodDraftState()),
      ChangeNotifierProvider<GymState>.value(value: gymState),
      ChangeNotifierProvider<InboxState>(
          create: (_) => InboxState(InboxRepository(api))),
      ChangeNotifierProvider<AnnouncementsState>(
          create: (_) => AnnouncementsState()),
      Provider<AchievementRepository>(
          create: (_) => AchievementRepository(api)),
      ChangeNotifierProvider<AchievementState>(
          create: (ctx) =>
              AchievementState(ctx.read<AchievementRepository>())..load()),
      ChangeNotifierProvider<AuthState>.value(value: auth),
      ChangeNotifierProvider<UiPrefsState>(create: (_) => UiPrefsState()),
      ChangeNotifierProvider<BossAuthState>.value(
          value: bossAuth ?? BossAuthState()),
      Provider<BossApiClient>.value(value: bossApi ?? BossApiClient.create()),
      ChangeNotifierProvider<WodSessionBus>(create: (_) => WodSessionBus()),
      ChangeNotifierProvider<ShellNavBus>(create: (_) => ShellNavBus()),
      ChangeNotifierProvider<GoalsState>(create: (_) => GoalsState()),
    ],
    child: MaterialApp(
      theme: FacingTheme.light,
      debugShowCheckedModeBanner: false,
      home: home,
      // 캡처 후 화면이 다른 라우트로 넘어가도 죽지 않게 전 라우트 스텁.
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => const Scaffold(body: SizedBox.shrink()),
      ),
    ),
  );
}

/// 비동기 로드가 그려질 시간을 준 뒤 캡처. (무한 애니메이션이 있어 pumpAndSettle 금지)
Future<void> capture(WidgetTester tester, String name) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await expectLater(
      find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

/// 트리 안 모든 Image(에셋 jpg 등)를 실디코딩 — flutter_test 는 기본으로
/// 이미지를 디코딩하지 않아 hero 배경이 빈 채로 찍힌다.
Future<void> precacheAllImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    final ctx = tester.element(find.byType(MaterialApp));
    for (final img in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(img.image, ctx);
    }
  });
  await tester.pump();
}

/// 하단 탭 전환 — NavigationBar 안 라벨만 정확히 탭.
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
      of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pump(const Duration(milliseconds: 300));
}
