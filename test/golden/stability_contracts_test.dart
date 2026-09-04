import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/core/theme.dart';
import 'package:hyphen_app/features/contracts/member_contracts_screen.dart';
import 'package:hyphen_app/widgets/hkit.dart';

import 'fakes.dart';
import 'harness.dart';
import 'layout_stability.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

/// 전자계약(목록·상세) 레이아웃 안정성(layout stability) 회귀 게이트 — D118 ·
/// 규격 정본 = docs/DESIGN-SSOT.md §레이아웃 안정성.
///
/// **고치기 전 실측 (2026-09-05)** — 첫 내용의 y:
///
/// | 화면 | 목록/내용 | 실패 | 0건 | 로딩 |
/// |---|---|---|---|---|
/// | 계약 목록 | 68 | 374.5 | 391.5 | **405** |
/// | 계약 상세 | 68 | 374.5 | — | **405** |
///
/// 최대 **337px**. 원인은 본문 **전체**를 4상태로 갈아 끼운 것이다 — 상태
/// 위젯(`HkLoading.slot`·`HkEmptyState`·`HkErrorState`)이 화면을 꽉 채우도록
/// 늘어나 내용을 세로 가운데에 놓았고, 목록은 위에서부터 그려졌다.
///
/// 지금은 뼈대(상단바 + 본문 자리)가 항상 그대로고, 변하는 것은 예약된 자리
/// ([HyphenTokens.stateSlotH]) **안에서만** 바뀐다.

/// 무한 애니메이션(스피너)이 있어도 안전한 정착 — pumpAndSettle 금지.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _reset(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

const String _listPath = '/api/v1/member/me/contracts';
const String _detailPath = '/api/v1/member/contracts/2';

Future<void> _pumpList(
  WidgetTester tester, {
  dynamic rows,
  bool hanging = false,
  bool failing = false,
}) async {
  await _reset(tester);
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final api = FakeApi(
    {...memberWorld(), _listPath: rows ?? memberContracts},
    hangPaths: hanging ? const {_listPath} : const {},
    errorPaths: failing ? const {_listPath} : const {},
  );
  await tester.pumpWidget(
    harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      home: const MemberContractsScreen(),
    ),
  );
  await _settle(tester);
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  bool hanging = false,
  bool failing = false,
}) async {
  await _reset(tester);
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final api = FakeApi(
    {...memberWorld(), _detailPath: memberContractDetail},
    hangPaths: hanging ? const {_detailPath} : const {},
    errorPaths: failing ? const {_detailPath} : const {},
  );
  await tester.pumpWidget(
    harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      home: const ContractDetailScreen(contractId: 2),
    ),
  );
  await _settle(tester);
}

Map<String, ScreenState> _listStates() => {
  '계약 2건': (t) async {
    await _pumpList(t);
    expect(find.text('회원권 이용 계약'), findsOneWidget);
  },
  // 로딩 증명은 '데이터가 아직 없다' 로 한다 — 로딩 표현(스켈레톤·스피너)이
  // 바뀌어도 상태 정의는 그대로여야 검사가 표현에 끌려다니지 않는다.
  '로딩 중': (t) async {
    await _pumpList(t, hanging: true);
    expect(find.text('회원권 이용 계약'), findsNothing);
    expect(find.byKey(MemberContractsScreen.kBody), findsOneWidget);
  },
  '0건': (t) async {
    await _pumpList(t, rows: const <dynamic>[]);
    expect(find.text('계약 없음'), findsOneWidget);
  },
  '불러오기 실패': (t) async {
    await _pumpList(t, failing: true);
    expect(find.text('다시 시도'), findsOneWidget);
  },
};

Map<String, ScreenState> _detailStates() => {
  '서명 대기': (t) async {
    await _pumpDetail(t);
    expect(find.text('서명'), findsWidgets);
  },
  '로딩 중': (t) async {
    await _pumpDetail(t, hanging: true);
    expect(find.byType(HkLoading), findsOneWidget);
  },
  '불러오기 실패': (t) async {
    await _pumpDetail(t, failing: true);
    expect(find.text('다시 시도'), findsOneWidget);
  },
};

