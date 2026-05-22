# facing — Phase 3 Architecture Roadmap

> **작성일**: 2026-05-23 오전 (오버나이트 자가 준비)
> **선행 문서**: `PHASE2_ROADMAP.md` (Phase 2 5박스 종료선) · `GAPS_ANALYSIS_2026-05-23.md` (현 미흡 영역) · `~/.claude/reference/study/gym-management-saas.md` §14.6 (단계별 임계)
> **목적**: Phase 2 종료(5박스 운영 안정) 이후 단계 3 (100박스) → 단계 4 (1,000박스·enterprise) → 단계 5 (10,000박스) 까지의 아키텍처·비즈니스 진화 plan.

---

## 0. 한 줄 요약

> **Phase 2 는 박스 5곳 운영, Phase 3 은 100곳 + CrossFit 도메인 깊이 + 비즈니스 모델 확장. 키워드는 read replica · 모니터링 · WOD 트래킹 · 자동결제 · PT 예약 · retention cohort · i18n.**

---

## 1. 단계 정의 (study §14.6 기준)

| 단계 | 박스 수 | 핵심 임계 | 기간 |
|---|---|---|---|
| **단계 1** | 1박스 (데모) | MVP | Phase 1 ✓ 완료 |
| **단계 2** | 5박스 | 첫 production · PostgreSQL+RLS · 결제 live · 사용성 검증 | Phase 2 (~3개월 진행 중) |
| **단계 3** | 100박스 | read replica · 모니터링 · 도메인 깊이 · 비즈니스 모델 확장 | **Phase 3 (3~6개월)** |
| **단계 4** | 1,000박스 또는 enterprise 1곳 | bridge schema-per-gym 또는 region pinning | Phase 4 (장기) |
| **단계 5** | 10,000박스+ | Citus distributed 또는 silo (compliance trigger) | Phase 5 (초장기) |

본 문서 범위는 **Phase 3** (단계 3) — 100박스 onboarding 까지.

---

## 2. Phase 3 마일스톤 (N1~N6)

| 마일스톤 | 목표 | 종료 조건 | 예상 기간 |
|---|---|---|---|
| **N1. CrossFit 도메인 깊이** | WOD·PR·benchmark·Open 시즌 leaderboard | Wodify 핵심 기능 90% 격차 해소 | 3~4주 |
| **N2. 비즈니스 모델 확장** | 자동결제·PT 예약·retention cohort·마케팅 dashboard | 사장 NPS 60+ (5박스 → 30박스 검증) | 4~6주 |
| **N3. i18n + 외국인 사장 자립** | EN/KO 토글 + 영문 계약서·영수증 | 외국인 사장 task_complete 60%+ | 2~3주 |
| **N4. 확장 인프라** | read replica + connection pool + Redis pub/sub 백플레인 | 100박스 · 1000 req/sec · uptime 99.9% | 2~4주 |
| **N5. 모니터링·관측성** | Sentry · Grafana · Railway log · SLA dashboard | error rate <0.1% · p95 latency <500ms | 2~3주 |
| **N6. 30~100박스 onboarding** | 5박스 → 30박스 → 100박스 점진 확장 · 박스 매니저 교육 | 100박스 active · 박스당 평균 회원 50명+ | 6~10주 |

**총 예상 기간**: 19~30주 (4.5~7개월)

---

## 3. N1 — CrossFit 도메인 깊이

### 3.1 목표

Wodify · PushPress 대비 가장 큰 격차 해소. `/test` p7(Wodify 헤비유저) 의 "회원관리 스프레드시트와 차별점 없음" 진단 반전.

### 3.2 task list

- [ ] **N1-1**. **WOD 트래킹 schema + UI**
  - `wod_session` · `wod_movement` · `wod_score` 테이블 신규
  - 사장 — 박스 일일 WOD 게시 (For Time · AMRAP · EMOM · Chipper)
  - 회원 — 본인 score 입력 + history
  - 박스 leaderboard (오늘·이번주·이번달)

- [ ] **N1-2**. **PR (Personal Record) 트래킹**
  - `member_pr` 테이블 — 동작·중량·횟수·날짜
  - 회원 행 상세 사이드패널의 PR 탭
  - 자동 PR 검출 (기존 기록 갱신 시 알림)

- [ ] **N1-3**. **Benchmark WOD 표준 (CrossFit Girls + Heroes)**
  - Fran · Grace · Helen · Murph · DT · 등 30개+
  - 회원 본인 benchmark history
  - 박스 percentile (상위 N% 등)

