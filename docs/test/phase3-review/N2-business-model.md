# N2 — 비즈니스 모델 재검토 (sub-agent B)

> **작성일**: 2026-05-23
> **입력**: PHASE3_ROADMAP.md §4·§9.2 + subscription-fitness.md + pricing.md + labor-office.md
> **목적**: N2 task list 7개 검증 질문에 study 기반 정밀 재설계

---

## 1. 가격·구독 정책 재설계

### 1-A. 자동결제 (정기결제) — Toss 빌링키 vs 현금·계좌이체

**현황 문제**: PHASE3 N2-1 은 Toss 정기결제만 기술. 한국 박스 30%가 현금·계좌이체 사용.

**study 근거**:
- pricing.md §5 "Pain of paying": 결제 수단이 pain modulator. 현금=4.1/7(최고 고통), 카드·자동이체=3.4/7. 정기결제 = **pain 최소화 → retention 도구**.
- pricing.md §10.2 Annual vs Monthly: 연간 플랜이 월 대비 involuntary churn **10~14배 낮음**, LTV **+40~45%**.
- subscription-fitness.md §4 churn 사유: 결제 문제(involuntary) **15~28%**가 3위. 카드 자동결제 미도입 = 가장 쉬운 involuntary churn 차단 포기.

**재설계 권고**:

| 결제 수단 | 기본 정책 | 인센티브 |
|---|---|---|
| Toss 빌링키 자동결제 | **기본값** 강제 유도 | 연간 선납 시 2개월 무료 (concrete framing — "20% 할인"보다 +45% revenue, pricing §7.1) |
| 계좌이체 수동 | 허용하되 **+10% 수수료 또는 월정액 제한** | 자동결제 전환 시 1개월 감면 |
| 현금 | 비활성화 권고 (invoicing 만) | — |

**6개월권 anchoring (pricing §2 Anchoring)**:
- 가격표 노출 순서: 연간(최고 anchor) → 6개월 → 월간(최저)
- "6개월 = 월×6 - 10%" 가 아니라 "연간 2개월 무료" concrete framing으로 표기
- 3-tier decoy 적용: 월간 ₩99,000 / 6개월 ₩529,000 / 연간 ₩899,000 (월환산 ₩74,917). 6개월을 **mid-tier decoy**로 배치해 연간 선택 유도.

**charm pricing**: 박스 SaaS는 B2B 분석 처리 → round 가격($100, $200)이 신뢰감 (Wadhwa-Zhang §11.1). ₩99,000보다 ₩100,000이 프리미엄 신호로 더 적합.

---

### 1-B. PT 예약 시스템 — 박스 내 PT vs 마켓플레이스

**현황**: N2-2 는 단순 예약 UI 기술. ClassPass 한국 진출 후 경쟁 구도 미검토.

**study 근거**:
- subscription-fitness.md §3.1: 양면시장은 supply-constrained. 박스가 PT를 마켓플레이스에 올리면 ClassPass 의존도가 **20~90%** 될 수 있음 (vice.com). 진입 후 이탈 시 매출 충격 큼.
- subscription-fitness.md §3.5 안티: "ClassPass가 신규 회원 유치" — **near-zero conversion**. 마켓플레이스는 박스에 도움 안 됨.
- subscription-fitness.md §2.5 안티: ClassPass 정착 사례 = 2021 Mindbody 흡수. aggregator → SaaS 통합 함정.

**취소 정책 설계 (study 기반)**:
- 24h 전 취소: **전액 환불** (pain of paying §5 — 취소 friction 제거 = lock-in 불안 해소 → 예약 증가)
- 24h 후 취소: **50% 환불** (손실회피 λ≈2.25 활용, prospect theory §4.1 — 취소 억제)
- No-show: **0% 환불 + 다음 예약 디파짓 ₩10,000** (commitment device, §8 Royer)

**권고**: 마켓플레이스 연동 **보류**. 박스 내 PT 예약 + 코치 캘린더를 우리 SaaS 안에 완결. ClassPass 연동은 박스 자체 선택에 맡기되 데이터 독점권 유지.

---

### 1-C. 할인·쿠폰 — 비수기/성수기 가격 차별

**study 근거**:
- pricing.md §12.1 KKT 1986: demand-only 가격 인상은 **82% unfair 인식**. 비수기 할인은 OK, 성수기 인상은 "비용 정당화" 없으면 백래시.
- subscription-fitness.md §7.1: 가격 인하로 churn 해결 시도 — **안티**. churn 1위는 사용 부족 (37%), 비용은 2위 (35%).
- pricing.md §13.1 Endowment effect: 30일 무료 → ownership → 이탈 저항. Trial 17~32일이 sweet spot (subscription-fitness §7.1).

