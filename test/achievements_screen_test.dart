// /go Phase 3: AchievementsScreen 렌더 회귀 위젯 테스트.
//
// 검증:
// - empty catalog → 'No achievements yet.'
// - error 상태 (AppException) → 업적 로딩 실패 + Retry 버튼
// - snapshot 데이터 있음 → ACHIEVEMENTS appbar + UNLOCKED stats

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:facing_app/core/api_client.dart';
import 'package:facing_app/core/exception.dart';
import 'package:facing_app/core/theme.dart';
import 'package:facing_app/features/achievement/achievement_repository.dart';
import 'package:facing_app/features/achievement/achievement_state.dart';
import 'package:facing_app/features/achievement/achievements_screen.dart';
import 'package:facing_app/models/achievement.dart';

/// list() 응답을 미리 주입하는 테스트용 repo.
/// snap 또는 listError 둘 중 하나만 동작.
class _FakeAchievementRepo extends AchievementRepository {
  final AchievementSnapshot? snap;
  final Object? listError;
  _FakeAchievementRepo(super.api, {this.snap, this.listError});

  @override
  Future<AchievementSnapshot> list() async {
    if (listError != null) throw listError!;
    return snap ?? AchievementSnapshot.empty;
  }

  @override
  Future<List<AchievementUnlockResult>> check() async => const [];
}

Widget _wrap(AchievementState state) => MaterialApp(
      theme: FacingTheme.dark,
      home: ChangeNotifierProvider<AchievementState>.value(
        value: state,
        child: const AchievementsScreen(),
      ),
    );

void main() {
  late ApiClient api;
  setUpAll(() {
    api = ApiClient.create();
  });

  group('AchievementsScreen 렌더 분기', () {
    testWidgets('empty catalog → "No achievements yet."', (tester) async {
      final state = AchievementState(_FakeAchievementRepo(api));
      await state.load();

      await tester.pumpWidget(_wrap(state));
      await tester.pumpAndSettle();

      expect(find.text('ACHIEVEMENTS'), findsOneWidget); // AppBar title
      expect(find.text('No achievements yet.'), findsOneWidget);
    });

    testWidgets('AppException 에러 → "업적 로딩 실패" + Retry', (tester) async {
      final state = AchievementState(_FakeAchievementRepo(
        api,
        listError:AppException('서버 연결 실패'),
      ));
      await state.load();

      await tester.pumpWidget(_wrap(state));
      await tester.pumpAndSettle();

      expect(find.text('업적 로딩 실패'), findsOneWidget);
      expect(find.text('서버 연결 실패'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('일반 Exception 에러 → error UI 표시', (tester) async {
      final state = AchievementState(_FakeAchievementRepo(
        api,
        listError:Exception('network down'),
      ));
      await state.load();

      await tester.pumpWidget(_wrap(state));
      await tester.pumpAndSettle();

      expect(find.text('업적 로딩 실패'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('snapshot 1개 있음 → AppBar + UNLOCKED 섹션 라벨', (tester) async {
      // _FeaturedPanel 이 default test surface (~600px) 보다 넓어 overflow.
      // 실 디바이스 사이즈 (1080×2400) 시뮬레이션.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final snap = AchievementSnapshot(
        catalog: const [
          AchievementCatalog(
            code: 'TEST_1',
            name: 'Test Achievement',
            description: 'Test description',
            rarity: 'Common',
            isHidden: false,
            sortOrder: 1,
          ),
        ],
        unlocked: const {},
        unlockedCount: 0,
        visibleCount: 1,
      );
      final state =
          AchievementState(_FakeAchievementRepo(api, snap: snap));
      await state.load();

      await tester.pumpWidget(_wrap(state));
      await tester.pumpAndSettle();

      expect(find.text('ACHIEVEMENTS'), findsOneWidget);
      expect(find.text('UNLOCKED'), findsAtLeastNWidgets(1)); // 섹션 라벨
      expect(find.text('/ 1'), findsOneWidget);
    });
  });
}
