# N4·N5 — 확장 인프라 + 모니터링 재검토 (sub-agent C)

> **작성**: 2026-05-23 (sub-agent C / /go 파이프라인)
> **입력**: PHASE3_ROADMAP.md §6·§7 + gym-management-saas.md + legacy-migration.md + legacy-migration-checklist.md
> **목적**: N4·N5 task list 의 전제 검증 + 의사결정 기준 재정의

---

## 1. read replica 도입 trigger 재정의

### 결론

**100박스 시점에 read replica 는 조기 최적화일 가능성 높음. 도입 trigger 를 "박스 수" 가 아닌 "측정 지표" 로 재정의해야 한다.**

### 근거

| 지표 | 현황 (100박스) | 임계 |
|---|---|---|
| 동시 읽기 req/sec | ~200 req/sec 추정 (100박스 × 50회원 × 출석 4건/일 / 86400초) | PgBouncer transaction mode 는 500 req/sec 까지 single primary 로 가능 |
| DB 연결 수 | 100박스 × 3 gunicorn worker × 2 = 600 connections (PgBouncer pooling 시 primary 20개로 압축) | primary 100 connection 이 실 한계 → PgBouncer 로 해결 |
| RLS 오버헤드 | 복합 인덱스 `(gym_id, primary_key)` 있을 때 **+2~5%** (gym-management-saas §3.2) | 허용 범위. Citus 필요 없음 |
| read/write 비율 | 통계·리포트 쿼리 특성상 read 80%+ 예상 | replica 효과 있을 시점: read heavy + p95 >300ms 실측 시 |

### lag 5초 기준 재검토

- lag 5초 기준은 **실시간 SSE 이벤트 (출석·가입)** 에는 부적합 → 이 데이터는 primary 에서 읽어야 함
- lag 5초 가 허용되는 것: 통계 대시보드·리포트·leaderboard (15분 갱신 빈도)
- **수정된 기준**: 통계 쿼리 한정 replica, p95 latency >300ms 실측 후 도입

### 재정의된 도입 trigger

```
[즉시 도입 필요] 둘 중 하나 충족 시:
  A. primary p95 latency > 300ms (Grafana 실측)
  B. primary CPU 80%+ 지속 (Railway metrics)

[replica 도입 대신 먼저 시도]:
  1. PgBouncer transaction mode 적용 (N4-2 먼저)
  2. VOLATILE → STABLE RLS 함수 최적화
  3. 통계 쿼리에 materialized view + 15분 refresh
```

**결론**: N4-1 (read replica) 를 N4-2 (connection pool) 이후로 순서 변경. 100박스 진입 시 바로 도입이 아니라 "도입 검토 기준 설정 + PgBouncer 먼저" 로 task 수정.

---

## 2. Redis SPOF + fallback

### 결론

**Redis 가 SSE + Celery broker + rate limit + session store 4역을 동시 맡으면 SPOF 위험 확실. 역할 분리 + graceful degradation 이 필수.**

### Redis 역할별 SPOF 영향도

| 역할 | Redis 다운 시 영향 | fallback 전략 |
|---|---|---|
| SSE pub/sub 백플레인 | 다중 worker 간 fan-out 불가 → **SSE 이벤트 일부 누락** (같은 worker 에 연결된 클라이언트만 수신) | 단일 worker 모드 fallback (sticky session 임시 활성) |
| Celery broker | 모든 백그라운드 작업 중단 (SMS·이메일·cohort) | APScheduler 인프로세스 fallback pool (중요 작업만) |
| rate limit | 무제한 요청 가능 (보안 degraded) | 앱 레벨 in-memory counter fallback (단일 worker 한정) |
| session store | 로그인 세션 유실 → 모든 사용자 재로그인 | PostgreSQL session table fallback |

### 핵심 fallback 전략

```python
# SSE fan-out: Redis pub/sub 연결 실패 시
class SSEBackplane:
    def publish(self, channel, event):
        try:
            redis.publish(channel, event)
        except RedisConnectionError:
            # fallback: 로컬 in-process queue (같은 worker 클라이언트만)
            local_queue[channel].put(event)
            logger.warning("Redis down: SSE fan-out degraded (local-only)")

# Celery task: Redis 다운 시 중요 작업 동기 실행
@celery.task(max_retries=3)
def send_payment_sms(gym_id, member_id, amount):
    ...

# Redis 다운 감지 → 결제 SMS는 동기 fallback (지연 허용)
def trigger_payment_sms(gym_id, member_id, amount):
    try:
        send_payment_sms.delay(gym_id, member_id, amount)
    except Exception:
        send_payment_sms_sync(gym_id, member_id, amount)  # fallback
```

