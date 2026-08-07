// 배지·칩 1종 강제 자동 검사 — DESIGN-SSOT §7-C (v1.32 · 2026-08-07 사용자 지시).
//
// 배경: 같은 역할의 작은 라벨 조각을 화면마다 따로 만들어(_Pill·_MiniPill·_StatusChip·
// _CategoryChip·_PainChip·_chip …) 모서리 5종·면 채움 3종이 난립했다. 전수 폐기 후
// FkBadge 하나로 통합했고, 다시 갈라지지 않도록 이 테스트가 게이트 역할을 한다.
//
// 모양이 다른 배지가 필요하면 lib/widgets/fkit.dart 의 FkBadge 를 고친다.

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
  group('배지 1종 강제 — DESIGN-SSOT §7-C', () {
    test('화면 로컬 Pill·Chip·Tag variant 0건 (FkBadge 만 사용)', () {
      // 클래스 선언 + 위젯 반환 헬퍼 메서드 양쪽을 잡는다.
      final classDecl = RegExp(r'class\s+_?\w*(Pill|Chip|Tag)\w*\s+extends');
      final helperDecl = RegExp(r'Widget\s+_?\w*(pill|chip|tag)\w*\s*\(',
          caseSensitive: false);
      final violations = <String>[];
      _scan((path, line, raw) {
        if (classDecl.hasMatch(raw) || helperDecl.hasMatch(raw)) {
          violations.add('$path:$line: ${raw.trim()}');
        }
      });
      expect(
        violations,
        isEmpty,
        reason: '배지·칩은 FkBadge 하나뿐입니다 (DESIGN-SSOT §7-C). '
            '모양이 다르면 fkit.dart 의 FkBadge 를 고치십시오:\n'
            '${violations.join('\n')}',
      );
    });

    test('인라인 선택 칩 0건 (선택 여부로 면·보더를 바꾸는 BoxDecoration)', () {
      // 클래스로 빼지 않고 build 안에서 바로 그리던 선택 칩까지 잡는다.
      // decoration: BoxDecoration( 이후 12줄 안에 selected 삼항이 있으면 칩으로 본다.
      const window = 12;
      final violations = <String>[];
      for (final f in Directory('lib').listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        final normalized = f.path.replaceAll('\\', '/');
        // FkBadge 자신이 유일하게 이 패턴을 가질 수 있다.
        if (normalized.endsWith('lib/widgets/fkit.dart')) continue;
        final lines = f.readAsStringSync().split('\n');
        for (var i = 0; i < lines.length; i++) {
          if (!lines[i].contains('BoxDecoration(')) continue;
          final end = (i + window).clamp(0, lines.length);
          for (var j = i + 1; j < end; j++) {
            if (!RegExp(r'(color|border):.*\bselected\s*\?').hasMatch(lines[j])) {
              continue;
            }
            // 배지가 아닌 컴포넌트(선택 상태를 갖는 카드 등)는 바로 위 줄에
            // `// badge-lint: ignore — 사유` 를 달아 명시 면제한다.
            final prev = j > 0 ? lines[j - 1] : '';
            if (prev.contains('badge-lint: ignore') ||
                lines[j].contains('badge-lint: ignore')) {
              break;
            }
            violations.add('$normalized:${j + 1}: ${lines[j].trim()}');
            break;
          }
        }
      }
      expect(
        violations,
        isEmpty,
        reason: '선택 칩은 FkBadge(selected: …, onTap: …) 하나뿐입니다 '
            '(DESIGN-SSOT §7-C):\n${violations.join('\n')}',
      );
    });

    test('Material 기본 칩 위젯 0건 (Chip/ChoiceChip/FilterChip/…)', () {
      final pattern =
          RegExp(r'\b(Chip|ChoiceChip|FilterChip|ActionChip|InputChip)\(');
      final violations = <String>[];
      _scan((path, line, raw) {
        if (pattern.hasMatch(raw)) violations.add('$path:$line: ${raw.trim()}');
      });
      expect(
        violations,
        isEmpty,
        reason: 'Material 칩 위젯은 모서리·면 규격이 우리 것과 다릅니다. '
            'FkBadge 를 쓰십시오:\n${violations.join('\n')}',
      );
    });
  });
}
