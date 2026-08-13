# §8 Gym Membership Model
## FACING — B2C + B2B 양면 시장 설계

> 대상 독자: 투자자 (VC / Angel) · 내부 PM · 박스 Owner 파트너
> 작성일: 2026-04-28
> 버전: v1.1
>
> **v1.1 변경점**: ModeSelect 도입(Coach/Member/Solo)으로 가입 funnel 진입점 변동 반영. TL;DR 한 줄 / Approach mode↔role 매핑 표 + ModeSelect 진입점 / lock-in 표 첫 행 갱신 / Metrics Solo→Member 전환율 / Risks R6 / FAQ Q11~12 / Decisions D4.

---

## TL;DR

FACING의 비즈니스 모델은 **양면 시장 lock-in**으로 설계한다. B2C 진입점(혼자 사용자 = Solo 모드)이 박스 가입 funnel을 생성하고, 박스 코치(B2B SaaS)가 멤버 retention을 구동한다. 멤버가 이탈하기 어려울수록 코치가 FACING에 의존하고, 코치가 FACING을 쓸수록 멤버가 더 들어온다. 외산 경쟁사(TrueCoach · TrainHeroic)는 코치 전용 도구이며 한국 박스 운영 현실과 맞지 않는다. FACING은 멤버와 코치가 같은 앱 안에서 만나는 구조로 차별화한다.

v1.1 부터 Tier 직후 ModeSelect (Coach / Member / Solo) 1 화면으로 가입 funnel 분기점을 명시한다. Solo 사용자가 Settings 또는 Profile 진입점에서 Member 로 전환할 때마다 박스 가입이 시작된다 — 이 전환율(Solo→Member)이 lock-in 루프의 첫 dial 이다. **의사결정 요청사항은 §Decisions 4항 참조.**

---

## Problem

### 박스 코치 시각

한국 CrossFit 박스 코치는 오늘도 WOD를 카카오톡 단체방에 사진으로 올린다. 멤버 숙제는 Notion 템플릿에 따로 저장하고, 리더보드는 화이트보드에 손으로 적는다. 멤버 퍼포먼스 추이를 한 화면에서 보는 도구가 없다. TrueCoach는 월 $99 이상이고 영문 전용이다. TrainHeroic은 팀 스포츠 중심 설계로 CrossFit Box WOD 구조(AMRAP / EMOM / For Time) 지원이 불완전하다. 한국 박스 코치가 쓸 수 있는 한국어 SaaS 도구는 사실상 없다.

### 멤버 시각

박스 가입 이후 멤버는 코치에게 디지털로 말을 걸 방법이 없다. 숙제 피드백은 카톡 DM, WOD 공지는 단체방 사진, 기록은 내 메모장이다. WOD 시작 전 페이싱 전략을 계산할 도구도 없다. "오늘 Fran에서 Thruster를 몇 개씩 쪼갤까?" — 이 질문에 FACING 외에 답해주는 앱은 없다.

### 시장 구조 문제

기존 CrossFit 앱(Sugarwod · WODsmith)은 기록 관리 중심이다. 코치 도구(TrueCoach · TrainHeroic)는 멤버 앱이 없다. 두 계층이 분리된 채로 존재한다. FACING은 이 두 계층을 하나의 앱에서 연결한다.

---

## Tenets

우선순위 충돌 시 아래 순서로 결정한다.

1. **Games-Player 급만 타깃한다.** 일반인 funnel을 넓히기 위한 기능 타협은 없다. Scaled 입문자도 CrossFit 커뮤니티 안에 있는 한 포함 범위다.
2. **멤버 데이터는 멤버 소유다.** 박스 Owner도 개별 멤버의 1RM · Engine Score 원본에 접근할 수 없다. 집계(리더보드 순위 · 출석 통계)만 허용한다. 이 원칙이 없으면 멤버가 앱을 신뢰하지 않는다.
3. **리더보드는 opt-in이다.** 강제 공개 리더보드는 엘리트 athlete를 오히려 이탈시킨다. 리더보드 참여 여부는 멤버가 매 WOD마다 결정한다.
4. **코치 도구는 멤버 retention을 구동한다.** 코치가 인박스를 더 많이 쓸수록 멤버가 앱을 더 자주 연다. 코치 도구는 B2B 수익원이자 B2C retention 엔진이다.
5. **다크 패턴 없이 lock-in을 만든다.** 강제 알림 · 회복 결제 · FOMO 카피 없이 데이터 연속성과 코치 관계성만으로 retention을 확보한다.

