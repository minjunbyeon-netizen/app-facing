# Gamification v1.16 Proposal — Achievement System

> **Status**: 제안 단계 (설계 · 미구현). 사용자 컨펌 후 Sprint 착수.
> **Source**: `/go` 파이프라인 4-agent 리서치 (Haiku×2 + Sonnet×2).
> **CPO 판단**: 조건부 도입. Streak/Leaderboard 제외, 9개 이하로 컷.

---

## 핵심 원칙 (3줄)

1. **Achievement = "성취의 증거"**. 동기부여 도구 X. HWPO가 Earned 뱃지 달듯, 실제 수치 돌파의 기록.
2. **Profile 탭 부속 요소**. 앱 주목적은 Split·Burst 페이싱. Achievement는 History 하단 collapsed 섹션 1개가 최대치.
3. **명사구+마침표**. "Engine 80+." "PR. Snatch." "30 WODs." 2인칭·느낌표·감탄 전면 금지 (V5/V8).

---

## 채택 · 거부 매트릭스

| 메커니즘 | 채택? | 이유 |
|---|---|---|
| **Achievement 배지 9개** | 채택 (MVP) | 숫자 돌파 — CrossFit 언어. HWPO/Wodify 정합 |
| **Tier progression 배지** | 채택 (9개에 포함) | Scaled→Games 여정 = 앱 존재 이유 |
| **Hidden Legendary** | 채택 (3개) | Games 유저도 장기 목표 존재 |
| **PR Badge (카테고리 신기록)** | Phase 2 | prev_max 비교 로직 필요, MVP 복잡도 ↑ |
| **Streak (연속 일수)** | **거부** | Duolingo 연상. "Last active: W16" 중립 표기만 |
| **Level/XP/Chest/Heart** | **거부** | 유치. NOBULL이 절대 안 할 짓 |
| **Leaderboard (공개/박스)** | **거부** | Bullying 리스크 + 개인 기록 포지셔닝 충돌 |
| **Confetti/이모지/캐릭터** | **거부** | V4 이모지 금기 직접 위반 |

---

## 카탈로그 (9개 — CPO 컷 반영)

| # | code | name | desc | trigger | rarity | hidden |
|---|---|---|---|---|---|---|
| 1 | FIRST_ENGINE | First Measure. | 첫 Engine 측정 완료. | session_count ≥ 1 | Common | 0 |
| 2 | REACH_RX | RX Standard. | Tier RX 도달. | tier ≥ 3 | Common | 0 |
| 3 | REACH_RX_PLUS | RX+. | Tier RX+ 도달. | tier ≥ 4 | Rare | 0 |
| 4 | REACH_ELITE | Elite. | Tier Elite 도달. | tier ≥ 5 | Epic | 0 |
| 5 | REACH_GAMES | Games. | Tier Games 도달. | tier = 6 | Legendary | **1** |
| 6 | SCORE_80_OVERALL | 80 Overall. | Overall Engine 80 돌파. | overall_score ≥ 4.0 (→ 60/100) | Rare | 0 |
| 7 | SCORE_95_OVERALL | 95 Overall. | Overall Engine 95+ (Games급). | overall_score ≥ 5.75 | Legendary | **1** |
| 8 | ALL_CAT_80 | Complete Athlete. | 전 카테고리 Engine 80 동시 달성. | min(6 cats) ≥ 4.0 | Epic | **1** |
| 9 | WOD_50 | 50 WODs. | WOD 50회 계산. | wod_count ≥ 50 | Rare | 0 |

**Rarity 분포**: Common 2 · Rare 3 · Epic 2 · Legendary 2 · Hidden 3 (REACH_GAMES/SCORE_95/ALL_CAT_80)
**Elite/Games 전용 트랙**: #5, #7, #8 세 배지는 Games 수준에서만 해금 가능 → 장기 목표 역할

