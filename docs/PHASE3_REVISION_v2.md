# facing — Phase 3 아키텍처 수정안 v2 (study 기반 종합)

> **작성일**: 2026-05-23 (오버나이트 /go 파이프라인 종합)
> **선행**: `PHASE3_ROADMAP.md` v1 (2026-05-23 오전 초안)
> **input**: 4 sub-agent artifact (`docs/test/phase3-review/{N1·N2·N4-N5·N3-N6}*.md`) — Sonnet 4명 병렬 검증
> **목적**: v1 의 task list 를 study 자료 (fitness·subscription-fitness·pricing·labor-office·gym-management-saas·ux-testing·cardnews-quality·legacy-migration) 기반 정밀 검증 → 수정·추가·제거
> **변경량**: N1 6 task 재정의 + N2 신규 5 task · N3 4 task 변경 + N4 task 우선순위 재배치 + N5 P0 즉시 도입 항목 분리 + N6 그룹 세션 모델 도입

---

## 0. 한 줄 결론

> **PHASE3_ROADMAP v1 의 task 70% 는 유효, 30% 는 재설계 필요. 가장 큰 변화 4가지 — ① CrossFit schema 3→6 테이블, ② 정기결제 기본값 강제 + 연간 "2개월 무료" framing, ③ read replica 측정 기반 도입 (조기 X), ④ 그룹 Zoom onboarding (개별 세션 폐지).**

---

## 1. 4 영역 핵심 변경점 요약