---

## Approach

### 클라이언트 mode ↔ 백엔드 role 매핑 (v1.1 신규)

**모드는 UI 게이트, 권한은 백엔드 role**. 둘은 1:N 관계이며 사용자가 Settings 에서 자유롭게 바꿀 수 있다. 백엔드 권한은 영향을 받지 않는다.

| 클라이언트 mode (SharedPreferences `app_mode`) | 매핑되는 백엔드 role / gym_status | 의미 |
|---|---|---|
| Coach | `coach_owner` 또는 `admin` (debug) | 박스 운영자 화면 — WOD 게시 · 멤버 관리 · Coach Dashboard |
| Member | `member` (`approved` / `pending` / `rejected` 무관) | 박스 가입자 화면 — 코치 WOD 수신 · 노트 · 숙제 |
| Solo | `app_user` (no-gym) | 박스 미사용 — Calc · Trends · Attend · Profile 만 |

이 매핑은 PersonaSwitcher debug 흐름에서 자동 처리된다 (§7 Appendix). 일반 사용자는 ModeSelect 카드 탭으로 직접 선택한다. **백엔드 권한 escalation 위험 없음** — 예: Solo 사용자가 Coach 모드를 강제 설정해도 백엔드 role 이 `app_user` 라서 WOD 게시 API 가 거절한다(클라이언트 화면만 Coach UI 로 보임).

### 4 역할 구조

| 역할 | 상태 | 매핑 mode | 권한 | 비즈니스 가치 |
|---|---|---|---|---|
| **혼자 사용자** (no-gym) | app_user | Solo | 페이싱 계산 · Engine 측정 · 업적 · 기록 | B2C 진입점. 박스 가입 funnel 상단 |
| **박스 멤버 Pending** | pending | Member | 가입 신청 완료, 코치 승인 대기 | 양방향 lock-in 시작 지점. 이탈 비용 발생 |
| **박스 멤버 Approved** | approved | Member | 코치 WOD · 인박스 · 숙제 · 리더보드 전체 | retention 극대화. 이탈 비용 최고 |
| **코치 (Owner)** | coach_owner | Coach | WOD 등록 · 인박스 발송 · 숙제 · 멤버 관리 · 리더보드 집계 | B2B SaaS 수익원. 코치 도구 dependency 핵심 |

#### 상태 전이 흐름

```
[Splash → Tier 부여 → ModeSelect 분기]
    |
    +---- Solo 카드 탭 → app_user (혼자 사용)
    |         |
    |         | Settings → Mode → Member 변경 (또는 Profile 박스 검색 진입점)
    |         | 또는 ModeSelect 재진입 → Member 카드 탭
    |         v
    +---- Member 카드 탭 → FindGym (박스 검색 + 가입 신청)
    |         |
    |         v
    |     pending (코치 승인 대기)
    |         |
    |         | 코치 승인
    |         v
    |     approved (풀 멤버)
    |         |
    |         | 코치 거절 또는 멤버 탈퇴
    |         v
    |     rejected / app_user (원복)
    |
    +---- Coach 카드 탭 → CreateGym (박스 등록, 스킵 허용)
              |
              v
          coach_owner (스킵 시 박스 미등록 = 예비 코치)
```

**ModeSelect 진입점 (v1.1)**:
- 첫 가입 funnel: Tier 부여 후 자동으로 ModeSelect 진입. Solo / Member / Coach 1개 선택.
- Settings 진입점: Profile → Settings → MODE 행 → ModeSelect 재진입(`arguments: 'settings'`). 모드 변경 후 분기 화면 우회 → Settings 로 pop.
- Profile 박스 검색 진입점 (Member 모드 한정): Profile 탭 → "박스 검색" 카드 → FindGym (모드 변경 없이 가입만 진행).

