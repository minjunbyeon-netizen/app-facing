# facing — Phase 2 Architecture Roadmap

> **작성일**: 2026-05-22 (회의 직후)
> **상태**: 초안 — 합의 후 SSOT 로 격상
> **선행 문서**: `docs/ARCHITECTURE_BRIEF.md` (시스템 SSOT) · `~/.claude/reference/study/gym-management-saas.md` (아키텍처·법규 근거)
>
> ⚠️ 이 로드맵은 **아키텍처 수준** 의 마일스톤·task 묶음이에요. 실제 코드 작업 단위(파일/라우트/컴포넌트)는 각 task 착수 시 별도 sub-plan 으로 분해해요.

---

## 0. 한 줄 요약

> **Phase 1 (MVP·SQLite·단일 박스 데모) 끝. Phase 2 는 "첫 5 박스 실 운영" 까지. 키워드는 PostgreSQL+RLS 이행 · 실 결제·푸시·SMS 통합 · 사장 5명 사용성 검증 · 코치/회원 도메인 깊이.**

study `gym-management-saas.md` §14.6 우선순위 단계 중 **단계 2 (첫 5 박스)** 가 Phase 2 의 종료선.

---

## 1. 마일스톤 5개 (M1~M5)

| 마일스톤 | 목표 | 종료 조건 | 예상 기간 |
|---|---|---|---|
| **M1. 사용성 검증 + hotfix** | 회의 피드백·사장 5명/회원 5명 think-aloud → 발견 이슈 즉시 수정 | 13 sanity 통과 유지 + 신규 발견 이슈 zero | 1~2주 |
| **M2. 실 서비스 통합** | Toss live · FCM live · NHN SMS · Mailgun env 한 줄씩 켜기 | 4 외부 시스템 모두 production 1건 호출 통과 | 1~2주 |
| **M3. DB 아키텍처 이행** | SQLite → PostgreSQL + RLS (pool 모델) | 모든 tenant table RLS 강제 + pgTAP cross-gym 차단 검증 | 2~3주 |
| **M4. 멀티 박스 운영** | 사장 다중 박스 (D18) · 코치 다중 박스 (D19) UI 확장 | 한 사용자 = N gym scope 동작 | 2주 |
| **M5. 배포 + 첫 5 박스 onboarding** | Railway/Vercel 배포 · 실 박스 5곳 invite · 30일 안정 운영 | uptime 99.5%+ · 5 박스 active · 결제 stub → live 전환 완료 | 2~4주 |

총 예상 기간: **8~13주** (2~3개월). 병렬화 가능한 task 는 마일스톤 안에서 표시.

---

## 2. M1 — 사용성 검증 + hotfix

### 2.1 목표

회의 피드백 수렴 + Phase 5 실 사용성 테스트 (사장 5명·회원 5명 think-aloud) 로 MVP 결함 즉시 잡기.

### 2.2 task list

- [ ] **M1-1**. 회의 피드백 수렴 정리 (`docs/MEETING_FEEDBACK_2026-05-22.md`)
  - 사장·코치·회원 관점 각각 분류
  - severity tag (block / major / minor / nice-to-have)
- [ ] **M1-2**. Phase 5 사용성 테스트 설계 (`reference/study/ux-testing.md` 활용)
  - JTBD 기반 페르소나 5+5명 모집 기준 (박스 사장·코치·회원 각 5/5/5)
  - Think-aloud 시나리오 4개: 가입→체크인 / 회원권 발급 / 출석 + 페어링 / 결제+영수증
  - Nielsen 휴리스틱 10 + Baymard 이탈 패턴 체크 시트
- [ ] **M1-3**. 사용성 테스트 실행 + 100 피드백 수집
  - `/test` 스킬 자동 시뮬레이션 후 실 사용자 차이 분석
  - 카테고리 5개 자동 도출
- [ ] **M1-4**. hotfix 우선순위 결정 + 실행
  - block / major 만 M1 안에 처리
  - minor / nice-to-have 는 백로그 (M5 이후)
- [ ] **M1-5**. 회귀 검증 — sanity 13 + usability 14 + member_sync 10 재실행, 모두 통과

### 2.3 아키텍처 변경