- [ ] **N1-4**. **CrossFit Open 시즌 통합**
  - 매년 2~3월 Open 시즌 자동 detection
  - 회원별 Open score 입력 + 박스 ranking
  - HQ API 통합 검토 (가능 시)

- [ ] **N1-5**. **운동 카테고리·동작 표준 라이브러리**
  - Gymnastics · Weightlifting · Cardio · Power 4 카테고리
  - 200개+ 동작 (study `study/fitness/` 참조)
  - 동작별 표준 비디오·기준·스케일링 옵션

### 3.3 산출물

- 백엔드: `models/wod_*.py`·`api/wod.py`·`api/benchmark.py`·`api/pr.py`
- 프론트엔드: `templates/wod.html`·`templates/leaderboard.html`·`templates/benchmark.html`
- 모바일 facing-app: WOD 카드 + score 입력 + PR 히스토리

### 3.4 의존성

- Phase 2 완료 (회원 schema·결제·인증 안정) 후 착수
- study `~/.claude/reference/study/fitness/` 의 운동 표준·기록 데이터 활용

---

## 4. N2 — 비즈니스 모델 확장

### 4.1 목표

`subscription-fitness.md` 의 핵심 — 박스 사장의 운영 효율 70% + 데이터 분석 30%. 사장이 SaaS 도입 이유 충족.

### 4.2 task list

- [ ] **N2-1**. **자동결제 (정기결제·빌링키)**
  - Toss 정기결제 API + 빌링키 발급 UI
  - 매월 지정일 자동 청구
  - 실패 3회 재시도 + 사장 SMS

- [ ] **N2-2**. **PT 예약 시스템**
  - 코치 시간표 · 회원 예약 · 캔슬 정책
  - 회원 폰에서 예약 + 코치 폰에서 수락·이동
  - 사장 PC 전체 캘린더

- [ ] **N2-3**. **회원 retention cohort**
  - 가입 월별 cohort table (3·6·12개월 잔존율)
  - 휴면·이탈 위험 회원 자동 검출
  - 사장 dashboard 주간 alert

- [ ] **N2-4**. **마케팅·매출 dashboard**
  - 매출 추세 · 신규·이탈 funnel · 박스 NPS · 회원 LTV
  - 월간 자동 리포트 PDF + 메일

- [ ] **N2-5**. **할인·쿠폰·친구 추천 (선택)**
  - 코드 기반 할인 + 친구 추천 보상 + 시즌 이벤트
  - subscription-fitness §marketing 룰 적용

- [ ] **N2-6**. **회원 등급·VIP·loyalty (선택)**
  - 출석 30회·90회·365회 같은 milestone
  - VIP 회원 우선 락커 배정 등

### 4.3 산출물

- 백엔드: `api/billing.py`·`api/pt.py`·`api/cohort.py`·`api/marketing.py`
- 프론트엔드: `templates/billing.html`·`templates/pt.html`·`templates/cohort.html`
- 백그라운드: APScheduler·Celery beat (cohort 갱신 + 재시도 큐)

---

## 5. N3 — i18n + 외국인 사장 자립

### 5.1 목표

`/test` p6(David Choi) task_complete 0% 반전. 한국 CrossFit 박스 30%+ 가 외국인 코치·재한 외국인 회원 보유 현실.

### 5.2 task list

- [ ] **N3-1**. **i18n framework 도입**
  - Flask-Babel + JSON locale 파일
  - 기본 ko, EN 추가 (향후 JA·ZH 확장 가능)
  - 사이드바 EN/KO 토글 + cookie 저장

- [ ] **N3-2**. **모든 UI 텍스트 번역 키화**
  - 사이드바·헤더·페이지 제목·버튼·placeholder·토스트
  - 약 300~500 키 예상

- [ ] **N3-3**. **영문 계약서 템플릿**
  - 한국 박스 ↔ 외국인 회원용 영문 표준 계약서
  - 환불 규정 영문 + 법적 disclaimer

- [ ] **N3-4**. **영문 영수증·세금계산서**
  - 한국 세금계산서 영문 표기 (사업자번호·세액 등)
  - PDF 생성 시 폰트 폴백 (영문은 Inter 또는 Roboto)

- [ ] **N3-5**. **날짜·통화·숫자 locale**
  - 2026-05-23 vs May 23, 2026
  - ₩50,000 vs $50

- [ ] **N3-6**. **에러 메시지·시스템 알림 영문화**
  - SMS·메일 본문 영문 옵션
  - FCM 푸시 본문 영문 옵션

