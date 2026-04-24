# Persona Feedback — v1.15.3 (2026-04-24)

> **Scope**: Shell 5탭 하단 내비 신설 + Trends(변화추이) · Attendance(출석률) 2화면 신규 + Grade 점수 1~6 → 0~100 환산 + 제목 대문자화 + 자간 타이트 + TierBadge 배경 pill 제거 + PopScope 처리.
>
> **Source**: `/go` 파이프라인 (Haiku×3 페르소나 시뮬레이션 + Sonnet×2 코드/벤치마크 교차검증).
>
> **Status**: 이 SSOT 작성 시점 기준 이미 반영 완료된 항목 표시 — `✓ v1.15.3`. 반영 대기 — `□`. 보류(사용자 결정) — `⏸`.

---

## 페르소나 10명 → 피드백 원문

### Tier A: Scaled~RX 진입 (P1~P3) — 진입장벽 관점

| 코드 | 정체성 | 핵심 피드백 |
|---|---|---|
| **P1** Min (28M, Scaled 1년차) | FS 80kg, DU 20. "Engine"/"Split"/"Burst" 용어 모름 | Splash "Games-Player 전용" 문구로 **즉시 이탈 위협**. 첫 측정 22/100은 절망감. 대문자 톤 "차가움/위협적". |
| **P2** Yoon (32F, 진입 RX) | Fran 6분대. 대시보드 3종 사용 중 | Benchmarks 5개 강제 입력에 **skip 충동**. 변화추이에 카테고리별 약점 분석 필요. 출석률은 "WOD 계산 횟수 vs 박스 출석" 혼동. |
| **P3** Daehyun (35M, Scaled→RX 전환기) | Fran 8분, 한글 선호 | "Games-Player 전용" 포지셔닝 반감. 점수 중심 선호 (Tier는 "낙인"). 대문자 전체 "명령적/거리감". |

### Tier B: RX·RX+ 중견 (P4~P6) — 실용성 관점

| 코드 | 정체성 | 핵심 피드백 |
|---|---|---|
| **P4** Jiho (30M, RX 3년차) | Fran 3:45, BS 150 | 매일 여는 탭: 계산기 > 변화추이 > 프로필. **카테고리별 세부 추이 필수**(P0). 출석률 "품질 > 빈도", 오버헤드. |
| **P5** Hana (27F, RX→RX+) | 소규모 경기 출전. 데이터광 | 변화추이 총점만 → 약점 진단 불가(P0). 점수·Tier 이중 표기는 혼동. AppBar 대문자 톤 OK. |
| **P6** Sangwoo (34M, RX+ 정체기) | 5년차, Fran 3:20 | **변화추이 전면 재설계 요구(P0)**: 총점 정체만 봐도 원인 모름. Metcon/Cardio 분리 추적 필요. 출석률 무의미. |

### Tier C: Elite / Games / Masters (P7~P10) — 정보 밀도·가독성 관점

| 코드 | 정체성 | 핵심 피드백 |
|---|---|---|
| **P7** Minho (26M, Elite Regionals 준비) | Fran 2:40, Snatch 120 | 카테고리별 시계열 부재(P0). 점수 0~100 공식 Elite 구간(5~6 → 90~100) 차별력 부족. |
| **P8** Dara (29F, Games 지망 Top 1%) | CGM/HRV/Pacing 다 추적 | History row "Score 5.2 / 날짜"만 보임 → **too terse**. 카테고리 6개 micro chart 필요. |
| **P9** Chulsoo (54M, Masters 50-54, 시력 -2.5) | 박스 10년 | **sectionLabel 11sp + 자간 타이트 위험**(P0). TierBadge 명도만 구분 → WCAG AA 미충족. |
| **P10** Hyejin (48F, Masters 45-49) | 3년차, Scaled 위주, 영문 긴 문장 어려움 | History 탭/라벨 영문 전무. Tier 4개 명도 차이만으로 한눈 구분 어려움. |

---

## Code / Benchmark 교차검증

### Sonnet A (코드 교차검증)
- **HIGH**: 스파크라인 Semantics 누락 / DayCell alt 텍스트 없음 / DayCell 터치 타겟 43.4dp (인터랙션 추가 시 미달)
- **MEDIUM**: `_to100` 중복 정의 / `fontSize: 56, 18` 하드코드 R5 위반 / `sectionLabel` 동적 문자열 `.toUpperCase()` 누락 위험
- **공식 검증**: `engineScoreTo100` 경계 OK (1.0→0, 6.0→100, clamp 정상). `firstWeekday` 일요일 시작 그리드 OK.

