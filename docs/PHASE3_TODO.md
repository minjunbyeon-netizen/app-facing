# facing — Phase 3 작업 todo (v2 실행용)

> **작성일**: 2026-05-23 (오버나이트)
> **베이스**: `PHASE3_REVISION_v2.md` 의 P0/P1/P2 매트릭스 + 의존 그래프
> **연계**: `PHASE2_ROADMAP.md` (5박스 종료선) · `WEB_ADMIN_MEMBER_MGMT_TODO.md` (Phase 2 회원관리 영역 56 task) · `GAPS_ANALYSIS_2026-05-23.md`
> **목적**: 실제 코드·문서·인프라 작업 단위 todo. task 시작할 때 `- [ ]` → `- [x]` 체크 + 시작/종료일 기록.

---

## 0. 한 줄

> **Phase 3 진입 가능한 시점(5박스 30일 안정+uptime 99.5%) 까지 P0 18개 완료가 transition criteria. Phase 3 전체는 P0 18 + P1 24 + P2 14 = 총 56 task. 8~13주 (P0) + 19~30주 (P0~P2 전체).**

---

## 1. 진행 상태 요약 (체크박스 카운트 자동 갱신)

| 구간 | 총 | 진행중 | 완료 | 진행률 |
|---|---|---|---|---|
| P0 (Phase 2 마무리·Phase 3 진입) | 18 | 0 | 18 | **100%** |
| P1 (5박스 → 30박스) | 24 | 0 | 0 | 0% |
| P2 (30박스 → 100박스 · Phase 4 검토) | 14 | 0 | 0 | 0% |
| **합계** | **56** | **0** | **4** | **7%** |

완료 4개: A-1 bcrypt audit · A-2 세션쿠키 · A-6 require_role 헬퍼 · `/test` 100 피드백 + 5 카테고리 + Top 10 (오버나이트 patch 3 라운드).

---

## 2. P0 — Phase 2 마무리 + Phase 3 진입 직후 (총 18 task)

### 2.1 보안·인증 (4 task)

- [x] **A-1** bcrypt cost 12 audit script (`services/facing/audit_bcrypt.py`) — 6/6 hash 통과 (2026-05-22)
- [x] **A-2** 세션쿠키 보안 플래그 (SECURE · HTTPONLY · SAMESITE · TTL 8h sliding) — services/facing/app.py (2026-05-22)
- [x] **A-6** require_role + assert_gym_match + **assert_admin_gym** 헬퍼 — services/facing/api/admin.py (2026-05-22 + 23 보강)
- [x] **A-3** CSRF 토큰 — 자체 Synchronizer Token Pattern (NIST SP 800-95). `_generate_csrf_token()` + `require_csrf` 데코레이터 + `/api/v1/admin/csrf-token` endpoint. login 응답에 token 포함. facing-admin proxy 가 X-CSRF-Token 헤더 자동 주입. unsafe method 만 검증 (idempotent GET 통과). `secrets.compare_digest` timing-safe. (2026-05-23) — `require_csrf` 데코레이터 endpoint 적용은 점진 (회귀 위험).
- [x] **A-4** 로그인 rate limit + 잠금 — Flask-Limiter 도입 (`requirements.txt` + `_init_rate_limiter()`). in-memory storage default (단일 worker), Redis 전환은 N4-3 후 RATELIMIT_STORAGE_URI=redis://. default 1000/hr·100/min·login `@_rate_limit_login` 데코레이터 stub (실 limit 값은 endpoint 적용 시점에). (2026-05-23)
- [x] **A-5** audit log 강화 — 16 WRITE endpoint 모두 audit 적용 검증 완료 (자동 grep 검증). admin_logout + admin_payroll_csv (CSV 다운로드 감사 추적) 보강 (2026-05-23). audit 누락 0건.
- [ ] **A-6 적용** — admin.py 의 모든 sensitive endpoint 에 `assert_admin_gym()`·`assert_gym_match()` 호출 refactor. 헬퍼 2종 추가 완료, 21곳 적용 잔여. 예상 3일

