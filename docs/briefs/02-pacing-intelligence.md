# §2 Pacing Intelligence — 6-Pager

> **FACING · Internal Brief · 2026-04-28**
> 독자: VC · PM · Eng. 본 문서는 Pacing Intelligence 의 원리·수치·로드맵을 단일 진원지로 정리한다.

---

## 1. TL;DR

WOD 가 주어진 즉시 — 헬멧을 쓰기 전 — Split 패턴과 Burst 시점과 예상 완주 시간을 받는다.
FACING 은 6 개 Engine 카테고리(Power / Olympic / Gymnastics / Cardio / Metcon / Body)로 측정한
사용자 역량을 Tier(Scaled → Games)로 매핑하고, Tier·WOD 타입·시간 영역을 3축으로 교차한
결정론적 알고리즘으로 결과를 산출한다. 외부 LLM 없음. 응답 1.8초. WODsmith·SugarWOD 처럼
"기록만" 관리하는 경쟁 앱은 시작 전 전략을 주지 않는다. 이것이 FACING 의 유일한 1순위 가치다.

---

## 2. Problem — 페이싱 없이 WOD 에 진입하면 생기는 일

### 2-1. 전형 시나리오

Fran (21-15-9 Thruster + Pull-up). RX 기준 65lb(남) / 35lb(여).
첫 라운드 21 Thruster 를 Unbroken 으로 질러버린다.
심박 170+ 로 치솟고, 두 번째 라운드 15개에서 7-5-3 으로 쪼개진다.
마지막 9개는 2-2-2-2-1. 완주는 하지만 기록은 이미 망쳤다.

RX Tier 사용자의 실제 최적 전략은 11-7-3 + Pull-up Unbroken 전 라운드 + Burst 마지막 3개.
이 사실을 박스에 들어서기 전에 알았으면 기록은 달라졌다.

### 2-2. 구조적 원인

WOD 페이싱은 세 개의 변수가 동시에 필요하다.

| 변수 | 기존 athlete 가 구하는 방법 | 문제 |
|---|---|---|
| 본인 역량 (1RM / UB / 페이스) | 감 + 코치 귀띔 | 비정형·주관적. Tier 간 차이 미반영 |
| 동작별 최적 분할 | 경험 + 인터넷 검색 | RX 전략을 Elite 가 따르면 위험 |
| Burst 시점 | "느낌상 마지막 라운드" | W-prime 과 Central Governor 무시 |

세 변수 중 하나라도 틀리면 전략은 무너진다.
FACING 은 셋을 동시에 처리하고, 1.8초 안에 근거와 함께 돌려준다.

### 2-3. 기존 도구의 한계

- **WODsmith**: WOD 기록 로그. 다음 WOD 에 활용할 전략 없음.
- **SugarWOD**: 박스 커뮤니티 중심. 결과 공유 우선. 시작 전 전략 부재.
- **코치 구두 설명**: 박스 전 5분 브리핑. 개인화 불가. Games Tier 와 Scaled Tier 동일 전략.
- **엑셀/메모**: 직접 계산. 동작 추가·변경 시 다시 계산. 마찰 높음.

---

## 3. Tenets — 페이싱 알고리즘의 원칙

### T1. Tier 차등 — 동일 WOD, 5개의 다른 전략

같은 Fran 이라도 Scaled 과 Elite 의 최적 전략은 다르다.
FACING 은 overall_number(1~6) → 5 Tier 로 Explosion Boundary(T_boundary)와
기준 강도(f_baseline)를 다르게 적용한다.

| Tier | f_baseline | T_boundary | 의미 |
|---|---|---|---|
| Scaled | 0.35 | 0.95 | 초반 보수, 마지막 5%에 마이크로 폭발 |
| RX (rxd) | 0.50 | 0.85 | 기준선. 중간 50% 강도, 마지막 15% 폭발 |
| RX+ (advanced) | 0.55 | 0.80 | 더 빨리 시작, 폭발 구간 20% |
| Elite | 0.60 | 0.75 | 고강도로 시작, 폭발 구간 25% |
| Games (elite 최상위) | 0.60 | 0.75 | Elite 동일 파라미터 + 세트 크기 상향 |

