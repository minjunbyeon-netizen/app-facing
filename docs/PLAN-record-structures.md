# PLAN — 수업 유형별 기록 구조 + 발전 측정 (②) · P4 트리거 확장 (③)

> 상태: **② = 승인 (2026-08-20 19:48 사용자 "1" — 결정 3건 추천안 확정) →
> Q1+Q2 같은 날 구현 완료** (Q3 추이 2화면은 다음 단계) ·
> **③ = "좋네" 승인 → 2026-08-20 저녁 세션 구현 완료** (아래 Part B 가 구현 명세 겸 기록).
> 관련: `PLAN-reward-rules.md` (리워드 엔진 본편) · `ARCHITECTURE_BRIEF.md §11.11~11.12`.
>
> **Q1+Q2 구현 로그 (2026-08-20)**: 확정 결정 = ①EMOM 성공 라운드 1칸 ②Strength
> 최고 무게+reps 1줄 ③AMRAP 라운드 우선. 백엔드 — `gym_wod_results` 4컬럼
> (weight_kg·weight_reps·is_pr·signature+인덱스, ADD COLUMN 마이그레이션) ·
> `services/wod_compare.py` 단일 판독(시그니처·직전 델타·역대 최고 PR 0.5% 임계·
> 한국어 메시지 서버 완성) · 응답 `comparison` 블록 · 리워드 'pr' 원천에
> gym_wod_results 합류 · ALLOWED_WOD_TYPES +strength (PC 게시와 정합) ·
> 결과 목록 무게 필드+strength 정렬 · pytest +5 (전체 152+1). 앱 — 시트 4분기
> (Strength 무게+reps 입력·EMOM "성공한 라운드" 라벨) · 저장 스낵바에 서버 비교
> 메시지 · 코치 등록 시트 STRENGTH 칩 · 골든 43장 (member_06b strength 분기).
> 구현 중 발견·정정: 앱 게시 API 가 strength 를 거부하던 드리프트 (PC 는 허용) —
> ALLOWED_WOD_TYPES 로 정합. 배포 안 함 (로컬 커밋만).

---

## Part A — ② 수업 유형별 기록 구조 + 발전 측정 (승인 대기)

### A-0. 문제 (사용자 지적 원문 요지)

완료 기록이 한 틀(시간 아니면 라운드)로 굳어 있다. 수업 유형마다 "잘했다"의
단위가 다르다 — For Time 은 시간, 1RM 측정일은 무게, AMRAP 은 라운드다.
그리고 기록이 쌓여도 **"전과 비교해 발전했는가"를 아무도 계산하지 않는다.**

### A-1. 현재 실물 (2026-08-20 실측)