Pending 상태에서 멤버는 아직 인박스·리더보드에 접근하지 못한다. 이 대기 구간이 기대감을 만들고, 코치가 승인함으로써 관계가 시작된다. **Coach 모드 + 박스 미등록(예비 코치)** 상태는 WOD 게시 권한이 없으며 CreateGym 화면을 다시 열어 등록할 때 비활성화 해제된다.

---

### 양방향 lock-in 메커니즘

#### B2C → B2B (멤버 retention이 코치 도구 의존도를 높인다)

| 멤버 행동 | 코치 효과 |
|---|---|
| ModeSelect Member 선택 → FindGym → 가입 신청 | 박스 멤버 pool 입수 → 코치 가입 신청 처리 권한 발동 |
| WOD 완료 후 기록 입력 | 리더보드 자동 갱신 → 코치가 화이트보드 불필요 |
| 숙제 수락 + 결과 입력 | 코치가 실시간 수행률 확인 가능 |
| Engine 측정 갱신 | 코치가 멤버 Tier 추이로 프로그래밍 조정 가능 |
| 인박스 질문 ("Ask Coach") | 코치 응답 채널 고정 → 카톡 DM 대체 |
| 리더보드 opt-in | 박스 커뮤니티 경쟁 구조 형성 → 멤버 출석률 상승 |

#### B2B → B2C (코치 도구 사용이 멤버 retention을 높인다)

| 코치 행동 | 멤버 효과 |
|---|---|
| WOD 게시 | 멤버가 박스 도착 전 페이싱 계산 → 앱 일일 사용 |
| 인박스 노트 발송 | 멤버 앱 열람 빈도 상승 (미읽음 dot) |
| 숙제 부여 | 마감일 기반 재방문 주기 형성 |
| 멤버 그룹 편성 (7AM Class) | 멤버 소속감 → 이탈 비용 상승 |
| 피드백 작성 | 멤버 코치 관계성 강화 → 타 박스 이동 비용 상승 |

#### lock-in 요약 공식

```
멤버 retention ↑  →  코치 도구 의존도 ↑  →  박스 FACING 구독 유지
박스 구독 유지    →  코치 WOD · 인박스 활성화  →  멤버 재방문 ↑
```

이 루프가 돌기 시작하면 박스 단위로 이탈이 어려워진다. TrueCoach 전환 비용 = 모든 WOD 기록 + 멤버 숙제 이력 + 리더보드 데이터 상실.

---

### 비즈니스 모델

#### B2C 구독 (개인)

| 플랜 | 가격 (안) | 포함 범위 |
|---|---|---|
| Free | 0원/월 | 페이싱 계산 · Engine 측정 · 업적 · 기록 이력 (무제한) |
| Pro | 4,900원/월 (안) | 고급 Engine 트렌드 분석 · 경쟁사 Engine 비교 · PR 알림 고급 설정 · 데이터 CSV 내보내기 |

> Free 범위를 충분히 넓게 잡는다. 핵심 기능 제한으로 유료를 강제하는 모델은 Games-Player 급 사용자에게 신뢰를 잃는다. Pro는 분석 레이어 추가 과금이지, 기본 기능 잠금이 아니다.

#### B2B SaaS (박스 단위)

| 플랜 | 가격 (안) | 포함 범위 |
|---|---|---|
| Starter | 49,000원/월 | 멤버 30명 이하 · WOD 게시 · 기본 인박스 (노트 발송) |
| Pro | 99,000원/월 | 멤버 무제한 · 숙제 · 그룹 메시지 · 리더보드 · 출석 통계 |
| Elite | 149,000원/월 | Pro + 멤버 Engine 집계 대시보드 · 코치 협업 (다수 코치) · 우선 지원 |

> TrueCoach 기준 $99/mo ≈ 145,000원. FACING Pro(99,000원)는 30% 저렴하고 멤버 앱이 번들로 포함된다. 한국 박스 코치에게 "TrueCoach 가격 - 멤버 앱 비용"이 FACING의 포지셔닝이다.

#### 수익 모델 요약

```
B2C Free  → 멤버 pool 확보 → B2B 박스 가입 funnel
B2C Pro   → ARPU 4,900원/월 · 부가 수익
B2B SaaS  → ARPU 49,000~149,000원/월 · 주 수익원
```

광고 없음. 데이터 판매 없음. 다크 패턴 없음.

