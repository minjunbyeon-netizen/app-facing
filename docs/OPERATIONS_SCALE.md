# facing — 박스 확장 운영 가이드 (5→30→100)

> **작성일**: 2026-05-23 (오버나이트)
> **연계**: `PHASE3_REVISION_v2.md` §7 (N6 onboarding) · `INFRA_GUIDE.md` · `NOTIFICATION_CATALOG.md`

---

## 1. 박스 확장 단계 (N6-3·N6-4)

| 단계 | 박스 수 | 기간 | onboarding 방식 | 인프라 | 인력 |
|---|---|---|---|---|---|
| **5 → 30** | 5 → 30 | 1~2개월 | 개별 선택 + 그룹 Zoom 주 2회 (5~10 동시) | Sentry + Railway 빌트인 metrics | 1인 운영 |
| **30 → 100** | 30 → 100 | 3~4개월 | 그룹 Zoom 전용 + 녹화 자동 업로드 | + Grafana Cloud free + JSON log | 1~2인 |
| **100+** | 100+ | 지속 | 셀프 onboarding wizard + FAQ + 챗봇 | + synthetic + PagerDuty | 2~3인 + on-call |

---

## 2. 박스 onboarding 표준 절차

### 2.1 사장 모집·계약 (1주)

1. 박스 사장 미팅 (30분 화상 또는 직접 방문)
2. 무료 trial 30일 등록 (subscription-fitness §7.1 endowment 효과)
3. 박스 정보 입력 (이름·주소·운영시간·기존 회원 수)
4. PC 사장 계정 발급 + 임시 비밀번호 SMS

### 2.2 setup wizard 8분 (N6-0)

1. 회원권 1개 등록 (1개월권 ₩100,000 default)
2. 첫 회원 1명 추가 + 회원권 자동 발급
3. 첫 계약서 발행

### 2.3 박스 매니저 교육 1시간 (N6-2)

- 10분 영상: 핵심 기능 5개 (회원 등록·결제·체크인·코치 추가·정산)
- 30분 상세 영상: WOD·PR·통계 dashboard
- 8p 빠른 시작 가이드 (PDF)
- 40p 전체 레퍼런스 (검색 가능 PDF)

### 2.4 기존 회원 마이그레이션 (1~3일)

- CSV import (B-6) — 200명 한 번에
- 기존 결제 history 는 별도 (수동 입력 권장)
- 회원권 만료일 자동 알림 (C-2) 활성

### 2.5 첫 30일 monitoring

- 매일 health check (자동)
- 주간 박스 사장 NPS 측정 (Typeform)
- 박스 첫 결제 1건 성공 확인
- 사장이 1주 안에 회원 등록 5명+ 했는지 확인 (engagement)

---

## 3. FAQ + 카카오 챗봇 (N6-5)

### 3.1 FAQ 도움말 센터 6개 항목 (Phase 3 P1)

1. **처음 사용 — 회원권 설정 방법** (p4·p10 마찰 최다)
2. **결제 — 현금·카드·이체 수동 등록 방법**
3. **계약서 — 영문 계약서 발행 방법** (p6 니즈)
4. **세금계산서 — 발행 조건 + 영문 영수증 차이**
5. **박스 스위처 — 두 번째 지점 추가 방법** (p1·p5 마찰)
6. **CSV — 회원 일괄 가져오기 방법** (p7·p8 마찰)

### 3.2 카카오 챗봇 (30박스 이후)

- 영업시간 안내 + FAQ 링크 3개 자동 응답
- 반복 질문 Top 5 자동 처리
- 야간·주말 응답 공백 해소
- Top 5 외 질문 → 영업일 4시간 안 담당자 회신

---

## 4. NPS·churn 측정 (N6-6)

### 4.1 측정 시점

- 가입 후 30일 (Typeform 자동 이메일)
- 분기 1회 정기 (Q1·Q2·Q3·Q4)
- 사장 이탈 직전 정성 인터뷰

### 4.2 NPS 목표

- 60+ (Phase 3 종료 조건)
- n ≥ 20 박스 이상일 때 유의미. 5~30박스 구간은 정성 인터뷰 우선

### 4.3 Promoter 활용

- 추천 코멘트 → 박스 추천 프로그램 testimonial (홈페이지 노출)
- 신규 박스 권유 시 case study

### 4.4 Detractor 인터뷰

- 1점·2점 응답 박스에 30분 화상 인터뷰
- 이탈 위험 5점 scoring (services/cohort.py) 와 교차

---

## 5. P2 인프라 단계화 (N4·N5)

| trigger | 작업 | 비용 |
|---|---|---|
| primary CPU 80%+ 지속 OR p95 > 300ms | **read replica** 도입 (N4-1) | Railway PostgreSQL replica $19/월 |
| Celery worker 2+ 필요 (cohort 갱신·SMS retry burst) | **Celery + Redis broker** (N4-4) | Railway worker dyno $20/월 |
| 30박스 이후 가시성 부족 | **Grafana Cloud free** (N5-2) | $0 (10K metrics/월) |
| 100박스 이후 endpoint 실패 빠른 발견 | **Synthetic monitoring** (N5-6) | $20/월 (Pingdom 또는 cron-job.org) |

---

## 6. 박스 추천 프로그램 (N6-4)

5박스 → 30박스 phase 에서 자연 성장 가속.

- 1박스 추천 = 추천한 박스에 1개월 무료
- 신규 박스도 첫 달 30% 할인
- 추천 link 자동 생성 → 박스 dashboard 에 노출
- 추천 history audit_log 기록

목표: 30박스 중 5박스 = 추천 출처 (16% 추천 conversion)

---

## §변경 이력

- **2026-05-23**: 신규 작성. 5→30→100 단계 onboarding 절차·FAQ 6개·NPS·인프라 단계화·추천 프로그램.