### Sonnet B (벤치마크 정합성 — HWPO/NOBULL/Mayhem/CompTrain)
- **CRITICAL**: 탭 한글 라벨 4/4 벤치마크 불일치 → 영문화 필요. **자간 0.2 + 대문자** = HWPO/NOBULL 대문자 tracking(1.0~1.6) 역행.
- **HIGH**: AppBar `변화추이`/`출석률` 영문화. `Score 72 / 100` → NOBULL 관점 과도, 간소화 여지.
- **LOW**: TierBadge 텍스트-온리는 HWPO(장식 제로) + NOBULL(단어 하나) 동시 달성 — 최고 결정.

---

## 분류 · 우선순위

### P0 CRITICAL (즉시 반영 — v1.15.3 당일 완료)

| # | 항목 | 출처 | 상태 |
|---|---|---|---|
| P0-1 | 자간 0.2 → 대문자 가독성 복원 (sectionLabel 1.2 / tierLabel 1.4 / bannerLabel 1.0) | Sonnet B + P9 | ✓ v1.15.3 |
| P0-2 | 탭 라벨 영문화 (Calc · WOD · Trends · Attend · Profile) | Sonnet B | ✓ v1.15.3 |
| P0-3 | AppBar 영문화 (`변화추이` → `TRENDS`, `출석률` → `ATTENDANCE`) | Sonnet B + P10 | ✓ v1.15.3 |
| P0-4 | 변화추이 **카테고리별 mini sparkline** (Power/Olympic/Gymnastics/Cardio/Metcon 5종) | P4/P5/P6/P7/P8 공통 | ✓ v1.15.3 |
| P0-5 | 스파크라인 Semantics wrapper | Sonnet A + WCAG | ✓ v1.15.3 |
| P0-6 | DayCell Semantics wrapper | Sonnet A + WCAG | ✓ v1.15.3 |
| P0-7 | `_to100` 중복 정의 → `lib/core/scoring.dart` 단일화 | Sonnet A | ✓ v1.15.3 |
| P0-8 | `fontSize: 56/18` 하드코드 → `displayCompact` 토큰 + `lead` 교체 | Sonnet A R5 | ✓ v1.15.3 |
| P0-9 | `_SparklinePainter.shouldRepaint` listEquals | Sonnet A | ✓ v1.15.3 |
| P0-10 | `MainShell._pages` const 상수화 | Sonnet A | ✓ v1.15.3 |

### P1 HIGH (다음 Sprint 권장)

| # | 항목 | 출처 | 상태 |
|---|---|---|---|
| P1-1 | History row에 카테고리 6개 micro chart/profile snap 추가 | P8 Dara | □ |
| P1-2 | Grade 0~100 **비선형 환산** 검토 (Elite 5~6 구간 차별력 회복) | P7 Minho | □ |
| P1-3 | Masters 가독성 — caption 13→14sp / micro 11→12sp 상향 or 토글 | P9/P10 | □ |
| P1-4 | TierBadge 색상 + 1글자 코드(S/R/P/E/G) 추가 — 명도만 의존 탈피 | P10 Hyejin | □ |
| P1-5 | Benchmarks 화면 per-field **Skip 버튼** 추가 (현재는 "빈 칸 자동 추론"만) | P1/P2 | □ |
| P1-6 | Shell 첫 진입 시 **계산기 탭 default 포커싱** (변화추이는 데이터 없으면) | P1~P3 | □ |
| P1-7 | 변화추이 탭에 **약점 카테고리 명시** 배너 ("약점: CARDIO 48") | P6 Sangwoo | □ |
| P1-8 | Day cell 터치 타겟 확보 (향후 상세 보기 추가 전) | Sonnet A H3 | □ |
| P1-9 | home_screen.dart orphan 정리 (라우트 `/home` 삭제 or deprecated 주석) | Sonnet A M5 | □ |

### P2 MEDIUM (여유 시 반영)

| # | 항목 | 출처 | 상태 |
|---|---|---|---|
| P2-1 | Score 표기 `Score 72 / 100` → `ENGINE 72` 또는 `ENGINE: 72` (슬래시 제거) | Sonnet B | ⏸ 사용자 결정 (현재 "100점만점" 명시 요청 반영 중) |
| P2-2 | YOUR TIER Bodoni italic serif 재검토 (HWPO/NOBULL 모두 이질) | Sonnet B | ⏸ 브랜드 SSOT |
| P2-3 | Attendance 캘린더 미래 월 이동 제한 | 사전 식별 | □ |
| P2-4 | 중앙 탭 back 1회 종료 → 2-tap exit 패턴 고려 | 사전 식별 | □ |
| P2-5 | 탭별 첫 실행 시 1줄 설명 오버레이(tooltip) | P1 Min | □ |

