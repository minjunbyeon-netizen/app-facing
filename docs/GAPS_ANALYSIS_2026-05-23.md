# facing — 미흡 영역 분석 (2026-05-23 오전)

> **작성**: 오버나이트 자동 분석 (사용자 명시 요청 2026-05-23 08:23)
> **근거**: `/test` 보고서 (`docs/test/2026-05-23-0136/report.md`) + study (`~/.claude/reference/study/gym-management-saas.md`·`subscription-fitness.md`·`ux-testing.md`) + `ARCHITECTURE_BRIEF.md` + `WEB_ADMIN_MEMBER_MGMT_TODO.md`
> **목적**: Phase 2 → Phase 3 transition 의사결정 input. 5박스 invite 임계 평가.

---

## 0. 한 줄 요약

> **현재 health 32~35/100 (오버나이트 patch 3 라운드 후). 5박스 invite 임계는 70/100 권장. 약 50% 거리 남음. 5 영역에서 미흡, 가장 큰 격차는 도메인 핵심 기능 부재(C3).**

---

## 1. 5 영역 미흡 매트릭스

| 영역 | 미흡 종류 | 영향 페르소나 | study 근거 | 5박스 invite 영향 |
|---|---|---|---|---|
| ① 도메인 핵심 기능 | 결제·CSV·WOD·박스 스위처·i18n·알림 | p1·p3·p5·p6·p7·p8·p10 (7/10) | gym-management-saas §5·subscription-fitness §3 | **block** |
| ② 운영·신뢰 인프라 | PostgreSQL+RLS·CSRF·rate limit·PIPA·webhook·backup | (모든 페르소나) | gym-management-saas §3·§8·§11 | **block** |
| ③ UX·접근성·온보딩 | 온보딩·empty state·도움말·WCAG·검색 | p2·p4·p9·p10 (4/10) | ux-testing | **major** |
| ④ 비즈니스 모델 | 자동결제·할인·PT·retention·marketplace | (사장 운영 효율 70%) | subscription-fitness 전체 | major |
| ⑤ 확장·미래 | read replica·bridge·Citus·region pinning | (확장 단계) | gym-management-saas §12·§14.6 | minor (단계 3+) |

---

## 2. ① 도메인 핵심 기능 — Wodify·PushPress 대비 격차

`/test` 보고서 C3 (32건 · score 1584 · Top 1).

### 2.1 결제·매출 · 영수증 · 세금계산서 (P0)

- 박스 운영의 가장 기본. 현금 받았을 때 입력할 곳이 없음
- p3(회계 사장 41세) · p10(63세 디지털약자) 가 task_complete 0%
- 세금계산서·영수증·환불·미납 검출 · 매출 CSV 모두 부재
- 근거: study `gym-management-saas.md` §14.6 단계 2 trigger. 첫 5박스 invite 전 의무
- 영향: 현금 보관 + Excel 별도 관리 → SaaS 도입 이유 자체 무산

### 2.2 CSV import (P0)

- 200명 가진 5년차 사장(p8) 가입 자체 포기
- Notion·Excel 에서 옮길 수 없으면 신규 박스만 받음
- Wodify 의 onboarding 우위 1번
- 근거: study `gym-management-saas.md` §5 Shopify·Notion 마이그레이션 사례

### 2.3 CrossFit 특화 — WOD · benchmark · PR · Open 시즌 leaderboard (P0)

- "CrossFit 박스 전용 vertical SaaS" 포지셔닝 vs 실제 CrossFit 콘텐츠 0개
- p7(Wodify 헤비유저) 진단: "회원관리 스프레드시트와 차별점 없음"
- 핵심 기능: WOD 트래킹 · 회원별 PR(Personal Record) · benchmark (Fran·Grace·Helen 등) · 박스 leaderboard · CrossFit Games Open 시즌 score 통합
- 근거: study `subscription-fitness.md` — vertical SaaS 차별화는 도메인 깊이에서 옴. Wodify 의 $200/월 가격 정당화 = 이 기능들

### 2.4 알림 자동화 (P0)

