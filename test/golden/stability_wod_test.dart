import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/core/api_client.dart';
import 'package:hyphen_app/features/classes/class_line.dart';
import 'package:hyphen_app/features/gym/box_wod_screen.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/gym/week_board.dart';
import 'package:hyphen_app/features/gym/wod_detail_screen.dart';

import 'fakes.dart';
import 'harness.dart';
import 'layout_stability.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

/// 레이아웃 안정성(layout stability) 회귀 게이트 — 수업 면 3화면.
/// 정본 규칙 = `docs/DESIGN-SSOT.md §레이아웃 안정성` · 헬퍼 = layout_stability.dart.
///
/// 여기서 지키는 약속은 하나다: **상태가 바뀌어도 요소의 y 가 변하지 않는다.**
/// - 수업 상세 — 네 구역(피드백·리더보드·내 이전 기록·댓글)이 각자 다른 시점에
///   도착해도 아래 구역·댓글 입력칸이 제자리다. 순차 도착(일부만 도착)이 가장
///   중요한 상태다 — 실제 사용자가 만나는 것이 그 중간 화면이기 때문이다.
/// - 수업 탭 — 상단 실패 배너가 떠도 주간 보드·체육관 정보가 안 밀린다.
/// - 주간 보드 — 요일을 펼쳤을 때 수업 목록이 로딩→도착으로 바뀌어도 그 아래
///   요일 줄이 안 밀린다.
///
/// 실패하면 "어느 앵커가 어느 상태에서 몇 px 밀렸다"가 표로 나온다. 원인은 대개
/// 넷 중 하나다 — 조건부 블록(`if (x != null) ...[]`) · 로딩과 '없음'을 같은
/// 화면으로 그림 · 로딩 교체 · 예약 높이보다 큰 내용.

const int _wodId = 31;
const String _wodPath = '/api/v1/gyms/1/wods/$_wodId';