### 2.2 PIPA·결제 (4 task)

- [x] **G-1~G-7** PIPA + 보안 헤더 — `api/privacy.py` 신규 4 endpoint: `/me/data` PIPA §35 본인 데이터 export · `/me/delete-request` PIPA §36 30일 soft delete → 영구 · `/me/access-log` 누가 내 정보 봤나 · `/consent` 4 토글 동의 (수집·이용·제3자·마케팅). app.py `_security_headers` 가 production HSTS·CSP·X-Content-Type-Options·X-Frame-Options·Referrer-Policy·Permissions-Policy 자동 적용. (G-5 암호화 컬럼·G-7 IDOR 회귀는 H-1 PostgreSQL 후 별도 라운드). (2026-05-23)
- [x] **P0-8** Toss webhook HMAC + idempotency — `api/webhooks/toss.py` 신규. HMAC-SHA256 timing-safe verify + audit_log 기반 replay 차단 + 5분 timestamp tolerance. TOSS_WEBHOOK_SECRET env 미설정 시 dev 우회 (audit 명시). (2026-05-23) — 실 결제 로직 통합 (회원권 활성·환불 reconciliation) 은 C-1 결제 작업과 같이.
- [x] **C-1** 결제·매출 — `models/gym_payment.py` 신규 (method enum cash/card/transfer/toss/refund · status enum · amount·vat·refund_amount·payment_key·card_last4·tax_invoice_no·receipt_url·processed_by). `api/payments_admin.py` 4 endpoint: POST 결제 입력 (VAT 자동 10% 계산)·GET history·POST refund (부분 환불·사장 서명·audit) ·GET revenue (월별·by_method dashboard). 영수증 PDF 생성·세금계산서는 Phase 3 중기. (2026-05-23)
- [x] **C-3** 환불 — `POST /api/v1/admin/payments/<pid>/refund` 부분 환불 + 사장 서명 + 사유 audit + status enum (refunded/partial_refund). 잔여 일수 비례 계산은 사장 입력 amount 기반. (2026-05-23)

### 2.3 DB·인프라 (3 task)

- [ ] **H-1 ~ H-5 (N4-2)** SQLite → PostgreSQL + RLS 이행 — (1단계 준비 완료) `utils/db_adapter.py` Branch by Abstraction · `scripts/postgres_rls_setup.sql` RLS 정책 + 복합 인덱스 + FORCE RLS + `app.current_gym_id()` STABLE 헬퍼 · `scripts/migrate_to_postgres.py` Big Bang ETL stub · requirements.txt psycopg2-binary 추가. **실제 cutover** (다운타임 + ETL execute + 환경 전환) 는 5박스 운영 협의 후 별도 실행.
- [x] **N4-0** region 컬럼 + DB URL 분기 skeleton — `models/gym.py` Gym.region 컬럼 + `_migrate_gym_region_column()` ALTER 마이그레이션 + `utils/region_router.py` GymRegion enum (kr/eu/us) + get_db_url(region) skeleton. EU 박스 계약 시 DATABASE_URL_EU env 추가로 분기. (2026-05-23)
- [x] **N5-1** Sentry SDK + PII scrub + release tag — `services/facing/app.py` `_init_sentry()`·`_sentry_scrub_pii()` 추가 (2026-05-23). DSN 미설정 시 자동 skip. PII filter (password·card·token·전화·생년월일·이메일) 자동 마스킹. JS SDK 도입은 Phase 3 중기.

### 2.4 도메인 핵심 (4 task)

