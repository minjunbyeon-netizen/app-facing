import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_app/core/app_clock.dart';

/// 모든 테스트가 보는 시각. 앱 코드는 `appClock.now()` 만 쓰므로 (DateTime.now()
/// 0건 — 게이트 = clock_lint_test) 여기서 고정하면 골든 날짜 드리프트가 사라진다.
/// 수요일 오전 — 주간 보드가 주 중간에 서고, fakes 의 저녁 20시 수업이
/// "아직 안 지난 오늘 수업"으로 남아 예약 버튼이 골든에 찍힌다.
/// (withClock 존 주입은 test 본문까지 전파 안 됨 — 2026-08-14 프로브 실측,
/// 그래서 전역 변수 대입.)
final Clock kTestClock = Clock.fixed(DateTime(2026, 8, 12, 10, 30));

/// 모든 테스트 공통 부트스트랩 — FontManifest 의 전체 폰트(Pretendard·MaterialIcons)를
/// 실제로 로드한다. flutter_test 기본은 모든 글자를 사각형(Ahem)으로 그리므로
/// 이걸 안 하면 골든 캡처가 의미 없어진다. (writeplz-app 골든스탠다드 패턴)
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  appClock = kTestClock;
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest = await rootBundle.loadString('FontManifest.json');
  for (final font
      in (json.decode(manifest) as List).cast<Map<String, dynamic>>()) {
    final family = (font['family'] as String)
        .replaceFirst(RegExp(r'^packages/[^/]+/'), '');
    final loader = FontLoader(family);
    for (final f in (font['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(f['asset'] as String));
    }
    await loader.load();
  }
  await testMain();
}
