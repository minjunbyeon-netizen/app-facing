import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 모든 테스트 공통 부트스트랩 — FontManifest 의 전체 폰트(Pretendard·MaterialIcons)를
/// 실제로 로드한다. flutter_test 기본은 모든 글자를 사각형(Ahem)으로 그리므로
/// 이걸 안 하면 골든 캡처가 의미 없어진다. (writeplz-app 골든스탠다드 패턴)
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
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