결론: Scaled 와 Elite 에게 같은 전략을 줄 수 없다.

### T2. 1RM 기반 정량화 — 감이 아닌 수치

모든 분할 결정의 기반은 사용자가 입력한 1RM, Unbroken Max, 카디오 페이스다.
체중 대비 비율(kg/BW), 절대 반복 수, sec/500m — 3가지 단위로 측정하고
CrossFit Open 통계·NSCA 기준·WMA 2023 Age Grading Factor 를 임계값 기준으로 삼는다.

추정치를 기반으로 하지 않는다. 빈 칸은 카테고리 기여에서 제외된다 (default 점수로 강점 희석 금지).

### T3. 근거 제시 의무 — 알고리즘이 왜 이 전략인지 설명해야 한다

숫자만 주면 신뢰를 얻지 못한다. 결과 화면에 출력되는 근거(Rationale)는 SSOT 테이블에서
결정론적으로 선택된다. LLM 없음. 예:

> "Max UB 21 의 52% 부터 내림차순 분할. W-prime 보존."
> "마지막 3개는 남은 W-prime 전부 소진. Central Governor 해제 구간."

논문(Abbiss & Laursen 2008, Attilio et al.) 근거가 있는 코드만 Rationale Table 에 올린다.

### T4. WOD 타입별 분기 — For Time / AMRAP / EMOM 은 다른 게임이다

- **For Time**: 완주 시간 최소화. 세트 사이 휴식 공격적으로 짧게(×0.65). 첫 세트 보수.
- **AMRAP**: 라운드당 균등 페이스. 마지막 라운드에서만 Burst.
- **EMOM**: 매 분 반복. 시간 자체가 페이싱. 여유 초(rest_sec) 기반으로 세트 결정.

### T5. 결정론적 — 같은 입력, 같은 출력, 항상

알고리즘은 순수 함수다. 외부 상태·LLM·랜덤 없음. 단위 테스트가 동작 증명이다.
입력(1RM, UB, Tier, WOD 구성, WOD 타입)이 고정되면 출력이 고정된다.

---

## 4. Approach — 어떻게 동작하는가

### 4-1. Engine Score 측정: 6 카테고리

사용자는 온보딩 Benchmarks 화면에서 본인 기록을 입력한다.
알고리즘(`grading.py`)이 6 카테고리 Score(0~6 연속값)를 산출한다.

| 카테고리 | 가중치 | 주요 입력 지표 | 기준 출처 |
|---|---|---|---|
| Power (정적 근력) | 0.25 | Back Squat / Deadlift / Front Squat / Bench / OHP 1RM | NSCA Strength Standards |
| Olympic (역도) | 0.25 | Clean / C&J / Snatch / Power Clean / Power Snatch 1RM | Catalyst Athletics |
| Gymnastics (체조) | 0.20 | Pull-up UB / T2B UB / HSPU UB / Bar MU / Ring MU | CrossFit Open 통계 |
| Cardio (유산소) | 0.15 | Run 1mile / 500m Row / 2km Row / 10km Run / Cooper 12min | Concept2 World Rowing |
| Metcon (1분 max) | 0.15 | Burpee / Double-Under / KB Swing / Wall Ball / Box Jump | CrossFit Games Open 영상 분석 |
| Body (신체 정보) | 보정 | 체중 / 나이 (WMA 2023 Age Grading) | World Masters Athletics 2023 |

카테고리별 점수 계산 방식:

1. 입력 지표를 체중비(역도)·절대 반복(체조)·시간(카디오) 단위로 정규화.
2. 성별 보정 적용 (여성 = 남성 임계값 × 0.75).
3. 마스터즈 보정: 35세 이상 카디오 임계값을 WMA 2023 factor 역수로 완화.
   (65세 → factor 0.72 → 39% 시간 추가 허용)
