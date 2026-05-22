# facing — 시스템 아키텍처 브리프 (SSOT)

> **작성일**: 2026-05-22
> **상태**: 합의 완료 — 이후 모든 작업의 중심 문서
> **적용 범위**: `apps/facing-app` (폰) + `web/facing-admin` (PC) + `services/facing` (백엔드)
>
> ⚠️ **이 문서가 우선이에요.** 코드 변경·새 기능 설계 시 이 브리프와 충돌하면 브리프를 따르고, 브리프를 바꿔야 한다면 사용자 명시 승인 후 문서 먼저 갱신해요.

---

## 0. 한 줄 요약

> **폰은 일상, PC는 운영. 백엔드는 단일 진실. 역할은 회원·코치·사장 3개. 실시간 동기화는 SSE.**

---

## 1. 시스템 구성

```
                      ┌────────────────────────┐
                      │ Backend (Flask+SQLite) │
                      │  services/facing       │
                      │  단일 진실 (SSOT)      │
                      └───┬────────────────┬───┘
                          │ REST + SSE     │ REST + SSE
                          │                │
              ┌───────────▼──────┐   ┌─────▼──────────────┐
              │ 폰 앱 (Flutter)  │   │ PC 웹 (Flask)      │
              │ apps/facing-app  │   │ web/facing-admin   │
              │                  │   │                    │
              │ 회원 + 코치 모드 │   │ 사장 전용          │
              └──────────────────┘   └────────────────────┘
```

- **백엔드 1개** (`services/facing`, Flask + SQLite) — 단일 진실 (SSOT)
- **클라이언트 2개**
  - **폰** (`apps/facing-app`, Flutter): 회원 + 코치 일상
  - **PC 웹** (`web/facing-admin`, Flask + 바닐라 HTML/CSS/JS): 사장 운영
- **통신**: REST + SSE (Server-Sent Events)

폰과 PC 가 같은 DB·같은 API 를 다른 화면으로 본다는 게 핵심이에요. 클라이언트는 따로지만 데이터는 한 곳.

---

## 2. RBAC — 3개 역할

| 역할 | 클라이언트 | 권한 |
|---|---|---|
| **회원** (member) | 폰 | 자기 WOD·페이싱·결과 제출·박스 공지 보기·코치에게 쪽지·배지·tier |
| **코치** (coach) | 폰 | 회원 모든 권한 + WOD 게시·회원 목록·쪽지·피드백·가입 승인 |
| **사장** (boss) | PC | 회원 DB CRUD·회원권 발급/연장·락커·전자계약·통계 (게이미피케이션 X) |

- 사장은 **회원이 아니라 운영자** 라서 폰을 안 써요. PC 에서 ID/PW 로 로그인 (회원·코치는 device_hash 익명).
- 한 사람이 두 역할 가질 수 있어요 (예: 박지훈 = 사장 + 코치). DB 상으로는 `gym_managers` 에 두 행 (또는 role 컬럼 set 형).

---

## 3. 신규 가입 흐름 (가장 중요한 데모 흐름)

```
[현장]                      [폰 회원]                 [PC 사장]
────────                    ──────────                ──────────
체육관 방문
      │
      ▼
QR 또는 카운터 안내    →    1. 박스 찾기 화면
                            2. SEONGSU 선택
                            3. 가입 신청 (pending)
                                 │
                                 │ POST /join
                                 ▼
                                                      ─── SSE ───▶ 4. 알림 토스트
                                                                    "신규 신청 1건"
                                                                      │
                                                                      ▼
                                                                    5. 회원 카드 클릭
                                                                    6. 이름·생년·전화·
                                                                       회원권·락커 입력
                                                                    7. "승인 + 등록"
                                                                      │
                                                                      │ POST /admin/members
                                                 ◀─── SSE/Push ───   ▼
                        8. "등록 완료" 알림   ◀
                           NOTICE 탭에 박스
                           정보 카드 자동 노출
```

회의 데모 핵심 흐름. **폰에서 시작한 신청이 SSE 로 PC 사장 화면에 실시간 푸시**.

---

## 4. SSE 채널

```python
GET /api/v1/admin/events  → Server-Sent Events stream (사장 PC 구독)
GET /api/v1/member/events → 회원 폰 구독 (또는 30초 poll fallback)

이벤트 종류:
- member_join_request   : 폰 → 사장 (신규 신청)
- member_approved       : 사장 → 폰 (승인됨)
- member_expiring       : 시스템 → 사장 (만료 14일 내)
- wod_result_posted     : 폰 → 코치 (회원 결과 제출)
- locker_freed          : 사장 → 사장 (락커 해제)
```

- **모바일은 SSE 끊김 잦음** → 폰은 SSE 시도 + 실패 시 30초 poll fallback
- **PC 브라우저는 EventSource 안정적** → SSE 만

---

## 5. 데이터 모델 — 신규 테이블 6개

| 테이블 | 누가 쓰나 | 핵심 컬럼 |
|---|---|---|
| `gym_managers` | 사장/코치 권한 분리 | gym_id, login_id, password_hash, role (boss/coach), name |
| `gym_member_profiles` | 사장 회원 DB | gym_id, member_id (FK), name, gender, birth_date, phone, level, note |
| `gym_memberships` | 회원권 관리 | member_id, plan_name, start_date, end_date, price, status |
| `gym_lockers` | 락커 관리 | gym_id, locker_no, member_id, start_date, end_date |
| `gym_contracts` | 전자계약 | member_id, body, signed_at, signature_url, ip |
| `gym_attendances` | 통계용 | member_id, checked_at |