### 아키텍처 권고

1. **Redis Sentinel 또는 Railway Redis HA** 사용 (단일 노드 → 자동 failover)
2. **역할 분리**: SSE channel = `gym.events:*`, Celery broker = 별도 DB number (`SELECT 1`), rate limit = 별도 DB (`SELECT 2`)
3. **health endpoint 분리**: `/api/v1/health/redis` 가 SSE / Celery / ratelimit 각각 ping

---

## 3. Celery vs APScheduler 결정 트리

### 결론

**100박스 임계에서 APScheduler 인프로세스 유지 가능하나, 특정 조건 충족 시 Celery 이행. 조건 기반 결정 트리로 접근.**

### 현황 분석

| 항목 | APScheduler (현재) | Celery + Redis broker |
|---|---|---|
| 100박스 작업량 | cohort 1개/월 × 100 + SMS retry 3회/실패건 | 동일 |
| 추정 작업 수/일 | ~500 작업/일 (출석·결제·리포트) | 동일 |
| 단일 worker 처리 가능? | **YES** (500 작업/일 = 0.006 작업/초. APScheduler 충분) | 오버킬 |
| 핵심 한계 | worker 증설 시 같은 작업이 **N번 실행** (duplicate job) | N worker 에서 자연 분산 |
| 운영 복잡도 | 낮음 (인프로세스) | 높음 (Celery worker 별도 프로세스 + flower 모니터링 + Redis broker) |

### 결정 트리

```
[분기 1] worker 를 2개 이상 실행해야 하는가?
  └─ NO (단일 worker 로 100박스 커버 가능):
       APScheduler 유지. Celery 불필요.
  └─ YES (scaling 필요):
       [분기 2] Railway worker dyno 추가 vs Celery 도입?
         └─ 작업 실행 중복 허용 불가 (결제·SMS):
              Celery + Redis broker 도입 필수
         └─ 작업 중복 허용 (통계 갱신):
              DB 분산 lock (Postgres advisory lock) 으로 APScheduler 유지

[분기 3] 작업 실패 추적·재시도 가시성 필요한가?
  └─ YES (100박스 운영 시 SMS 실패 원인 추적 필수):
       Celery + Flower (UI) 권장 (APScheduler 는 실패 로그만)

[분기 4] 비용 수용 가능한가?
  └─ Railway Celery worker $20/월 추가:
       100박스 ($5,000/월 수익) 에서 허용 가능
```

### 권고 순서

1. **Phase 3 진입 시**: APScheduler 유지 + DB advisory lock 으로 중복 방지
2. **worker 2+ 필요 시점**: Celery 이행 (단계적 Strangler Fig — APScheduler → Celery 병행 후 cutover)
3. **중복 불허 작업** (결제 SMS): APScheduler 유지하더라도 Postgres advisory lock 즉시 적용

---

## 4. bridge schema 이행 시점·방법

### 결론

**bridge 이행 trigger 는 "1,000박스 도달" 이 아니라 "enterprise 격리 요구 1건 + 계약 LTV > $6,000/년" 이다. 박스 수보다 계약 품질이 우선.**

### gym-management-saas §2.3 재해석

원문 권고: "Bridge 는 100~1,000 tenant 구간"

하지만 facing 맥락에서:
- 100박스 = $5,000/월 = 년 $60,000 수익. 이 시점에 Bridge 전환 = 과잉 운영 부담
- **실제 trigger**: enterprise 고객 1곳 (박스 체인 또는 200+ 회원 박스) 이 명시적 격리 요구 + SLA 서명

### 이행 전략 (Strangler Fig 적용)

