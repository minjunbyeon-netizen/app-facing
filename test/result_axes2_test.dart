// 기록 축 계약 2 — **축을 서버가 내려주고, 앱은 사본을 갖지 않는다**
// (D122 · `docs/CONTRACT-result-axes-2.md`).
//
// D121 이 "파트 종류가 칸을 정한다" 를 세웠지만, 그 표를 **앱이 리터럴로 복제**하고
// 있었다 (`_scoredTypes` · `_noRepsTypes`). 새 종류·축 변경마다 앱 재배포·스토어
// 심사가 필요한 상태였다. D122 는 파트마다 `score_keys`·`score_labels`·
// `score_target`·`show_movement_reps`·`set_based` 를 서버가 실어 주고, 앱은 그것만
// 보고 그린다 (대전제 6-b).
//
// 이 파일이 재는 것 (계약 §9 앱 게이트):
//   1. lib/** 에 축 표(종류 리터럴 집합)가 없다 — 정적 검사
//   2. score_keys 대로 칸이 선다 — for_time 3 · amrap 2 · emom 1 · strength 0
//   3. 맨몸 동작만 든 EMOM 파트가 시트에 **남아 있다** (계약 전에는 통째로 소멸)
//   4. AMRAP 라벨 '+ 회' · 힌트 = score_target · 안내 줄 · 동작 줄 읽기 전용
//   5. STRENGTH 세트 줄은 **그 줄의 목표만** 힌트로 (전체 '5-5-5-5-5' 금지)
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/gym/wod_result_sheet.dart';
import 'package:hyphen_app/models/gym.dart';

import 'golden/fakes.dart';
import 'golden/harness.dart';
import 'golden/screens_golden_test.dart'
    show rxProfile, signedInAuth, signedInPrefs;
import 'result_axes_test.dart' show mountSheet, textOf;

/// 축 표를 이루는 종류 값 — 이 넷이 **함께** 앱 코드에 적혀 있으면 사본이다.
const List<String> _axisTypes = ['for_time', 'amrap', 'emom', 'strength'];

/// 축 표와 무관하게 남아 있어도 되는 자리 — 파일별 **허용 건수**.
/// 새 자리가 생기면(또는 건수가 늘면) 이 표를 같이 고쳐야 실패가 풀린다 (의도적 마찰).
const Map<String, int> _allowed = {
  // 타이머 진입을 strength 에서만 숨긴다 (기록 축이 아니라 화면 진입 규칙, 2026-08-20).
  'lib/features/gym/wod_detail_screen.dart': 1,
  // 타이머 모드(카운트업·카운트다운) — 점수 축이 아니라 스톱워치 동작.
  'lib/features/wod_session/wod_session_screen.dart': 2,
};

String? _hintOf(WidgetTester tester, Key key) =>
    tester.widget<TextField>(find.byKey(key)).decoration?.hintText;

String? _labelOf(WidgetTester tester, Key key) =>
    tester.widget<TextField>(find.byKey(key)).decoration?.labelText;

/// 주석을 지운 코드 본문 (리터럴 검사는 코드에만 적용).
String _codeOf(File f) => f
    .readAsLinesSync()
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

List<File> _libFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

String _rel(File f) => f.path.replaceAll('\\', '/');

