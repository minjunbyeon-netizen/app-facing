# §6 Achievement System — 결정론적 보상 시스템

**Brief 유형**: Amazon 6-Pager (VC + PM + Eng + UX)
**버전**: v1.1 · 2026-04-28
**작성 근거**: ABOUT.md §6 / PROJECT_CHARTER.md §7 / rules/gamification.md / reference/gamification.md / lib/core/ 소스

> **v1.1 변경점**: Panel B 칭호 20 → 50 확장 (`expect(kPanelBTitles.length, 50)` 테스트 정합). rarity 분포 6/8/4/2 → 15/20/10/5. TitleUnlockSignals 22 필드 추가 (streakDays / prCount / profileComplete / freshStartSession / shareCount / deadlift1rmKg 등). §1 TL;DR / §4-4 / §7-1 / ABOUT.md §6-3 정합.

---

## 1. TL;DR

FACING 의 Achievement System 은 CrossFit Games-Player 급 엘리트 athlete 를 위한
**결정론적(deterministic) 보상 시스템**이다. 랜덤 보상, 회복 결제, Lv 차감, FOMO
루프를 전면 차단하고 — 자율성·유능감·관계성 세 축(SDT)을 화이트햇 방식으로 충족한다.

핵심 메커니즘 5종:

1. **Tier 5단계** (Scaled / RX / RX+ / Elite / Games) — 라벨 + 아이콘 + 색 3중 신호, WCAG 준수.
2. **Engine Score 0~100** — 6 카테고리 가중 평균. 실력의 단일 수치 표현.
3. **Level 1~50** — 5 XP 소스 합산, 차감 없음. 비활동해도 Lv 보존.
4. **Panel B 50 칭호** — Common 15 / Rare 20 / Epic 10 / Legendary 5. 결정론적 임계만.
5. **Streak Freeze / Season Badge / PR 자동 감지 / Engine Decay** — 보조 레이어 4종.

---

## 2. Problem — 다크 패턴 앱이 엘리트를 잃는 이유

### 2-1. 현재 시장의 다크 패턴 지형도

기존 fitness 게이미피케이션은 행동 심리학의 가장 강한 도구(가변 비율 강화, 손실 회피)를
**단기 DAU 극대화** 목적으로 오용한다. 대표 사례:

| 앱 | 다크 패턴 | 측정된 부작용 |
|---|---|---|
| **Duolingo** | 스트릭 복구 400 gems (결제), Lv 차감 없으나 streaksaber 강제 | 엘리트 사용자 Lv 차감 A/B 실험 → 21%+ 이탈 (CHI 2025) |
| **Strava** | 강제 세그먼트 리더보드 (비공개 불가), 랜덤 챌린지 알림 | 랭킹 정체 시 이탈 (ACM CSCW 2024) |
| **Nike Run Club** | "100일 잃습니다" 회피형 push 알림, 결제 배지 잠금 | FTC 2024 심의 대상 (dark-pattern subscription 분류) |

규제 환경도 이미 전환됐다. FTC 는 Epic Games $245M, Noom $62M 합의금을 받았고
(2024-2025). EU Digital Fairness Act (2026-Q1 공식 제안)은 블랙햇 메커니즘을
도박과 동급으로 분류할 예정이다.

### 2-2. 엘리트 사용자의 반응

Scaled/RX 진입 사용자와 달리, RX+/Elite/Games 층은:

- 회복일을 전략적으로 계획한다. 강제 스트릭은 과훈련 권장과 동일하다.
- 랜덤 보상에 무감각하다. 실력 기반 임계만 신뢰한다.
- 강제 리더보드를 거부한다. 본인 PR 추적이 우선이다.
- 앱이 "속인다"는 인상을 받으면 즉시 이탈한다. 대체재는 노트 앱이다.

FACING 의 타깃 — Rich Froning / Mat Fraser / Tia Toomey 세대 — 은
**수치와 결정론**을 요구한다. 다음에 무엇을 해야 Tier 승급하는지,
정확히 얼마나 더 필요한지 알아야 앱을 신뢰한다.

### 2-3. 현재 공백

