// v3.24 (2026-08-25 사용자 지시 "인라인으로 되어 있거나 이원화된 것 찾아서 전부
// 통일") — 상단바·다이얼로그·바텀시트·입력칸 스타일을 HKit/테마 한 곳으로
// 끌어올린 뒤, 화면 코드에 다시 인라인이 생기지 못하게 막는 게이트.
//
// 정본: 상단바 = HkAppBar · 다이얼로그 = HkDialog · 시트 = HkSheet ·
// 입력칸 모양 = theme.dart inputDecorationTheme (화면은 hintText 만 준다).
// 버튼은 button_lint_test.dart 가 따로 지킨다.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// (금지 패턴, 설명) — lib/features/** 에서 0건이어야 한다.
const List<(String, String)> _forbidden = [
  (r'(?<![A-Za-z_])AppBar\(', '상단바는 HkAppBar 만 (widgets/hkit.dart)'),
  (r'AlertDialog\(', '다이얼로그는 HkDialog.confirm/info/custom 만'),
  (r'showModalBottomSheet', '바텀시트는 HkSheet.show 만'),
  (r'(?<![A-Za-z_])NavigationBar\(', '하단 탭바는 HkTabBar 만 — 셸 두 벌 금지'),
  (r'CircularProgressIndicator\(', '스피너는 HkLoading 만'),
  (r'style: HyphenTokens\.sectionLabel[,)]', '섹션 라벨은 HkSectionLabel 만 (copyWith 변형만 예외)'),
  (r'String _(fmt|hhmm|ymd|dateShort)\w*\(', '날짜·시각 표기는 core/time_format.dart 만'),
  (r'InputDecoration _\w+\(', '입력칸 스타일은 테마 한 벌 — 화면별 _deco 금지'),
  (r'OutlineInputBorder\(', '입력칸 테두리는 theme.dart inputDecorationTheme 만'),
  (r'danger\.withValues\(alpha: ?0\.12\)', '인라인 에러 박스 금지 — HkInlineError'),
  // D91 (2026-08-30) — 히스토리 원천은 서버 한 벌. 앱은 판정·집계를 다시 하지 않는다.
  (r'PrDetector', 'PR 판정은 서버(wod_compare) 한 곳 — 응답 is_pr 를 읽는다 (D91)'),
  (r"post\(\s*'/api/v1/history", '히스토리는 읽기만 — 결과 저장 창구는 GymRepository.submitWodResult 하나 (D91)'),
  (r'\.length\s*;\s*//\s*totalSessions|totalSessions:\s*records\.length', '총 기록 수는 서버 meta.total (D91)'),
  (r'StreakFreeze|_currentStreak\(|_uniqueDays\(', '연속일은 서버 meta.streak_days — 폰이 세지 않는다 (D92)'),
  (r'rankHistory\(|scoreHistoryItem\(|searchTokens\(', '히스토리 검색 순위는 서버 services/history_search.py 하나 (D95)'),
  (r'kLateCancelMinutes|isLateCancel\(', '늦은 취소 판정은 서버 노쇼 정책 — cancel-preview 문구를 그대로 (D96)'),
  // D102 (2026-08-30) — 계약 상태 라벨·서명 가능 판정은 서버 status_label·signable 하나.
  // 스위치 팔('signed' => …)과 판정식('sent' || 'viewed')만 잡는다 — 쪽지 상태(m.status == 'sent')는 다른 뜻.
  (r"'(signed|sent|viewed)'\s*(\|\||=>)", '계약 상태 라벨·서명 가능 판정은 서버 status_label·signable (D102)'),
  (r'coversDay\(|hasMembershipOn\(', '그날 회원권 유무는 서버 수업 목록의 membership_ok (과제 4 · 2026-08-30)'),
  (r'DateTime\.parse\(pause(Start|End)', '정지 중·정지 예정 판정은 서버 is_paused/is_pause_scheduled (과제 4)'),
];

