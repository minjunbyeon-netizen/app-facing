// /go 6 Phase 3: InboxScreen 게이트·렌더 회귀 위젯 테스트.
//
// 검증:
// - 코치 (isOwner) → 4 탭 (ALL / NOTES / ASSIGNMENTS / OUTBOX)
// - 멤버 (approved) → 3 탭 (OUTBOX 미노출)
// - InboxScreen 컴파일·기본 build 통과 회귀 보장

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:facing_app/core/api_client.dart';
import 'package:facing_app/core/theme.dart';
import 'package:facing_app/features/gym/gym_repository.dart';
import 'package:facing_app/features/gym/gym_state.dart';
import 'package:facing_app/features/inbox/inbox_repository.dart';
import 'package:facing_app/features/inbox/inbox_state.dart';
import 'package:facing_app/features/inbox/inbox_screen.dart';
import 'package:facing_app/models/gym.dart';

class _FakeGymRepo extends GymRepository {
  final GymMembership stub;
  _FakeGymRepo(super.api, this.stub);

  @override
  Future<GymMembership> getMine() async => stub;

  @override
  Future<List<GymWodPost>> listWods({
    required int gymId,
    String? date,
  }) async =>
      const [];
}

class _FakeInboxRepo extends InboxRepository {
  _FakeInboxRepo(super.api);

  @override
  Future<InboxResult> listInbox(int gymId) async => InboxResult.empty;

  @override
  Future<List<OutboxNote>> listOutbox(int gymId) async => const [];
}

Widget _wrap(GymState gym, InboxState inbox) => MaterialApp(
      theme: FacingTheme.dark,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<GymState>.value(value: gym),
          ChangeNotifierProvider<InboxState>.value(value: inbox),
        ],
        child: const InboxScreen(),
      ),
    );

const _testGym = GymSummary(
  id: 1,
  name: 'Test Box',
  location: 'Test City',
  memberCount: 0,
);

void main() {
  late ApiClient api;
  setUpAll(() {
    api = ApiClient.create();
  });

  group('InboxScreen 게이트 분기', () {
    testWidgets('코치 (isOwner) → 4 탭 (OUTBOX 노출)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const owner = GymMembership(
        gym: _testGym,
        role: 'owner',
        status: 'approved',
      );
      final gym = GymState(_FakeGymRepo(api, owner));
      await gym.loadMine();
      final inbox = InboxState(_FakeInboxRepo(api));

      await tester.pumpWidget(_wrap(gym, inbox));
      await tester.pumpAndSettle();

      expect(find.text('INBOX'), findsOneWidget);
      expect(find.textContaining('OUTBOX'), findsOneWidget);
      expect(find.textContaining('ALL'), findsOneWidget);
      expect(find.textContaining('NOTES'), findsOneWidget);
      expect(find.textContaining('ASSIGNMENTS'), findsOneWidget);
    });

    testWidgets('멤버 (approved) → 3 탭 (OUTBOX 미노출)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const member = GymMembership(
        gym: _testGym,
        role: 'member',
        status: 'approved',
      );
      final gym = GymState(_FakeGymRepo(api, member));
      await gym.loadMine();
      final inbox = InboxState(_FakeInboxRepo(api));

      await tester.pumpWidget(_wrap(gym, inbox));
      await tester.pumpAndSettle();

      expect(find.text('INBOX'), findsOneWidget);
      expect(find.textContaining('OUTBOX'), findsNothing);
      expect(find.textContaining('ALL'), findsOneWidget);
      expect(find.textContaining('NOTES'), findsOneWidget);
      expect(find.textContaining('ASSIGNMENTS'), findsOneWidget);
    });
  });
}