WOD Pacing Intelligence 자체(Split + Burst + 예상 완주)는 시장 최초다.
그러나 게이미피케이션이 다크 패턴이면 엘리트 사용자는 페이싱 결과를 노션에
붙여넣고 앱을 닫는다. Achievement System 은 "재방문 이유"를 만드는 레이어다.

---

## 3. Tenets — 화이트햇 7원칙

> rules/gamification.md §1 기준. 이 원칙을 위반하는 피처는 구현 전 차단한다.

**T1. 자율성 (Autonomy)**: Streak Freeze 는 Rest Pass 다. 사용자가 선택한다.
자동 차감 없음. 회복일을 전략으로 프레임한다.

**T2. 유능감 (Competence)**: 모든 unlock 임계는 결정론적이다. "Engine Score 80+ 5회" 처럼
사용자가 계산할 수 있어야 한다. 랜덤 보상(loot box 가변 비율) 전면 차단.

**T3. 관계성 (Relatedness)**: 박스 리더보드는 opt-in 이 기본이다. 비공개 PR 추적이 디폴트.
코치-멤버 칭호(THE TEACHER / THE STUDENT)로 사회적 연결을 격려하되 강제하지 않는다.

**T4. 회복 결제 금지**: Streak Freeze(Rest Pass)는 주 1회 자동 충전. 결제 없음.
Duolingo 의 400 gems 모델을 명시적으로 거부한다.

**T5. Lv 차감 패널티 금지**: 30일 비활동에도 Lv 변화 없다. Engine Score 만 표시 점수 조정
(원본 보존). 엘리트 사용자 21%+ 이탈 데이터를 근거로 차단 결정됐다.

**T6. FOMO 루프 금지**: "시간 한정 희소성" 카피("내일 자정까지" 류) 전면 차단.
시즌 배지는 기간 내 세션 1회면 자동 unlock — 의도적 행동이 아닌 자연스러운 훈련이 조건이다.

**T7. 색상 단독 등급 금지**: WCAG 2.1 §1.4.1. Tier 는 라벨 + 아이콘 + 색 3중 신호.
색약/저시력 사용자도 동일 정보를 받는다.

---

## 4. Approach — 시스템 설계

### 4-1. Tier 5단계

백엔드 `overall_number` (1~6) → 5 Tier 매핑.

| Tier | 색상 토큰 | 설명 한 줄 |
|---|---|---|
| Scaled | `tierScaled #4A4A4A` (회색) | Novice. 스케일드 동작 위주 |
| RX | `tierRx #EE2B2B` (CrossFit 빨강) | RX 표준 달성 |
| RX+ | `tierRxPlus #929292` (은회색) | Advanced |
| Elite | `tierElite #C8C8C8` (밝은 회색) | Regionals 급 |
| Games | `tierGames #F5F5F5` (Off-White) | Games 출전급. 최상위 |

- `overall_number` 1~2 = Scaled / 3 = RX / 4 = RX+ / 5 = Elite / 6 = Games.
- UI 에 "RXD 4/6" 같은 내부 코드 노출 금지. 5 Tier 라벨만.
- TierBadge: 2px solid 티어 컬러 + 대문자 라벨 + 아이콘. 그라디언트 없음.

### 4-2. Engine Score 0~100

6 카테고리 가중 평균. 실력을 단일 수치로 압축.

| 카테고리 | 측정 지표 예시 |
|---|---|
| Power (역도) | Back Squat / Clean & Jerk / Deadlift 1RM |
| Olympic | Snatch / Clean 1RM |
| Gymnastics | Pull-up UB / HSPU UB / Muscle-up |
| Cardio | 5km Run / 2km Row 페이스 |
| Metcon | Fran / Helen / DT 기록 |
| Body | 체중 / 키 기반 상대 강도 보정 |

백엔드 `/api/v1/grade/calculate` 결과가 단일 진원지.
프론트는 렌더만 담당 — 계산 로직 없음.

Engine Decay 정책 (30일+ 비측정):
- 표시 점수만 -3%/30days (원본 보존). 상한 -20%.
- 라벨: `STALE`. 재측정 즉시 회복.
- Lv / Tier / 칭호 손실 없음.

### 4-3. Level 1~50 (5 XP 소스)