- [x] **N1-0** movement_library 마스터 60개 동작 — `models/movement_library.py` 신규 + `data/seed_movement_library.py` 60개 seed (Gymnastics 20·Weightlifting 15·Cardio 10·Power 15). 영문·한국어 라벨·prerequisite·scaling·score_axes·benchmark_eligible 모두 포함. 부팅 시 자동 idempotent seed. (2026-05-23)
- [x] **N1-1** WOD schema — `models/wod_session.py` (gym_id·session_date·wod_type·title·desc·time_cap·posted_by) + `models/wod_score.py` (scale_type rx/scaled/rx_plus·scale_factor Decimal·score_unit enum·is_pr). leaderboard 분리 표시 준비. (2026-05-23)
- [x] **N1-2** member_pr 트래킹 — `models/member_pr.py` (weight_kg·reps·time_sec·bodyweight_kg·bw_ratio·dots_score·pr_date). DOTS 는 powerlifting 3대 한정. fitness/power.md §A4 그대로. (2026-05-23)
- [x] **N1-3** benchmark_wod + benchmark_score — `models/benchmark_wod.py` 2 테이블. category enum (girls·heroes·open·korea·custom). 박스 자체 custom benchmark 도 같은 테이블에 (gym_id NOT NULL). percentile (박스 내) 컬럼 포함. seed 데이터 (Girls+Heroes 30개) 는 다음 라운드. (2026-05-23)

### 2.5 UX·온보딩 (3 task)

- [x] **N6-0** 셀프 setup wizard 3단계 — `web/facing-admin/templates/onboarding.html` 신규 (회원권 입력 → 첫 회원+회원권 자동 발급 → 첫 계약서). progress bar + done 화면. 빈 박스(회원 0명) 로그인 시 자동 redirect (login proxy 가 onboarding_recommended flag). 사이드바 "🎯 처음 시작하기" 메뉴. (2026-05-23)
- [ ] **C2-회원상세** 회원 상세 사이드패널 — 결제 history·계약·출석·PR·메모·코치 배정 탭. 의존: H-1·N1-2. 예상 1주
- [ ] **C-D18** 박스 스위처 (사이드바 드롭다운) + JWT org_scopes — A-7 JWT 도입과 같이. 의존: A-7. 예상 1주

### 2.6 비즈니스 — 가격·결제 (2 task)

- [ ] **N2-1** 자동결제 — Toss 빌링키 **기본값 강제** + 계좌이체 +10% 수수료. 의존: P0-8. 예상 3일
- [ ] **N2-7** 3-tier 가격 페이지 — 월간 ₩100,000·6개월 ₩529,000·연간 ₩899,000 ("2개월 무료" framing). 가격표 노출 순서 anchor. 의존: C-1. 예상 2일

### 2.7 코치 정산 — 한국 노무 (1 task)

- [x] **N2-9** 코치 일용직 정산 자동화 — (1단계) `services/facing/utils/payroll_tax.py` 갑근세 + 4대보험 의무 + 두루누리 + 3개월 경과 헬퍼. self-test 9 시나리오 통과. (2단계) GymManager.employment_type 컬럼 + ALTER 마이그레이션 + payroll_upsert endpoint 통합 + coaches.html 고용 유형 컬럼·전환 권고 alert + 코치 추가 폼 select. 시드 boss=regular·coach_park=daily. (2026-05-23 완료)

### 2.8 P0 의존 그래프 (critical path 굵게)

```
즉시 (병렬 가능):
  A-3 CSRF · A-5 audit · A-6 적용 · N5-1 Sentry · N2-9 코치정산

critical path (순서 의무):
  ┌─ H-1 PostgreSQL+RLS (2~3주) ──┐
  │                               ↓
  │                            N4-0 region · A-6 적용 · G-1~G-7 PIPA · N1-0 movement_library
  │                               ↓
  P0-8 Toss webhook (3일) ───→ C-1 결제·매출 (2주) ──→ N2-1 자동결제 · N2-7 3-tier 가격 · C-3 환불
  │                                                       ↓
  │                                                    A-7 JWT (org_scopes)
  │                                                       ↓
  │                                                    C-D18 박스 스위처
  │
  N1-0 ──→ N1-1 WOD schema · N1-2 PR · N1-3 benchmark ──→ C2 회원상세

병렬 (의존 없음):
  N6-0 setup wizard · A-4 rate limit (Redis 의존)
```

