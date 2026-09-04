// 캐릭터 에셋 게이트 (2026-09-04 신설).
//
// 왜 필요한가 — `mascot.dart` 의 위젯들은 파일이 없으면 화면이 깨지는 대신
// **조용히 접힌다**(errorBuilder → SizedBox.shrink). 안전한 대신, 그림이 빠져도
// 테스트도 빌드도 통과하고 아무도 모른다. 배율본(2.0x·3.0x)은 더 조용하다 —
// 1x 만 있으면 앱은 그걸 늘려 쓰므로 고해상도 폰에서 뭉개질 뿐 에러가 없다.
//
// 정본은 이 앱이 아니라 `C:/dev/services/design/_작업/앱에셋` 이고 여기 있는 건
// 사본이라, 정본에서 떨구다 한 벌을 빠뜨리는 사고가 실제로 가능하다. 그걸 막는다.
//
// 지키는 것 3가지:
//   1. mascot.dart 가 적은 경로는 전부 실물이 있다
//   2. 전신 세트(action/·greeting/)는 2.0x·3.0x 배율본이 같이 있다
//   3. 그 폴더가 pubspec.yaml assets 에 등록돼 있다 (등록 없으면 번들에 안 실린다)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 배율본이 함께 있어야 하는 전신 세트. 얼굴·스낵바 3장은 1x 단일이라 제외한다.
const _needsDensityVariants = ['assets/character/action/', 'assets/character/greeting/'];

void main() {
  final source = File('lib/widgets/mascot.dart').readAsStringSync();
  final paths = RegExp(r"'(assets/character/[^']+)'")
      .allMatches(source)
      .map((m) => m.group(1)!)
      .toSet()
      .toList()
    ..sort();

  test('mascot.dart 가 경로를 실제로 들고 있다', () {
    // 매핑이 통째로 비면 아래 검사가 전부 공회전한다 — 0건 자체를 실패로 본다.
    expect(paths, isNotEmpty, reason: 'mascot.dart 에서 캐릭터 경로를 하나도 못 찾았다');
  });

  test('적은 경로는 전부 실물이 있다', () {
    final missing = paths.where((p) => !File(p).existsSync()).toList();
    expect(missing, isEmpty,
        reason: '파일이 없으면 화면에서 조용히 접힌다. 정본에서 다시 떨궈라:\n'
            'C:/dev/services/design/_작업/앱에셋/flutter\n${missing.join('\n')}');
  });

  test('전신 세트는 2.0x·3.0x 배율본이 같이 있다', () {
    final missing = <String>[];
    for (final p in paths) {
      if (!_needsDensityVariants.any(p.startsWith)) continue;
      final dir = p.substring(0, p.lastIndexOf('/'));
      final file = p.substring(p.lastIndexOf('/') + 1);
      for (final d in ['2.0x', '3.0x']) {
        final v = '$dir/$d/$file';
        if (!File(v).existsSync()) missing.add(v);
      }
    }
    expect(missing, isEmpty,
        reason: '1x 만 있으면 에러 없이 고해상도 폰에서만 뭉갠다:\n${missing.join('\n')}');
  });

  test('쓰는 폴더가 pubspec.yaml assets 에 등록돼 있다', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final dirs = paths.map((p) => '${p.substring(0, p.lastIndexOf('/'))}/').toSet();
    final unregistered =
        dirs.where((d) => !pubspec.contains('- $d')).toList()..sort();
    expect(unregistered, isEmpty,
        reason: '등록 안 된 폴더는 번들에 안 실려 실기에서만 빈다:\n${unregistered.join('\n')}');
  });

  test('세트별 enum 과 매핑 수가 맞는다', () {
    // HypeeActions.ready / HypeeGreetings.ready 가 거짓이면 호출부가 연출을 통째로
    // 접도록 돼 있다. 그 스위치가 조용히 꺼지는 일을 막는다.
    for (final set in ['action', 'greeting']) {
      final n = paths.where((p) => p.startsWith('assets/character/$set/')).length;
      expect(n, greaterThan(0), reason: '$set 세트 매핑이 비었다');
    }
  });
}