- 없음 (M1 은 검증·수정 사이클, 구조 변경 없음)

### 2.4 산출물

- `docs/MEETING_FEEDBACK_2026-05-22.md`
- `docs/USABILITY_TEST_RESULTS.md`
- hotfix commit log (회귀 검증 통과 마커 포함)

---

## 3. M2 — 실 서비스 통합

### 3.1 목표

HANDOFF "실 서비스 통합" 4건 — 환경변수 1줄씩 켜면 production 동작하도록 마무리.

### 3.2 task list

- [ ] **M2-1**. **Toss Payments live 전환** (`reference/study/payment.md` 활용)
  - `TOSS_SECRET` Railway env 등록
  - webhook HMAC-SHA256 verify (`api/webhooks/toss.py`)
  - idempotency key 처리 (replay 방어)
  - 환불 endpoint + reconciliation
  - 결제 1건 production 호출 통과 검증
- [ ] **M2-2**. **FCM live 전환**
  - `FIREBASE_CREDENTIALS` 서비스 계정 JSON 등록
  - `send_push()` stub → 실 호출 전환
  - 토큰 만료·재등록 로직
  - 폰 가입 신청 → 사장 PC 푸시 1건 production 통과
- [ ] **M2-3**. **NHN Cloud Toast SMS 통합**
  - 회원 가입 신청 → 사장 SMS · 결제 완료 → 회원 SMS
  - sender ID 인증 (한국 통신사 요구)
  - rate limit + 비용 모니터
- [ ] **M2-4**. **Mailgun 메일 통합**
  - 영수증·계약서·월간 리포트 메일 발송
  - SPF·DKIM·DMARC 설정
  - 한국어 본문 인코딩 검증
- [ ] **M2-5**. **외부 통합 운영 dashboard** (선택)
  - Toss·FCM·SMS·메일 4 채널 30일 송수신 통계
  - 실패율 + alert 임계값

### 3.3 아키텍처 변경

- `services/facing/api/webhooks/` 신규 디렉토리
- `services/facing/api/notifications/` (FCM·SMS·메일 통합 인터페이스 — adapter pattern)
- 환경변수 추가: `TOSS_SECRET`·`FIREBASE_CREDENTIALS`·`NHN_TOAST_KEY`·`MAILGUN_KEY` (Railway 만, 로컬 `.env` 미적용 — CLAUDE.md §0-A 준수)

### 3.4 의존성 / 위험

- Toss 계약 + KYC 심사 — 사용자 액션 필요
- 한국 SMS 발신 sender ID 사전 인증 (1~2주 소요)
- Mailgun 도메인 DNS 권한 — 사용자 액션

---

## 4. M3 — DB 아키텍처 이행 (SQLite → PostgreSQL + RLS)

### 4.1 목표

study `gym-management-saas.md` §14.1 권고 그대로 — 첫 박스 추가 시점에 pool + RLS 이행.

### 4.2 task list

- [ ] **M3-1**. **마이그레이션 도구 도입**
  - Alembic 셋업 (`services/facing/migrations/`)
  - 현재 `migrate_db()` 자동 import + sqlite_master 직접 편집 패턴 → Alembic versioned migration 으로 이전
  - SQLite → PostgreSQL 스키마 변환 스크립트
- [ ] **M3-2**. **모든 tenant table 에 `gym_id` 강제**
  - 현재 8 신규 table 검증 (gym_manager·gym_member_profile·gym_membership·gym_locker·gym_attendance·gym_contract·gym_inquiry·audit_log)
  - 누락된 table 식별 + `gym_id` 컬럼 추가
- [ ] **M3-3**. **Postgres RLS 활성화**
  - 모든 tenant table 에 `ENABLE` + `FORCE ROW LEVEL SECURITY`
  - SELECT/INSERT/UPDATE/DELETE 정책 (study §3.1 패턴)
  - `(gym_id, primary_key)` 복합 인덱스 (study §3.4 anti-pattern 회피)
  - VOLATILE 함수 사용 시 `(SELECT current_setting(...))` subquery 강제
- [ ] **M3-4**. **미들웨어 — 요청 진입 시 `SET LOCAL app.current_gym_id`**
  - JWT `org_scopes` 에서 `gym_id` 추출
  - PgBouncer transaction mode 호환 (SET LOCAL 만 사용)
  - 누락·실패 시 명시 reject (open by default 금지)