- 사장이 화면 안 켜놓으면 알림 X
- 외부 채널 (SMS·메일·푸시·카카오) stub 만 있고 live X
- 만료 N일 전 · 결제 수신 · 가입 신청 · 출석 결석 등
- 근거: gym-management-saas §6 NIST + study §13 OWASP Mobile

### 2.5 박스 스위처 (D18) (P0)

- 다중 박스 사장(p5) 사용 불가 — 8건 집중 발견
- 한국 CrossFit Affiliate 의 30% 가 2 박스 이상 운영
- JWT `org_scopes` 배열 + 사이드바 드롭다운 + 모든 화면 box_id 필터
- 근거: study §7 B2B2C JWT org_scopes 패턴 (Shopify·Stripe Connect)

### 2.6 i18n EN/KO (P1)

- 외국인 사장(p6) task 0%
- 한국 CrossFit 박스 30% 이상이 외국인 코치 활용·재한 외국인 회원 받음
- 사이드바 EN/KO 토글 + 영문 계약서 템플릿 + 영문 영수증
- 근거: study `gym-management-saas.md` §11 GDPR 한국 PIPA 동등 + 한국 시장 외국인 점유율

---

## 3. ② 운영·신뢰 인프라 — production-ready 미달

### 3.1 SQLite → PostgreSQL + RLS 이행 (P0 · block)

- 박스 2개 받자마자 데이터 누출 위험
- `FORCE ROW LEVEL SECURITY` + `SET LOCAL` 패턴 의무
- Alembic 도입 + 마이그레이션 스크립트
- 근거: study §3 Postgres RLS. roadmap M3

### 3.2 assert_gym_match endpoint 적용 (P0)

- 헬퍼는 추가됨. admin.py 회원·결제·계약 endpoint 미적용
- 옛 `if m.gym_id != session[...]` 패턴 → `assert_gym_match()` 통일
- 회귀 어렵고 OWASP A01 위험 (94% 앱 결함)
- 근거: study §8.3 Failure 1 IDOR 방어

### 3.3 CSRF · rate limit · 로그인 잠금 (P0)

- A-3 Flask-WTF 또는 자체 double-submit 토큰
- A-4 Flask-Limiter + Redis IP·user·endpoint 별 sliding window
- 로그인 5회 실패 = 5분 lockout, 30회 = 30분 + SMS
- 근거: study §8 OWASP A01·A05·A07

### 3.4 PIPA — 개인정보 분리·동의서·암호화 (P0)

- 회원 이름·전화·생년월일 평문 컬럼
- 가입 시 동의 (수집·이용·제3자·마케팅) 4 토글 UI 0개
- AES-256 application-level 암호화 (식별정보) + pgcrypto 옵션
- 근거: study §11 GDPR + 한국 PIPA 제15조·제17조

### 3.5 결제 webhook HMAC · idempotency (P0)

- Toss stub 만 있음 — replay 공격·중복 결제·환불 reconciliation 모두 X
- HMAC-SHA256 verify · idempotency key · 실패 재시도 + dead letter
- 근거: roadmap M2-1 · study payment 영역

### 3.6 백업·복구·migration drill (P1)

- 일일 03:00 SQLite dump 외 검증 없음
- PostgreSQL 이행 시 데이터 손실 위험
- 분기 1회 복구 drill + 30일 retention

### 3.7 production stack (P1)

- CORS · CSP · HSTS production 설정
- logging 구조화 (JSON 포맷)
- error tracking Sentry SDK + release tag
- health check /db /redis /external endpoint
- 좀비 서버 다중 LISTEN 운영 가이드 (`scripts/dev_boot.ps1` 추가했지만 README 없음)

---

## 4. ③ UX · 접근성 · 온보딩

`/test` 보고서 C4 (31건 · score 644) + C5 (9건 · score 89).

### 4.1 온보딩 3단계 가이드 (P0)

- 박스 오픈 1주차 사장(p4) "어디부터 시작" 무대응
- 단계: (1) 회원권 종류 등록 → (2) 첫 회원 → (3) 첫 계약서
- `ux-testing.md` 룰: 첫 5분에 task 1개 못 끝내면 60% 이탈