**권고**:

| 할인 유형 | 적용 | 근거 |
|---|---|---|
| 신규 가입 30일 무료 | **강력 권고** | Endowment + 습관 형성 윈도 (17~32일 sweet spot) |
| 비수기 (1~2월, 7~8월) 할인 | 10% 할인 + "시즌 특가" concrete framing | KKT cost passthrough OK — "운영 지원" 명분 |
| 성수기 인상 | **금지** | KKT 82% unfair, CrossFit 커뮤니티 규모 작아 백래시 치명적 |
| 친구 추천 | 추천인 1개월 무료 + 신규 1개월 무료 | cancellation flow §10.4 "save offer" 패턴 적용 |
| 연간 선납 | 2개월 무료 (concrete) | annual LTV +40~45%, involuntary churn -10~14x |

---

## 2. Retention 개입 (SDT/BCT/commitment)

### 2-A. 코호트 분석 이상의 retention 개입

**N2-3 현황**: cohort table (3·6·12개월 잔존율) + 이탈 위험 검출. 개입 수단 미정의.

**study 기반 개입 스택** (우선순위 순):

| 개입 | 메커니즘 | 효과 근거 | 구현 |
|---|---|---|---|
| **full onboarding flow** | 습관 + competence (SDT) | 6개월 retention 60%→87% (+45%) (Glofox) | 가입 후 7일: WOD 트래킹·PR 입력 완료 유도 |
| **코치 2회/월 연락** | relatedness (SDT) + social support (BCT) | -33% cancellation (Glofox) | 회원 휴면 14일 감지 → 코치 SMS/카카오 자동 안내 |
| **group class 등록 유도** | conjunctive Köhler + group cohesion | -56% cancellation vs equipment-only (Keepme) | WOD 참가 기록 없는 회원 → 그룹 클래스 초대 push |
| **다중 discipline 확장** | multi-discipline -60% churn | Peloton PYMNTS 2026 | 단일 WOD만 → 벤치마크·Open 참여 유도 |
| **commitment contract** | Royer NBER: incentive+commitment만 1년+ 지속 | NBER w18580 | 6개월 선납 + 출석 목표 설정 (이탈 시 미달성 명시) |
| **milestone badge** | identified regulation → intrinsic (SDT §8.1 Fortier) | PMID 22385751 | 출석 30·90·365일 자동 배지 |

**안티 (study 명시)**:
- incentive 단독: Royer — 프로그램 종료 시 decay. commitment 없이 "1개월 무료" 쿠폰만 → 효과 소멸.
- 가격 인하로 churn 해결: RevenueCat 2025 — 사용 부족(37%) > 비용(35%). engagement 먼저.
- "social feature만 추가": Peloton 격차는 *engaged* 사용자 한정. 비참여자는 그대로.

### 2-B. 이탈 위험 알고리즘

```python
# 위험 신호 (study 근거)
RISK_SIGNALS = {
    "no_checkin_14d": 0.4,      # Glofox: 2주 미출석 = 이탈 신호
    "no_wod_score_30d": 0.3,    # CrossFit 특화: WOD 기록 없음
    "payment_failed_once": 0.2, # involuntary churn 전조
    "single_discipline": 0.1,  # Peloton: 다중 discipline이 -60% churn
}
# 합산 > 0.5 → 이탈 위험 HIGH → 코치 SMS + 할인 제안
# 합산 > 0.8 → 코치 전화 + cancel flow save offer (15~30% 회수)
```

---

## 3. 한국 노무·세무 — 코치 정산 정밀화

### 3-A. 일용직 vs 정규직 코치 분리

**labor-office study 기준**:

| 구분 | 일용직 코치 | 정규직·프리랜서 코치 |
|---|---|---|
| 정의 | 동일 고용주 3개월 미만 (건설 1년 미만, §2.1) | 3개월 이상 = 자동 일반근로자 전환 |
| 갑근세 | (일급 - ₩150,000) × 2.97% (§3.1) | 종합소득세·사업소득세 (별도) |
| 4대보험 | 산재·고용 1일 이상 의무. 국민·건강은 월 8일/60h 이상 (§4.1) | 전원 의무 |
| 소액부징수 | 일급 ≤ ₩187,037 → 세금 0 (§3.5) | 해당 없음 |

