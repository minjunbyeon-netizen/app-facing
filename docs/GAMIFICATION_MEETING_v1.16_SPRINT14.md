# Gamification Expert Panel — Meeting Minutes
**일자**: 2026-04-25 · 사회자: Lead Architect
**참석 전문가**:
- **Panel A**: Level System Designer (LoL/Overwatch/SC2 MMR 경력)
- **Panel B**: Title/Badge Designer (배그 치킨디너·카톡 닉네임·Discord Roles 경력)
- **Panel C**: Fitness Daily Engagement Designer (Strava·Duolingo·Nike Run Club 경력)

---

## 🎯 안건
1. Trends 탭에 **레벨(Level) 시스템** 도입
2. 기존 **Achievement 15배지 → 칭호(Title)** 재설계
3. CrossFit 맥락 게이미피케이션 전반

---

## 🗣 Panel A 핵심 의견 (Level System)
- **Tier vs Level 엄격 분리**: Tier=실력(Engine), Level=헌신도(누적 세션). PVP/PVE 구조 차용.
- **XP 공식**: 세션 +100 · PR +250 · Streak +50/일 · 주 챌린지 +300 · Tier 승급 +500
- **레벨 범위 1~50**: 초반 선형 (Lv1~20) + 후반 이차곡선 (Lv21~50). 총 약 12개월 Lv50 도달.
- **Decay**: 비활성 90일 후 월 5%, Level 자체는 유지
- **시즌 리셋 반대** — CrossFit 문화상 연간 경력 누적이 자연스러움. 대신 분기별 시즌 "배지"만 신설.
- **위험 경고**: Tier/Level 혼동, XP farming, 형식적 세션 반복 — 공식 설명 + 일일 한도 + PR 가중치로 완화.

## 🗣 Panel B 핵심 의견 (Title System)
- **칭호 착용 1 + 배지 컬렉션 N 이원 체계**: HWPO/Wodify 모범. 프로필 이름 옆 1개 착용, 나머지는 갤러리.
- **칭호 20개 제안**: 5 카테고리 (Tier 승급 4 · 볼륨 누적 3 · 성취 수치 3 · Streak 3 · PR/모멘텀 3 · Hidden 1 · 시즌 3).
- **희소성 분포**: Common 2 / Rare 6 / Epic 7 / Legendary 7 / Hidden 11개.
- **한글 칭호 + 영문 부제 병기**: "RX 기준. / RX Standard Achieved." · "백인 전사. / Century Achieved." — HWPO 명령형 마침표 톤.
- **Hidden 조건 5개 예시**: 365일 streak, 6 카테고리 동시 PR, 주간 무패 등. 커뮤니티 구전 유발.
- **시즌 칭호 3개** (Phase 2): Open Qualifier · Regionals Bound · Games Champion.
- **착용 UX**: Profile 프로필 영역 "WORN TITLE" 라인 + 모달 라디오 선택.

## 🗣 Panel C 핵심 의견 (Daily Engagement)
- **Streak 재정의 권고**: 주간 단위 (주 3회 이상 완료 주수 연속)로 변경. 일일 streak는 과훈련 유발.
- **Rest Day 시스템**: "Intentional Rest" 기록 버튼 → streak 깨지지 않음.
- **Streak Freeze / Mercy Day**: 월 최대 3회 아이템, 주 1회 재사용. "REST PASS" 네이밍.
- **Weekly Ritual 축하 모멘트**: 주간 목표 달성 시 confetti + haptic + "+50 XP" 플로팅.
- **Loss Aversion 알림 5개**: 일요일 저녁 경고, N주 연속 리셋 경고 등.
- **번아웃 방지**: 연속 7일 감지 → "Rest Day recommended" 팝업.
- **XP 배분 재검토**: Panel A와 상호 보완 — 세션 +10(기본 낮음), Weekly Goal +50, Milestone +100.

---

## ⚖️ 사회자 합의 (Sprint 14 실행 스펙)

### 결정 1 — Level 시스템 채택 (Panel A 기조 + 숫자는 B/C 절충)
- **Level 1~50 하이브리드 곡선**
- **XP 소스 (MVP)**: 세션 완료 +100 · 완료 Streak +50/일 · Tier 승급 +500 · 주 챌린지 +300
- **Level 공식**: `누적XP = 500 × L` (Lv1~20 선형) · `누적XP = 500 × L²/30` (Lv21~50 이차)
- **Decay 보류** (MVP): 비활성 처리는 실유저 데이터 쌓인 후 v2에서 결정
- **시즌 보류**: 연말 "Year-End Grind" 배지 하나만 v2에 예약

