// 기록 축 — **파트 종류가 입력 칸을 정한다** (D121 · docs/CONTRACT-result-axes.md).
//
// 사용자 지적(2026-09-05): "백스쿼트 5×5 수업이면 첫 세트에 몇 kg 로 몇 회 를 적고
// 싶지 않겠나. FOR TIME 은 … 몇 분 만에 끝났나 를 적는 게 중요할 거고."
//
// v3.45(2026-09-02)가 점수 칸을 걷어낸 뒤 파트(D109 · 2026-09-04)가 들어오면서,
// 완료 시트는 파트를 무시하고 모든 동작을 한 줄씩 평평하게 늘어놓고 `[한 횟수][무게]`
// 두 칸만 줬다 — 종류도 파트도 못 보는 상태였다.
//
// 이 검사는 계약 §2 축 표를 **실물 렌더**로 잰다. 축의 정본은 서버
// `services/result_axes.py` 이고, 앱은 `wod_type`·`has_load`·`set_count` 를 읽어서
// 그리기만 한다 (대전제 6-b — 앱에 같은 표를 복제하지 않는다).
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

/// 시트를 화면에 올린다. [raw] 는 서버 응답 모양의 게시물 한 건.
Future<FakeApi> mountSheet(
  WidgetTester tester,
  Map<String, dynamic> raw, {
  Map<String, dynamic>? extraResponses,
}) async {
  phone(tester);
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final api = FakeApi({...?extraResponses, ...memberWorld()});
  final gym = GymState(GymRepository(api), sse: FakeSse());
  await gym.loadMine();
  final post = GymWodPost.fromJson(raw);
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
  return api;
}

String textOf(WidgetTester tester, Key key) =>
    tester.widget<TextField>(find.byKey(key)).controller?.text ?? '';

