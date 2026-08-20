# PLAN — 리워드 규칙 엔진 (GTM 식 "행동 → 조건 → 보상" 빌더)

> 상태: **설계 초안 — 사용자 승인 대기** (승인 시 BRIEF §11.11 로 등재 후 구현 착수).
> 발주: 2026-08-20 사용자 지시 — "1(반복 재적립)과 3(출석 스트릭)을 내가 구체적으로
> 설정할 수 있게. 구글 GTM 하듯이 ##행동을 ##하면 ##포인트를 적립한다
> (업적 달성도 마찬가지)".
> 3면 적용: services/facing(엔진) · web/facing-admin(빌더 UI) · apps/facing-app(표시).

---

## 0. 한 줄 문법 (코치가 읽게 될 문장)

```
[행동]을 [기간] 안에 [N회/N일 연속] 하면 → [P 포인트 적립] + [업적 부여] · [1회 | 주기마다 반복]
```

예시 (전부 이 문법으로 표현 가능):
- "달리기 인증(수업 기록)을 **매주 2회** 하면 → **100P** 적립 · **주기마다 반복**"
- "출석을 **7일 연속** 하면 → 업적 '일주일 개근'(불꽃·희귀) 부여 + 300P · **1회**"
- "PR 을 **누적 10회** 달성하면 → 업적 'PR Hunter' + 500P · **1회**"
- "출석을 **이번 달 15회** 하면 → 1,000P · **매달 반복**"

GTM 대응: 행동=Trigger · 기간/횟수=Condition · 보상=Tag(Action) · 반복=Firing option.

---

## 1. 규칙 모델

| 슬롯 | 값 | v1 지원 |
|---|---|---|
| **행동 (trigger)** | `attendance` 출석 · `wod_log` 수업 기록 저장 · `pr` PR 달성 | ✅ v1 (실데이터 존재) |
| | **`custom` 코치가 만드는 행동** — "달리기 인증"·"식단 인증" 등 이름을 코치가 지음. 시스템이 관측 불가하므로 §3-1 인증 로그로 체크 | ✅ v1 |
| | `reservation` 예약 · `payment` 결제 · `membership_extend` 연장 · `birthday` 생일 | P4 확장 |
| **조건 (condition)** | `count_in_window` — 기간(week/month) 안 N회 | ✅ |
| | `streak_days` — N일 연속 (달력일 기준) | ✅ (출석 스트릭 부활) |
| | `lifetime_count` — 누적 N회 | ✅ |
| **보상 (reward)** | 포인트 P (member_points earn 자동 적립) | ✅ |
| | 업적 부여 — 커스텀 업적(이름·픽토그램·희귀도) 자동 생성·해금 | ✅ |
| | 둘 다 동시 | ✅ |
| **반복 (repeat)** | `once` 회원당 1회 | ✅ |
| | `per_window` 주기(주/월)마다 재충족 시 재적립 — **반복 재적립 엔진** | ✅ |

- 반복(per_window)은 조건이 `count_in_window` 일 때만 유효 (streak·lifetime 은 1회 성격).
- 기존 시드 업적 22종은 그대로 — 이 엔진은 **코치가 만드는 규칙** 레이어.

### 1-1. 행동별 "달성 체크" 방식 (2026-08-20 사용자 질문 반영 — 핵심)

| 행동 | 누가 발생시키나 | 체크(검증) 방식 | 일일 상한 |
|---|---|---|---|
| 출석 | 코치가 수업 명단에서 찍음 (수업 예약 기반) | 시스템 자동 — `gym_attendances` 날짜당 1행 | **1일 1회** (같은 날 중복 수업 출석도 1회) |
| 수업 기록 | 회원이 결과 저장 | 시스템 자동 — `wods` | 규칙별 설정 (기본 1일 1회 카운트) |
| PR | 결과 저장 시 자동 감지 | 시스템 자동 — `wods.is_pr` | 제한 없음 (실PR 만) |
| **custom (달리기 인증 등)** | **회원이 앱에서 [인증하기]** | **인증 로그 + 코치 승인** (§3-1) | **1일 1회 고정** |

시스템이 볼 수 없는 행동은 "인증 없이는 카운트 0" — 표기만 하고 달성 판정을
못 하는 규칙은 애초에 만들 수 없게 빌더가 막는다 (custom 은 인증 흐름 강제).

## 2. DB 스키마 (services/facing — 신규 2표 + 1표 확장)