4. 각 지표 Score = [1.0~6.0] 연속값 선형 보간.
5. 카테고리 내 상위 70%(top-K 가중 평균) 채택 — 약점 항목이 강점을 희석하지 않음.
6. 데이터 있는 카테고리만 가중 평균 — 빈 카테고리는 기여 제외.

전체 Engine Score(overall_score) → `_bucket()` → overall_number 1~6.

### 4-2. Tier 매핑

| overall_number | 내부 grade | UI Tier | 색상 토큰 |
|---|---|---|---|
| 1 | scaled | Scaled | #4A4A4A 회색 |
| 2 | beginner | Scaled | 동일 |
| 3 | intermediate → rxd | RX | #EE2B2B 빨강 |
| 4 | rxd → advanced | RX+ | #929292 실버 |
| 5 | advanced | Elite | #C8C8C8 연실버 |
| 6 | elite | Games | #F5F5F5 화이트 |

UI 에 "RXD 4/6" 같은 내부 코드 노출 금지. 사용자는 Tier 라벨만 본다.

### 4-3. WOD Calc 데이터 흐름 (9-3 요약)

WodBuilder → MovementPicker → 동작·횟수·중량·WodType 입력 →
POST /api/v1/pacing/calculate (≤1.8s) →
PacingPlan(segments / total_estimated_sec / burst_segments) →
ResultScreen(Split 카드 + Burst + 근거) → WodHistoryItem 저장 → SeasonBadge check.

### 4-4. 페이싱 공식 상세

핵심 공식: `allowed_output = N × f(T)`

- **N**: 해당 동작의 사용자 Max 능력 (UB / 1RM / 카디오 페이스)
- **T**: WOD 진행률 [0.0, 1.0]
- **f(T)**: Tier별 페이싱 함수

```
T < T_boundary → f(T) = f_baseline         (Saving Zone: 보존 구간)
T ≥ T_boundary → f(T) = f_baseline + k × (T - T_boundary)   (Explosion Zone)
k = (1.0 - f_baseline) / (1.0 - T_boundary)
```

**Split Matrix**: (시간 영역, Tier) 2축 매트릭스가 첫 세트 비율(first_set_ratio)과
하강 계수(descending_step)를 결정한다.

| 시간 영역 | RX first_ratio | RX descending_step |
|---|---|---|
| Short (<5분) | 0.50 | 0.80 |
| Medium (5-15분) | 0.43 | 0.80 |
| Long (15분+) | 0.38 | 0.85 |

Elite Short WOD 에서는 first_ratio 0.55 / descending_step 0.75 — 더 공격적으로 시작해 더 가파르게 내려간다.

**부하 분류**: 1RM 대비 load 비율로 세트 전략이 달라진다.

| 비율 | 분류 | 전략 |
|---|---|---|
| <60% | Light | Touch-and-go. first_ratio × 1.60 보너스 적용 |
| 60-80% | Moderate | 기본 Split Matrix 적용 |
| >80% | Heavy | 세트 크기 cap 5개 — 기술 붕괴 방지 |

**동적 휴식**: `rest = base_grade × phase_mult × category_mult × load_mult × wod_type_mult × metcon_bonus`

- 카테고리별 multiplier: 역도(barbell) 1.50 / 체조 1.00 / 카디오 0.50
- For Time 의 세트 사이 휴식 = ×0.65 (완주 시간 최소화 목표)
- Metcon 점수가 높을수록 더 짧은 휴식 견딤 → 공격성 계수(0.85~1.10) 적용

**카디오 페이스**: `target_pace = max_pace / (0.80 + 0.15 × f(T))`
Saving Zone 에서 Max 의 80% 페이스. Explosion Zone 에서 95% 페이스.