---

## 보류 결정사항 (사용자 컨펌 필요)

### D1. Splash 포지셔닝 — "Games-Player 전용" 유지 여부
- **영향**: P1 Min / P3 Daehyun 즉시 이탈 (Scaled 대상자는 브랜드가 자기 배제로 해석)
- **현재**: CLAUDE.md 브랜드 포지셔닝 SSOT에 명시 ("CrossFit Games-Player 전용 WOD Pacing")
- **대안 A**: 유지 — 브랜드 일관성 / 타깃 집중
- **대안 B**: "Scaled에서 Games까지. 당신의 Tier를 찾는다." 로 완화 — 진입 장벽 완화
- **권장**: B로 완화. 내부 엘리트 톤은 유지하되 진입 문턱 낮춤. 사용자 결정 요청.

### D2. 출석률 탭 용도 재정의 — "WOD 계산 vs 박스 출석"
- **현재**: `/api/v1/history/wod` 기록(WOD 계산 1회 = 1 세션)을 "출석"으로 카운트
- **문제**: P2/P3/P4 전원 "박스 출석"으로 오해. "계산 안 해도 운동함" / "계산만 하고 운동 안 함" 괴리.
- **대안 A**: 이름을 `SESSIONS` 또는 `ACTIVITY`로 변경 — 의미 명확화
- **대안 B**: 탭 제거. Trends 하위로 병합 (Sangwoo: "출석은 무의미").
- **권장**: A (이름 변경 `Attend` → `Activity`, AppBar `ATTENDANCE` → `ACTIVITY`). 제거는 MVP 후 리뷰.

### D3. Grade 점수 0~100 비선형 환산
- **현재**: 선형 `((s-1)/5)*100`. Elite 5.0→80, 6.0→100 → 상위 구간 차별력 부족.
- **대안 A**: 유지 — 모든 구간 일관
- **대안 B**: Power law scale (감마 0.5~0.7) — 하위 구간 압축, 상위 구간 확장
- **대안 C**: 등급별 구간 고정 (Scaled 0~30, RX 31~60, RX+ 61~80, Elite 81~92, Games 93~100)
- **권장**: C (구간 고정). Elite/Games 사용자에게 더 의미 있는 점수, 진입자에게도 목표 명확. 수식 변경이라 v1.16 별도 논의.

### D4. 카테고리별 시계열 확장 — Trends 탭 Tab 구조로
- **현재 v1.15.3**: 카테고리 5종 mini sparkline (28sp 높이) 1줄씩
- **Dara/Minho 요구**: 각 카테고리 **전체 스파크라인** (140sp 높이) + 히스토리
- **대안 A**: 현재 mini 유지, 탭하면 카테고리 상세 화면 푸시
- **대안 B**: Trends 상단에 `Overall / Power / Olympic / Gymnastics / Cardio / Metcon` 6탭 HorizontalScroll
- **권장**: A (다음 Sprint). B는 정보 밀도 과부하 위험.

---

## Sprint 로드맵 권장

**Sprint 3 (현재 종료)**: v1.15.3 P0 10건 완료 — 위 SSOT대로.

**Sprint 4 (다음)**: P1 9건 + 보류 결정 D1/D2 반영. 특히 —
- P1-1 History row 카테고리 profile snap
- P1-4 TierBadge 색+코드
- P1-5 Benchmarks per-field Skip
- P1-6 Shell 첫 진입 계산기 포커싱
- D1 Splash 포지셔닝 (결정 후)
- D2 Attend → Activity (결정 후)

**Sprint 5 (v1.16 후보)**: D3 비선형 환산 + D4 카테고리 탭 구조 + Masters 접근성 패키지(D3/P1-3/P1-4 합침).

---

## 관련 문서

- 이전 피드백: `docs/PERSONA_FEEDBACK_v1.15.md`
- 브랜드 SSOT: `CLAUDE.md` (v1.12.0 Games-Player 포지셔닝)
- 비주얼 SSOT: `docs/VISUAL_CONCEPT.md` v1.0
- 타이포 토큰: `lib/core/theme.dart` (v1.15.3 `displayCompact` 신규)
- 점수 환산 단일 진원지: `lib/core/scoring.dart` (v1.15.3 신규)
