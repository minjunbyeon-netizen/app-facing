// 프로그램 순서·중복·펼침·파트 회귀 (v3.41 · 2026-08-29 / D109 · D111 · 2026-09-04).
//
// 사용자 지시 (v3.41): "프로그램 들어왔을 때 그날 수업이 시간 순서대로
// (어웨이크, 스웻, 빌드): 가장 빠른순대로 중복은 표시하지 않고,
// 수업 펼쳐져서 내용은 다 보여야 함".
// 사용자 지시 (D109): "60분 운동에서 A세션때 15분 B세션때 20분 이런식으로
// 사람들이 보기 쉬우라는 거지. 다른 운동이 아님" — 같은 수업의 A·B·C 는
// 한 카드 안의 **파트**다. 카드가 셋으로 갈라지면 안 된다.
//
// 네 가지를 못 박는다.
//   1) 순서 = 그 수업 종류의 그날 **첫 수업 시각** (서버 `first_class_at`)
//   2) 같은 수업 종류는 **한 번만** — 하루에 두 번 돌아도 내용은 하나다
//   3) 카드가 **전부 펼쳐진 채**로 열린다 (접힌 것을 눌러 열 필요가 없다)
//   4) 파트가 둘 이상인 글은 **카드 한 장** 안에 파트 머리줄·동작 줄이 세로로
//      서고, 카드 머리에는 종류(AMRAP 등)를 적지 않는다
//
// 픽스처(`gymWods`)가 일부러 뒤섞인 순서에 BUILD 를 두 번, SWEAT 에 파트 셋을
// 담고 있어, 이 검사가 곧 그 픽스처의 뜻이다.
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
      wodTypeLabel: '수업',
      content: '내용 $id',
      createdAt: DateTime(2026, 8, 29, 5),
      templateId: tid,
      templateName: name,
      firstClassAt: at,
      displayName: name,
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

    test('같은 종류 글이 여럿이어도 카드는 하나 — D109 (구 D89 세션 분리 폐기)', () {
      // 옛 데이터(세션 글자가 남은 글)가 같은 종류로 여럿 와도 앱은 종류당 첫 글만.
      final out = visibleProgram([
        _p(1, tid: 1, name: 'AWAKE', at: DateTime(2026, 8, 29, 19)),
        _p(2, tid: 1, name: 'AWAKE', at: DateTime(2026, 8, 29, 6)),
        _p(4, tid: 1, name: 'AWAKE', at: DateTime(2026, 8, 29, 12)),
      ]);
      expect(out.map((w) => w.id), [1]);
      expect(out.single.displayName, 'AWAKE');
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

  group('GymWodPost — 파트 (D109)', () {
    test('파트가 둘 이상이면 isMultiPart, 서버 title·lines·memo 를 그대로 든다', () {
      final sweat = gymWods().firstWhere((w) => w['id'] == 32);
      final post = GymWodPost.fromJson(sweat);
      expect(post.isMultiPart, isTrue);
      expect(post.roundsData.map((r) => r.title), [
        'A 파트 · 15분 · STRENGTH',
        'B 파트 · 20분 · AMRAP · 캡 12분',
        'C 파트 · 10분',
      ]);
      expect(post.roundsData[1].lines, ['KB Swing 15회 · 24kg', 'Row 200m']);
      expect(post.roundsData.map((r) => r.durationMin), [15, 20, 10]);
      expect(post.memo, '마지막 파트는 쿨다운.');
      expect(post.wodType, 'custom', reason: '둘 이상이면 대표 종류가 없다');
    });

    test('파트 하나(옛 글)는 isMultiPart 가 아니고 title 이 비어도 읽힌다', () {
      final awake = gymWods().firstWhere((w) => w['id'] == 31);
      final post = GymWodPost.fromJson(awake);
      expect(post.isMultiPart, isFalse);
      expect(post.roundsData.single.title, '');
      // D122 (2026-09-06) — 동작 줄은 이제 파트마다 온다. 입력 칸이 없는 동작
      // (Pull-up)을 완료 시트가 이 줄로 세우기 때문이다 (계약 §5). 파트가 하나뿐인
      // 글은 여전히 **머리줄(title)이 없다** — 나눌 것이 없어서다.
      expect(post.roundsData.single.lines, [
        'Thruster 21-15-9회 · 42.5kg',
        'Pull-up 21-15-9회',
      ]);
      expect(post.memo, '');
    });
  });

  testWidgets('수업 탭 (D111) — 파트 셋이 한 줄 아래 세로로, 수업 없는 종류는 프로그램 칸에 시간 순',
      (tester) async {
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

    // D112 — 들어오면 전부 닫혀 있다. 20:00 SWEAT 줄의 화살표를 눌러 연다.
    expect(tester.widgetList<WodRow>(find.byType(WodRow)).where((r) => r.headerless),
        isEmpty, reason: '자동으로 열리는 줄은 없다');
    await tester.tap(find.byKey(WeekBoard.rowKey(101)));
    await tester.pumpAndSettle();

    // 열린 줄 아래 파트 셋이 머리 없는 본문으로 선다. 종류(AMRAP 등)는 파트 머리줄에만.
    final rows = tester.widgetList<WodRow>(find.byType(WodRow)).toList();
    final sweat = rows.where((r) => r.headerless).toList();
    expect(sweat.length, 1, reason: '파트 셋이 카드 셋으로 갈라지면 안 된다');
    expect(sweat.single.wod.displayName, 'SWEAT');
    for (final head in ['A 파트 · 15분 · STRENGTH', 'B 파트 · 20분 · AMRAP · 캡 12분', 'C 파트 · 10분']) {
      expect(find.text(head.toUpperCase()), findsOneWidget, reason: '파트 머리줄 $head');
    }
    expect(find.textContaining('KB Swing'), findsWidgets);
    expect(find.textContaining('Plank 60초'), findsWidgets);
    expect(find.text('마지막 파트는 쿨다운.'), findsOneWidget, reason: '메모는 파트 아래 한 번');
    // 상단바 제목 '수업' 은 빼고, 파트 본문 안에서만 찾는다.
    final sweatBody = find.byWidgetPredicate((w) => w is WodRow && w.headerless);
    expect(find.descendant(of: sweatBody, matching: find.text('수업')), findsNothing,
        reason: "wod_type 'custom' 의 라벨 '수업' 이 머리에 서면 안 된다");

    // 오늘 수업이 없는 종류(AWAKE 06:00 · BUILD 18:00)는 '프로그램' 밑에 시간 순, 전부 펼친 채.
    final cards = rows.where((r) => !r.headerless).toList();
    expect(cards.map((r) => r.wod.displayName ?? r.wod.templateName), ['AWAKE', 'BUILD'],
        reason: '첫 수업 시각 순 (06:00 · 18:00) — BUILD 중복 한 건은 안 온다');
    expect(cards.every((r) => r.initiallyExpanded == false), isTrue,
        reason: 'D112 — 프로그램 칸 카드도 닫힌 채로 (눌러서 연다)');
    expect(find.textContaining('Thruster'), findsWidgets);
    expect(find.textContaining('Clean & Jerk'), findsWidgets);
    expect(find.textContaining('같은 종류 중복'), findsNothing);
    // 파트 하나짜리 AWAKE 카드 머리에는 종전대로 종류가 선다.
    expect(find.text('FOR TIME'), findsOneWidget);
  });
}
