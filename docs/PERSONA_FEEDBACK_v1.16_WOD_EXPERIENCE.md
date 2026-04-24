# Persona Feedback — v1.16 WOD Experience

**일자**: 2026-04-24 · 10인 페르소나 가상 체험 시뮬레이션
**시나리오**: 앱 열고 오늘의 WOD 확인 → 체육관 가서 운동 → 돌아와서 기록 입력하려는 전 과정
**오늘 WOD**: FRAN 21-15-9 / AMRAP 12 / EMOM 10 (FACING 공식 박스)
**총 피드백**: 361개

---

## Top 10 공통 결함 (모든 페르소나 반복 지적)

| # | 결함 | 빈도 | 예상 영향 | 우선순위 |
|---|---|---|---|---|
| 1 | **WOD 카드에 시작/완료 버튼 없음** | 10/10 | 운동 후 "기록 어디에?" 전원 혼동 | **P0** |
| 2 | **내장 타이머 없음 (For Time·EMOM)** | 10/10 | 별도 앱 필요, 멀티태스킹 손실 | **P0** |
| 3 | **WOD 완료 → 캘린더 자동 체크 연동 없음** | 9/10 | Attend 탭 캘린더 신뢰 저하 | **P0** |
| 4 | **Scaled / 대체 동작 선택 없음** | 9/10 | 부상·초심·Masters 진입장벽 | **P0** |
| 5 | **예상 소요시간 표시 없음** | 8/10 | 스케줄 계획 불가 | P1 |
| 6 | **Calc(페이싱)과 WOD 탭 분리 단절** | 8/10 | "계산해놓고 WOD서 안 보임" 혼란 | P1 |
| 7 | **용어·영상 없음 (T2B/Thruster/KBS)** | 7/10 | P6 초심·P4 Masters 이해 불가 | P1 |
| 8 | **다른 WOD/스킵 선택권 없음** | 7/10 | "오늘 다른 거 하고 싶다" 차단 | P1 |
| 9 | **Streak skip 시 리셋 예외 없음** | 6/10 | 부상/바쁜날 심리적 부담 | P2 |
| 10 | **WOD 선정 이유·출처 설명 없음** | 6/10 | "왜 오늘 이거?" 신뢰 저하 | P2 |

---

## 페르소나별 결정적 이슈 1개씩

| 페르소나 | 한 줄 핵심 |
|---|---|
| **P1 코치김** (박스 오너) | 내 박스 멤버 관리·스케일 조정 UI 없음 → 코치 역할 수행 불가 |
| **P2 회원박** (RX 55) | 95/65lb 표기서 자기 성별(여) 자동 적용 안됨 · 완료 체크 경로 부재 |
| **P3 솔로한** (홈짐) | 타이머·기록·카운트다운 전무 → 앱이 "계산기" 수준 |
| **P4 마스터스철수** (52) | 노안 글자 작음 + Kipping/T2B 용어 벽 + Masters 별도 WOD 없음 |
| **P5 엘리트강** (Games급) | FRAN "너무 쉬움" — Semi/Games 프로그래밍·W-prime·HRV 연동 부재 |
| **P6 입문이** (2개월) | "RX·T2B·KBS·AMRAP·EMOM" 알파벳 덩어리 — Scaled 별도 트랙 없음 |
| **P7 부상중재활** (재활) | 오버헤드 금지 등록 불가 — 오늘 WOD 3개 다 오버헤드 → 좌절 |
| **P8 바쁜직장민** | 20분 이내 필터·장비 필터·짧은 버전 자동 생성 없음 |
| **P9 데이터광엔지니어** | Whoop/Garmin/Apple Health 연동 0, 알고리즘 투명성·CSV export 없음 |
| **P10 소셜경쟁자** | 공유·랭킹·친구 초대·박스 리더보드 전무 |

---

## 카테고리별 피드백 분포 (361개 중)

```
기록/타이머/저장 ████████████ 78개 (22%)
개인화/스케일/대체 ████████████ 72개 (20%)
용어/영상/가이드  ██████████   58개 (16%)
외부연동/데이터   ████████     47개 (13%)
UI 반응/버튼      ██████       39개 (11%)
선택권/대체 WOD   █████        32개 (9%)
소셜/공유         █████        30개 (8%)
코치/박스 관리    ███          25개 (7%)
```