```
Phase 0 (현재): Pool + RLS (모든 박스 공유 schema)

Phase 1 (enterprise 1곳 계약 시): 
  → 해당 박스만 CREATE SCHEMA gym_{gym_id}
  → 기존 박스는 Pool schema 유지 (이원 운영)
  → Bridge 라우터: gym_id → schema 매핑 테이블

Phase 2 (enterprise 3~5곳):
  → 자동화 schema provisioning (onboarding script)
  → Pool 박스는 계속 Pool

Phase 3 (전체 Bridge로 전환 — 선택):
  → 기존 Pool 박스 → Bridge 마이그레이션 (Strangler Fig: dark launch → cutover)
  → 전체 전환 강제 X. Pool 박스는 Pool 유지 가능
```

### 비용 estimate

| 상태 | 스키마 수 | 마이그레이션 비용 | 운영 부담 |
|---|---|---|---|
| Pool 100박스 | 1 | 0 | 낮음 |
| Bridge 5 enterprise + Pool 95 | 6 | CREATE SCHEMA × 5 | 중간 |
| Full Bridge 100박스 | 100 | 100 × ETL | 높음 (마이그레이션 파이프라인 필요) |

**결론**: Full Bridge 강제 이전 불필요. enterprise 요구 건별 bridge 추가 (하이브리드) 가 최적.

---

## 5. Citus 임계 재검토 + Phase 매핑

### 결론

**facing 의 데이터 볼륨 추정 시 Citus 는 Phase 5 (10,000박스+) 에도 불필요할 수 있음. Read replica + connection pool 이 Phase 4 까지 커버.**

### 데이터 볼륨 추정

| 단계 | 박스 수 | 회원 수 | 월 출석 row | 월 결제 row | 월 누적 total row | 연간 누적 |
|---|---|---|---|---|---|---|
| Phase 2 | 5 | 250 | 12,500 | 250 | ~13K | ~156K |
| Phase 3 | 100 | 5,000 | 250,000 | 5,000 | ~255K | ~3M/년 |
| Phase 4 | 1,000 | 50,000 | 2,500,000 | 50,000 | ~2.55M | ~30M/년 |
| Phase 5 | 10,000 | 500,000 | 25,000,000 | 500,000 | ~25.5M | ~300M/년 |

### Citus 임계 (gym-management-saas §12.2) 대비

| 임계 | facing Phase 5 (10K박스) | 도달 여부 |
|---|---|---|
| > 1TB 분산 데이터 | 300M row × ~500 bytes = ~150GB | **X** (1TB 미달) |
| > 1,000 discrete tenants | 10,000박스 | ✓ tenant 수 충족 |
| > 1,000 req/sec | 10K박스 × 피크 = 가능 | 충족 가능 |
| > 10B rows | 300M/년 → 10B = 33년 후 | **X** |

### Phase 매핑 수정

| Phase | 단계 | DB 전략 | Citus |
|---|---|---|---|
| Phase 3 | 100박스 | Pool + RLS + PgBouncer | **X** |
| Phase 4 | 1,000박스 | + read replica + (enterprise → bridge) | **X** |
| Phase 5 | 10,000박스 | + shard key 검토 | **검토만** (1TB 미달 시 불필요) |

**결론**: PHASE3_ROADMAP.md §1 의 "단계 5 → Citus distributed" 표기를 "Citus 검토 (1TB 도달 시)" 로 수정 권고. 10,000박스 도달 전에 1TB 초과 측정이 선행 조건.

---

## 6. SQLite → PostgreSQL migration 전략 (Strangler Fig 적용)

### 결론

**5박스 운영 시점에 계획 다운타임(2~4시간) 협의 가능. Big Bang ETL이 Strangler Fig보다 현실적. 단, 롤백 계획 필수.**

### 전략 선택 근거

| 전략 | 적합성 | 이유 |
|---|---|---|
| **Strangler Fig (점진)** | △ | SQLite → PostgreSQL 은 스키마·API 동시 변경 필요. façade 가 두 DB 동시 지원하려면 코드 복잡도 폭발 |
| **Big Bang ETL (계획 다운타임)** | ✓ 권장 | 5박스 = 사전 협의 가능. 2~4시간 새벽 창 확보 현실적 |
| **Branch by Abstraction** | ✓ 선행으로 | DB 레이어 추상화 먼저 → ETL 시 스위치 1줄 교체 |

### 권장 절차 (Branch by Abstraction + 단계적 ETL)

