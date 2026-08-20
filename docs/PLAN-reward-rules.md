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

## 4. API (admin — @require_staff + 감사로그, 기존 패턴 복제)

| 메서드 | 경로 | 용도 |
|---|---|---|
| GET | `/api/v1/admin/gyms/<gid>/reward-rules` | 목록 (+지급 통계 요약) |
| POST | 〃 | 규칙 생성 (업적 보상 포함 시 커스텀 업적 자동 생성) |
| PATCH | `/api/v1/admin/reward-rules/<id>` | 수정 (조건 변경 시 기지급 grants 는 보존) |
| DELETE | 〃 | 삭제 (커스텀 업적 is_hidden 전환) |
| GET | `/api/v1/admin/reward-rules/<id>/grants` | 지급 이력 (누가·언제·몇 P) |

회원 쪽은 신규 API 없음 — 기존 `/api/v1/achievements`(커스텀 포함)·포인트 잔액으로 자연 반영.
(P3 에서 진행률 노출 시 `/api/v1/member/me/reward-progress` 1개 추가.)

## 5. PC 빌더 UI (`/settings/achievements` 상단에 "리워드 규칙" 섹션)

GTM 태그 편집기처럼 **문장형 빌더** — 드롭다운·입력을 채우면 문장이 완성된다:

```
[출석 ▾] 을  [매주 ▾]  [ 2 ]회 하면
→ [ 100 ] P 적립   ☑ 업적 부여 (이름 [주간 개근], 픽토그램 [불꽃 ▾], 희귀도 [희귀 ▾])
반복: (●) 주기마다 반복   ( ) 회원당 1회
미리보기: "출석을 매주 2회 하면 100P 적립 + '주간 개근' 업적 — 매주 반복"
```

- 규칙 목록 = 문장 그대로 행 표시 + 활성 토글 + 이번 주 지급 수 + 이력 링크.
- **프리셋 템플릿 6종** 버튼 (한 번에 채움): 3일 연속 출석 / 7일 연속 출석 /
  30일 연속 출석 / 주간 출석 N회 / 월간 기록 N회 / 첫 PR — 출석 스트릭 업적이
  여기서 부활한다 (지난 대수술로 삭제된 streak 업적의 대체 — 이번엔 실출석 기반).
- 검증: 문장이 안 되는 조합은 저장 불가 (streak + 반복, 보상 둘 다 0 등).

## 6. 앱 (apps/facing-app — 표시만, 계산 0)

- 커스텀 업적: 카탈로그에 섞여 자동 노출. 서버 `icon` 슬러그 → Material 아이콘
  매핑 렌더 (13종 — 지난 턴 한계 ② 해소). 포인트 보상은 업적 상세 시트에
  "달성 시 {P}P" 한 줄 표시.
- 반복 규칙 진행률 카드 (P3): 홈 마일스톤 아래 "이번 주 도전 — 출석 1/2" 진행바.
- 골든: 업적 전체·상세·홈 3~4장 갱신.

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
| **P1 백엔드 코어** | 스키마 2표+확장·마이그레이션 / reward_engine / 훅 3곳 / admin API 5개 / pytest (규칙 CRUD·streak·주간 반복 중복 차단·멱등·커스텀 업적 생성) | 테스트 ~15건 |
| **P2 PC 빌더** | 문장형 빌더 + 프리셋 6종 + 이력 화면 / playwright 실기동 | 규칙 생성→회원 폰 반영 왕복 검증 |
| **P3 앱 표시** | icon 렌더·업적 상세 포인트 줄·진행률 카드 / 골든 갱신 | 앱 테스트 + 골든 |
| **P4 확장** | 트리거 4종(예약·결제·연장·생일) / point_rule 통합 검토 / 알림(해금 푸시) | 별도 승인 |

P1+P2 가 최소 배포 단위 (코치가 만들고 폰에 반영). P3 는 다음 배포 가능.

## 9. 결정 필요 2건 (추천 포함 — 승인 시 함께 답 주시면 됩니다)

1. **주(週) 경계**: ISO 주(월요일 시작) vs 일요일 시작(앱 goals 화면 방식).
   → **추천: 월요일 시작(ISO)** — 지급 키가 표준이라 셈이 단순, 체육관 주간 리듬과 일치.
2. **규칙 소급**: 규칙 생성 시점 이전 행동을 조건에 포함할지.
   → **추천: 미소급** (생성 시점 이후 행동만) — "만들자마자 전원 일괄 지급" 사고 방지.
   단 streak 는 진행 중이던 연속일을 인정 (오늘까지 6일 연속이면 내일 7일 충족).

## 10. 리스크 / 한계 선언

- 출석 정정(코치가 출석 취소) 시 이미 지급된 포인트는 자동 회수하지 않음 —
  코치가 포인트 탭에서 수동 조정 (v1 명시 한계, 이력 화면에서 추적 가능).
- 커스텀 업적 남발 시 회원 업적 화면이 길어짐 — 규칙 상한 20개/체육관.
- 반복 지급 폭주 방지: 규칙당 회원당 주기 1회(UNIQUE) + points 상한 100,000 재사용.

---

*작성 2026-08-20 · 승인 후 BRIEF §11.11 등재 + P1 착수.*
