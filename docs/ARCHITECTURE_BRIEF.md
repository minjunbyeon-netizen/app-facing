# facing — 시스템 아키텍처 브리프 (SSOT)

> **작성일**: 2026-05-22
> **상태**: 합의 완료 — 이후 모든 작업의 중심 문서
> **적용 범위**: `apps/facing-app` (폰) + `web/facing-admin` (PC) + `services/facing` (백엔드)
>
> ⚠️ **이 문서가 우선이에요.** 코드 변경·새 기능 설계 시 이 브리프와 충돌하면 브리프를 따르고, 브리프를 바꿔야 한다면 사용자 명시 승인 후 문서 먼저 갱신해요.

---

## 0. 한 줄 요약

> **폰은 일상, PC는 운영. 백엔드는 단일 진실. 역할은 회원·코치·사장 3개. 실시간 동기화는 SSE.**

**시스템 카테고리**: CrossFit 박스 전용 **Vertical SaaS for Gym** (B2B2C · 멀티테넌시 + flat RBAC 3-tier + 실시간 SSE). 해외 동종: Wodify·PushPress·Mindbody. 아키텍처 패턴·법규·학술 근거 SSOT → `~/.claude/reference/study/gym-management-saas.md` (15 sub-topic · 94 source).

---

## 0.1. PHASE4 시작 (2026-05-23)

> **상태**: PHASE3 P0 18 + P1 24 + P2 14 = 56 task 완료 후 진입 예정. 본 섹션은 PHASE4 계획 선등록.
> **상세 로드맵**: `docs/PHASE4_ROADMAP.md`

### 0.1.1. PHASE4 목표 — 듀얼 포지셔닝 확립

**"linko 는 운영, facing 은 운영 + 선수."**

linko.my (한국 1위급, 350+ 박스) 의 운영 자동화 7 모듈을 흡수하면서, facing 만의 선수 도구 4 모듈을 동시에 강화해 패스트팔로워 함정을 회피한다.

### 0.1.2. 11 모듈 요약

**흡수 7 모듈 (linko.my 추격)**:
1. §1.1 예약 시스템 (Class Reservation) — **P0** 1주
2. §1.2 카카오 알림톡 알림 자동화 — **P0** 3일 + NHN 사전심사 1주
3. §1.3 전자계약 (e-Sign, PDF, audit hash) — **P0** 1주
4. §1.4 다지점 그룹 (gym_group + RLS) — P1 2주
5. §1.5 Toss 빌링키 자동결제 + 재시도 + grace period — **P0** 1주
6. §1.6 WOD 디자인 도구 + 월간 캘린더 + 복붙 — P1 1주
7. §1.7 AI 코칭 보조 (Claude API, HITL 의무) — P2 3일

**차별 강화 4 모듈 (facing 만)**:
8. §2.1 W-prime·CGM 페이싱 알고리즘 정밀화 — **P0** 2주
9. §2.2 5-Tier Engine 백분위 + 박스 leaderboard — P1 3일
10. §2.3 Games 선수 어휘·톤 PC 확장 — P2 2일
11. §2.4 듀얼 포지셔닝 B2B2C 데이터 브릿지 — **P0** 1주

**P0 총 공수**: ~6.4주 (parallel 시 ~5주) / **전체**: ~9~10주

### 0.1.3. B2B2C 데이터 브릿지 흐름

```
[폰 facing-app]               [PC facing-admin]
  회원 1RM·Engine·Tier   →    회원 등록 시 hydrate
        ↓                            ↓
    [services/facing 백엔드]
        ↓
   [linko 운영 자동화 흡수]
   예약·알림톡·전자계약·다지점
```

회원이 facing-app 으로 입력한 1RM·Engine·Tier → 박스 가입 시 코치에게 자동 공유 (PIPA §22 별도 동의). linko 가 따라올 수 없는 B2B2C 융합 영역.

---

## 0.5. 인프라 카탈로그 (헷갈림 차단 — INDEX)

### 0.5.1. 포트 · URL · 환경

| 컴포넌트 | 로컬 URL | Flask 환경 | 에뮬레이터 호출 URL | 실기/배포 호출 URL | 비고 |
|---|---|---|---|---|---|
| **백엔드** `services/facing` | `http://localhost:5060` | `debug=True` (Werkzeug dev) | `http://10.0.2.2:5060` | `http://<LAN-IP>:5060` 또는 Railway URL | 폰·PC 둘 다 호출. host=`0.0.0.0` 으로 LISTEN |
| **PC 사장 웹** `web/facing-admin` | `http://localhost:8081` | `debug=True` (Werkzeug dev) | (해당 없음) | (Phase 2 후반 Railway) | **5060/5061 은 Chrome `ERR_UNSAFE_PORT` 차단**. 8081 사용 필수 |
| **폰 앱** `apps/facing-app` | (해당 없음) | Flutter | `flutter run` 시 `--dart-define=API_BASE_URL=http://10.0.2.2:5060` | release APK 빌드 시 `--dart-define=API_BASE_URL=http://192.168.x.x:5060` 또는 배포 URL | base URL 미지정 default = `10.0.2.2:5060` (에뮬레이터 전용) |