### 제외된 배지 (원 27개 → 9개)
- WOD count 10/100, Engine 10/50/100 세션: 누적 숫자 피로. 50 하나만 유지
- SCORE_60/80_ANY 카테고리 한계 돌파: `any ≥ N` 트리거는 균형 무시 → ALL_CAT_80로 대체
- SCORE_90_OVERALL: 95와 간격 좁음. 95 하나로 명확
- PR_POWER/OLYMPIC/GYMNASTICS/CARDIO: 전부 Phase 2
- JOIN_BOX / BOX_WOD_10 / BOX_MEMBERS_10: MVP에서는 박스 기능 자체가 신규 → 가입만으로 배지 획득은 스티커 느낌
- TIER_UP: 이미 REACH_RX~GAMES 4개가 티어별로 있음
- ALL_CAT_60: 60→80 중 하나. 80이 의미 있음
- ENGINE_10/50/100 세션: "100회 측정" 동기 약함

---

## 데이터 모델

```sql
-- 정적 카탈로그. 서버 코드 하드코딩 대신 DB로 — 운영 중 name/desc 수정 가능.
CREATE TABLE achievements_catalog (
    code          TEXT PRIMARY KEY,           -- 'FIRST_ENGINE'
    name          TEXT NOT NULL,              -- 영문 20자 이내
    description   TEXT NOT NULL,              -- 한글 2줄 이내
    trigger_type  TEXT NOT NULL,              -- 'engine_score'|'tier'|'session_count'|'all_categories'|'wod_count'
    trigger_value TEXT NOT NULL,              -- JSON: {"threshold":4.0,"category":"overall"}
    rarity        TEXT NOT NULL
        CHECK(rarity IN ('Common','Rare','Epic','Legendary')),
    is_hidden     INTEGER NOT NULL DEFAULT 0, -- 1 = 해금 전 목록 비노출
    sort_order    INTEGER NOT NULL DEFAULT 0
);

-- 해금 레코드. 미달성은 행 없음. progress 저장 안 함 (매번 재계산).
CREATE TABLE user_achievements (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    device_hash      TEXT NOT NULL,
    achievement_code TEXT NOT NULL REFERENCES achievements_catalog(code),
    unlocked_at      DATETIME NOT NULL DEFAULT (DATETIME('now')),
    context_json     TEXT,                   -- 해금 시점 스냅샷: {"score":4.2,"tier":"Elite"}
    CONSTRAINT uq_user_achievement UNIQUE(device_hash, achievement_code)
);

CREATE INDEX ix_ua_device ON user_achievements(device_hash);
```

**progress 저장 X**: engine_snapshots / wods 원천 데이터 충분. `/check` 호출 시 서버가 O(1) 쿼리로 재계산.

---

## API (2개 엔드포인트)

| method | path | 역할 | response |
|---|---|---|---|
| `GET` | `/api/v1/achievements` | 카탈로그 + 내 해금 + 미달성 progress | `{catalog:[...], unlocked:[{code, unlocked_at}], progress:{code: pct}}` |
| `POST` | `/api/v1/achievements/check` | 서버가 현재 상태 스캔 → INSERT OR IGNORE → 신규 unlock만 반환 | `{newly_unlocked:[{code, name, rarity}]}` |

**자동 호출 정책**
- Grade 화면 계산 직후: 호출 (계산 결과가 trigger)
- WOD 저장 완료: 호출
- Profile 탭 진입: 세션당 1회 (10분 로컬 캐시)
- 콜드스타트: 호출 안 함 (초기 로딩 지연 방지)

---

## UI 통합 지점

### Profile 탭 — ACHIEVEMENTS 섹션 (기본 collapsed)
```
┌──────────────────────────────────────────┐
│  ACHIEVEMENTS         4 / 6 unlocked  ▸  │  ← 탭해서 펼침
└──────────────────────────────────────────┘
```
펼친 상태:
```
┌────────────────────────────────────────┐
│ ELITE                            EPIC  │  ← Tier 색 2px left-border
│ Tier Elite 도달.                        │
│                           2026-01-03   │
├────────────────────────────────────────┤
│ 80 OVERALL                       RARE  │
│ Overall Engine 80 돌파.                 │
│                           2026-02-14   │
└────────────────────────────────────────┘

  Show locked (2)  ← opt-in 버튼. 미달성 3개는 hidden=0만 노출
```

