import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/announcements/announcements_state.dart';
import 'package:hyphen_app/features/auth/auth_state.dart';
import 'package:hyphen_app/features/boss/coach_week_classes.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/inbox/inbox_screen.dart';
import 'package:hyphen_app/features/inbox/note_detail_screen.dart';
import 'package:hyphen_app/features/profile/profile_state.dart';
import 'package:hyphen_app/widgets/hkit.dart';

import 'fakes.dart';
import 'harness.dart';
import 'layout_stability.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

/// 레이아웃 안정성(layout stability) 회귀 게이트 — 코치 주간 예약 · 쪽지함 공지 ·
/// 쪽지 상세 액션. 규격 정본 = docs/DESIGN-SSOT.md §레이아웃 안정성.
///
/// 세 자리 모두 **상태에 따라 높이가 갈리던 곳**이다. 이제 변하는 것은 미리 잡아
/// 둔 자리(공간 예약 / space reservation) 안에서만 바뀐다. 이 테스트가 실패하면
/// 그 자리 중 하나가 다시 "있다 없다" 하게 됐다는 뜻이다.
///
/// 골든 PNG 는 "달라졌다" 까지만 말하지만, 여기서는 **어느 앵커가 몇 px 밀렸는지**
/// 를 바로 짚는다.

/// 상태마다 **트리를 새로 세운다**. 같은 위젯 구조를 다시 pump 하면 Flutter 가
/// element 를 재사용해 `Provider(create:)` 값과 화면 State 가 앞 상태 것 그대로
/// 남는다 (가짜 API 를 바꿔도 앞 상태 응답을 계속 본다 — 상태별 검사가 통째로
/// 헛돌게 되는 함정).
Future<void> _reset(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

/// 무한 애니메이션(스피너)이 있어도 안전한 정착 — pumpAndSettle 금지.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

// ── 코치 주간 예약 ──────────────────────────────────────────────────────────

/// 응답을 영원히 붙잡아 두는 문 — '로딩 중' 을 고정한다.
/// (FakeBossApi 의 hold 는 get 계열에만 걸려 주간 목록에는 닿지 않는다.)
class _HoldingBossApi extends FakeBossApi {
  _HoldingBossApi(super.responses, {required this.gate});

  final Future<void> gate;

  @override
  Future<List<dynamic>> getList(String path) async {
    await gate;
    return super.getList(path);
  }
}

final Completer<void> _weekHold = Completer<void>();

/// 고정 시계는 2026-08-12 수요일 — 기본 선택(오늘)은 수요일(i=2)이다.
const int _todayIndex = 2;

/// 수요일 수업 1건. 명단이 도착해도 아래 요일 행이 밀리면 안 된다.
List<Map<String, dynamic>> _wedOneClass() => [
  {
    'id': 901,
    'gym_id': 1,
    'start_at': '2026-08-12T19:00:00',
    'duration_minutes': 60,
    'title': '저녁 수업',
    'room': 'A홀',
    'capacity': 16,
    'waitlist_capacity': 4,
    'reserved_count': 8,
    'waitlist_count': 0,
    'status': 'open',
  },
];

Future<void> _pumpWeek(
  WidgetTester tester, {
  required List<Map<String, dynamic>> classes,
  bool holding = false,
  bool failing = false,
}) async {
  await _reset(tester);
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  final responses = {'/api/v1/admin/gyms/1/classes': classes};
  await tester.pumpWidget(
    harness(
      api: FakeApi(memberWorld()),
      auth: AuthState(),
      profile: ProfileState(),
      bossAuth: FakeBossAuth(),
      bossApi: holding
          ? _HoldingBossApi(responses, gate: _weekHold.future)
          : FakeBossApi(
              responses,
              errorPaths: failing
                  ? const {'/api/v1/admin/gyms/1/classes'}
                  : const {},
            ),
      home: const Scaffold(
        body: SingleChildScrollView(child: CoachWeekClasses(gymId: 1)),
      ),
    ),
  );
  await _settle(tester);
}

/// 요일 행을 눌러 접거나 편다.
Future<void> _tapDay(WidgetTester tester, int i) async {
  await tester.tap(find.byKey(CoachWeekClasses.dayHeader(i)));
  await _settle(tester);
}

// ── 쪽지함 ─────────────────────────────────────────────────────────────────

/// 가장 긴 공지 — 제목 1줄(잘림) + 본문 2줄(잘림). 예약한 자리가 이보다
/// 작으면 공지가 도착하는 순간 대화 목록이 밀린다.
List<Map<String, dynamic>> _longAnnouncements() => [
  {
    'id': 9,
    'title': '설 연휴 운영 시간 변경 및 수업 일정 조정 안내 (지점 공통 적용)',
    'body':
        '설 연휴 기간 오전 수업은 전 지점 휴강하고 저녁 수업만 운영합니다. '
        '연휴 직후 첫 주는 예약이 몰리니 미리 잡아 두시고, 회원권 만료일이 '
        '연휴에 걸린 경우 데스크로 문의해 주십시오.',
    'priority': 'urgent',
    'pinned': true,
    'category': 'notice',
    'visible_to': 'all',
    'created_at': '2026-08-10T09:00:00',
  },
  {
    'id': 10,
    'title': '저녁 수업 신설',
    'body': '저녁 8시 수업 추가.',
    'priority': 'normal',
    'pinned': false,
    'category': 'notice',
    'visible_to': 'all',
    'created_at': '2026-08-11T09:00:00',
  },
];

Future<void> _pumpInbox(
  WidgetTester tester, {
  required bool withAnnouncements,
  bool holdingThreads = false,
  bool longAnnouncement = false,
  bool failingThreads = false,
}) async {
  await _reset(tester);
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final world = {
    ...memberWorld(),
    if (withAnnouncements)
      '/api/v1/member/announcements':
          longAnnouncement ? _longAnnouncements() : memberAnnouncements(),
  };
  final api = FakeApi(
    world,
    hangPaths: holdingThreads ? const {'/api/v1/gym/1/threads'} : const {},
    errorPaths: failingThreads ? const {'/api/v1/gym/1/threads'} : const {},
  );
  final gym = GymState(GymRepository(api), sse: FakeSse());
  await gym.loadMine();
  await tester.pumpWidget(
    harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      gym: gym,
      home: const MessagingScreen(),
    ),
  );
  await _settle(tester);
  // 공지는 셸·SSE 가 뒤늦게 채워 넣는 값이다 — 실제 경로 그대로 불러온다.
  final ctx = tester.element(find.byType(MessagingFeed));
  await ctx.read<AnnouncementsState>().refresh(ctx.read<GymRepository>());
  await _settle(tester);
}

