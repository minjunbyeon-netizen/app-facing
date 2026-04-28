// v1.20 /go 페르소나 검증: WornTitleStore 회귀 테스트.
//
// SharedPreferences wrapper 단순 wrapper지만 mypage_screen Profile 상단의
// 착용 칭호 표시(_WornTitleLine)와 PanelB 화면 선택 흐름의 핵심 의존.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facing_app/core/worn_title_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('WornTitleStore', () {
    test('초기 상태 — null', () async {
      expect(await WornTitleStore.get(), isNull);
    });

    test('set 후 get → 동일 코드', () async {
      await WornTitleStore.set('PB_GRINDER');
      expect(await WornTitleStore.get(), 'PB_GRINDER');
    });

    test('set 두번째 호출 → 덮어쓰기 (단일 착용)', () async {
      await WornTitleStore.set('PB_GRINDER');
      await WornTitleStore.set('PB_SNATCH_KING');
      expect(await WornTitleStore.get(), 'PB_SNATCH_KING');
    });

    test('clear 후 get → null', () async {
      await WornTitleStore.set('PB_HEAVY');
      await WornTitleStore.clear();
      expect(await WornTitleStore.get(), isNull);
    });

    test('빈 문자열 set → get 시 null 반환 (정책)', () async {
      // 정책: get() 은 빈 문자열도 null 로 통일 처리.
      // SharedPreferences.setString('') 은 가능하나 wrapper 가 normalize.
      SharedPreferences.setMockInitialValues({'worn_title_code_v1': ''});
      expect(await WornTitleStore.get(), isNull);
    });

    test('Panel B 칭호 코드 형식 (PB_*) 호환', () async {
      // titles_catalog.dart 의 모든 코드는 PB_ 접두 — wrapper 가 형식 강제 안 함.
      const codes = ['PB_GRINDER', 'PB_HEAVY', 'PB_SNATCH_KING', 'PB_RUNNER'];
      for (final c in codes) {
        await WornTitleStore.set(c);
        expect(await WornTitleStore.get(), c);
      }
    });
  });
}