void main() {
  group('계약 §9 — 앱은 축 표를 다시 갖지 않는다 (정적 검사)', () {
    test('완료 시트에 종류 리터럴 0건 — 칸은 서버 score_keys 가 정한다', () {
      final f = File('lib/features/gym/wod_result_sheet.dart');
      final code = _codeOf(f);
      final hits = [
        for (final t in _axisTypes)
          if (code.contains("'$t'")) t,
      ];
      expect(
        hits,
        isEmpty,
        reason:
            '완료 시트가 종류 리터럴 ${hits.join(', ')} 을 갖고 있습니다. '
            '어떤 칸을 그릴지는 서버가 파트마다 주는 score_keys·show_movement_reps·'
            'set_based 가 정합니다 (계약 §3).',
      );
    });

    test('lib/** 어디에도 종류 리터럴 **집합**이 없다', () {
      // 중첩 없는 컬렉션 리터럴 한 덩이 — 여러 줄에 걸쳐 있어도 잡힌다.
      final collection = RegExp(r'[\{\[][^\{\}\[\]]*[\}\]]');
      final hits = <String>[];
      for (final f in _libFiles()) {
        for (final m in collection.allMatches(_codeOf(f))) {
          final body = m.group(0)!;
          // 값 목록만 본다 — 문장이 든 덩이(switch 본문·블록)는 아래 건수 검사가 맡는다.
          if (body.contains(';') || body.contains('case ')) continue;
          final found = [
            for (final t in _axisTypes)
              if (body.contains("'$t'")) t,
          ];
          if (found.length >= 2) {
            hits.add('${_rel(f)}: ${found.join('·')}  ← ${body.trim()}');
          }
        }
      }
      expect(
        hits,
        isEmpty,
        reason:
            '축 표가 앱에 복제됐습니다 — 새 종류가 생길 때마다 스토어 심사를 다시 '
            '받아야 합니다. 정본은 서버 services/result_axes.py 한 곳입니다:\n'
            '${hits.join('\n')}',
      );
    });

    test("lib/** 에 '추가 회' 0건 — 뜻이 정반대로 읽히던 말 (§5)", () {
      final hits = [
        for (final f in _libFiles())
          if (_codeOf(f).contains('추가 회')) _rel(f),
      ];
      expect(
        hits,
        isEmpty,
        reason:
            "'추가 회' 는 한국어로 '정해진 것에 더해서' 로 읽히는데 실제 뜻은 "
            '반대다 (마지막 라운드를 다 못 채우고 한 만큼). 라벨은 서버 '
            'score_labels 가 준다:\n${hits.join('\n')}',
      );
    });

    test('종류 리터럴이 남은 자리는 등록된 곳뿐 (건수까지)', () {
      final counts = <String, int>{};
      for (final f in _libFiles()) {
        final code = _codeOf(f);
        var n = 0;
        for (final t in _axisTypes) {
          n += RegExp("'$t'").allMatches(code).length;
        }
        if (n > 0) counts[_rel(f)] = n;
      }
      final problems = <String>[];
      counts.forEach((path, n) {
        final allow = _allowed[path];
        if (allow == null) {
          problems.add('$path: $n건 — 등록되지 않은 자리');
        } else if (n > allow) {
          problems.add('$path: $n건 (등록 $allow건) — 늘었습니다');
        }
      });
      expect(
        problems,
        isEmpty,
        reason:
            '종류 값을 앱이 다시 판정하고 있습니다. 정말 필요하면 이 검사의 '
            '_allowed 에 이유와 함께 등록하십시오:\n${problems.join('\n')}',
      );
    });
  });

  group('계약 §3 — score_keys 대로 칸을 그린다', () {
    testWidgets('for_time = 완주 시간·캡 종료·남긴 렙스 (3칸)', (tester) async {
      await mountSheet(tester, wodAxesPost());
      expect(find.byKey(WodResultSheet.partFieldKey(2, 'min')), findsOneWidget);
      expect(find.byKey(WodResultSheet.partFieldKey(2, 'sec')), findsOneWidget);
      expect(find.byKey(WodResultSheet.partFieldKey(2, 'cap')), findsOneWidget);
      expect(
        find.byKey(WodResultSheet.partFieldKey(2, 'extra')),
        findsOneWidget,
      );
      // 라벨은 서버 score_labels 그대로 (앱에 한글을 심지 않는다).
      expect(
        _labelOf(tester, WodResultSheet.partFieldKey(2, 'extra')),
        '남긴 렙스',
      );
    });

    testWidgets('amrap = 라운드·+ 회 (2칸, 시간 칸 없음)', (tester) async {
      await mountSheet(tester, wodAxesPost());
      expect(
        find.byKey(WodResultSheet.partFieldKey(1, 'rounds')),
        findsOneWidget,
      );
      expect(
        find.byKey(WodResultSheet.partFieldKey(1, 'extra')),
        findsOneWidget,
      );
      expect(find.byKey(WodResultSheet.partFieldKey(1, 'min')), findsNothing);
      expect(find.byKey(WodResultSheet.partFieldKey(1, 'cap')), findsNothing);
    });

    testWidgets('emom = 완료한 분 1칸', (tester) async {
      await mountSheet(tester, wodAxesPost());
      expect(
        find.byKey(WodResultSheet.partFieldKey(3, 'rounds')),
        findsOneWidget,
        reason: 'EMOM 파트에 점수 칸이 없습니다 — 계약 §4 는 rounds(완료한 분) 하나를 줍니다',
      );
      expect(
        _labelOf(tester, WodResultSheet.partFieldKey(3, 'rounds')),
        '완료한 분',
      );
      for (final f in const ['min', 'sec', 'extra', 'cap']) {
        expect(
          find.byKey(WodResultSheet.partFieldKey(3, f)),
          findsNothing,
          reason: 'EMOM 에 없는 칸 "$f" 가 생겼습니다',
        );
      }
    });

    testWidgets('strength = 파트 점수 0칸 (세트가 담당)', (tester) async {
      await mountSheet(tester, wodAxesPost());
      for (final f in const ['min', 'sec', 'rounds', 'extra', 'cap']) {
        expect(find.byKey(WodResultSheet.partFieldKey(0, f)), findsNothing);
      }
    });

    testWidgets('체크박스가 아니라 숫자 한 칸 — EMOM 에 체크 줄이 없다', (tester) async {
      // 계약 §4: 체크 안 된 칸이 '실패' 로 읽히는데 실제로는 '안 적음' 일 수 있다.
      await mountSheet(tester, wodEmomBodyweightPost());
      expect(find.byType(Checkbox), findsNothing);
    });
  });

  group('계약 §4 — EMOM 파트는 사라지지 않는다', () {
    testWidgets('맨몸 동작만 든 EMOM 파트도 시트에 남는다', (tester) async {
      await mountSheet(tester, wodEmomBodyweightPost());
      expect(
        find.byKey(WodResultSheet.partFieldKey(0, 'rounds')),
        findsOneWidget,
        reason: '적을 칸이 없다고 파트를 통째로 지우면 "왜 없지?" 가 된다 (계약 §4)',
      );
      // 서버가 그린 동작 줄이 읽기 전용으로 선다 (입력 칸은 없다).
      expect(find.text('Burpee 8회'), findsOneWidget);
      expect(find.text('Air Squat 12회'), findsOneWidget);
      expect(
        find.byKey(WodResultSheet.fieldKey(0, 0, null, 'load')),
        findsNothing,
      );
      expect(
        find.byKey(WodResultSheet.fieldKey(0, 0, null, 'reps')),
        findsNothing,
      );
    });

    testWidgets('완료한 분 힌트는 서버 score_hints 문장 그대로', (tester) async {
      await mountSheet(tester, wodEmomBodyweightPost());
      expect(_hintOf(tester, WodResultSheet.partFieldKey(0, 'rounds')), '10분 중');
    });

    testWidgets('EMOM 점수가 제출 payload 에 담긴다', (tester) async {
      final api = await mountSheet(
        tester,
        wodEmomBodyweightPost(),
        extraResponses: {
          '/api/v1/gyms/1/wods/41/results': {
            'result_id': 9,
            'is_pr': false,
            'attendance_added': true,
          },
        },
      );
      await tester.enterText(
        find.byKey(WodResultSheet.partFieldKey(0, 'rounds')),
        '9',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(kWodSaveButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(kWodSaveButton));
      await tester.pumpAndSettle();
      final body = api.posts
          .firstWhere((p) => p.path.endsWith('/results'))
          .body;
      final parts = (body['parts'] as List).cast<Map>();
      expect(parts, hasLength(1));
      expect(parts.single['index'], 0);
      expect(parts.single['rounds'], 9);
    });
  });

  group('계약 §5 — AMRAP 라벨·힌트·안내 줄', () {
    testWidgets("'추가 회' 는 사라지고 '+ 회' 가 선다", (tester) async {
      await mountSheet(tester, wodAxesPost());
      expect(
        find.text('추가 회'),
        findsNothing,
        reason: "'추가 회' 는 '정해진 것에 더해서' 로 읽힌다 — 뜻이 정반대다 (계약 §5)",
      );
      expect(_labelOf(tester, WodResultSheet.partFieldKey(1, 'extra')), '+ 회');
    });

    testWidgets('힌트는 서버 score_hints 문장 — "21 미만" 을 그대로 (D124 · 앱 조립 금지)', (tester) async {
      await mountSheet(tester, wodAxesPost());
      expect(_hintOf(tester, WodResultSheet.partFieldKey(1, 'extra')), '21 미만');
    });

    testWidgets('score_hints 가 없으면 빈 값 표시 0', (tester) async {
      // SWEAT(32) B 파트 = AMRAP + Row(meters) — 한 라운드 렙스 합을 셀 수 없다.
      await mountSheet(tester, gymWods().firstWhere((p) => p['id'] == 32));
      expect(_hintOf(tester, WodResultSheet.partFieldKey(1, 'extra')), '0');
    });

    testWidgets('안내 줄은 늘 있다 (고정 높이 한 줄)', (tester) async {
      await mountSheet(tester, wodAxesPost());
      expect(
        find.text('마지막 라운드에서 한 횟수를 적습니다'),
        findsOneWidget,
        reason: '안내 줄이 없으면 "+ 회" 가 무엇인지 알 길이 없다 (계약 §5)',
      );
      // for_time·emom 에는 붙지 않는다 (뜻이 없다).
      expect(find.byKey(WodResultSheet.partFieldKey(2, 'note')), findsNothing);
      expect(find.byKey(WodResultSheet.partFieldKey(3, 'note')), findsNothing);
    });

    testWidgets('무게 없는 동작도 서버 lines 로 선다 (읽기 전용)', (tester) async {
      await mountSheet(tester, wodAxesPost());
      // B 파트 Toes-to-bar — 입력 칸은 없고 줄만 있다.
      expect(find.text('Toes-to-bar 9회'), findsOneWidget);
      expect(
        find.byKey(WodResultSheet.fieldKey(1, 1, null, 'load')),
        findsNothing,
      );
      expect(
        find.byKey(WodResultSheet.fieldKey(1, 1, null, 'reps')),
        findsNothing,
      );
    });
  });

  group('계약 §6 — STRENGTH 세트별 횟수', () {
    testWidgets('세트 줄 힌트는 그 줄의 목표만 (전체 문자열 금지)', (tester) async {
      await mountSheet(tester, wodAxesPost());
      for (var i = 0; i < 5; i++) {
        final hint = _hintOf(tester, WodResultSheet.fieldKey(0, 0, i, 'reps'));
        expect(
          hint,
          '5',
          reason:
              '${i + 1}세트 힌트가 "$hint" 입니다 — 세트 줄마다 전체 처방'
              '(5-5-5-5-5)을 보여 주면 그 줄이 무엇을 요구하는지 알 수 없습니다',
        );
      }
    });

    testWidgets('세트별 횟수가 서버 set_reps 로 채워져 있다', (tester) async {
      await mountSheet(tester, wodAxesPost());
      for (var i = 0; i < 5; i++) {
        expect(
          textOf(tester, WodResultSheet.fieldKey(0, 0, i, 'reps')),
          '5',
          reason: '${i + 1}세트 횟수가 코치 값으로 안 채워졌습니다',
        );
      }
    });

    testWidgets('세트 줄 수는 set_reps 길이 (3세트 처방)', (tester) async {
      // SWEAT(32) A 파트 = Back Squat 5-5-5 → 세 줄.
      await mountSheet(tester, gymWods().firstWhere((p) => p['id'] == 32));
      for (var i = 0; i < 3; i++) {
        expect(
          find.byKey(WodResultSheet.fieldKey(0, 0, i, 'reps')),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(WodResultSheet.fieldKey(0, 0, 3, 'reps')),
        findsNothing,
      );
    });
  });

  group('옛 서버 응답 (score_keys 없음)', () {
    testWidgets('점수 칸 없이도 동작 줄은 그대로 그린다', (tester) async {
      // 계약 전 서버 — 파트에 축 정보가 없다. 앱은 표를 다시 만들지 않고,
      // 적을 수 있는 것(동작 줄)만 그린다 (v3.45 와 같은 화면).
      final raw = Map<String, dynamic>.from(wodAxesPost());
      raw['rounds_data'] = [
        for (final r in raw['rounds_data'] as List)
          {
            for (final e in (r as Map<String, dynamic>).entries)
              if (!const [
                'score_keys',
                'score_labels',
                'score_target',
                'score_hints',
                'show_movement_reps',
                'set_based',
              ].contains(e.key))
                e.key: e.value,
          },
      ];
      await mountSheet(tester, raw);
      expect(find.byKey(WodResultSheet.partFieldKey(2, 'min')), findsNothing);
      expect(find.text('A 파트 · 15분 · STRENGTH'), findsOneWidget);
      // 옛 응답에서는 종전대로 한 횟수 칸을 준다 (판정 규칙을 앱이 만들지 않는다).
      expect(
        find.byKey(WodResultSheet.fieldKey(1, 0, null, 'reps')),
        findsOneWidget,
      );
    });
  });

  group('제출 — 화면에 없는 칸은 보내지 않는다', () {
    testWidgets('세트별 횟수·무게가 그대로 담긴다', (tester) async {
      phone(tester);
      SharedPreferences.setMockInitialValues(signedInPrefs());
      final api = FakeApi({
        '/api/v1/gyms/1/wods/40/results': {
          'result_id': 11,
          'is_pr': false,
          'attendance_added': true,
        },
        ...memberWorld(),
      });
      final gym = GymState(GymRepository(api), sse: FakeSse());
      await gym.loadMine();
      final post = GymWodPost.fromJson(wodAxesPost());
      await tester.pumpWidget(
        harness(
          api: api,
          auth: await signedInAuth(),
          profile: rxProfile(),
          gym: gym,
          home: Scaffold(
            body: SingleChildScrollView(child: WodResultSheet(wod: post)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(WodResultSheet.partFieldKey(3, 'rounds')),
        '10',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(kWodSaveButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(kWodSaveButton));
      await tester.pumpAndSettle();

      final body = api.posts
          .firstWhere((p) => p.path.endsWith('/results'))
          .body;
      final parts = (body['parts'] as List).cast<Map>();
      // EMOM(3)만 적었다 — 나머지 파트는 담기지 않는다 (0 을 지어내지 않는다).
      expect(parts.map((p) => p['index']).toList(), [3]);
      expect(parts.single['rounds'], 10);

      final moves = (body['movements'] as List).cast<Map>();
      final squat = moves.where((m) => m['name'] == 'Back Squat').toList();
      expect(squat, hasLength(5));
      expect(squat.every((m) => m['reps'] == '5'), isTrue);
      // 입력 칸이 없던 동작은 보내지 않는다.
      expect(moves.any((m) => m['name'] == 'Toes-to-bar'), isFalse);
    });
  });
}