### 0.5.2. 데이터베이스

| 컴포넌트 | 경로 | 형식 | git 추적 | 비고 |
|---|---|---|---|---|
| 백엔드 메인 DB | `services/facing/data/facing.db` | SQLite | **추적 X** (.gitignore) | 페르소나·박스·WOD·결과 등 모든 진실 |
| 백엔드 WAL | `facing.db-wal` / `facing.db-shm` | SQLite WAL | 추적 X | 자동 생성 |
| PC 사장 mockup | `web/facing-admin/data/mock_*.json` | JSON | 추적 O (회의 데모용) | Phase 1.5 에서 `facing.db` 의 신규 6 테이블로 마이그레이션 → 폐기 |
| 페르소나 SSOT | `services/facing/data/personas.json` | JSON | 추적 O | 시드 스크립트 입력 |

### 0.5.3. 환경변수

| 변수 | 위치 | 값 | 용도 |
|---|---|---|---|
| `SECRET_KEY` | `C:/dev/.env` (글로벌) 또는 `services/facing/.env` | 사용자 정의 (없으면 default `facing_default_salt`) | device_hash 솔트. 변경 시 페르소나 해시 모두 어긋남 |
| `PORT` | `services/facing/.env` | 5060 | 백엔드 포트 (글로벌 PORT 와 분리) |
| `APP_TEST_ADMIN_ID` / `APP_TEST_ADMIN_PASSWORD` | `C:/dev/.env` | 사용자 정의 | 슈퍼관리자 시드 (CLAUDE.md §3-A) |
| `ANTHROPIC_API_KEY` | 배포 PaaS 만 (Railway 콘솔) | Anthropic key | **로컬 .env 에 절대 X** (CLI 우회용) |
| `API_BASE_URL` | Flutter dart-define (빌드 시) | URL | facing-app 백엔드 호출 base |

### 0.5.4. 데모 계정 (의무 시드)

| ID | PW | 권한 | 시드 위치 |
|---|---|---|---|
| `admin` | `1234` | 슈퍼관리자 (모든 환경 시드) | 백엔드 부팅 시 자동 |
| `${APP_TEST_ADMIN_ID}` | `${APP_TEST_ADMIN_PASSWORD}` | 슈퍼관리자 (env 있을 때만, 프로덕션 skip) | env 기반 |
| `boss_seongsu` | `1234` | FACING SEONGSU 사장 (PC 웹) | Phase 1 마이그레이션 |
| `coach_park` | `1234` | FACING SEONGSU 코치 (폰 페어링 가능) | Phase 1 |

폰 페르소나 4명 (`persona-coach-park-2026` 등) 은 device_id 시드로 별도. 위 ID/PW 계정은 PC 사장 웹 로그인 전용.

### 0.5.5. 자주 헷갈리는 점

- ⚠️ **에뮬레이터 `10.0.2.2`** 는 Android 가상 호스트 PC 별칭. 실기는 LAN IP (예: `192.168.1.100`) 또는 배포 URL.
- ⚠️ **`localhost:5061` Chrome 에서 안 열림** — SIP-TLS 표준 포트라 차단. 사장 웹은 8081.
- ⚠️ **`SECRET_KEY` 변경하면 페르소나 해시 다 어긋남** — 시드 재실행 필요. 회의 직전엔 default salt 유지.
- ⚠️ **Windows bash + curl 한글 payload 깨짐** — 검증용으로 curl 쓸 때만. 폰·웹 폼은 정상 (UTF-8 자동).
- ⚠️ **debug APK 약 178MB / release APK 약 30MB** — 회의 시연은 페르소나 스위처 필요 → debug 필수.

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

**PHASE4 B2B2C 확장 (§0.1.3 참조)**:

```
[폰 facing-app]                    [PC facing-admin]
  회원 1RM·Engine·Tier     →       회원 등록 시 hydrate
  (device_hash 익명 → 동의 연결)         ↓
        ↓                     코치 클래스 12명 페이싱 카드
    [services/facing 백엔드 — 단일 진실]
        ↓
   [PHASE4 운영 자동화 흡수]
   예약·카카오 알림톡·전자계약·다지점·Toss 빌링키
```

---

## 2. RBAC — 3개 역할 (+ 매니저 1)

| 역할 | 클라이언트 | 권한 |
|---|---|---|
| **회원** (member) | 폰 | 자기 WOD·페이싱·결과 제출·박스 공지 보기·코치에게 쪽지·배지·tier |
| **코치** (coach) | 폰 | 회원 모든 권한 + WOD 게시·회원 목록·쪽지·피드백·가입 승인 |
| **사장** (boss) | **PC 주 + 폰 보조 (PHASE5)** | 회원 DB CRUD·회원권 발급/연장·락커·전자계약·통계 (게이미피케이션 X) |
| **매니저** (manager) | **PC 주 + 폰 보조 (PHASE5)** | 사장 위임 운영권 (회원 운영·예약 응대·결제 확인) |