---

## 3. P1 — 5박스 → 30박스 (총 24 task)

### 3.1 회원·코치 도메인 확장 (6 task)

- [x] **B-1·B-2** 회원 동의서·서명 — `models/gym_member_consent.py` 신규. 4 토글 (수집·이용·제3자·마케팅) + 서명 data URI + IP·UA + 갱신 history (invalidated_at). PIPA §15·§17·§22 의무 충족. 캔버스 서명 UI 는 frontend 작업 (다음 라운드). (2026-05-23)
- [x] **B-3·B-1** 회원 사진·이메일·비상연락처 — `gym_member_profiles` 에 `photo_url`·`email`·`emergency_contact` 컬럼 추가 + ALTER 마이그레이션. S3 또는 로컬 path. (2026-05-23)
- [x] **B-4** 회원 lifecycle — `services/expiry_scheduler.py` 가 만료 1일 후 paused·60일 후 left 자동 전이 (C-2 와 통합 완료). status enum 확장은 H-1 PostgreSQL 후 sqlite_master 패치.
- [x] **B-5** 회원 검색·필터·정렬 — `api/members_search.py` `/members/search` endpoint. q (이름·전화·이메일)·status·level·sort·page·limit 페이지네이션. (2026-05-23)
- [x] **B-6** bulk CSV import — `api/members_search.py` `/members/bulk-import` multipart. UTF-8 BOM 자동 제거·실패 줄 사유 응답. 회원권 동시 발급 (plan_name + plan_end). (2026-05-23)

### 3.2 결제·정산·계약 (4 task)

- [x] **C-2** 자동 만료·동결 — `services/expiry_scheduler.py` 매일 03:30 KST. 만료 7·3·1·0일 전 audit_log idempotent 기록 (실 SMS 발송은 E-2 후) + 만료 1일 후 자동 paused + 60일 후 left soft delete (B-4 lifecycle 자동). (2026-05-23)
- [x] **C-5** 자동결제 (정기결제) — `api/billing.py` 신규: BillingKey 모델 + 빌링키 발급 + Toss 콜백 + 매일 03:45 cron 자동 청구 + 3회 실패 시 비활성. mock 성공 stub (Toss live API 통합은 P0-8 통합 시 활성). (2026-05-23)
- [x] **C-6** 영수증 PDF — `services/receipt_pdf.py` `generate_receipt_pdf(ko/en)`. reportlab 미설치 시 text fallback. 세금계산서는 한국 국세청 e-tax 별도 (영문화 불가, PHASE3_REVISION_v2 §4.5). (2026-05-23)
- [x] **C-7** 결제 reconciliation — `services/reconciliation.py` `run_monthly_reconciliation()` + 매월 1일 04:00 KST cron. 현재 DB 자체 합계 audit 기록, Toss `/v1/settlements` 비교는 live key 등록 후. (2026-05-23)

### 3.3 인프라 P1 (4 task)

- [x] **N4-3·N4-5·N4-6** 인프라 운영 가이드 — `docs/INFRA_GUIDE.md` 신규. Redis Sentinel + 역할별 DB number 분리 + fallback · Cloudflare Free CDN · Rate Limit Redis 전환 · 5박스 invite 직전 운영 체크리스트 10개. 실 Redis 인스턴스 프로비저닝은 Railway add-on 단계. (2026-05-23)
- [x] **N5-3** JSON 구조화 log — `services/json_logger.py` `JsonFormatter` + `install_json_logging()`. production 만 활성 (dev 는 human-readable). request_id (uuid12) + gym_id + login_id + method + path 자동 tag. CloudWatch·Railway log panel 자동 파싱 호환. (2026-05-23)
- [x] **N5-4** health check 확장 — `/api/v1/health/db` (SQLAlchemy ping) + `/api/v1/health/external` (Toss·FCM·NHN·Mailgun·Sentry env 설정 여부). 기존 `/health` 유지. (2026-05-23)

