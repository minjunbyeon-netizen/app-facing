# FACING — WOD Pacing Intelligence

> **CrossFit Games-Player 급 athlete 를 위한 페이싱 + 박스 통합 앱.**

일반 피트니스 / 다이어트 / 웰니스 앱이 아닙니다.
Rich Froning, Mat Fraser, Tia Toomey 세대의 도구입니다.

---

## 1. 페이싱 전략 — 시작하기 전에 알기

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

## 2. WOD 공지 — 박스 코치가 직접 게시

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

## 3. 쪽지 기능 — 코치-멤버 직접 통신

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

## 4. 숙제 기능 — 코치 처방 + 멤버 수행 기록

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

## 5. 업적 기능 — 결정론적 보상, 다크 패턴 없음

지속 동기 부여 시스템. **랜덤 보상 / 회복 결제 / Lv 차감 / FOMO 카피 전부 차단** (rules/gamification.md 화이트햇 7원칙).

### 5-1. Tier (5단계)
| Tier | 의미 | 색 |
|---|---|---|
| Scaled | Motivation | 회색 |
| RX | Discipline | 빨강 |
| RX+ | Discipline+ | 밝은 회색 |
| Elite | Obsession | 실버 |
| Games | Obsession (최상위) | 화이트 |

색상 단독 구분 안 함 — 라벨 + 아이콘 + 색 3중 신호 (WCAG 준수).

### 5-2. Engine Score 0~100 + Level 1~50
- 6 카테고리 (Power / Olympic / Gymnastics / Cardio / Metcon + Body) 가중 평균
- XP 소스 5종: 세션 / Streak / Tier / 주간 목표 / PR
- Lv 1~20 선형 (500 XP/Lv) → Lv 21~50 이차 곡선
- **Lv 차감 없음** — 비활성 사용자도 Lv 보존

### 5-3. Panel B 칭호 20종
| Rarity | 개수 | 예시 |
|---|---|---|
| Common | 6 | THE GRINDER (100 sessions), WEEKEND WARRIOR (주말 20회) |
| Rare | 8 | IRON LUNG (Engine 80+ 5회), RUNNER (5km sub-25:00) |
| Epic | 4 | HEAVY (BS 1RM 200kg+), THRUSTER LORD (Fran sub-3:00) |
| Legendary | 2 | PRINCIPAL (FS 1RM 150kg+), SNATCH KING (100kg+) |

해금된 칭호 1개 착용 → Profile 상단 노출.

### 5-4. 시즌 배지
CrossFit 시즌 (Open / Quarterfinals / Semifinals / Games) 동안 1회 이상 세션 시 자동 unlock. 매년 새 배지.

### 5-5. PR 자동 감지
같은 WOD 두 번째 완료 시 시간 단축되면 즉시 'PR' toast + heavy haptic. 백엔드 trigger 없이 클라이언트 추론.

### 5-6. Streak Freeze (Rest Pass)
주 1회 무료 'Freeze' 토큰 — 하루 빠져도 streak 보호. **사용자 자율 선택** (자동 차감 X). 매주 월요일 충전.

### 5-7. Engine Decay
30일+ 무측정 시 STALE 라벨 + 안내. 표시 점수만 -3%/30days 감산 (-20% cap), 원본 보존. 재측정 시 즉시 회복.

---

## 6. 사용자 흐름 (30초 요약)

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

## 7. 박스 / 멤버 / 코치 구조

| 역할 | 권한 |
|---|---|
| **혼자 사용자** (no-gym) | 페이싱 계산 / Engine 측정 / 업적. 박스 기능 잠금 |
| **박스 멤버 (Pending)** | 박스 가입 신청 후 코치 승인 대기. 다른 기능은 사용 가능 |
| **박스 멤버 (Approved)** | 코치 WOD 수신 / 인박스 수신 / 숙제 수행 / 박스 리더보드 |
| **코치 (Owner)** | WOD 등록·삭제 / 인박스 발송 / 숙제 부여 / 멤버 승인·거절 / 코치 대시보드 |

---

## 8. 무엇이 다른가

### 일반 피트니스 앱과의 차이
- **타깃**: Games-Player 급 (Scaled→Games 5 티어)
- **카피**: HWPO·NOBULL 톤 (명령형, 숫자 중심, 동기부여 공허 문구 금지)
- **디자인**: 다크 모드 전용, 흑백·전사·Obsession 컨셉, 이모지 0
- **언어**: 동작명·등급명·메트릭 영문 단독 (1RM / AMRAP / Metcon / Engine 그대로)

### 다크 패턴 차단 (rules/gamification.md)
- 랜덤 보상 (loot box) 금지
- 회복 결제 (스트릭 복구) 금지
- Lv 차감 패널티 금지
- 시간 한정 FOMO 금지
- 강제 리더보드 금지 (opt-in)
- 회피형 카피 ("100일 잃습니다") 금지
- 색상 단독 등급 표시 금지

### 데이터 정책
- 익명 device_id 기반 (이메일 의존 없음)
- 개인 진척 ↔ 공개 리더보드 분리 저장
- 비활성 시 데이터 보존 (Whoop / Garmin 패턴)

---

## 9. 디자인 한 줄

> **타이포 + 수치 중심. 사진·일러스트 없음. 검정 위 흰 글씨, 기준선 빨강.**

폰트 1종 (Pretendard) + 영문 헤드라인용 Bodoni Moda Italic.
컬러 9 토큰 + Tier 5색.
Pretendard variable axis 활용한 weight 그라데이션만, 그라디언트·다중 그림자 금지.

---

## 10. 현 상태 (2026-04-28)

- **플랫폼**: Android (MVP) — APK 직배포
- **백엔드**: Flask (services/facing/, localhost:5060 dev)
- **iOS**: Phase 4 예정
- **빌드**: 로컬 디버그 빌드 안정 (10 페르소나 시드 + 백엔드 E2E 회귀 통과)
- **앞으로**: FCM 푸시 / SNS 공유 카드 (텍스트는 완료, 이미지는 후속) / 영상 폼 분석 / Whoop·Garmin OAuth

---

## 한 줄로 다시

> **WOD 받자마자 분할 패턴 + 폭발 시점 + 예상 완주 시간 받고, 박스 코치가 보낸 WOD·숙제·노트를 한 앱에서 처리한다. Engine 측정으로 본인 수준 정량화, 칭호·Tier·시즌 배지로 동기 유지 — 다크 패턴 없이.**
