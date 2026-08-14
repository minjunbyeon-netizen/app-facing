// 시각 접근 단일화 자동 검사 — core/app_clock.dart (2026-08-14).
//
// 배경: 골든이 회귀가 아니라 달력을 검사하고 있었다 — 앱 코드 곳곳의
// DateTime.now() 탓에 날이 바뀌면 주간 보드·수업 시간 골든이 통째로 깨졌다.
// 전량을 appClock.now() 로 갈고 flutter_test_config 가 Clock.fixed 로 고정했다.
// 이 게이트는 그 두 구멍(직접 호출·존 주입 클록)이 다시 뚫리는 것을 막는다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// lib/ 아래 .dart 파일을 (경로, 줄번호, 원문) 으로 훑는다. 주석 줄은 건너뛴다.
void _scan(void Function(String path, int line, String raw) visit) {
  for (final f in Directory('lib').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    final normalized = f.path.replaceAll('\\', '/');
    final lines = f.readAsStringSync().split('\n');
    for (var i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.startsWith('//') ||
          trimmed.startsWith('*') ||
          trimmed.startsWith('/*')) {
        continue;
      }
      visit(normalized, i + 1, lines[i]);
    }
  }
}

void main() {
  group('시각 접근 단일화 — appClock 만', () {
    test('DateTime.now() 0건 (appClock.now() 만 사용)', () {
      final pattern = RegExp(r'\bDateTime\.now\(\)');
      final violations = <String>[];
      _scan((path, line, raw) {
        if (pattern.hasMatch(raw)) violations.add('$path:$line: ${raw.trim()}');
      });
      expect(
        violations,
        isEmpty,
        reason: 'DateTime.now() 는 테스트가 고정할 수 없습니다 — '
            'core/app_clock.dart 의 appClock.now() 를 쓰십시오:\n'
            '${violations.join('\n')}',
      );
    });

    test('존 주입 clock.now() 0건 (전파 안 됨 — appClock 만)', () {
      // package:clock 의 top-level `clock` 은 존(withClock) 주입인데,
      // package:test 가 본문을 선언 존 밖에서 실행해 고정이 전파되지 않는다.
      final pattern = RegExp(r'\bclock\.now\(');
      final violations = <String>[];
      _scan((path, line, raw) {
        if (pattern.hasMatch(raw)) violations.add('$path:$line: ${raw.trim()}');
      });
      expect(
        violations,
        isEmpty,
        reason: '존 주입 clock 은 테스트 고정이 안 먹힙니다 (2026-08-14 실측) — '
            'appClock.now() 를 쓰십시오:\n${violations.join('\n')}',
      );
    });
  });
}
