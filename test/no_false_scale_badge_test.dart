// 아무도 고르지 않은 난도를 화면이 단정하지 않는다 (2026-09-05).
//
// 2026-09-02(v3.45)에 완료 시트의 난도(RXD/SCALED) 선택을 없앴다. 그런데 앱은
// `scale_level: 'rx'` 를 **기본값으로 계속 보내고**, 히스토리 상세는 그 값을
// 조건 없이 `RXD` 배지로 그렸다. 회원이 코치 처방보다 가볍게 들어도 `RXD` 가
// 붙는다 — 고른 사람이 없는 값을 화면이 사실처럼 말한 것이다.
// (D121 이 점수 라벨을 되살리기 전까지는 히어로 줄이 통째로 숨어 안 보였을 뿐이다.)
//
// 제품 제1원칙: 화면이 거짓말하지 않을 것.
// 난도를 다시 보여주려면 **회원이 고르는 창구**를 먼저 만든다 — 그때 이 검사를 고친다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:hyphen_app/features/history/history_models.dart';

void main() {
  test('값은 계속 받되(휴면), 표기로 바꾸지 않는다', () {
    final item = WodHistoryItem.fromJson(const {
      'id': 1,
      'title': 'SWEAT',
      'label': '9:42',
      'scale_level': 'rx',
      'created_at': '2026-09-05T14:02:00+09:00',
    });
    // 값 자체는 서버에서 계속 내려온다 — 휴면 컬럼이라 지우지 않는다 (대전제 5).
    expect(item.scaleLevel, 'rx');
  });

  test('난도 배지를 그리는 코드가 화면에 남아 있지 않다', () {
    // 주석은 뺀다 — 왜 지웠는지 적어 둔 글이 검사에 걸리면 기록을 못 남긴다.
    String code(String path) => File(path)
        .readAsLinesSync()
        .where((l) => !l.trimLeft().startsWith('//'))
        .join(' ');

    expect(
      code('lib/features/history/history_detail_screen.dart')
          .contains('scaleLabel'),
      isFalse,
      reason: '고른 사람이 없는 난도를 상세가 배지로 단정하고 있다',
    );
    expect(
      code('lib/features/history/history_models.dart').contains('RXD'),
      isFalse,
      reason: "앱이 'rx' 를 'RXD' 라는 표기로 바꾸는 자리가 남아 있다",
    );
  });
}