### Grade 화면 — unlock toast (3초 자동 소멸)
```
┌───────────────────────────────┐
│ ▮ 80 Overall. Logged.         │  ← left-border accent 4px
└───────────────────────────────┘  ← 이모지/confetti/사운드 없음
```
복수 unlock 시 0.5초 간격 스택.

### Trends 탭 — 변경 없음 (MVP)
streak dot pill 는 Phase 2.

---

## 시각 언어

- **카드**: 텍스트 전용. 아이콘 없음. Rarity 색 border만.
  - Common: `muted` #8A8A8A
  - Rare: `accent` #EE2B2B
  - Epic: `tierElite` #C8A84B
  - Legendary: `tierGames` #E8E8E8 + 얇은 outer glow (box-shadow 1px)
- **카드 내부**:
  - name: `h3` 토큰 (20sp w700)
  - desc: `caption` (13sp, 한글 OK)
  - rarity: `micro` 토큰 대문자 우측정렬 ("EPIC")
  - unlocked_at: `micro muted` (YYYY-MM-DD)
- **미달성 (hidden=0)**: border `#2A2A2A`, name 표시, desc `· · ·` 대체
- **미달성 (hidden=1)**: 목록에 없음. 해금 순간 첫 노출
- **정렬**: 해금 먼저 (unlocked_at DESC) → 미달성 뒤

---

## 카피 규칙 (V5·V8·마침표 3분류 반영)

### 금지 패턴
- ✗ "You've reached RX." (V5 2인칭)
- ✗ "당신의 Engine이 80을 넘었습니다." (V5 + 긴 문장)
- ✗ "Your first PR!" (V5 + 느낌표)
- ✗ "Great job!" (감탄 + V4 위험)

### 허용 패턴 (name)
- ✓ `First Measure.` (단어 2개 + 마침표)
- ✓ `80 Overall.` (숫자+명사+마침표)
- ✓ `Complete Athlete.` (명사구 마침표)
- ✓ `Elite.` (단어 1개? — 선언문 계열로 마침표 유지)

### Toast 문구
- ✓ `80 Overall. Logged.` (사실 2단어)
- ✓ `Elite. Unlocked.` (Tier명 + 동사 과거분사)
- ✗ `You unlocked Elite!` 금지

---

## 다크패턴 회피 매트릭스

| 리스크 | 심각도 | 완화 | 잔존 |
|---|---|---|---|
| Streak reset 스트레스 | 高 | Streak 프레임 자체 미채택 | 低 |
| 미달성 배지 = 못한 리스트 | 高 | 기본 collapsed + hidden=1 | 中 (펼치면 보임) |
| Box leaderboard bullying | 最高 | MVP 제외 | - |
| FOMO/SNS 공유 압박 | 中 | 공유 기능 미구현 | 低 |
| Games 유저 "유치" 반응 | 中 | hidden Legendary 3개 + Profile 하단 collapsed | 中 |
| Masters 정보 과부하 (P9/P10) | 中 | 기본 collapsed + caption 한글 2줄 | 低 |
| 카탈로그 변경 시 기존 영향 | 低 | trigger_value JSON → threshold 조정 가능, code 불변 | 低 |

---

## MVP vs Phase 2

### MVP (Sprint 4 권장)
- `achievements_catalog` + `user_achievements` 마이그레이션
- 카탈로그 9개 seed
- `AchievementChecker` 서비스 (5종 trigger_type)
- `GET /achievements` + `POST /check`
- Flutter: Profile 탭 ACHIEVEMENTS 섹션 (collapsed + Show locked)
- Flutter: Grade 화면 unlock toast

