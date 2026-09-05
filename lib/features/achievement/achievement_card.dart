import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/achievement.dart';
import 'hyphen_pictogram.dart';
import '../../core/time_format.dart';

/// v1.16 Sprint 9a: Achievement 배지 카드.
/// 잠긴 배지에도 해금 조건 힌트 표시 — hidden 배지만 "· · ·" 유지.
class AchievementCard extends StatelessWidget {
  final AchievementCatalog catalog;
  final AchievementUnlock? unlock; // null이면 미해금

  const AchievementCard({super.key, required this.catalog, this.unlock});

  @override
  Widget build(BuildContext context) {
    final unlocked = unlock != null;
    final color = unlocked
        ? RarityPalette.of(catalog.rarity).light
        : HyphenTokens.border;
    return Container(
      margin: const EdgeInsets.only(bottom: HyphenTokens.sp3),
      padding: const EdgeInsets.fromLTRB(
        HyphenTokens.sp4,
        HyphenTokens.sp3,
        HyphenTokens.sp4,
        HyphenTokens.sp3,
      ),
      decoration: BoxDecoration(
        color: HyphenTokens.surface,
        border: Border(
          left: BorderSide(color: color, width: 3),
          top: BorderSide(color: HyphenTokens.border, width: 1),
          right: BorderSide(color: HyphenTokens.border, width: 1),
          bottom: BorderSide(color: HyphenTokens.border, width: 1),
        ),
        borderRadius: BorderRadius.circular(HyphenTokens.r2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      koreanTitle(catalog.code).isEmpty
                          ? catalog.name
                          : koreanTitle(catalog.code),
                      style: HyphenTokens.h3.copyWith(
                        color: unlocked ? HyphenTokens.fg : HyphenTokens.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      catalog.name,
                      style: HyphenTokens.caption.copyWith(
                        color: unlocked
                            ? HyphenTokens.muted
                            : HyphenTokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                RarityPalette.of(catalog.rarity).ko,
                style: HyphenTokens.micro.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: HyphenTokens.sp1),
          // v1.16 Sprint 9a: 해금 시 description · 미해금 시 조건 문구.
          Text(
            unlocked ? catalog.description : lockedHint(catalog),
            style: HyphenTokens.caption,
          ),
          if (unlocked) ...[
            const SizedBox(height: HyphenTokens.sp1),
            Text(
              _formatDate(unlock!.unlockedAt),
              style: HyphenTokens.micro.copyWith(color: HyphenTokens.muted),
            ),
          ],
        ],
      ),
    );
  }

  /// 표시용 제목 — 한글 칭호 우선, 없으면 영문 고유명(마침표 제거).
  /// 홈 표·전체 보기 그리드·featured 패널이 모두 이걸 쓴다 (표기 일원화).
  static String displayTitle(AchievementCatalog c) {
    final ko = koreanTitle(c.code);
    return ko.isEmpty ? gridLabel(c.name) : ko;
  }

  /// 잠긴 업적의 조건 문구 — 서버 카탈로그 description 이 정본(SSOT),
  /// 비어 있을 때만 아래 정적 힌트로 폴백. hidden 은 조건 자체를 감춘다.
  /// (v1.30: 정적 힌트가 신규 코드를 못 따라가 "미공개 조건." 이 뜨던 문제 차단.)
  static String lockedHint(AchievementCatalog c) {
    if (c.isHidden) return '· · · (조건 공개 안 됨)';
    final desc = c.description.trim();
    return desc.isEmpty ? triggerHint(c.code) : desc;
  }

  /// v1.16 Sprint 9a: 배지 해금 조건 한글 힌트 (description 부재 시 폴백).
  /// 백엔드 trigger_value JSON 수동 파싱 대신 정적 매핑 (간단·안전).
  static String triggerHint(String code) {
    switch (code) {
      case 'FIRST_ENGINE':
        return '첫 Engine 측정 1회.';
      case 'REACH_RX':
        return 'Tier RX(3) 이상 도달.';
      case 'REACH_RX_PLUS':
        return 'Tier RX+(4) 이상 도달.';
      case 'REACH_ELITE':
        return 'Tier Elite(5) 이상 도달.';
      case 'REACH_GAMES':
        return 'Tier Games(6) 도달.';
      case 'SCORE_80_OVERALL':
        return 'Overall Engine 80 이상 돌파.';
      case 'SCORE_95_OVERALL':
        return 'Overall Engine 95 이상 — Games급.';
      case 'ALL_CAT_80':
        return '전 카테고리 Engine 80 동시 달성.';
      case 'WOD_50':
        return '수업 기록 50회 이상.';
      case 'STREAK_10':
        return '10일 연속 출석.';
      case 'STREAK_30':
        return '30일 연속 출석.';
      case 'GIRLS_5_COMPLETE':
        return 'Girls WOD 5개 이상 완주.';
      case 'GIRLS_ALL':
        return 'Girls WOD 전부 완주.';
      case 'HEROES_3':
        return 'Hero WOD 3개 이상 완주.';
      case 'GAMES_1':
        return 'Games WOD 1개 이상 완주.';
      // v1.16 Sprint 14: 칭호 5개.
      case 'TITLE_POLYMATH':
        return '6 카테고리 Engine 80 동시 돌파.';
      case 'TITLE_OBSESSED':
        return '365일 연속 출석.';
      case 'TITLE_SCHOLAR':
        return 'Overall Engine 80 이상.';
      case 'TITLE_RELENTLESS':
        return '100일 연속 출석.';
      case 'TITLE_UNDEFEATED':
        return '한 주 모든 기록 갱신 (주 7회).';
      // v1.17 Sprint 18: 시즌 한정.
      case 'SEASON_SPRING':
        return '봄(3-5월) Engine 70+ 측정.';
      case 'SEASON_SUMMER':
        return '여름(6-8월) Engine 70+ 측정.';
      case 'SEASON_FALL':
        return '가을(9-11월) Engine 70+ 측정.';
      case 'SEASON_WINTER':
        return '겨울(12-2월) 수업 기록 20회.';
      case 'SEASON_YEAREND':
        return '12월 30일 연속 출석.';
      // v1.17 이스터에그 (잠금 상태에선 hidden).
      case 'EGG_WITCHING':
        return '심야 측정 시 발현.';
      case 'EGG_DOOMSDAY':
        return '특정 날짜 측정 시 발현.';
      case 'EGG_SUNDAY':
        return '주간 패턴 발현.';
      case 'EGG_PI':
        return '특정 점수 도달 시 발현.';
      case 'EGG_TRIPLE':
        return '카테고리 패턴 발현.';
      // v1.17 PR.
      case 'PR_FIRST':
        return '동일 수업 내용 기록 단축 1회.';
      case 'PR_HUNTER':
        return 'PR 10회 누적.';
      case 'PR_LIFT_KING':
        return 'Power/Olympic 카테고리 PR 5개.';
      case 'PR_ENGINE':
        return 'Cardio 카테고리 PR 5개.';
      case 'PR_BODY_IRON':
        return '1RM 체중의 2배 도달.';
      // v1.17 Volume / Discipline.
      case 'VOL_100_WODS':
        return '수업 기록 100회 누적.';
      case 'VOL_200_WODS':
        return '수업 기록 200회 누적.';
      case 'VOL_TRIPLE_STREAK':
        return '3주 연속 주 4회 출석.';
      case 'VOL_COMEBACK':
        return '30일 휴식 후 복귀.';
      case 'VOL_EQUAL':
        return '6 카테고리 70+ 동시.';
      default:
        return '미공개 조건.';
    }
  }

  /// 한글 칭호 매핑 — 업적 고유명(영문)의 한글 대응.
  /// v1.30 (2026-08-06): 서버 카탈로그 56종 전수 커버. 없는 코드는 빈 문자열 →
  /// 호출부가 catalog.name(영문 고유명)으로 폴백한다.
  /// 표기 규칙: 명사형 간결체 · 중복 칭호 금지 · 설명문(description) 반복 금지.
  static String koreanTitle(String code) {
    switch (code) {
      // ── 진입 / Tier 도달 ──
      case 'FIRST_ENGINE':
        return '첫 측정';
      case 'REACH_SCALED':
        return '스케일드 도달';
      case 'REACH_INTERMEDIATE':
        return '중급 도달';
      case 'REACH_RX':
        return 'RX 기준';
      case 'REACH_RX_PLUS':
        return 'RX+ 도달';
      case 'REACH_ELITE':
        return '엘리트 도달';
      // ── Engine 점수 고지 ──
      case 'SCORE_50_OVERALL':
        return '절반 지점';
      case 'SCORE_60_OVERALL':
        return '60 고지';
      case 'SCORE_70_OVERALL':
        return '70 고지';
      case 'SCORE_80_OVERALL':
        return '80 고지';
      case 'SCORE_90_OVERALL':
        return '90 고지';
      case 'ALL_CAT_60':
        return '여섯 기둥';
      case 'HOLY_TRINITY':
        return '세 축 정복';
      // ── WOD 누적 ──
      case 'WOD_10':
        return '첫 열 번';
      case 'WOD_25':
        return '스물다섯';
      case 'WOD_50':
        return '오십 고지';
      case 'WOD_75':
        return '칠십오 통과';
      case 'VOL_100_WODS':
        return '백인대장';
      // ── 연속 출석 ──
      case 'STREAK_3':
        return '사흘 불씨';
      case 'STREAK_7':
        return '일주일 고정';
      case 'STREAK_10':
        return '열흘 투지';
      case 'STREAK_60':
        return '예순 날 습관';
      case 'STREAK_90':
        return '아흔 날 단조';
      case 'VOL_TRIPLE_STREAK':
        return '3주 연속';
      case 'VOL_COMEBACK':
        return '돌아온 자';
      case 'VOL_COMEBACK_60':
        return '불사조';
      // ── 벤치마크 WOD ──
      case 'GIRLS_5_COMPLETE':
        return 'Girls 5연';
      case 'HEROES_3':
        return 'Hero 헌정';
      case 'HEROES_5':
        return 'Hero 베테랑';
      case 'GAMES_1':
        return 'Games 도전';
      // ── 카테고리 숙련 ──
      case 'CAT_POWER_RX':
        return 'Power 숙련';
      case 'CAT_OLYMPIC_RX':
        return 'Olympic 숙련';
      case 'CAT_GYMN_RX':
        return 'Gymnastics 숙련';
      case 'CAT_CARDIO_RX':
        return 'Cardio 숙련';
      case 'CAT_METCON_RX':
        return 'Metcon 숙련';
      case 'CAT_BODY_RX':
        return 'Body 숙련';
      case 'VOL_EQUAL':
        return '균등의 기둥';
      // ── PR ──
      case 'PR_FIRST':
        return '첫 PR';
      case 'PR_HUNTER':
        return 'PR 헌터';
      case 'PR_25':
        return 'PR 추적자';
      case 'PR_LIFT_KING':
        return '리프트 왕';
      case 'PR_ENGINE':
        return '카디오 상승';
      case 'PR_DEADLIFT_2X':
        return 'Deadlift 2배';
      case 'PR_SQUAT_2X':
        return 'Squat 2배';
      case 'PR_SNATCH_BW':
        return 'Snatch 체중';
      // ── 시즌 한정 ──
      case 'SEASON_SPRING':
        return '봄의 약진';
      case 'SEASON_SUMMER':
        return '여름의 엔진';
      case 'SEASON_FALL':
        return '가을의 단련';
      case 'SEASON_WINTER':
        return '겨울의 적재';
      case 'SEASON_YEAREND':
        return '연말의 전사';
      // ── CrossFit 시즌 이벤트 ──
      case 'CF_OPEN_SURVIVOR':
        return 'Open 생존자';
      case 'CF_QUARTERFINAL_GRINDER':
        return 'Quarterfinal 완주';
      case 'CF_SEMIFINAL_WATCH':
        return 'Semifinal 관측';
      // ── 칭호 / 이스터에그 ──
      case 'TITLE_SCHOLAR':
        return '데이터 분석가';
      case 'TITLE_UNDEFEATED':
        return '불패 일주일';
      case 'EGG_TRIPLE':
        return '삼중의 위협';
      // ── 구 시드 코드 (현 카탈로그 미포함 — 다른 환경 호환용 잔류) ──
      case 'REACH_GAMES':
        return '게임스 선수';
      case 'SCORE_95_OVERALL':
        return '정점에';
      case 'ALL_CAT_80':
        return '만능 선수';
      case 'GIRLS_ALL':
        return 'Girls 완수';
      case 'STREAK_30':
        return '서른 날 성실';
      case 'TITLE_POLYMATH':
        return '전 영역 정복';
      case 'TITLE_OBSESSED':
        return '집착하는';
      case 'TITLE_RELENTLESS':
        return '끝을 모르는';
      case 'EGG_WITCHING':
        return '마녀의 시간';
      case 'EGG_DOOMSDAY':
        return '운명의 날';
      case 'EGG_SUNDAY':
        return '일요 리셋';
      case 'EGG_PI':
        return '강철의 원주율';
      case 'PR_BODY_IRON':
        return '강철의 몸';
      case 'VOL_200_WODS':
        return '이백 돌파';
      default:
        // 매핑 없는 코드는 빈 문자열 — 호출부에서 catalog.name(업적 고유명)으로 폴백.
        return '';
    }
  }

  /// 그리드 타일용 단어 라벨 — 마침표 3분류(CLAUDE.md): 단어 1~3개 라벨 = 마침표 없음.
  /// 선언형 원문("First Ten.")은 상세 패널에서만 유지.
  static String gridLabel(String name) =>
      name.replaceAll(RegExp(r'\.+$'), '').trim();

  static String _formatDate(DateTime d) {
    final l = d.gym();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
  }
}
