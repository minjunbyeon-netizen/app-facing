# facing — 인프라 운영 가이드 (Phase 3 P1)

> **작성일**: 2026-05-23 (오버나이트)
> **목적**: Redis Sentinel·CDN·rate limit·monitoring 운영 가이드 SSOT.
> **연계**: `PHASE3_REVISION_v2.md` §5·§6 + `services/facing/scripts/postgres_rls_setup.sql` (H-1)

---

## 1. Redis Sentinel + 역할별 DB 분리 (N4-3)

### 1.1 역할별 DB number 분리

| 역할 | Redis DB # | fallback |
|---|---|---|
| SSE pub/sub backplane | `db=0` | 로컬 in-process queue |
| Celery broker (향후) | `db=1` | APScheduler 인프로세스 |
| Flask-Limiter rate limit | `db=2` | in-memory counter |
| 세션 store (옵션) | `db=3` | PostgreSQL session table |

### 1.2 환경변수 (Railway/production)

```bash
# 단일 Redis (개발)
RATELIMIT_STORAGE_URI=redis://default:<password>@<host>:6379/2
REDIS_SSE_URL=redis://default:<password>@<host>:6379/0
REDIS_CELERY_URL=redis://default:<password>@<host>:6379/1

# Sentinel (production, HA)
REDIS_SENTINELS=sentinel1:26379,sentinel2:26379,sentinel3:26379
REDIS_SENTINEL_NAME=facing-master
```

### 1.3 fallback 동작

- Redis 다운 → SSE: 같은 Flask worker 클라이언트만 수신 (degraded mode)
- Redis 다운 → rate limit: in-memory counter (single worker 한정 정확)
- Redis 다운 → 결제 같은 중요 작업: 동기 fallback (지연 허용)

---

## 2. CDN (N4-5)

### 2.1 Cloudflare Free Tier (초기)

- 비용: $0
- 도메인: facing.app + admin.facing.app
- DNS: Cloudflare 네임서버로 변경
- caching rules:
  - `/static/*` 1년 (immutable filename hash)
  - `/api/*` no-cache
  - HTML: stale-while-revalidate

### 2.2 Vercel CDN (PC 사장 웹 분리 시)

- web/facing-admin 별도 배포 → Vercel CDN 자동 활용
- 백엔드는 Railway 단독

---

## 3. Rate Limit Redis 전환 (N4-6)

현재 in-memory storage (단일 worker). worker 2+ 시점에 Redis 전환:

```bash
# .env 또는 Railway env
RATELIMIT_STORAGE_URI=redis://...

# 자동 적용 (app.py `_init_rate_limiter` 가 env 우선)
```

---

## 4. JSON 로그·Sentry·Grafana stack (N5)

### 4.1 Sentry (N5-1, 이미 도입)

- DSN: `SENTRY_DSN` env
- release tag: `GIT_COMMIT_SHA` env (CI/CD 가 주입)
- PII scrub 자동 (password·card·token·전화·생년월일·이메일)

### 4.2 Grafana Cloud (N5-2, 30박스 이후)

- 무료 tier: 10K metrics/월 + 50GB log
- Railway metrics → Grafana 통합
- 박스별 req/latency 대시보드

### 4.3 Synthetic monitoring (N5-6, 100박스 이후)

- Cron-job.org 또는 Pingdom 무료 tier
- 5분마다 `/api/v1/health` + 핵심 endpoint ping
- 실패 시 SMS alert

---

## 5. 배포 절차 (Railway)

### 5.1 백엔드 (services/facing)

```bash
# 1. Railway CLI 로그인
railway login

# 2. 프로젝트 link
railway link service-facing

# 3. 환경변수 (한 번만, Railway 콘솔 또는 CLI)
railway variables set ANTHROPIC_API_KEY=...
railway variables set SECRET_KEY=...
railway variables set TOSS_SECRET=...
railway variables set TOSS_WEBHOOK_SECRET=...
railway variables set NHN_TOAST_KEY=...
railway variables set MAILGUN_KEY=...
railway variables set FIREBASE_CREDENTIALS=/app/data/fcm-creds.json
railway variables set SENTRY_DSN=...
railway variables set DB_ENGINE=postgres  # H-1 cutover 후
railway variables set FLASK_ENV=production

# 4. 배포
railway up
```

### 5.2 PC 사장 웹 (web/facing-admin)

```bash
cd C:/dev/web/facing-admin
railway link web-facing-admin
railway variables set FACING_BACKEND_URL=https://facing.up.railway.app
railway variables set SECRET_KEY=...
railway up
```

---

## 6. 운영 체크리스트 (5박스 invite 직전)

- [ ] PostgreSQL+RLS 이행 완료 (`scripts/migrate_to_postgres.py`)
- [ ] Sentry DSN 등록 + 첫 error 캡처 확인
- [ ] Toss live key + webhook 등록
- [ ] NHN SMS sender ID 인증
- [ ] Mailgun DNS (SPF·DKIM·DMARC) 설정
- [ ] FCM 서비스 계정 JSON 등록
- [ ] Railway 백업 정책 활성 (PostgreSQL automated snapshot)
- [ ] `/api/v1/health/db` + `/health/external` 모든 ok
- [ ] CSRF·rate limit·security headers 동작 검증
- [ ] pgTAP cross-gym 차단 회귀 테스트 통과

---

## §변경 이력

- **2026-05-23**: N4-3/N4-5/N4-6 + N5 통합 운영 가이드. Redis Sentinel·CDN·rate limit·Sentry·Grafana·Synthetic stack 단계화.