### 4-5. Fran 풀 예시 (RX Tier, Medium 시간 영역)

WOD: Fran — 21-15-9 Thruster(65lb) + Pull-up. Profile: Back Squat 1RM 210lb / Pull-up UB 25.

| Round | T 범위 | Zone | Thruster Split | Pull-up | 근거 코드 |
|---|---|---|---|---|---|
| R1 (21) | 0.00~0.40 | Saving | **11-7-3** (Light 31%, ×1.60 boost) | 21 UB | DESCENDING_SPLIT |
| R2 (15) | 0.40~0.75 | Saving | **8-5-2** | 15 UB | DESCENDING_SPLIT |
| R3 (9) | 0.88 → Burst | Explosion | **9 all-out** (FINAL_EXPLOSION) | 9 UB all-out | FINAL_EXPLOSION |

예상 완주: **4:35**. Burst 시점: R3 진입 즉시 전부.
근거: "Max UB 25의 44%부터 내림차순 분할. W-prime 보존." / "마지막 9개는 남은 W-prime 전부 소진."

---

## 5. Metrics — 어떻게 측정하는가

### 5-1. 시스템 성능

| 지표 | 목표 | 비고 |
|---|---|---|
| 응답 시간 (P50) | 1.8초 이하 | 백엔드 순수 계산 + 네트워크 포함 |
| 응답 시간 (P99) | 3.0초 이하 | 에뮬레이터 로컬 기준 |
| 알고리즘 결정성 | 100% | 동일 입력 → 동일 출력 보장 |
| 오프라인 대응 | Offline banner | 연결 복구 시 자동 재시도 |

### 5-2. 알고리즘 정확도 기준 (현재)

정확도는 "예상 시간 오차"와 "Split 패턴 현실성" 두 축으로 측정한다.

| 지표 | 현황 | 목표 |
|---|---|---|
| 예상 시간 오차 (For Time) | 캘리브레이션 중 | ±15% 이내 |
| WOD 타입 지원률 | For Time / AMRAP / EMOM | Chipper Phase 2 에서 추가 |
| 단위 테스트 커버리지 | formula / splitter / grading / rest / rationale | pytest 전체 Green |
| 백엔드 E2E 회귀 | 10 페르소나 × 8 endpoint | test_personas_e2e.py 통과 |

캘리브레이션 이력: v1.5.1 — 실측 7:30 기준으로 sec_per_rep 보정 계수 0.45 → 0.65 조정.
이후 변경은 `DECISION_LOG.md` 에 FORMULA_VERSION 과 함께 기록한다.

### 5-3. 사용자 깔때기 (MVP 기준)

Engine 측정 완료(100%) → WOD Calc 진입(~80%) → Split 수신(~95%) → 기록 저장.
WOD 세션 완료 후 PrDetector 가 이전 기록과 비교 — PR 감지 시 즉시 unlock toast.

---

## 6. Risks / Trade-offs — 알고리즘의 한계

### R1. sec_per_rep 추정 오차

동작별 sec_per_rep 는 동작 카탈로그 기본값을 쓴다.
실제 사용자의 기술 수준·피로 상태·바벨 설치 속도에 따라 편차가 생긴다.
현재 캘리브레이션은 단일 실측(Fran 7:30)에서 출발했다.

완화 방향: 사용자가 WOD 완료 후 실제 시간을 입력하면 History 로 누적 → 개인별 보정 계수 도출(Phase 3).

### R2. 1RM 미입력 시 카테고리 기여 제외

Engine Score 는 데이터 있는 카테고리만 반영한다. 입력 카테고리가 적으면
전체 점수의 신뢰도가 낮아진다. Tier 가 실제보다 낮게 나올 수 있다.

완화 방향: Benchmarks 화면에서 "아는 것만 입력" 안내. 최소 2카테고리 입력 권장.
미입력 카테고리는 Split 계산 시 overall Tier 로 fallback.