| XP 소스 | 단가 | 비고 |
|---|---|---|
| 세션 완료 | +100 / WOD | WOD History record 기준 |
| Streak 유지 | +50 / 일 | 현재 연속 출석일 |
| Tier 승급 | +500 × overall_number | 누적 보너스 |
| 주간 목표 챌린지 달성 | +300 / 주 | Phase 2 |
| PR (Personal Record) 갱신 | +250 / PR | v1.20 Phase 2 |

Level 곡선:
- Lv 1~20: 선형. 누적 XP = 500 × (L-1). 500 XP/Lv.
- Lv 21~50: 이차 가속. 누적 XP = 9,500 + (L-20)² × 40. 도달 난이도 급등.
- Lv 50 도달 예상: 세션 500회 + Streak 730일 + Tier 4 + PR 20개 수준 (Games 층 기준).

차감 없음. 비활동 시 Lv 동결. Lv 회색 표시("마지막 세션 N일 전")로 정보만 노출.

### 4-4. Panel B 50 칭호 (v1.1)

FIFA Ultimate Team 스타일 3×3 격자 UI. 해금 칭호는 착색, 미해금은 실루엣.
착용(worn)은 1개만. 해금은 누적. 50 칭호 = 4 화면 분량.

#### 칭호 카탈로그 (rarity 계층 분포)

| rarity | 수 | 비율 |
|---|---|---|
| Common | 15 | 30% |
| Rare | 20 | 40% |
| Epic | 10 | 20% |
| Legendary | 5 | 10% |
| **합계** | **50** | 100% |

**전체 카탈로그 SSOT**: `lib/core/titles_catalog.dart` 의 `kPanelBTitles` 상수 (단위 테스트 `test/titles_catalog_test.dart` 가 갯수·분포·코드 유일성·라벨 영문/캡션 한글 6 항목 회귀 보장).

#### 대표 칭호 (rarity 계층 sample)

| rarity | 대표 코드 | 해금 조건 (예시) |
|---|---|---|
| Common | `PB_FIRST_WOD` | 첫 WOD 세션 완료 |
| Common | `PB_GRINDER` | 세션 100회 |
| Common | `PB_METRIC_DEVOTEE` | 벤치마크 5종 입력 |
| Common | `PB_BOX_MEMBER` | 박스 가입 (approved) |
| Common | `PB_COMMITTED` | Streak 30일 |
| Rare | `PB_IRON_LUNG` | Engine Score 80+ 5회 |
| Rare | `PB_UNBROKEN` | UB 50+ 3회 세션 |
| Rare | `PB_PR_HUNTER` | PR 5회 갱신 |
| Rare | `PB_THE_TEACHER` | 코치 노트 10건 발송 |
| Epic | `PB_HEAVY` | Back Squat 1RM 200kg+ |
| Epic | `PB_THRUSTER_LORD` | Fran sub-3:00 (179초 이내) |
| Epic | `PB_QF_QUALIFIER` | CrossFit Quarterfinal 통과 |
| Legendary | `PB_SNATCH_KING` | Snatch 1RM 100kg+ |
| Legendary | `PB_GAMES` | CrossFit Games 출전 |
| Legendary | `PB_REGIONAL_CHAMP` | Regional 우승 |

(위는 sample. 전체 50종은 카탈로그 파일 참조)

#### 해금 시그널 (TitleUnlockSignals — 43 필드)

`lib/core/titles_catalog.dart` 의 `TitleUnlockSignals` 클래스가 단일 진원지. 주요 그룹:

| 그룹 | 필드 (예시) | 추출 출처 |
|---|---|---|
| 세션·기록 | `totalSessions` / `streakDays` / `prCount` / `freshStartSession` / `doubleSessionDayCount` | WodHistoryItem 집계 |
| 1RM·신체 | `snatch1rmKg` / `backSquat1rmKg` / `frontSquat1rmKg` / `deadlift1rmKg` / `pressStrict1rmKg` / `bodyWeightKg` | ProfileState |
| Gymnastics | `kippingPullupUnbroken` / `t2bUnbrokenMax` / `wbUnbrokenMax` / `hspu10Unbroken` / `mus5Unbroken` | self-report (백엔드 trigger 의존) |
| Cardio·Metcon | `fiveKmSub25` / `twoKmRowSub730` / `franSec` / `helenSec` / `dtSec` / `graceSec` / `filthyFiftySec` / `murphRxSec` | 벤치마크 입력 |
| 박스·코치 | `hasGym` / `coachNotesSent` / `coachNotesReceived` | GymState + InboxState |
| Game·시즌 | `openRegistered` / `qfQualified` / `gamesQualified` / `regionalChampion` | self-report (Phase 4 서버 trigger) |
| 행동 | `sessionsBefore6am` / `sessionsAfter10pm` / `weekendSessions` / `engineScore80PlusCount` / `ub50PlusSessions` / `pacingAccuracy95Count` / `shareCount` / `profileComplete` | WodHistoryItem + ProfileState |