---

### 데이터 경계 설계

| 데이터 | 멤버 본인 | 코치 (Owner) | 다른 멤버 |
|---|---|---|---|
| 1RM · Engine Score 원본 | 열람 O | 열람 X | 열람 X |
| 리더보드 순위 (opt-in) | 열람 O | 열람 O | 열람 O (같은 박스) |
| 출석 통계 (집계) | 열람 O | 열람 O | 열람 X |
| 숙제 수행 결과 | 열람 O | 열람 O (본인 부여 과제만) | 열람 X |
| 인박스 노트 | 열람 O | 발신자만 | 열람 X |

이 경계는 Tenet 2("멤버 데이터는 멤버 소유")를 기술 레벨에서 보장한다. 박스 코치가 멤버의 원본 Max 데이터에 접근하지 못하더라도 리더보드 순위와 출석 통계만으로 프로그래밍에 충분하다.

---

## Metrics

### 박스 단위 (B2B)

| 지표 | 측정 방법 | 목표값 (1년 내) |
|---|---|---|
| 박스당 활성 멤버 수 | approved 상태 멤버 DAU/MAU | 20명 이상 |
| 박스 코치 WOD 게시율 | 7일 내 WOD ≥ 3회 박스 비율 | 70% 이상 |
| 박스 구독 churn | 월 취소 박스 수 / 전체 박스 수 | 5% 이하/월 |
| 인박스 발송 빈도 | 코치 발송 노트 수 / 주 | 박스당 ≥ 5건/주 |

### 멤버 단위 (B2C retention)

| 지표 | 측정 방법 | 목표값 |
|---|---|---|
| D7 retention | 최초 Engine 측정 후 7일 내 재방문 | 40% 이상 |
| D30 retention | 최초 Engine 측정 후 30일 내 재방문 | 25% 이상 |
| pending → approved 전환율 | 가입 신청 후 7일 내 승인 완료 비율 | 70% 이상 |
| app_user → pending 전환율 | 혼자 사용자 중 박스 가입 신청 비율 | 목표 15% (3개월 내) |
| **Solo → Member 모드 전환율** | Solo 모드 사용자 중 30일 내 Member 모드로 전환한 비율 | **목표 ≥ 10% / 월 (lock-in dial)** |
| ModeSelect 분포 | 신규 가입 funnel 첫 모드 선택 비율 (Coach / Member / Solo) | Member 60~70% / Solo 25~30% / Coach 5~10% |
| Coach 박스 등록 스킵율 | Coach 모드 선택 후 CreateGym 스킵 비율 | < 60% (60% 초과 시 박스 등록 마찰 점검) |

### 비즈니스

| 지표 | 측정 방법 |
|---|---|
| B2B MRR | 박스 구독 수 × 플랜 단가 |
| B2C MRR | Pro 구독자 수 × 4,900원 |
| LTV:CAC | B2B = 12개월 구독 단가 / 영업 비용 |
| NRR (Net Revenue Retention) | 기존 박스의 upsell + downsell 합산 |

---

## Risks / Trade-offs

### R1. 박스 의존성 강화 시 혼자 사용자 이탈

lock-in을 박스 중심으로 설계할수록 no-gym 사용자가 기능 제한을 느낀다. 완화책: Free 플랜에서 페이싱 계산 · Engine 측정 · 업적을 완전 개방한다. 박스 없이도 핵심 가치를 소비할 수 있어야 funnel 상단이 살아있다.

### R2. 코치 도구 부재 시 lock-in 루프 미작동

인박스 · 숙제 · WOD 게시 기능이 완성되기 전까지 B2B 가치가 없다. Phase 1에서 B2B 고객을 유치하면 기능 부재로 조기 churn이 발생한다. 완화책: 얼리 박스 파트너 3-5곳과 베타 계약(무료 또는 대폭 할인)으로 기능 완성도를 함께 높인다.

### R3. 데이터 경계 설계 실수로 신뢰 붕괴

코치가 멤버 원본 1RM에 접근 가능하다는 인식이 퍼지면 멤버 이탈이 즉각 발생한다. 완화책: API 레벨에서 코치 role에 개인 데이터 엔드포인트 접근 차단. 집계 전용 엔드포인트만 허용. 이 결정은 초기 설계에서 고정해야 한다.

