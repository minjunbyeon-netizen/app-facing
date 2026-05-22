# N1 — CrossFit 도메인 깊이 재검토 (sub-agent A)

> 작성: 2026-05-23 / 입력: PHASE3_ROADMAP.md §3 + fitness sub-files × 6 + subscription-fitness.md + gym-management-saas.md §5/§14

---

## 1. 누락·과잉 항목

### 누락 (Fitness study 대조 결과)

| # | 누락 항목 | 근거 |
|---|---|---|
| L1 | **Wilks / DOTS 체중 보정 점수** | `fitness/power.md §A4` — "동작별 1RM·횟수·시간 3축으로 충분?"의 답: 충분하지 않음. 체급 다른 두 회원을 같은 leaderboard에 올리면 고체중자가 절대값으로 항상 유리 → DOTS 정규화 필수 |
| L2 | **Power Clean / Snatch BW ratio 등급 테이블** | `fitness/olympic-lifting.md §4` — Snatch ≈ 0.75×C&J, Power Clean ≈ 0.80~0.88×Clean 공식 존재. member_pr 에 "역도 종목 등급" 컬럼 없으면 입력된 숫자가 "잘 한 건지" 판단 불가 |
| L3 | **Gymnastics skill progression 단계** | `fitness/gymnastics.md §3~6` — Kipping pull-up → Strict pull-up → Chest-to-bar → Bar muscle-up → Ring muscle-up 진행 단계. 현재 N1-5 동작 라이브러리에 "스케일링 옵션"만 있고 "선행 동작(prerequisite) 트리" 없음 |
| L4 | **AMRAP 라운드 비교 정규화** | 같은 AMRAP이라도 시작 체력·스케일이 다름. "Rx vs Scaled" 스코어를 같은 leaderboard에 올릴 변환 공식 없음 — 이것이 leaderboard 알고리즘의 핵심 미결 문제 |
| L5 | **HYROX 포맷 지원** | `fitness/hyrox.md §1` — HYROX(8km 런 + 8 기능 스테이션)는 CrossFit이 아니지만 동일 한국 박스 회원층이 출전. 현재 WOD 타입 목록(For Time·AMRAP·EMOM·Chipper)에 없음. 한국 박스 사장 인터뷰 없이 "30개+ 충분" 주장은 과도한 가정 |
| L6 | **시즌 주기 자동화 (CrossFit Open 2~3월)** | N1-4가 "자동 detection" 언급하지만 CrossFit HQ Public API 존재 여부가 study에 명시 없음 (gym-management-saas.md §15.2에서도 "HQ API" 를 "다음 study 후보"로 분류만). 실현 가능성 검증 전에 task로 세팅된 것 |
| L7 | **한국 박스 표준 기록** | `fitness/olympic-lifting.md §7` — KWA 기록(사재혁·장미란·박혜정)과 `fitness/physical-norms.md §7` KSPO 국민체력100 데이터 있음. 그러나 N1-3 "Benchmark WOD 30개+"는 Girls+Heroes 기준이며 **한국 CrossFit Korea 챔피언 기록·한국 박스 특화 벤치마크(예: 한강 런 WOD, 한국 오픈 기록)**는 누락 |

### 과잉 (현재 단계에서 스코프 초과)

| # | 과잉 항목 | 이유 |
|---|---|---|
| O1 | **N1-5 동작 표준 비디오** | 200개+ 동작 × 영상 = 라이센스·스토리지 문제. Wodify도 외부 링크(SugarWOD·WODify TV) 방식 사용. Phase 3 MVP에서 비디오 자체 호스팅은 과잉 |
| O2 | **N1-5 "200개+ 동작"** | 한국 박스가 실제로 쓰는 CrossFit 표준 동작은 상위 40~60개가 80% 이상 커버. 200개를 먼저 넣으면 DB 정규화·UI 검색보다 데이터 입력 부채가 더 큼 |
| O3 | **Open 시즌 HQ API 통합 (N1-4)** | HQ 공식 API가 비공개이거나 유료일 가능성 높음. "수동 입력 + 박스 내 ranking"으로 MVP 충분 → API 통합은 N2 이후 검증 후 판단 |

---

## 2. schema 재설계 권고

### 현재 N1 제안: `wod_session · wod_movement · wod_score` 3 테이블