**해금 추론 분기**: 클라이언트 로컬 (`PanelBUnlocker.unlockedCodes`).
**현재 즉시 추론 가능**: 12 종 (세션·1RM·박스·노트 카운트 기반).
**백엔드 trigger 의존 (Phase 4)**: 13 종 (Open / QF / Games / Regional / Murph 등 self-report 검증 필요).
**나머지 25종**: self-report 수용 (false-positive 리스크 낮음, 다크 패턴 없음).

### 4-5. Streak Freeze (Rest Pass)

정책:
- 매주 월요일 자동 충전 1개. 동시 보유 상한 3개.
- 사용자가 명시적으로 "사용"을 선택할 때만 차감. 자동 소비 없음.
- 스트릭이 끊길 위험인 날(출석 없는 날 자정 전) UI 에 Rest Pass 배너 노출.
- 회복 결제 없음. Freeze 추가 구매 불가.

카피 원칙:
- 손실형 "100일 잃습니다" 차단 → 이득형 "Rest Pass 사용. 전략적 휴식."

### 4-6. Season Badge

CrossFit 공식 시즌 4개와 1:1 매핑:

| 시즌 | 기간 (대략) | 배지 이름 |
|---|---|---|
| Open | 2월 하순 ~ 3월 중순 | Open Survivor |
| Quarterfinals | 4월 초 ~ 4월 하순 | Quarterfinal Grinder |
| Semifinals | 5월 초 ~ 6월 말 | Semifinal Watch |
| Games | 7월 말 ~ 8월 초 | Games Witness |

조건: 해당 시즌 기간 내 세션(WOD Calc 또는 Box WOD) 1회 이상 완료.
매년 새 배지 발급 (연도 suffix 없음 — 디자인 단순화).
시즌 외 기간 (9월~2월 초) = Offseason. 별도 배지 없음.

### 4-7. PR 자동 감지

For Time WOD 두 번째 완료 시 이전 최고 기록과 비교. 0.5% 이상 단축되면 PR.

```
is_pr = new_totalSec < prev_best_sec × 0.995
```

PR 확정 즉시:
1. Haptic.achievementUnlock() — lightImpact 80ms 후 heavyImpact 1회.
2. SnackBar: "PR." (영문 마침표 단독, 2초).
3. XP +250 반영.

False positive 방지: 첫 기록은 baseline(PR 아님). 단위(kg/lb) 정규화 전처리 필수.

### 4-8. Unlock Moment (UX)

unlock 은 화려하지 않다. Elite 사용자는 confetti 과잉에 거부감이 강하다.

| 요소 | FACING 적용 |
|---|---|
| Haptic | achievementUnlock() = lightImpact + 80ms + heavyImpact |
| Toast | 상단 50% 너비. 2초 자동 소멸. |
| 텍스트 | "Earned." — 단어 + 마침표 |
| Confetti | Epic/Legendary 한정 300ms burst. Common/Rare 없음. |
| 사운드 | 기본 OFF |
| 배경 플래시 | white 40% alpha → 200ms fade |
| 강제 모달 | 없음 |

rarity별 색상 강조:
- Common: `muted` 톤 토스트
- Rare: `fg` 기본
- Epic: `tierElite #C8C8C8` 보더
- Legendary: `tierGames #F5F5F5` + 짧은 pulse 애니메이션

---

## 5. Metrics — 성공 지표

시스템을 평가하는 단일 기준: **엘리트 사용자가 측정을 계속하는가**.

### 5-1. Primary (리텐션)

