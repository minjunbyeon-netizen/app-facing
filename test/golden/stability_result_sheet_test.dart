// 완료 시트 레이아웃 안정성 — 저장 버튼·고지 줄이 '저장 중' 으로 바뀌어도 밀리지 않는다.
//
// 2026-08-30 저장 중 토스트를 붙이며 버튼을 `HkLoading` 스왑(높이 22)에서 자리 그대로
// busy(높이 52)로 바꿨다 — 종전엔 누르는 순간 아래 고지 줄이 30px 위로 튀었다.
// 정본 규칙 = docs/DESIGN-SSOT.md §레이아웃 안정성 (로딩 스왑 밀림 금지).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/gym/wod_result_sheet.dart';
import 'package:hyphen_app/models/gym.dart';

import 'fakes.dart';
import 'harness.dart';
import 'layout_stability.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

/// 상태를 하나씩 다시 올릴 때마다 **새 State** 를 강제한다. 키가 같으면 Flutter 가
/// 같은 위젯으로 보고 State 를 재사용해서, 다른 게시물을 올려도 `initState` 에서
/// 편 파트 목록이 앞 상태의 것으로 남는다 (2026-09-06 D122 검사에서 실측).
int _mountSeq = 0;
Key _freshSheetKey() => ValueKey('sheet-${_mountSeq++}');