// ── 쪽지 상세 ──────────────────────────────────────────────────────────────

Map<String, dynamic> _assignmentNote(String status) => {
  'id': 5,
  'gym_id': 1,
  'sender_hash': 'c0ffee12c0ffee12',
  'sender_short': 'c0ffee12',
  'sender_name': '박준서',
  'target_type': 'group',
  'target_id': 'g1',
  'kind': 'assignment',
  'title': '스쿼트 보강',
  'body': '수업 전 20분 보강 진행.',
  'structured': const <dynamic>[],
  'due_date': '2026-08-14',
  'created_at': '2026-08-12T09:00:00',
  'my': {'status': status, 'actual': const <dynamic>[]},
  'recipients': const [
    {'hash': 'a1b2c3d4', 'name': '김민준', 'status': 'read'},
    {'hash': 'b2c3d4e5', 'name': '이서연', 'status': 'accepted'},
    {'hash': 'c3d4e5f6', 'name': '최지우', 'status': 'completed'},
  ],
};

Future<void> _pumpNote(WidgetTester tester, String status) async {
  await _reset(tester);
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final api = FakeApi({
    '/api/v1/gym/notes/5': _assignmentNote(status),
    ...memberWorld(),
  });
  await tester.pumpWidget(
    harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      home: const NoteDetailScreen(noteId: 5),
    ),
  );
  await _settle(tester);
}