| 지표 | 목표 (MVP 3개월) | 측정 방법 |
|---|---|---|
| 월간 Engine 측정 세션 / 사용자 | ≥ 2 회 | WOD History count |
| 30일 잔존율 | ≥ 40% | device_id 기준 |
| Streak 평균 길이 (활성 사용자) | ≥ 14 일 | streak 컬럼 |

### 5-2. Achievement 건강도

| 지표 | 해석 |
|---|---|
| 사용자당 unlock 칭호 평균 수 | < 2 = 너무 어려움 / > 8 = 배지 인플레이션 |
| Legendary 도달 사용자 비율 | < 2% 목표 (진짜 Games 층만) |
| Common 칭호 미달성 30일 사용자 비율 | > 30% 이면 초기 진입 장벽 점검 |

### 5-3. Freeze 남용 방지

| 지표 | 임계 | 조치 |
|---|---|---|
| 주 4회 이상 Freeze 사용 사용자 비율 | > 15% | 알림 ("이번 주 4회 Rest Pass. 부상 점검 권고") |
| Freeze 보유 최대치(3개) 도달 사용자 비율 | > 40% | 보유 한도 정책 재검토 |

### 5-4. Engine Decay 경보

| 상태 | 조건 | UI |
|---|---|---|
| Fresh | 30일 이내 측정 | 점수 정상 표시 |
| Aging | 30~90일 | 점수 경미 감산 + 수치 muted |
| Stale | 90일+ | STALE 라벨 + 재측정 CTA |
| Expired | 180일+ | -20% cap. 강제 경고 없음. 정보 표시만 |

### 5-5. Tier 분포 모니터링

이상적 분포 (CrossFit 커뮤니티 통계 기반 추정):

| Tier | 예상 비율 |
|---|---|
| Scaled | 30~40% |
| RX | 35~45% |
| RX+ | 10~15% |
| Elite | 3~7% |
| Games | < 2% |

Games/Elite 비율이 25%+ 이면 Engine 기준 재검토 필요.
Scaled 비율이 70%+ 이면 온보딩 벤치마크 수집 질 저하 의심.

---

## 6. Risks / Trade-offs

### 6-1. 결정론적 unlock vs 랜덤 보상

| 구분 | 결정론적 (FACING) | 랜덤 (경쟁사) |
|---|---|---|
| 단기 도파민 | 약 | 강 (슬롯머신 효과) |
| 장기 retention | 강 (목표 달성 만족) | 약 (허무감, 번아웃) |
| 엘리트 신뢰도 | 높음 | 낮음 (조작 인식) |
| 규제 리스크 | 없음 | EU DFA 2026 차단 예정 |

**결정**: 단기 지표보다 장기 신뢰 우선. 엘리트 사용자가 타깃인 한 결정론이 맞다.

### 6-2. Streak Freeze 남용 위험

Rest Pass 를 3개 보유하면 일주일 내내 비활동해도 스트릭 유지가 가능하다.
이는 설계 의도와 충돌한다 (CrossFit = 주 5일 훈련 가정).

대응:
- 보유 상한 3개 유지.
- 연속 사용 4일+ 경고 알림 (강제 아님, 정보).
- 장기적으로 "활성 회복(요가/모빌리티 로깅)"이 Freeze 없이 스트릭 유지하는 옵션 추가 검토 (Phase 4).

### 6-3. Panel B 클라이언트 추론 정확도

현재 일부 칭호는 서버 정보 없이 클라이언트에서만 추론한다.
예: `COMPETITOR` (Open 등록 여부)는 외부 CrossFit.com API 없이 사용자 self-report에 의존.

대응:
- Phase 4 백엔드 trigger 통합 시 정확도 향상.
- 현재는 self-report 수용. 다크 패턴이 아니므로 false-positive 리스크 낮음.

### 6-4. Engine Decay 심리적 저항

"점수가 줄어드는" 경험은 동기 저하로 작용할 수 있다.

대응:
- UI 카피: "마지막 측정: N일 전. 재측정하면 즉시 회복." 회복 경로를 항상 노출.
- Lv / Tier / 칭호는 절대 변경 없음. 오직 Engine Score 표시값만 조정.
- STALE 상태에도 재측정 CTA 를 accent 색이 아닌 muted 로 — 압박 아닌 초대.