- **사장은 운영자**, PHASE5 부터는 **외출·이동 중 폰 보조 운영 가능** (linko 격차 해소 — `docs/PHASE5_ROADMAP.md` 참조). PC 가 주, 폰이 보조. **폰 사장 로그인 = PC 동일 ID/PW** 사용. 회원·코치는 device_hash 익명 유지.
- 한 사람이 두 역할 가질 수 있어요 (예: 박지훈 = 사장 + 코치). DB 상으로는 `gym_managers` 에 두 행 (또는 role 컬럼 set 형).
- **PHASE5 추가 가정**: facing-app 진입 시 `user_type` 분기 — `device_hash` (회원·코치 익명) vs `login_id` (사장·매니저 ID/PW). 같은 앱 바이너리, 다른 진입 플로우.

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
| `gym_managers` | 사장/코치 권한 분리 (다중 박스 OK) | gym_id, login_id, password_hash, role (boss/coach), name, phone, hired_at, left_at |
| `gym_member_profiles` | 사장 회원 DB | gym_id, member_id (FK), name, gender, birth_date, phone, level, preferred_time_slot, preferred_coach_gender, safety_note, note |
| `gym_memberships` | 회원권 관리 | member_id, plan_name, start_date, end_date, price, status (active/expired/refunded), refund_amount, refunded_at |
| `gym_lockers` | 락커 관리 | gym_id, locker_no, member_id, start_date, end_date |
| `gym_contracts` | 전자계약 | member_id, body, signed_at, signature_url, ip, pdf_url |
| `gym_attendances` | 통계용 | member_id, gym_id, checked_at, source (qr/manual) |
| `gym_inquiries` | 회원→사장 직접 문의 (환불·계약·분쟁) | gym_id, member_id, subject, body, status, responded_at |
| `audit_logs` | 개인정보 접근·변경 감사 | actor_login_id, action, target_member_id, payload_hash, created_at, ip |

기존 `gym_members` (device_hash 기반) 와 1:1 외래키. 폰은 device_hash 그대로 쓰고, PC 는 member_id 기반 + 사장 로그인.

**기존 `gym_members` 에 컬럼 추가**: `status` (`pending`/`approved`/`rejected`/`left`/`removed`), `left_at`, `left_reason` — **M14 자발적 탈퇴 처리** 위해 필요.

**`gym_managers` 다중 박스 (M7·M8)**: 한 login_id 가 박스 2곳 운영 시 두 행 INSERT (gym_id 다르게). PK = (gym_id, login_id) 복합키. 사장 로그인 시 박스 선택 토글 (또는 통합 대시보드).

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

### 6.1 측정 알고리즘 (M13 — 통계 정의 명시)

| 지표 | 정의 | SQL 의사코드 |
|---|---|---|
| 오늘 출석 | 오늘(KST) `gym_attendances.checked_at` UNIQUE(member_id) 수 | `COUNT(DISTINCT member_id) WHERE DATE(checked_at)=today` |
| 이번 달 신규 가입 | 이번 달 안에 `gym_memberships.start_date` ≥ first_day_of_month | `COUNT WHERE start_date BETWEEN month_start AND month_end` |
| 만료 임박 | `end_date` 가 오늘로부터 14일 이내 + status=active | `WHERE end_date BETWEEN today AND today+14d` |
| 매출 추정 (이번 달) | 이번 달 시작된 회원권 price 합 + 갱신 매출 | `SUM(price) WHERE start_date IN month` |
| 3개월 retention | M-3 코호트(3개월 전 가입자) 중 지금까지 1회 이상 출석한 비율 | `cohort 가입자 N / 그 중 M+0~M+3 동안 attendance 1+ 인원` |
| 6개월 retention | M-6 코호트 | 동일 패턴 |
| 1년 retention | M-12 코호트 | 동일 패턴 |
| 락커 점유율 | `gym_lockers` 중 `member_id IS NOT NULL` 비율 | `COUNT(occupied) / COUNT(total)` |
| 여성 비중 (M10) | gym_member_profiles WHERE gender='여' 비율 | gender 분포 |
| 여성 시간대 분포 (M10) | preferred_time_slot 별 GROUP BY | bar chart |

retention 정의 = "코호트(가입 월) 의 N개월 후 시점에 attendance ≥ 1 인 비율". 출석 기록 없으면 "left" 로 간주 (자발적 탈퇴와 별개).

---

## 7. 인증·보안

| 플랫폼 | 인증 방식 | 비고 |
|---|---|---|
| 폰 (회원·코치) | device_hash (X-Device-Id 헤더) | 현재 그대로. 익명 |
| PC (사장) | ID/PW + 세션 쿠키 (httpOnly Secure) | 신규. bcrypt cost ≥ 12 |
| 시드 계정 | `boss_seongsu / 1234` (데모) + `APP_TEST_ADMIN_*` env (슈퍼) | CLAUDE.md §3-A 의무 시드 |
| 출석 체크인 | 1회용 QR (60초 만료) | 박스 입구 디스플레이가 토큰 갱신, 폰이 스캔 → POST `/attendances` |
| 결제 (Toss Payments) | webhook HMAC-SHA256 서명 검증 + timing-safe compare + idempotency key | reference/payment.md + reference/webhook.md 준수 |