기존 `gym_members` (device_hash 기반) 와 1:1 외래키. 폰은 device_hash 그대로 쓰고, PC 는 member_id 기반 + 사장 로그인.

기존 테이블 (유지): gyms · gym_members · gym_wod_posts · gym_wod_results · gym_messages · gym_announcements · gym_coach_feedback · gym_member_requests · gym_profile (박스 정보).

---

## 6. 사장 통계 — 게이미피케이션 빼고 운영 숫자만

```
┌─ 오늘 ────────────────────┐  ┌─ 이번 달 ──────────────────┐
│ 출석 회원   38명          │  │ 신규 가입       12명       │
│ WOD 게시    2건           │  │ 만료 회원       8명        │
│ 가입 신청   3건 (대기)    │  │ 만료 임박       5명        │
└───────────────────────────┘  │ 매출 추정    8,400,000원   │
                               └────────────────────────────┘
┌─ Retention ───────────────┐  ┌─ 락커 점유율 ──────────────┐
│ 3개월 retention   78%     │  │ A존  10/12 (83%)           │
│ 6개월 retention   62%     │  │ B존  16/22 (72%)           │
│ 1년  retention    44%     │  │ 만료 임박     2개          │
└───────────────────────────┘  └────────────────────────────┘
```

- **게이미피케이션(배지·streak·tier)** 은 회원 폰에는 그대로 유지 (회원 유지 동기), 사장 화면은 **숫자만**
- 사장 = 결정 빠르게 내릴 수 있는 운영 지표 중심

---

## 7. 인증·보안

| 플랫폼 | 인증 방식 | 비고 |
|---|---|---|
| 폰 (회원·코치) | device_hash (X-Device-Id 헤더) | 현재 그대로. 익명 |
| PC (사장) | ID/PW + 세션 쿠키 (httpOnly Secure) | 신규. bcrypt cost ≥ 12 |
| 시드 계정 | `boss_seongsu / 1234` (데모) + `APP_TEST_ADMIN_*` env (슈퍼) | CLAUDE.md §3-A 의무 시드 |

- 회원 개인정보(이름·생년·전화·서명)는 들어가는 순간 **개인정보보호법 적용**. 암호화·접근로그·감사 필수.
- 사장 mutation 액션(승인/연장/락커 배정)은 **GET 절대 금지** (CSRF). POST/PATCH/DELETE + CSRF 토큰.

---

## 8. 게이미피케이션 정책

- **회원 폰** — 배지·tier·streak·season 유지. 회원 유지율 핵심 가치.
- **사장 PC** — 게이미피케이션 노출 X. 사장은 운영 숫자만.
- **코치 폰** — 회원 게이미피케이션 진행도 조회 가능 (코칭 도구), 단 사장처럼 retention 통계는 X.

---

## 9. 빌드 우선순위

| Phase | 작업 | 무게 |
|---|---|---|
| **1. 백엔드 기반** | 신규 6 테이블 마이그레이션 + 사장 로그인 + SSE 채널 | 2일 |
| **2. PC 사장 화면 풀** | 회원 DB CRUD + 회원권 + 락커 + 통계 대시보드 + 전자계약 + SSE 알림 | 3일 |
| **3. 폰 가입 흐름 연동** | 박스 찾기 → 신청 → SSE 푸시 알림 수신 → 박스 정보 hydrate | 1일 |
| **4. 폰 코치 모드 보강** | 사장 등록 회원과 device_hash 매핑 + 회원 목록 동기화 | 1일 |

총 약 7일 풀빌드. mockup (`web/facing-admin` v0.2) 은 이미 1번 일부 + 2번 부분 완료 상태.

---

## 10. 결정 사항 / 합의

| # | 결정 | 근거 |
|---|---|---|
| D1 | 백엔드 1개 (services/facing) — 분리 X | SSOT 단일성, 작업·인증 일관성 |
| D2 | 폰은 device_hash 익명 유지 | 회원 가입장벽 ↓, 기존 코드 호환 |
| D3 | 사장은 ID/PW 로그인 | 개인정보 다루므로 신원 식별 필수 |
| D4 | SSE 사용 (WebSocket X) | 단방향 푸시면 충분, Flask Werkzeug 호환 |
| D5 | 사장 화면 게이미피케이션 X | 운영자 결정 속도 중심, 숫자만 |
| D6 | 폰·PC 모두 같은 박스(gym_id) 기반 | RBAC 가 gym 단위로 분리 |
| D7 | 신규 가입 = 폰 시작, PC 완성 | 사용자가 명시한 핵심 흐름 |

---

## 11. 변경 절차

이 브리프와 충돌하는 코드 변경이 필요할 때:
1. Claude 가 충돌 감지 → 사용자에게 보고 ("이 브리프와 어긋나는데 어느 쪽 우선?")
2. 사용자 명시 승인 → 브리프 먼저 갱신 → 코드 변경
3. 변경 이력은 §10 결정 사항 표에 D8, D9... 로 추가

브리프 우선 원칙. 코드만 갱신하고 브리프 방치 금지 (글로벌 §0-B SSOT 룰).