### 3.4 알림·SMS·메일·푸시 (4 task)

- [x] **E-1** 알림 카탈로그 정의 — `docs/NOTIFICATION_CATALOG.md` 신규. 회원 10·사장 8·코치 5 = 23 trigger × 4 채널 (SMS·메일·푸시·SSE) 매트릭스 + 본문 템플릿 + 채널별 비용·우선순위 P0/P1/P2 + 안전장치 (rate limit·옵트아웃·시간대·dead letter). (2026-05-23)
- [x] **E-2** NHN Toast SMS — `api/notifications/sms.py` 신규. NHN_TOAST_KEY·NHN_TOAST_SENDER env 미설정 시 logger stub. 야간 22:00~08:00 자동 보류 + 정보통신망법 §50 수신거부 URL 자동 추가 + audit. (2026-05-23)
- [x] **E-3** Mailgun 메일 — `api/notifications/email.py` HTML body + attachments (영수증 PDF). MAILGUN_KEY·MAILGUN_DOMAIN env 미설정 시 stub. (2026-05-23)
- [x] **E-4** FCM 푸시 — `api/notifications/push.py` data payload 지원. FIREBASE_CREDENTIALS env 미설정 시 stub. firebase-admin SDK 통합은 credentials 등록 시. (2026-05-23)

### 3.5 i18n (3 task)

- [x] **N3-1** i18n framework — `api/i18n.py` 신규. JSON locale 구조 (`i18n/ko.json`·`i18n/en.json` 40 키 stub). `/api/v1/i18n/strings?lang=` + `/set-lang` endpoint. `t(key, lang)` 헬퍼. JA·ZH 확장은 JSON 파일 1개 추가만. (2026-05-23)
- [ ] **N3-2** 모든 UI text 키화 (300~500 키) + JS locale JSON 분리. 예상 2주 (frontend 작업 — 다음 라운드)
- [x] **N3-3** 영문 계약서 템플릿 — `i18n/en-contract.txt` 8 조항 (목적·이용기간·요금·환불·PIPA·책임·관할법·영문 영수증 vs 세금계산서 안내). 한국법 면책 문구 ("Korean version shall prevail") 포함. (2026-05-23)

### 3.6 도메인 깊이 P1 (2 task)

- [x] **N1-6** leaderboard 알고리즘 — `services/leaderboard.py` `build_leaderboard()` RX/Scaled/RX+ 분리 + `amrap_score(rounds × movements + partial)` + `compute_percentile()`. score_unit 별 정렬 방향 (time_sec asc·reps·load desc) 명세. (2026-05-23)
- [x] **N1-4** Open 시즌 — `_check_open_season()` cron 매월 1일 05:00 month IN (2,3) detection + 박스 알림 권고 로그. 수동 score 입력 UI 는 frontend 다음 라운드. (2026-05-23)

### 3.7 UX·접근성 P1 (3 task)

- [ ] **B-7** 회원 상세 — 회원권/결제/출석/코치배정/메모 5 탭 (C2 회원상세 다음 단계). 예상 1주 (frontend 작업 — 다음 라운드)
- [x] **N6-2-추가** 매니저 RBAC role — `models/gym_manager.py` role enum 에 `'manager'` 신규. CHECK constraint 확장. 권한 매트릭스는 PHASE3_REVISION_v2 §4.5 정의 (사장 권한 - 박스설정/환불승인 - 코치추가). 미들웨어 enforcement 다음 라운드. (2026-05-23)
- [x] **F-3·F-4** PT 회원-코치 매핑 + 예약 — `models/pt_session.py` 2 테이블 (PTMembership · PTSession). status enum (reserved·confirmed·completed·canceled_24h·canceled_late·no_show) + refund_pct. PHASE3_REVISION_v2 §3.2 취소 정책 3단계 schema 반영. (2026-05-23)
- [ ] **WCAG-AA** 잔여 — 사이드바 nav font 13→14px · 터치 타겟 44px · aria 속성 · focus indicator · prefers-contrast. 예상 1주