- 회원 개인정보(이름·생년·전화·서명)는 들어가는 순간 **개인정보보호법 적용**. 암호화·접근로그·감사 필수.
- 사장 mutation 액션(승인/연장/락커 배정)은 **GET 절대 금지** (CSRF). POST/PATCH/DELETE + CSRF 토큰.
- 결제 webhook idempotency: 같은 Toss orderId 두 번 들어와도 1회만 처리.

### 7.1 개인정보 보존·삭제 (M5 — 개인정보보호법 §29 준수)

| 데이터 | 보존 기간 | 삭제 시점 | 근거 |
|---|---|---|---|
| 회원 이름·전화·생년 | 회원 탈퇴 후 5년 (세무·소비자 분쟁 대비) | 5년 경과 자동 cron 으로 NULL 처리 (member_id 만 유지) | 국세기본법 §85-3 (5년 보존) |
| 전자계약서·서명 이미지 | 계약 종료 후 5년 | 동일 | 전자문서법 §5 |
| WOD 결과·페이싱 기록 | 영구 (운동 기록은 회원 자산) | 회원이 명시 요청 시 즉시 익명화 | GDPR §17 (삭제 권리), 개인정보보호법 §36 |
| 출석 기록 | 회원 탈퇴 후 1년 | 1년 경과 자동 익명화 (회원 단위 식별 제거, 통계 카운트만 유지) | 통계 가치 vs 최소 보존 원칙 |
| audit_logs | 영구 (위변조 방지) | 절대 삭제 X | 정보통신망법 §29 (감사로그) |

**회원이 "삭제 요청" 시**: 사장 PC 화면에서 "개인정보 삭제" 버튼 → 30일 유예 → 자동 NULL 처리. audit_logs 에는 "deletion_requested_at" 만 남김.

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
| **1.5. 결제·체크인·푸시** | Toss Payments 통합 + QR 출석 체크인 + FCM 푸시 (D13·D14) | 1.5일 |
| **2. PC 사장 화면 풀** | 회원 DB CRUD + 회원권 3-tier (D9) + 락커 + 통계 대시보드 (여성 비중 D10 포함) + 전자계약 + SSE 알림 + churn win-back UI (D8) | 3일 |
| **3. 폰 가입 흐름 연동** | 박스 찾기 → 신청 → SSE 푸시 알림 수신 → 박스 정보 hydrate + first-week buddy 자동 메시지 (D11) | 1.5일 |
| **4. 폰 코치 모드 보강** | 사장 등록 회원과 device_hash 매핑 + 회원 목록 동기화 + buddy assign UI | 1일 |
| **5. 사용성 테스트** | 사장 5명·회원 5명 think-aloud 30분 (D14, Nielsen) → 발견 이슈 hotfix | 1일 |

