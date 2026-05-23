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
| P0 (Phase 2 마무리·Phase 3 진입) | 18 | 0 | 4 | 22% |
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
- [ ] **A-4** 로그인 rate limit + 잠금 — Flask-Limiter + Redis sliding window. IP 5분/5회·계정 30분/10회. 의존: N4-3 Redis. 예상 3일
- [x] **A-5** audit log 강화 — 16 WRITE endpoint 모두 audit 적용 검증 완료 (자동 grep 검증). admin_logout + admin_payroll_csv (CSV 다운로드 감사 추적) 보강 (2026-05-23). audit 누락 0건.
- [ ] **A-6 적용** — admin.py 의 모든 sensitive endpoint 에 `assert_admin_gym()`·`assert_gym_match()` 호출 refactor. 헬퍼 2종 추가 완료, 21곳 적용 잔여. 예상 3일

### 2.2 PIPA·결제 (4 task)

- [ ] **G-1~G-7** PIPA 동의서·암호화·삭제권·접근 audit·CSP·HSTS·IDOR 회귀 테스트 (WEB_ADMIN_MEMBER_MGMT_TODO.md §8 참조). 의존: H-1 PostgreSQL. 예상 1주
- [ ] **P0-8 (N2-1·N2-7~N2-9 일부)** Toss webhook HMAC + idempotency + 환불 reconciliation. 의존: 없음. 예상 3일
- [ ] **C-1** 결제·매출 — 회원 상세에 결제 추가 (현금/카드/이체) + 영수증 자동 + 세금계산서. 의존: P0-8. 예상 2주
- [ ] **C-3** 환불 — 부분 환불 + 잔여 일수 비례 + 사유 audit. 예상 2일

### 2.3 DB·인프라 (3 task)

- [ ] **H-1 ~ H-5 (N4-2)** SQLite → PostgreSQL + RLS 이행 — Big Bang ETL + Branch by Abstraction (v2 §5.5). PgBouncer transaction mode + `SET LOCAL` + 복합 인덱스. 의존: 없음 (핵심 critical path). 예상 2~3주
- [x] **N4-0** region 컬럼 + DB URL 분기 skeleton — `models/gym.py` Gym.region 컬럼 + `_migrate_gym_region_column()` ALTER 마이그레이션 + `utils/region_router.py` GymRegion enum (kr/eu/us) + get_db_url(region) skeleton. EU 박스 계약 시 DATABASE_URL_EU env 추가로 분기. (2026-05-23)
- [x] **N5-1** Sentry SDK + PII scrub + release tag — `services/facing/app.py` `_init_sentry()`·`_sentry_scrub_pii()` 추가 (2026-05-23). DSN 미설정 시 자동 skip. PII filter (password·card·token·전화·생년월일·이메일) 자동 마스킹. JS SDK 도입은 Phase 3 중기.

### 2.4 도메인 핵심 (4 task)

- [ ] **N1-0** movement_library 마스터 60개 동작 — Gymnastics 20·Weightlifting 15·Cardio 10·Power 15. 한국어 라벨 컬럼. 의존: H-1. 예상 5일
- [ ] **N1-1** WOD schema + scale_type/scale_factor — wod_session·wod_score 테이블. 의존: N1-0. 예상 5일
- [ ] **N1-2** member_pr + bodyweight_kg + bw_ratio + dots_score (powerlifting 3대 한정). 의존: N1-0. 예상 3일
- [ ] **N1-3** benchmark_wod + benchmark_score 별도 테이블 + Korea/Custom 카테고리. Girls+Heroes 30개 우선. 의존: N1-0. 예상 5일

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

- [ ] **B-1** 회원 schema PIPA 분리 — 식별·신체·민감 정보 별도 + 암호화 컬럼. 의존: H-1. 예상 1주
- [ ] **B-2** 동의서·서명 컬럼 + 캔버스 서명 UI. 예상 5일
- [ ] **B-3** 회원 사진 — image/jpeg·png magic byte 검증. 예상 3일
- [ ] **B-4** 회원 lifecycle — pending·active·paused·left·removed enum + 자동 전이. 예상 5일
- [ ] **B-5** 회원 검색·필터·정렬 강화 — status·기간·코치별·금액. 예상 5일
- [ ] **B-6** bulk 작업 — 체크박스 일괄 + CSV import (200명) + CSV export. 예상 2주 (큰 task)

### 3.2 결제·정산·계약 (4 task)

- [ ] **C-2** 자동 만료·동결 — APScheduler 매일 03:00 KST. 만료 7일 전 SMS. 예상 3일
- [ ] **C-5** 자동결제 (정기결제) — Toss 빌링키. 매월 지정일 + 3회 재시도. 예상 1주
- [ ] **C-6** 영수증·세금계산서 PDF — 영수증 메일·세금계산서 사장 요청 시. 예상 1주
- [ ] **C-7** 결제 reconciliation — 월 1회 Toss 정산 vs DB 비교 + 불일치 alert. 예상 3일

