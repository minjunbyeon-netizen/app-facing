# PC 어드민 ↔ 폰 facing-app 1:1 데이터 매칭 전수조사

생성: 2026-05-24 08:30
범위: PC 어드민(`web/facing-admin/`) ↔ Flutter 앱(`apps/facing-app/`) 양방향 동기화
백엔드: `services/facing/` Flask (localhost:5060) — 같은 SQLAlchemy 모델 공유

## 요약

| 영역 | PC→폰 | 폰→PC | 즉시 SSE | 상태 |
|---|---|---|---|---|
| A. 회원 추가/수정/탈퇴 | ⚠ DB 동기 / SSE X | OK (join 요청) | X | refresh로만 |
| B. 코치 관리 | ⚠ DB 동기 / SSE X | OK (pair) | X | refresh로만 |
| C. 클래스 예약 | **❌ 폰 화면 부재** | - | OK (취소만) | **블로커** |
| D. 회원권·결제 | **❌ 폰 화면 부재** | - | X | **블로커** |
| E. 전자계약서 | **❌ 폰 화면 부재** | - | X | **블로커** |
| F. 공지·타임라인 | OK | - | X | refresh로만 |
| G. 출석(QR) | OK | OK | X | refresh로만 |
| H. 박스 정보 | OK | - | X | refresh로만 |
| I. SSE 구독 | - | - | **❌ 폰 측 클라이언트 부재** | **블로커** |
| J. 프로필 (폰→PC) | - | OK | X | OK |

## 상세

### A. 회원 (member)

| 검증 | API | 결과 |
|---|---|---|
| A1. PC 회원 추가 → DB | `POST /api/v1/admin/gyms/<id>/members` | DB 기록됨 (GymMember + GymMemberProfile) |
| A2. 폰 회원 list 갱신 | `GET /api/v1/gyms/<id>/members` (코치만) | 같은 GymMember 테이블 조회 — refresh 시 보임 |
| A3. PC 회원 수정 → 폰 반영 | `PATCH /api/v1/admin/members/<mid>` | DB 기록. **SSE publish 없음** |
| A4. PC 탈퇴 → 폰 사라짐 | `POST /api/v1/admin/members/<mid>/leave` | status=left 변경. **SSE publish 없음** |
| A5. 폰→PC: 폰이 박스 join 요청 → PC 승인 list | `POST /api/v1/gyms/<id>/join` | OK |

raw fact: 같은 DB 보지만 폰은 SSE 미구독 → 폰 화면 떠 있을 때 PC 변경 즉시 반영 X.

### B. 코치

| 검증 | API | 결과 |
|---|---|---|
| B1. PC 코치 추가 | `POST /api/v1/admin/gyms/<id>/coaches` | OK |
| B2. 폰 코치 list 반영 | (해당 API 없음) | 폰에 코치 list 화면 없음 — 코치 본인이 페어링만 |
| B3. PC 페어링 코드 발급 | `POST /api/v1/admin/gyms/<id>/coaches/<login_id>/pairing-code` | OK |
| B4. 폰 페어링 코드 입력 | `POST /api/v1/coach/pair` | OK (debug 메뉴) |
| B5. PC 시급/employment_type 변경 → 폰 자기 정보 | `PATCH .../coaches/<login_id>` | DB 변경. 폰 자기 정보 조회 화면 없음. |

### C. 클래스 예약

| 검증 | API | 결과 |
|---|---|---|
| C1. PC 클래스 생성 | `POST /api/v1/admin/gyms/<id>/classes` | OK |
| C2. 폰 회원 예약 가능 | `POST /api/v1/member/classes/<id>/reservations` | **백엔드 OK, 폰 화면 부재** |
| C3. 폰 예약 취소 → PC 반영 | `DELETE /api/v1/member/reservations/<id>` | OK, SSE publish (`member_reservation_cancelled`, `member_promoted_from_waitlist`) |
| C4. PC 클래스 취소 → 폰 알림 | `POST /api/v1/admin/classes/<id>/cancel` | SSE `class_cancelled` publish함 |

**블로커**: 폰에 클래스/예약 화면(`features/classes/` 등) 부재.

### D. 회원권·결제