**구현 권고**:
- 코치 등록 시 "고용 유형" 필드: `일용직` / `정규직` / `프리랜서(3.3%)`
- 일용직: `income_tax(daily_wage)` 함수 자동 적용 (labor-office §8.1 코드)
- 3개월 경과 알림: "이 코치는 일반근로자 전환 대상입니다 — 계약 검토 필요"

### 3-B. 코치 시급 정산 표준

| 항목 | 산식 | 법적 근거 |
|---|---|---|
| 기본 시급 | ≥ 2026 최저시급 ₩10,320 | 최저임금법 |
| 일급 | 시급 × 8h | §2.1 1공수=8h |
| PT 1회 (60분) | 별도 계약 (최저 ₩10,320 보장) | |
| 야간 수업 (22~06시) | 기본 × 1.5 (5인 이상 박스) | §2.3 가산률 |
| 주휴수당 | 주 15h 이상 시 1일분 추가 | §55 |

**두루누리 지원**: 10인 미만 박스 + 월보수 ₩270만 미만 신규 코치 → 고용·국민연금 **80% 지원** 자동 안내 (§4.4).

### 3-C. 박스 정산 주기

**권고**: 코치 정산은 "매월 1회 이정한 날짜" 의무 (근로기준법 §43 §5.1). 우리 시스템에서 박스별 "정산일" 설정 + 전월 PT·WOD 지도 집계 자동 계산.

---

## 4. 여성 WTP 반영 가격 차별 (윤리 검토 포함)

### 4-A. study 수치

- 미국 여성 헬스장 월 지출 중앙값 $50 (Statista IHRSA, §5.1)
- 미국 millennial 여성 beauty+fitness+wellness 통합 $115/월
- McKinsey "Maximalist" (25% 인구) 여성 압도 — $150+/월 WTP
- Boutique fitness (CAGR 10.9%) 여성 참여자 **77%** (§5.3)
- 여성 group exercise 동기 1위: **사회적 연결 57%** (Glofox, §5.1)

**한국 적용 주의**: 영문 Tier 1+2 기반 글로벌 수치. 한국 부산 동일 적용은 위험 (§5.4 boundary).

### 4-B. 가격 차별 윤리 검토

**적용 가능한 패턴**:

| 패턴 | 적법성 | 추천 |
|---|---|---|
| 성별 기반 직접 차별 ("여성 ₩10,000 할인") | 한국 남녀고용평등법·소비자기본법 위반 우려 | **금지** |
| 그룹 클래스 별도 tier (여성 선호 높음) | 합법 — 서비스 유형 차별 | **권고** |
| "커플 패키지" "패밀리 패키지" | 합법 | 권고 (Peloton Multi-discipline 효과 동시 달성) |
| 아침/저녁 클래스 할인 (수요 기반) | 합법 — KKT cost passthrough 포함 시 | 신중 적용 |
| 여성 전용 WOD 리더보드 별도 운영 | 합법 — 기능 차별 아님 | **권고** (Salci 2025: women-only 환경 선호) |

**최종 권고**: 성별 직접 가격 차별 금지. 대신 **그룹 클래스 tier**, **커플/패밀리 패키지**, **여성 전용 리더보드** 로 여성 WTP 간접 포착.

---

## 5. NPS·LTV·CAC 정밀 모델

### 5-A. 현행 PHASE3 §9.2 모델의 한계

```
현행: 박스당 $50/월 × N박스 = 단순 산식
문제: LTV·CAC·churn elasticity 미반영
```

### 5-B. 정밀 LTV 모델 (study §4.2 + §10.2 기반)

**기본 가정** (글로벌 boutique 벤치마크 적용):

| 변수 | 값 | 근거 |
|---|---|---|
| 박스 월 churn (목표) | <5% | subscription-fitness §4.2 |
| 박스 월 churn (현실적) | 7~8% (초기) | boutique 헬스장 연 20~30% / 12 |
| 연간 플랜 churn | 3~4% (월 환산) | pricing §10.2 annual 12-month retention 92% |
| LTV (월간 플랜) | 평균 ~14개월 (68% 12mo retention) | Baremetrics T2 |
| LTV (연간 플랜) | 평균 ~40개월 | pricing §10.2 |

**LTV 계산 (₩ 기준, 박스당)**:

