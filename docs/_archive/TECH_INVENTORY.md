---
domain: facing
type: tech-inventory
last_updated: 2026-05-23
status: active
phase: 4 (in progress · P0 3/6 done — 알림톡·예약·전자계약)
source: code-verified (apps/facing-app + web/facing-admin + services/facing)
ssot: docs/ARCHITECTURE_BRIEF.md
---

# facing 기술 인벤토리 (2026-05-23 기준)

> 폰(Flutter) + PC 웹(Flask) + 백엔드(Flask/SQLite) 에서 **지금 코드에 존재하는** 기술 전체.
> "예정"·"미구현" 은 §8 만 별도. 본문 §1~§7 은 코드 경로 기반 검증된 것만.
> 시스템 합의 SSOT 는 `docs/ARCHITECTURE_BRIEF.md`. 본 파일은 그 브리프의 **실제 구현 인벤토리** 보조 문서.

---

## §1. 폰 — `apps/facing-app` (Flutter 3.11.5 + Dart)

### 1.1 화면 카테고리 (`lib/features/`)

| 영역 | 주요 화면 | 비고 |
|---|---|---|
| `splash` | splash_screen | 부팅 + 명언 1개 |
| `intro` | intro_screen | 최초 진입 가이드 |
| `auth` | signup_screen / auth_state / demo_accounts | 회원·코치 분기 |
| `onboarding` | mode_select / basic / benchmarks / grade / create_gym | 5-Tier 산정 |
| `home` | home_screen + benchmark_sheet | 오늘의 WOD |
| `shell` | main_shell | 하단 네비 + Inbox bell |
| `wod_builder` | wod_builder / calc_entry / movement_picker / wod_draft_state | WOD 구성 |
| `pacing_result` | result_screen | 분할·폭발 시점·근거 |
| `wod_session` | wod_session_screen | 진행 타이머 |
| `history` | history_screen / history_detail / history_repository | Engine·WOD 기록 |
| `gym` | search · profile_edit · wod_post · wod_detail · result_sheet · member_requests · coach_dashboard · box_wod | 박스/코치 풀스택 |
| `messages` | messages_screen | 회원↔코치 쪽지 |
| `inbox` | inbox · note_detail · compose_note · group_management | 코치 노트 inbox/outbox |
| `announcements` | announcements_screen | 박스 공지 |
| `attendance` | attendance_screen | QR 체크인 |
| `leaderboard` | box_leaderboard_screen | 박스 내 순위 |
| `achievement` | achievements · achievement_card/section · panel_b · confetti · unlock_toast | 배지·언락 |
| `goals` | goals_screen | 목표 설정 |
| `presets` | presets · preset_detail | 프리셋 WOD |
| `mypage` | mypage · edit_profile · algorithm · import · privacy | 프로필 + PIPA |
| `profile` | profile_screen / profile_state | Max 입력 |
| `_debug` | persona_switcher / persona_debug_data / coach_pair / qr_input | 데모용 |

### 1.2 핵심 도메인 모듈 (`lib/core/`)

api_client (dio + interceptor), device_id, app_mode (회원/코치), athletes, benchmark_data, connectivity_state, engine_decay, formula_references, glossary, goals_state, haptic, level_system, movements_repository, pr_detector, quotes, scoring, season, season_badges, share_count_store, shell_nav_bus, streak_freeze, theme (FacingTokens), tier, titles_catalog, ui_prefs_state, unit_state (kg/lb), weak_insight, wod_session_bus, worn_title_store.

### 1.3 위젯 (`lib/widgets/`)

avatar, coach_badge, grain_overlay, gym_info_card, hero_background, inbox_bell, offline_banner, quote_card, tier_badge.

### 1.4 사용 라이브러리 (`pubspec.yaml`)

| 패키지 | 버전 | 용도 |
|---|---|---|
| `dio` | ^5.7.0 | HTTP 클라이언트 + interceptor |
| `shared_preferences` | ^2.3.2 | device_id, 프로필 로컬 저장 |
| `uuid` | ^4.5.1 | device UUID v4 |
| `provider` | ^6.1.2 | 상태관리 (Riverpod 미사용) |
| `connectivity_plus` | ^6.0.5 | 온오프 감지 + retry queue |
| `google_fonts` | ^6.2.1 | (Pretendard 로컬 fallback 보조) |
| `flutter_svg` | ^2.0.10+1 | SVG 아이콘 |
| `wakelock_plus` | ^1.2.8 | WOD 타이머 화면 꺼짐 방지 |
| `share_plus` | ^10.0.0 | WOD 결과 카드 SNS 공유 |
| `cupertino_icons` | ^1.0.8 | iOS 아이콘 |
| `integration_test` (dev) | sdk | E2E |
| Pretendard 폰트 | (assets) | 본문/헤딩 단일 폰트 |