총 약 10일 풀빌드. mockup (`web/facing-admin` v0.2) 은 이미 1번 일부 + 2번 부분 완료 상태.

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
| D8 | **Churn 방지**: 만료 7·14일 전 자동 알림 (push+SMS) + 연장 시 10% 할인. cancel flow 에 "save offer" (1개월 무료) 1회 | subscription-fitness §4 (retention 벤치) + pricing §10.4 (cancel flow) |
| D9 | **회원권 3-tier + decoy**: charm 99k / 279k / 990k (12개월) + decoy 12개월+PT 1,490k (anchor). Annual 가입 시 churn 50% ↓ | pricing §1·§6·§9 + §10.2 (annual vs monthly churn) |
| D10 | **여성 회원 특수 필드**: `preferred_time_slot` (여성 전용/심야), `preferred_coach_gender`, `safety_note`. 사장 통계에 여성 비중·시간대 분포 추가 | subscription-fitness §5 (여성 20-39 WTP) |
| D11 | **신규 first-week buddy assign**: 사장이 가입 승인 시 코치에게 buddy 매칭 지시. 폰에서 buddy 첫 메시지 자동 트리거. 1주 retention 측정 | subscription-fitness §6 (group dynamics retention 1.5~2x) |
| D12 | **페르소나 = JTBD 라벨**: 박지훈="회원 관리 시간 줄이기" / 김도윤="내 PR 자동 추적" / 송예준="박스 안 다녀도 자체 WOD" / 최서윤="처음이라 뭐부터 할지 모름" | ux-testing §2 (JTBD & behavioral segmentation) |
| D13 | **출석 체크인 = QR 1회용 (60초 만료)** / **결제 = Toss Payments + webhook 서명 검증** | 사용자 명시 + subscription-fitness §2 (multi-gym 결제) |
| D14 | **FCM 푸시 통합** (Phase 2 후반) + **사용성 테스트 사장 5명·회원 5명 think-aloud** (Nielsen 5-user 84% 발견율) | ux-testing §3.3 (Nielsen 5-user rule) |
| D15 | **API 엔드포인트 카탈로그를 §13 에 통일 명세** — REST 동사·경로·인증·응답 형식 SSOT | 통독 M1 |
| D16 | **회원 탈퇴 처리**: `gym_members.status='left'` + `left_at` + `left_reason` 추가. 자발적 탈퇴와 만료 분리 | 통독 M14 |
| D17 | **개인정보 보존 5년 + 자동 익명화 cron**: §7.1 보존 표 준수 | 개인정보보호법 §29·§36 · 국세기본법 §85-3 |
| D18 | **사장 다중 박스**: `gym_managers` PK 복합키 (gym_id, login_id). 로그인 시 박스 선택 토글 + 통합 대시보드 (총매출/총회원) | 통독 M7 |
| D19 | **코치 다중 박스**: 동일 패턴. 코치 폰에 박스 선택 토글 + 박스별 알림 분리 | 통독 M8 |
| D20 | **다국어 정책**: 폰 = 영문 헤드라인 + 한글 캡션 (V8~V10 SSOT 유지) / **PC 사장 = 전체 한글** (운영자 한국인) / 코치 폰 = 폰과 동일 | facing-app CLAUDE.md V8~V11 |
| D21 | **환불·해지 자동 계산** (M3): 잔여기간 × 1일 단가 − 위약금 10%. 환불 상태 = gym_memberships.status='refunded'. 환불 처리 화면 사장 PC §14 | 소비자보호법 · 체육시설업 표준약관 |
| D22 | **알림 게이트웨이**: SMS = **NHN Cloud Toast SMS** (D8 만료 알림) · 이메일 = **Mailgun** (계약서 PDF 발송) · 푸시 = FCM (D14) | 한국 시장 가용성 + Mailgun 무료 tier |
| D23 | **DB 백업**: SQLite `facing.db` 일일 새벽 03:00 → `data/backup/facing-YYYYMMDD.db` (30일 보존) + 주간 외부 백업 (Railway Volume snapshot) | 회원 50명 시점부터 적용 |
| D24 | **사장의 코치 관리 페이지** 신설 (§14) — 가장 큰 빈약점 보강. 코치 추가/제거·시급·스케줄·페어링 코드 발급 | 통독 M15 |
| D25 | **폰 탭별 화면 책임 재배치** (2026-06-02): **Home** = 공지/쪽지 아코디언(최상단·접힘) + 게이미피케이션(Level·업적·Milestones) / **WOD** = 코치 오늘 WOD + 하단 프리셋 카테고리 아코디언(참조) / **Notice** = 쪽지·숙제·공지 전체 피드(Home은 요약본) / **Attend** = 출석 캘린더 전담(Profile에서 이동) / **Profile** = Identity + 점수(숫자만, radar·sparkline 그래프 제거) + Body·Membership·Locker·MyBox·Settings·Actions. 페이싱 엔진 Home→Profile 강등은 §11.5 positioning(엔진=부가 기능, 홈 노출 위계↓) 과 정합. 5탭 구조·라벨·인덱스 유지 | 사용자 결정 2026-06-02 + §11.5 |

---

## 13. API 엔드포인트 카탈로그 (M1)

### 13.1 기존 (현재 동작 — facing-app 폰 호출)

| 동사 | 경로 | 인증 | 비고 |
|---|---|---|---|
| GET | `/api/v1/gyms/search?q=` | device_hash | 박스 검색 |
| GET | `/api/v1/gyms/mine` | device_hash | 내 박스 (owner_hash + profile) |
| POST | `/api/v1/gyms` | device_hash | 박스 생성 (owner) |
| POST | `/api/v1/gyms/{id}/join` | device_hash | 가입 신청 |
| DELETE | `/api/v1/gyms/{id}/leave` | device_hash | 탈퇴 |
| PATCH | `/api/v1/gyms/{id}/profile` | device_hash (owner) | 박스 정보 수정 |
| GET/POST/DELETE | `/api/v1/gyms/{id}/wods` | device_hash | 오늘의 WOD |
| GET/POST/PATCH | `/api/v1/gyms/{id}/members` | device_hash (owner) | 회원 목록·승인 |
| GET/POST/DELETE | `/api/v1/gyms/{id}/announcements` | device_hash | 공지 |
| GET/POST | `/api/v1/gyms/{id}/messages` | device_hash | 1:1 쪽지 |
| GET/POST | `/api/v1/gyms/{id}/wods/{wid}/results` | device_hash | 결과·리더보드 |
| GET/POST/DELETE | `/api/v1/gyms/{id}/wods/{wid}/comments` | device_hash | WOD 댓글 |
| GET/POST/DELETE | `/api/v1/gyms/{id}/wods/{wid}/feedback` | device_hash (owner) | 코치 1:1 피드백 |
| GET/POST/PATCH | `/api/v1/gyms/{id}/requests` | device_hash | 회원 사전 건의 |

### 13.2 신규 (Phase 1·2 — 사장 PC + 폰 가입 흐름 보강)