void main() {
  const resultsPath = '/api/v1/gyms/1/wods/31/results';

  Future<void> mount(
    WidgetTester tester, {
    bool hang = false,
    bool fail = false,
  }) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(
      memberWorld(),
      hangPaths: hang ? {resultsPath} : const {},
      errorPaths: fail ? {resultsPath} : const {},
    );
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    final post = GymWodPost.fromJson(
      gymWods().firstWhere((p) => p['id'] == 31),
    );
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: Scaffold(
          body: SingleChildScrollView(child: WodResultSheet(key: _freshSheetKey(), wod: post)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 시트가 화면보다 길다 — 두 상태 모두 같은 만큼 내려 버튼을 보이게 한 뒤 잰다.
    await tester.ensureVisible(find.byKey(kWodSaveButton));
    await tester.pumpAndSettle();
  }

  testWidgets('완료 시트: 저장 버튼·고지 줄은 저장 중에도 같은 y', (tester) async {
    await expectStableAnchorY(
      tester,
      states: {
        '대기': (t) => mount(t),
        '저장 중': (t) async {
          await mount(t, hang: true);
          await t.tap(find.byKey(kWodSaveButton));
          await t.pump(const Duration(milliseconds: 300));
          expect(find.text(kWodSavingTitle), findsOneWidget);
        },
      },
      anchors: {
        '저장 버튼': kWodSaveButton,
        '고지 줄': kWodSaveCaption,
      },
    );
  });

  // D117 (2026-09-04) — 에러 상태가 검사 밖이었다.
  // 저장이 실패하면 `if (_error != null) ...[` 블록이 **저장 버튼 바로 위**에 생겨
  // 버튼과 고지 줄을 통째로 밀어 내린다. 사람이 다시 누르려던 버튼이 손가락
  // 아래에서 도망간다 — 실패 직후가 가장 다시 누르기 쉬운 순간인데 그렇다.
  // 정본 규칙 = docs/DESIGN-SSOT.md §레이아웃 안정성 (밀림 2번 — 조건부 블록).
  testWidgets('완료 시트: 저장이 실패해도 버튼·고지 줄은 같은 y', (tester) async {
    await expectStableAnchorY(
      tester,
      states: {
        '대기': (t) => mount(t),
        '저장 실패': (t) async {
          await mount(t, fail: true);
          await t.tap(find.byKey(kWodSaveButton));
          await t.pumpAndSettle();
          // 실패 문구가 실제로 떠 있는 상태에서 재야 의미가 있다
          expect(find.byKey(kWodSaveButton), findsOneWidget);
        },
      },
      anchors: {
        '저장 버튼': kWodSaveButton,
        '고지 줄': kWodSaveCaption,
      },
    );
  });

  // ── D121 (2026-09-05) — 파트가 여럿인 시트 (계약 CONTRACT-result-axes.md) ──
  //
  // 파트마다 종류가 다른 점수 칸(완주 시간·라운드·세트 줄)이 서면 시트가 길어진다.
  // 길어지는 것 자체는 문제가 아니다 (시트는 스크롤된다) — 문제는 **상태가 바뀔 때**
  // 그 안에서 무엇이 생겼다 사라지며 아래를 미는 것이다. 두 가지를 잰다:
  //   1. 저장 중·저장 실패로 바뀌어도 버튼·고지 줄이 그 자리인가
  //   2. '캡 종료' 를 켜서 '남긴 렙스' 칸이 열려도 아래가 안 밀리는가
  //      (조건부 블록으로 만들었다면 여기서 걸린다 — 그래서 칸을 늘 그려 두고
  //       enabled 만 바꾼다)
  const axesResults = '/api/v1/gyms/1/wods/40/results';

  Future<void> mountAxes(
    WidgetTester tester, {
    bool hang = false,
    bool fail = false,
    Map<String, dynamic>? raw,
  }) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(signedInPrefs());
    final api = FakeApi(
      memberWorld(),
      hangPaths: hang ? {axesResults} : const {},
      errorPaths: fail ? {axesResults} : const {},
    );
    final gym = GymState(GymRepository(api), sse: FakeSse());
    await gym.loadMine();
    final post = GymWodPost.fromJson(raw ?? wodAxesPost());
    await tester.pumpWidget(
      harness(
        api: api,
        auth: await signedInAuth(),
        profile: rxProfile(),
        gym: gym,
        home: Scaffold(
          body: SingleChildScrollView(child: WodResultSheet(key: _freshSheetKey(), wod: post)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollToSave(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(kWodSaveButton));
    await tester.pumpAndSettle();
  }

  // 상태 목록은 위 두 검사와 같은 이유로 한 검사에 하나씩만 묶는다 — 저장 중
  // 토스트의 로딩바가 끝나지 않는 애니메이션이라 그 뒤에 다시 pumpWidget 하면
  // 살아남은 ScaffoldMessenger 때문에 다음 상태가 서지 않는다.
  testWidgets('파트 넷 시트: 저장 중에도 버튼·고지 줄은 같은 y', (tester) async {
    await expectStableAnchorY(
      tester,
      states: {
        '대기': (t) async {
          await mountAxes(t);
          await scrollToSave(t);
        },
        '저장 중': (t) async {
          await mountAxes(t, hang: true);
          await scrollToSave(t);
          await t.tap(find.byKey(kWodSaveButton));
          await t.pump(const Duration(milliseconds: 300));
          expect(find.text(kWodSavingTitle), findsOneWidget);
        },
      },
      anchors: {
        '저장 버튼': kWodSaveButton,
        '고지 줄': kWodSaveCaption,
      },
    );
  });

  testWidgets('파트 넷 시트: 저장이 실패해도 버튼·고지 줄은 같은 y', (tester) async {
    await expectStableAnchorY(
      tester,
      states: {
        '대기': (t) async {
          await mountAxes(t);
          await scrollToSave(t);
        },
        '저장 실패': (t) async {
          await mountAxes(t, fail: true);
          await scrollToSave(t);
          await t.tap(find.byKey(kWodSaveButton));
          await t.pumpAndSettle();
          expect(find.byKey(kWodSaveButton), findsOneWidget);
        },
      },
      anchors: {
        '저장 버튼': kWodSaveButton,
        '고지 줄': kWodSaveCaption,
      },
    );
  });

  // '캡 종료' 는 켤 때 '남긴 렙스' 칸이 **생기는** 자리다 — 조건부 블록으로 만들면
  // 그 아래가 통째로 밀린다 (DESIGN-SSOT §레이아웃 안정성 밀림 2번). 그래서 칸을
  // 늘 그려 두고 enabled 만 바꾼다.
  //
  // 여기서는 **자리의 높이**로 잰다. 앵커 y 로 재면 못 잡는다 — 시트가 스크롤되고
  // 검사가 저장 버튼까지 내려서 재기 때문에, 위가 길어져도 버튼의 화면 y 는 같다
  // (2026-09-05 실측으로 확인 — 조건부 블록을 일부러 넣어도 y 검사는 통과했다).
  testWidgets("파트 넷 시트: '캡 종료' 를 켜도 점수 자리 높이가 그대로", (tester) async {
    // 캡이 걸린 파트 = index 2 (C 파트 · FOR TIME · 캡 12분).
    final cap = WodResultSheet.partFieldKey(2, 'cap');
    await expectStableHeight(
      tester,
      states: {
        '캡 끔': (t) async {
          await mountAxes(t);
          await t.ensureVisible(find.byKey(cap));
          await t.pumpAndSettle();
        },
        '캡 켬': (t) async {
          await mountAxes(t);
          await t.ensureVisible(find.byKey(cap));
          await t.pumpAndSettle();
          await t.tap(find.byKey(cap));
          await t.pumpAndSettle();
          // 실제로 켜진 상태에서 재야 의미가 있다 — 남긴 렙스 칸이 열렸는지.
          final extra = t.widget<TextField>(
            find.byKey(WodResultSheet.partFieldKey(2, 'extra')),
          );
          expect(extra.enabled, isTrue, reason: '캡을 켰는데 남긴 렙스 칸이 안 열렸다');
        },
      },
      targets: {'FOR TIME 점수 자리': WodResultSheet.partFieldKey(2, 'score')},
    );
  });

  // ── D122 (2026-09-06) — 파트·세트가 늘어도 저장 버튼이 도망가지 않는다
  //    (계약 CONTRACT-result-axes-2.md §9 앱 게이트 마지막 줄).
  //
  //    D122 로 시트가 길어지는 자리가 셋 늘었다: EMOM 점수 칸 · AMRAP 안내 줄 ·
  //    입력 칸 없는 동작의 읽기 전용 줄. 길어지는 것 자체는 문제가 아니지만(시트는
  //    스크롤된다), 길이에 따라 **버튼이 화면에서 잡히는 자리**가 달라지면 손가락
  //    아래에서 도망간다. 파트 다섯·세트 여덟짜리 시트로 그 끝을 재 둔다.
  testWidgets('파트·세트가 늘어도 저장 버튼·고지 줄은 같은 y', (tester) async {
    Map<String, dynamic> bigger() {
      final raw = Map<String, dynamic>.from(wodAxesPost());
      final rounds = [
        for (final r in raw['rounds_data'] as List)
          Map<String, dynamic>.from(r as Map<String, dynamic>),
      ];
      // 세트 다섯 → 여덟.
      final a = Map<String, dynamic>.from(rounds[0]);
      a['movements'] = [
        {
          ...(a['movements'] as List).first as Map<String, dynamic>,
          'set_count': 8,
          'set_reps': const ['5', '5', '5', '3', '3', '3', '1', '1'],
        },
      ];
      rounds[0] = a;
      // 파트 넷 → 다섯 (맨몸 EMOM 한 파트 추가).
      final extra = Map<String, dynamic>.from(
        (wodEmomBodyweightPost()['rounds_data'] as List).first
            as Map<String, dynamic>,
      );
      extra['index'] = 4;
      extra['title'] = 'E 파트 · 10분 · EMOM';
      raw['rounds_data'] = [...rounds, extra];
      return raw;
    }

    await expectStableAnchorY(
      tester,
      states: {
        '파트 넷': (t) async {
          await mountAxes(t);
          await scrollToSave(t);
        },
        '파트 다섯 · 세트 여덟': (t) async {
          await mountAxes(t, raw: bigger());
          await scrollToSave(t);
          expect(
            find.byKey(WodResultSheet.partFieldKey(4, 'rounds')),
            findsOneWidget,
            reason: '늘린 EMOM 파트가 실제로 서 있어야 잰 값에 뜻이 있다',
          );
        },
      },
      anchors: {'저장 버튼': kWodSaveButton, '고지 줄': kWodSaveCaption},
    );
  });
}
