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
}) async {
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
          : FakeBossApi(responses),
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

Future<void> _pumpInbox(
  WidgetTester tester, {
  required bool withAnnouncements,
  bool holdingThreads = false,
}) async {
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final world = {
    ...memberWorld(),
    if (withAnnouncements) '/api/v1/member/announcements': memberAnnouncements(),
  };
  // ignore: avoid_print
  print('PROBE world=' +
      (world['/api/v1/member/announcements'] as List).length.toString() +
      ' keys=' +
      world.keys.where((k) => '/api/v1/member/announcements'.startsWith(k)).join(','));
  final api = FakeApi(
    world,
    hangPaths: holdingThreads ? const {'/api/v1/gym/1/threads'} : const {},
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
  final ann = ctx.read<AnnouncementsState>();
  await ann.refresh(ctx.read<GymRepository>());
  try {
    final raw = await ctx.read<GymRepository>().listMemberAnnouncements();
    final direct = await api.getList('/api/v1/member/announcements');
    // ignore: avoid_print
    print('PROBE raw=' + raw.length.toString() +
        ' direct=' + direct.length.toString() +
        ' t=' + (direct.isEmpty ? '-' : direct.first.runtimeType.toString()));
  } catch (e) {
    // ignore: avoid_print
    print('PROBE err=' + e.toString());
  }
  // ignore: avoid_print
  print('PROBE items=' + ann.items.length.toString());
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
        '로딩 중': (t) => _pumpWeek(t, classes: const [], holding: true),
        '명단 도착': (t) => _pumpWeek(t, classes: _wedOneClass()),
        '빈 명단': (t) => _pumpWeek(t, classes: const []),
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
        },
        '마지막 요일 펼침': (t) async {
          await _pumpWeek(t, classes: _wedOneClass());
          await _tapDay(t, _todayIndex);
          await _tapDay(t, 6);
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
  testWidgets('쪽지함 — 로딩·공지 없음·공지 있음에서 대화 목록 y 가 같다', (tester) async {
    phone(tester);
    final table = await expectStableAnchorY(
      tester,
      states: {
        '로딩 중': (t) =>
            _pumpInbox(t, withAnnouncements: false, holdingThreads: true),
        '공지 없음': (t) => _pumpInbox(t, withAnnouncements: false),
        '공지 있음': (t) => _pumpInbox(t, withAnnouncements: true),
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
        '수락 대기': (t) => _pumpNote(t, 'read'),
        '수락함': (t) => _pumpNote(t, 'accepted'),
        '완료': (t) => _pumpNote(t, 'completed'),
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