- [ ] **M3-5**. **pgTAP cross-gym 차단 검증 (CI)**
  - 박스 A user 가 박스 B 데이터 접근 시도 = 0 row 반환 검증
  - 모든 RLS-enabled table 대상 자동 테스트
- [ ] **M3-6**. **superuser 분리**
  - migration·backup 전용 user (RLS bypass 허용)
  - 애플리케이션 user (RLS 강제)
- [ ] **M3-7**. **데이터 마이그레이션 plan**
  - 기존 SQLite `facing.db` → PostgreSQL 1회성 export/import
  - 데모 데이터 vs 실 박스 데이터 구분
  - rollback 절차

### 4.3 아키텍처 변경

- DB: SQLite → PostgreSQL 15+ (Railway add-on)
- ORM: SQLAlchemy 그대로, dialect 만 변경
- migration: `migrate_db()` 함수 폐기 → Alembic
- backup: `backup.py` APScheduler → `pg_dump` + Railway 백업 정책

### 4.4 의존성 / 위험

- SQLite 의존 코드 (`sqlite_master` 직접 편집·CHECK enum 마이그레이션) 전면 재작성 필요
- Railway PostgreSQL plan 비용 증가
- 다운타임 최소화 plan 필요 (실 박스 가입 후라면 zero-downtime migration)

---

## 5. M4 — 멀티 박스 운영 (D18·D19)

### 5.1 목표

브리프 §D18 (사장 다중 박스 운영) · §D19 (코치 다중 박스 운영) 의 UI/UX 구현. study `gym-management-saas.md` §7 의 JWT `org_scopes` 패턴 적용.

### 5.2 task list

- [ ] **M4-1**. **JWT `org_scopes` 클레임 구조 적용**
  - 단일 `gym_id` → `org_scopes: [{gym_id, role}, ...]` 배열로 확장
  - 토큰 발급·갱신·검증 로직 업데이트
  - RFC 7519 JWT 스펙 유지
- [ ] **M4-2**. **PC 사장 — 박스 스위처 UI**
  - 헤더에 현재 박스 표시 + 드롭다운으로 박스 전환
  - 박스 전환 = silent re-auth (새 토큰 발급)
  - 박스별 분리된 stats·members·payroll·lockers·contracts
- [ ] **M4-3**. **폰 코치 — 박스 페어링 누적**
  - 한 코치가 박스 A·B 양쪽 페어링 가능
  - 박스별 device_hash 분리 매핑
  - 화면 상단 박스 indicator + 전환
- [ ] **M4-4**. **API 권한 재검증**
  - 모든 sensitive endpoint 가 권한 게이트 통과 (study §7.3 패턴)
    *(2026-08-12: 구현은 `@require_staff` 하나로 통일 — `require_role()` 은 삭제)*
  - 다른 박스 자원 접근 = 403 (study §8.3 horizontal escalation 방어)
- [ ] **M4-5**. **회원 측 영향 (선택)**
  - 회원이 박스 A 가입 + 박스 B 게스트 방문 시나리오 처리
  - 추후 marketplace 확장 여지 (subscription-fitness study 참고)

### 5.3 아키텍처 변경

- JWT 페이로드 schema 변경 (마이그레이션 필요 — 기존 토큰 expiry 까지 유예)
- `gym_managers.gym_id` 단일 컬럼 → `gym_manager_assignments` 별도 table (gym_id, manager_id, role)
- audit_log 에 `(gym_id, manager_id, action)` 3-tuple 의무

### 5.4 의존성 / 위험

- M3 완료 후 착수 권장 (RLS 가 박스 격리 보장하지 않으면 멀티 박스 = 데이터 누출 위험)
- 토큰 페이로드 schema 변경 = breaking change. 폰 앱 강제 업데이트 1회 필요

---

## 6. M5 — 배포 + 첫 5 박스 onboarding

### 6.1 목표

Railway/Vercel production 배포 + 실 박스 5곳 invite + 30일 안정 운영. Phase 2 종료선.

### 6.2 task list