### 결정 2 — Achievement → 칭호(Title) 리라벨 (Panel B 기조)
- **기존 15개 catalog 유지** + **5개 신규 = 총 20개**
- **한글 칭호 필드 추가** (기존 영문 name 유지, Korean title 병기)
- **착용 1 + 컬렉션 N**: Profile 상단 WORN TITLE · Trends 탭 배지 갤러리 유지
- **희소성**: 기존 rarity 필드 유지 + Hidden 플래그 확대
- **시즌 3개 Phase 2로 연기**

### 결정 3 — Streak 재정의 보류 (Panel C 의견 일부만 수용)
- 일일 streak 유지 (redefine은 사용자 혼란 위험) — v2에서 재검토
- Rest Day / Mercy Day / 7일 번아웃 알림: **Phase 2로 연기**
- Weekly Goal 축하 모멘트: **이번 스프린트 구현** (Haptic + 토스트)

---

## 📋 Sprint 14 구현 범위 (이번 세션)

### MVP 1 — Level 시스템 (core/level_system.dart)
```dart
int xpForLevel(int level)   // L² 기반 누적 XP
int levelFromXp(int xp)     // 역산
int nextLevelXp(int xp)
int xpProgressInLevel(int xp)
int totalXp(int sessions, int streak, int tierNumber) // 합산 mock
```

### MVP 2 — Trends LEVEL 카드 (trends_screen.dart)
```
┌─────────────────────────────┐
│ LEVEL 12                    │
│ ████████░░░░░░ 62% · 340 xp │
│ next: Lv13 (550 xp remain)  │
│                              │
│ XP SOURCES                   │
│ · Sessions 20 × 100 = 2,000  │
│ · Streak 5d × 50 = 250       │
│ · Tier (RX) = 500            │
│ TOTAL 2,750 XP               │
└─────────────────────────────┘
```

### MVP 3 — 칭호 5개 신규 seed (backend/data/seed_achievements.py)
- `TITLE_POLYMATH` 만능 선수. / Complete Athlete. — 6 카테고리 ≥ 80 · Epic · Hidden
- `TITLE_OBSESSED` 집착하는. / 365 Day Obsession. — 365일 streak · Legendary · Hidden
- `TITLE_SCHOLAR` 분석가. / Data Scientist. — Overall ≥ 80 · Rare
- `TITLE_UNDEFEATED` 불패. / Weekly Undefeated. — 주간 모든 PR 갱신 · Legendary · Hidden
- `TITLE_RELENTLESS` 끝을 모르는. / Relentless Grind. — 100일 streak · Epic · Hidden
- + 기존 15개에 `korean_title` 컬럼 추가 권장 (지금은 프론트에 매핑만)

### MVP 4 — UI 리라벨
- `AchievementCard` 클래스는 유지, 표시 문자열만 `"칭호"` / `TITLE` / `칭호 보기`로
- Trends 탭 섹션 타이틀 `EARN` → `LEVEL & TITLES`

### MVP 5 — Profile 착용 칭호
- `features/profile/profile_state.dart` 에 `wornTitleCode` + `setWornTitle()` 추가
- `mypage_screen.dart` TIER SNAPSHOT 아래 "WORN TITLE" 라인 표시
- 탭 시 bottom sheet — 해금된 칭호 + 라디오 선택

---

## 🔴 Phase 2 로드맵 (다음 스프린트)

1. **Streak Freeze (REST PASS)** — 월 3회 · 주 1회 재사용
2. **Rest Day 기록 버튼** — 의도적 휴식 상태
3. **번아웃 경고 7일 감지**
4. **Weekly Goal Confetti + Haptic 축하 모멘트**
5. **시즌 배지 3개** — Spring Surge · Fall Grind · Year-End Warrior
6. **PR 자동 감지 + XP +250** (현재 mock)
7. **Level XP Decay** (90일+)
8. **공유 카드 (Tier 승급 / Streak 돌파 / PR)**

---

## 🚫 명시적 배제 (이번 분기 내 반영 안 함)

- Games Leaderboard 공식 연동 (Panel B 시즌 칭호 3개)
- SNS 자동 공유 카드 (Instagram Graph API)
- Streak 주간 단위 재정의 (Panel C 제안) — 사용자 혼란 위험
- 원격 코치 피드백 마켓플레이스