> **글로벌 `rules/mobile.md` 와 차이**: 현재 facing-app 은 **Provider** 사용 (Riverpod 미도입). go_router 미사용 — MaterialApp + Navigator. `fresh_dio` / `pigeon` 미도입. 추후 마이그레이션 후보.

### 1.5 폰 → 백엔드 호출 endpoint (lib/features/*/\*_repository.dart 기준)

- `/api/v1/gyms/*` (search·mine·create·join·leave·profile·members·wods·announcements·messages·results·comments·feedback·requests)
- `/api/v1/achievements`, `/api/v1/achievements/check`
- `/api/v1/history/engine`, `/api/v1/history/wod`
- `/api/v1/gym/<gid>/groups`, `/notes`, `/inbox`, `/outbox`, `/invite-code`, `/join-by-code`, `/member-report`
- `/api/v1/movements`, `/api/v1/movements/categories`
- `/api/v1/wods/presets`
- `/api/v1/profile/info`, `/profile/grade`
- `/api/v1/pacing/calculate`
- `/api/v1/coach/pair` (QR 페어링)
- `/api/v1/attendances` (체크인)
- `/api/v1/inventory`, `/inventory/use`
- `/api/v1/i18n/strings`, `/i18n/set-lang`
- `/api/v1/devices/fcm-token`
- `/api/v1/privacy/me/data`, `/me/delete-request`, `/me/access-log`, `/privacy/consent`
- `/api/v1/member/contracts/<id>` + `/sign`
- `/api/v1/member/classes/<id>/reservations`

응답 envelope `{ok, data, error, code}` — `api_client.dart:_rawData` 가 unwrap.

---

## §2. PC 웹 — `web/facing-admin` (Flask 3.1.0 + 바닐라 HTML/CSS/JS)

### 2.1 페이지 (`templates/*.html` + `app.py` 라우트)

| 경로 | 템플릿 | 용도 |
|---|---|---|
| `/login` | login.html | 사장 ID/PW 로그인 |
| `/members` | members.html + _member_form_fields.html | 회원 DB 풀 리스트 |
| `/members/<int:id>` | member_detail.html | 회원 상세 5탭 사이드패널 |
| `/lockers` | lockers.html | 락커 grid (Phase 1.5 후반) |
| `/contracts` | contracts.html | 전자계약 목록 |
| `/coaches` | coaches.html | 코치 관리 §14 (D24) |
| `/payroll` | payroll.html | 코치 시급 정산 |
| `/checkin` | checkin.html | QR 토큰 발급 디스플레이 |
| `/wod` | wod.html | WOD·PR·Benchmark 진입점 |
| `/classes` | classes.html | PHASE4 P0 예약 주간 캘린더 |
| `/settings/notifications` | notifications.html | E-5 카카오 알림톡 설정 |
| `/onboarding` | onboarding.html | N6-0 셀프 setup wizard |
| `/stats` | stats.html | §6 통계 대시보드 (range 7d/30d/90d/all) |

### 2.2 사이드바·메뉴 (`_layout.html` 기반)

회원 / 코치 / 락커 / 전자계약 / WOD / 클래스 / 출석 / 통계 / 정산 / 알림 설정 / 셀프 onboarding. CSS 1파일 (`static/style.css`) + JS 1파일 (`static/app.js`).

### 2.3 사용 가능 액션

회원 CRUD (이름·생년·전화·level·preferred_time_slot·preferred_coach_gender·safety_note·note 입력) · 회원권 발급/연장/환불/탈퇴 · 락커 배정 · 전자계약 생성/서명/PDF · 코치 추가/제거/페어링 코드 발급 · QR 출석 토큰 발행 · CSV bulk import (multipart) · CSV export · stats range 토글 · 박스 스위처 (다중 박스 사장) · 알림톡 템플릿 토글 · SSE 알림 토스트 수신.

### 2.4 백엔드 proxy 라우트 (`app.py`)