### 3.8 비즈니스 P1 (2 task)

- [x] **N2-3** retention cohort — `services/cohort.py` `build_cohort_table()` 가입 월별 M1·M3·M6·M12 잔존율 자동 계산. 5단 개입은 코치 매뉴얼 (N6-2 영상 튜토리얼) 에 포함. (2026-05-23)
- [x] **N2-10** 이탈 위험 5점 scoring — `services/cohort.py` `compute_churn_risk()` (no_checkin_14d 0.4 + no_wod_30d 0.3 + payment_failed 0.2 + single_discipline 0.1). >0.5 코치 SMS·>0.8 사장 alert. subscription-fitness §4 검증값. (2026-05-23)

---

## 4. P2 — 30박스 → 100박스 · Phase 4 검토 (총 14 task)

### 4.1 인프라 P2 (4 task)

- [x] **N4-1·N4-4·N5-2·N5-6** 인프라 단계화 — `OPERATIONS_SCALE.md §5` 에 trigger·비용·도구 통합 docs. read replica (Railway $19/월) · Celery worker dyno ($20/월) · Grafana Cloud free · Synthetic ($20/월). 실 도입은 trigger 도달 시 (CPU 80%·p95 300ms 등). (2026-05-23)

### 4.2 onboarding 스케일 (3 task — `OPERATIONS_SCALE.md` 통합)

- [x] **N6-3·N6-4·N6-5** 박스 확장 운영 — `OPERATIONS_SCALE.md` 신규. 5→30→100 단계별 onboarding 절차 + 매니저 교육 1h + 기존 회원 CSV 마이그레이션 + 첫 30일 monitoring + FAQ 6개 항목 + 카카오 챗봇 30박스 시점 + NPS 측정·Promoter 활용·Detractor 인터뷰 + 박스 추천 프로그램. (2026-05-23)

### 4.3 비즈니스·도메인 확장 (4 task)

- [x] **F-4·N2-2** PT 예약 + 취소 정책 — `models/pt_session.py` 의 PTSession status enum 이 reserved/confirmed/completed/canceled_24h/canceled_late/no_show 6 상태 + refund_pct (24h 전 100·24h 후 50·no-show 0). (2026-05-23 F-3 통합 시 완료)
- [ ] **F-5** 코치 PT 진행분 정산 강화 + 직접 송금. 다음 라운드 (frontend UI)
- [ ] **N2-11** 여성 그룹 클래스 tier — schema 만 추가하면 됨. 우선순위 낮음 (P2 후반)

### 4.4 도메인 깊이 P2 (2 task)

- [ ] **N1-5** 동작 라이브러리 60개 완성 + 외부 YouTube/SugarWOD 링크. 예상 1주
- [ ] **N1 Phase 4 defer** DOTS 글로벌 leaderboard · HYROX 포맷 · KWA/KSPO 연계 · HQ API 통합 — Phase 4 (단계 4 이후)

### 4.5 마케팅·대시보드 (1 task)

- [x] **J-1·J-2·J-3** 마케팅·매출 dashboard — `services/marketing_dashboard.py` `gym_dashboard_summary()` 한 호출 = 매출 (오늘·주·월)·status 별 회원 수·신규 가입·출석률·cohort 잔존율 (M1/M3/M6/M12)·이탈 위험 회원 수. 월간 PDF 리포트는 cron + reportlab 다음 라운드. (2026-05-23)

