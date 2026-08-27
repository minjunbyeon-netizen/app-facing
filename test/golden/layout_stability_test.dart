import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';
import 'layout_stability.dart';
import 'login_states.dart';

/// 레이아웃 안정성(layout stability) 회귀 게이트 — DESIGN-SSOT §레이아웃 안정성.
///
/// 로그인 화면은 어떤 상태에서도 요소가 위아래로 밀리지 않는다 (2026-08-27 사용자
/// 지시 "아이디 입력칸 비밀번호 입력칸은 고정 같은 자리"). 이 테스트가 실패하면
/// 곧 밀림이 생겼다는 뜻이다 — 조건부 상단바·조건부 블록·검증 에러 줄·로딩 교체
/// 넷 중 하나가 되살아났는지부터 본다.
void main() {
  testWidgets('로그인 — 6 상태에서 앵커 y 좌표가 전부 같다', (tester) async {
    phone(tester);
    final table = await expectStableAnchorY(
      tester,
      states: loginStates(),
      anchors: loginAnchors(),
    );
    // ignore: avoid_print — 표를 그대로 보고·확인용 HTML 에 쓴다.
    print(formatAnchorTable(table));
    final out = File('build/login_layout_anchors.json');
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(table),
    );
  });
}
