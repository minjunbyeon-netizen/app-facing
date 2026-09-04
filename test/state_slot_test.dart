/// 로딩·빈·에러가 **같은 자리**를 쓰는지 (D115 · 2026-09-04).
///
/// 사용자 지시: "스켈레톤으로 자리 잘 비워두고 특히 레이아웃 시프트 발생 안 하도록."
///
/// 왜 이 검사가 있나 — 2026-09-04 UI 감사에서 셋을 실제로 렌더해 재 보니
/// 로딩 22 · 빈 70(캡션 있으면 97) · 에러 131 로 **최대 109px** 차이가 났다.
/// 같은 자리에서 삼항으로 갈아 끼우는 화면은 상태가 바뀌는 순간 그만큼 밀렸다.
/// 규격이 부품에 없어서 호출부가 감싸 준 곳만 안전했다.
///
/// 상수를 서로 비교하지 않는다 — **실물을 렌더해 `tester.getSize` 로 잰다**
/// (`touch_target_test.dart` 와 같은 방식). 규격을 문서에만 적으면 안 지켜진다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_app/core/theme.dart';
import 'package:hyphen_app/widgets/hkit.dart';

/// 폭 360 안에서 위젯 하나를 세우고 높이를 잰다 (세로는 제약 없음 = 내용 높이).
Future<double> _heightOf(WidgetTester tester, Widget child) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      theme: HyphenTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: KeyedSubtree(key: key, child: child),
          ),
        ),
      ),
    ),
  );
  return tester.getSize(find.byKey(key)).height;
}

void main() {
  group('상태 3종은 같은 바닥을 갖는다 (stateSlotH)', () {
    testWidgets('로딩(slot) · 빈 · 빈+캡션 · 에러 — 넷 다 같은 높이', (tester) async {
      final loading = await _heightOf(tester, const HkLoading.slot());
      final empty = await _heightOf(tester, const HkEmptyState(title: '기록 없음'));
      final emptyCap = await _heightOf(
        tester,
        const HkEmptyState(title: '기록 없음', caption: '수업을 완료하면 여기에 쌓입니다.'),
      );
      final error = await _heightOf(
        tester,
        HkErrorState(message: '불러오지 못했습니다.', onRetry: () {}),
      );

      expect(
        {loading, empty, emptyCap, error},
        {HyphenTokens.stateSlotH},
        reason:
            '로딩 $loading · 빈 $empty · 빈+캡션 $emptyCap · 에러 $error — '
            '넷이 같아야 갈아 끼울 때 안 밀립니다 (기대 ${HyphenTokens.stateSlotH})',
      );
    });

    testWidgets('기본 HkLoading 은 자리를 차지하지 않는다 (버튼 안·줄 안용)', (tester) async {
      final inline = await _heightOf(tester, const HkLoading());
      expect(
        inline,
        lessThan(HyphenTokens.stateSlotH),
        reason: '기본 생성자는 22×22 스피너 그대로여야 합니다 (실측 $inline)',
      );
      expect(inline, 22);
    });

    testWidgets('내용이 크면 바닥 위로 자란다 (자르지 않는다)', (tester) async {
      final long = await _heightOf(
        tester,
        const HkEmptyState(
          title: '아직 아무 기록도 없습니다',
          caption: '수업에 참여하고 완료를 남기면 이 자리에 기록이 쌓입니다. '
              '코치가 올린 그날 운동을 보고 자기 기록을 적어 두면 나중에 '
              '히스토리 탭에서 동작별로 다시 찾아볼 수 있습니다.',
        ),
      );
      expect(long, greaterThan(HyphenTokens.stateSlotH));
    });
  });
}