### R4. 박스 오너 진입 장벽 (IT 친숙도 낮음)

한국 CrossFit 박스 코치 상당수는 SaaS 도구 사용 경험이 없다. 카카오톡 → FACING 전환 마찰이 크다. 완화책: 온보딩 시 기존 카카오 단체방 → FACING WOD 게시 마이그레이션 1-click 도구. 초기 3개월 코치 전담 CS.

### R5. 가격 수용성 (한국 박스 규모)

한국 박스는 평균 멤버 20-40명, 월 매출 1,000-3,000만 원 수준(추정). 박스 SaaS 99,000원/월은 매출의 0.3-1% 수준으로 합리적이다. 그러나 명확한 ROI 제시가 없으면 예산 승인이 어렵다. 완화책: "멤버 1명 retention 연장 = 약 15,000원 이상 가치" 프레임으로 ROI 역산 자료 제공.

### R6. Solo 모드 영구화 → lock-in 루프 미작동 (v1.1 신규)

ModeSelect 도입으로 신규 사용자가 처음부터 Solo 를 선택할 수 있게 됐다. Solo 모드는 박스 미사용 화면이라 박스 가입 funnel 진입 마찰이 없지만, **Solo 사용자가 Settings 에서 Member 로 전환하지 않으면 lock-in 루프 자체가 시작되지 않는다.** Solo 비율이 50% 를 넘기면 B2C MRR 만 누적되고 B2B 박스 funnel 이 마르는 위험이 있다.

**완화책**:
- WOD 탭에 "박스 검색" 카드 영구 노출 (Solo 모드일 때 강조). 다크 패턴 없이 진입 경로만 노출.
- Profile 탭 박스 검색 진입점 강조 (Member 모드 변경 없이 FindGym 직접 진입 가능).
- Solo → Member 전환율 (월 ≥ 10%) KPI 미달 시 진입점 디자인 재검토 — 강제 알림이나 모달 차단 (Tenet 5 위반 회피).
- 얼리 박스 파트너 베타 기간에 Solo 사용자 인터뷰로 "박스 가입 안 하는 이유" 수집 (가격 / 위치 / 기존 박스 만족 등 분류).

### Trade-off: 멤버 무료 vs 코치 유료

멤버 앱을 완전 무료로 두면 B2C 수익은 포기하지만 멤버 pool이 빠르게 커진다. 멤버 pool이 커질수록 박스 코치의 FACING 수요가 증가한다. 초기에는 멤버 Free → 박스 유료 구조를 우선하고, B2C Pro는 후기에 도입한다.

---

## Roadmap

### 현재 (Phase 2 완료)

| 기능 | 상태 |
|---|---|
| 4 역할 (app_user / pending / approved / coach_owner) | 구현 완료 |
| 인박스 게이트 (approved + owner 만 활성) | 구현 완료 |
| WOD 게시 · 리더보드 · 멤버 관리 | 구현 완료 |
| 숙제 (Assignment) · 그룹 노트 | 구현 완료 |
| 업적 · Tier · Engine 측정 | 구현 완료 |

### Phase 3 (비즈니스 레이어 구축)

| 항목 | 내용 | 우선순위 |
|---|---|---|
| 박스 SaaS 결제 연동 | 토스페이먼츠 월 구독 | HIGH |
| 코치 온보딩 플로우 | 박스 생성 → WOD 첫 게시 → 멤버 초대 링크 3-step | HIGH |
| 멤버 박스 가입 funnel 강화 | 박스 검색 → 1-click 신청 → push 승인 알림 | HIGH |
| 얼리 박스 파트너 3-5곳 유치 | 6개월 무료 또는 50% 할인 베타 계약 | MEDIUM |
| 박스 대시보드 MVP | 멤버 수 · 출석률 · WOD 참여율 집계 | MEDIUM |

### Phase 4 (리더보드 + 분석 강화)

| 항목 | 내용 |
|---|---|
| 박스 간 리더보드 (opt-in) | 동의한 박스끼리 Engine Score 비교 |
| 코치 멤버 Engine 집계 | Tier 분포 · 카테고리별 약점 집계 (원본 미노출) |
| Whoop / Garmin 연동 | HRV · 회복 데이터 Engine 보정 |
| B2C Pro 론칭 | 고급 트렌드 분석 · CSV 내보내기 · 경쟁사 비교 |