### 4.2 회원권 종류 관리 페이지 (P0)

- 회원 추가 모달에 select 만 있고 박스별 가격표 정의 화면 없음
- 1개월권 50만원 · PT 10회 30만원 · 동결권 · 횟수권 등
- 박스마다 가격 정책 다른 현실 반영

### 4.3 회원 상세 사이드패널 (P0)

- 행 클릭 → 수정 모달만. 결제 history · 계약서 · 출석 · PR · 메모 · 코치 배정 탭 부재
- test C2 Top 7. p7 Wodify 비교 발견

### 4.4 도움말 · 툴팁 · placeholder · hint (P1)

- 0건. p10(디지털 약자) 의 "여기 뭐 하는 거예요?" 모든 항목

### 4.5 빈 상태 다음 액션 (P1)

- members · coaches · payroll 일부 patch 완료
- 잔여: lockers · contracts · checkin 빈 상태 미흡

### 4.6 WCAG AA (p9 8건)

- 락커 patch 했지만 잔여: 사이드바 nav 13px · 터치 타겟 40px (44px 미달)
- aria 속성 0개 · focus indicator 0개 · prefers-contrast 0개
- 노안 사장 + 태블릿 운영 차단

### 4.7 모바일 운영 (P1)

- 사장 PC 웹 데스크톱 가정. 박스 안에서 태블릿·폰으로 락커·QR 만질 일 많음
- responsive · 터치 친화 · safe-area inset 점검

### 4.8 토스트 적용 확대 (P1)

- 이번 patch 일부. 잔여: lockers · contracts · payroll csv export · 모든 작업 success/error

### 4.9 검색·필터·정렬 (P1)

- 회원·코치·계약서·결제 모두 단순 텍스트만
- status · 기간 · 코치별 · 금액 등 운영자 자주 쓰는 필터 부재

### 4.10 데이터 일관성 (P1)

- 통계 KPI "총 회원" vs /members 카운트 정의 다름
- 백엔드 stats query 통일 (전체 vs 활성 별도 필드)

---

## 5. ④ 비즈니스 모델 — 박스 운영 30%만 커버

`subscription-fitness.md` + `gym-management-saas.md` §5 강조. 박스 사장 SaaS 도입 동기 = 운영 효율 70% + 데이터 분석 30%.

### 5.1 회원 retention cohort (P1)

- 신규·이탈·재가입·휴면 트래킹
- 가입 월별 cohort table (3·6·12개월 잔존율)
- churn 검출 자동 alert

### 5.2 자동결제 (정기결제·빌링키) (P1)

- Toss 정기결제 API + 빌링키 발급
- 매월 지정일 자동 청구 + 3회 재시도 + 실패 시 SMS
- 한국 박스 30% 가 매월 카드 긁는 방식 잔존

### 5.3 할인·쿠폰·친구 추천 (P2)

- 박스 마케팅 핵심
- 코드 기반 할인 + 친구 추천 보상 + 시즌 이벤트

### 5.4 PT 예약 시스템 (P1)

- 코치-회원 매칭 · 시간표 · 캔슬 정책
- 현재 코치만 추가·시급. PT 진행 X

### 5.5 마케팅·매출 dashboard (P1)

- 매출 · 신규 · 이탈 · NPS 같은 사장 KPI
- 현재 통계 카드는 운영 지표만

### 5.6 marketplace 연동 (P2)

- ClassPass 한국 진출 후 박스가 받으면 통합
- 근거: subscription-fitness §marketplace economics

---

## 6. ⑤ 확장·미래

study `gym-management-saas.md` §14.6 단계별 임계.

### 6.1 단계 2 (5박스) — Phase 2 종료선

- 현재 약 30% 진행
- PostgreSQL+RLS · 결제 · SMS · 푸시 · CSV · 온보딩 · 사용성 검증 필수
- 임계까지 약 70% 거리

### 6.2 단계 3 (100박스) — Phase 3 첫 목표

- read replica · connection pool 튜닝
- 모니터링 stack 강화 (Sentry · Grafana · Railway log)
- 0%