---

## 6. N4 — 확장 인프라

### 6.1 목표

study §3 의 100박스+ 임계. read replica·connection pool·Redis pub/sub 백플레인.

### 6.2 task list

- [ ] **N4-1**. **PostgreSQL read replica**
  - Railway PostgreSQL replica add-on
  - 통계·리포트·검색 쿼리는 replica
  - write 은 primary
  - lag 모니터링 (< 5초 기준)

- [ ] **N4-2**. **connection pool 튜닝**
  - PgBouncer transaction mode (study §3.4)
  - 박스당 max connection 제한
  - tenant 별 query timeout (`statement_timeout` 5s)

- [ ] **N4-3**. **Redis pub/sub 백플레인**
  - 모든 Flask instance 가 Redis subscribe
  - SSE fan-out 다중 worker 가능
  - 회원 가입 신청 → 모든 사장 PC 즉시 알림
  - Redis 도 별도 cluster (Railway add-on)

- [ ] **N4-4**. **APScheduler → Celery 이행**
  - 워커 증설 시 인프로세스 한계
  - Celery + Redis broker
  - 백업·리포트·SMS 전송·cohort 갱신 분산 처리

- [ ] **N4-5**. **CDN · static asset 분리**
  - Vercel · Cloudflare 사용
  - 폰트·이미지·JS bundle 분리
  - p95 latency < 500ms

- [ ] **N4-6**. **rate limit 강화**
  - Flask-Limiter + Redis (전체)
  - 박스당·user당·endpoint당 limit
  - 결제·로그인 더 엄격 (10/min)

### 6.3 아키텍처 변경

- DB: PostgreSQL primary + replica 1개+
- Redis: SSE + Celery broker + rate limit + session store
- Celery worker 2~5 instance
- Nginx · Cloudflare CDN

---

## 7. N5 — 모니터링·관측성

### 7.1 task list

- [ ] **N5-1**. **Sentry SDK 도입**
  - 백엔드 + 프론트엔드 (Flask + JS)
  - PII scrub + release tag
  - 일일 error digest 사장(우리) 메일

- [ ] **N5-2**. **Grafana dashboard**
  - 박스별 request 수 · latency · error rate
  - DB connection pool 사용률
  - SSE 동접 수
  - 박스별 SLA (uptime 99.9% 목표)

- [ ] **N5-3**. **로그 구조화 (JSON)**
  - logging.basicConfig 변경
  - request_id · gym_id · user_id 자동 tag
  - CloudWatch / Railway log 호환

- [ ] **N5-4**. **health check 확장**
  - `/api/v1/health/db` (Postgres ping)
  - `/api/v1/health/redis` (Redis ping)
  - `/api/v1/health/external` (Toss·FCM·NHN)
  - 박스별 마지막 활동 시각

- [ ] **N5-5**. **incident response runbook**
  - DB down · Redis down · 결제 webhook 실패 시
  - escalation paths · rollback 절차
  - on-call rotation (Phase 3 후반에 필요할 수도)

- [ ] **N5-6**. **synthetic monitoring**
  - 5분마다 핵심 endpoint 자동 호출 (login·members·payments)
  - 실패 시 SMS alert

---

## 8. N6 — 30~100박스 onboarding

### 8.1 목표

5박스 (Phase 2 종료) → 30박스 → 100박스 점진 확장. 박스 매니저(사장이 아닌 직원) 교육 포함.

### 8.2 task list

- [ ] **N6-1**. **5박스 안정화 (Phase 2 → Phase 3 transition)**
  - 30일+ 안정 운영 검증
  - 결제·푸시·SMS·메일 4 채널 production 1건+ 통과
  - cross-gym 데이터 누출 0건 (RLS·pgTAP 검증)

- [ ] **N6-2**. **박스 매니저 교육 컨텐츠**
  - 영상 튜토리얼 (10분 onboarding · 30분 상세)
  - PDF 매뉴얼 (50~100p)
  - FAQ + 도움말 센터

- [ ] **N6-3**. **5박스 → 30박스 (1~2개월)**
  - 한국 CrossFit Affiliate 100여곳 중 20~30곳 가입 권유
  - 초기 30일 무료 trial (subscription-fitness §pricing 참조)
  - 박스마다 30분 onboarding 세션

- [ ] **N6-4**. **30박스 → 100박스 (3~4개월)**
  - 박스 추천 프로그램 (1박스 추천 = 1개월 무료)
  - 박스 community Slack/카카오 운영
  - 사용자 conference 또는 webinar 1회