- `/api/proxy/login` — 백엔드 `/api/v1/admin/login` + session cookie 저장 + CSRF 토큰 보관 + onboarding_recommended 신호
- `/api/proxy/me`, `/api/proxy/switch-gym` — 박스 스위처 (D18)
- `/api/proxy/<path:subpath>` — passthrough (GET/POST/PATCH/DELETE) + CSRF 헤더 자동 주입 + multipart 파일 forwarding + non-JSON(CSV) 응답 처리
- `/api/proxy/events` — SSE stream proxy (백엔드 `/api/v1/admin/events` forward)

### 2.5 의존성 (`requirements.txt`)
flask 3.1.0 · requests 2.32.3 · python-dotenv 1.0.1 · gunicorn 23.0.0. 별도 ORM·DB 없음 — 모든 데이터는 백엔드 호출.

---

## §3. 백엔드 — `services/facing` (Flask 3.1.0 + SQLAlchemy 2.0 + SQLite + APScheduler)

### 3.1 DB 모델 (`models/*.py`)

기본: gym · gym_profile · gym_member (device_hash) · gym_member_profile · gym_membership · gym_locker · gym_contract · gym_attendance · gym_manager · gym_announcement · gym_coach_feedback · gym_inquiry · gym_social · gym_notification_settings · gym_payment · gym_payroll · gym_plan · gym_member_consent · admin_user · audit_log.
WOD/Engine: wod · wod_score · wod_session · movement · movement_library · benchmark_wod · max_record · member_pr · pacing · profile · snapshot · achievement · pt_session · coach_note · inventory.
PHASE4 신규: class_session · class_reservation · class_waitlist_promotion · contract_template · contract_instance.

### 3.2 API 블루프린트 (`api/*.py` — 25개)

core · movements · pacing · presets · profile · history · gym · achievement · inventory · coach_note · contracts · admin · checkin · payments · fcm · webhooks/toss · webhooks/kakao · privacy · payments_admin · billing · i18n · members_search · notification_settings · classes · admin (lockers·payroll·contracts·coaches inline).

엔드포인트 카테고리(주요 군):
- **`/api/v1/admin/*`** — 사장 운영 풀스택 (login·logout·me·members·memberships·lockers·contracts·coaches·pairing-code·stats·payroll·backup·csrf-token·switch-gym·churn-risk·payment-consent·cancel-membership·events SSE)
- **`/api/v1/gyms/*`** — 폰 회원/코치 풀스택 (search·mine·join·leave·wods·announcements·messages·results·comments·feedback·requests)
- **`/api/v1/billing/*`** — Toss 빌링키 (PHASE4 §1.5)
- **`/api/v1/payments/webhook`** + **`/api/v1/webhooks/toss`** + **`/api/v1/webhooks/kakao_delivery`** — HMAC-SHA256 + idempotency
- **`/api/v1/contracts/<id>/verify`** — 전자계약 verify
- **`/api/v1/member/classes/<id>/reservations`** — PHASE4 §1.1
- **`/api/v1/attendances`**, **`/api/v1/admin/qr/issue`** — QR 출석 (60초)
- **`/api/v1/devices/fcm-token`** — FCM 토큰 등록
- **`/api/v1/i18n/strings`** + `/set-lang` — 다국어 (D20)
- **`/api/v1/privacy/me/*`** — PIPA 데이터 권리

### 3.3 서비스 모듈 (`services/*.py`)

| 모듈 | 책임 |
|---|---|
| `churn_risk.py` | 출석14d·결제실패·30d 추세·만료 4-factor 스코어링 + recommended_action |
| `churn_risk_scheduler.py` | 일배치 + after_payment_failure 훅 + SSE publish |
| `cohort.py` | retention 코호트 + per-member churn risk |
| `expiry_scheduler.py` | 만료 D-14/-7/-3/-0 알림톡 + 월 빌링 + reconciliation + open-season cron |
| `leaderboard.py` | sort/ascending/AMRAP score/percentile |
| `marketing_dashboard.py` | gym_dashboard_summary |
| `reconciliation.py` | run_monthly_reconciliation |
| `receipt_pdf.py` | 영수증 PDF (weasyprint) |
| `json_logger.py` | JsonFormatter + install_json_logging (production) |

### 3.4 알림 어댑터 (`api/notifications/*.py`)

