// /go 13 (B1 후속): WodSessionScreen 빌드 smoke 위젯 테스트.
//
// 풀 mock: ApiClient + GymState + AchievementState + WodSessionBus.
// PrDetector / SeasonBadgeService / HistoryRepository 는 SharedPreferences·dio 호출이 있어
// 빌드 단계에서 호출 안 되도록 widget pumpAndSettle 대신 pump() 단일 프레임만 사용.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:facing_app/core/api_client.dart';
import 'package:facing_app/core/theme.dart';
import 'package:facing_app/core/wod_session_bus.dart';
import 'package:facing_app/features/achievement/achievement_repository.dart';
import 'package:facing_app/features/achievement/achievement_state.dart';
import 'package:facing_app/features/gym/gym_repository.dart';
import 'package:facing_app/features/gym/gym_state.dart';
import 'package:facing_app/features/wod_session/wod_session_screen.dart';
import 'package:facing_app/models/achievement.dart';
import 'package:facing_app/models/gym.dart';

class _FakeGymRepo extends GymRepository {
  _FakeGymRepo(super.api);

  @override
  Future<GymMembership> getMine() async => GymMembership.empty;

  @override
  Future<List<GymWodPost>> listWods({
    required int gymId,
    String? date,
  }) async =>
      const [];
}

class _FakeAchievementRepo extends AchievementRepository {
  _FakeAchievementRepo(super.api);

  @override
  Future<AchievementSnapshot> list() async => AchievementSnapshot.empty;

  @override
  Future<List<AchievementUnlockResult>> check() async => const [];
}

GymWodPost _wodForTimeFran() => GymWodPost(
      id: 1,
      postDate: '2026-04-28',
      wodType: 'for_time',
      content: 'Fran 21-15-9 Thruster + Pull-up',
      scaledVersion: null,
      beginnerVersion: null,
      scaleGuide: null,
      roundsData: const [],
      rounds: null,
      timeCapSec: null,
      createdAt: DateTime.now(),
    );

GymWodPost _wodAmrap12() => GymWodPost(
      id: 2,
      postDate: '2026-04-28',
      wodType: 'amrap',
      content: 'AMRAP 12 — 5 Pull-up + 10 Push-up + 15 Air Squat',
      scaledVersion: null,
      beginnerVersion: null,
      scaleGuide: null,
      roundsData: const [],
      rounds: null,
      timeCapSec: 720,
      createdAt: DateTime.now(),
    );

Widget _wrap(GymWodPost wod, ApiClient api) => MaterialApp(
      theme: FacingTheme.dark,
      home: MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: api),
          ChangeNotifierProvider<GymState>(
            create: (_) => GymState(_FakeGymRepo(api)),
          ),
          ChangeNotifierProvider<AchievementState>(
            create: (_) => AchievementState(_FakeAchievementRepo(api)),
          ),
          ChangeNotifierProvider<WodSessionBus>(
            create: (_) => WodSessionBus(),
          ),
        ],
        child: WodSessionScreen(wod: wod),
      ),
    );

void main() {
  late ApiClient api;
  setUpAll(() {
    api = ApiClient.create();
    // wakelock_plus / shared_preferences 채널 stub — 호출 시 null 반환.
    TestWidgetsFlutterBinding.ensureInitialized();
    const wakelockChannel =
        MethodChannel('dev.fluttercommunity.plus/wakelock');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(wakelockChannel, (call) async => null);
    const prefsChannel =
        MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(prefsChannel, (call) async {
      if (call.method == 'getAll') return <String, Object>{};
      return null;
    });
  });

  group('WodSessionScreen smoke', () {
    testWidgets('For Time WOD 빌드 통과', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrap(_wodForTimeFran(), api));
      await tester.pump(); // 단일 프레임 (timer 호출 회피)

      expect(find.byType(WodSessionScreen), findsOneWidget);
    });

    testWidgets('AMRAP 12 WOD 빌드 통과 (timeCapSec=720)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrap(_wodAmrap12(), api));
      await tester.pump();

      expect(find.byType(WodSessionScreen), findsOneWidget);
    });
  });
}
