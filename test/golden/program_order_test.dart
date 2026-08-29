// 프로그램 칸의 순서·중복·펼침 회귀 (v3.41 · 2026-08-29).
//
// 사용자 지시: "프로그램 들어왔을 때 그날 수업이 시간 순서대로
// (어웨이크, 스웻, 빌드): 가장 빠른순대로 중복은 표시하지 않고,
// 수업 펼쳐져서 내용은 다 보여야 함".
//
// 세 가지를 못 박는다.
//   1) 순서 = 그 수업 종류의 그날 **첫 수업 시각** (서버 `first_class_at`)
//   2) 같은 수업 종류는 **한 번만** — 하루에 두 번 돌아도 내용은 하나다
//   3) 카드가 **전부 펼쳐진 채**로 열린다 (접힌 것을 눌러 열 필요가 없다)
//
// 픽스처(`gymWods`)가 일부러 뒤섞인 순서에 BUILD 를 두 번 담고 있어,
// 이 검사가 곧 그 픽스처의 뜻이다.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/gym/box_wod_screen.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/gym/week_board.dart';
import 'package:hyphen_app/features/gym/wod_row.dart';
import 'package:hyphen_app/models/gym.dart';

import 'fakes.dart';
import 'harness.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

GymWodPost _p(int id, {int? tid, String? name, DateTime? at}) => GymWodPost(
  id: id,
  postDate: '2026-08-29',
  wodType: 'custom',
  content: '내용 $id',
  createdAt: DateTime(2026, 8, 29, 5),
  templateId: tid,
  templateName: name,
  firstClassAt: at,
);

void main() {
  group('visibleProgram — 순서와 중복', () {
    test('첫 수업 시각이 이른 순으로 세운다', () {
      final out = visibleProgram([
        _p(3, tid: 3, name: 'BUILD', at: DateTime(2026, 8, 29, 18)),
        _p(1, tid: 1, name: 'AWAKE', at: DateTime(2026, 8, 29, 6)),
        _p(2, tid: 2, name: 'SWEAT', at: DateTime(2026, 8, 29, 12)),
      ]);
      expect(out.map((w) => w.templateName), ['AWAKE', 'SWEAT', 'BUILD']);
    });

    test('같은 수업 종류는 한 번만 — 하루에 두 번 돌아도 내용은 하나다', () {
      final out = visibleProgram([
        _p(1, tid: 3, name: 'BUILD', at: DateTime(2026, 8, 29, 6)),
        _p(2, tid: 3, name: 'BUILD', at: DateTime(2026, 8, 29, 18)),
        _p(3, tid: 2, name: 'SWEAT', at: DateTime(2026, 8, 29, 12)),
      ]);
      expect(out.length, 2);
      expect(out.map((w) => w.templateName), ['BUILD', 'SWEAT']);
      expect(out.first.id, 1, reason: '중복이면 먼저 온 것을 남긴다');
    });

    test('수업 종류에 안 붙은 단발 글은 맨 뒤에, 서로는 지우지 않는다', () {
      final out = visibleProgram([
        _p(9), // 시각 없음
        _p(1, tid: 1, name: 'AWAKE', at: DateTime(2026, 8, 29, 6)),
        _p(8), // 시각 없음 — 위와 다른 글이므로 둘 다 남는다
      ]);
      expect(out.map((w) => w.id), [1, 8, 9]);
    });
  });

  testWidgets('프로그램 칸 — 오늘 세 종류가 시간 순으로, 전부 펼쳐진 채', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(memberWorld());
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

    // 기본 진입이 프로그램 칸이고 오늘이 펼쳐져 있다 (v3.40).
    final rows = tester.widgetList<WodRow>(find.byType(WodRow)).toList();
    expect(rows.length, 3, reason: 'BUILD 중복 한 건은 화면에 오지 않는다');
    expect(
      rows.map((r) => r.wod.templateName),
      ['AWAKE', 'SWEAT', 'BUILD'],
      reason: '첫 수업 시각 순 (06:00 · 12:00 · 18:00)',
    );
    expect(rows.every((r) => r.initiallyExpanded == true), isTrue,
        reason: '내용이 다 보여야 한다 — 눌러서 열 필요가 없다');

    // 펼쳐진 내용이 실제로 그려졌는지 (접힌 카드면 본문이 없다).
    expect(find.textContaining('Thruster'), findsWidgets);
    expect(find.textContaining('KB Swing'), findsWidgets);
    expect(find.textContaining('Clean & Jerk'), findsWidgets);
    // 중복 글의 본문은 어디에도 없다.
    expect(find.textContaining('같은 종류 중복'), findsNothing);
  });
}