### 2-1. `gym_reward_rules` (신규 — 규칙 정본)
| 컬럼 | 타입 | 설명 |
|---|---|---|
| id | PK | |
| gym_id | FK gyms | 체육관 단위 |
| trigger | VARCHAR(16) | attendance/wod_log/pr (P4: +4종) |
| condition_type | VARCHAR(16) | count_in_window / streak_days / lifetime_count |
| condition_value | INT | N회 / N일 |
| window | VARCHAR(8) | week / month / NULL(streak·lifetime) |
| points | INT | 0 = 포인트 없음 |
| achievement_code | VARCHAR(32) NULL | 커스텀 업적 연결 (RULE_{id} 자동 생성) |
| repeat_kind | VARCHAR(12) | once / per_window |
| label | VARCHAR(60) | 코치가 짓는 규칙 이름 ("주간 달리기 2회 인증") |
| is_active, created_at, updated_at | | 감사로그 병행 (audit_logs) |

### 2-2. `gym_reward_grants` (신규 — 지급 이력·중복 방지 = 반복 엔진의 심장)
| 컬럼 | 타입 | 설명 |
|---|---|---|
| id | PK | |
| rule_id | FK rules | |
| member_id | FK gym_members | |
| window_key | VARCHAR(16) | `2026-W34`(주) / `2026-08`(월) / `once` |
| points_granted | INT | 지급 시점 스냅 (규칙 수정 후 추적) |
| granted_at | DATETIME | |
| **UNIQUE(rule_id, member_id, window_key)** | | 같은 주기 이중 적립 차단 |

### 2-2-b. `gym_action_logs` (신규 — custom 행동의 인증 원장)
| 컬럼 | 타입 | 설명 |
|---|---|---|
| id | PK | |
| rule_id | FK rules | 어떤 규칙의 행동인지 |
| member_id | FK gym_members | |
| gym_id | FK gyms | |
| occurred_on | DATE | 인증 대상 날짜 (KST) |
| status | VARCHAR(10) | pending / approved / rejected |
| note | VARCHAR(200) NULL | 회원 메모 ("한강 5km") |
| decided_by, decided_at | | 코치 승인/거절 기록 |
| **UNIQUE(rule_id, member_id, occurred_on)** | | **1일 1회 인증 상한** |

- 카운트는 **approved 만** 집계. 승인 순간 reward_engine 재평가 → 조건 충족 시 지급.
- 사진 첨부는 **P4** — 앱이 카메라·사진 권한 0 인 현행 개인정보 방침을 지키는 범위에서
  v1 은 메모만. (1샵·코치가 회원을 아는 구조라 승인만으로 신뢰 확보.)

### 2-3. `achievements_catalog` 확장 (기존 표)
- `gym_id INT NULL` 추가 — NULL = 전역 시드 22종, 값 있음 = 그 체육관 커스텀 업적.
- 커스텀 업적 code = `RULE_{rule_id}` (§0-B — 규칙과 1:1, rename 없음).
- 회원 카탈로그 API 는 "전역 + 내 체육관" 만 노출 (타 체육관 커스텀 미노출).
- 규칙 삭제 시 커스텀 업적은 is_hidden 처리 (해금 기록 보존 — v3.2 정책 계승).

## 3. 평가 엔진 (server-side · 이벤트 구동)

`services/reward_engine.py` 신설 — 단일 진입 `evaluate(session, gym_id, member, trigger)`:

1. 해당 gym 의 is_active 규칙 중 trigger 일치분 로드
2. 조건 계산 (원천 데이터):
   - attendance → `gym_attendances` (출석 스트릭 부활 — Engine 스냅샷이 아니라 **실출석**으로)
   - wod_log → `wods` (기존 achievement checker 와 동일 원천)
   - pr → `wods.is_pr`
3. 충족 시 `gym_reward_grants` INSERT (UNIQUE 로 중복 차단) → 성공하면
   포인트 적립(member_points, created_by='reward_rule') + 업적 해금(user_achievements)
4. 실패(이미 지급)는 무음 — 멱등

**훅 지점 (기존 코드 3곳 — 실좌표 확정됨):**
| 이벤트 | 훅 | 비고 |
|---|---|---|
| 출석 기록 | `api/classes.py` 수업 명단 출석 동기화 (gym_attendances 생성 + SSE `attendance_checked` 발행 직후) | 코치가 PC 에서 찍는 순간 평가 — 회원 앱 안 열려도 즉시 적립 |
| 수업 기록 저장 | `api/history.py:102 save_wod_history` 커밋 직전 | PR 감지도 이 흐름이라 pr 트리거 동시 평가 |
| 보조 스윕 | `POST /api/v1/achievements/check` (기존 앱 10분 스로틀) | 훅 누락·과거분 보정용 안전망 |