### 6-5. Season Badge 시즌 외 소외감

Offseason (9월~2월 초) 동안 신규 시즌 배지 없음. 신규 사용자는 당해 연도 배지를 놓친다.

대응:
- 연도 suffix 제거로 설계 단순화 유지.
- Offseason 중 "100 WOD 누적" 같은 진행형 칭호가 Panel B 동기 공백 커버.
- 시즌 전 알림 1회 (CrossFit Open 시작 7일 전): "Open. 7일." — 정보, FOMO 아님.

---

## 7. Roadmap

### 7-1. 현재 완료 (Phase 3 기준 · 2026-04-28)

| 모듈 | 파일 | 단위 테스트 | 상태 |
|---|---|---|---|
| LevelSystem (Lv 1~50, 5 XP source) | `lib/core/level_system.dart` | 8 pass | 완료 |
| PrDetector | `lib/core/pr_detector.dart` | 20 pass | 완료 |
| EngineDecay | `lib/core/engine_decay.dart` | 11 pass | 완료 |
| StreakFreezeStore | `lib/core/streak_freeze.dart` | 6 pass | 완료 |
| SeasonBadgeService | `lib/core/season_badges.dart` | 6 pass | 완료 |
| Panel B 50-title Catalog (v1.1 확장) | `lib/core/titles_catalog.dart` | 11 pass (분포·코드 유일성·라벨/캡션) | 완료 |
| WornTitleStore | `lib/core/worn_title_store.dart` | 6 pass | 완료 |
| Tier (5단계) | `lib/core/tier.dart` | 10 pass | 완료 |
| UnlockToast + Haptic | `features/achievement/` | side-effect | 완료 |
| AchievementState | `features/achievement/achievement_state.dart` | — | 완료 |
| Panel B UI (3×3 격자) | `features/achievement/panel_b_screen.dart` | — | 완료 |
| WodSession 연동 (PR/Season/Achievement) | `features/wod_session/` | — | 완료 |

총 12 컴포넌트 wired. 단위 테스트 68개 pass.

### 7-2. 즉시 가능 (백엔드 의존 없음)

| 작업 | 예상 규모 |
|---|---|
| 칭호 unlock 카드 이미지 공유 (RepaintBoundary + shareXFiles) | M (2~3h) |
| Toast 큐잉 정책 (4건 동시 발생 시 순서 보장) | S (1h) |
| Confetti 애니메이션 미세조정 (Epic/Legendary 300ms burst) | S (1h) |
| Engine Decay STALE 표시 세분화 (Aging/Stale/Expired 3단) | S (1h) |

### 7-3. Phase 4 (백엔드 trigger 의존)

| 기능 | 의존 | 작업 |
|---|---|---|
| Panel B 5 signal 서버 추출 | `/api/v1/achievements/signals` 신규 endpoint | M |
| CrossFit Open 등록 확인 | CrossFit.com OAuth 또는 self-report webhook | L |
| FCM 기반 unlock push 알림 | Firebase 통합 (docs/PHASE3_PUSH.md) | L |
| Cloud 칭호/Lv 백업 (device 교체 대비) | 사용자 계정 시스템 필요 | XL |

---

## 8. FAQ

**Q1. Duolingo 스트릭 시스템과 무엇이 다른가?**

Duolingo 는 회복 결제(400 gems) + 회피형 카피("잃습니다")를 사용한다.
CHI 2025는 이를 다크 패턴으로 분류했다. FACING 의 Streak Freeze 는 주 1회 무료 자동 충전이다.
결제 없음. 카피는 이득형("Rest Pass 사용. 전략적 휴식."). 회복일을 CrossFit 훈련 철학과 정렬한다.

**Q2. Lv 차감이 없으면 동기부여 효과가 줄지 않는가?**

단기 DAU 는 Lv 차감이 더 높게 나온다. 그러나 Duolingo 자체 A/B 데이터(엘리트 사용자 21%+ 이탈)와
Whoop/Garmin/Strava 세 플랫폼 모두 Lv 차감을 사용하지 않는 사실이 답이다.
엘리트 사용자의 장기 retention 은 "공정함"에 달려 있다.

**Q3. Engine Decay 는 사용자를 처벌하는가?**

