import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/gym/box_wod_screen.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';

import 'fakes.dart';
import 'harness.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

/// 예약 취소 확인 다이얼로그의 차감 안내 — 회귀 게이트.
///
/// 2026-08-28 테스터 확정으로 시작이 임박해도 취소를 막지 않는다. 대신 시작
/// 20분 전을 지났으면 **횟수가 차감될 수 있다는 사실**을 누르기 전에 말한다.
/// 조용히 차감하면 화면이 거짓말을 하는 것이다.
///
/// 반대로 20분 전까지는 아무 문구도 붙지 않아야 한다 — 차감되지 않는 취소에
/// 경고를 붙이면 그것도 거짓말이다. 두 방향을 다 잠근다.
///
/// 코치 쪽에 남는 '시한 후 취소' 기록은 **회원의 일이 아니다.** 그 말이 회원
/// 화면에 새어 나오지 않는지도 여기서 함께 막는다.
void main() {
  testWidgets('20분 전 이후 취소 — 차감 안내가 붙는다', (tester) async {
    phone(tester);
    await _openCancelDialog(tester, memberClassesLateCancel());
    expect(find.textContaining('늦은 취소로 기록됩니다'), findsOneWidget);
    expect(find.textContaining('차감'), findsOneWidget);
  });

  testWidgets('20분 전까지 취소 — 아무 안내도 붙지 않는다', (tester) async {
    phone(tester);
    await _openCancelDialog(tester, memberClassesReserved());
    expect(find.textContaining('늦은 취소'), findsNothing);
    expect(find.textContaining('차감'), findsNothing);
  });

  testWidgets('코치 쪽 기록은 회원 화면에 새지 않는다', (tester) async {
    phone(tester);
    await _openCancelDialog(tester, memberClassesLateCancel());
    for (final leak in ['코치', '기록이 남', '시한 후', '주 1회', '통보']) {
      expect(find.textContaining(leak), findsNothing, reason: '회원 미노출: $leak');
    }
  });
}

/// 내 예약이 있는 수업 목록을 띄우고 '취소' 배지를 눌러 다이얼로그를 연다.
Future<void> _openCancelDialog(
  WidgetTester tester,
  List<Map<String, dynamic>> classes,
) async {
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final api = FakeApi({
    ...memberWorld(),
    '/api/v1/member/classes': classes,
  });
  final gym = GymState(GymRepository(api), sse: FakeSse());
  await gym.loadMine();
  await tester.pumpWidget(
    harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      gym: gym,
      home: const BoxWodScreen(),
    ),
  );
  await tester.pumpAndSettle();
  // v3.40 — 수업 탭 기본 진입이 '프로그램' 이다. 예약 취소 줄은 옆 칸에 있다.
  await tapSchedulePane(tester);
  await tester.pumpAndSettle();
  await tester.tap(find.text('취소'));
  await tester.pumpAndSettle();
  expect(find.text('예약을 취소할까요?'), findsOneWidget);
}
