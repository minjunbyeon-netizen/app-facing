// 카피 일관성 자동 검사 — §9 Differentiation 6-pager Phase 2 Roadmap.
//
// Voice 11원칙 + 금지 용어 검출. 위반 시 PR 차단.
// 검사 대상: lib/ 전체 .dart 파일. 주석 라인은 스킵.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Copy lint — Voice 11원칙 + 금지 용어', () {
    // v3.0 (2026-08-14): '운동' 해제 — 크로스핏 표기 철수로 '운동 경력' 이 정본이 됐다.
    test('금지 용어 0건 (헬스/다이어트/웰니스/체중관리/쉬운/편리한/누구나/당신/귀하)', () {
      final dir = Directory('lib');
      // 일반 피트니스 톤·다크 패턴 카피·V5 위반.
      final pattern = RegExp(
        r'(헬스|다이어트|웰니스|체중관리|쉬운|편리한|누구나|당신|귀하)',
      );
      // 정당한 사용 예외:
      // - test/copy_lint_test.dart: 본 테스트 자체 (패턴 정의)
      final excludePaths = <String>{
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

    // docs/GLOSSARY.md §1 자동 게이트 (2026-08-12 사용자 지시).
    // 박스를 운영하는 사람은 '코치' 하나로만 부른다 — 사장·오너·매니저 등은
    // 이 제품에 없는 말이다. 번역은 core/role_labels.dart 한 곳에서만 한다.
    test('운영자 호칭 1종 — 사장/오너/점주/매니저/관리자 0건 (GLOSSARY §1)', () {
      final dir = Directory('lib');
      final pattern = RegExp(r'(사장|오너|점주|짐매니저|매니저|관리자|운영자)');
      final violations = <String>[];
      for (final f in dir.listSync(recursive: true)) {
        if (f is! File) continue;
        if (!f.path.endsWith('.dart')) continue;
        // 약관·방침은 법적 고지 — "서비스 운영자(개인 변민준)" 는 체육관을 운영하는
        // 사람(코치)이 아니라 서비스 제공자 표기라 GLOSSARY §1 대상이 아니다
        // (2026-08-28 개인 명의 출시 전환 — 스토어 심사에 운영자 명시가 필요).
        final normalized = f.path.replaceAll('\\', '/');
        if (normalized.endsWith('lib/features/mypage/terms_screen.dart') ||
            normalized.endsWith('lib/features/mypage/privacy_screen.dart')) {
          continue;
        }
        final lines = f.readAsStringSync().split('\n');
        for (var i = 0; i < lines.length; i++) {
          final raw = lines[i];
          final trimmed = raw.trim();
          // 주석 라인 스킵 — 히스토리 설명에는 옛 용어가 남을 수 있다.
          if (trimmed.startsWith('//')) continue;
          if (trimmed.startsWith('*') || trimmed.startsWith('/*')) continue;
          if (trimmed.startsWith('///')) continue;
          if (pattern.hasMatch(raw)) {
            violations.add('${f.path}:${i + 1}: $trimmed');
          }
        }
      }
      expect(
        violations,
        isEmpty,
        reason: 'docs/GLOSSARY.md §1 위반 — 운영자는 "코치" 하나:\n'
            '${violations.join('\n')}',
      );
    });

    // 크로스핏 표기 철수 (2026-08-14 v3.0 — "이 제품은 크로스핏장이 아니다").
    // 노출 문구에서 박스·크로스핏·WOD(일반 명칭) 금지 — 박스→체육관,
    // WOD 게시물→수업 내용, 시간표→수업 시간 (docs/GLOSSARY.md §2 v2).
    // 내부 심볼·API·DB 값(BoxWodScreen·wodType·'WOD_50' 등)은 대상 아님.
    test('크로스핏 표기 0건 — 박스/크로스핏/WOD 노출 문구 금지 (GLOSSARY §2 v2)', () {
      final dir = Directory('lib');
      // 고유명사 보존 예외: 명언 원문(quotes) · 업적 고유명(
      // CrossFit Open/Games). 벤치마크 계열(Girls/Hero/Games WOD)은 정규화로 제거.
      final excludePaths = <String>{
        'lib/core/quotes.dart',
      };
      final banned = RegExp(r'(박스|크로스핏|CrossFit|\bWOD\b)');
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
          // 주석 라인 스킵 — 히스토리 설명에는 옛 용어가 남는다.
          if (trimmed.startsWith('//')) continue;
          if (trimmed.startsWith('*') || trimmed.startsWith('/*')) continue;
          // 문자열 리터럴이 있는 라인만 — 식별자(BoxWod·wodType)는 통과.
          if (!raw.contains("'") && !raw.contains('"')) continue;
          final cleaned = raw
              .replaceAll('인박스', '')
              .replaceAll('아웃박스', '')
              .replaceAll(RegExp(r'(Girls|Hero|Games)\s+WOD'), '');
          if (banned.hasMatch(cleaned)) {
            violations.add('${f.path}:${i + 1}: $trimmed');
          }
        }
      }
      expect(
        violations,
        isEmpty,
        reason: 'GLOSSARY §2 v2 위반 — 크로스핏 표기 철수 (박스→체육관, '
            'WOD→수업 내용):\n${violations.join('\n')}',
      );
    });

    test('하드코드 fontSize 0건 (HyphenTokens 외 인라인 TextStyle 차단)', () {
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
