// 쪽지 대화 화면 레이아웃 안정성 — 하단 입력바가 '전송 중' 으로 바뀌어도 안 밀린다.
//
// D118 (2026-09-05) — `docs/UI-INDEX.md §4` 밀림 후보 10번(채팅 전송 아이콘)은
// **미확인**으로 남아 있었다. 입력칸 안이라 제약(constraints)을 받아 안 밀릴
// 가능성이 있어 "고치기 전에 실측" 이 먼저였다. 이 파일이 그 실측이자 회귀 게이트다.
//
// 왜 이 자리가 위험한가: 입력바는 `Column` 의 마지막 칸이고 그 위가 `Expanded`
// (대화 목록)다. 바가 1px 두꺼워지면 목록이 그만큼 깎이고, 바 자신의 y 도 위로
// 올라간다. 보내기를 누르는 순간 손가락 아래에서 칸이 움직이는 셈이다.
//
// 정본 규칙 = docs/DESIGN-SSOT.md §레이아웃 안정성 · 헬퍼 = layout_stability.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/gym/gym_repository.dart';
import 'package:hyphen_app/features/gym/gym_state.dart';
import 'package:hyphen_app/features/inbox/inbox_screen.dart';
import 'package:hyphen_app/widgets/hkit.dart';

import 'fakes.dart';
import 'harness.dart';
import 'layout_stability.dart';
import 'screens_golden_test.dart' show rxProfile, signedInAuth, signedInPrefs;

const String _peerHash = 'c0ffee12c0ffee12';
const String _sendPath = '/api/v1/gym/1/member-report';

/// 앞 상태의 State 를 확실히 버린다 — 같은 트리를 다시 pump 하면 Flutter 가
/// element 를 재사용해 `_sending` 이 앞 상태 그대로 남는다.
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

/// 대화 화면 한 판. [holdSend] 면 보내기 요청이 영원히 안 끝나 '전송 중' 이 고정된다.
Future<void> _pumpChat(WidgetTester tester, {bool holdSend = false}) async {
  await _reset(tester);
  phone(tester);
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final api = FakeApi(
    memberWorld(),
    hangPaths: holdSend ? const {_sendPath} : const {},
  );
  final gym = GymState(GymRepository(FakeApi(memberWorld())), sse: FakeSse());
  await gym.loadMine();
  await tester.pumpWidget(
    harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      gym: gym,
      home: const ChatThreadScreen(
        gymId: 1,
        peerHash: _peerHash,
        peerName: '박준서',
      ),
    ),
  );
  await _settle(tester);
}

/// 글자를 적어 넣는다 — 빈 칸이면 `_send` 가 곧장 돌아와 '전송 중' 이 안 생긴다.
Future<void> _type(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), '어깨가 아파 대체 동작 문의드립니다.');
  await _settle(tester);
}

void main() {
  // ── 후보 10 — 채팅 전송 아이콘 (실측 결과: 밀렸다) ──────────────────────────
  //
  // "입력칸 안이라 제약을 받아 안 밀릴 것" 이라는 짐작은 **틀렸다**. 재 보니
  // 입력바가 65 → 129 (+64px) 로 부풀고 그 y 가 715 → 651 로 올라갔다.
  // 범인은 아이콘 세로 크기가 아니라 **가로**였다: 스피너를 그리던 `HkLoading()`
  // 은 [Center] 라 suffixIcon 자리에서 남는 가로폭을 전부 먹었고(48 → 336),
  // 글자 칸이 0 으로 눌리며 한 줄이 네 줄(maxLines: 4)로 접혔다. 입력바는
  // Column 의 마지막 칸이라 그만큼 위 대화 목록이 깎였다.
  //
  // 고친 방법 = 버튼 자리 그대로 안에서 스피너만 (`HkButton(busy:)` 와 같은 결).
  testWidgets('채팅 입력바 — 전송 중에도 바의 y 가 같다', (tester) async {
    final anchors = await expectStableAnchorY(
      tester,
      states: {
        '대기': (t) async {
          await _pumpChat(t);
          await _type(t);
          expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
        },
        '전송 중': (t) async {
          await _pumpChat(t, holdSend: true);
          await _type(t);
          await t.tap(find.byIcon(Icons.arrow_upward));
          await _settle(t);
          // 정말 '전송 중' 인지 못 박는다 — 아니면 두 상태가 사실 같은 그림이다.
          expect(find.byType(HkLoading), findsOneWidget);
          expect(find.byIcon(Icons.arrow_upward), findsNothing);
        },
      },
      anchors: {'입력바': ChatThreadScreen.kInputBar},
    );
    // ignore: avoid_print — 실측 수치를 보고용으로 남긴다.
    print(formatAnchorTable(anchors));
  });

  testWidgets('채팅 입력바 — 전송 아이콘 자리와 바 높이가 상태를 안 탄다', (tester) async {
    final table = await expectStableHeight(
      tester,
      states: {
        '대기': (t) async {
          await _pumpChat(t);
          await _type(t);
          expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
        },
        '전송 중': (t) async {
          await _pumpChat(t, holdSend: true);
          await _type(t);
          await t.tap(find.byIcon(Icons.arrow_upward));
          await _settle(t);
          expect(find.byType(HkLoading), findsOneWidget);
        },
      },
      targets: {
        '입력바': ChatThreadScreen.kInputBar,
        '전송 자리': ChatThreadScreen.kSendSlot,
      },
    );
    // ignore: avoid_print
    print(formatAnchorTable(table));
  });
}