```
Step 1: Branch by Abstraction (코드 레벨, 다운타임 0)
  → DatabaseAdapter 인터페이스 추가
  → SQLite 구현: SqliteAdapter
  → PostgreSQL 구현: PostgresAdapter (병행 개발)
  → 환경변수 DB_ENGINE=sqlite / postgres 로 전환

Step 2: PostgreSQL 인스턴스 준비 (다운타임 0)
  → Railway PostgreSQL 프로비저닝
  → RLS 정책·복합 인덱스 적용
  → 빈 스키마 검증

Step 3: 계획 다운타임 (새벽 2~6시, 5박스 사전 통보)
  → 서비스 점검 모드 (HTTP 503 + 안내)
  → SQLite dump → PostgreSQL load (ETL)
  → 데이터 검증 (row count + 샘플 검증)
  → DB_ENGINE=postgres 로 스위치
  → 서비스 재기동

Step 4: 롤백 준비 (항상)
  → 점검 창 동안 SQLite 파일 백업 유지
  → PostgreSQL 실패 시 5분 내 SQLite 복귀
  → 복귀 후 원인 분석 → 재시도
```

### 5박스 다운타임 협의 가능 이유

- legacy-migration §3.4: Big Bang 이 합리적인 경우 — "작은 시스템 + 1~2주 rewrite 가 더 싼 경우"
- 5박스 = 소규모 운영자 커뮤니티. Slack/카카오 공지로 새벽 창 협의 현실적
- 데이터 양: 5박스 × 250회원 × 출석 = ~15만 row. ETL 30분 이내

---

## 7. region pinning trigger (한국·EU)

### 결론

**한국 사장만 받는 동안 region pinning 불필요. EU 박스 1곳 계약 시 즉시 Art. 44 trigger. 미리 코드 분기만 준비.**

### 법적 분석

| 시나리오 | 법 적용 | 의무 |
|---|---|---|
| 한국 박스만 (한국 서버) | 한국 개인정보보호법 (PIPA) | 동의·파기·열람권 → RLS+FORCE 로 대부분 충족 |
| 한국 박스 (Railway US 서버) | PIPA + 국외 이전 고지 | 회원 가입 시 "서버 미국 소재" 동의 → PIPA §17조 |
| EU 박스 1곳이라도 | GDPR Art. 44 trigger | EU 개인정보 → EU/EEA 서버 또는 DPF-certified US 로만 |

### Railway 인프라 GDPR 대응

- Railway EU region (Frankfurt `eu-west`) 사용 시 → Art. 45 adequacy 충족
- Railway 는 DPF-certified → US 서버도 일단 합법. 단 2025-09 항소 진행 중

### 코드 준비 (다운타임 없이 분기 추가)

```python
# 지금 당장 추가 (비용 0)
class GymRegion(enum.Enum):
    KR = "kr"
    EU = "eu"

# gyms 테이블에 region 컬럼 추가 (기본 'kr')
# ALTER TABLE gyms ADD COLUMN region VARCHAR(5) DEFAULT 'kr';

# 나중에 EU 박스 계약 시 → Railway EU region DB 연결 분기
def get_db_url(gym_id: str) -> str:
    gym = Gym.query.get(gym_id)
    if gym.region == GymRegion.EU:
        return os.getenv("DATABASE_URL_EU")  # Railway EU Postgres
    return os.getenv("DATABASE_URL")  # Railway US Postgres (기본)
```

### 결론

N4 task list 에 "region 컬럼 추가 + 분기 skeleton" 을 **즉시 추가** (코드 변경 최소, EU 진출 대응 사전 준비). 실제 EU DB 프로비저닝은 EU 박스 계약 시로 defer.

---

## 8. 모니터링 stack 우선순위

### 결론

**Sentry 먼저, Railway log 는 무료 활용, Grafana 는 50박스+ 이후. 셋 동시 도입 필요 없음.**

### 비용·가치 분석

| 도구 | 월 비용 | 100박스 필수? | 핵심 가치 |
|---|---|---|---|
| **Sentry** | $26/월 (Team plan) | ✓ **즉시** | Python Exception 자동 캡처 + release tag + PII scrub + Slack alert |
| **Railway 빌트인 log** | $0 (포함) | ✓ 지금도 가능 | 구조화 JSON log → Railway log panel 필터 |
| **Grafana** | $0 (OSS self-host) 또는 $19/월 (Cloud) | 50박스+ | 박스별 req/latency 대시보드. 100박스 전까진 Railway metrics 로 충분 |
| **PagerDuty** | $21/월/user | Phase 4 | on-call rotation. 1인 운영 시 불필요 |