void main() {
  // ── 계약 목록 ────────────────────────────────────────────────────────────
  testWidgets('계약 목록 — 네 상태에서 본문 자리 y 가 같다', (tester) async {
    phone(tester);
    final table = await expectStableAnchorY(
      tester,
      states: _listStates(),
      anchors: {'본문자리': MemberContractsScreen.kBody},
    );
    // ignore: avoid_print — 표를 그대로 보고에 쓴다.
    print(formatAnchorTable(table));
  });

  testWidgets('계약 목록 — 로딩·0건·실패는 같은 바닥을 갖는다', (tester) async {
    phone(tester);
    final states = _listStates();
    final table = await expectStableHeight(
      tester,
      states: {
        '로딩 중': states['로딩 중']!,
        '0건': states['0건']!,
        '불러오기 실패': states['불러오기 실패']!,
      },
      targets: {'본문자리': MemberContractsScreen.kBody},
    );
    expect(
      table['로딩 중']!['본문자리'],
      HyphenTokens.stateSlotH,
      reason:
          '본문 자리가 예약한 바닥(stateSlotH)과 다릅니다 — 상태 위젯이 다시 '
          '화면 전체로 늘어났을 수 있습니다.',
    );
    // ignore: avoid_print
    print(formatAnchorTable(table));
  });

  testWidgets('계약 목록 — 스켈레톤과 첫 계약 카드가 같은 자리에서 시작한다', (tester) async {
    phone(tester);
    final table = await expectStableAnchorY(
      tester,
      states: {
        '로딩 중': _listStates()['로딩 중']!,
        '계약 2건': _listStates()['계약 2건']!,
      },
      anchors: {'첫 줄': MemberContractsScreen.kFirstRow},
    );
    // ignore: avoid_print
    print(formatAnchorTable(table));
  });

  testWidgets('계약 목록 — 스켈레톤 높이가 실제 카드 높이와 같다', (tester) async {
    phone(tester);
    await _pumpList(tester, hanging: true);
    final skeletonH = tester
        .getSize(find.byKey(MemberContractsScreen.kFirstRow))
        .height;
    await _pumpList(tester);
    final cardH = tester
        .getSize(find.byKey(MemberContractsScreen.kFirstRow))
        .height;
    expect(
      cardH,
      MemberContractsScreen.kRowH,
      reason:
          '계약 카드 높이가 바뀌었습니다 — 스켈레톤(kRowH)도 같이 고치십시오. '
          '한쪽만 바뀌면 로딩이 끝나는 순간 목록이 그 차이만큼 밀립니다.',
    );
    expect(
      skeletonH,
      cardH,
      reason:
          '스켈레톤이 카드와 다른 높이입니다 — 예약한 자리(stateSlotH)가 '
          '스켈레톤을 늘려 세로 가운데로 밀고 있는지 보십시오 (Align topCenter).',
    );
  });

  // ── 계약 상세 ────────────────────────────────────────────────────────────
  testWidgets('계약 상세 — 로딩·내용·실패에서 본문 자리 y 가 같다', (tester) async {
    phone(tester);
    final table = await expectStableAnchorY(
      tester,
      states: _detailStates(),
      anchors: {'본문자리': ContractDetailScreen.kBody},
    );
    // ignore: avoid_print
    print(formatAnchorTable(table));
  });

  testWidgets('계약 상세 — 로딩·실패는 같은 바닥을 갖는다', (tester) async {
    phone(tester);
    final states = _detailStates();
    final table = await expectStableHeight(
      tester,
      states: {'로딩 중': states['로딩 중']!, '불러오기 실패': states['불러오기 실패']!},
      targets: {'본문자리': ContractDetailScreen.kBody},
    );
    expect(table['로딩 중']!['본문자리'], HyphenTokens.stateSlotH);
    // ignore: avoid_print
    print(formatAnchorTable(table));
  });
}