- `kakao.py` — NHN Cloud Bizmessage `/alimtalk/v2.3` (8 템플릿 상수 + 야간차단 21~08 KST + send_batch 100건/call). dev=stub
- `sms.py` — `send_sms` (stub)
- `push.py` — `send_push` (FCM stub)
- `email.py` — `send_email` (Mailgun stub)

### 3.5 전자계약 (`contracts/`)

`pdf_generator.py` — weasyprint HTML→PDF (Windows GTK Runtime fallback) + base64 SHA256 hash.
`template_seed.py` — `seed_membership_3m()` (앱 부팅 시 idempotent).
`templates/membership_3m.html` — 회원권 3개월 템플릿.

### 3.6 엔진 (`engine/*.py`)

calculator/formula/grading/rationale/rest/sinclair/splitter/wod_types/achievement_checker/config.

### 3.7 부팅 시 의존 (`app.py`)

flask-cors · flask-limiter (rate limit memory:// default · Redis 전환 N4-3) · sentry-sdk (PII scrub before_send · env DSN 없으면 skip) · python-dotenv (글로벌 `C:/dev/.env` → 로컬 override) · session cookie (Secure/HttpOnly/SameSite=Lax · 8시간 sliding) · production 보안 헤더 (HSTS·CSP·X-Frame-Options·Referrer-Policy·Permissions-Policy) · `install_json_logging` (production) · migrate_db + seed_superadmin + seed_admin_demo_data + seed_gym_managers + seed_membership_3m + APScheduler 백업 + expiry_scheduler.

### 3.8 의존성 (`requirements.txt`)

flask 3.1.0 · flask-cors 5.0.0 · sqlalchemy 2.0.36 · gunicorn 23.0.0 · gevent 24.11.1 · pytest 8.3.4 · python-dotenv 1.0.1 · **bcrypt 4.2.1** · **sentry-sdk[flask] 2.18.0** · psycopg2-binary 2.9.10 (Postgres 전환 대기) · **Flask-Limiter 3.8.0** · **weasyprint ≥60.0** · **pypdf ≥4.0** · **qrcode[pil] ≥7.4** · APScheduler (별도 install — backup.py + scheduler 사용).

---

## §4. 폰 ↔ 백엔드 ↔ PC 웹 — 실시간 동기화

### 4.1 SSE 채널

- `GET /api/v1/admin/events` — 사장 PC EventSource 구독 (facing-admin 의 `/api/proxy/events` 가 stream forward)
- 이벤트: `member_join_request`, `member_approved`, `member_expiring`, `wod_result_posted`, `locker_freed`, `churn_alert` (churn_risk_scheduler 가 publish), `class-reservation-changed` (PHASE4 §1.1 예고), `contract_signed` (계획)
- `GET /api/v1/member/events` — 회원 폰 (브리프 §13.2 등록, 실제 폰 구현은 30초 poll fallback 우선)

### 4.2 인증 분리 (D2/D3)

- 폰 = `X-Device-Id` (UUID v4, device_hash 익명) — `api_client.dart` interceptor 자동 주입
- PC 사장 = `/api/v1/admin/login` ID/PW → Flask session cookie (Secure/HttpOnly/SameSite=Lax) + CSRF 토큰
- 코치 폰 페어링 = `/api/v1/coach/pair` (사장 PC 가 6자리 코드 발급 → 코치 폰 입력 → device_hash ↔ login_id 매핑)

---

## §5. 외부 의존성

| 통합 | 상태 | 비고 |
|---|---|---|
| Toss Payments — webhook | 구현 | HMAC-SHA256 + idempotency + 5분 timestamp tolerance (`api/webhooks/toss.py`) |
| Toss Payments — 빌링키 자동결제 | PHASE4 §1.5 진행 | `api/billing.py` + `BillingKey` 테이블 + 월간 cron |
| NHN Cloud Bizmessage (카카오 알림톡) | 구현 (stub) | 8 템플릿 + 야간 21~08 KST 차단 + batch 100 |
| FCM 푸시 | 토큰 등록 endpoint 만 | send_push stub |
| Mailgun (이메일) | stub | 계약서 PDF 발송용 |
| NHN Cloud Toast SMS | stub | D22 만료 알림 |
| Anthropic Claude API | 예정 (PHASE4 §1.7 AI 코칭) | 글로벌 §0-A — CLI/API 분기 |
| Sentry | 구현 (DSN 옵션) | PII scrub before_send + GIT_COMMIT_SHA release tag |
| Redis (SSE backplane) | 미구현 (N4-3 후) | RATELIMIT_STORAGE_URI 도 동일 전환 |
| weasyprint | 구현 | HTML → PDF (Win GTK + Docker libcairo/pango) |
| qrcode | 구현 | 60초 QR 토큰 |
| Postgres | 대기 | psycopg2-binary 설치만, H-1 이행 시점 활성 |

---

## §6. 한국 시장 특화 (구현 검증)

- **PIPA 4-toggle 동의 모달** — `mypage/privacy_screen.dart` + `api/privacy.py` (`/me/data`·`/me/delete-request`·`/me/access-log`·`/consent`)
- **환불·해지 자동 비례 계산 (D21)** — `/api/v1/admin/memberships/<id>/refund` (`payments_admin.py`)
- **갑근세 3.3% 자동 (코치 페이롤)** — `gym_payroll` 모델 + `/admin/gyms/<gid>/payroll/auto` + CSV export
- **전자서명법 §3 (서명 IP·hash 저장)** — `contract_instance.py` + `contracts/pdf_generator.py` SHA256
- **카카오 알림톡 8 템플릿** — `TMPL_EXPIRE_7D/3D/TODAY` · `TMPL_PAYMENT_SUCCESS/FAIL` · `TMPL_RESERVATION_CONFIRM/CANCEL` · `TMPL_MEMBERSHIP_CANCEL`
- **다국어 (D20)** — `/api/v1/i18n/strings` (폰=영문헤드+한글캡션 / PC=전체 한글)

---

## §7. PHASE 진행 상태

| Phase | 상태 | 주요 산출물 |
|---|---|---|
| Phase 1 — 백엔드 기반 | 완료 | 신규 6 테이블 + 사장 로그인 + SSE 채널 |
| Phase 1.5 — 결제·체크인·푸시 | 완료 | Toss webhook + QR 출석 + FCM 토큰 |
| Phase 2 — PC 사장 풀 | 완료 | 회원 DB·락커·통계·전자계약·코치 관리·알림 설정 |
| Phase 3 — 56 task | 완료 | P0 18 (보안·rate limit·CSRF·세션쿠키·sentry·JSON 로그·CrossFit 60 동작 라이브러리 등) + P1 24 (CSV export·payroll·셀프 onboarding) + P2 14 (UX polish) |
| **Phase 4 — P0 6 모듈** | **3/6 완료** | ✅ §1.1 예약 (`classes.py` + 3 테이블) · ✅ §1.2 카카오 알림톡 (NHN + 8 템플릿) · ✅ §1.3 전자계약 (`contracts.py` + weasyprint + template_seed) / 남은 — §1.5 Toss 빌링키 자동결제 cron 안정화 · §2.1 페이싱 W-prime·CGM 알고리즘 정밀화 · §2.4 B2B2C 듀얼 포지셔닝 데이터 브릿지 |

---

## §8. 기술 부족·갭 (PHASE 4·5 후보)

- **회원 facing-app ↔ 박스 SaaS Tier hydrate 미연결** (PHASE4 §2.4 P0) — 가장 큰 빈약점
- **Toss 빌링키 자동결제 cron 안정화** — schedule·retry·grace period (PHASE4 §1.5)
- **Redis backplane 부재** — SSE 단일 인스턴스 제약 · rate limit memory:// → Redis 전환 (N4-3)
- **다지점 RLS 백엔드 미구현** — `gym_managers` 복합키만, gym_group/cross-gym 출석 endpoint 미구현 (PHASE4 §1.4 P1)
- **AI 코칭** — `ai_coaching_session` 테이블 예정, Claude API 미연결 (PHASE4 §1.7 P2)
- **WOD 월간 캘린더** — `wod_calendar_plan` 테이블 예정 (PHASE4 §1.6 P1)
- **모바일 admin 반응형** — 현재 viewport=1280 우회. PC 데스크톱 전용 유지가 합의
  (스태프의 폰 동선은 반응형 웹이 아니라 앱 사장 화면이 담당 — 브리프 §2-0 대전제 3)
- **Riverpod/go_router/fresh_dio/pigeon 미도입** — `rules/mobile.md` 권장 스택과 차이. 단기 작업 우선이라 deferred
- **회원 폰 SSE 실제 구현** — `/api/v1/member/events` 등록만, 30초 poll fallback 우선
- **Postgres 이행** — psycopg2-binary 설치만, H-1 시점 SQLite → Postgres 전환

---

## §9. 라이브러리 라이선스

- **LGPL** — weasyprint · pypdf : 정적 링크 금지, 동적 import 만 (현재 Python 모듈 import = OK)
- **Apache 2.0** — Flutter SDK · dio · provider · connectivity_plus · share_plus : 자유 사용
- **MIT** — Flask · SQLAlchemy · APScheduler · Flask-Limiter · Flask-CORS · gunicorn · requests · python-dotenv · uuid · shared_preferences · flutter_svg · wakelock_plus : 자유 사용
- **BSD** — psycopg2 · gevent : 자유 사용
- **PSF / Python 표준** — zoneinfo · hashlib · hmac · secrets : 자유 사용
- **상용 SDK** — sentry-sdk (BSD-2 · 무료 tier) · bcrypt (Apache 2.0)
- **글꼴** — Pretendard (SIL OFL · 자유 배포)

---

## §10. 빠른 참조 — "이 기능 어디 있어?"

| 기능 | 위치 |
|---|---|
| Engine 계산 (5-Tier) | `services/facing/engine/grading.py` + `formula.py` + `sinclair.py` |
| 페이싱 분할/폭발 | `services/facing/engine/splitter.py` + `rest.py` + `api/pacing.py` |
| Churn risk 4-factor | `services/facing/services/churn_risk.py` + `churn_risk_scheduler.py` |
| Cohort retention | `services/facing/services/cohort.py` |
| 카카오 알림톡 발송 | `services/facing/api/notifications/kakao.py` (`send_alimtalk` + `send_batch`) |
| Toss webhook 서명 검증 | `services/facing/api/webhooks/toss.py` |
| Toss 빌링키 자동결제 | `services/facing/api/billing.py` |
| 전자계약 PDF + hash | `services/facing/contracts/pdf_generator.py` |
| 클래스 예약 (PHASE4) | `services/facing/api/classes.py` + `models/class_session.py` |
| QR 출석 토큰 | `services/facing/api/checkin.py` + `/admin/qr/issue` |
| 만료·자동결제 cron | `services/facing/services/expiry_scheduler.py` |
| DB 백업 03:00 KST | `services/facing/backup.py` |
| PIPA 데이터 권리 | `services/facing/api/privacy.py` |
| 회원 검색·CSV import | `services/facing/api/members_search.py` |
| Sentry PII scrub | `services/facing/app.py:_sentry_scrub_pii` |
| Flask-Limiter init | `services/facing/app.py:_init_rate_limiter` |
| 폰 dio interceptor (X-Device-Id) | `apps/facing-app/lib/core/api_client.dart` |
| 폰 Tier 배지 + 컬러 토큰 | `apps/facing-app/lib/widgets/tier_badge.dart` + `lib/core/theme.dart` |
| 폰 명언 SSOT | `apps/facing-app/lib/core/quotes.dart` |
| 폰 페르소나 스위처 (데모) | `apps/facing-app/lib/features/_debug/persona_switcher_screen.dart` |
| PC 사장 SSE 토스트 | `web/facing-admin/app.py:/api/proxy/events` + `static/app.js` |
| PC 사장 박스 스위처 (D18) | `web/facing-admin/app.py:/api/proxy/switch-gym` |
| 회원권 환불 비례 | `services/facing/api/payments_admin.py:/payments/<pid>/refund` |
| 코치 페어링 코드 | `services/facing/api/admin.py:/coaches/<login_id>/pairing-code` + 폰 `_debug/coach_pair_screen.dart` |

---

## §11. 부팅·실행 (참고)

- 백엔드: `cd services/facing && python app.py` → `http://localhost:5060` (host=0.0.0.0, debug, use_reloader=False)
- PC 웹: `cd web/facing-admin && python app.py` → `http://localhost:8081` (5061 = Chrome ERR_UNSAFE_PORT 차단)
- 폰: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5060` (에뮬레이터) 또는 LAN IP (실기)
- 데모 계정: `admin / 1234` (슈퍼) · `boss_seongsu / 1234` (PC 사장) · `coach_park / 1234` (코치 페어링 가능)
- 폰 페르소나 4명: 박지훈(사장) / 김도윤(엘리트) / 송예준(원격) / 최서윤(입문) — `_debug/persona_switcher_screen.dart`