충분하지 않은 이유 3가지:

**R1. 스케일(RX/Scaled/RX+) 차원 누락**

```sql
-- 현재 추정 구조 (N1-1 기준)
wod_score(id, wod_session_id, member_id, score_value, score_unit, created_at)

-- 필요한 추가 컬럼
wod_score(
  id, wod_session_id, member_id,
  scale_type     TEXT NOT NULL,     -- 'rx' | 'scaled' | 'rx_plus'
  scale_factor   DECIMAL(5,4),      -- 정규화 계수 (0.0~1.0). RX=1.0, Scaled≈0.75
  score_value    DECIMAL(10,2),
  score_unit     TEXT,              -- 'time_sec' | 'reps' | 'rounds_plus_reps' | 'load_kg'
  is_pr          BOOLEAN DEFAULT FALSE,
  notes          TEXT,
  created_at     TIMESTAMPTZ
)
```

**R2. member_pr의 Wilks/DOTS 차원 누락**

```sql
-- 현재 N1-2 제안
member_pr(id, member_id, movement_id, weight_kg, reps, date)

-- 권고 추가 컬럼
member_pr(
  id, member_id, movement_id,
  weight_kg      DECIMAL(6,2),
  reps           INTEGER,
  time_sec       INTEGER,           -- 시간 기준 PR (예: 400m sprint PR)
  bodyweight_kg  DECIMAL(5,2),      -- PR 당시 체중 (체중 보정용)
  dots_score     DECIMAL(6,2),      -- 파워리프팅 3대 전용 (Squat·Bench·Deadlift)
  bw_ratio       DECIMAL(5,3),      -- 모든 근력 동작: weight_kg / bodyweight_kg
  date           DATE,
  created_at     TIMESTAMPTZ
)
```

`dots_score` 공식 (`fitness/power.md §A4`): DOTS = weight_total × 500 / (−307.75076 + 24.0900756×BW − 0.1918759221×BW² + ...). 서버에서 계산해서 저장.

**R3. benchmark_wod 테이블 필요 (현재 wod_session에 묻힘)**

```sql
-- N1-3 "Benchmark WOD 30개+"를 지원하려면 별도 master 테이블 필요
benchmark_wod(
  id             UUID PRIMARY KEY,
  slug           TEXT UNIQUE,       -- 'fran' | 'grace' | 'helen' | 'murph'
  category       TEXT,             -- 'girls' | 'heroes' | 'open' | 'korea'
  description    TEXT,
  movements      JSONB,            -- [{movement_id, reps, load_rx, load_scaled}]
  scoring_type   TEXT,             -- 'for_time' | 'amrap' | 'load'
  rx_standard    JSONB,
  scaled_standard JSONB,
  created_at     TIMESTAMPTZ
)

benchmark_score(
  id, benchmark_wod_id, member_id, gym_id,
  scale_type, score_value, score_unit,
  percentile     DECIMAL(5,2),     -- 박스 내 percentile
  created_at     TIMESTAMPTZ
)
```

**R4. movement_library 마스터 (N1-5 지원)**

```sql
movement_library(
  id             UUID PRIMARY KEY,
  name_en        TEXT UNIQUE,      -- 'Thruster' | 'Pull-up' | 'Box Jump'
  category       TEXT,            -- 'gymnastics' | 'weightlifting' | 'cardio' | 'power'
  subcategory    TEXT,            -- 'kipping' | 'strict' | 'olympic' | 'powerlifting'
  prerequisite_ids UUID[],        -- 선행 동작 ID 배열 (gymnastics.md 진행 트리)
  scaling_options JSONB,          -- [{name: 'ring row', description: ...}]
  score_axes     TEXT[],          -- ['load_kg', 'reps', 'time_sec'] (해당 PR 유형)
  is_benchmark_eligible BOOLEAN,
  created_at     TIMESTAMPTZ
)
```

### 결론: 3 테이블 → 5 테이블로 확장 권고

| 테이블 | 역할 |
|---|---|
| `movement_library` | 동작 마스터 (N1-5) |
| `benchmark_wod` | Girls/Heroes/Open/Korea 워크아웃 정의 (N1-3) |
| `wod_session` | 박스 일일 WOD (N1-1) |
| `wod_score` | 회원 세션 점수 + scale_type (N1-1) |
| `benchmark_score` | 회원 벤치마크 기록 + percentile (N1-3) |
| `member_pr` | 동작별 PR + DOTS/BW ratio (N1-2) |