| 동사 | 경로 | 인증 | 용도 |
|---|---|---|---|
| POST | `/api/v1/admin/login` | ID/PW → 세션 쿠키 | 사장 로그인 |
| POST | `/api/v1/admin/logout` | 세션 | 로그아웃 |
| GET | `/api/v1/admin/me` | 세션 | 본인 정보 + 박스 목록 (다중 박스) |
| GET | `/api/v1/admin/gyms/{id}/members` | 세션 (boss) | 회원 DB 풀 리스트 |
| POST | `/api/v1/admin/gyms/{id}/members` | 세션 (boss) | 회원 추가 (이름·전화·생년 입력) |
| PATCH | `/api/v1/admin/members/{mid}` | 세션 (boss) | 회원 정보 편집 |
| DELETE | `/api/v1/admin/members/{mid}` | 세션 (boss) | 회원 삭제 (status='removed') |
| POST | `/api/v1/admin/members/{mid}/leave` | 세션 (boss) | 자발적 탈퇴 처리 (D16) |
| POST | `/api/v1/admin/members/{mid}/memberships` | 세션 (boss) | 회원권 발급 |
| PATCH | `/api/v1/admin/memberships/{mid}/extend` | 세션 (boss) | 회원권 연장 (D8 win-back) |
| POST | `/api/v1/admin/memberships/{mid}/refund` | 세션 (boss) | 환불 처리 (D21) |
| GET/POST/PATCH | `/api/v1/admin/gyms/{id}/lockers` | 세션 (boss) | 락커 관리 |
| GET/POST | `/api/v1/admin/members/{mid}/contracts` | 세션 (boss) | 전자계약 |
| GET | `/api/v1/admin/gyms/{id}/stats` | 세션 (boss) | §6 통계 한 묶음 |
| GET/POST/PATCH/DELETE | `/api/v1/admin/gyms/{id}/coaches` | 세션 (boss) | **코치 관리 §14 (D24)** |
| POST | `/api/v1/admin/gyms/{id}/coaches/{cid}/pairing-code` | 세션 (boss) | 코치 폰 페어링 코드 발급 |
| POST | `/api/v1/admin/members/{mid}/inquiries/{iid}/respond` | 세션 (boss) | 회원 문의 답변 |
| GET | `/api/v1/admin/events` | 세션 (boss) | **SSE stream §4** |
| POST | `/api/v1/attendances` | device_hash + QR 토큰 | 출석 체크인 (D13) |
| POST | `/api/v1/payments/webhook` | HMAC-SHA256 서명 | Toss webhook (D13) |
| GET | `/api/v1/member/events` | device_hash | 회원 폰 SSE stream |
| POST | `/api/v1/member/inquiries` | device_hash | 회원→사장 직접 문의 |

**응답 형식** 통일: `{ok: true, data: {...}}` / `{ok: false, error: "한글", code: "MACHINE_CODE"}` (기존 envelope 유지).

---

## 14. 코치 관리 페이지 (M15·D24 — 가장 큰 빈약점 보강)

### 14.1 사장 PC 화면 (`/admin/coaches`)

```
┌─ 코치 명단 ──────────────────────────────────────────────────┐
│ 이름      전화          입사일      시급       상태   액션  │
│ 박지훈    010-...       2024-03-01  35,000원   재직   편집 │
│ 김민수    010-...       2025-08-15  28,000원   재직   편집 │
│ 이수연    010-...       2024-11-10  30,000원   퇴사   복원 │
└─────────────────────────────────────────────────────────────┘
[+ 코치 추가]  [급여 정산 export]
```

### 14.2 코치 추가 흐름

1. 사장이 "+ 코치 추가" 클릭 → 폼 (이름·전화·시급·시작일)
2. 백엔드 `POST /api/v1/admin/gyms/{id}/coaches` → `gym_managers` INSERT (role='coach')
3. 자동으로 **페어링 코드 6자리 발급** + SMS 발송
4. 코치가 폰 facing-app 켜고 "코치 페어링 코드 입력" → device_hash ↔ login_id 연결
5. 코치 폰이 코치 모드 활성화 (기존 owner 와 동일 권한)

### 14.3 코치 제거 / 퇴사

- "퇴사 처리" 클릭 → `gym_managers.left_at = now()` (행 삭제 X, 이력 보존)
- 해당 코치의 폰 device_hash 는 그 박스에서 권한 박탈
- 회원에게 보낸 쪽지·피드백은 history 로 유지 (작성자 표기는 "(퇴사) 이수연")

### 14.4 시급·스케줄 (Phase 5+)

- 시급 입력만 v1. 자동 정산은 Phase 5+ (회계 시스템 연동 후보)
- 스케줄 (수업 시간표) 은 D2 (이번 빌드 X)

### 14.5 다중 박스 코치 (M8·D19)

- 같은 코치가 박스 2곳 등록 시 `gym_managers` 에 두 행 (gym_id 다르게)
- 코치 폰에 박스 선택 토글 (상단 메뉴)
- 시급·페이먼트는 박스별 독립

---

## 11. 변경 절차

이 브리프와 충돌하는 코드 변경이 필요할 때:
1. Claude 가 충돌 감지 → 사용자에게 보고 ("이 브리프와 어긋나는데 어느 쪽 우선?")
2. 사용자 명시 승인 → 브리프 먼저 갱신 → 코드 변경
3. 변경 이력은 §10 결정 사항 표에 D8, D9... 로 추가

브리프 우선 원칙. 코드만 갱신하고 브리프 방치 금지 (글로벌 §0-B SSOT 룰).

