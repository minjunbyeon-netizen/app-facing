// 수업 상세 '코치에게 요청' 시트 레이아웃 안정성 — 실패 문구가 떠도 안 밀린다.
//
// D118 (2026-09-05) — `docs/UI-INDEX.md §11` 의 남은 밀림 후보 4번.
// 시트가 `stability_wod_test` 의 앵커 밖이라(모달은 화면이 아니다) 미검사로
// 남아 있었다. 시트를 여는 절차를 `wod_request_sheet.dart` 한 곳에 뽑아 두고,
// 그 위에서 좌표를 잰다.
//
// 왜 이 자리가 위험한가: 바텀시트는 **아래에 붙어 위로 자란다**. 보내기 버튼
// 위에 조건부 블록이 생기면 버튼은 아래로, 그 위 입력칸·제목은 위로 — 시트
// 안의 모든 것이 한꺼번에 움직인다. 실패 직후가 다시 누르기 가장 쉬운 순간인데
// 손가락 아래에서 버튼이 도망간다.
//
// 정본 규칙 = docs/DESIGN-SSOT.md §레이아웃 안정성 · 헬퍼 = layout_stability.dart.

import 'package:flutter_test/flutter_test.dart';

import 'package:hyphen_app/features/gym/wod_detail_screen.dart';

import 'layout_stability.dart';
import 'wod_request_sheet.dart';

void main() {
  testWidgets('코치에게 요청 시트 — 실패 문구가 떠도 시트 안이 같은 y', (tester) async {
    final table = await expectStableAnchorY(
      tester,
      states: {
        '갓 열림': requestSheetIdle,
        '내용 비움': requestSheetEmptyError,
      },
      anchors: {
        '시트 제목': WodDetailScreen.kRequestSheet,
        '안내 줄': WodDetailScreen.kRequestNotice,
        '제목 칸': WodDetailScreen.kRequestSubject,
        '내용 칸': WodDetailScreen.kRequestBody,
        '보내기': WodDetailScreen.kRequestSend,
      },
    );
    // ignore: avoid_print — 실측 수치를 보고용으로 남긴다.
    print(formatAnchorTable(table));
  });

  // 안내 줄은 실패 문구와 **같은 자리**를 쓴다 (D117 #1 과 같은 결 — 빈 띠를
  // 새로 만들지 않고 이미 있는 줄의 글자만 바꾼다). 줄 수가 달라 자리가
  // 늘었다 줄었다 하면 위 검사가 잡지만, 자리 자체의 높이도 못 박아 둔다.
  testWidgets('코치에게 요청 시트 — 안내 줄 자리는 두 상태에서 같은 높이', (tester) async {
    final table = await expectStableHeight(
      tester,
      states: {
        '갓 열림': requestSheetIdle,
        '내용 비움': requestSheetEmptyError,
      },
      targets: {'안내 줄': WodDetailScreen.kRequestNotice},
    );
    // ignore: avoid_print
    print(formatAnchorTable(table));
  });
}