streak 계산은 achievement_checker 의 날짜 유틸 재사용 (KST 달력일). 주차 키 = ISO week.

### 3-1. custom 행동 인증 흐름 ("달리기 매주 2회 인증"을 체크하는 방법)

```
회원 앱 [인증하기] (메모 선택 입력, 1일 1회)
   → gym_action_logs pending 생성 + 코치 PC SSE 알림
   → 코치 승인 방식 (규칙별 설정):
       · 승인 필요(기본): PC 인증 대기함에서 승인/거절 → approved 시 카운트 +1
       · 자동 인정: pending 없이 즉시 approved (신뢰 기반 챌린지용)
   → approved 시점에 reward_engine 평가 → "이번 주 2회 도달" 이면 지급
```

- 코치가 대신 기록도 가능 (PC 회원 상세 [인증 추가] — 회원이 앱을 안 쓰는 날 보정).
- 거절돼도 그날 재인증 불가(1일 1회 UNIQUE) — 분쟁은 코치가 [인증 추가]로 정정.
- 진행률은 회원 앱 도전 카드에 "이번 주 1/2 · 승인 대기 1건" 로 표시 (P3).

## 4. API (admin — @require_staff + 감사로그, 기존 패턴 복제)

| 메서드 | 경로 | 용도 |
|---|---|---|
| GET | `/api/v1/admin/gyms/<gid>/reward-rules` | 목록 (+지급 통계 요약) |
| POST | 〃 | 규칙 생성 (업적 보상 포함 시 커스텀 업적 자동 생성) |
| PATCH | `/api/v1/admin/reward-rules/<id>` | 수정 (조건 변경 시 기지급 grants 는 보존) |
| DELETE | 〃 | 삭제 (커스텀 업적 is_hidden 전환) |
| GET | `/api/v1/admin/reward-rules/<id>/grants` | 지급 이력 (누가·언제·몇 P) |
| GET | `/api/v1/admin/gyms/<gid>/action-logs?status=pending` | **인증 대기함** |
| PATCH | `/api/v1/admin/action-logs/<id>` | 승인/거절 |
| POST | `/api/v1/admin/members/<mid>/action-logs` | 코치 대리 인증 추가 (보정) |

회원 쪽 (X-Device-Id — JSON only, 대전제 ②):

| 메서드 | 경로 | 용도 |
|---|---|---|
| POST | `/api/v1/member/reward-rules/<id>/log` | **[인증하기]** — pending 생성 (1일 1회) |
| GET | `/api/v1/member/me/reward-progress` | 도전 카드 — 규칙별 이번 주기 진행률·대기 건수 |

## 5. PC 빌더 UI (`/settings/achievements` 상단에 "리워드 규칙" 섹션)

GTM 태그 편집기처럼 **문장형 빌더** — 드롭다운·입력을 채우면 문장이 완성된다:

```
[출석 ▾] 을  [매주 ▾]  [ 2 ]회 하면
→ [ 100 ] P 적립   ☑ 업적 부여 (이름 [주간 개근], 픽토그램 [불꽃 ▾], 희귀도 [희귀 ▾])
반복: (●) 주기마다 반복   ( ) 회원당 1회
미리보기: "출석을 매주 2회 하면 100P 적립 + '주간 개근' 업적 — 매주 반복"
```

custom 행동 선택 시 추가 슬롯: 행동 이름 입력([달리기]) + 인증 방식([코치 승인 ▾ | 자동 인정]).
미리보기: "달리기 인증(코치 승인)을 매주 2회 하면 100P — 매주 반복".

- 규칙 목록 = 문장 그대로 행 표시 + 활성 토글 + 이번 주 지급 수 + 이력 링크.
- **인증 대기함** — 가입 승인함과 같은 패턴: 회원·규칙·날짜·메모, 승인/거절 버튼,
  SSE 로 실시간 유입. 회원 상세에 [인증 추가] (코치 대리 기록).
- **프리셋 템플릿 6종** 버튼 (한 번에 채움): 3일 연속 출석 / 7일 연속 출석 /
  30일 연속 출석 / 주간 출석 N회 / 월간 기록 N회 / 첫 PR — 출석 스트릭 업적이
  여기서 부활한다 (지난 대수술로 삭제된 streak 업적의 대체 — 이번엔 실출석 기반).
- 검증: 문장이 안 되는 조합은 저장 불가 (streak + 반복, 보상 둘 다 0 등).

