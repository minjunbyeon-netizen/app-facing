// 히스토리 — **파트 점수가 보이게** (D122 §7 · `docs/CONTRACT-result-axes-2.md`).
//
// 서버는 `history_item.parts[]` 를 내려주는데 앱이 **파싱조차 하지 않았다**. 회원이
// 파트마다 적어 낸 점수는 목록 둘째 줄의 잘린 한 줄 말고는 다시 볼 방법이 없었다.
//
// 이 파일이 재는 것:
//   1. 목록 둘째 줄은 두 줄까지 (maxLines 2)
//   2. 다중 파트에서 온 헤드라인이면 숫자 아래 작은 라벨 (서버 headline_part_label)
//   3. 상세에 파트별 줄 — **서버가 그린 `line` 그대로** (앱이 조립하지 않는다)
//   4. `capped` 면 '캡' 배지 — 캡 기록과 완주 기록은 다른 단위다 (§2)
//   5. 난도 배지는 되살아나지 않는다 (2026-09-05 삭제 · no_false_scale_badge_test)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hyphen_app/features/history/history_detail_screen.dart';
import 'package:hyphen_app/features/history/history_screen.dart';

import 'golden/fakes.dart';
import 'golden/harness.dart';
import 'golden/screens_golden_test.dart'
    show rxProfile, signedInAuth, signedInPrefs;

Future<void> mountList(WidgetTester tester) async {
  phone(tester);
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final api = FakeApi({...memberWorld(), '/api/v1/history/wod': wodHistoryList()});
  await tester.pumpWidget(
    harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      home: const HistoryScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> mountDetail(
  WidgetTester tester,
  Map<String, dynamic> detail,
) async {
  phone(tester);
  SharedPreferences.setMockInitialValues(signedInPrefs());
  final api = FakeApi({'/api/v1/history/wod/502': detail, ...memberWorld()});
  await tester.pumpWidget(
    harness(
      api: api,
      auth: await signedInAuth(),
      profile: rxProfile(),
      home: const HistoryDetailScreen(recordId: 502),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('계약 §7 — 목록', () {
    testWidgets('둘째 줄은 두 줄까지 보여 준다', (tester) async {
      await mountList(tester);
      final row = tester.widget<Text>(
        find.text('Thruster 21-15-9회 · 43kg · Pull-up 21-15-9회'),
      );
      expect(
        row.maxLines,
        2,
        reason:
            '그날 운동 요약이 한 줄에서 잘리면 회원이 적어 낸 값을 다시 볼 방법이 '
            '없습니다 (계약 §7)',
      );
    });

    testWidgets('다중 파트 헤드라인이면 어느 파트인지 밝힌다', (tester) async {
      await mountList(tester);
      expect(
        find.text('C 파트'),
        findsOneWidget,
        reason:
            '파트가 여럿인 수업의 6:52 는 C 파트 점수다 — 어느 파트인지 안 밝히면 '
            '수업 전체 시간처럼 읽힌다 (서버 headline_part_label)',
      );
    });
  });

  group('계약 §7 — 상세', () {
    testWidgets('파트별 줄이 선다 (서버 line 그대로)', (tester) async {
      await mountDetail(tester, wodHistoryDetail());
      for (final line in const [
        'A 파트 · STRENGTH — 70kg×5',
        'B 파트 · AMRAP — 5R+12',
        'C 파트 · FOR TIME — 6:52',
      ]) {
        expect(
          find.text(line),
          findsOneWidget,
          reason: '파트 줄 "$line" 이 없습니다 — parts[] 를 파싱하지 않았습니다',
        );
      }
    });

    testWidgets('파트가 없는 기록에는 파트 칸도 없다', (tester) async {
      await mountDetail(tester, wodHistoryDetailNoScore());
      expect(find.text('파트별 기록'), findsNothing);
    });

    testWidgets('캡 기록에는 캡 배지 (완주와 다른 단위)', (tester) async {
      await mountDetail(tester, wodHistoryDetailCapped());
      expect(
        find.text('캡'),
        findsOneWidget,
        reason: '캡에 걸려 끝난 기록을 완주 기록과 같은 얼굴로 보여 주면 거짓말이다 (§2)',
      );
      // 난도 배지는 되살리지 않는다 (고른 사람이 없는 값).
      expect(find.text('SCALED'), findsNothing);
      expect(find.text('RXD'), findsNothing);
    });

    testWidgets('캡이 아닌 기록에는 캡 배지가 없다', (tester) async {
      await mountDetail(tester, wodHistoryDetail());
      expect(find.text('캡'), findsNothing);
    });
  });
}
