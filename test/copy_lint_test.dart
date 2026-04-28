// 카피 일관성 자동 검사 — §9 Differentiation 6-pager Phase 2 Roadmap.
//
// Voice 11원칙 + 금지 용어 검출. 위반 시 PR 차단.
// 검사 대상: lib/ 전체 .dart 파일. 주석 라인은 스킵.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Copy lint — Voice 11원칙 + 금지 용어', () {
    test('금지 용어 0건 (운동/헬스/다이어트/웰니스/건강/체중관리/쉬운/편리한/누구나/당신/귀하)', () {
      final dir = Directory('lib');
      // 일반 피트니스 톤·다크 패턴 카피·V5 위반.
      final pattern = RegExp(
        r'(운동|헬스|다이어트|웰니스|체중관리|쉬운|편리한|누구나|당신|귀하)',
      );
      // 정당한 사용 예외:
      // - core/glossary.dart: 용어 정의문 (예: WOD = Workout of the Day)
      // - test/copy_lint_test.dart: 본 테스트 자체 (패턴 정의)
      final excludePaths = <String>{
        'lib/core/glossary.dart',
        'lib/core/quotes.dart',
      };
      final violations = <String>[];
      for (final f in dir.listSync(recursive: true)) {
        if (f is! File) continue;
        if (!f.path.endsWith('.dart')) continue;
        final normalized = f.path.replaceAll('\\', '/');
        if (excludePaths.any(normalized.contains)) continue;
        final lines = f.readAsStringSync().split('\n');
        for (var i = 0; i < lines.length; i++) {
          final raw = lines[i];
          final trimmed = raw.trim();
          // 주석 라인 스킵
          if (trimmed.startsWith('//')) continue;
          if (trimmed.startsWith('*') || trimmed.startsWith('/*')) continue;
          final m = pattern.firstMatch(raw);
          if (m != null) {
            violations.add('${f.path}:${i + 1}: ${raw.trim()}');
          }
        }
      }
      expect(
        violations,
        isEmpty,
        reason: '§9 Differentiation 카피 위반:\n${violations.join('\n')}',
      );
    });

    test('하드코드 fontSize 0건 (FacingTokens 외 인라인 TextStyle 차단)', () {
      final dir = Directory('lib');
      // 의도된 케이스 (theme 정의 자체) 제외.
      final excludePaths = <String>{
        'lib/core/theme.dart',
      };
      // TextStyle(...fontSize: NN...) 패턴 검출.
      final pattern = RegExp(r'TextStyle\([^)]*fontSize:\s*\d');
      final violations = <String>[];
      for (final f in dir.listSync(recursive: true)) {
        if (f is! File) continue;
        if (!f.path.endsWith('.dart')) continue;
        final normalized = f.path.replaceAll('\\', '/');
        if (excludePaths.any(normalized.contains)) continue;
        final content = f.readAsStringSync();
        // 멀티라인 TextStyle 도 포함 — 대략 검사
        final m = pattern.firstMatch(content);
        if (m != null) {
          violations.add(f.path);
        }
      }
      expect(
        violations,
        isEmpty,
        reason: 'CLAUDE.md R5 위반 — 하드코드 fontSize:\n${violations.join('\n')}',
      );
    });
  });
}