### Phase 2 (v1.17+)
- PR Badge (카테고리별 prev_max 비교)
- `user_streaks` 테이블 활성화 — 단 "Last active: W16" 중립 표기로
- Trends 탭 `· · · N` dot sequence pill (streak 프레임 X)
- HapticFeedback.heavyImpact (unlock 순간)
- hidden Legendary reveal fade-in (300ms)

### v2 재평가 대상
- 박스 기반 배지 (MVP 박스 기능 정착 후)
- 박스 비공개 비교 (본인 티어만 노출) — leaderboard 대안

---

## 리스크 · 완화

| 리스크 | 가능성 | 완화 |
|---|---|---|
| Games 유저 "유치하다" | 中 | Profile 탭 하단 collapsed + hidden Legendary 3개 |
| Masters 정보 과부하 | 中 | 기본 접힘. 펼치기 = opt-in |
| 카탈로그 장기 고갈 | 中 | hidden Legendary 3개 = Games 수준까지 목표. 장기 동기는 History 선 그래프가 주력 |
| 2인칭 위반 슬립 | 低 | 카피 규칙 전수 체크리스트로 리뷰 |
| 트리거 오판 (중복 unlock) | 低 | UNIQUE(device_hash, code) + INSERT OR IGNORE |

---

## 구현 순서 (10단계)

| # | 단계 | 경로 |
|---|---|---|
| 1 | 카탈로그 모델 + seed | `services/facing/models/achievement.py`, `data/seed_achievements.py` |
| 2 | migrate_db에 등록 | `services/facing/models/base.py` |
| 3 | AchievementChecker 서비스 | `services/facing/engine/achievement_checker.py` |
| 4 | API 2개 + Blueprint | `services/facing/api/achievement.py` |
| 5 | smoke test (curl 9배지 × 5 trigger) | — |
| 6 | Flutter 모델 + Repository | `lib/models/achievement.dart`, `lib/features/achievement/achievement_repository.dart` |
| 7 | AchievementState (Provider) | `lib/features/achievement/achievement_state.dart` |
| 8 | AchievementCard 위젯 + Collapsed 섹션 | `lib/features/achievement/achievement_card.dart` |
| 9 | Profile 탭 통합 + Grade 화면 toast | `lib/features/mypage/mypage_screen.dart`, `lib/features/onboarding/onboarding_grade.dart` |
| 10 | QA — Games dummy device 시뮬레이션 | — |

예상 소요: 1 세션 (3~4시간) — 백엔드 1.5h + 프론트 2h.

---

## CPO 최종 판단

> **도입 여부**: 조건부 Yes
>
> **범위**: 9개 배지. Streak 제외, Box leaderboard 제외, 카테고리별 PR 제외.
>
> **경계선**: Achievement가 앱의 "주목적"처럼 보이는 순간 브랜드가 죽는다.
> facing의 핵심 가치는 Split·Burst 페이싱 전략이고, Achievement는 Profile 탭 부속 요소여야 한다.
> Profile 탭에 ACHIEVEMENTS 섹션 하나, 기본 collapsed. 이것이 최대치.
> 토스트는 3초 자동 소멸, 이모지 없음, 명사구 마침표 형식.
> 이 이상 커지면 CPO로서 기능을 잘라낸다.

---

## 관련 문서

- Persona SSOT: `docs/PERSONA_FEEDBACK_v1.15.3.md`
- 브랜드 SSOT: `CLAUDE.md` (Voice & Tone 11원칙 · 2인칭 금기 V5)
- 시각 SSOT: `docs/VISUAL_CONCEPT.md` v1.0
- 타이포 토큰: `lib/core/theme.dart` (`sectionLabel`, `tierLabel`, `caption`, `micro`, `h3`)
- Tier 색상: `lib/core/tier.dart`
- 점수 환산: `lib/core/scoring.dart` (`engineScoreTo100`)
- 데이터 소스: `services/facing/models/snapshot.py` (EngineSnapshot 6 카테고리 score)
- 교차 참조: `docs/GAMIFICATION_v1.16_PROPOSAL.md` (이 문서)
