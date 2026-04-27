// 페르소나 자동 회귀 — v1.19 차수 5+ 트랙 B.
//
// 목적: PersonaSwitcherScreen 렌더링 + DeviceIdService override + 핵심 위젯 진입.
// 범위: emulator 없이 실행 가능한 widget test. 실 백엔드 연동은 후속.
//
// 실행:
//   flutter test integration_test/persona_smoke_test.dart
//
// (integration_test 패키지 사용. Driver/emulator 필요 시 별도 실행.)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:facing_app/core/device_id.dart';
import 'package:facing_app/core/theme.dart';
import 'package:facing_app/core/unit_state.dart';
import 'package:facing_app/features/_debug/persona_switcher_screen.dart';
import 'package:facing_app/features/profile/profile_state.dart';

const _kPersonaSeeds = [
  ('admin_01', '변민준', 'persona-admin-byun-2026'),
  ('coach_a', '박지훈', 'persona-coach-park-2026'),
  ('coach_b', '이수민', 'persona-coach-lee-2026'),
  ('member_a1', '김도윤', 'persona-member-kim-doyun-2026'),
  ('member_a2', '정하은', 'persona-member-jung-haeun-2026'),
  ('member_a3', '최서윤', 'persona-member-choi-seoyun-2026'),
  ('member_b1', '강민재', 'persona-member-kang-minjae-2026'),
  ('member_b2', '윤지원', 'persona-member-yoon-jiwon-2026'),
  ('member_b3', '한수아', 'persona-member-han-suah-2026'),
  ('app_user_01', '송예준', 'persona-app-song-yejun-2026'),
];

Widget _wrapWithProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ProfileState>(create: (_) => ProfileState()),
      ChangeNotifierProvider<UnitState>(create: (_) => UnitState()),
    ],
    child: MaterialApp(
      theme: FacingTheme.dark,
      home: child,
    ),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('PersonaSwitcherScreen', () {
    testWidgets('렌더링 + 10명 페르소나 표시', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const PersonaSwitcherScreen()));
      await tester.pumpAndSettle();

      // AppBar 타이틀
      expect(find.text('PERSONA SWITCHER'), findsOneWidget);

      // 10명 displayName 모두 표시
      for (final (_, name, _) in _kPersonaSeeds) {
        expect(
          find.text(name),
          findsOneWidget,
          reason: '$name 표시 안 됨',
        );
      }
    });

    testWidgets('Tier 배지 표시 (Elite × 2, RX × 4 등)', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const PersonaSwitcherScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Elite'), findsNWidgets(2));   // 박지훈, 이수민
      expect(find.text('RX'), findsAtLeastNWidgets(4)); // 김·정·윤·송
      expect(find.text('RX+'), findsAtLeastNWidgets(2)); // 변민준, 강민재
      expect(find.text('Scaled'), findsNWidgets(2)); // 최서윤, 한수아
    });

    testWidgets('박지훈 탭 → device_id override + 다이얼로그 표시', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const PersonaSwitcherScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('박지훈'));
      await tester.pumpAndSettle();

      // 적용 다이얼로그 노출
      expect(find.text('Switched.'), findsOneWidget);

      // SharedPreferences 갱신 확인
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('device_id'), 'persona-coach-park-2026');

      // 캐시 갱신
      expect(DeviceIdService.cached, 'persona-coach-park-2026');
    });
  });

  group('DeviceIdService.overrideForDebug', () {
    testWidgets('각 페르소나 seed 가 정확히 SharedPreferences 에 저장', (tester) async {
      for (final (_, name, seed) in _kPersonaSeeds) {
        await DeviceIdService.overrideForDebug(seed);
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('device_id'),
          seed,
          reason: '$name seed 저장 실패',
        );
        expect(DeviceIdService.cached, seed);
      }
    });
  });

  group('Persona seed 정합성', () {
    test('10명 모두 device_id_seed 가 unique', () {
      final seeds = _kPersonaSeeds.map((p) => p.$3).toSet();
      expect(seeds.length, 10, reason: 'device_id_seed 중복 발견');
    });

    test('10명 모두 displayName 이 unique', () {
      final names = _kPersonaSeeds.map((p) => p.$2).toSet();
      expect(names.length, 10, reason: 'displayName 중복 발견');
    });

    test('seed prefix 일관성 (persona-)', () {
      for (final (_, _, seed) in _kPersonaSeeds) {
        expect(
          seed.startsWith('persona-'),
          true,
          reason: '$seed 가 persona- prefix 아님',
        );
      }
    });
  });
}
