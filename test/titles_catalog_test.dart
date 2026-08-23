// v1.20 Phase 2: Panel B 칭호 카탈로그 단위 테스트.
//
// v3.12 (2026-08-23) 전면 갱신. 이 테스트는 "50개 · 영문 라벨 · Legendary 5"
// 를 지키고 있었는데, 그 셋 다 실물과 어긋난 옛 전제였다:
//  - 50개 중 32개는 **영원히 해금 불가**였다. 조건이 보는 신호(벤치마크·체중·
//    Engine 점수·unbroken 횟수·대회 등록)의 입력 경로가 v2.3~v2.6 개편에서
//    전부 사라졌는데 칭호만 남아, 회원 눈에는 "언젠가 얻을 수 있는 것"처럼
//    보였다. 얻을 수 있는 18개만 남긴다.
//  - '영문 라벨 강제' 는 v1.29 한글 기본 전환으로 폐기된 원칙이다.
//
// 이 테스트의 진짜 역할은 개수 세기가 아니라 **해금 불가 칭호의 재발 차단**
// 이다 — 아래 '살아있는 신호' 게이트가 그것이다.

import 'package:flutter_test/flutter_test.dart';
import 'package:hyphen_app/core/titles_catalog.dart';

void main() {
  group('Panel B catalog', () {
    test('칭호 18개 · code 고유', () {
      expect(kPanelBTitles.length, 18);
      expect(kPanelBTitles.map((t) => t.code).toSet().length, 18);
    });

    test('rarity 분포 — Common 13 / Rare 5', () {
      final by = <String, int>{};
      for (final t in kPanelBTitles) {
        by[t.rarity] = (by[t.rarity] ?? 0) + 1;
      }
      expect(by['Common'], 13);
      expect(by['Rare'], 5);
      // Epic·Legendary 는 전멸했다 — 남아 있던 것이 전부 1RM·대회 기록
      // 기반이라 입력 경로가 없다. 되살리려면 그 입력부터 만들어야 한다.
      expect(by['Epic'], isNull);
      expect(by['Legendary'], isNull);
    });

    test('칭호 이름은 한글 (도메인 고정어 PR·Streak 는 예외)', () {
      final hangulRe = RegExp(r'[가-힣]');
      const domainOnly = {'PB_WARM_UP', 'PB_COMMITTED', 'PB_DEDICATED'};
      for (final t in kPanelBTitles) {
        if (domainOnly.contains(t.code)) continue;
        expect(hangulRe.hasMatch(t.label), isTrue,
            reason: '${t.code} 이름에 한글 없음: ${t.label}');
      }
    });

    test('금지어 미포함 (박스·크로스핏·WOD — GLOSSARY §2 v2)', () {
      // 구 'BOX MEMBER' 는 금지어 '박스' 의 영문이라 한글 검사에 안 걸렸다.
      final banned = RegExp(r'(박스|크로스핏|CrossFit|\bBOX\b|\bWOD\b)',
          caseSensitive: false);
      for (final t in kPanelBTitles) {
        expect(banned.hasMatch('${t.label} ${t.captionKo}'), isFalse,
            reason: '${t.code} 금지어: ${t.label} / ${t.captionKo}');
      }
    });

    test('captionKo 한글 포함', () {
      final hangulRe = RegExp(r'[ㄱ-ㅎ가-힣]');
      for (final t in kPanelBTitles) {
        expect(hangulRe.hasMatch(t.captionKo), isTrue,
            reason: '${t.code} captionKo 한글 누락');
      }
    });
  });

  group('PanelBUnlocker', () {
    test('빈 signals → 해금 0', () {
      final out = PanelBUnlocker.unlockedCodes(const TitleUnlockSignals());
      expect(out, isEmpty);
    });

    test('100세션 → 백 번의 수업', () {
      final out = PanelBUnlocker.unlockedCodes(
        const TitleUnlockSignals(totalSessions: 100),
      );
      expect(out, contains('PB_GRINDER'));
    });

    test('99세션 → 미해금', () {
      final out = PanelBUnlocker.unlockedCodes(
        const TitleUnlockSignals(totalSessions: 99),
      );
      expect(out, isNot(contains('PB_GRINDER')));
    });

    test('Streak 30일 → 7·14·30 셋 다 해금 (누적)', () {
      final out = PanelBUnlocker.unlockedCodes(
        const TitleUnlockSignals(streakDays: 30),
      );
      expect(out, containsAll(
          <String>['PB_WARM_UP', 'PB_COMMITTED', 'PB_DEDICATED']));
    });

    test('복합 signals → 다중 해금', () {
      final out = PanelBUnlocker.unlockedCodes(
        const TitleUnlockSignals(
          totalSessions: 100,
          hasGym: true,
          prCount: 10,
        ),
      );
      expect(out, containsAll(<String>[
        'PB_GRINDER',
        'PB_BOX_MEMBER',
        'PB_PR_HUNTER',
        'PB_PR_MACHINE',
      ]));
    });

    // ── 재발 차단 게이트 ──
    // 카탈로그의 모든 칭호는 **실제로 값이 채워지는 신호**만 봐야 한다.
    // 새 칭호를 넣을 때 여기 목록에 없는 신호를 쓰면 이 테스트가 막는다.
    // (신호를 살리려면 그 입력 화면부터 만들 것.)
    test('모든 칭호가 살아있는 신호만 본다 — 해금 불가 재발 차단', () {
      // 아래 signals 를 최대치로 채우면 카탈로그 전부가 해금되어야 한다.
      final out = PanelBUnlocker.unlockedCodes(const TitleUnlockSignals(
        totalSessions: 1000,
        hasGym: true,
        sessionsBefore6am: 100,
        sessionsAfter10pm: 100,
        weekendSessions: 100,
        streakDays: 400,
        freshStartSession: true,
        shareCount: 100,
        coachNotesSent: 100,
        coachNotesReceived: 100,
        prCount: 100,
        doubleSessionDayCount: 100,
      ));
      final all = kPanelBTitles.map((t) => t.code).toSet();
      expect(out.difference(all), isEmpty, reason: '규칙에만 있고 카탈로그에 없는 code');
      expect(all.difference(out), isEmpty,
          reason: '살아있는 신호로 해금 불가 — 입력 경로 없는 칭호가 남아 있다');
    });
  });
}