/// 무한 애니메이션(스피너)이 있어도 안전한 정착 — pumpAndSettle 금지.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// 세로로 긴 화면 — 상세는 한 화면보다 길어서, 폰 높이로 재면 아래쪽 앵커가
/// 아직 만들어지지 않는다(ListView 는 보이는 만큼만 만든다). 폭은 갤S22 그대로.
void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(720, 4000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

// ── 수업 상세: 네 구역의 응답 ───────────────────────────────────────────────
// 각 구역 **한 줄**씩 — 예약 높이(WodDetailScreen.slot*H)가 한 줄 기준이라
// 도착해도 아래가 밀리지 않아야 한다.

List<Map<String, dynamic>> _feedbackOne() => [
  {
    'id': 1,
    'member_hash_prefix': 'a1b2',
    'is_mine': true,
    'body': '2라운드부터 프론트랙이 무너집니다.',
    'created_at': '2026-08-12T09:00:00',
    'updated_at': '2026-08-12T09:00:00',
  },
];

List<Map<String, dynamic>> _resultsOne() => [
  {
    'id': 1,
    'rank': 1,
    'device_hash_prefix': 'c3d4',
    'is_mine': false,
    'time_sec': 258,
    'scale_level': 'rx',
    'notes': '',
    'created_at': '2026-08-12T09:10:00',
  },
];

List<Map<String, dynamic>> _commentsOne() => [
  {
    'id': 1,
    'author_prefix': 'e5f6',
    'is_mine': false,
    'body': 'Thruster 중량 낮춰 완주했습니다.',
    'created_at': '2026-08-12T09:20:00',
  },
];

Map<String, dynamic> _historyOne() => {
  'kind': 'time',
  'items': [
    {'wod_post_id': 29, 'date': '2026-08-05', 'label': '4:30', 'is_pr': false},
  ],
};

/// 네 구역 응답을 갈아 끼운 세계. 구체 경로가 `/api/v1/gyms/1/wods/` 보다
/// **앞**에 와야 한다 (FakeApi 는 삽입 순서대로 prefix 매칭). memberWorld 가
/// 같은 키(my-history)를 갖고 있어 값이 덮이지 않도록 먼저 걷어낸다.
Map<String, dynamic> _detailWorld({
  required List<Map<String, dynamic>> feedback,
  required List<Map<String, dynamic>> results,
  required List<Map<String, dynamic>> comments,
  required Map<String, dynamic> history,
}) {
  final base = Map<String, dynamic>.from(memberWorld())
    ..remove('$_wodPath/my-history');
  return {
    '$_wodPath/feedback': feedback,
    '$_wodPath/results': results,
    '$_wodPath/comments': comments,
    '$_wodPath/my-history': history,
    ...base,
  };
}

/// 앞 상태의 State 를 확실히 버린다. `pumpWidget` 은 같은 타입의 트리를 만나면
/// **갱신**만 해서 State(=이미 나간 요청)를 그대로 물려준다 — 그러면 상태를
/// 바꿔 끼워도 화면은 첫 상태 그대로라 검사가 헛돈다 (2026-08-27 실측).
Future<void> _reset(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

/// 상세 화면 한 판. [api] 만 상태별로 갈아 끼운다 — 회원·체육관·수업 내용은 같다.
Future<void> _pumpDetail(WidgetTester tester, ApiClient api) async {
  await _reset(tester);
  _tall(tester);
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final gym = GymState(GymRepository(FakeApi(memberWorld())), sse: FakeSse());
  await gym.loadMine();
  final wod = gym.wods.firstWhere((w) => w.id == _wodId);
  await tester.pumpWidget(
    harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      gym: gym,
      home: WodDetailScreen(wod: wod),
    ),
  );
  await _settle(tester);
}

// 상태마다 **정말 그 상태인지** 한 줄로 못 박는다. 자리만 재고 내용을 안 보면
// "네 상태 모두 사실은 로딩" 같은 헛도는 통과가 생긴다 (2026-08-27 실제로 겪음).
const String _feedbackText = '2라운드부터 프론트랙이 무너집니다.';
const String _commentText = 'Thruster 중량 낮춰 완주했습니다.';
const String _feedbackEmpty = '아직 피드백 없음.';
const String _commentEmpty = '첫 댓글 작성.';

/// (a) 전부 로딩 중 — 네 구역 모두 아직 응답 없음 (스켈레톤).
Future<void> detailAllLoading(WidgetTester tester) async {
  await _pumpDetail(
    tester,
    FakeApi(
      _detailWorld(
        feedback: _feedbackOne(),
        results: _resultsOne(),
        comments: _commentsOne(),
        history: _historyOne(),
      ),
      hangPaths: {'$_wodPath/'},
    ),
  );
  expect(find.text(_feedbackText), findsNothing);
  expect(find.text(_feedbackEmpty), findsNothing);
  expect(find.text(_commentEmpty), findsNothing);
}

/// (b) 전부 도착 — 네 구역 모두 한 줄씩.
Future<void> detailAllArrived(WidgetTester tester) async {
  await _pumpDetail(
    tester,
    FakeApi(
      _detailWorld(
        feedback: _feedbackOne(),
        results: _resultsOne(),
        comments: _commentsOne(),
        history: _historyOne(),
      ),
    ),
  );
  expect(find.text(_feedbackText), findsOneWidget);
  expect(find.text(_commentText), findsOneWidget);
}

/// (c) 전부 비어 있음 — 도착했는데 내용이 없다 ('로딩 중'과 다른 사실이다).
Future<void> detailAllEmpty(WidgetTester tester) async {
  await _pumpDetail(
    tester,
    FakeApi(
      _detailWorld(
        feedback: const [],
        results: const [],
        comments: const [],
        history: const {'kind': 'time', 'items': <dynamic>[]},
      ),
    ),
  );
  expect(find.text(_feedbackEmpty), findsOneWidget);
  expect(find.text(_commentEmpty), findsOneWidget);
}

/// (d) 일부만 도착 — 피드백·내 이전 기록은 왔고 리더보드·댓글은 아직.
/// 실제 사용자가 가장 오래 보는 중간 화면이라 이 상태가 제일 중요하다.
Future<void> detailPartial(WidgetTester tester) async {
  await _pumpDetail(
    tester,
    FakeApi(
      _detailWorld(
        feedback: _feedbackOne(),
        results: _resultsOne(),
        comments: _commentsOne(),
        history: _historyOne(),
      ),
      hangPaths: {'$_wodPath/results', '$_wodPath/comments'},
    ),
  );
  expect(find.text(_feedbackText), findsOneWidget); // 왔다
  expect(find.text(_commentText), findsNothing); // 아직
  expect(find.text(_commentEmpty), findsNothing); // '없음' 으로 속이지 않는다
}

/// (e) 불러오기 실패 — 네 구역 모두 에러. 자리는 그대로, 문구만 실패로.
Future<void> detailAllError(WidgetTester tester) async {
  await _pumpDetail(
    tester,
    FakeApi(
      _detailWorld(
        feedback: const [],
        results: const [],
        comments: const [],
        history: const {'kind': 'time', 'items': <dynamic>[]},
      ),
      errorPaths: {'$_wodPath/'},
    ),
  );
  expect(find.text('피드백 불러오기 실패.'), findsOneWidget);
  expect(find.text('댓글 불러오기 실패.'), findsOneWidget);
}

// ── 수업 탭: 상단 실패 배너 ─────────────────────────────────────────────────

/// 배너만 다른 상태를 만들기 위한 대역 — 나머지(회원권·수업 내용·수업)는 같다.
/// 실패를 실제 통신으로 만들면 수업 내용까지 같이 비어 화면이 통째로 달라진다.
class _BannerGymState extends GymState {
  _BannerGymState(super.repo, {super.sse});

  @override
  String? get error => '정보를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

Future<void> _pumpWodTab(
  WidgetTester tester, {
  required ApiClient api,
  bool banner = false,
}) async {
  await _reset(tester);
  _tall(tester);
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final repo = GymRepository(FakeApi(memberWorld()));
  final gym = banner
      ? _BannerGymState(repo, sse: FakeSse())
      : GymState(repo, sse: FakeSse());
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
  await _settle(tester);
}

/// 수업 한 건만 있는 하루 — 예약 높이(WeekBoard.classSlotH)가 한 줄 기준이다.
List<Map<String, dynamic>> _oneClassToday() => [memberClasses().first];

Map<String, dynamic> _tabWorld(Object classes) => {
  '/api/v1/member/classes': classes,
  ...Map<String, dynamic>.from(memberWorld())
    ..remove('/api/v1/member/classes'),
};

const String _bannerText = '정보를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
const String _classEmpty = '등록된 수업 없음.';
const String _classError = '수업 불러오기 실패.';

Future<void> tabNoBanner(WidgetTester tester) async {
  await _pumpWodTab(tester, api: FakeApi(_tabWorld(_oneClassToday())));
  expect(find.text(_bannerText), findsNothing);
}

Future<void> tabBanner(WidgetTester tester) async {
  await _pumpWodTab(
    tester,
    api: FakeApi(_tabWorld(_oneClassToday())),
    banner: true,
  );
  expect(find.text(_bannerText), findsOneWidget);
}

// ── 주간 보드: 펼친 날의 '수업 시간' 구역 ────────────────────────────────────

/// v3.40 — 기본 진입이 '프로그램' 이 됐다. 아래 네 상태는 전부 **수업 시간 칸**의
/// 것이라 재기 전에 옮긴다. `pumpAndSettle` 을 쓰지 않는다 — 로딩 상태(hangPaths)
/// 에서는 영영 안 멎는다.
Future<void> _toSchedulePane(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(WeekBoard.kPaneSwitch),
      matching: find.text(WeekBoard.paneSchedule),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> dayClassesLoading(WidgetTester tester) async {
  await _pumpWodTab(
    tester,
    api: FakeApi(
      _tabWorld(_oneClassToday()),
      hangPaths: {'/api/v1/member/classes'},
    ),
  );
  await _toSchedulePane(tester);
  expect(find.text(_classEmpty), findsNothing); // 로딩을 '없음' 으로 속이지 않는다
  expect(find.byType(ClassLine), findsNothing);
}

Future<void> dayClassesArrived(WidgetTester tester) async {
  await _pumpWodTab(tester, api: FakeApi(_tabWorld(_oneClassToday())));
  await _toSchedulePane(tester);
  expect(find.byType(ClassLine), findsOneWidget);
}

Future<void> dayClassesEmpty(WidgetTester tester) async {
  await _pumpWodTab(tester, api: FakeApi(_tabWorld(const <dynamic>[])));
  await _toSchedulePane(tester);
  expect(find.text(_classEmpty), findsOneWidget);
}

Future<void> dayClassesError(WidgetTester tester) async {
  await _pumpWodTab(
    tester,
    api: FakeApi(
      _tabWorld(_oneClassToday()),
      errorPaths: {'/api/v1/member/classes'},
    ),
  );
  await _toSchedulePane(tester);
  expect(find.text(_classError), findsOneWidget);
}

// ── 두 칸: 수업 시간 ↔ 프로그램 (v3.37 · 2026-08-29) ────────────────────────
//
// 칸을 바꾸는 것은 **아래 내용만** 갈아 끼우는 일이다. 칸 전환 줄·주간 이동
// 줄·요일 줄은 두 칸에서 같은 자리에 있어야 손이 기억한 위치로 계속 갈 수 있다.
//
// 앵커는 '펼친 날까지' 다. 그 아래 요일 줄은 펼쳐진 내용의 높이만큼 밀리는데,
// 두 칸이 보여 주는 것이 애초에 다르므로(수업 두 줄 ↔ 프로그램 카드) 높이가
// 같을 수 없다 — 같게 만들려면 짧은 쪽에 빈 띠를 넣어야 하고, 그건 D69 에서
// 이미 틀린 처방으로 판정났다. 대신 **접힌 상태**를 따로 재서 일곱 줄 전부가
// 두 칸에서 같은 자리인지 확인한다 (아래 두 번째 검사).

Future<void> _pumpPane(WidgetTester tester, String pane) async {
  await _pumpWodTab(tester, api: FakeApi(_tabWorld(_oneClassToday())));
  // v3.40 — 기본 진입이 프로그램이 됐다. 이미 그 칸이면 눌러도 무해하므로
  // 어느 칸을 재든 항상 한 번 누른다 (기본값이 또 바뀌어도 안 깨진다).
  await tester.tap(
    find.descendant(
      of: find.byKey(WeekBoard.kPaneSwitch),
      matching: find.text(pane),
    ),
  );
  await _settle(tester);
}

Future<void> paneSchedule(WidgetTester tester) async {
  await _pumpPane(tester, WeekBoard.paneSchedule);
  expect(find.byType(ClassLine), findsOneWidget);
}

Future<void> paneProgram(WidgetTester tester) async {
  await _pumpPane(tester, WeekBoard.paneProgram);
  expect(find.byType(ClassLine), findsNothing);
}

/// 펼친 날(수요일)을 다시 눌러 접는다 — 일곱 줄만 남은 상태.
/// 요일 글자를 눌러야 한다 — 타일 전체를 누르면 펼쳐진 내용 한가운데를 눌러
/// 접히지 않는다 (2026-08-29 실측: 그래서 '접힘' 상태가 아니었다).
Future<void> _pumpPaneCollapsed(WidgetTester tester, String pane) async {
  await _pumpPane(tester, pane);
  await tester.tap(
    find.descendant(of: find.byKey(WeekBoard.dayKey(2)), matching: find.text('수')),
  );
  await _settle(tester);
}

Future<void> paneScheduleCollapsed(WidgetTester tester) =>
    _pumpPaneCollapsed(tester, WeekBoard.paneSchedule);

Future<void> paneProgramCollapsed(WidgetTester tester) =>
    _pumpPaneCollapsed(tester, WeekBoard.paneProgram);

void main() {
  testWidgets('수업 상세 — 네 구역이 어느 순서로 도착해도 앵커 y 가 같다', (tester) async {
    final table = await expectStableAnchorY(
      tester,
      states: {
        '전부 로딩': detailAllLoading,
        '전부 도착': detailAllArrived,
        '전부 비어 있음': detailAllEmpty,
        '일부만 도착': detailPartial,
        '전부 실패': detailAllError,
      },
      anchors: {
        '피드백라벨': WodDetailScreen.kFeedbackLabel,
        '리더보드라벨': WodDetailScreen.kLeaderboardLabel,
        '이전기록라벨': WodDetailScreen.kHistoryLabel,
        '댓글라벨': WodDetailScreen.kCommentsLabel,
        '댓글입력칸': WodDetailScreen.kCommentInput,
      },
    );
    // ignore: avoid_print — 표를 그대로 보고에 쓴다.
    print(formatAnchorTable(table));
    _writeTable('wod_detail', table);
  });

  testWidgets('수업 탭 — 상단 실패 배너가 떠도 주간 보드·체육관 정보가 안 밀린다', (tester) async {
    final table = await expectStableAnchorY(
      tester,
      states: {'배너 없음': tabNoBanner, '실패 배너': tabBanner},
      anchors: {
        '월요일줄': WeekBoard.dayKey(0),
        '일요일줄': WeekBoard.dayKey(6),
        '체육관정보': BoxWodScreen.kGymInfo,
      },
    );
    // ignore: avoid_print
    print(formatAnchorTable(table));
    _writeTable('wod_tab', table);
  });

  testWidgets('주간 보드 — 펼친 날의 수업이 로딩·도착·없음·실패여도 아래 요일이 안 밀린다', (
    tester,
  ) async {
    // 고정 시계(2026-08-12 수요일)라 펼쳐지는 날은 수요일(3번째 줄)이다 —
    // 그 아래 목·금·토·일 줄이 앵커다.
    final table = await expectStableAnchorY(
      tester,
      states: {
        '수업 로딩': dayClassesLoading,
        '수업 도착': dayClassesArrived,
        '수업 없음': dayClassesEmpty,
        '수업 실패': dayClassesError,
      },
      anchors: {
        '목요일줄': WeekBoard.dayKey(3),
        '일요일줄': WeekBoard.dayKey(6),
        '체육관정보': BoxWodScreen.kGymInfo,
      },
    );
    // ignore: avoid_print
    print(formatAnchorTable(table));
    _writeTable('week_board', table);
  });

  testWidgets('수업 탭 두 칸 — 칸을 바꿔도 칸 전환·주간 이동·펼친 날까지 안 밀린다', (
    tester,
  ) async {
    final table = await expectStableAnchorY(
      tester,
      states: {'수업 시간 칸': paneSchedule, '프로그램 칸': paneProgram},
      anchors: {
        '칸전환줄': WeekBoard.kPaneSwitch,
        '주간이동줄': WeekBoard.kWeekNav,
        '월요일줄': WeekBoard.dayKey(0),
        '화요일줄': WeekBoard.dayKey(1),
        '펼친날(수)': WeekBoard.dayKey(2),
      },
    );
    // ignore: avoid_print
    print(formatAnchorTable(table));
    _writeTable('week_panes', table);
  });

  testWidgets('수업 탭 두 칸 — 접으면 일곱 줄 전부가 두 칸에서 같은 자리다', (tester) async {
    final table = await expectStableAnchorY(
      tester,
      states: {
        '수업 시간 칸(접힘)': paneScheduleCollapsed,
        '프로그램 칸(접힘)': paneProgramCollapsed,
      },
      anchors: {
        '칸전환줄': WeekBoard.kPaneSwitch,
        '주간이동줄': WeekBoard.kWeekNav,
        for (var i = 0; i < 7; i++) '${i + 1}번째줄': WeekBoard.dayKey(i),
        '체육관정보': BoxWodScreen.kGymInfo,
      },
    );
    // ignore: avoid_print
    print(formatAnchorTable(table));
    _writeTable('week_panes_collapsed', table);
  });
}

/// 잰 값을 파일로 — 보고·확인용 (로그인 게이트와 같은 관례).
void _writeTable(String name, AnchorTable table) {
  final out = File('build/${name}_layout_anchors.json');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(table));
}
