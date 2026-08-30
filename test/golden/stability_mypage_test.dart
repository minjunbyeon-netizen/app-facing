import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/core/api_client.dart';
import 'package:hyphen_app/core/app_clock.dart';
import 'package:hyphen_app/core/notification_service.dart';
import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/mypage/mypage_screen.dart';

import 'fakes.dart';
import 'harness.dart';
import 'layout_stability.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

/// 레이아웃 안정성(layout stability) 회귀 게이트 — 내 정보 화면.
/// 정본 규칙 = `docs/DESIGN-SSOT.md §레이아웃 안정성 — 공간 예약`.
///
/// 이 화면은 서버 응답 네 갈래(체육관·회원권·락커·포인트)가 제각각 도착한다.
/// 전엔 그 하나하나가 `SizedBox.shrink()` → 실물로 바뀌며 아래를 밀어 올렸다:
/// 포인트 카드가 통째로 생기고, 회원권 섹션이 없다가 나타나고, 코치가 PC 에서
/// 상태를 바꾸면 SSE 로 카드 안 배너가 실시간으로 토글됐다.
///
/// 여기서는 그 결과를 **픽셀이 아니라 좌표로** 검증한다 — 어느 앵커가 어느
/// 상태에서 몇 px 밀렸는지 바로 나온다.
///
/// 실패하면 공간 예약이 풀린 것이다: 조건부 블록(`if (x) ...[]`)이 되살아났는지,
/// 고정 높이 슬롯의 높이가 내용에 따라 변하는지부터 본다.

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 세로로 긴 화면 — 내 정보는 한 화면보다 길다. ListView 가 아래 항목까지
/// 실제로 배치하게 만들어 앵커 y 를 재는 용도 (골든이 아니므로 크기 자유).
void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(720, 4000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// 무한 애니메이션(스피너)이 있어도 안전한 정착 — pumpAndSettle 금지.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required ApiClient api,
  required GymState gym,
}) async {
  _tallPhone(tester);
  // 상태를 갈아 끼울 때마다 트리를 완전히 새로 짓는다. 같은 타입으로 다시
  // pumpWidget 하면 element 가 재사용돼 아코디언 펼침 상태가 앞 상태에서
  // 넘어온다 (다음 상태의 탭이 도로 접어 버린다).
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  SharedPreferences.setMockInitialValues(signedInPrefs());
  await tester.pumpWidget(
    harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      gym: gym,
      home: const MyPageScreen(embedded: true),
    ),
  );
  await _settle(tester);
}

/// 회원권 목록만 갈아 끼운 세계. [points] 를 주면 포인트 응답까지 바꾼다.
Map<String, dynamic> _world(List<dynamic> memberships, {int? points}) => {
  ...memberWorld(),
  '/api/v1/member/me/memberships': memberships,
  if (points != null)
    '/api/v1/member/points': {'balance': points, 'history': const <dynamic>[]},
};

/// 기간제 활성 1건 — 정지 창을 붙이면 '일시정지 중' 배너가 같이 뜬다.
List<Map<String, dynamic>> _memberships({
  String status = 'active',
  bool paused = false,
  bool expiredDates = false,
}) {
  final now = appClock.now();
  return [
    {
      'id': 1,
      'gym_id': 1,
      'member_id': 7,
      'plan_name': '3개월 무제한',
      'start_date': _ymd(
        now.subtract(Duration(days: expiredDates ? 100 : 56)),
      ),
      'end_date': _ymd(
        expiredDates
            ? now.subtract(const Duration(days: 10))
            : now.add(const Duration(days: 34)),
      ),
      'price': 330000,
      'status': status,
      if (paused) 'pause_start': _ymd(now.subtract(const Duration(days: 2))),
      if (paused) 'pause_end': _ymd(now.add(const Duration(days: 5))),
      ...fakeMembershipCalendar(
        start: _ymd(now.subtract(Duration(days: expiredDates ? 100 : 56))),
        end: _ymd(expiredDates
            ? now.subtract(const Duration(days: 10))
            : now.add(const Duration(days: 34))),
        pauseStart: paused ? _ymd(now.subtract(const Duration(days: 2))) : null,
        pauseEnd: paused ? _ymd(now.add(const Duration(days: 5))) : null,
        active: status == 'active',
      ),
    },
  ];
}

// ── 1) 화면 전체 — 응답이 도착해도 아래 요소가 제자리 ────────────────────────

/// (a) 전부 로딩 중 — 어떤 응답도 아직 안 왔다.
Future<void> mypageAllLoading(WidgetTester tester) async {
  final api = FakeApi(memberWorld(), hang: true);
  final gym = GymState(GymRepository(api), sse: FakeSse());
  unawaited(gym.loadMine()); // 영원히 대기 → isLoading = true
  await _pump(tester, api: api, gym: gym);
}

/// (b) 회원권 있음 · 포인트 있음 — 정상 상태.
Future<void> mypageLoaded(WidgetTester tester) async {
  final api = FakeApi(_world(_memberships(), points: 1240));
  final gym = GymState(GymRepository(api), sse: FakeSse());
  await gym.loadMine();
  await _pump(tester, api: api, gym: gym);
}

/// (c) 회원권 없음 — 로딩이 끝났는데 정말 한 장도 없다.
Future<void> mypageNoMembership(WidgetTester tester) async {
  final api = FakeApi(_world(const <dynamic>[], points: 0));
  final gym = GymState(GymRepository(api), sse: FakeSse());
  await gym.loadMine();
  await _pump(tester, api: api, gym: gym);
}