/// 모델까지 보는 패턴 — 회원권 날짜 규칙은 서버 api/_membership.membership_calendar_fields 한 곳.
/// 2026-09-06 사용자 지시 "업계 표준대로" — 시각·날짜는 **체육관 시각(Asia/Seoul)** 하나로
/// 그린다. 기기 시간대(`toLocal`)로 그리면 UTC 기기에서 수업이 전날 밤으로 밀려 다른 날
/// 묶음에 들어가고, 서버가 한국 날짜로 묶은 글과 짝이 어긋난다 (2026-09-06 에뮬 실측).
/// 정본 = `lib/core/time_format.dart` 의 `gym()` 하나 — 그 파일만 예외.
const _forbiddenTimezone = <(String, String)>[
  (r'DateTime\(\w+\.year, ?\w+\.month, ?\w+\.day\)',
   '기기 시간대 자정 생성 금지 — 체육관 날짜 자정은 .gymDay() (2026-09-06 조회 범위 9시간 밀림)'),
  (r'\.toLocal\(\)', '기기 시간대 표시 금지 — 체육관 시각 .gym() 하나 (time_format.dart)'),
];

const _forbiddenInModels = <(String, String)>[
  (r'DateTime\.parse\(pause(Start|End)', '정지 판정을 폰이 다시 세지 않는다 — 서버 is_paused (과제 4)'),
  (r'coversDay\(', '그날 회원권 유무는 서버 membership_ok (과제 4)'),
  (r'endDay\.difference\(today\)', 'D-day 는 서버 d_day (과제 4)'),
];

void main() {
  test('화면 코드에 인라인 상단바·다이얼로그·시트·입력칸 스타일 0건 (HKit SSOT)',
      () {
    final files = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    final hits = <String>[];
    for (final f in files) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        for (final (pattern, why) in _forbidden) {
          if (RegExp(pattern).hasMatch(line)) {
            final rel = f.path.replaceAll('\\', '/');
            hits.add('$rel:${i + 1}: ${line.trim()}  ← $why');
          }
        }
      }
    }
    expect(hits, isEmpty,
        reason: '인라인 UI 골격이 다시 생겼습니다 — HKit 정본을 쓰십시오:\n'
            '${hits.join('\n')}');
  });

  test('회원권 날짜 규칙을 모델에서 다시 세지 않는다 (서버 membership_calendar_fields 하나)', () {
    final hits = <String>[];
    // 회원권 모델만 본다 — 락커(models/locker.dart)의 D-day 도 같은 모양이지만 서버
    // /member/me/locker 가 아직 d_day 를 안 내려준다 (과제 4 범위 밖 — 보고에 남김).
    for (final f in [File('lib/models/membership.dart')]) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//') || line.trimLeft().startsWith('///')) continue;
        for (final (pattern, why) in _forbiddenInModels) {
          if (RegExp(pattern).hasMatch(line)) {
            hits.add('${f.path.replaceAll('\\', '/')}:${i + 1}: ${line.trim()}  ← $why');
          }
        }
      }
    }
    expect(hits, isEmpty, reason: '회원권 날짜 판정이 폰에 다시 생겼습니다:\n${hits.join('\n')}');
  });

  test('lib/** 에 기기 시간대 표시(.toLocal) 0건 — 체육관 시각 한 벌', () {
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final norm = f.path.replaceAll(r'\', '/');
      if (norm.endsWith('core/time_format.dart')) continue;
      // 생년월일 검증기 — 체육관 하루 규칙이 아니라 예외.
      if (norm.endsWith('core/input_formatters.dart')) continue;
      final src = f.readAsStringSync();
      for (final (pattern, why) in _forbiddenTimezone) {
        if (RegExp(pattern).hasMatch(src)) hits.add('$norm — $why');
      }
    }
    expect(hits, isEmpty, reason: hits.join(', '));
  });
}