```
월간 플랜 박스:
  ARPU = ₩100,000/월 (안전 추정, $50→₩70K + 마진)
  평균 수명 = 1 / 0.07 = 14.3개월
  LTV = ₩100,000 × 14.3 = ₩1,430,000

연간 플랜 박스:
  ARPU = ₩90,000/월 (10% 할인)
  평균 수명 = 1 / 0.035 = 28.6개월
  LTV = ₩90,000 × 28.6 = ₩2,574,000 (+80% vs 월간)
```

**CAC 추정**:
- 직접 영업 (onboarding 1회 = 30분): 인건비 ₩50,000~100,000/박스
- 추천 프로그램: 추천 박스 1개월 무료 ₩100,000 = CAC
- LTV:CAC 목표 >3:1 → CAC 한도 ₩430,000~858,000 (월간 기준)

### 5-C. grandfathering 전략 (pricing §10.1)

Netflix 2011 vs 2023 비교:
- 2011 (surprise, no grandfather): 17.8% churn
- 2023 (grandfathered + ad tier): ~3% churn

**Phase 3→4 가격 인상 시 의무 적용**:
1. 기존 박스: 6~12개월 grandfather (현행 가격 유지)
2. 신규 박스: 인상 가격 즉시 적용
3. "인상 이유" 기능 추가 명시 (KKT: cost passthrough OK)

### 5-D. 박스 NPS → LTV 상관 모델

```
NPS 60+ 박스:
  - 추천 프로그램 전환율 추정 5~10%/박스
  - 1박스 NPS 추천 → 0.05~0.1박스 신규 (CAC ₩100K)

NPS <30 박스:
  - churn 위험 3x (churn 21% annualized)
  - 분기 NPS 측정 + 이탈 인터뷰 의무화
```

### 5-E. Freemium/Trial 전환 전략 (pricing §13.2)

```
30일 무료 trial (endowment effect 극대화):
  - B2B SaaS trial→paid 중앙값 39.9% (운동 앱, RevenueCat 2025)
  - Trial 17~32일 conversion 45.7% (vs ≤4일 26.8%)
  → 21일 trial 권고 (17~32일 sweet spot)

3-tier cancel flow (pricing §10.4):
  1. 해지 클릭 → save offer: 1개월 50% 할인 제안 (15~30% 회수)
  2. 거절 → downgrade: 기능 제한 플랜 제안 (~15% 선택)
  3. 거절 → 탈퇴 확인 + 재가입 링크 이메일
```

---

## 6. Study 인용

| 주제 | 출처 | 적용 |
|---|---|---|
| Annual vs Monthly churn | Baremetrics 1,850 sites (pricing §10.2) | 연간 플랜 LTV +40~45% |
| Netflix grandfathering | NBC/CNN/SEC (pricing §10.1) | 가격 인상 시 grandfather 의무 |
| Concrete framing "2개월 무료" | RevenueCat 2025 (subscription-fitness §7.2) | +45% revenue vs "20% 할인" |
| 3-tier decoy | Orbix Studio (subscription-fitness §7.2) | mid-tier +28% |
| Trial 17~32일 sweet spot | Business of Apps 2026 (subscription-fitness §7.1) | 21일 trial 권고 |
| Cancel flow save offer | Rework.com (pricing §10.4) | 15~30% 해지 위험 계정 회수 |
| Onboarding 6mo retention | Glofox 2026 (subscription-fitness §4.3) | 60%→87% (+45%) |
| 코치 연락 -33% cancellation | Glofox 2026 (subscription-fitness §4.3) | 휴면 14일 자동 알림 |
| Royer commitment+incentive | NBER w18580 (subscription-fitness §8.1) | 6개월 선납 + 출석 목표 |
| Köhler group effect | Feltz 2012 RCT d≈1.1 (subscription-fitness §6.1) | 그룹 WOD 참여 유도 |
| Multi-discipline -60% churn | Peloton PYMNTS 2026 (subscription-fitness §4.1) | WOD+벤치마크+Open 유도 |
| Pain of paying | JEBO 2025 (pricing §5.1) | Toss 자동결제 기본값 |
| KKT fairness | AER 1986 (pricing §12.1) | 비수기 할인 OK, 성수기 인상 금지 |
| Charm→round 전환 | Wadhwa-Zhang JCR 2015 (pricing §11.1) | B2B round 가격 (₩100,000) |
| 갑근세 2.97% 실효 | 소득세법 §70의2 (labor-office §3.1) | 코치 일용직 정산 자동화 |
| 4대보험 의무 기준 | 4insure.or.kr (labor-office §4.1) | 코치 8일/60h 이상 건강·국민연금 |
| 두루누리 80% 지원 | 고용노동부 (labor-office §4.4) | 소규모 박스 코치 채용 인센티브 안내 |
| 여성 group동기 57% | Glofox 2026 (subscription-fitness §5.1) | 여성 전용 리더보드 + 그룹 tier |
| 여성 boutique 77% | ResearchAndMarkets (subscription-fitness §5.1) | 그룹 클래스 별도 tier 설계 |