| 검증 | API | 결과 |
|---|---|---|
| D1. PC 회원권 발급 | `POST /api/v1/admin/members/<mid>/memberships` | DB OK. **SSE publish 없음** |
| D2. 폰 회원권 표시 | (해당 API 없음) | **폰 화면 부재** |
| D3. PC 결제 추가 | (별도 endpoint — billing.py) | 백엔드 OK |
| D4. 폰 결제 history | (해당 API 없음) | **폰 화면 부재** |
| D5. PC 환불 | (별도 endpoint) | 백엔드 OK. 폰 표시 X |

**블로커**: 폰에 회원권/결제 history 화면 부재.

### E. 전자계약서

| 검증 | API | 결과 |
|---|---|---|
| E1. PC 계약서 발급 | `POST /api/v1/admin/members/<mid>/contracts` | OK |
| E2. 폰 회원 서명 화면 | `GET /api/v1/member/contracts/<id>` + `POST .../sign` | 백엔드 OK, **폰 화면 부재** |
| E3. 폰 서명 → PC 즉시 | (sign API) | **SSE publish 없음** |

**블로커**: 폰에 계약서 화면 부재.

### F. 공지·타임라인

| 검증 | API | 결과 |
|---|---|---|
| F1. PC 공지 작성 | `POST /api/v1/coach/gyms/<id>/announcements` (코치 권한) | OK |
| F2. 폰 타임라인 반영 | `GET /api/v1/member/announcements` | OK (refresh로만) |
| F3. 핀고정 | (필드 존재, UI에서 토글) | OK |

⚠ SSE 미발사 — 폰 화면 떠 있을 때 새 공지 즉시 안 보임. refresh 필요.

### G. 출석

| 검증 | API | 결과 |
|---|---|---|
| G1. 폰 QR 체크인 → PC dashboard | `POST /api/v1/attendances` (token) | OK (체크인 self) |
| G2. PC 수동 출석 → 폰 history | (확인 필요) | - |

### H. 박스 정보

| 검증 | API | 결과 |
|---|---|---|
| H1. PC 박스 이름·전화 변경 | `PATCH /api/v1/gyms/<id>/profile` | OK |
| H2. 폰 즉시 반영 | (mine endpoint 등) | refresh로만 |

### I. SSE 구독 (양방향 실시간)

| 검증 | API | 결과 |
|---|---|---|
| I1. PC 어드민 SSE 구독 | `GET /api/v1/admin/events` (구현됨) | 백엔드 OK |
| I2. 폰 SSE 구독 | `GET /api/v1/member/events` 또는 같은 admin events | **❌ 폰 EventSource 클라이언트 부재** |
| I3. 폰 SSE 미구현 영향 | - | PC가 SSE 발사해도 폰은 못 받음 → 모든 실시간 알림 X |

**블로커**: `lib/core/` 에 EventSource/SSE client 없음. 모든 폰 화면은 폴링·refresh 만으로 갱신.

### J. 프로필 (폰→PC)

| 검증 | API | 결과 |
|---|---|---|
| J1. 폰 자기 프로필 편집 | `POST /api/v1/profile/info` | OK |
| J2. PC 회원 상세 즉시 반영 | PC `/members/<mid>` refresh | OK (같은 DB) |

## fix 우선순위 결정

이번 세션 budget 40분, 발견된 미반영 항목:
1. **P0 (블로커)**: 폰에 회원권 표시 / 클래스 예약 / 계약서 화면 부재 → 신규 화면 신설 작업으로 1~2 sprint 단위. 단일 세션 X.
2. **P0 (작은 fix)**: PC 어드민 변경 시 SSE publish 안 함 → 백엔드 add `sse_publish(...)` 호출 N건.
3. **P1**: 폰 측 SSE 클라이언트 추가 — 새 코드 100~200줄. 시간 허락 시.
4. **P2**: 폰 측 회원/공지 list 화면 자동 폴링 (10초마다 silent refresh) — UX 보완.

이번 세션 fix: **#2 (SSE publish 백엔드 추가)** 를 모든 admin 변경 endpoint에 적용. 이후 #3 폰 SSE 클라이언트 신설.
