// 버튼 1종 강제 자동 검사 — DESIGN-SSOT §7-D (v2.2 · 2026-08-12 사용자 지시).
//
// 배경: §7-D 는 "버튼 = HkButton 하나뿐" 을 선언했지만, 선언 시점에 원시
// Material 버튼(ElevatedButton·OutlinedButton·TextButton·FilledButton) 이
// 37개 파일에 이미 퍼져 있었다. 전량 이관은 별건이므로 이 게이트는 **래칫**:
//  - baseline 에 없는 파일에서 원시 버튼 발견 = 실패 (신규 화면은 HkButton 만)
//  - baseline 파일이 원시 버튼 0건이 되면 = 실패 (목록에서 지워 래칫을 조인다)
// 즉 목록은 줄어들기만 한다. 이관을 마친 파일은 여기서 빼는 것이 완료 조건.
//
// 모양이 다른 버튼이 필요하면 lib/widgets/hkit.dart 의 HkButton 을 고친다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// §7-D 선언(2026-08-12) 이전부터 원시 버튼을 쓰던 레거시 파일 — 줄어들기만 한다.
/// v3.24 (2026-08-25): 22개 파일 71건 전부 HkButton 으로 이관 — 래칫이 0에 닿았다.
/// 여기에 다시 파일을 넣는 것은 §3 코드·클래스 SSOT 위반.
const Set<String> _rawButtonBaseline = {};

/// lib/ 아래 .dart 파일을 (경로, 줄번호, 원문) 으로 훑는다. 주석 줄은 건너뛴다.
/// HkButton 구현체인 hkit.dart 자신은 원시 버튼을 가질 수 있어 제외한다.
void _scan(void Function(String path, int line, String raw) visit) {
  for (final f in Directory('lib').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    final normalized = f.path.replaceAll('\\', '/');
    if (normalized.endsWith('lib/widgets/hkit.dart')) continue;
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

/// 원시 버튼 생성자 호출. `TextButton.styleFrom(` 같은 static 헬퍼는 안 잡는다.
final _rawButton =
    RegExp(r'\b(ElevatedButton|OutlinedButton|FilledButton|TextButton)'
        r'(\.icon)?\s*\(');

void main() {
  group('버튼 1종 강제 — DESIGN-SSOT §7-D', () {
    test('baseline 밖 원시 버튼 0건 (신규 코드는 HkButton 만)', () {
      final violations = <String>[];
      _scan((path, line, raw) {
        if (!_rawButton.hasMatch(raw)) return;
        if (_rawButtonBaseline.contains(path)) return;
        violations.add('$path:$line: ${raw.trim()}');
      });
      expect(
        violations,
        isEmpty,
        reason: '버튼은 HkButton 하나뿐입니다 (DESIGN-SSOT §7-D). '
            '모양이 다르면 hkit.dart 의 HkButton 을 고치십시오:\n'
            '${violations.join('\n')}',
      );
    });

    test('baseline 래칫 — 이관 끝난 파일은 목록에서 뺀다', () {
      final stillRaw = <String>{};
      _scan((path, line, raw) {
        if (_rawButton.hasMatch(raw)) stillRaw.add(path);
      });
      final stale = _rawButtonBaseline.difference(stillRaw);
      expect(
        stale,
        isEmpty,
        reason: '원시 버튼이 사라진 파일입니다 — baseline 에서 지워 래칫을 '
            '조이십시오 (다시 늘어나지 못하게):\n${stale.join('\n')}',
      );
    });

    test('터치 최소 48 미만 minimumSize 0건 (§7-D 금지)', () {
      // 높이 인자가 숫자 리터럴이면 48 미만 금지. HyphenTokens.touchMin 참조는 통과.
      final pattern = RegExp(
          r'minimumSize:\s*(?:const\s+)?Size(?:\.square)?\(\s*[^,)]+(?:,\s*(\d+(?:\.\d+)?))?\s*\)');
      final violations = <String>[];
      _scan((path, line, raw) {
        final m = pattern.firstMatch(raw);
        if (m == null) return;
        final h = m.group(1);
        if (h == null) return; // 숫자 리터럴 아님 (토큰 상수 등)
        if (double.parse(h) < 48) {
          violations.add('$path:$line: ${raw.trim()}');
        }
      });
      expect(
        violations,
        isEmpty,
        reason: '터치 최소 48 은 §7-D 하한입니다 — minimumSize 를 낮추지 말고 '
            'HkButton/토큰(touchMin)을 쓰십시오:\n${violations.join('\n')}',
      );
    });

    test('muted 전경 styleFrom 0건 (비활성처럼 보임 — §7-D 금지)', () {
      // 중립 톤이 필요하면 HkButton(neutral: true) = fgSecondary.
      final pattern = RegExp(r'styleFrom\(\s*foregroundColor:[^,)]*muted');
      final violations = <String>[];
      _scan((path, line, raw) {
        if (pattern.hasMatch(raw)) violations.add('$path:$line: ${raw.trim()}');
      });
      expect(
        violations,
        isEmpty,
        reason: 'muted 전경 버튼은 비활성으로 읽힙니다 (§7-D) — '
            'HkButton(neutral: true) 를 쓰십시오:\n${violations.join('\n')}',
      );
    });
  });
}
