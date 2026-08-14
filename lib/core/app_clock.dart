// 시각 접근 단일 지점 — 앱 코드는 DateTime.now() 직접 호출 금지, appClock.now() 만.
// (게이트 = test/clock_lint_test.dart)
//
// 프로덕션은 시스템 시계 그대로, 테스트는 flutter_test_config 가 Clock.fixed 로
// 갈아끼워 골든 날짜 드리프트를 없앤다. package:clock 의 존 주입(withClock)은
// package:test 가 테스트 본문을 선언 존 밖에서 실행해 전파되지 않는다
// (2026-08-14 프로브 실측) — 전역 변수 주입으로 대체.
import 'package:clock/clock.dart';

Clock appClock = const Clock();
