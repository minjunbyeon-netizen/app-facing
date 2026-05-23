# facing — Incident Response Runbook (N5-5)

> **작성일**: 2026-05-23 (오버나이트)
> **대상**: 박스 30곳 이후 시점에 on-call 1인 운영 가정.
> **연계**: `INFRA_GUIDE.md` (Sentry·Grafana stack) + `docs/test/2026-05-23-0136/report.md` (좀비 포트 lesson)

---

## 1. Severity 정의

| 등급 | 정의 | 대응 시간 | 예시 |
|---|---|---|---|
| **SEV-1** | 전 박스 운영 중단 | 15분 안 응답·1시간 안 복구 | DB 다운·결제 webhook 전체 실패·인증 시스템 down |
| **SEV-2** | 일부 박스·기능 마비 | 1시간 안 응답·4시간 안 복구 | 박스 1곳 데이터 누출 의심·SMS 전체 실패·체크인 안 됨 |
| **SEV-3** | 단일 사용자·작은 기능 | 영업일 1일 안 | UI 깨짐·1 회원 결제 오류·통계 숫자 불일치 |
| **SEV-4** | UX·문구·미관 | 백로그 | 폰트 ·번역 오타·padding 깨짐 |

---

## 2. SEV-1 대응 — DB 다운

### 2.1 즉시 (5분 안)

```bash
# 1. health check 다 깨졌는지 확인
curl -sS https://facing.up.railway.app/api/v1/health/db
curl -sS https://facing.up.railway.app/api/v1/health

# 2. Railway dashboard — PostgreSQL 상태 확인
railway status

# 3. Sentry 에러 burst 확인
# https://sentry.io/organizations/facing/issues/?statsPeriod=15m
```

### 2.2 분류 (15분 안)

- DB connection pool 고갈 → `max_connections` 증가 또는 PgBouncer restart
- DB 디스크 풀 → 백업 정리 + 디스크 증설
- Railway 자체 장애 → Railway status page 확인 + 사용자 공지
- migration 도중 lock → 진행 중인 migration 중단 결정

### 2.3 복구 (1시간 안)

```bash
# A. Connection pool 고갈
railway service restart facing-backend
# 또는 PgBouncer 단독 restart

# B. Railway 자체 장애 — fallback SQLite read-only 모드 검토
# 임시 환경변수: DB_ENGINE=sqlite + 최근 백업 복원
export DB_ENGINE=sqlite
export FACING_DB_PATH=/app/data/backup/facing-{YYYYMMDD}.db
railway up

# C. DB drop·corruption — 최신 백업 복원
pg_restore -h <pg_host> -U <user> -d facing /path/to/backup.dump
```

---

## 3. SEV-1 대응 — 결제 webhook 전체 실패

### 3.1 즉시

```bash
# Toss 콘솔에서 webhook 상태 확인
# https://api.tosspayments.com/dashboard

# 백엔드 webhook endpoint health
curl -sS https://facing.up.railway.app/api/v1/health/external
```

### 3.2 분류

- HMAC 검증 실패 burst → TOSS_WEBHOOK_SECRET 변경 또는 만료
- Toss 측 timeout → Toss 콘솔 retry 활성
- 우리 측 500 error → Sentry 검토

### 3.3 복구

```bash
# A. TOSS_WEBHOOK_SECRET 갱신
railway variables set TOSS_WEBHOOK_SECRET=<new>
railway up

# B. 누락된 결제 manual reconciliation
python scripts/manual_reconciliation.py --date 2026-05-23  # 미구현 stub
```

---

## 4. SEV-2 대응 — 박스 1곳 데이터 누출 의심

### 4.1 즉시 (1시간 안)

1. 해당 박스 사장 즉시 연락 (개인정보보호법 §34 — 5일 안 통지 의무)
2. audit_log 검토 — 비정상 접근 패턴 (cross-gym query·대량 export)
3. 임시 해당 박스 로그인 비활성
4. RLS 정책 검증 (`SET LOCAL app.current_gym_id` 누락 endpoint 있나)

### 4.2 분류·복구

```sql
-- audit_log 에서 의심 패턴 검색
SELECT * FROM audit_log
WHERE gym_id != current_setting('app.current_gym_id')::int
  AND created_at >= NOW() - INTERVAL '7 days'
ORDER BY created_at DESC LIMIT 100;

-- pgTAP 회귀 테스트 즉시 실행
psql $DATABASE_URL -f scripts/test_rls_isolation.sql
```

PIPA §34 — 1,000명 이상 영향 시 개인정보보호위원회 신고 의무 (72시간 안).

---

## 5. SEV-2 대응 — 좀비 서버 다중 LISTEN (개발 환경)

study `report.md` C1 발견 — 포트 5060 PID 4개 동시 LISTEN 사고.

```powershell
# scripts/dev_boot.ps1 활용 — 좀비 정리 + 새 서버
.\scripts\dev_boot.ps1 -Port 5060
```

production gunicorn `preload_app=True` 면 자동 해결 (INFRA_GUIDE §6).

---

## 6. SEV-3·4 — 백로그 처리

- Sentry issue triage 주 1회 (월요일)
- 사용자 보고는 Linear 또는 GitHub issue
- 영업일 1일 안 응답·1주 안 fix

---

## 7. on-call rotation (Phase 3 후반)

Phase 3 100박스 이후 1인 → 2~3인 rotation:

| 시간대 | 담당 | 대응 의무 |
|---|---|---|
| 평일 09:00~18:00 | 풀타임 (CEO) | SEV-1·2 즉시 |
| 평일 18:00~09:00 | on-call A | SEV-1 만 (SEV-2 영업일 익일) |
| 주말 | on-call B | SEV-1 만 |

연락 채널: SMS·Slack·전화 (Sentry alert → PagerDuty 연동, Phase 4)

---

## 8. post-mortem 템플릿

SEV-1·2 사고 후 48시간 안 작성:

- 발생 시각 + 발견 시각 (MTTD)
- 영향 (박스·회원·금액)
- 근본 원인 (5 Whys)
- 시간순 타임라인
- 임시 fix vs 영구 fix
- 재발 방지 (코드·문서·룰 변경)

---

## §변경 이력

- **2026-05-23**: 신규 작성. SEV 4단계 + DB 다운·결제 실패·데이터 누출·좀비 LISTEN 4 시나리오 + on-call rotation + post-mortem 템플릿.