### R3. 1RM 자기보고 과대 입력

1RM 을 실제보다 높게 입력하면 Load 비율이 낮아지고 첫 세트가 커진다.
전략이 현실보다 공격적이 된다.

완화 방향: 검증 불가. 대신 결과 화면에 "Split 이 너무 크면 1RM 을 재측정하라" 근거 문구 포함.

### R4. Split Matrix 는 6×3 격자 — 경계값 점프

overall_number 경계에서 Tier 가 바뀌면 Split 이 불연속 점프한다.
(예: score 3.49 = rxd / 3.50 = advanced → first_ratio 0.43 → 0.45)

완화 방향: overall_score 를 연속 보간으로 first_ratio 를 선형화하는 방식을 Phase 2 에서 검토.

### R5. AMRAP 라운드 수 추정 의존

AMRAP 은 "예상 완주 라운드 수"를 사용자가 입력해야 한다.
실제 라운드 수가 예측과 다르면 후반 pacing_ratio 가 어긋난다.

완화 방향: AMRAP 결과 화면에서 실제 라운드 수 입력 → 자동 보정(Phase 2).

### R6. Chipper / Ladder / Tabata 미지원

현재 `UNSUPPORTED_WOD_TYPES = {"ladder", "tabata", "long_chipper"}`.
복잡한 WOD 타입은 Plan_for_time 으로 근사 처리되거나 차단된다.

완화 방향: Phase 2 Chipper 지원. 타입 감지 로직 추가.

---

## 7. Roadmap

### Phase 1 — 현재 완료

- For Time / AMRAP / EMOM 3 타입 지원
- Engine Score 6 카테고리 (Power / Olympic / Gymnastics / Cardio / Metcon + Body)
- Split Matrix (6 Tier × 3 시간 영역 = 18셀)
- 동적 휴식 (6축 multiplier)
- 카테고리별 Tier 분기 (gymnastics 등급으로 Pull-up 평가 등)
- Metcon 공격성 보너스 (metcon_aggression_factor)
- 마스터즈 보정 WMA 2023 Age Grading Factor
- 단위 테스트: formula / splitter / grading / rest / rationale 전체 커버
- 백엔드 E2E 회귀: 10 페르소나 × 8 endpoint

### Phase 2 — Chipper 보강 + 연속 보간

- Chipper WOD 타입 지원 (multi-element, descending rep scheme)
- Tabata 8-라운드 특화 전략 (on:off = 20:10 고정)
- Split Matrix 경계 연속 보간 (불연속 점프 제거)
- AMRAP 실제 라운드 수 피드백 → 자동 보정
- 실측 History 누적 → 동작별 sec_per_rep 개인화

### Phase 3 — 실시간 보정

- WOD 세션 타이머와 연동: 실제 Split 시간 추적
- 중간 시점 재계산: "현재 속도로 완주 예상 시간 갱신"
- 세트 완료 시 햅틱 신호: "다음 세트 시작" 알림
- Wearable(Whoop / Garmin) 심박 연동 → 실시간 T 보정

---

## 8. FAQ

**Q1. LLM 을 쓰지 않으면 어떻게 개인화되나?**

1RM, UB, 카디오 페이스 — 이 3개의 입력이 개인화의 전부다.
두 사람이 같은 입력을 주면 같은 결과를 받는다.
LLM 이 없으므로 응답이 결정론적이고, 단위 테스트로 전체 동작을 증명할 수 있다.
"어떤 답이 나올지 모르는" 블랙박스를 엘리트 athlete 는 신뢰하지 않는다.

---

**Q2. Engine Score 와 Tier 는 어떻게 다른가?**

Engine Score 는 0~6 연속값 float. 카테고리별 강약점을 표시한다.
Tier 는 5단계 라벨: Scaled / RX / RX+ / Elite / Games.
Tier 는 Pacing 알고리즘의 입력이다. Engine Score 는 자기 인식 도구다.
결과 화면에 "RXD 4/6" 같은 내부 숫자를 노출하지 않는다.