- [ ] **M5-1**. **Railway 백엔드 배포**
  - `services/facing` Dockerfile · railway.toml
  - PostgreSQL plan + Redis (SSE pub/sub 백플레인) add-on
  - 환경변수 production 등록 (M2 4 채널 + DB)
  - 헬스체크 + 자동 재기동 + 백업
- [ ] **M5-2**. **Vercel PC 사장 웹 배포**
  - `web/facing-admin` Vercel 프로젝트
  - 백엔드 URL = Railway 도메인
  - 사장 도메인 매핑 (`admin.facing.app` 또는 사용자 명시 도메인)
- [ ] **M5-3**. **폰 release APK 빌드**
  - `--dart-define=API_BASE_URL=https://api.facing.app` (실 도메인)
  - release 빌드 30MB 검증 (debug 178MB 대비)
  - 데모 페르소나 스위처 release 에서 제거 (5 박스 onboarding 단계라 불필요)
  - Play Store internal testing track 업로드 (closed beta)
- [ ] **M5-4**. **실 박스 5곳 onboarding**
  - 박스 1: FACING SEONGSU (이미 데모 박스)
  - 박스 2~5: 사용자 네트워크 박스 4곳 (CrossFit Affiliate 우선)
  - 사장 계정 발급·회원 마이그레이션·회원권·결제 setup 가이드
  - 박스별 30분 onboarding 세션 (사용자 직접 또는 화상)
- [ ] **M5-5**. **30일 안정 운영 + 모니터링**
  - uptime 99.5%+ 목표
  - error tracking (Sentry 또는 Railway log)
  - 일일 sanity check 자동 실행 (APScheduler)
  - 박스별 weekly 지표 리포트 자동 생성
- [ ] **M5-6**. **결제 stub → live 완전 전환**
  - 5 박스 모두 Toss live 등록
  - 환불·정기결제·실패 재시도 케이스 검증
  - 회계 reconciliation 월 1회

### 6.3 아키텍처 변경

- 도메인: localhost → 실 도메인 (`api.facing.app` · `admin.facing.app`)
- CORS · CSP · HSTS production 설정
- Redis 도입 (SSE pub/sub fan-out — study §9.5)
- 모니터링 stack: Railway log + Sentry + (선택) Grafana

### 6.4 의존성 / 위험

- 사용자 인맥 박스 5곳 사전 약속 필요
- 도메인 구매·DNS 설정 사용자 액션
- Toss 사업자 등록 + 가맹점 심사 통과 의존

---

## 7. 횡단 관심사 (모든 마일스톤 적용)

### 7.1 보안 (study §8 OWASP A01 준수)

- IDOR 방어: 모든 `/:resource_id` endpoint 에 `gym_id` 검증 (study §8.3 Failure 1 패턴)
- vertical escalation: `@require_staff` 매 sensitive endpoint (study §8.3 Failure 2)
- horizontal escalation: JWT 재검증 + 자원 owner 매칭 (study §8.3 Failure 3)
- 시크릿: `.env` 절대 commit 금지 (글로벌 §2-A-1)

### 7.2 모바일 보안 (study §13)

- flutter_secure_storage 만 사용 (평문 SharedPreferences 금지)
- RS256 비대칭 키 + 로컬 public key cache
- access token 15분 + refresh 7일 single-use rotation
- OAuth 2.0 for Native Apps (RFC 8252) PKCE 강제

### 7.3 한국 개인정보보호법 (study §11 GDPR 패턴 그대로)

- `FORCE ROW LEVEL SECURITY` 한국법도 같은 효과
- 회원 가명 정보 분리 + 본명·전화·이메일 별도 암호화 컬럼
- 탈퇴 시 30일 soft delete → 영구 삭제 (PIPA 요구)

### 7.4 회귀 검증 (모든 마일스톤 종료 조건)

- `sanity_check.py` 13/13
- `usability_test.py` 14/14
- `member_sync_check.py` 10/10
- 신규 추가: `rls_isolation_test.py` (M3 이후 의무) · `multi_gym_test.py` (M4 이후 의무)

### 7.5 문서 동기화 (§0-B 이름 SSOT)