### Phase 5 (글로벌 확장)

| 항목 | 내용 |
|---|---|
| 영문 전환 | UI 카피 이미 영문 중심 — 추가 번역 비용 최소 |
| 해외 박스 파트너 | 미국 · 호주 CrossFit 박스 B2B 영업 |
| Store 출시 | Google Play + App Store |

---

## FAQ

**Q1. TrueCoach · TrainHeroic 과 무엇이 다른가?**

TrueCoach와 TrainHeroic은 코치 전용 도구다. 멤버 앱이 없다. 멤버는 PDF 파일이나 링크를 통해 숙제를 확인하고 별도로 기록을 입력한다. FACING은 멤버와 코치가 같은 앱 안에서 만난다. 코치가 WOD를 게시하면 멤버가 그 WOD로 페이싱을 계산하고, 완료 후 기록이 리더보드에 자동으로 올라간다. 단일 앱 안에서 루프가 완결된다.

**Q2. Sugarwod 와 무엇이 다른가?**

Sugarwod는 WOD 완료 후 기록 관리 앱이다. "WOD 시작 전 페이싱 전략"을 산출하는 기능이 없다. FACING의 핵심 Wedge는 Split + Burst + 예상 완주 시간을 WOD 시작 전 1.8초 안에 계산하는 것이다. 코치 도구도 기본 WOD 게시 수준이다.

**Q3. 한국 박스가 월 99,000원을 낼 의향이 있는가?**

현재 한국 박스 코치가 Notion 유료($16/월) + 카카오톡(무료) + 화이트보드로 운영한다는 가정 하에 FACING의 대체 가치는 "시간 절약 + 멤버 retention"이다. 멤버 1명이 1개월 더 다니면 약 15,000원 이상의 추가 수입이다. 박스당 멤버 2명 retention 개선으로 구독료 회수가 가능하다. 이 프레임을 얼리 파트너 계약에 명시한다.

**Q4. 멤버 데이터 보안은 어떻게 보장하는가?**

API 레벨에서 역할(role) 기반 접근 제어로 분리한다. 코치(coach_owner) role은 집계 엔드포인트만 호출 가능하다. 개인 데이터 엔드포인트(profile/info · Engine Score 원본)는 본인 device_id 인증만 허용한다. 리더보드 데이터는 멤버 opt-in 시에만 집계 쿼리에 포함된다.

**Q5. 박스 없이 혼자 쓰는 사람은 왜 계속 쓰는가?**

페이싱 계산(Split + Burst) + Engine 측정(Tier 1~6) + 업적(칭호 20종 · 시즌 배지 · PR 감지 · Streak)은 박스 없이도 완전하게 동작한다. 혼자 사용자는 자신의 Engine 수준을 정량화하고, WOD 전략을 계산하고, 기록 추이를 추적하는 데 FACING을 쓴다. 박스 가입은 이 경험 위에 코치 관계성과 커뮤니티 경쟁을 더하는 레이어다.

**Q6. 리더보드를 강제로 공개하지 않는 이유가 무엇인가?**

엘리트 athlete는 퍼포먼스 수치를 민감하게 다룬다. Strava가 강제 공개로 일부 사용자를 이탈시킨 사례가 있다. FACING의 리더보드는 WOD 완료 후 "이번 기록 리더보드에 올리겠습니까?" opt-in 방식이다. 공개를 선택한 멤버만 리더보드에 표시된다. 이 원칙이 없으면 Games-Player 급 사용자가 앱을 신뢰하지 않는다.

**Q7. 박스가 FACING을 그만두면 데이터는 어떻게 되는가?**

멤버 개인 데이터(Engine · 기록 · 업적)는 박스 구독과 분리 저장된다. 박스가 FACING 구독을 중단해도 멤버의 개인 기록은 앱에 남는다. 이 설계는 멤버 이탈 방어이자, 박스 전환 시 멤버 데이터 인질 구조를 차단하는 윤리적 결정이다.

**Q8. Phase 3 결제 연동 전 수익화 계획은 무엇인가?**

