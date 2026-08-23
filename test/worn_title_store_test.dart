// v1.20 /go 페르소나 검증: 착용 칭호 회귀 테스트.
//
// v3.12 (2026-08-23): 저장소가 WornTitleStore(로컬 전용) → GoalsState(서버
// 저장)로 옮겨졌다. 로컬에만 있던 시절엔 폰을 바꾸면 착용이 풀렸다.
// 목표와 성격이 같은 값(회원이 스스로 고르는·체육관 무관)이라 같은 행·같은
// 창구로 합쳤다 (§0-B) — 이 테스트도 그 창구를 검사한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hyphen_app/core/goals_state.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('착용 칭호 (GoalsState)', () {
    test('초기 상태 — 빈 문자열 (착용 안 함)', () async {
      final g = GoalsState();
      await g.load();
      expect(g.wornTitle, '');
    });

    test('착용 후 값 유지', () async {
      final g = GoalsState();
      await g.load();
      await g.setWornTitle('PB_GRINDER');
      expect(g.wornTitle, 'PB_GRINDER');
    });

    test('다른 칭호 착용 → 덮어쓰기 (단일 착용)', () async {
      final g = GoalsState();
      await g.load();
      await g.setWornTitle('PB_GRINDER');
      await g.setWornTitle('PB_FIRST_WOD');
      expect(g.wornTitle, 'PB_FIRST_WOD');
    });

    test('빈 문자열로 해제', () async {
      final g = GoalsState();
      await g.load();
      await g.setWornTitle('PB_GRINDER');
      await g.setWornTitle('');
      expect(g.wornTitle, '');
    });

    test('로컬 캐시에 남아 다음 실행에서 복원', () async {
      final g1 = GoalsState();
      await g1.load();
      await g1.setWornTitle('PB_WEEKEND');

      // 같은 기기의 다음 실행 (서버 미배선 = 캐시만으로 떠야 한다)
      final g2 = GoalsState();
      await g2.load();
      expect(g2.wornTitle, 'PB_WEEKEND');
    });

    test('서버 미배선이어도 예외 없이 동작 (오프라인 경로)', () async {
      final g = GoalsState();
      await g.load();
      await g.setWornTitle('PB_EARLY_BIRD'); // sync 내부에서 api == null → no-op
      expect(g.wornTitle, 'PB_EARLY_BIRD');
      expect(g.isServerDown, isFalse);
    });
  });
}