### 3.3 인프라 P1 (4 task)

- [ ] **N4-3** Redis Sentinel + SSE fan-out + fallback (local queue · APScheduler 동기 fallback). 예상 1주
- [ ] **N4-5** CDN — Cloudflare free tier. 예상 1일
- [ ] **N4-6** rate limit — Flask-Limiter + Redis (의존: N4-3). 예상 3일
- [ ] **N5-3** JSON 구조화 log + request_id·gym_id·user_id 자동 tag. 예상 2일
- [ ] **N5-4** health check 확장 — /db /redis /external. 예상 1일

### 3.4 알림·SMS·메일·푸시 (4 task)

- [ ] **E-1** 알림 카탈로그 정의 (회원·사장·코치 트리거 매트릭스). 예상 2일
- [ ] **E-2** NHN Toast SMS — sender ID + 발송 limit + audit. 예상 1주
- [ ] **E-3** Mailgun 메일 — SPF·DKIM·DMARC + HTML 템플릿. 예상 1주
- [ ] **E-4** FCM 푸시 (폰 회원·코치). 의존: 폰 facing-app FCM stub → live. 예상 5일

### 3.5 i18n (3 task)

- [ ] **N3-1** Flask-Babel + JSON locale (EN only · 확장 구조). 예상 1주
- [ ] **N3-2** 모든 UI text 키화 (300~500 키) + JS locale JSON 분리. 예상 2주
- [ ] **N3-3** 영문 계약서 + 한국법 면책 + Receipt (세금계산서 영문화 X). 예상 1주

### 3.6 도메인 깊이 P1 (2 task)

- [ ] **N1-4** Open 시즌 수동 입력 + 박스 ranking + `month IN (2,3)` 알림. 예상 3일
- [ ] **N1-6** leaderboard 알고리즘 명세 (RX/Scaled 분리) + AMRAP 계산식. 예상 3일

### 3.7 UX·접근성 P1 (3 task)

- [ ] **B-7** 회원 상세 — 회원권/결제/출석/코치배정/메모 5 탭 (C2 회원상세 다음 단계). 예상 1주
- [ ] **F-3** PT 회원-코치 매핑 (main·sub) + PT 횟수권. 예상 5일
- [ ] **WCAG-AA** 잔여 — 사이드바 nav font 13→14px · 터치 타겟 44px · aria 속성 · focus indicator · prefers-contrast. 예상 1주

### 3.8 비즈니스 P1 (2 task)

- [ ] **N2-3** retention cohort + 5단 개입 (onboarding/코치연락/그룹WOD/다중discipline/commitment). 예상 2주
- [ ] **N2-10** 이탈 위험 5점 scoring + 자동 개입 (코치 SMS · 사장 alert). 예상 1주

---

## 4. P2 — 30박스 → 100박스 · Phase 4 검토 (총 14 task)

### 4.1 인프라 P2 (4 task)

- [ ] **N4-1** read replica — p95>300ms 또는 CPU 80%+ 실측 시. 예상 3일
- [ ] **N4-4** Celery — worker 2+ 필요 시점. 예상 1주
- [ ] **N5-2** Grafana dashboard — 박스별 req/latency. 예상 1주
- [ ] **N5-6** synthetic monitoring — 5분마다 핵심 endpoint ping. 예상 3일

### 4.2 onboarding 스케일 (3 task)

- [ ] **N6-3** 5박스 → 30박스 onboarding + 법무 자문 30박스 전. 예상 4~8주 (운영)
- [ ] **N6-4** 30박스 → 100박스 + 그룹 Zoom 전용 + 녹화 자동 업로드. 예상 4~12주 (운영)
- [ ] **N6-5** FAQ 6개 + 카카오 챗봇 + 야간 자동 응답. 예상 2주

### 4.3 비즈니스·도메인 확장 (4 task)

- [ ] **F-4** PT 예약 시스템 — 코치 시간표·회원 예약·캔슬 정책 3단계. 예상 2주
- [ ] **F-5** 코치 정산 강화 — PT 진행분 별도 + 직접 송금 연동 (선택). 예상 1주
- [ ] **N2-2** PT 예약 + 24h 전 전액 환불 + 24h 후 50% + No-show 디파짓. 예상 1주
- [ ] **N2-11** 여성 그룹 클래스 tier + 커플/패밀리 패키지 + 여성 전용 리더보드. 예상 5일

### 4.4 도메인 깊이 P2 (2 task)

- [ ] **N1-5** 동작 라이브러리 60개 완성 + 외부 YouTube/SugarWOD 링크. 예상 1주
- [ ] **N1 Phase 4 defer** DOTS 글로벌 leaderboard · HYROX 포맷 · KWA/KSPO 연계 · HQ API 통합 — Phase 4 (단계 4 이후)

### 4.5 마케팅·대시보드 (1 task)

- [ ] **J-1·J-2·J-3** 마케팅·매출 dashboard + 월간 자동 PDF 리포트 + 회원 retention cohort table. 예상 2주

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