얼리 박스 파트너 3-5곳과 6개월 무료 베타 계약을 체결한다. 이 기간에 코치 피드백으로 도구를 완성하고, 이탈률 · 사용 패턴 · 멤버 retention 데이터를 수집한다. 베타 종료 시 유료 전환 협상을 진행한다. B2C Pro는 이 데이터로 가격 검증 후 도입한다.

**Q9. 글로벌 확장 시 언어 문제는?**

현재 FACING의 모든 UI 핵심 라벨은 영문 단독으로 설계되어 있다(V8 원칙). 동작명 · 등급명 · 메트릭 모두 영문이다. 한글은 부연 설명(캡션) 레이어에만 존재한다. 글로벌 확장 시 한글 캡션 레이어만 교체하면 된다. 추가 번역 비용이 최소화된다.

**Q10. 경쟁 박스 앱이 유사 기능을 복제하면?**

페이싱 계산 알고리즘(Split + Burst)은 서비스 facing의 Engine 로직이며, 논문 · CGM · W-prime · 벤치마크 데이터 기반이다. 복제에 최소 12개월 이상이 걸린다. 멤버 Engine 이력 · 숙제 기록 · 박스 관계성 데이터는 FACING 안에 누적된다. 경쟁자가 기능을 복제하더라도 이 데이터 자산은 이전되지 않는다.

**Q11. Solo 사용자가 박스에 가입하면 어떻게 되는가? (v1.1)**

두 경로 모두 동등하게 동작한다:
1. Settings → MODE 행 → ModeSelect 재진입 → Member 카드 탭 → FindGym → 가입 신청
2. Profile 탭 박스 검색 진입점 → FindGym 직접 진입 → 가입 신청 (모드 자동 변경)

가입 신청 후 백엔드 `gym_status` 가 `pending` 으로 변경되고 클라이언트 mode 가 자동으로 `Member` 로 갱신된다. 기존 Solo 시절 데이터(Engine 이력 · 기록 · 업적)는 device_id 귀속이므로 유실 없이 그대로 유지된다. 코치 승인 후 `approved` 로 전환되면 인박스·리더보드가 활성화된다.

**Q12. Coach 모드를 선택했지만 박스를 등록하지 않으면? (v1.1)**

CreateGym 화면에서 Skip 또는 미입력 → "예비 코치" 상태로 Shell 진입. 클라이언트 mode 는 `Coach` 로 유지되지만 백엔드 `coach_owner` 권한이 없어 WOD 게시 API 가 거절한다. Coach Dashboard 화면은 "박스 등록 필요" 안내 카드만 표시. CreateGym 재진입 경로(Settings → 박스 등록 또는 Coach Dashboard 카드 탭)로 언제든 등록 가능. 데모 사용자 또는 박스 오픈 준비 중 코치를 위한 안전한 대기 상태.

---

## Decisions / Asks

| # | 결정 필요 사항 | 선택지 | 권장 |
|---|---|---|---|
| D1 | **B2C Pro 도입 시점** | Phase 3 동시 vs Phase 4 별도 론칭 | Phase 4. Phase 3에서 B2B 결제 먼저 안정화 후 B2C Pro 가격 검증 |
| D2 | **박스 SaaS 가격 구간 확정** | Starter 49K / Pro 99K / Elite 149K 안 vs 단일 플랜 99K | 얼리 파트너 베타 피드백 수집 후 결정. 단일 플랜부터 시작 권장 |
| D3 | **얼리 박스 파트너 선정 기준** | 서울 강남 / 성수 클러스터 vs 온라인 박스 vs 지방 거점 박스 | 서울 클러스터 우선 (밀도 높고 코치 네트워크 연결 빠름). 첫 3곳이 레퍼런스가 된다 |
| D4 | **Solo→Member 전환율 KPI 임계 (v1.1)** | 월 5% / 월 10% / 월 15% | **월 10%**. 미달 시 WOD 탭·Profile 탭 박스 검색 진입점 디자인 재검토(다크 패턴 없이). 월 5% 이하 지속 시 Solo 영구화 위험 신호 — 박스 검색 UX 또는 박스 공급(파트너 박스 수) 부족 진단 필요 |