### 우선순위 순서

```
Priority 1 (지금, Phase 2 종료 전):
  → Sentry SDK (Flask + JS) 설치
  → release tag (git hash) + PII scrub 설정
  → 일일 error digest → 운영자 이메일

Priority 2 (5박스 → 30박스):
  → 구조화 JSON 로그 (request_id · gym_id · user_id 자동 tag)
  → Railway log panel 에서 gym_id 기반 필터 활용

Priority 3 (30박스 → 100박스):
  → Grafana Cloud (무료 tier: 10K metrics/월) 또는 Railway metrics
  → 박스별 request 수 · latency · error rate 대시보드

Priority 4 (100박스+):
  → synthetic monitoring (5분마다 핵심 endpoint ping)
  → SLA dashboard (박스별 uptime 99.9%)
  → on-call runbook 문서화
```

### 비용 최적화

| 박스 수 | 모니터링 비용 | 선택 |
|---|---|---|
| 5~30박스 | $26/월 (Sentry만) | Sentry + Railway 빌트인 |
| 30~100박스 | $45/월 (Sentry + Grafana Cloud) | 위 + Grafana 무료 tier |
| 100박스+ | $80~100/월 | 위 + synthetic + 구조화 log 강화 |

---

## 9. boot 안정성 production 이행 시

### 결론

**production gunicorn 이행 시 좀비 포트 문제 자동 해결. 단, gunicorn worker 설정 주의사항 있음.**

### 원인 분석

| 환경 | 포트 중복 LISTEN 원인 | 해결 여부 |
|---|---|---|
| Windows + Werkzeug debug mode | `use_reloader=True` → 부모 + 자식 프로세스 둘 다 포트 bind. Ctrl+C 후 잔존 | **Windows 한정 문제** |
| production gunicorn (Linux) | master 1개가 fork → worker N개 (모두 같은 fd 상속). TCP listen fd 1개 공유 → 중복 X | **자동 해결** |

### gunicorn 설정 주의사항

```python
# gunicorn.conf.py (주의사항 포함)
workers = 2 * multiprocessing.cpu_count() + 1  # Railway 2 vCPU → 5 workers
worker_class = "gevent"  # SSE 장시간 연결 → gevent 필수

# APScheduler 인프로세스 사용 시 중복 실행 주의
# → preload_app = False (기본값) 로 유지하면 master fork 후 각 worker 에서 scheduler init
# → preload_app = True 로 하면 master 에서만 init → fork 시 공유 → 문제 없음

preload_app = True  # APScheduler 중복 실행 방지
```

### dev_boot.ps1 대체 방안

```powershell
# dev_boot.ps1 에서 Werkzeug debug 모드 안전하게 실행
# use_reloader=False 로 좀비 방지
$env:FLASK_DEBUG = "0"
python -m flask run --no-reload --port 5060
```

### 결론

- production gunicorn 이행 후 좀비 포트 문제 없음
- `preload_app = True` + APScheduler `max_instances=1` 설정으로 scheduler 중복 방지
- dev 환경: `use_reloader=False` 또는 `flask run --no-reload` 로 Windows 좀비 회피

---

## 10. 수정된 N4·N5 task list + 의존 그래프

### N4 수정 task list

| ID | 원래 task | 수정 내용 | 우선순위 | 의존 |
|---|---|---|---|---|
| N4-0 | (신규) region 컬럼 + skeleton | `gyms.region` 컬럼 추가 + DB URL 분기 skeleton | P0 (즉시) | 없음 |
| N4-1 | read replica | **"도입 기준 설정"으로 변경**: PgBouncer 도입 후 p95 >300ms 실측 시 진행 | P2 (30박스 후) | N4-2 |
| N4-2 | connection pool (PgBouncer) | **P0으로 승격**: `SET LOCAL` 강제 + VOLATILE→STABLE 최적화 포함 | P0 (5박스) | 없음 |
| N4-3 | Redis pub/sub + SSE | SSE 백플레인 + fallback (local queue) + Redis Sentinel | P1 (30박스) | N4-2 |
| N4-4 | APScheduler → Celery | **조건부**: worker 2+ 필요 시점에만. 100박스는 APScheduler + advisory lock | P2 (조건부) | N4-3 |
| N4-5 | CDN · static asset | Cloudflare free tier 먼저 (비용 0) | P1 | 없음 |
| N4-6 | rate limit | Flask-Limiter + Redis (N4-3 의존) | P1 | N4-3 |