## 6. 앱 (apps/facing-app — 표시만, 계산 0)

- 커스텀 업적: 카탈로그에 섞여 자동 노출. 서버 `icon` 슬러그 → Material 아이콘
  매핑 렌더 (13종 — 지난 턴 한계 ② 해소). 포인트 보상은 업적 상세 시트에
  "달성 시 {P}P" 한 줄 표시.
- **도전 카드 (P3, custom 규칙의 회원 접점)**: 홈 마일스톤 아래 — 규칙 문장 +
  진행바("이번 주 1/2") + **[인증하기]** 버튼(메모 입력 시트, 1일 1회) +
  "승인 대기 1건" 상태. 승인/거절 결과는 종(알림함) 쪽지로 통지.
- 골든: 홈(도전 카드)·인증 시트·업적 전체·상세 4~5장 갱신.

## 7. 기존 시스템과의 관계 (충돌 정리)

| 기존 | 처리 |
|---|---|
| 포인트 설정(`point_rule` — 수동 적립 기준표) | **온존.** 수동(코치 클릭) vs 자동(규칙 엔진) 성격이 다름 — 페이지에 구분 문구. 장기 통합은 P4 검토 |
| 시드 업적 22종 + points 필드 | 온존 — 시드 업적의 points 적립(v3.2)은 그대로. 규칙 엔진은 커스텀 레이어 |
| 업적 설정 (마스터/개별 토글) | 커스텀 업적에도 동일 적용 (같은 disabled 메커니즘) |
| repeat_kind 표기 (v3.2 '반복 가능') | 시드 업적의 표기는 유지. **실반복은 규칙 엔진 전용** — 시드 업적 자체는 1회 해금 |

## 8. 단계별 계획 (승인 후 착수 순서)

| 단계 | 내용 | 산출 |
|---|---|---|
| **P1 백엔드 코어** | 스키마 3표+확장·마이그레이션 / reward_engine / 훅 3곳 / custom 인증 로그·승인 API / admin API 8개 + 회원 API 2개 / pytest (규칙 CRUD·streak·주간 반복 중복 차단·1일 1회 인증·승인→지급·멱등·커스텀 업적 생성) | 테스트 ~20건 |
| **P2 PC 빌더** | 문장형 빌더(custom 슬롯 포함) + 프리셋 6종 + 인증 대기함 + 이력 화면 / playwright 실기동 | 규칙 생성→인증→승인→지급 왕복 검증 |
| **P3 앱 표시** | 도전 카드 + [인증하기] 시트 + icon 렌더 + 업적 상세 포인트 줄 / 골든 갱신 | 앱 테스트 + 골든 |
| **P4 확장** | 트리거 4종(예약·결제·연장·생일) / point_rule 통합 검토 / 알림(해금 푸시) | 별도 승인 |

P1+P2 가 최소 배포 단위 (코치가 만들고 폰에 반영). P3 는 다음 배포 가능.

## 9. 결정 필요 2건 (추천 포함 — 승인 시 함께 답 주시면 됩니다)

1. **주(週) 경계**: ISO 주(월요일 시작) vs 일요일 시작(앱 goals 화면 방식).
   → **추천: 월요일 시작(ISO)** — 지급 키가 표준이라 셈이 단순, 체육관 주간 리듬과 일치.
2. **규칙 소급**: 규칙 생성 시점 이전 행동을 조건에 포함할지.
   → **추천: 미소급** (생성 시점 이후 행동만) — "만들자마자 전원 일괄 지급" 사고 방지.
   단 streak 는 진행 중이던 연속일을 인정 (오늘까지 6일 연속이면 내일 7일 충족).
3. **custom 인증 기본값**: 코치 승인 필요 vs 자동 인정.
   → **추천: 코치 승인 필요 기본** (자동 인정은 규칙별 옵트인) — 포인트가 걸린
   인증이라 기본은 사람 확인, 신뢰 챌린지만 코치가 자동으로 푼다.

## 10. 리스크 / 한계 선언

- 출석 정정(코치가 출석 취소) 시 이미 지급된 포인트는 자동 회수하지 않음 —
  코치가 포인트 탭에서 수동 조정 (v1 명시 한계, 이력 화면에서 추적 가능).
- 커스텀 업적 남발 시 회원 업적 화면이 길어짐 — 규칙 상한 20개/체육관.
- 반복 지급 폭주 방지: 규칙당 회원당 주기 1회(UNIQUE) + points 상한 100,000 재사용.

---

*작성 2026-08-20 · 승인 후 BRIEF §11.11 등재 + P1 착수.*
