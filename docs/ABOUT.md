# FACING — WOD Pacing Intelligence

> **CrossFit Games-Player 급 athlete 를 위한 페이싱 + 박스 통합 앱.**

일반 피트니스 / 다이어트 / 웰니스 앱이 아닙니다.
Rich Froning, Mat Fraser, Tia Toomey 세대의 도구입니다.

---

## 1. 시장 기회

기존 시장:
- **일반 피트니스 앱** (MyFitnessPal · Strong · Nike Training Club) — 일반인용. CrossFit 전문성 부재.
- **CrossFit 전용 앱** (WODsmith · Sugarwod) — 기록 관리 중심. 페이싱·코치 도구 부재.

FACING 차별점:
- **WOD 시작 전 페이싱 전략** 산출 — 시장 최초.
- **박스 코치 ↔ 멤버 통합** — WOD 공지 / 쪽지 / 숙제 / 리더보드 한 앱에서 처리.
- **다크 패턴 없는 동기부여** — 엘리트 athlete 신뢰 확보 구조.

---

## 2. 페이싱 전략 — 시작하기 전에 알기

WOD 받자마자 **분할(Split) + 폭발 시점(Burst) + 예상 완주 시간** 을 즉시 산출합니다.

### 어떻게 동작하나
1. 본인 데이터 입력 (1RM · UB · 카디오 페이스)
2. 오늘 WOD 구성 (동작·횟수·중량 또는 프리셋)
3. 계산 — 1.8초 후 결과
4. 분할 패턴 + 어디서 터뜨릴지 + 왜 그런지 근거

### 예시
```
WOD: Fran (21-15-9 Thruster + Pull-up)
당신의 Tier: RX

분할 전략:
  Thruster: 11-7-3
  Pull-up:  21-15-9 (unbroken)

폭발 시점: Thruster 마지막 3개 + 마지막 라운드 전부
예상 완주: 4:35

근거:
  Thruster 1RM 95kg 기준 60% 비율 → 11-7-3 안정
  앞 2 라운드 페이스 보존 → 마지막 라운드 all-out 확보
```

화면 한 번에 모두 표시 — 헬멧 쓰기 전 30초 안에 전략 파악.

---

## 3. WOD 공지 — 박스 코치가 직접 게시

박스(Gym) 가입 시 **코치가 등록한 오늘의 WOD** 가 앱에 표시됩니다.

### 멤버 입장
- 오늘 WOD 미리 확인 (박스 도착 전에 페이싱 계산 가능)
- RX / Scaled / Beginner 3 버전 제공
- Scale Guide (변형 동작 안내)
- 댓글로 코치·동료와 소통
- 완료 후 시간·라운드 입력 → 박스 리더보드 자동 반영

### 코치 입장
- WOD 한 번 게시 → 박스 멤버 전체에 즉시 공유
- 어제 WOD 복제 + 수정 가능
- 라운드별 세부 (round-by-round) 입력
- 댓글·코치 피드백으로 실시간 지도

---

## 4. 쪽지 기능 — 코치-멤버 직접 통신

코치가 멤버에게 **개인 노트** 를 보낼 수 있습니다. 카카오톡식 인박스.

### 4 탭 분류
- **ALL** — 전체 받은 메시지
- **NOTES** — 일반 노트 ("어깨 컨디션 어때?")
- **ASSIGNMENTS** — 숙제 (다음 섹션 참조)
- **OUTBOX** — 코치 전용, 본인이 보낸 메시지

### 발송 옵션 (코치)
- **개인** — 1:1 멤버 지정
- **그룹** — 시간대별·실력대별 그룹 (예: 7AM Class)
- **전체** — 박스 모든 멤버

### 멤버 액션
- 읽음 / 수락 / 거절 / **Ask Coach** (질문 답장)
- 미읽음은 빨간 dot 으로 즉시 알림

---

## 5. 숙제 기능 — 코치 처방 + 멤버 수행 기록

코치가 멤버에게 **구조화된 운동 과제** 를 부여합니다.

### 과제 구성
- 동작 (예: Back Squat)
- 세트 × 횟수 (예: 5×5)
- 하중 단위: %1RM / RPE / kg / lb / sec/500m / tempo / feel
- 마감일 (단일 날짜 또는 윈도우)
- 대체 동작 (부상자용)
- 코치 의도 (rationale: "왜 이걸 하는가")

### 예시
```
COACH: 박지훈
MEMBER: 김도윤

ASSIGNMENT — Heavy Squat Day
  Back Squat 5×5 @ 80% 1RM
  Substitute: Front Squat (어깨 부상 시)
  Tempo: 3-1-1-0
  Rest: 180s 사이클

DUE: 2026-05-02
RATIONALE: Open 대비 leg drive 강화. 5주 누적 후 1RM 테스트.
```