void main() {
  group('계약 §2 — 파트 종류가 입력 칸을 정한다', () {
    testWidgets('파트 머리줄은 서버 title 그대로', (tester) async {
      await mountSheet(tester, wodAxesPost());
      for (final title in const [
        'A 파트 · 15분 · STRENGTH',
        'B 파트 · 20분 · AMRAP',
        'C 파트 · 12분 · FOR TIME · 캡 12분',
        'D 파트 · 10분 · EMOM',
      ]) {
        expect(
          find.text(title),
          findsOneWidget,
          reason: '파트 머리줄 "$title" 이 없다 — 입력이 파트로 묶이지 않았다',
        );
      }
    });

    testWidgets('for_time — 완주 시간 칸 + 캡 종료 + 남긴 렙스', (tester) async {
      await mountSheet(tester, wodAxesPost());
      // 파트 2 = FOR TIME (캡 12분).
      expect(find.byKey(WodResultSheet.partFieldKey(2, 'min')), findsOneWidget);
      expect(find.byKey(WodResultSheet.partFieldKey(2, 'sec')), findsOneWidget);
      expect(find.text('완주 시간 (분)'), findsOneWidget);
      // 캡이 있는 파트만 캡 종료·남긴 렙스를 가진다.
      expect(find.text('캡 종료'), findsOneWidget);
      expect(
        find.byKey(WodResultSheet.partFieldKey(2, 'extra')),
        findsOneWidget,
      );
      // 남긴 렙스는 캡 종료를 켜야 열린다 (칸은 늘 있고 잠겨만 있다 — 밀림 0).
      final extra = tester.widget<TextField>(
        find.byKey(WodResultSheet.partFieldKey(2, 'extra')),
      );
      expect(extra.enabled, isFalse);
      // 손가락 영역 48 (DESIGN-SSOT §3 · test/touch_target_test.dart 와 같은 기준).
      final cap = tester.getSize(
        find.byKey(WodResultSheet.partFieldKey(2, 'cap')),
      );
      expect(cap.height, greaterThanOrEqualTo(48));
      expect(cap.width, greaterThanOrEqualTo(48));
    });

    testWidgets('캡이 없는 for_time 파트에는 캡 종료가 없다', (tester) async {
      // 게시물 31(AWAKE)은 캡 600초라 캡 줄이 있다 — 캡을 뺀 변형으로 잰다.
      final raw = Map<String, dynamic>.from(
        gymWods().firstWhere((p) => p['id'] == 31),
      );
      raw['rounds_data'] = [
        {
          ...(raw['rounds_data'] as List).first as Map<String, dynamic>,
          'time_cap_sec': null,
        },
      ];
      await mountSheet(tester, raw);
      expect(find.byKey(WodResultSheet.partFieldKey(0, 'min')), findsOneWidget);
      expect(find.text('캡 종료'), findsNothing);
      expect(find.byKey(WodResultSheet.partFieldKey(0, 'extra')), findsNothing);
    });

    testWidgets('amrap — 라운드 + 추가 회', (tester) async {
      await mountSheet(tester, wodAxesPost());
      expect(
        find.byKey(WodResultSheet.partFieldKey(1, 'rounds')),
        findsOneWidget,
      );
      expect(
        find.byKey(WodResultSheet.partFieldKey(1, 'extra')),
        findsOneWidget,
      );
      expect(find.text('라운드'), findsOneWidget);
      expect(find.text('추가 회'), findsOneWidget);
    });

    testWidgets('emom — 점수 칸 없음 (무게 칸만)', (tester) async {
      await mountSheet(tester, wodAxesPost());
      for (final f in const ['min', 'sec', 'rounds', 'extra']) {
        expect(
          find.byKey(WodResultSheet.partFieldKey(3, f)),
          findsNothing,
          reason: 'EMOM 파트에 점수 칸 "$f" 가 생겼다 — 완주가 기본, 점수 축 없음',
        );
      }
      // Clean 은 무게 쓰는 동작이라 무게 칸은 있다.
      expect(
        find.byKey(WodResultSheet.fieldKey(3, 0, null, 'load')),
        findsOneWidget,
      );
    });

    testWidgets('strength — 세트 줄 수는 서버 set_count', (tester) async {
      await mountSheet(tester, wodAxesPost());
      // 코치 5-5-5-5-5 → set_count 5. 각 줄 [무게][횟수].
      for (var i = 0; i < 5; i++) {
        expect(
          find.byKey(WodResultSheet.fieldKey(0, 0, i, 'load')),
          findsOneWidget,
          reason: '${i + 1}세트 무게 칸이 없다',
        );
        expect(
          find.byKey(WodResultSheet.fieldKey(0, 0, i, 'reps')),
          findsOneWidget,
          reason: '${i + 1}세트 횟수 칸이 없다',
        );
      }
      expect(
        find.byKey(WodResultSheet.fieldKey(0, 0, 5, 'load')),
        findsNothing,
        reason: 'set_count 를 넘는 세트 줄이 생겼다',
      );
      // strength 파트 자체에는 점수 칸이 없다 (세트가 담당).
      expect(find.byKey(WodResultSheet.partFieldKey(0, 'rounds')), findsNothing);
      expect(find.byKey(WodResultSheet.partFieldKey(0, 'min')), findsNothing);
    });

    testWidgets('세트 무게는 코치 값으로 채워져 있다', (tester) async {
      await mountSheet(tester, wodAxesPost());
      for (var i = 0; i < 5; i++) {
        expect(
          textOf(tester, WodResultSheet.fieldKey(0, 0, i, 'load')),
          '60',
          reason: '${i + 1}세트 무게가 코치 값(60)으로 안 채워졌다',
        );
      }
    });

    testWidgets('has_load 가 거짓이면 무게 칸이 없다', (tester) async {
      await mountSheet(tester, wodAxesPost());
      // 파트 1 동작 1 = Toes-to-bar (has_load false) · 파트 2 동작 0 = Row.
      expect(
        find.byKey(WodResultSheet.fieldKey(1, 1, null, 'load')),
        findsNothing,
        reason: '토투바에 무게 칸을 줬다',
      );
      expect(
        find.byKey(WodResultSheet.fieldKey(2, 0, null, 'load')),
        findsNothing,
        reason: 'Row(500m)에 무게 칸을 줬다',
      );
      // 같은 파트의 무게 쓰는 동작에는 있다.
      expect(
        find.byKey(WodResultSheet.fieldKey(1, 0, null, 'load')),
        findsOneWidget,
      );
      expect(
        find.byKey(WodResultSheet.fieldKey(2, 1, null, 'load')),
        findsOneWidget,
      );
    });

    testWidgets('for_time·amrap·emom 동작 줄에는 횟수 칸이 없다', (tester) async {
      await mountSheet(tester, wodAxesPost());
      for (final (part, move) in const [(1, 0), (1, 1), (2, 0), (2, 1), (3, 0)]) {
        expect(
          find.byKey(WodResultSheet.fieldKey(part, move, null, 'reps')),
          findsNothing,
          reason: '파트 $part 동작 $move 에 횟수 칸이 생겼다 — 점수 축이 파트에 있다',
        );
      }
    });

    testWidgets('custom(수업) — 동작마다 한 횟수, 무게는 has_load 인 동작만', (
      tester,
    ) async {
      // 게시물 32 = SWEAT (C 파트가 custom · Plank 60초, 무게 없음).
      await mountSheet(
        tester,
        gymWods().firstWhere((p) => p['id'] == 32),
      );
      expect(
        find.byKey(WodResultSheet.fieldKey(2, 0, null, 'reps')),
        findsOneWidget,
        reason: 'custom 파트 동작에 한 횟수 칸이 없다',
      );
      expect(
        find.byKey(WodResultSheet.fieldKey(2, 0, null, 'load')),
        findsNothing,
        reason: 'Plank(무게 없음)에 무게 칸을 줬다',
      );
    });
  });

  group('계약 §4 — 제출 payload', () {
    testWidgets('parts[] · movements[] · 빈 칸 제외 · wod_type 미전송', (tester) async {
      phone(tester);
      SharedPreferences.setMockInitialValues(signedInPrefs());
      final api = FakeApi({
        '/api/v1/gyms/1/wods/40/results': {
          'result_id': 7,
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
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        body: SingleChildScrollView(
                          child: WodResultSheet(wod: post),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      // 회원이 적는다: AMRAP 5R+12 · FOR TIME 12분 34초 · 1·2세트 무게만 고침.
      await tester.enterText(
        find.byKey(WodResultSheet.partFieldKey(1, 'rounds')),
        '5',
      );
      await tester.enterText(
        find.byKey(WodResultSheet.partFieldKey(1, 'extra')),
        '12',
      );
      await tester.enterText(
        find.byKey(WodResultSheet.partFieldKey(2, 'min')),
        '12',
      );
      await tester.enterText(
        find.byKey(WodResultSheet.partFieldKey(2, 'sec')),
        '34',
      );
      await tester.enterText(
        find.byKey(WodResultSheet.fieldKey(0, 0, 1, 'load')),
        '65',
      );
      await tester.pump();

      await tester.ensureVisible(find.byKey(kWodSaveButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(kWodSaveButton));
      await tester.pumpAndSettle();

      final sent = api.posts.where((p) => p.path.endsWith('/results')).toList();
      expect(sent, hasLength(1), reason: '결과 제출이 한 번 나가야 한다');
      final body = sent.single.body;

      // 점수가 있는 파트만 — strength(0)·emom(3)은 안 보낸다.
      final parts = (body['parts'] as List).cast<Map>();
      expect(parts.map((p) => p['index']).toList(), [1, 2]);
      expect(parts[0]['rounds'], 5);
      expect(parts[0]['extra_reps'], 12);
      expect(parts[1]['time_sec'], 754); // 12*60 + 34
      expect(parts[1]['capped'], false);
      for (final p in parts) {
        expect(
          p.containsKey('wod_type'),
          isFalse,
          reason: 'wod_type 은 서버가 게시물에서 읽는다 — 앱이 보내지 않는다',
        );
      }

      final moves = (body['movements'] as List).cast<Map>();
      // strength 5세트 — set_index 0..4, part_index 0.
      final squat = moves.where((m) => m['name'] == 'Back Squat').toList();
      expect(squat.map((m) => m['set_index']).toList(), [0, 1, 2, 3, 4]);
      expect(squat.every((m) => m['part_index'] == 0), isTrue);
      expect(squat[1]['load_kg'], 65);
      expect(squat[0]['load_kg'], 60);
      // set_index 는 strength 에만.
      final thruster = moves.firstWhere((m) => m['name'] == 'Thruster');
      expect(thruster['part_index'], 1);
      expect(thruster.containsKey('set_index'), isFalse);
      expect(thruster['load_kg'], 40);
      // 칸이 없던 동작은 아예 안 보낸다 (0 을 지어내지 않는다).
      expect(moves.any((m) => m['name'] == 'Toes-to-bar'), isFalse);
      expect(moves.any((m) => m['name'] == 'Row'), isFalse);
    });

    testWidgets('빈 칸만 있으면 parts 를 안 보낸다', (tester) async {
      phone(tester);
      SharedPreferences.setMockInitialValues(signedInPrefs());
      final api = FakeApi({
        '/api/v1/gyms/1/wods/40/results': {
          'result_id': 8,
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
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        body: SingleChildScrollView(
                          child: WodResultSheet(wod: post),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(kWodSaveButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(kWodSaveButton));
      await tester.pumpAndSettle();

      final body = api.posts
          .firstWhere((p) => p.path.endsWith('/results'))
          .body;
      expect(
        body.containsKey('parts'),
        isFalse,
        reason: '아무것도 안 적었는데 parts 를 보내면 0 을 지어내는 것',
      );
    });
  });

  group('계약 §3 — 재수정 프리필 (my_result)', () {
    testWidgets('파트 점수·세트별 값이 되채워진다', (tester) async {
      await mountSheet(tester, wodAxesPostWithResult());
      expect(textOf(tester, WodResultSheet.partFieldKey(1, 'rounds')), '5');
      expect(textOf(tester, WodResultSheet.partFieldKey(1, 'extra')), '12');
      expect(textOf(tester, WodResultSheet.partFieldKey(2, 'min')), '12');
      expect(textOf(tester, WodResultSheet.partFieldKey(2, 'sec')), '34');
      // 세트별 — 1세트 60kg, 2세트 65kg.
      expect(textOf(tester, WodResultSheet.fieldKey(0, 0, 0, 'load')), '60');
      expect(textOf(tester, WodResultSheet.fieldKey(0, 0, 1, 'load')), '65');
      expect(textOf(tester, WodResultSheet.fieldKey(0, 0, 0, 'reps')), '5');
      expect(textOf(tester, WodResultSheet.fieldKey(0, 0, 1, 'reps')), '5');
      // set_index 없는(파트만 있는) 저장 값도 그 파트의 동작에 붙는다.
      expect(textOf(tester, WodResultSheet.fieldKey(1, 0, null, 'load')), '40');
    });
  });
}