### 11.1. PHASE4 신규 테이블 (12개) — 사전 합의 등록

> 등록일: 2026-05-23. 상세 DDL: `docs/PHASE4_ROADMAP.md` 각 §1.x·§2.x.
> Migration 방법: `services/facing/models/base.py` `_migrate()` 함수에 `CREATE TABLE IF NOT EXISTS` 패턴 추가 (기존 Phase 1 방식 동일).

| # | 테이블 명 | PHASE4 Week | 모듈 | 브리프 §5 다이어그램 갱신 필요 |
|---|---|---|---|---|
| 1 | `class_session` | Week 1 | §1.1 예약 | 예 |
| 2 | `class_reservation` | Week 1 | §1.1 예약 | 예 |
| 3 | `class_waitlist_promotion` | Week 1 | §1.1 예약 대기열 audit | 예 |
| 4 | `notification_template` | Week 3 | §1.2 카카오 알림톡 | 예 |
| 5 | `notification_dispatch` | Week 3 | §1.2 발송 이력 | 예 |
| 6 | `contract_template` | Week 1 | §1.3 전자계약 템플릿 | 예 |
| 7 | `contract_instance` | Week 1 | §1.3 서명 인스턴스 | 예 |
| 8 | `gym_group` | Week 5 | §1.4 다지점 그룹 | 예 |
| 9 | `billing_key` | Week 2 | §1.5 Toss 빌링키 | 예 |
| 10 | `billing_schedule` | Week 2 | §1.5 자동결제 스케줄 | 예 |
| 11 | `ai_coaching_session` | Week 7 | §1.7 AI 코칭 보조 | 아니오 (Phase 2 연기) |
| 12 | `wod_calendar_plan` | Week 4 | §1.6 WOD 월간 캘린더 | 예 |

> `billing_key` 는 PHASE3 C-1 에서 일부 구현됐을 수 있음. 코드 착수 시 `services/facing/models/` 확인 후 중복 방지.

### 11.2. PHASE4 ALTER 컬럼 (3건) — 사전 합의 등록

> Migration 방법: `_migrate()` 내 `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` (SQLite 호환 — `IF NOT EXISTS` 는 SQLite 3.37+ 지원, 미만이면 try/except OperationalError 패턴).

| # | 테이블.컬럼 | 타입 | PHASE4 Week | 모듈 | 용도 |
|---|---|---|---|---|---|
| A1 | `gym_member_profiles.preferred_class_time_slot` | VARCHAR(50) | Week 1 | §1.1 예약 | 예약 선호 시간대 (기존 D10 `preferred_time_slot` 과 별도 — 클래스 예약용) |
| A2 | `gyms.group_id` | INT FK → `gym_group.id` | Week 5 | §1.4 다지점 | 다지점 그룹 FK |
| A3 | `gym_memberships.auto_renew_enabled` | BOOLEAN DEFAULT FALSE | Week 2 | §1.5 자동결제 | 자동갱신 토글 |

> A1 주의: 기존 `gym_member_profiles.preferred_time_slot` (D10 여성 전용/심야) 과 **다른 컬럼**. 클래스 예약 전용으로 분리. 이름 충돌 방지를 위해 `preferred_class_time_slot` 사용.

### 11.3. PHASE4 신규 API 엔드포인트 (§13 카탈로그 갱신 예고)

> PHASE4 구현 착수 시 §13.2 에 신규 endpoint 추가 의무. 아래는 예고 목록 (상세: `docs/PHASE4_ROADMAP.md` 각 §).

| 모듈 | 신규 엔드포인트 수 | 비고 |
|---|---|---|
| §1.1 예약 | 6 | POST·GET·DELETE·noshow·SSE 이벤트 |
| §1.2 알림톡 | 2 | dispatch·이력 |
| §1.3 전자계약 | 4 | draft·sign-link·sign·pdf |
| §1.4 다지점 | 4 | group dashboard·gym-switcher·share·cross-gym 출석 |
| §1.5 빌링키 | 5 | key 발급·삭제·schedule·retry·APScheduler |
| §1.6 WOD 캘린더 | 4 | 작성·복사·공유·조회 |
| §1.7 AI 코칭 | 1 | wod-pacing-explain |
| §2.1 페이싱 보강 | 3 | calculate 보강·cp-estimate·pacing-batch |
| §2.2 leaderboard | 3 | leaderboard·tier-distribution·engine-comparison |
| §2.4 듀얼 포지셔닝 | 3 | link-facing-app·class-pacing·push-pacing-card |
| **합계** | **35** | |

### 11.5. facing-app 포지셔닝 전환 (2026-05-24)

> 등록일: 2026-05-24. 사용자 결정: 신규 방문자 페르소나 시뮬레이션 100건 그루밍 결과, facing-app 의 primary value 를 "Games-elite 전용 페이싱 계산기" → **"수업 관리 + 페이싱 (+α)"** 로 전환.
> 상세: `docs/PERSONA_BACKLOG.md` 와 `apps/facing-app/CLAUDE.md` v1.16.2.