---

**Q3. 1RM 이 하나도 없으면 어떻게 되나?**

해당 카테고리(Power / Olympic)는 가중 평균에서 제외된다.
Gymnastics·Cardio·Metcon 만 있어도 Tier 가 산출된다.
WOD 에 Barbell 동작이 있는데 1RM 이 없으면 overall Tier 로 fallback.
최소 1카테고리 이상 입력해야 의미 있는 Tier 가 나온다.

---

**Q4. 예상 시간이 실제와 다르면?**

예상 시간은 추정이다. sec_per_rep 는 동작별 평균값에서 출발한다.
오차는 R1(기술 편차)·R3(1RM 과대 입력) 두 원인이 크다.
실제 완주 시간 입력 → History 저장 → Phase 3 에서 개인 보정.
현재 캘리브레이션 목표: For Time ±15% 이내.

---

**Q5. 같은 WOD 를 두 번 계산하면 다른 결과가 나오나?**

입력이 동일하면 결과는 동일하다. 알고리즘은 순수 함수.
단, Profile 의 1RM 이나 UB 가 바뀌면 결과도 바뀐다.
PR 갱신 후 같은 WOD 를 다시 계산하면 Split 이 바뀔 수 있다.

---

**Q6. Burst 시점은 어떻게 정의하나?**

`T ≥ T_boundary` 인 구간이 Explosion Zone 이다.
RX Tier 에서 T_boundary = 0.85 → WOD 진행률 85% 이상 구간.
For Time 21-15-9 에서 마지막 9개 라운드가 대략 이 구간에 해당한다.
Burst 는 "Split 이 1개인 단일 세트 + is_explosion = true" 로 마킹된다.

---

**Q7. AMRAP 에서 Split 은 어떤 의미인가?**

AMRAP 은 시간 제한 안에서 가능한 한 많은 라운드를 완주하는 타입이다.
Split 전략은 "라운드당 균등 페이스" + "마지막 라운드에서 Burst".
라운드 중반부터 속도를 높이면 후반 라운드를 줄이는 결과를 낳는다.
FACING 은 Even Pacing(Abbiss & Laursen 2008) 원칙을 기본으로 한다.

---

**Q8. EMOM 에서 Split 은 필요한가?**

EMOM 은 매 분 동일 동작을 반복한다. 시간이 자체 페이싱이다.
FACING 은 "매 분 작업 시간(work_sec) + 여유(rest_sec)" 를 계산해서
세트 크기가 현실적인지 검증한다. work_sec > 55초면 세트 크기를 줄이도록 권고한다.

---

**Q9. 경쟁사는 왜 이걸 안 하나?**

CrossFit 특화 앱(WODsmith·SugarWOD)은 커뮤니티·기록 관리에 집중했다.
페이싱 전략은 "코치가 해주는 것" 으로 간주되어 앱의 범위 밖이었다.
FACING 이 다른 이유: 코치를 대체하는 것이 아니라 코치가 없을 때 사용자가 스스로 전략을 짤 수 있게 한다.
박스에서도 코치 WOD 를 받은 뒤 FACING 으로 자기 Split 을 개인화한다.

---

**Q10. Tier 가 바뀌면 전 WOD 의 Split 도 소급 변경되나?**

소급 변경 없음. Split 은 계산 시점의 Tier 로 확정되어 History 에 저장된다.
이후 1RM 갱신으로 Tier 가 높아져도 기존 기록은 그대로다.
"과거의 나" 와 "현재의 나" 를 비교하는 것이 PR 시스템의 목적이다.

---

*이 문서의 알고리즘 수치(f_baseline / T_boundary / SPLIT_MATRIX 등) 변경은
`services/facing/engine/config.py` 의 `FORMULA_VERSION` 갱신 + `DECISION_LOG.md` 항목 추가 의무.*