/// (d) 일시정지 — 카드 안 배너가 떠 있는 상태.
Future<void> mypagePaused(WidgetTester tester) async {
  final api = FakeApi(_world(_memberships(paused: true), points: 1240));
  final gym = GymState(GymRepository(api), sse: FakeSse());
  await gym.loadMine();
  await _pump(tester, api: api, gym: gym);
}

/// (e~g) '알림 받기' 세 상태 — 켜짐·꺼짐·폰 설정에서 차단됨 (2026-08-28).
///
/// 이 행은 자리를 비워 두는 방식(HkNoticeSlot)을 쓰지 않는다. 부제를 항상 한 줄
/// 두고 글자만 바꾸므로 세 상태의 행 높이가 같아야 한다 — 그 증명이 여기다.
/// 차단 상태는 실기에서만 나오므로 알림 창구를 대역으로 갈아 끼워 만든다.
Future<void> _pumpNotifications(
  WidgetTester tester, {
  required bool enabled,
  required bool granted,
}) async {
  final sink = FakeNotificationSink(granted: granted);
  NotificationService.instance.debugUseSink(sink);
  addTearDown(NotificationService.instance.debugReset);
  // 스위치 값은 서비스가 메모리에 들고 있다 — _pump 안의
  // setMockInitialValues 가 저장소를 다시 깔아도 이 값이 유지된다.
  await NotificationService.instance.setEnabled(enabled);
  final api = FakeApi(_world(_memberships(), points: 1240));
  final gym = GymState(GymRepository(api), sse: FakeSse());
  await gym.loadMine();
  await _pump(tester, api: api, gym: gym);
}

Map<String, ScreenState> mypageStates() => {
  '전부 로딩 중': mypageAllLoading,
  '회원권·포인트 있음': mypageLoaded,
  '회원권 없음': mypageNoMembership,
  '일시정지': mypagePaused,
  '알림 켜짐': (t) => _pumpNotifications(t, enabled: true, granted: true),
  '알림 꺼짐': (t) => _pumpNotifications(t, enabled: false, granted: true),
  '알림 차단됨': (t) => _pumpNotifications(t, enabled: true, granted: false),
};

Map<String, Key> mypageAnchors() => {
  '회원권섹션': MyPageScreen.kMembership,
  '로그아웃': MyPageScreen.kSignOut,
  '포인트': MyPageScreen.kPoints,
  '알림': MyPageScreen.kNotifications,
  '메뉴': MyPageScreen.kMenu,
};

// ── 2) 회원권 카드 안 — 배너 3종이 한 자리를 나눠 쓴다 ───────────────────────

/// 회원권 아코디언을 펼친 뒤 정착. 카드 안 앵커를 재려면 펼쳐야 한다.
Future<void> _pumpExpanded(
  WidgetTester tester,
  List<Map<String, dynamic>> memberships,
) async {
  final api = FakeApi(_world(memberships, points: 1240));
  final gym = GymState(GymRepository(api), sse: FakeSse());
  await gym.loadMine();
  await _pump(tester, api: api, gym: gym);
  await tester.tap(find.text('회원권').first);
  await _settle(tester);
  await _settle(tester);
}

Map<String, ScreenState> membershipCardStates() => {
  '배너 없음': (t) => _pumpExpanded(t, _memberships()),
  '만료 안내': (t) =>
      _pumpExpanded(t, _memberships(status: 'expired', expiredDates: true)),
  '횟수권 면제': (t) => _pumpExpanded(t, memberMembershipsSessionPass()),
  '일시정지': (t) => _pumpExpanded(t, _memberships(paused: true)),
  '만료+일시정지': (t) => _pumpExpanded(
    t,
    _memberships(status: 'expired', expiredDates: true, paused: true),
  ),
};

Map<String, Key> membershipCardAnchors() => {
  '진행막대': MyPageScreen.kMembershipProgress,
  '시작종료일': MyPageScreen.kMembershipDates,
};

void main() {
  testWidgets('내 정보 — 7 상태에서 앵커 y 좌표가 전부 같다', (tester) async {
    final table = await expectStableAnchorY(
      tester,
      states: mypageStates(),
      anchors: mypageAnchors(),
    );
    // ignore: avoid_print — 표를 그대로 보고용으로 쓴다.
    print(formatAnchorTable(table));
  });

  testWidgets('내 정보 회원권 카드 — 배너 5 조합에서 카드 안이 안 밀린다', (tester) async {
    final table = await expectStableAnchorY(
      tester,
      states: membershipCardStates(),
      anchors: membershipCardAnchors(),
    );
    // ignore: avoid_print
    print(formatAnchorTable(table));
  });

  testWidgets('상태 슬롯 — 배너 두 개가 동시에 뜨는 조합이 실재한다', (tester) async {
    // 슬롯 높이를 두 줄로 잡은 근거. (1)비활성·(2)면제는 배타적이지만
    // (3)일시정지는 status 를 안 보므로 (1)+(3) 이 같이 뜬다.
    await _pumpExpanded(
      tester,
      _memberships(status: 'expired', expiredDates: true, paused: true),
    );
    expect(find.textContaining('예약에 쓸 수 없습니다'), findsOneWidget);
    expect(find.text('일시정지 중'), findsOneWidget);
  });
}