| 항목 | Before | After | 영향 범위 |
|---|---|---|---|
| facing-app primary value | "Split defines rank · Games elite" | "수업을 간편하게 — 박스 운영 + 페이싱(+α)" | 모든 화면 카피·온보딩·홈 |
| 타깃 유저층 | Games tier 출전자급 한정 | RX-aspiring ~ Games 까지 폭넓게 | 마케팅·기능 우선순위 |
| 페이싱 엔진 위상 | 메인 기능 | 부가/차별 기능 (Wodify 미보유 hook) | 홈 화면 노출 위계 |
| 톤·V1~V11 어투 | 유지 | 유지 (단, "elite 전용" 문구 제거) | 카피 톤 |
| 금지 용어 (헬스·다이어트·웰니스) | 유지 | 유지 | 카피 |

> §10 결정사항 표에는 D-번호 부여 후 추가 예정.

### 11.6. 박스 프로필 + 코치 프로필 스키마 확장 (2026-05-24)

> 등록일: 2026-05-24. 페르소나 결과 분류 — 박스 운영 정보 18 필드를 `gym_profiles` + 신규 `gym_coach_profiles` 두 테이블로 흡수.
> 상세 DDL: `docs/GYM_PROFILE_SCHEMA.md`.

| 변경 | 대상 | 신규 필드 / 모델 | 비고 |
|---|---|---|---|
| ALTER | `gym_profiles` | +9 필드 (price_summary, payment_methods, receipt_info, parking_info, first_visit_guide, attire_guide, wifi_info, contact_kakao, free_notice) | 기존 7 필드 (phone·coach_*·motto·logo·class_schedule·instagram) 와 합쳐 16 필드 |
| 신규 테이블 | `gym_coach_profiles` | coach_user_id, gym_id, name, photo_url, career, certifications, specialty, competition_records, demo_video_url, sns_url, pt_bookable, off_days_json, hired_at | 코치 multi 지원. `gym_managers.role='coach'` 와 1:1 연결 |
| 신규 endpoint | §13 카탈로그 | 6 (GET/PATCH gym profile / GET coach list / GET coach detail / PATCH coach profile / GET coach off-days) | RBAC: 사장 = 전부, 코치 = 본인 only, 회원 = 읽기만 |

> 계약서(`contract_template` / `contract_instance`) 는 **PHASE4 §1.3 으로 이미 등록됨** (위 §11.1). 추가 작업 없음. 박스 프로필 페이지에서 "환불·해지·등록비·보험" 4 항목은 계약서 템플릿 필드로 흡수.

---

### 11.4. PHASE5 §2 RBAC 변경 등록 (2026-05-23)

> 등록일: 2026-05-23. 상세 plan: `docs/PHASE5_ROADMAP.md`.
> 사장 폰 보조 운영 가정 추가 — linko 격차 해소 (linko 9 스크린샷 분석에서 격차 발견).

| 변경 항목 | Before | After | 영향 범위 |
|---|---|---|---|
| 사장 클라이언트 | PC 전용 | PC 주 + 폰 보조 (PHASE5) | facing-app 인증·라우팅·UI |
| 매니저 역할 | 미정의 | RBAC 표 추가 — 사장 위임 운영권 | 백엔드 RBAC enum + 미들웨어 |
| 폰 진입 분기 | device_hash 단일 | user_type=`device_hash` (회원·코치) vs `login_id` (사장·매니저) | facing-app 부팅 라우터 |
| 사장 폰 로그인 | 없음 | PC 와 동일 ID/PW | 백엔드 admin login endpoint 확장 |

> §10 결정사항 표에는 PHASE5 착수 시점에 D-번호 부여 후 추가.

---

## 12. 참조 study (브리프 보강 근거)

| study 파일 | 적용된 결정사항 | 핵심 인용 |
|---|---|---|
| `reference/study/subscription-fitness.md` | D8 · D9 · D10 · D11 · D13 | §4 retention 벤치 / §5 여성 WTP / §6 group dynamics / §2 multi-gym pricing |
| `reference/study/pricing.md` | D8 · D9 · D21 | §1 charm / §6 tier / §9 bundle / §10 churn (annual vs monthly) / §10.4 cancel flow |
| `reference/study/ux-testing.md` | D12 · D14 | §2 JTBD / §3.3 Nielsen 5-user / §4 10 heuristics / §5 Baymard friction |
| `reference/study/ui-design-fundamentals.md` | (Phase 2 UI 설계 시 참조) | 5 디자인 프리셋 · 21 파라미터 default-deny 룰 |
| `reference/study/fitness.md` (sub-files: cardio·olympic-lifting·power·gymnastics·hyrox) | 기존 engine·grade 산정 로직 | 페이싱 계산·tier 정의의 학술 근거 |
| `reference/payment.md` | D13 · D22 | Toss Payments + webhook 검증 + idempotency |
| `reference/webhook.md` | D13 · D22 | HMAC-SHA256 + timing-safe compare + replay 방어 |
| `reference/security.md` + `reference/authorization.md` | D17 · §7.1 · D3 | 개인정보보호법 §29·§36 · bcrypt · RBAC · 감사로그 |

신규 보강 시 study 인용 우선 — 임의 결정 금지.