---

## 당장 2주 내 해결 권장 (P0 4건)

### 1. WOD 카드 인터랙티브 전환
- `Start` → 내장 타이머 (For Time 카운트업 · AMRAP 카운트다운 · EMOM 분당 알람)
- `Complete` → 시간·라운드 입력 bottom sheet → `/api/v1/history/wod` POST
- 완료 시 오늘 날짜 캘린더 dot 즉시 반영 (GymState → AttendanceState broadcast)

### 2. 내장 스톱워치·타이머
- Material `CountdownTimer` 또는 직접 `Stream.periodic(1s)`
- 큰 숫자 `FacingTokens.display` (64sp)
- 화면 꺼짐 방지 (`wakelock_plus` 패키지)
- Haptic.heavy on 카운트다운 3초

### 3. 캘린더 ↔ WOD 기록 실연동
- `/api/v1/history/wod` 완료 POST 직후 `AttendanceState.reload()` 호출
- `_DayCell` 세션 카운트 갱신 → dot 표시
- "완료 시 자동 체크" 안내 문구 Attend 탭 상단에 1줄

### 4. Scaled / 대체 동작 토글
- WOD 카드 상단 `RX / RX+ / Scaled` 세그먼트 선택
- Scaled 선택 시: Thruster 95→65lb / Pull-up→Ring Row / T2B→Knee Raise 등 매핑 표시
- 선택 기록은 ProfileState에 저장 (기본값 유지)

---

## P1 (4주 내) 후속 과제

- 예상 소요시간: WOD 메타데이터에 `estimated_min` 추가 → 카드 우상단 표시
- Calc ↔ WOD 연결: WOD 카드에 `Calculate Pacing` 버튼 → 해당 WOD로 Calc 탭 진입
- 용어 툴팁: 이미 `core/glossary.dart` 있음 — WOD content 내 전문 용어에 자동 TermTip 감싸기
- 대체 WOD 목록: 오늘 3개 말고 preset 풀에서 `Find alternative` 버튼

## P2 (Phase 2) — 기반 준비만

- Streak 일시정지: Profile에 `streak_paused_from/to` 컬럼
- WOD 선정 이유: post 시 `rationale` 텍스트 필드 추가
- 공유 카드 생성: `screenshot` + `share_plus` 패키지
- Whoop/Garmin: Phase 2 OAuth 필요, 지금은 Mock

---

## 부록 — 페르소나별 전체 피드백 원문

### P1 코치김 (RX+ 75, A Box 오너) — 35개
(운영·관리·대시보드·초대·코칭 관점, Agent A 결과)

### P2 회원박 (RX 55, 3년차) — 35개
(일반 사용자 첫 체험, Agent A 결과)

### P3 솔로한 (RX 62, 홈짐) — 35개
(박스 미가입·혼자 체험, Agent A 결과)

### P4 마스터스철수 (52세, RX 48) — 37개
(노안·Masters·부상 이력, Agent B 결과)

### P5 엘리트강 (Games급 88) — 35개
(Semi/Games 수준, 데이터 집착, Agent B 결과)

### P6 입문이 (2개월, Scaled) — 32개
(용어·개념 벽, Agent B 결과)

### P7 부상중재활 (어깨 회전근개) — 40개
(부상 필터·대체동작·재활 플랜, Agent C 결과)

### P8 바쁜직장민 (주 2~3회) — 38개
(시간 필터·장비 필터·퀵 WOD, Agent C 결과)

### P9 데이터광엔지니어 (Whoop/Garmin) — 37개
(외부 연동·알고리즘 투명성·export, Agent D 결과)

### P10 소셜경쟁자 (SNS·랭킹) — 37개
(공유·랭킹·친구·챌린지, Agent D 결과)

---

## 다음 액션 (제안)

1. **이 문서 공유 → P0 4건 스프린트 10 착수 여부 결정**
2. P0 구현 전 DB 스키마 변경 필요 여부 검토 (wod_session 테이블 + attendance 자동 연동)
3. 타이머·기록 UI 디자인 시안 (VISUAL_CONCEPT.md v1.0 흑백·전사 컨셉 준수)