### 멤버 수행
- 수락 → 완료 시 실제 수행 결과 입력 (actualLoad / actualReps / RPE)
- 코치가 피드백 작성 가능
- 거절 시 사유 (부상·일정 등) 명시

---

## 6. 업적 시스템 — 결정론적 보상, 다크 패턴 없음

지속 동기 부여 시스템. **랜덤 보상 / 회복 결제 / Lv 차감 / FOMO 카피 전부 차단**.

### 6-1. Tier 5단계
| Tier | 의미 |
|---|---|
| Scaled | Motivation |
| RX | Discipline |
| RX+ | Discipline+ |
| Elite | Obsession |
| Games | Obsession (최상위) |

라벨 + 아이콘 + 색 3중 신호 (WCAG 준수, 색약 사용자 보호).

### 6-2. Engine Score 0~100 + Level 1~50
6 카테고리 (Power · Olympic · Gymnastics · Cardio · Metcon + Body) 가중 평균.
**Lv 차감 없음** — 비활성 사용자도 보유 Lv 보존.

### 6-3. 칭호 / 시즌 배지 / PR / Streak Freeze
- **20종 칭호** (Common 6 / Rare 8 / Epic 4 / Legendary 2) — 결정론적 임계 (e.g., Engine 80+ 5회 → IRON LUNG).
- **시즌 배지**: CrossFit 공식 시즌 (Open / QF / SF / Games) 1회 이상 세션 시 자동 unlock. 매년 새 배지.
- **PR 자동 감지**: 같은 WOD 두 번째 완료 시 시간 단축되면 즉시 알림.
- **Streak Freeze**: 주 1회 무료 'Freeze' 토큰. 사용자 자율 선택. 회복 결제 X.

---

## 7. 사용자 흐름 (30초 요약)

```
1. 앱 실행 → Splash → Intro (3 페이지, 처음 1회)
2. Sign in (네이버 / 카카오 / 데모)
3. 본인 입력
   - 체중 · 키 · 나이 · 성별 (필수)
   - 1RM · UB · 카디오 (아는 것만)
4. Engine 측정 → Tier 부여
5. 메인:
   a. Calc 탭   → WOD 직접 입력 → 페이싱 전략 받기
   b. WOD 탭    → 박스 가입 → 코치 WOD 받기
   c. Trends 탭 → Engine 추이 + 업적 갤러리 + Panel B 칭호
   d. Attend 탭 → 캘린더 + Streak + 챌린지
   e. Profile 탭 → Tier · 기록 · 인박스 · 박스 정보
```

---

## 8. 박스 / 멤버 / 코치 구조 (양방향 lock-in)

| 역할 | 권한 | 비즈니스 가치 |
|---|---|---|
| **혼자 사용자** (no-gym) | 페이싱 · Engine 측정 · 업적 | B2C 진입점, 박스 가입 funnel |
| **박스 멤버 (Pending)** | 가입 신청 후 코치 승인 대기 | 멤버 ↔ 박스 양방향 lock-in 시작 |
| **박스 멤버 (Approved)** | 코치 WOD · 인박스 · 숙제 · 리더보드 | retention 극대화 |
| **코치 (Owner)** | WOD 등록 · 인박스 발송 · 숙제 · 멤버 관리 | B2B SaaS 기반 |

박스 멤버 retention ↑ → 코치 도구 의존도 ↑ → **양방향 lock-in**.

---

## 9. 무엇이 다른가

### 일반 피트니스 앱과의 차이
- **타깃**: Games-Player 급 (Scaled→Games 5 티어). "쉬운"·"편리한"·"누구나" 카피 차단.
- **카피**: HWPO · NOBULL 톤 (명령형, 숫자 중심, 동기부여 공허 문구 금지).
- **언어**: 동작명 · 등급명 · 메트릭 영문 단독 (1RM / AMRAP / Metcon / Engine) — 글로벌 확장 시 번역 비용 0.

### 다크 패턴 차단 (화이트햇 7원칙)
- 랜덤 보상 (loot box) 금지
- 회복 결제 (스트릭 복구) 금지
- Lv 차감 패널티 금지
- 시간 한정 FOMO 금지
- 강제 리더보드 금지 (opt-in)
- 회피형 카피 ("100일 잃습니다") 금지
- 색상 단독 등급 표시 금지

→ Duolingo · Strava 가 가는 길 거부. 엘리트 athlete 는 **속이는 앱** 을 신뢰하지 않음.

---

## 10. 한 줄로 다시

> **WOD 받자마자 분할 패턴 + 폭발 시점 + 예상 완주 시간 받고, 박스 코치가 보낸 WOD·숙제·노트를 한 앱에서 처리한다. Engine 측정으로 본인 수준 정량화, 칭호·Tier·시즌 배지로 동기 유지 — 다크 패턴 없이.**