| 영역 | v1 핵심 | v2 변경점 | study 근거 |
|---|---|---|---|
| **N1 CrossFit 도메인** | 3 테이블·200 동작·HQ API 자동 detection·30 benchmark | 6 테이블·60 동작·HQ API 제거(수동)·Korea/Custom 카테고리 추가·RX·Scaled 분리 leaderboard | fitness/* + Wodify 사례 |
| **N2 비즈니스 모델** | 자동결제·PT·cohort·할인·marketing dashboard 6 task | 정기결제 **기본값 강제**·3-tier anchor+decoy 가격·21일 trial·cancel flow 3단계·코치 갑근세 2.97% 자동화·이탈 위험 5점 scoring + 5 신규 task | subscription-fitness §4·§7·pricing §2·§10·labor-office §3 |
| **N3 i18n** | EN/KO 토글·영문 계약서·세금계산서 영문화 | EN only·영문 Receipt (세금계산서 영문화 불가)·법무 자문 30박스 시점·날짜 locale 환산 금지 | seo-geo·cardnews-quality·한국 PIPA/부가세법 |
| **N4 확장 인프라** | read replica·Redis pub/sub·Celery·CDN | read replica 측정 기반 (p95>300ms 도입)·PgBouncer 먼저·Redis Sentinel + fallback·Celery 조건부·region 컬럼 즉시 추가·Citus 검토만 | gym-management-saas §3·§9·§12·legacy-migration |
| **N5 모니터링** | Sentry·Grafana·log·health check 등 6 task | Sentry **즉시 P0**·Grafana 30박스 후·JSON log 5박스 이후·synthetic 100박스 이후 비용 단계화 | gym-management-saas 운영 패턴 |
| **N6 onboarding** | 박스마다 30분 세션·PDF 50~100p·매니저 교육 | 셀프 setup wizard·그룹 Zoom 5~10박스·PDF 8p+40p 분리·RBAC4 매니저 역할 신규·RITE 5박스 파일럿 | ux-testing §3·§6·cardnews-quality §2 |

---

## 2. N1 — CrossFit 도메인 깊이 (수정안)

### 2.1 schema 6 테이블 (3 → 6 확장)

study `fitness/power.md` §A4 Wilks/DOTS · `fitness/olympic-lifting.md` §4 BW ratio · `fitness/gymnastics.md` §3 progression tree 근거.

| 테이블 | 역할 | 핵심 컬럼 |
|---|---|---|
| `movement_library` | 동작 마스터 | `name_en` · `category` · `subcategory` · `prerequisite_ids[]` · `scaling_options` JSONB · `score_axes[]` · `is_benchmark_eligible` |
| `benchmark_wod` | Girls·Heroes·Open·Korea·Custom 워크아웃 | `slug` · `category` ('girls/heroes/open/korea/custom') · `movements` JSONB · `scoring_type` · `rx_standard` · `scaled_standard` |
| `wod_session` | 박스 일일 WOD | `gym_id` · `date` · `wod_type` · `description` · `posted_by` |
| `wod_score` | 회원 세션 점수 | + **`scale_type`** (rx·scaled·rx_plus) · **`scale_factor`** · `score_unit` enum · `is_pr` |
| `benchmark_score` | 회원 벤치마크 기록 | + `percentile` (박스 내) · `scale_type` |
| `member_pr` | 동작별 PR | + **`bodyweight_kg`** · **`bw_ratio`** · **`dots_score`** (powerlifting 3대 한정) · `time_sec` |

### 2.2 동작 라이브러리 60개 (200개 → 축소)

- Gymnastics 20개 (Pull-up·Push-up·Dip·HSPU·Muscle-up·Pistol·T2B·L-sit·Rope climb·...)
- Weightlifting 15개 (Snatch·Clean·Jerk·C&J·Power Clean·Hang Clean·Front Squat·Back Squat·OHS·Press·Push Press·Push Jerk·Deadlift·...)
- Cardio 10개 (Row·Bike·Run·Burpee·Box Jump·Double Under·Single Under·Jump Rope·Ski Erg·Air Squat)
- Power 15개 (Wall Ball·KB Swing·DB Snatch·DB Clean·DB Press·Thruster·Wallball·Bench Press·...)

비디오 자체 호스팅 **제거** → 외부 YouTube/SugarWOD 링크 필드만 (라이센스·스토리지 절감).

### 2.3 RX/Scaled leaderboard 분리

- 같은 스케일 내에서만 비교 (RX leaderboard, Scaled leaderboard 분리 표시)
- 혼합 정규화는 Phase 4 검토
- AMRAP: `rounds × movements_per_round + partial_reps` 통일 계산식

### 2.4 한국 Custom benchmark 카테고리

- 박스 자체 benchmark 정의 가능 (예: "한강 5km 런 + Murph 절반")
- `benchmark_wod.category = 'custom'` 분류
- 한국 CrossFit Korea Open 순위 — 수동 입력 (HQ API 미확인 → Phase 4 재검토)

### 2.5 task 재정의

| ID | 변경 | 우선순위 |
|---|---|---|
| **N1-0** (신설) | movement_library 마스터 (60 동작 + 한국어 라벨) | P0 |
| **N1-1** (수정) | WOD schema + scale_type/scale_factor 추가 | P0 |
| **N1-2** (수정) | PR 트래킹 + BW ratio + DOTS (3대 한정) | P0 |
| **N1-3** (수정) | Benchmark WOD 테이블 분리 + Korea/Custom 카테고리 | P0 |
| **N1-4** (수정) | Open 시즌 — HQ API 제거, 수동 입력 + 박스 ranking | P1 |
| **N1-5** (수정) | 동작 라이브러리 200→60, 비디오 외부 링크만 | P1 |
| **N1-6** (신설) | leaderboard 알고리즘 명세 (RX/Scaled 분리) | P1 |
| (Phase 4 defer) | DOTS 글로벌 leaderboard · HYROX 포맷 · KWA/KSPO 연계 | P2 |

---

## 3. N2 — 비즈니스 모델 (수정안)

### 3.1 가격·구독 정책 — 3-tier anchor+decoy

`pricing.md §2 Anchoring` + `§10.2 Annual vs Monthly` + `subscription-fitness §7.2` 적용.

| 플랜 | 가격 (₩) | 포지셔닝 |
|---|---|---|
| 월간 | 100,000/월 | 최저 anchor |
| 6개월 | 529,000 (월환산 88,167) | **mid-tier decoy** |
| 연간 | 899,000 (월환산 74,917) | **목표 — "2개월 무료" concrete framing** |

- 가격표 노출 순서: 연간(최고 anchor) → 6개월 → 월간
- "20% 할인" 대신 "2개월 무료" framing (+45% revenue, pricing §7.1)
- charm pricing 회피 — round 가격 ₩100,000 (B2B 신뢰감, Wadhwa-Zhang JCR 2015)

### 3.2 정기결제 기본값 강제

- Toss 빌링키 자동결제 = **기본값**
- 계좌이체 = 허용하되 +10% 수수료
- 현금 = 비활성 권고 (invoicing 만)
- 자동결제 전환 시 1개월 감면 인센티브
- 근거: pricing §5 pain of paying + subscription-fitness §4 involuntary churn 15~28% 차단

### 3.3 21일 trial + 3단계 cancel flow

- 신규 가입 21일 무료 trial (subscription-fitness §7.1 17~32일 sweet spot)
- 해지 클릭 → save offer (1개월 50% 할인) → downgrade → 탈퇴 확인
- 재가입 링크 자동 메일 30일 후
- 근거: 15~30% 해지 위험 계정 회수 (Rework.com)

### 3.4 retention 5단 개입 스택

| 개입 | 메커니즘 | 효과 | 구현 |
|---|---|---|---|
| **full onboarding flow** | 습관 + competence (SDT) | 6mo retention 60%→87% (+45%) | 가입 후 7일: WOD·PR 입력 유도 |
| **코치 2회/월 연락** | relatedness + social support | -33% cancellation | 14일 미체크인 감지 → 코치 SMS |
| **group class 등록** | conjunctive Köhler + cohesion | -56% cancellation | WOD 참가 없는 회원 → 그룹 초대 |
| **다중 discipline 확장** | 다양성 → engagement | -60% churn (Peloton) | WOD + benchmark + Open 유도 |
| **commitment contract** | Royer incentive + commitment | 1년+ 지속 | 6개월 선납 + 출석 목표 명시 |

### 3.5 이탈 위험 5점 scoring 알고리즘

```python
RISK_SIGNALS = {
    "no_checkin_14d": 0.4,
    "no_wod_score_30d": 0.3,
    "payment_failed_once": 0.2,
    "single_discipline": 0.1,
}
# 합산 > 0.5 → 코치 SMS 자동
# 합산 > 0.8 → 박스 사장 alert + save offer
```

### 3.6 코치 일용직 정산 자동화 (한국법 의무)

`labor-office.md` §3 갑근세 + §4 4대보험 적용.

| 항목 | 산식 | 법적 근거 |
|---|---|---|
| 갑근세 (일용직) | (일급 - ₩150,000) × 2.97% | 소득세법 §70의2 |
| 소액부징수 | 일급 ≤ ₩187,037 → 세금 0 | labor-office §3.5 |
| 4대보험 | 산재·고용 1일 이상 의무. 국민·건강 = 월 8일/60h 이상 | 4insure.or.kr |
| 3개월 경과 알림 | 일용직 → 일반근로자 자동 전환 대상 | labor-office §2.1 |
| 두루누리 80% 지원 | 10인 미만 박스 + 월보수 ₩270만 미만 | 고용노동부 |
| 정산 주기 | 매월 1회 이정한 날짜 의무 | 근로기준법 §43 |

### 3.7 여성 그룹 클래스 tier (간접 WTP 포착)

- 성별 직접 가격 차별 **금지** (남녀고용평등법·소비자기본법)
- 대신: 그룹 클래스 별도 tier · 커플/패밀리 패키지 · 여성 전용 WOD 리더보드
- 근거: subscription-fitness §5 여성 boutique 77% · group 동기 57%

### 3.8 ClassPass 마켓플레이스 연동 — 금지

- subscription-fitness §3.5 안티: ClassPass 신규 회원 유치 **near-zero conversion**
- 박스 의존도 20~90% 위험. 진입 후 이탈 시 매출 충격
- 결론: 박스 내 PT 예약 + 코치 캘린더만 우리 SaaS 안에 완결

### 3.9 정밀 LTV·CAC 모델

| 플랜 | ARPU | 월 churn | 평균 수명 | LTV |
|---|---|---|---|---|
| 월간 | ₩100,000 | 7% | 14.3개월 | ₩1,430,000 |
| 연간 | ₩90,000 | 3.5% | 28.6개월 | ₩2,574,000 (+80%) |

- CAC 목표: 직접 영업 ₩50~100K/박스, 추천 ₩100K
- LTV:CAC > 3:1 → CAC 한도 ₩430,000~858,000
- grandfathering 의무: Phase 3→4 가격 인상 시 6~12개월 기존 가격 유지

### 3.10 task 재정의 (N2)

| ID | 변경 | 우선순위 (MoSCoW) |
|---|---|---|
| **N2-1** | 자동결제 — Toss 기본값 강제 + 계좌이체 +10% | **Must** |
| **N2-2** | PT 예약 — 마켓플레이스 연동 보류 + 취소 정책 3단계 | Should |
| **N2-3** | retention cohort + 5단 개입 스택 | Should |
| **N2-4** | 마케팅 dashboard + NPS→LTV 상관 모델 | Should |
| **N2-5** | 할인·쿠폰 — 비수기 10% + 성수기 인상 금지 | Should |
| **N2-6** | 회원 등급·loyalty — SDT identified regulation 경로 | Could |
| **N2-7** (신설) | 3-tier 가격 설계 (anchor + decoy + concrete framing) | **Must** |
| **N2-8** (신설) | 21일 trial + 3단계 cancel flow | **Must** |
| **N2-9** (신설) | 코치 일용직 정산 자동화 (갑근세 2.97% + 두루누리) | **Must** |
| **N2-10** (신설) | 이탈 위험 5점 scoring + 자동 개입 | Should |
| **N2-11** (신설) | 여성 그룹 클래스 tier (간접 WTP 포착) | Could |
| (Won't) | ClassPass 마켓플레이스 연동 | **Won't** |

---

## 4. N3 — i18n (수정안)

### 4.1 EN only (JA·ZH 보류)

- Phase 3: EN만 추가. p6 블로커 해소
- JA·ZH: Phase 4 트리거 — 일본인/중국인 박스 5곳+ 문의 시
- locale 파일 구조 확립 — 추후 JSON 1개 추가로 확장 가능

### 4.2 영문 Receipt (세금계산서 영문화 X)

| 버전 | 용도 | 내용 |
|---|---|---|
| **한글 세금계산서** | 사장 세무사·국세청 신고 | 법정 양식 (부가가치세법 §53 강행규정) |
| **영문 Receipt** | 외국인 회원 경비 처리 | 별도 양식 — 세금계산서 아님. VAT·품목 영문 표기 |

- N3-4 task 명칭 "영문 영수증 (Receipt) PDF 생성" 으로 변경
- 세금계산서 영문화 시도 불가 (법 위반 리스크)

### 4.3 영문 계약서 + 법무 면책 + 30박스 시점 자문

```
"This document is an English translation for reference only.
In the event of any discrepancy between the Korean and English versions,
the Korean version shall prevail."
```

- 단계 1 (N3): 영문 번역 + 면책 문구
- 단계 2 (N6-3 / 30박스 전): 변호사 자문 1회 50~100만원, 표준 EN 계약서 확정

### 4.4 통화·날짜 locale

- ₩50,000 → KRW 50,000 (EN 표기, **환산 금지**)
- 2026-05-23 (ko) vs May 23, 2026 (en)
- 환율 기준 비교 불필요 (분쟁 소지 차단)

### 4.5 RBAC4 매니저 역할 (신규)

| 권한 | 사장 | **매니저 (신규)** | 코치 |
|---|---|---|---|
| 회원 추가·편집 | ✓ | ✓ | ✗ |
| 결제 처리·조회 | ✓ | ✓ | ✗ |
| 계약서 발행 | ✓ | ✓ | ✗ |
| 코치 시급·급여 | ✓ | 조회만 | ✗ |
| 코치 추가·편집 | ✓ | ✗ | ✗ |
| 박스 설정 변경 | ✓ | ✗ | ✗ |
| 환불 | ✓ | 사장 승인 필요 | ✗ |
| 통계·매출 dashboard | ✓ | 조회만 | ✗ |
| WOD 게시 | ✓ | ✓ | ✓ |

- `models/gym_user.py` role enum 에 `manager` 추가
- N3-6 연계: 매니저(외국인) 로그인 시 EN locale 자동 적용

### 4.6 task 재정의 (N3)

| ID | 변경 |
|---|---|
| **N3-1** | Flask-Babel + JSON locale, EN only, 확장 구조 설계 |
| **N3-2** | 토스트·에러 메시지 JS locale JSON 분리 추가 |
| **N3-3** | 영문 계약서 + 한국법 준거법 명시 + 면책 문구 |
| **N3-4** | **영문 Receipt** (세금계산서 영문화 X) |
| **N3-5** | 통화 환산 금지 (KRW 단위명 변경만) |
| **N3-6** | 매니저(외국인) 로그인 시 EN 자동 (RBAC4 연계) |

---

## 5. N4 — 확장 인프라 (수정안)

### 5.1 read replica — 측정 기반 도입

| 변경 | 기준 |
|---|---|
| 도입 시점 | 100박스 자동 X → **p95 latency > 300ms 또는 primary CPU 80%+ 지속** 실측 시 |
| 우선순위 | N4-1 (read replica) 를 N4-2 (PgBouncer) 이후로 변경 |
| lag 기준 | 5초 통계쿼리 한정. 실시간 SSE 이벤트는 primary 필수 |
| 선행 시도 | PgBouncer transaction mode + VOLATILE→STABLE RLS + 통계 materialized view 15분 refresh |

### 5.2 PgBouncer (P0 승격)

- `SET LOCAL` 강제 (study §3.4 PgBouncer transaction mode + RLS 호환)
- 박스당 max connection 제한
- tenant 별 `statement_timeout = 5s`

### 5.3 Redis Sentinel + 역할별 분리 + fallback

| 역할 | Redis DB | fallback |
|---|---|---|
| SSE pub/sub | `db=0` | 로컬 in-process queue (같은 worker 한정) |
| Celery broker | `db=1` | APScheduler 인프로세스 + 동기 fallback |
| rate limit | `db=2` | 앱 레벨 in-memory counter |
| session store | `db=3` | PostgreSQL session table |

- Redis Sentinel 또는 Railway Redis HA 사용
- health endpoint 분리: /health/redis/sse · /health/redis/celery · /health/redis/ratelimit

### 5.4 Celery vs APScheduler — 조건부

- 100박스 작업량 0.006 작업/초 → APScheduler 충분
- worker 2+ 필요 시점에만 Celery 이행
- 결제·SMS 같은 중복 불허 작업: Postgres advisory lock 즉시 적용

### 5.5 SQLite → PostgreSQL — Big Bang ETL + Branch by Abstraction

```
Step 1: Branch by Abstraction (코드 레벨, 다운타임 0)
  → DatabaseAdapter 인터페이스 + SqliteAdapter + PostgresAdapter
  → 환경변수 DB_ENGINE=sqlite/postgres 로 전환

Step 2: PostgreSQL 인스턴스 준비 (다운타임 0)
  → Railway PostgreSQL + RLS 정책·복합 인덱스

Step 3: 계획 다운타임 (새벽 2~6시 사전 통보, 5박스 협의 가능)
  → 점검 모드 HTTP 503
  → SQLite dump → PostgreSQL load
  → row count + 샘플 검증 → DB_ENGINE 스위치

Step 4: 롤백 준비
  → SQLite 백업 유지 → 실패 시 5분 내 복귀
```

데이터 양: 5박스 × 250회원 × 출석 = ~15만 row. ETL 30분 이내.

### 5.6 region 컬럼 즉시 추가 (N4-0 신설)

```sql
ALTER TABLE gyms ADD COLUMN region VARCHAR(5) DEFAULT 'kr';
```

```python
def get_db_url(gym_id: str) -> str:
    gym = Gym.query.get(gym_id)
    if gym.region == GymRegion.EU:
        return os.getenv("DATABASE_URL_EU")
    return os.getenv("DATABASE_URL")
```

- 비용 0 — EU 박스 계약 시 즉시 분기 가능
- EU 실제 DB 프로비저닝은 EU 박스 계약 시로 defer

### 5.7 Citus 검토만 (1TB 도달 시)

facing Phase 5 (10,000박스) 데이터 추정 = ~150GB. Citus §12.2 임계 (1TB) 미달.

→ PHASE3_ROADMAP §1 의 "단계 5 → Citus distributed" 표기를 "Citus 검토 (1TB 도달 측정 시)" 로 수정.

### 5.8 production gunicorn 좀비 자동 해결

```python
# gunicorn.conf.py
workers = 2 * multiprocessing.cpu_count() + 1
worker_class = "gevent"  # SSE 장시간 연결
preload_app = True  # APScheduler 중복 실행 방지
```

dev 환경: `flask run --no-reload` 로 Windows 좀비 회피.

### 5.9 task 재정의 (N4)

| ID | 변경 | 우선순위 |
|---|---|---|
| **N4-0** (신설) | region 컬럼 + DB URL 분기 skeleton | P0 (즉시) |
| **N4-1** | read replica — 측정 기반 도입 | P2 (30박스 후 측정) |
| **N4-2** | PgBouncer + SET LOCAL + RLS 최적화 | **P0** (5박스) |
| **N4-3** | Redis Sentinel + SSE fan-out + fallback | P1 (30박스) |
| **N4-4** | Celery — 조건부 (worker 2+ 시) | P2 |
| **N4-5** | CDN — Cloudflare free tier | P1 |
| **N4-6** | rate limit — Flask-Limiter + Redis | P1 |

---

## 6. N5 — 모니터링 (수정안)

### 6.1 단계별 비용·도구

| 박스 수 | 도구 | 월 비용 |
|---|---|---|
| 5~30박스 | Sentry + Railway 빌트인 log | $26 |
| 30~100박스 | Sentry + Grafana Cloud free tier + JSON log | $26 + grafana |
| 100박스+ | + synthetic monitoring + SLA dashboard | $80~100 |

### 6.2 Sentry **즉시 도입** (Phase 2 종료 전)

- Flask + JS 양쪽 SDK
- PII scrub + release tag (git hash)
- 일일 error digest 운영자 메일

### 6.3 task 재정의 (N5)

| ID | 변경 | 우선순위 |
|---|---|---|
| **N5-1** | Sentry SDK | **P0** (지금, Phase 2 종료 전) |
| **N5-2** | Grafana dashboard | P2 (30박스 후) |
| **N5-3** | JSON 구조화 log + request_id·gym_id 자동 tag | P1 (5~30박스) |
| **N5-4** | /health/db /health/redis /health/external | P1 |
| **N5-5** | incident response runbook | P2 (30박스 이후 실 경험 기반) |
| **N5-6** | synthetic monitoring | P3 (100박스 이후) |

---

## 7. N6 — onboarding (수정안)

### 7.1 셀프 setup wizard (P0)

3단계 setup wizard (ux-testing §6.1):
- Step 1: 회원권 상품 1개 설정 (5분)
- Step 2: 첫 회원 1명 추가 (3분)
- Step 3: 계약서 1건 발행 (2분)
- 각 단계 완료 시 토스트 + 다음 CTA
- **8분 이내 TTFV 달성 목표** (ux-testing §6.1 상위 SaaS 기준)

### 7.2 영상 튜토리얼 + PDF 분리 (8p + 40p)

- 영상: 10분 핵심 + 30분 상세 (YouTube unlisted)
- PDF: 빠른 시작 가이드 8p + 전체 레퍼런스 40p 이하
- 폰트: Pretendard Variable 4단계 위계
- 색상: 60% 흰 + 30% 중성 + 10% accent (CrossFit red #EE2B2B)
- 화면 캡처 + 빨간 화살표 오버레이 (ShareX 또는 Loom)
- 근거: cardnews-quality §2·§3 시각 위계

### 7.3 그룹 Zoom 세션 모델 (개별 30분 폐지)

| 단계 | 박스 수 | 모델 | 시간 비용 |
|---|---|---|---|
| 5~30박스 | 5~30 | 개별 선택 (주 2회 그룹 Zoom 5~10박스 동시) | 주 2시간 |
| 30~100박스 | 30~100 | 그룹 전용 (개별 세션 폐지) | 주 2시간 |

- 세션 녹화 → 도움말 센터 자동 업로드 (지식 누적)
- 100박스 시간 비용: 영상 제작 40시간 1회 + 운영 32시간 (vs 원안 50시간 개별)

### 7.4 RBAC4 매니저 역할 신규 (N6-2-추가)

§4.5 참조. `models/gym_user.py` role enum + RLS + 매니저 초대 UI + 매니저 dashboard.

### 7.5 RITE 5박스 파일럿 (30박스 전)

- 5명 파일럿 박스 사장에게 영상+PDF 테스트
- 문제 발견 즉시 수정 → 다음 5명 변경본 테스트
- 2라운드 × 5명 = 10명으로 85%+ 이슈 발견 (Nielsen 5-user rule)
- 팀 전원 관찰 참여

### 7.6 CS — 단계별 자동화

| 단계 | 박스 수 | CS 방식 | 예상 일 문의 |
|---|---|---|---|
| Phase 3 초기 | 5~30 | 카카오 채널 직접 응답 | 1~5건/일 |
| Phase 3 중기 | 30~100 | FAQ 도움말 센터 + 카카오 채널 | 5~20건/일 |
| Phase 4 | 100+ | FAQ + 카카오 챗봇 1차 + 담당자 2차 | 20+건/일 |

FAQ 도움말 센터 우선 6개 (test C4 + C3 기반):
1. 처음 사용 — 회원권 설정 방법
2. 결제 — 현금·카드 수동 등록
3. 계약서 — 영문 계약서 발행
4. 세금계산서 — 발행 조건 + 영문 Receipt 차이
5. 박스 스위처 — 두 번째 지점 추가
6. CSV — 회원 일괄 가져오기

### 7.7 NPS — 30일 자동 트리거 + 분기 정기

- 측정: 분기 1회 + 가입 후 30일 자동 트리거 (첫 인상 포착)
- 채널: 이메일 (사장) + 앱 내 팝업 (부차적)
- 도구: Typeform/Google Forms 초기 → Delighted/Survicate (100박스 이후)
- 신뢰성: n ≥ 20박스 이상일 때 유의미. 5~30박스는 정성 인터뷰 병행
- Promoter 코멘트 → 박스 추천 프로그램 testimonial 활용

### 7.8 task 재정의 (N6)

| ID | 변경 |
|---|---|
| **N6-0** (신설) | 셀프 setup wizard 3단계 (8분 TTFV) |
| **N6-1** | 5박스 안정화 (유지) |
| **N6-2** | 영상 10분+30분 + PDF 8p+40p 분리 + Pretendard 4단계 위계 |
| **N6-2-추가** (신설) | RBAC4 매니저 역할 + 초대 UI + dashboard |
| **N6-3** | 5박스→30박스: 그룹 Zoom 주 2회 5~10박스 동시 + 법무 자문 30박스 전 |
| **N6-4** | 30박스→100박스: 그룹 전용 + 녹화 자동 업로드 |
| **N6-5** | FAQ 6개 우선 + 30박스 시점 카카오 챗봇 + 야간 자동 응답 |
| **N6-6** | NPS — 30일 자동 트리거 추가 + 정성 인터뷰 병행 (n<20) |

---

## 8. 우선순위 매트릭스 종합 (P0 → P1 → P2)

### P0 — Phase 3 진입 직후 무조건

| 영역 | task | 근거 |
|---|---|---|
| N4 | **N4-0** region 컬럼 + DB URL 분기 | EU 박스 사전 준비, 비용 0 |
| N4 | **N4-2** PgBouncer + SET LOCAL + RLS 최적화 | 100박스 즉시 필요 |
| N5 | **N5-1** Sentry SDK + PII scrub | 즉시 도입 |
| N6 | **N6-0** 셀프 setup wizard | 8분 TTFV |
| N1 | **N1-0**~**N1-3** schema 6 테이블·movement_library·WOD·PR·benchmark | Wodify 격차 해소 |
| N2 | **N2-1**·**N2-7**·**N2-8**·**N2-9** 자동결제·3-tier 가격·trial·코치 정산 | 매출 + 법적 의무 |

### P1 — Phase 3 중기 (5~30박스)

| 영역 | task |
|---|---|
| N4 | N4-3 Redis Sentinel + SSE fallback · N4-5 Cloudflare CDN · N4-6 rate limit |
| N5 | N5-3 JSON log · N5-4 health check 확장 |
| N6 | N6-2 PDF + 영상 · N6-2-추가 매니저 RBAC4 · N6-3 그룹 Zoom · N6-5 FAQ + 챗봇 |
| N1 | N1-4 Open 시즌 수동 · N1-5 동작 60개 · N1-6 leaderboard 알고리즘 |
| N2 | N2-2~N2-6 PT·cohort·dashboard·할인·loyalty · N2-10 이탈 scoring |
| N3 | N3-1~N3-6 i18n EN · Receipt · 통화 locale |

### P2 — Phase 3 후기 (30~100박스) 또는 Phase 4 검토

| 영역 | task |
|---|---|
| N4 | N4-1 read replica (p95>300ms 실측 시) · N4-4 Celery (worker 2+ 시) |
| N5 | N5-2 Grafana · N5-5 runbook · N5-6 synthetic |
| N6 | N6-4 30→100박스 · N6-6 NPS Delighted/Survicate |
| N1 | N1 Phase 4 defer: DOTS 글로벌·HYROX·KWA/KSPO 연계·HQ API |
| N2 | N2-11 여성 그룹 tier (검증 후) |
| (Won't) | ClassPass marketplace · Citus (1TB 미달 시) |

---

## 9. 의존 그래프

```
즉시 (Phase 2 종료 전):
  N5-1 (Sentry) ── independent
  N4-0 (region skeleton) ── independent
  N4-2 (PgBouncer + RLS) ── independent
  N1-0 (movement_library) ── PostgreSQL 이행 후
  N2-1 (자동결제 강제) ── Toss webhook (P0-8) 완료 후
  N2-9 (코치 정산) ── 코치 schema 확장 후

5박스 → 30박스:
  N1-1~N1-3 (WOD·PR·benchmark schema) ── 데이터 모델 안정 후
  N2-7 (3-tier 가격) · N2-8 (trial·cancel flow)
  N3-1~N3-6 (i18n EN) ── 모든 UI text 키화 후
  N6-0 (setup wizard) ── 신규 UI 작업
  N6-2 (영상·PDF) ── content 제작
  N5-3 (JSON log) ── Sentry 통합 후
  N4-5 (CDN) ── independent

30박스 → 100박스:
  N4-3 (Redis SSE + fallback)
  N4-6 (rate limit) ← N4-3
  N5-2 (Grafana) ← N4-3
  N6-3 (그룹 Zoom)
  N6-5 (카카오 챗봇)
  N6-6 (NPS 30일 자동)
  N1-6 (leaderboard 알고리즘)
  N2-10 (이탈 scoring)

100박스 측정 기반:
  N4-1 (read replica) ← p95>300ms 또는 CPU 80%+
  N4-4 (Celery) ← worker 2+ 필요 시
  N5-5 N5-6 runbook·synthetic
  N6-4 (100박스 onboarding 운영)
```

---

## 10. 비용 모델 재추정

원안 PHASE3 §9.2 의 단순 추정 → study 기반 정밀화.

| 단계 | 박스 수 | ARPU | 월 수익 | 인프라 | 모니터링 | 인건비 (1인) | 순이익 |
|---|---|---|---|---|---|---|---|
| Phase 2 | 5박스 | ₩100K (월간 우세) | ₩500K | $100 (~₩130K) | $26 | ₩2,500K | -₩2,260K (적자) |
| Phase 3 초기 | 30박스 | ₩95K (연간 1/3 가정) | ₩2,850K | $300 (~₩400K) | $45 | ₩3,000K | -₩595K (적자) |
| Phase 3 중기 | 60박스 | ₩93K | ₩5,580K | $500 (~₩650K) | $60 | ₩3,500K | +₩1,370K (break-even 돌파) |
| Phase 3 종료 | 100박스 | ₩90K (연간 1/2) | ₩9,000K | $800 (~₩1,040K) | $100 | ₩4,000K | +₩3,830K (성장 이익) |
| Phase 4 | 1000박스 | ₩85K | ₩85,000K | $3,000~5,000 | $300 | ₩15,000K (팀 3~5인) | +₩60,000K (월 6천만) |

### break-even 박스 수 추정

- 60박스 부근 (연간 플랜 비중 30~40% 가정)
- Phase 3 핵심 임계 = break-even 통과 (subscription-fitness §pricing 의 boutique 헬스장 ARPU 일반)

### LTV·CAC 한계선

- 박스 LTV (연간 플랜) ₩2,574,000
- CAC 한도 (LTV:CAC > 3:1) ₩858,000
- 초기 5박스: 직접 영업·인맥 → CAC 거의 0
- 30~100박스: 추천 프로그램 (₩100K) + 직접 영업 (₩50~100K) → CAC ~ ₩200K
- 100박스+ : 마케팅 채널 다양화 (콘텐츠·SEO·박스 conference) → CAC ~ ₩500K

---

## 11. 종합 결론

### 11.1 v1 → v2 변경 요약

- N1: schema 3→6 / 동작 200→60 / HQ API 제거 / Korea Custom 카테고리 / RX·Scaled 분리 — **6 task 재정의**
- N2: 정기결제 기본값 강제 / 3-tier 가격 / 21일 trial / 코치 정산 자동화 / 이탈 5점 scoring — **5 신규 task + 6 기존 수정 = 11 task**
- N3: EN only / 영문 Receipt (세금계산서 X) / 법무 자문 30박스 시점 / RBAC4 매니저 — **6 task 수정**
- N4: read replica 측정 기반 / PgBouncer P0 / Redis Sentinel / Big Bang ETL / region 즉시 / Citus 검토만 — **7 task (1 신설)**
- N5: Sentry P0 즉시 / Grafana 30박스 후 / 비용 단계화 — **6 task 우선순위 재배치**
- N6: 셀프 setup wizard / 그룹 Zoom / PDF 분리 / RITE 파일럿 / NPS 30일 자동 — **6 task + 2 신설 = 8 task**

### 11.2 Phase 3 진입 가능 시점

- Phase 2 종료선 = 5박스 30일+ 안정 운영 + uptime 99.5%+ + RLS·결제·푸시·SMS·메일 4 채널 production
- 현재 진행률 ~30~35% (오버나이트 patch 3 라운드 후)
- 5박스 invite 임계까지 약 50% 거리

### 11.3 다음 단계 액션 (자동 진행)

1. PHASE3_ROADMAP.md 의 §변경 이력에 v2 cross-reference 추가
2. WEB_ADMIN_MEMBER_MGMT_TODO.md 의 P0 task 와 PHASE3 v2 의 P0 매핑
3. Phase 2 P0 critical path (PostgreSQL+RLS → assert_gym_match → PIPA → CSRF → Toss → 결제) 진행
4. 동시 (병렬): 박스 스위처 stub · 회원 상세 사이드패널 · 회원권 종류 관리 · 온보딩 wizard

---

## §변경 이력

- **2026-05-23 오전**: v2 작성. 4 sub-agent (Sonnet 병렬) artifact 종합. PHASE3_ROADMAP.md v1 의 task 70% 유효 + 30% 재설계. 영역별 변경점·우선순위 매트릭스·의존 그래프·비용 모델 정밀화·break-even 60박스 추정.

---

## 12. 부록 — 4 sub-agent artifact 위치

- `docs/test/phase3-review/N1-crossfit-domain.md` (sub-agent A)
- `docs/test/phase3-review/N2-business-model.md` (sub-agent B)
- `docs/test/phase3-review/N4-N5-infra.md` (sub-agent C)
- `docs/test/phase3-review/N3-N6-i18n-onboarding.md` (sub-agent D)

각 artifact 에 study 인용 verbatim + 출처 명시. 본 v2 는 종합·요약·우선순위만 담음.