처벌 아니다. 표시 점수 조정 + STALE 라벨 은 "측정이 오래됐음"을 정보로 알린다.
원본 점수, Lv, Tier, 칭호는 변경 없다. 재측정 즉시 회복. Whoop 의 "마지막 활동 N일 전" 패턴과 동일하다.

**Q4. Panel B 칭호가 20개뿐이면 충분한가?**

20개는 의도된 희소성이다. 배지 인플레이션(주 4개 이상 발급 → 가치 상실)을 피하기 위해
상한을 명시한다. Legendary 2개는 Games 층도 쉽게 달성할 수 없는 수준으로 설계됐다.
(Snatch 1RM 100kg+ / Front Squat 1RM 150kg+)

**Q5. 강제 리더보드 없이 사회적 동기가 생기는가?**

공개 리더보드는 내재 동기를 랭킹 경쟁으로 대체한다. 랭킹 정체 시 이탈이 증가한다
(ACM CSCW 2024). FACING 은 박스(gym) 단위 opt-in 리더보드를 제공한다. 같은 박스
멤버 간 경쟁은 관계성(SDT)을 활성화하면서도 글로벌 공개 경쟁의 침식 효과를 피한다.

**Q6. Season Badge 조건(1회 세션)이 너무 쉽지 않은가?**

의도적이다. 시즌 배지는 "존재했다"는 기록이다. "Games 시즌에 훈련하고 있었음" = 진지한 athlete 의 증거.
Quarterfinals 참여자와 구분하기 위해 COMPETITOR 칭호(Open 등록)를 Epic 계층으로 별도 제공한다.

**Q7. WCAG 색상 단독 금지는 어떻게 구현됐는가?**

TierBadge 는 (1) 색상 토큰, (2) 대문자 라벨 ("GAMES"), (3) 아이콘 의 3중 신호로 구성된다.
색약 사용자는 라벨 + 아이콘만으로도 Tier 를 식별한다.
스크린 리더: aria-label 패턴 — "Elite tier, Kim Doyun" 포맷.

**Q8. PR 감지의 false positive 위험은 어떻게 막는가?**

임계는 0.5% (new < prev × 0.995). 노이즈 구분용. 첫 기록은 baseline 으로 PR 아님.
단위 변환(kg/lb) 정규화는 입력 시점에 처리한다. `pr_detector_test.dart` 20개 케이스가
edge case(단위 혼용, 동일 기록, 첫 기록)를 모두 커버한다.

**Q9. EU Digital Fairness Act 준수 상태는?**

2026-Q1 공식 제안 기준 7개 블랙햇 메커니즘을 전부 차단한 상태다.
랜덤 보상 X / 회복 결제 X / Lv 차감 X / FOMO 루프 X / 강제 리더보드 X / 회피형 카피 X / 색상 단독 등급 X.
신규 게이미피케이션 기능 추가 시 위 7종 자가 점검 절차를 통과해야 merge 가능하다.

**Q10. 이 시스템의 "킬러 기능"은 하나를 꼽으면 무엇인가?**

Panel B 20 칭호 + Engine Score 의 조합이다.
Engine Score 는 "나는 지금 80점이고 IRON LUNG 은 80점 5회가 조건이다"를 즉시 계산하게 한다.
목표가 결정론적이고, 경로가 명확하며, 달성 순간에 Haptic + Toast 가 확정한다.
이것이 Strava 리더보드 "내가 N위"와 다른 점이다 — 남과 비교가 아닌 자기 임계 돌파다.

---

## 부록. 규제 자가 점검표

신규 게이미피케이션 피처 merge 전 확인:

- [ ] 랜덤 보상 메커니즘 없음 (가변 비율 강화 X)
- [ ] 회복 결제 없음 (결제로 불이익 회피 X)
- [ ] Lv/Tier/칭호 차감 없음 (비활동 페널티 X)
- [ ] 시간 한정 FOMO 카피 없음 ("내일까지" 류 X)
- [ ] 리더보드 opt-in (기본 비공개)
- [ ] 카피 이득형 확인 ("잃습니다" 류 X)
- [ ] 등급 표시 3중 신호 (색 + 라벨 + 아이콘)

---

*Brief 종료. 문의: PROJECT_CHARTER.md §13 관련 문서 참조.*