### 6.3 단계 4 (1,000박스 또는 enterprise 1곳)

- bridge schema-per-gym (Notion·Shopify 패턴)
- 또는 region pinning (EU 진출 시 GDPR Art. 44-49)
- 0%

### 6.4 단계 5 (10,000박스)

- Citus distributed Postgres (SIGMOD 2021 Cubukcu et al.)
- 또는 silo (compliance · HIPAA · SOC2)
- 0%

---

## 7. 우선순위 매트릭스 (Phase 3 input)

### P0 — 5박스 invite 전 무조건 (Phase 2 마무리)

| # | 항목 | 영역 | 시간 |
|---|---|---|---|
| P0-1 | 결제·매출·영수증·세금계산서 | ① | 2주 |
| P0-2 | CSV import | ① | 1주 |
| P0-3 | 알림 자동화 (SMS·메일·푸시) | ① | 1.5주 |
| P0-4 | SQLite → PostgreSQL + RLS | ② | 2주 |
| P0-5 | assert_gym_match 전 endpoint 적용 | ② | 3일 |
| P0-6 | CSRF + rate limit + 로그인 잠금 | ② | 1주 |
| P0-7 | PIPA — 동의서·암호화·삭제권 | ② | 1주 |
| P0-8 | Toss webhook HMAC · idempotency | ② | 3일 |
| P0-9 | 박스 스위처 (D18) | ① | 1주 |
| P0-10 | 회원권 종류 관리 페이지 | ③ | 4일 |
| P0-11 | 회원 상세 사이드패널 | ③ | 1주 |
| P0-12 | 온보딩 3단계 가이드 | ③ | 3일 |

**합산**: 약 10~12주 (Phase 2 종료선)

### P1 — invite 후 30일 안

| # | 항목 | 영역 |
|---|---|---|
| P1-1 | i18n EN/KO + 영문 계약서 | ① |
| P1-2 | WOD/PR 트래킹 (CrossFit 전용) | ① |
| P1-3 | 자동결제 정기결제 | ④ |
| P1-4 | PT 예약 시스템 | ④ |
| P1-5 | 마케팅·매출 dashboard | ④ |
| P1-6 | WCAG AA 전반 fix | ③ |
| P1-7 | 도움말·툴팁·placeholder | ③ |
| P1-8 | 검색·필터·정렬 강화 | ③ |
| P1-9 | 모바일 운영 케이스 | ③ |
| P1-10 | retention cohort | ④ |
| P1-11 | 백업·migration drill | ② |
| P1-12 | production stack (CSP·HSTS·Sentry) | ② |

### P2 — Phase 3 단계 3 (100박스) 진입 시

- read replica
- bridge schema-per-gym
- ClassPass marketplace 통합
- 할인·쿠폰·친구 추천
- region pinning (EU 진출 시)
- Citus 검토 (1,000박스 + trigger)

---

## 8. 결론

### 8.1 현재 위치

- Phase 1 (MVP·데모) 완료
- Phase 2 (5박스 invite) 진행률 30%
- /test health 28→32~35/100 (오버나이트 patch 3 라운드 후)
- 5박스 invite 임계 70/100 까지 약 50% 거리

### 8.2 다음 마일스톤 — Phase 2 마무리

P0 12 항목 처리 = 10~12주 예상. 우선순위 의존 그래프 (study §14.1):
```
P0-4 (PostgreSQL+RLS) → P0-5 (assert_gym_match) → P0-7 (PIPA)
                          ↓
P0-6 (CSRF/rate limit) → P0-8 (Toss webhook) → P0-1 (결제·매출)
                          ↓
P0-2 (CSV import) · P0-3 (알림) · P0-9 (박스 스위처) · P0-10 (회원권) · P0-11 (상세) · P0-12 (온보딩) 병렬
```

### 8.3 Phase 3 준비

`PHASE3_ROADMAP.md` 참조. 단계 3 (100박스) 진입 plan.

---

## §변경 이력

- **2026-05-23 오전**: 신규 작성. 5 영역 미흡 분석 + P0/P1/P2 우선순위 + Phase 3 input.