- [ ] **N6-5**. **지원·CS 체계**
  - 카카오 상담 채널 또는 챗봇
  - 회원 → 박스 사장 → 우리 3 tier escalation
  - 응답 시간 (≤4시간 영업일)

- [ ] **N6-6**. **NPS · churn 추적**
  - 박스 NPS 분기 1회 측정 (60+ 목표)
  - churn 박스 인터뷰 (이탈 이유 파악)
  - 개선 plan 분기별 갱신

### 8.3 비즈니스 검증 지표

- 100박스 active (single tenant 활동 30일+)
- 박스당 평균 회원 50명+ (총 5000명+)
- 박스 NPS 60+ (5명 중 3명+ 추천 의향)
- 박스 monthly churn < 5%
- uptime 99.9%+

---

## 9. 횡단 관심사

### 9.1 보안·격리 (study §8 OWASP A01 + §11 PIPA)

- 단계 3 도달 시 박스 100개 = 회원 5000명. 한 줄 RLS 버그 = 5000명 데이터 노출
- 정기 보안 audit (분기 1회 외부)
- pen-test (단계 3 진입 전 1회)
- SOC2 또는 ISO 27001 인증 검토 (단계 4 enterprise tier 진입 시)

### 9.2 비용 모델

- 5박스: Railway $100/월 (PostgreSQL + Flask + Redis 추정)
- 30박스: $300/월 (read replica + Celery)
- 100박스: $800/월 (CDN + Sentry + Grafana add-on)
- 단계 4 (1000박스): $3,000~5,000/월 (bridge or silo)

박스당 구독료 $50/월 가정 시:
- 5박스 = $250/월 수익 (적자)
- 30박스 = $1,500/월 (break-even 근처)
- 100박스 = $5,000/월 (이익 시작)
- 1000박스 = $50,000/월

`subscription-fitness.md` §pricing 참조해서 박스 LTV·CAC 정밀 계산 권장.

### 9.3 회의·정기 검토

- 주간 health 지표 보고 (Slack)
- 월간 KPI 리뷰
- 분기별 박스 NPS + roadmap 갱신

---

## 10. Phase 3 종료 조건 (Phase 4 → 단계 4 transition)

다음 6 항목 모두 충족 시 Phase 3 종료:

- [ ] 100박스 production active · 각 30일+ 안정 운영
- [ ] uptime 99.9%+ (Sentry + Grafana 측정)
- [ ] 박스 monthly churn < 5%
- [ ] 박스 NPS 60+ 
- [ ] CrossFit 도메인 깊이 (WOD·PR·benchmark·Open) 활성 사용 박스 80%+
- [ ] 자동결제·PT 예약 도입 박스 50%+
- [ ] enterprise 1곳 (200+ 회원 박스 또는 박스 체인) onboarding 검토 진입

---

## 11. Phase 4 예고 (참고용)

study §14.6 단계 4 — 1,000박스 또는 enterprise 1곳:

- **bridge schema-per-gym** — Notion·Shopify 패턴
- **region pinning** — EU 진출 시 GDPR Art. 44~49 대응
- **enterprise tier** — BYOK · SLA · 24/7 지원
- **B2B sales motion** — 박스 체인 (대형 brand·프랜차이즈)

---

## §변경 이력

- **2026-05-23 오전**: 신규 작성. Phase 3 (단계 3 = 100박스) 6 마일스톤 (N1~N6). GAPS_ANALYSIS_2026-05-23.md 의 P0/P1/P2 → Phase 3 task 매핑.

---

## 12. 부록 — 의존 문서

- `docs/ARCHITECTURE_BRIEF.md` — 시스템 SSOT
- `docs/PHASE2_ROADMAP.md` — Phase 2 (5박스) 마일스톤 M1~M5
- `docs/GAPS_ANALYSIS_2026-05-23.md` — 현 미흡 영역 (Phase 3 input)
- `docs/WEB_ADMIN_MEMBER_MGMT_TODO.md` — 9 영역 56 task
- `docs/test/2026-05-23-0136/report.md` — 사용성 테스트 결과
- `~/.claude/reference/study/gym-management-saas.md` — 멀티테넌시·RBAC·SSE·GDPR·Flutter
- `~/.claude/reference/study/subscription-fitness.md` — 비즈니스 모델·가격·marketplace
- `~/.claude/reference/study/ux-testing.md` — 사용성 테스트 방법론
- `~/.claude/reference/study/fitness/` — CrossFit 운동 표준·기록 (N1 활용)