→ 실제로는 **6 테이블** (member_pr 포함).

---

## 3. 한국 박스 특화 항목

### 3.1 현재 N1-3 "30개+"가 커버하지 못하는 한국 특화 요소

| 항목 | 내용 | 근거 |
|---|---|---|
| 한국 CrossFit Open 기록 | CrossFit Korea가 매년 Open 순위 공식 발표. 박스 leaderboard에 "한국 순위 몇 위"를 보여주려면 CrossFit HQ 연동 또는 수동 입력 시스템 필요 | gym-management-saas.md §14 |
| KSPO 체력 등급과 CrossFit 등급 교차 | physical-norms.md §7 — KSPO 국민체력100 (한국 공식 체력 등급표) 데이터 존재. CrossFit 회원이 "내 체력이 국민 평균 대비 몇 %냐"를 물어볼 경우 연결 가능. 한국 박스 특화 마케팅 포인트 | fitness/physical-norms.md §7 |
| 한강·남산 런 WOD | 서울 박스 공통 야외 WOD. 표준 타임 캡 없는 비공식 benchmark. 박스 자체 benchmark 생성 기능 필요 → `benchmark_wod.category = 'custom'` 분류 대응 |  |
| 한국어 동작명 | 역도/파워리프팅 동작명 한국어 병기 필요 (스내치·클린앤저크 등 이미 영문 계열이나, 초보 회원용 한국어 레이블) | N3 i18n과 연계 |

### 3.2 KWA 한국 역도 기록 연계 가능성

`fitness/olympic-lifting.md §7` — 사재혁(105kg급 C&J 217.5kg, 2012 올림픽), 박혜정(2024 파리 금) 기록 있음. PR 트래킹에서 "한국 기록 대비 몇 %"를 보여주는 기능은 차별화 포인트이나 Phase 3 스코프 초과. N2 이후 검토.

---

## 4. study 인용 (verbatim + 출처)

| 검증 질문 | 인용 | 출처 파일 |
|---|---|---|
| Q2 Wilks/DOTS 필요성 | "Wilks / DOTS 체급 보정 점수" — "동작·중량·횟수·날짜 3축으로 충분?"의 답: 체급 보정 없으면 고체중자가 leaderboard 상위 독점 | fitness/power.md §A4 |
| Q1 schema 충분성 | "Snatch ≈ 0.75~0.80 × C&J (출처: btwb.blog BTWB CrossFit 데이터, men 0.76 / women 0.75) — T2" | fitness/olympic-lifting.md §1-1 |
| Q3 CrossFit gymnastics 정의 | "CrossFit 의 'gymnastics' 카테고리 — pull-up / push-up / dip / handstand push-up / muscle-up / pistol squat / toe-to-bar / L-sit / rope climb. (출처: CrossFit Level 1 Training Guide — T1)" | fitness/gymnastics.md §1-3 |
| Q4 HQ API 불확실 | "CrossFit Affiliate 도메인 특수성 (WOD programming·benchmark·Open 시즌 score 통합·HQ API) — 비즈니스 차별화 축 [다음 study 후보]" | gym-management-saas.md §15.2 |
| Q5 RX vs Scaled 비교 | N1-5 task "스케일링 옵션" 만 있고 변환 공식 없음. Wodify도 별도 leaderboard(RX/Scaled 분리) 방식 채택 — 같은 리스트 내 혼합 비교는 미해결 문제 | gym-management-saas.md §49 (Wodify 기능) |
| Gymnastics progression | "Pull-up 12~15 strict → Dip 15+ → High pull → False grip pull-up 3+ (prerequisite for strict bar muscle-up)" | fitness/gymnastics.md §3-2 |
| HYROX 포맷 | "총 8km 러닝 + 8 스테이션. 러닝과 스테이션이 교대로 끼워져 있어..." 현재 For Time/AMRAP/EMOM/Chipper 4 타입에 없음 | fitness/hyrox.md §1.1 |

---

## 5. 수정된 N1 task list

### 우선순위 재조정 (P0 = Phase 3 필수 / P1 = Phase 3 권장 / P2 = Phase 4 검토)