| 항목 | 실물 | 문제 |
|---|---|---|
| 코치 게시 유형 | 4종 for_time/amrap/emom/**strength** (`web/facing-admin templates/wod.html` wpType) | — |
| 앱 입력 분기 | **2분기뿐** — for_time=시간 / 나머지=라운드 (`lib/features/gym/wod_result_sheet.dart`) | **strength 가 "몇 라운드 했는지"로 잘못 흡수 — 무게 입력 자리 없음** |
| 저장 표 | `gym_wod_results` time_sec·rounds·extra_reps·scale_level·notes | 무게 컬럼 없음 · 동작별 선택은 notes 문자열 |
| 발전 측정 | **0.** PR 감지는 별도 history(`wods`) 흐름의 `_detect_pr` (wod_type+notes 시그니처 — 페이싱 계산기 시절 설계) | 수업 기록엔 비교·PR 없음 |

### A-2. R1 — 유형별 점수 구조

| 유형 | 점수 = "잘했다"의 단위 | 입력 (최소) | 비교 방향 |
|---|---|---|---|
| For Time | time_sec | 분:초 (현행 유지) | 작을수록 발전 |
| AMRAP | rounds + extra_reps | 라운드 + 추가 reps (현행 유지) | 클수록 |
| EMOM | 성공 라운드 | "게시 10라운드 중 N 성공" (라벨 명확화) | 클수록 |
| **Strength** | **최고 무게 kg (+reps)** | **신설 — 무게·reps 입력. SCALED/RXD 선택 아님** | 클수록 |

DB: `gym_wod_results` 에 `weight_kg REAL NULL` · `weight_reps INT NULL` ·
`is_pr INT DEFAULT 0` 3컬럼 추가 (ADD COLUMN — 재빌드 불필요).

### A-3. R2 — 발전 측정 (서버 단일 판독 · 앱 계산 0)

1. **"같은 것" 판정 = 비교 시그니처**
   - strength → 대표(첫) 동작 slug — 동작 단위 무게 추이
   - for_time/amrap/emom → wod_type + 구성 정규화 해시 (rounds_data 의
     동작 slug·reps 시퀀스. 자유 서술 게시물은 content 첫 줄 정규화 폴백)
   - 코치가 같은 벤치마크(Fran 등)를 재게시하면 자동으로 잡힌다.
2. **저장 시 비교** — 서버가 같은 시그니처의 과거 내 기록과 대조, 응답에
   `comparison` 블록: `{prev_value, delta, is_pr, kind}`.
3. **PR 판정** — strength=같은 동작 역대 최고 무게 초과 / for_time=최단 기록
   (0.5% 임계 — 기존 `_detect_pr` 원칙 계승) / amrap=최다 라운드·reps.
   첫 기록은 비교 대상이 없으므로 PR 아님 (기존 원칙 계승).
4. **리워드 연결** — `gym_wod_results.is_pr` 를 reward_engine 'pr' 트리거
   원천에 합류 → 기존 "PR 누적 N회" 규칙이 수업 기록 PR 도 집계.
5. **앱 표시** — 저장 스낵바: "저장됨 · 지난번보다 42초 단축" / PR 시
   "PR! +5kg" (업적 해금 컨페티와는 별개 흐름).

### A-4. R3 — 추이 표시 (앱)

- 수업 상세: "내 이전 기록" 섹션 — 같은 시그니처 최근 3건 + 델타.
- 내 정보(기록): strength 동작별 최고 무게 목록 (1RM 보드).
- 골든 갱신: 시트 4분기 변형 + 수업 상세.

### A-5. 하지 않는 것 (v1 한계 선언)

- 세트별 전체 기록 (톱 세트 1값만) · time cap DNF 표기 — 후속.
- 자유 서술 strength 게시물의 동작 식별 — 첫 줄 시그니처 폴백 (수업 PR 로만).
- history(`wods`) 미러 정리 — 온존 (출석 캘린더·기존 업적 원천). 통합은 후속.

### A-6. 단계

| 단계 | 내용 | 상태 |
|---|---|---|
| Q1 백엔드 | 4컬럼 + 시그니처·비교·PR + 응답 comparison + pr 원천 확장 + pytest | ✅ 2026-08-20 |
| Q2 앱 | 시트 4분기 (strength 무게 입력) + 저장 피드백 + 골든 | ✅ 2026-08-20 |
| Q3 앱 | 추이 2화면 (수업 상세 "내 이전 기록" · 1RM 보드) + 백엔드 이력 API + 골든 | ✅ 2026-08-20 |

**Q3 구현 로그 (2026-08-20 저녁 2차)**: 백엔드 — `my-history`(같은 시그니처 내
기록 10건, 라벨 "4:18"·"105kg×3"·"10R+5" 서버 완성) + `strength-board`(리프트별
역대 최고, 동작명은 게시물에서 읽기 시점 추출) + pytest (전체 153+1). 앱 —
수업 상세 "내 이전 기록" 섹션(날짜·라벨·PR 배지) + 내 정보 메뉴 "최고 기록" →
1RM 보드 화면. 골든 44장 (member_20 보드 신규 · member_05/09 갱신).
한계: v3.4 이전 기록은 signature NULL 이라 이력에 안 잡힘 (신규 저장분부터 축적).

### A-7. 결정 필요 3건 (추천 포함)

1. **EMOM 입력**: 성공 라운드 수 1칸 (추천 — 최소 입력) vs 분당 체크리스트.
2. **Strength 입력**: 최고 무게+reps 1줄 (추천) vs 세트×무게 전부.
3. **AMRAP 비교**: 라운드 우선, 동라운드면 reps (추천) vs 총 reps 환산.

---

## Part B — ③ P4 트리거 확장 (구현 명세 · 2026-08-20 완료)

리워드 규칙 빌더의 행동 슬롯에 4종 추가. 전부 **카테고리 1 (자동 — 시스템 관측)**.

| 행동 | 원천 | 이벤트 날짜 | 카운트 규칙 |
|---|---|---|---|
| `reservation` 예약 | `class_reservations` (confirmed·attended) | **예약한 날** (reserved_at) | 1일 1회 정규화 (수업 몰아 예약 = 1회). 취소는 재평가 시 제외 — 기지급 회수 없음 (출석 정정과 동일 한계) |
| `payment` 결제 | `gym_payment` (status=paid, refund 제외) | paid_at | 1일 1회 정규화 |
| `membership_extend` 연장 | `gym_memberships` **2번째 발급부터** (재등록=연장, refunded/cancelled 제외) | 발급일 (created_at) | 조건은 **누적(lifetime)만** |
| `birthday` 생일 | `gym_member_profiles.birth_date` | 그 해 생일 | **당일~+7일 유예** 안에 앱을 열거나 출석하면 지급 · **매년 반복** (지급 키 = 생일의 연도) · 2/29 생은 평년 2/28 · 미소급 (규칙 생성 전 생일 제외) |

- 조건 제약: `streak_days` 는 신규 4종 금지 · extend 는 lifetime 만 ·
  birthday 는 조건 슬롯 고정 (서버가 count_in_window/1/year 로 강제 저장).
- **CHECK 마이그레이션**: `gym_reward_rules.ck_reward_trigger` 가 기존 4종만
  허용 — writable_schema 패턴(`_migrate_gym_member_status_enum` 계승)으로 확장.
- 훅: 회원 예약 2경로 + 대기열 승격 (`api/classes.py`) / 결제 입력
  (`api/payments_admin.py`) / 회원권 발급 (`api/admin.py` — payment+extend 동시
  평가) / 생일은 출석 훅 동승 + 앱 스윕(`achievements/check`).
- 빌더 UI: 카테고리 1 트리거 5종 노출, birthday 선택 시 조건·반복 슬롯 고정
  표시 (`web/facing-admin templates/settings_achievements.html`).
- 앱 변화 없음 — 규칙 문장(sentence)·진행률은 서버 생성분을 그대로 표시.

---

*작성 2026-08-20. Part A 승인 시 Q1 착수.*