- 모든 마일스톤 종료 시 `ARCHITECTURE_BRIEF.md` §13 (API 카탈로그) 갱신
- `gym-management-saas.md` 갱신 사유 발생 시 §변경 이력 추가
- HANDOFF.md 갱신 (마일스톤 단위)

---

## 8. 아키텍처 진화도

```
[Phase 1 종료 — 2026-05-22]
SQLite WAL (단일 파일)
1 박스 (FACING SEONGSU) 데모
모든 데이터 = facing.db
인증 = 단순 JWT (gym_id 1개)
실시간 = SSE (in-process pub/sub)
결제·푸시·SMS = stub
배포 = 로컬 only
        ↓
[M1] 사용성 검증 — 구조 변경 없음
        ↓
[M2] 외부 통합 — webhook + adapter pattern 도입
        ↓
[M3] PostgreSQL + RLS — DB 격리 강제
        ↓
[M4] org_scopes 멀티 박스 — JWT schema 확장
        ↓
[M5] Railway/Vercel 배포 + Redis SSE backplane
        ↓
[Phase 2 종료 — 첫 5 박스 production]
PostgreSQL pool + RLS
5 박스 active · 박스 간 100% 격리
JWT org_scopes (멀티 박스 사용자 지원)
실시간 = SSE + Redis pub/sub fan-out
결제 = Toss live · 푸시 = FCM live · SMS = NHN · 메일 = Mailgun
배포 = Railway 백엔드 + Vercel PC 사장 + Play Store internal
```

---

## 9. Phase 3 예고 (참고용, Phase 2 종료 후 재합의)

study `gym-management-saas.md` §14.6 단계 3~5 에 해당:

- **단계 3 (100 박스)**: read replica · connection pool 튜닝 · 모니터링 stack 강화
- **단계 4 (1,000 박스 또는 enterprise 1곳)**: bridge (schema-per-gym) 검토 또는 region pinning (EU 진출 시)
- **단계 5 (10,000 박스)**: Citus distributed Postgres 또는 silo (compliance trigger 발생 시)

Phase 3 는 Phase 2 종료 후 실제 운영 지표 확인하고 합의해요.

---

## 10. 우선순위 의사결정 매트릭스

마일스톤 안 task 충돌 시 다음 우선순위:

1. **보안·격리** (RLS · OWASP A01) — 항상 최우선. 다른 모든 것 보류 가능
2. **사용성 검증 발견 block 결함** — 박스 활동 막는 결함
3. **외부 통합** (결제·푸시) — 실 박스 invite 전 필수
4. **멀티 박스 UI** — 첫 박스가 1개 박스만 운영하면 후순위 가능
5. **모니터링·문서** — 안정 운영 중 점진 강화

---

## 11. 종료 조건 (Phase 2 → Phase 3 transition)

다음 5 항목 모두 충족 시 Phase 2 종료:

- [ ] 5 박스 production active · 각 박스 30일+ 안정 운영
- [ ] uptime 99.5%+ (Railway log 기반)
- [ ] 결제·푸시·SMS·메일 4 채널 production 1건+ 통과
- [ ] cross-gym 데이터 누출 0건 (RLS·pgTAP 검증)
- [ ] 사장 NPS 50+ (5명 중 3명+ "추천 의향 있음")

---

## §변경 이력

- **2026-05-22**: 초안 작성. 5 마일스톤 · 30+ task · 아키텍처 진화도. 회의 직후 study + 브리프 종합.

---

## 12. 부록 — 의존 문서

- `docs/ARCHITECTURE_BRIEF.md` — 시스템 SSOT (D1~D24 결정사항)
- `docs/MEETING_BUILD_STATUS.md` — Phase 1 현황
- `docs/MEETING_DEMO_2026-05-22.md` — 회의 데모 흐름
- `docs/HANDOFF.md` — 세션 인계장 (반영 후 archive)
- `~/.claude/reference/study/gym-management-saas.md` — 멀티테넌시·RBAC·SSE·GDPR·Flutter 아키텍처 SSOT
- `~/.claude/reference/study/subscription-fitness.md` — 가격·marketplace·churn (Phase 3 단계 활용)
- `~/.claude/reference/study/ux-testing.md` — M1 사용성 테스트 방법론
- `~/.claude/reference/study/payment.md` — M2 Toss·Stripe·webhook 보안 (예정)