**N1-0 [신설, P0] movement_library 마스터 구축 (40~60개 핵심 동작 먼저)**
- 200개 전부가 아닌 CrossFit 상위 사용 빈도 60개 우선
- `category`(gymnastics·weightlifting·cardio·power) + `prerequisite_ids` + `scaling_options` + `score_axes` 포함
- 한국어 라벨 컬럼 추가 (N3 i18n 연계)

**N1-1 [유지, P0] WOD 트래킹 schema + UI — schema 수정 필요**
- `wod_score`에 `scale_type(rx/scaled/rx_plus)` + `scale_factor` 컬럼 추가
- `score_unit` 필드: `time_sec | reps | rounds_plus_reps | load_kg` enum
- leaderboard는 scale_type 분리 표시 (RX 별도, Scaled 별도) — 혼합 정규화는 P2

**N1-2 [수정, P0] PR 트래킹 — schema 확장**
- `member_pr`에 `bodyweight_kg` + `bw_ratio` + `dots_score(파워리프팅 전용)` 컬럼 추가
- 3축(load_kg·reps·time_sec) 유지하되 BW ratio 자동 계산 로직 백엔드에 추가
- Wilks/DOTS는 Squat·Bench·Deadlift 3대에만 적용 (역도·CrossFit 동작은 BW ratio만)

**N1-3 [수정, P0] Benchmark WOD 표준 — 테이블 분리 + 카테고리 추가**
- `benchmark_wod` 별도 테이블 (wod_session과 분리)
- 카테고리: `girls | heroes | open | korea | custom`
- Girls + Heroes 우선 30개, `korea` 카테고리로 한국 박스 자체 벤치마크 등록 가능
- percentile은 박스 내 기준만 (글로벌 비교는 P2)

**N1-4 [수정, P1] CrossFit Open 시즌 — HQ API 연동 제거, 수동 입력으로 MVP**
- HQ API 존재 여부 불확실 (gym-management-saas.md §15.2 "다음 study 후보")
- MVP: 회원 수동 Open score 입력 + 박스 내 ranking
- Open 시즌 2~3월 자동 알림은 코드에서 `month IN (2,3)` 단순 체크로 구현
- HQ API 통합은 Phase 4에서 "필요 시" 검토

**N1-5 [수정, P1] 운동 카테고리·동작 라이브러리 — 200개→60개, 비디오 제거**
- Phase 3: 60개 핵심 동작 (Gymnastics 20 · Weightlifting 15 · Cardio 10 · Power 15)
- 비디오 자체 호스팅 제거 → 외부 YouTube/SugarWOD 링크 필드만 (라이센스·스토리지 절감)
- prerequisite_ids 트리 구조로 "이 동작을 하려면 먼저 이것부터" 표시

**N1-6 [신설, P1] leaderboard 알고리즘 명세 (RX/Scaled 분리)**
- 같은 스케일 내에서만 비교 (RX leaderboard, Scaled leaderboard 분리)
- 교차 비교는 Phase 4에서 scale_factor 검증 후 도입
- AMRAP: `rounds × movements_per_round + partial_reps` 통일 계산식 명세

**[P2, Phase 4 검토] 제거 또는 연기**
- DOTS 글로벌 leaderboard (체급 보정 전체 적용) → Phase 4
- CrossFit HQ API 통합 → Phase 4 (study 선행 필요)
- HYROX WOD 타입 지원 → Phase 4 (한국 박스 수요 조사 선행)
- KWA/KSPO 기록 연계 "나는 한국 기록 대비 몇%" → Phase 4

---

## 6. 요약 판정

| 검증 질문 | 판정 | 핵심 이슈 |
|---|---|---|
| Q1 schema 충분성 | **불충분** | 6 테이블 필요 (현재 3). scale_type·BW ratio·DOTS 누락 |
| Q2 Benchmark 30개 | **과소 정의** | Girls+Heroes 30개는 커버되나 Korea/Custom 카테고리 없음 |
| Q3 PR 3축 충분성 | **부분 충분** | BW ratio 추가 필수, DOTS는 3대 한정 선택적 |
| Q4 HQ API | **미결·위험** | 공식 API 비공개 가능성. MVP는 수동 입력으로 대체 |
| Q5 leaderboard RX/Scaled | **미결** | 혼합 비교 공식 없음. Phase 3는 분리 표시로 우회 |