### N5 수정 task list

| ID | 원래 task | 수정 내용 | 우선순위 | 의존 |
|---|---|---|---|---|
| N5-1 | Sentry SDK | **즉시 도입 (Phase 2 종료 전)**: PII scrub + release tag | P0 (지금) | 없음 |
| N5-2 | Grafana dashboard | **30박스 이후로 defer**: 그 전까지 Railway 빌트인 metrics | P2 | N4-3 |
| N5-3 | JSON 구조화 로그 | **P1 (5~30박스)**: request_id + gym_id + user_id | P1 | N5-1 |
| N5-4 | health check 확장 | /health/db + /health/redis + /health/external | P1 | N4-3 |
| N5-5 | incident response runbook | 30박스 이후 실제 사고 경험 기반 작성 | P2 | N5-2 |
| N5-6 | synthetic monitoring | 100박스 이후 (비용 $20/월, 그 전 Railway uptime check로 대체) | P3 | N5-2 |

### 의존 그래프

```
즉시 (Phase 2 종료 전):
  N5-1 (Sentry)
  N4-0 (region skeleton)
  N4-2 (PgBouncer + SET LOCAL)

5박스 → 30박스:
  N5-3 (JSON log) → depends on N5-1
  N4-5 (CDN)
  N5-4 (health check)

30박스 → 100박스:
  N4-3 (Redis + SSE fallback)
  N4-6 (rate limit) → depends on N4-3
  N5-2 (Grafana) → depends on N4-3

100박스 임계 (측정 기반):
  N4-1 (read replica) → IF p95 >300ms 실측 시
  N4-4 (Celery) → IF worker 2+ 필요 시
  N5-5 (runbook)
  N5-6 (synthetic)
```

### Phase 3 ROADMAP §6·§7 수정 권고 요약

| 섹션 | 수정 전 | 수정 후 |
|---|---|---|
| §6.2 N4-1 lag 기준 | lag < 5초 | 통계쿼리 한정 허용. 실시간 이벤트는 primary 필수 |
| §6.2 N4-1 도입 시점 | 100박스 진입 시 | p95 >300ms 실측 후 (N4-2 이후) |
| §6.2 N4-4 | APScheduler → Celery (무조건) | worker 2+ 필요 시점에만 (100박스는 APScheduler 가능) |
| §6.3 아키텍처 | Redis 4역 단일 노드 | Redis Sentinel + 역할별 DB number 분리 |
| §7.1 N5-1 | 구현 순서 명시 없음 | **즉시 도입 (Phase 2 종료 전)** 으로 P0 승격 |
| §7.1 N5-2 | Grafana (시점 불명) | 30박스 이후로 defer |
| §1 단계 5 | Citus distributed | Citus 검토 (1TB 도달 측정 시) |
| (신규) | — | N4-0: region 컬럼 + skeleton (즉시, 비용 0) |

---

## 판단 기록

| 판단 | 선택 | 이유 | 반대 시 수정 범위 |
|---|---|---|---|
| 100박스 read replica 즉시 도입 | 기각 → 측정 기반 도입 | PgBouncer + materialized view 로 선 대응 가능. 조기 최적화 비용 낭비 | N4-1 task 원복 + N4-2 의존 제거 |
| Celery 무조건 이행 | 기각 → 조건부 | 100박스 작업량 0.006 작업/초. APScheduler 충분. Celery 운영 복잡도 불필요 | N4-4 P2→P1 승격 + Redis broker 즉시 설정 |
| Big Bang ETL (SQLite → PG) | 채택 | 5박스 협의 가능 + Strangler Fig 보다 코드 단순 | Strangler Fig 로 전환 시 Branch by Abstraction 레이어 설계 2~3주 추가 |
| Grafana defer (30박스) | 채택 | Railway 빌트인 metrics 로 30박스까지 충분. Sentry 우선 | 30박스 이전 가시성 필요 시 Grafana Cloud free tier 즉시 도입 |

---

*생성: 2026-05-23 / sub-agent C (/go pipeline) / git push 미실행*