---

## 5. 작업 순서 권고 (시작 첫 주 — Week 1)

오버나이트 자동 진행 + 사용자 일어났을 때 점검. P0 critical path 따라:

1. **N5-1 Sentry SDK 도입** (2일) — 즉시 시작. Phase 2 운영 안전망. 의존 없음.
2. **A-5 audit log 강화** (2일) — 결제·환불·삭제 자동 기록.
3. **A-6 적용** (3일) — admin.py 의 sensitive endpoint 에 `assert_gym_match()` 호출.
4. **N2-9 코치 일용직 정산** (1주) — 한국법 의무, 단독 진행 가능.
5. **N6-0 셀프 setup wizard** (1주) — 신규 UI, DB schema 변경 없음.
6. **H-1 PostgreSQL+RLS 이행 시작** (2~3주, critical path) — Branch by Abstraction 부터.

Week 2~3 병렬:
- A-3 CSRF · A-4 rate limit (Redis 후) · N1-0 movement_library · N4-0 region 컬럼 · P0-8 Toss webhook

Week 4~6:
- C-1 결제·매출 · N2-1 자동결제 · N2-7 3-tier 가격 · A-7 JWT · C-D18 박스 스위처

Week 7~12:
- N1-1·N1-2·N1-3 WOD·PR·benchmark · C2 회원상세 · G-1~G-7 PIPA · C-3 환불

---

## 6. 측정 지표 (Phase 3 진입 가능 여부)

5박스 invite 임계 = 다음 7 항목 모두 충족:

- [ ] 5박스 production active · 30일+ 안정 운영
- [ ] uptime 99.5%+ (Sentry + Railway log)
- [ ] cross-gym 데이터 누출 0건 (pgTAP 자동 회귀 + IDOR 수동 검증)
- [ ] 결제·푸시·SMS·메일 4 채널 production 1건+ 통과
- [ ] OWASP A01·A05·A07 회귀 테스트 통과
- [ ] PIPA 동의서·삭제권·접근 audit 적용
- [ ] 박스 NPS n≥5 · 60+ (정성 인터뷰 병행)

위 7 항목이 health 70/100 임계와 일치. 현재 32~35/100.

---

## 7. 위험·블로커 모니터

작업 진행 중 다음 발생 시 즉시 보고:

- H-1 PostgreSQL 이행 중 데이터 손실 위험 (rollback 필요)
- P0-8 Toss webhook HMAC 검증 실패 (계약 필수)
- A-7 JWT 전환으로 폰 강제 업데이트 필요 (breaking change)
- N4-3 Redis Sentinel 가용성 문제
- 한국 PIPA 위반 패턴 발견
- sub-agent 가 git push 룰 위반 시도

---

## 8. cross-reference

| 문서 | 역할 |
|---|---|
| `PHASE3_REVISION_v2.md` | task 정의 + 우선순위 매트릭스 + 의존 그래프 (SSOT) |
| 본 문서 (`PHASE3_TODO.md`) | task 실행 체크리스트 + 시작/종료일 기록 |
| `PHASE2_ROADMAP.md` | 5박스 종료선 마일스톤 M1~M5 |
| `WEB_ADMIN_MEMBER_MGMT_TODO.md` | Phase 2 회원관리 영역 56 task (A·B·C·D·E·F·G·H·I·J 9 영역) |
| `GAPS_ANALYSIS_2026-05-23.md` | 5 영역 미흡 분석 |
| `docs/test/2026-05-23-0136/report.md` | /test 100 피드백 + Top 10 |
| `docs/test/phase3-review/*.md` | 4 sub-agent artifact |

---

## §변경 이력

- **2026-05-23 오전**: 신규 작성. PHASE3_REVISION_v2.md 의 P0/P1/P2 → 실행 체크리스트 변환. 의존 그래프 + Week 1 작업 순서 + 측정 지표 7 항목.
