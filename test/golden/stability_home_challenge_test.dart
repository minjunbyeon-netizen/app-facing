import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/core/theme.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/home/challenge_section.dart';
import 'package:hyphen_app/features/shell/main_shell.dart';
import 'package:hyphen_app/widgets/hkit.dart';

import 'fakes.dart';
import 'harness.dart';
import 'layout_stability.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

/// 홈 '도전' 섹션 레이아웃 안정성(layout stability) 회귀 게이트 — D118 ·
/// 규격 정본 = docs/DESIGN-SSOT.md §레이아웃 안정성.
///
/// **고치기 전 실측 (2026-09-05)**: 로딩 0px · 0건 0px · 실패 0px · 도전 2건
/// **289px**. 규칙이 도착하는 순간 섹션이 통째로 생겨났고, 홈 스크롤 총길이가
/// 145 → 434 로 3배가 됐다. "홈 마지막이라 위는 안 밀린다" 는 안전의 근거가
/// 못 된다 — 스크롤 위치·막대 길이가 튀고, 홈 아래에 무엇이든 붙는 순간
/// 그대로 밀림이 된다. 실패가 0px 인 것은 밀림이자 **거짓말**이기도 했다:
/// 못 읽은 것과 없는 것이 화면에서 똑같이 보였다.
///
/// 지금은 섹션이 **항상 서 있고** 안만 갈아 끼운다 — 로딩·0건·실패가 같은
/// 바닥([HyphenTokens.stateSlotH])을 쓴다. 이 검사가 실패하면 섹션이 다시
/// `SizedBox.shrink()` 로 사라졌다는 뜻이다.

/// 무한 애니메이션(스피너)이 있어도 안전한 정착 — pumpAndSettle 금지.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// 상태마다 트리를 새로 세운다 — 같은 구조를 다시 pump 하면 Flutter 가 element 를
/// 재사용해 앞 상태의 State·Future 가 그대로 남는다 (상태별 검사가 헛돈다).
Future<void> _reset(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

const String _progressPath = '/api/v1/member/me/reward-progress';

/// 섹션만 단독으로 세운다 — 홈 안에서 재면 상태마다 스크롤 최대치가 달라
/// (145 vs 434) 같은 만큼 끌어도 도달 위치가 달라진다. 좌표 검사는 스크롤이
/// 개입하지 않는 자리에서 해야 한다 (코치 주간 검사와 같은 방식).
Future<void> _pumpSection(
  WidgetTester tester, {
  Map<String, dynamic>? world,
  bool hanging = false,
  bool failing = false,
}) async {
  await _reset(tester);
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final api = FakeApi(
    world ?? memberWorld(),
    hangPaths: hanging ? const {_progressPath} : const {},
    errorPaths: failing ? const {_progressPath} : const {},
  );
  final gym = GymState(GymRepository(api), sse: FakeSse());
  await gym.loadMine();
  await tester.pumpWidget(
    harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      gym: gym,
      home: const Scaffold(
        body: SingleChildScrollView(child: ChallengeSection()),
      ),
    ),
  );
  await _settle(tester);
}

Map<String, dynamic> _noRules() {
  final world = memberWorld();
  world[_progressPath] = const <dynamic>[];
  return world;
}

Map<String, ScreenState> _sectionStates() => {
  '도전 2건': (t) async {
    await _pumpSection(t);
    expect(find.textContaining('달리기 인증'), findsWidgets);
  },
  '로딩 중': (t) async {
    await _pumpSection(t, hanging: true);
    expect(find.byType(HkLoading), findsOneWidget);
  },
  '0건': (t) async {
    await _pumpSection(t, world: _noRules());
    expect(find.text('등록된 도전 없음'), findsOneWidget);
  },
  '불러오기 실패': (t) async {
    await _pumpSection(t, failing: true);
    expect(find.text('다시 시도'), findsOneWidget);
  },
};

/// 홈 셸 안에서 섹션까지 스크롤한다 — 배선(홈 마지막 자리)이 살아 있는지 확인용.
/// 좌표가 아니라 **존재**만 본다 (스크롤 위치는 상태마다 다르다).
Future<void> _pumpHomeAndScroll(
  WidgetTester tester, {
  Map<String, dynamic>? world,
  bool hanging = false,
  bool failing = false,
}) async {
  await _reset(tester);
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final api = FakeApi(
    world ?? memberWorld(),
    hangPaths: hanging ? const {_progressPath} : const {},
    errorPaths: failing ? const {_progressPath} : const {},
  );
  final gym = GymState(GymRepository(api), sse: FakeSse());
  await gym.loadMine();
  await tester.pumpWidget(
    harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      gym: gym,
      home: const MainShell(),
    ),
  );
  await _settle(tester);
  await tapTab(tester, '홈');
  await _settle(tester);
  // 홈 ListView 는 lazy 다 — 화면 밖 마지막 자식은 아예 지어지지 않는다.
  await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
  await _settle(tester);
}

void main() {
  testWidgets('도전 섹션 — 로딩·데이터·0건·실패에서 라벨·본문 자리 y 가 같다', (tester) async {
    phone(tester);
    final table = await expectStableAnchorY(
      tester,
      states: _sectionStates(),
      anchors: {
        '도전라벨': ChallengeSection.kLabel,
        '본문자리': ChallengeSection.kBody,
      },
    );
    // ignore: avoid_print — 표를 그대로 보고에 쓴다.
    print(formatAnchorTable(table));
  });

  testWidgets('도전 섹션 — 로딩·0건·실패는 같은 바닥을 갖는다', (tester) async {
    phone(tester);
    final states = _sectionStates();
    final table = await expectStableHeight(
      tester,
      states: {
        '로딩 중': states['로딩 중']!,
        '0건': states['0건']!,
        '불러오기 실패': states['불러오기 실패']!,
      },
      targets: {'본문자리': ChallengeSection.kBody},
    );
    // 예약한 바닥(stateSlotH)보다 낮으면 도착할 때 밀린다.
    expect(
      table['로딩 중']!['본문자리'],
      greaterThanOrEqualTo(HyphenTokens.stateSlotH),
      reason: '도전 본문 자리가 예약한 바닥(stateSlotH)보다 낮습니다.',
    );
    // ignore: avoid_print
    print(formatAnchorTable(table));
  });

  testWidgets('도전 섹션 — 홈 마지막 자리에서 네 상태 모두 서 있다', (tester) async {
    phone(tester);
    for (final entry in <String, Future<void> Function(WidgetTester)>{
      '도전 2건': (t) => _pumpHomeAndScroll(t),
      '로딩 중': (t) => _pumpHomeAndScroll(t, hanging: true),
      '0건': (t) => _pumpHomeAndScroll(t, world: _noRules()),
      '불러오기 실패': (t) => _pumpHomeAndScroll(t, failing: true),
    }.entries) {
      await entry.value(tester);
      expect(
        find.byKey(ChallengeSection.kLabel),
        findsOneWidget,
        reason:
            "홈 '도전' 섹션이 '${entry.key}' 에서 사라졌습니다 — 섹션은 상태와 "
            '무관하게 항상 서 있어야 합니다 (DESIGN-SSOT §레이아웃 안정성).',
      );
    }
  });
}