void main() {
  // ── 1. 코치 주간 예약 — 로딩이 명단으로 바뀌어도 요일 행이 그대로 ──────────
  //
  // 기본 선택이 '오늘' 이라 코치는 화면에 들어가는 순간 이 전환을 매일 겪는다.
  // 펼침 자리를 예약해 로딩 스피너·수업 한 줄·'등록된 수업 없음' 이 같은 높이다.
  testWidgets('코치 주간 예약 — 로딩·명단·빈 명단에서 요일 행 y 가 같다', (tester) async {
    phone(tester);
    final table = await expectStableAnchorY(
      tester,
      states: {
        // 상태마다 '정말 그 상태인지' 를 먼저 못 박는다 — 트리 재사용으로
        // 앞 상태가 그대로 남으면 y 검사가 통째로 헛돈다.
        '로딩 중': (t) async {
          await _pumpWeek(t, classes: const [], holding: true);
          expect(find.byType(HkLoading), findsOneWidget);
        },
        '명단 도착': (t) async {
          await _pumpWeek(t, classes: _wedOneClass());
          expect(find.text('저녁 수업'), findsOneWidget);
        },
        '빈 명단': (t) async {
          await _pumpWeek(t, classes: const []);
          expect(find.text('등록된 수업 없음.'), findsOneWidget);
        },
        // D117 — 실패 상태가 검사 밖이었다. 종전에는 카드 7행을 배너로 통째
        // 치환해서 요일 행 앵커가 **사라졌고**, 그래서 이 검사를 걸 수조차 없었다.
        '불러오기 실패': (t) async {
          await _pumpWeek(t, classes: const [], failing: true);
          expect(find.text('수업 불러오기 실패.'), findsOneWidget);
        },
      },
      anchors: {
        '주간헤더': CoachWeekClasses.kWeekHeader,
        '오늘행': CoachWeekClasses.dayRow(_todayIndex),
        '금요일행': CoachWeekClasses.dayRow(4),
        '일요일행': CoachWeekClasses.dayRow(6),
      },
    );
    // ignore: avoid_print — 표를 그대로 보고용으로 남긴다.
    print(formatAnchorTable(table));
  });

  // ── 2. 코치 주간 예약 — 펼쳐도 위쪽이 안 밀린다 ────────────────────────────
  //
  // 마지막 요일을 펼쳐 잰다: 아코디언은 **누른 줄 아래**를 밀어 내리는 것이
  // 제 일이므로(사용자가 스스로 연 것), 그 위 7줄과 헤더가 그대로인지를 본다.
  testWidgets('코치 주간 예약 — 접힘·펼침에서 요일 행 y 가 같다', (tester) async {
    phone(tester);
    final table = await expectStableAnchorY(
      tester,
      states: {
        '전부 접힘': (t) async {
          await _pumpWeek(t, classes: _wedOneClass());
          await _tapDay(t, _todayIndex); // 오늘(기본 펼침) 을 접는다
          expect(find.text('저녁 수업'), findsNothing);
        },
        '마지막 요일 펼침': (t) async {
          await _pumpWeek(t, classes: _wedOneClass());
          await _tapDay(t, _todayIndex);
          await _tapDay(t, 6);
          expect(find.text('등록된 수업 없음.'), findsOneWidget);
        },
      },
      anchors: {
        '주간헤더': CoachWeekClasses.kWeekHeader,
        for (var i = 0; i < 7; i++) '요일$i': CoachWeekClasses.dayRow(i),
      },
    );
    // ignore: avoid_print
    print(formatAnchorTable(table));
  });

  // ── 3. 쪽지함 — 공지가 생겨도 대화 목록이 제자리 ───────────────────────────
  //
  // 공지는 최초 로딩 완료·SSE 신규 도착으로 **뒤늦게** 들어온다. 자리를 미리
  // 잡아 두지 않으면 그때마다 대화 목록 전체가 아래로 밀린다.
  // D117 — 목록 **안쪽**은 검사 밖이었다. 앵커는 목록의 시작 y 만 재는데,
  // 목록이 마지막 요소라 안이 132 였다 59 가 돼도 위쪽 앵커는 그대로다.
  // 그래도 화면 높이가 바뀌므로 아래에 무엇이든 붙는 순간 밀린다 —
  // 로딩·빈·에러가 갈아 끼워지는 자리는 **높이**로 잰다.
  testWidgets('쪽지함 — 대화 목록 자리는 로딩·빈·에러에서 같은 높이', (tester) async {
    phone(tester);
    await expectStableHeight(
      tester,
      states: {
        '로딩 중': (t) async {
          await _pumpInbox(t, withAnnouncements: false, holdingThreads: true);
          expect(find.byType(HkLoading), findsOneWidget);
        },
        '빈 목록': (t) async {
          await _pumpInbox(t, withAnnouncements: false);
          expect(find.text('코치 쪽지 도착 시 표시.'), findsOneWidget);
        },
        '불러오기 실패': (t) async {
          await _pumpInbox(t, withAnnouncements: false, failingThreads: true);
          expect(find.text('다시 시도'), findsOneWidget);
        },
      },
      targets: {'대화목록 자리': MessagingFeed.kThreadList},
    );
  });

  testWidgets('쪽지함 — 로딩·공지 없음·공지 있음에서 대화 목록 y 가 같다', (tester) async {
    phone(tester);
    final table = await expectStableAnchorY(
      tester,
      states: {
        '로딩 중': (t) async {
          await _pumpInbox(t, withAnnouncements: false, holdingThreads: true);
          expect(find.byType(HkLoading), findsOneWidget);
        },
        '공지 없음': (t) async {
          await _pumpInbox(t, withAnnouncements: false);
          expect(find.text('등록된 공지 없음.'), findsOneWidget);
        },
        '공지 있음': (t) async {
          await _pumpInbox(t, withAnnouncements: true);
          expect(find.text('휴관 안내'), findsOneWidget);
        },
        '공지 긴 본문': (t) async {
          await _pumpInbox(t, withAnnouncements: true, longAnnouncement: true);
          expect(find.text('+1'), findsOneWidget);
        },
      },
      anchors: {
        '공지자리': MessagingFeed.kAnnouncementSlot,
        '대화목록': MessagingFeed.kThreadList,
      },
    );
    // 자리는 예약된 높이 그대로여야 한다 — 공지가 넘치면 아래를 밀어낸다.
    expect(
      tester.getSize(find.byKey(MessagingFeed.kAnnouncementSlot)).height,
      MessagingFeed.announcementSlotH,
      reason: '공지 카드가 예약된 자리를 넘쳤습니다 — announcementSlotH 를 올리십시오.',
    );
    // ignore: avoid_print
    print(formatAnchorTable(table));
  });

  // ── 4. 쪽지 상세 — 수락·완료로 버튼이 상태 박스가 돼도 수신자 목록이 제자리 ──
  testWidgets('쪽지 상세 — 대기·수락·완료에서 수신자 목록 y 가 같다', (tester) async {
    phone(tester);
    final table = await expectStableAnchorY(
      tester,
      states: {
        '수락 대기': (t) async {
          await _pumpNote(t, 'read');
          expect(find.text('수락'), findsOneWidget);
        },
        '수락함': (t) async {
          await _pumpNote(t, 'accepted');
          expect(find.text('완료'), findsOneWidget);
        },
        '완료': (t) async {
          await _pumpNote(t, 'completed');
          expect(find.text('Completed.'), findsOneWidget);
        },
      },
      anchors: {
        '액션자리': NoteDetailScreen.kActions,
        '수신자목록': NoteDetailScreen.kRecipients,
      },
    );
    // ignore: avoid_print
    print(formatAnchorTable(table));
  });
}