---

## 7. 수정된 N2 Task List

### 기존 N2 task 유지 (재확인)

- [x] **N2-1 자동결제** — 유지. 단 Toss 빌링키를 **기본값 강제** + 계좌이체에 +10% 수수료 부과 추가.
- [x] **N2-2 PT 예약** — 유지. 단 마켓플레이스 연동 보류, 취소 정책 3단계 명확화 추가.
- [x] **N2-3 retention cohort** — 유지. 단 개입 스택 5개 (onboarding/코치연락/그룹WOD/다중discipline/commitment) 추가 구현 필요.
- [x] **N2-4 마케팅 dashboard** — 유지. NPS→LTV 상관 포함 정밀 모델 추가.
- [x] **N2-5 할인·쿠폰** — 유지. 성수기 인상 금지, 비수기 10% 할인 + "시즌 특가" concrete framing 적용.
- [x] **N2-6 회원 등급·loyalty** — 유지. SDT identified regulation 경로로 설계 (milestone badge).

### 신규 추가 task (study 기반 도출)

- [ ] **N2-7**. **연간/6개월 플랜 tier 설계** (anchor+decoy 적용)
  - 월간 ₩99,000 → 6개월 ₩529,000 → 연간 ₩899,000 3-tier
  - 연간 "2개월 무료" concrete framing (pricing §7.1)
  - 프라이싱 페이지 고가→저가 순서 노출 (anchor 효과)

- [ ] **N2-8**. **21일 trial + cancel flow 3단계**
  - 가입 시 21일 무료 (17~32일 sweet spot)
  - 해지 클릭 → 1개월 50% save offer → downgrade → 탈퇴 확인
  - 재가입 링크 자동 이메일 (30일 후)

- [ ] **N2-9**. **코치 일용직 정산 자동화** (labor-office §8.1 코드 통합)
  - 코치 유형 등록: 일용직/정규직/프리랜서
  - 갑근세 자동 계산 (일급 - ₩150,000) × 2.97%
  - 3개월 경과 알림 (일용직→일반근로자 전환)
  - 두루누리 대상 박스 자동 감지 + 안내

- [ ] **N2-10**. **이탈 위험 자동 개입 (5점 scoring)**
  - 14일 미체크인 / WOD 미기록 / 결제 실패 / 단일 discipline / 코치 연락 0회 → 위험 점수
  - 점수 >0.5: 코치 SMS 자동 안내 발송
  - 점수 >0.8: 박스 사장에게 "이탈 위험 HIGH" alert + save offer 추천

- [ ] **N2-11**. **여성 그룹 클래스 tier 별도 설계**
  - 박스별 "그룹 클래스 패키지" 플랜 추가 (월간 기본 + 그룹 클래스 add-on)
  - 여성 전용 WOD 리더보드 (성별 별도, Salci 2025)
  - 커플/패밀리 패키지 (가족 2인 15% 할인)

---

## 8. 구현 우선순위 (MoSCoW)

| Priority | Task | 근거 |
|---|---|---|
| **Must** | N2-1 자동결제 기본값 강제 | involuntary churn 15~28% 차단 |
| **Must** | N2-7 3-tier 가격 설계 | LTV +40~45% (연간) |
| **Must** | N2-8 21일 trial + cancel flow | trial→paid 45.7% |
| **Must** | N2-9 코치 정산 자동화 | 법적 의무 (갑근세·4대보험) |
| **Should** | N2-3 retention cohort + N2-10 이탈 scoring | onboarding 6mo retention 60→87% |
| **Should** | N2-2 PT 예약 (취소 정책 포함) | 박스 운영 차별화 핵심 |
| **Could** | N2-11 여성 그룹 tier | 한국 granular 데이터 부재로 검증 후 |
| **Won't** | 마켓플레이스 연동 | ClassPass near-zero conversion 안티 |

---

*작성: sub-agent B (N2 비즈니스 모델 재검토) · 2026-05-23*
*인용 study: subscription-fitness.md (93 출처 Tier1 45%) + pricing.md (27 출처 Tier1 78%) + labor-office.md (80 출처 Tier1 62%)*
