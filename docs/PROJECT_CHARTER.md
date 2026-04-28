# facing-app · Project Charter

> **Snapshot 시점**: 2026-04-28
> **버전**: v1.20 Phase 3 완료 직후 (origin 대비 36 commits ahead, local-only)
> **목적**: 프로젝트 정체성·범위·결정사항의 단일 진원지. 세션 진입 시 첫 reference.

---

## 1. 한 줄 정의

> **CrossFit Games-Player 급 엘리트 athlete 를 위한 WOD Pacing Intelligence + Box 통합 앱.**

운동 / 헬스 / 다이어트 / 웰니스 앱 아님. Rich Froning · Mat Fraser · Tia Toomey 세대 전용.

---

## 2. 핵심 목표

| 목표 | 측정 지표 |
|---|---|
| WOD 시작 전 페이싱 전략 산출 | 분할(Split) + 폭발 시점(Burst) + 예상 완주 시간 |
| 사용자 Engine 수준 정량화 | 6 카테고리 점수 → Tier 1~6 매핑 |
| 박스 단위 코치-멤버 통신 | 인박스 (Note / Assignment / 4 탭) |
| 지속 동기 부여 (화이트햇) | Level / Panel B 칭호 / Streak Freeze / Season Badge |
| 데이터 정합성 | 개인 진척 vs 공개 리더보드 분리 저장 |

---

## 3. 타깃 사용자

**진입 자격**: Scaled → RX → RX+ → Elite → Games 5 티어 중 하나.
**금지 사용자**: 일반 피트니스·웰니스·다이어트 추구.

### 벤치마크 브랜드 (UI/카피 결정의 기준점)
| 브랜드 | 톤 키워드 | 적용 |
|---|---|---|
| HWPO (Mat Fraser) | "Earn it." 명령형·자부심 | 단어 1개 라벨, 고대비 타이포 |
| NOBULL | Stoic·blacked out | 모노 블랙/화이트, 장식 제로 |
| Mayhem (Rich Froning) | Team·discipline | 숫자·기록 우선, 과시 없음 |
| CompTrain (Ben Bergeron) | Coach·analytical | 데이터·근거 제시 |

---

## 4. 페르소나 (10명, 시드 SSOT)

`services/facing/data/personas.json` + `lib/features/_debug/persona_switcher_screen.dart`

| # | id | 이름 | 역할 | Tier | 박스 | 상태 | WOD |
|---|---|---|---|---|---|---|---|
| 1 | admin_01 | 변민준 | admin | RX+ | — | — | 8 |
| 2 | coach_a | 박지훈 | coach_owner | Elite | FACING SEONGSU | owner | 14 |
| 3 | coach_b | 이수민 | coach_owner | Elite | FACING GANGNAM | owner | 12 |
| 4 | member_a1 | 김도윤 | member | RX | FACING SEONGSU | approved | 11 |
| 5 | member_a2 | 정하은 | member | RX | FACING SEONGSU | approved | 9 |
| 6 | member_a3 | 최서윤 | member | Scaled | FACING SEONGSU | pending | 0 |
| 7 | member_b1 | 강민재 | member | RX+ | FACING GANGNAM | approved | 13 |
| 8 | member_b2 | 윤지원 | member | RX | FACING GANGNAM | approved | 7 |
| 9 | member_b3 | 한수아 | member | Scaled | FACING GANGNAM | rejected | 0 |
| 10 | app_user_01 | 송예준 | app_user | RX | — | — | 6 |

분포: admin 1 / coach_owner 2 / member approved 4 / pending 1 / rejected 1 / app_user 1.

---

## 5. 기능 매트릭스 (14 기능군)

| 그룹 | 기능군 | 핵심 화면 | 페르소나 분기 |
|---|---|---|---|
| A | 온보딩 | Splash → Intro → Onboarding (Basic / Benchmarks / Grade) | 전 페르소나 동일, intro_seen 플래그로 1회만 |
| A | Auth | SignupScreen + Persona Switcher (debug only) | 5 데모 계정 + 10 페르소나 |
| A | Settings | MyPage Settings 섹션 (단위 / textScale / Reset / SignOut) | 전 페르소나 동일 |
| B | WOD Calc | Builder → MovementPicker → Result | 전 페르소나 (gym 무관) |
| B | WOD 세션 | Box WOD → Detail → Session Timer → 기록 저장 | owner / approved 만 활성 |
| B | History | Engine snapshots + WOD records + Detail | 전 페르소나 (개인 device_id 한정) |
| C | Inbox | 4 탭 (ALL/NOTES/ASSIGNMENTS/OUTBOX) + Compose + Note Detail + Group | owner 4탭, approved 3탭, 그 외 차단 |
| C | Coach Tools | WOD 등록·삭제 / 노트 / Group / Announcements / Leaderboard / Messages | owner 만 |
| C | Gym | Box 검색·가입·박스 생성 + 멤버 승인 | 무소속 검색·가입, owner 만 박스 생성 |
| D | Profile | TierSnapshot / WornTitle / InboxEntry / TierRoadmap / EngineTrend / RoleModel / CategoryTiers / Achievements | 전 페르소나, 일부 섹션 게이트 |
| D | Trends | LEVEL & TITLES (LEVEL 카드 + Achievement 갤러리 + Panel B 진입) | 전 페르소나 |
| D | Attendance | 월별 캘린더 + Streak + Streak Freeze + 챌린지 | 전 페르소나 |
| E | Achievements / Panel B | FIFA-style 3x3 + 20-title Panel B | 전 페르소나, 칭호 신호 따라 잠금 |
| E | Gamification Unlock | PR / Season / Achievement / Streak Freeze / Level up 알림 | 전 페르소나 |

---

## 6. 디자인 톤·매너 (SSOT 우선순위: VISUAL_CONCEPT.md > DESIGN_PLAYBOOK.md > CLAUDE.md)

### 6-1. 컬러 (9 토큰 + 5 tier)
- `bg #0A0A0A` / `surface #141414` / `surfaceOverlay #1E1E1E`
- `fg #F5F5F5` / `muted #9E9E9E` / `border #2A2A2A`
- `accent #EE2B2B` (CrossFit red, primary CTA) / `accentPressed #CC2020`
- `success #22C55E` / `warning #F59E0B` / `error #EE2B2B` / `overdue #F59E0B`
- 5 Tier: `tierScaled #4A4A4A` / `tierRx #EE2B2B` / `tierRxPlus #929292` / `tierElite #C8C8C8` / `tierGames #F5F5F5`

### 6-2. 타이포 (Pretendard + Bodoni Moda Italic 영문 헤드라인)
| 토큰 | 크기 | weight | 용도 |
|---|---|---|---|
| display | 64sp w800 | -1.6 ls | 히어로 숫자·총시간 |
| displayCompact | 56sp w800 | -1.4 ls | 카드 내 히어로 |
| h1 | 44sp w800 | -1.1 ls | 화면 단일 헤드라인 |
| h2 | 30sp w700 | -0.6 ls | 화면 주 타이틀 |
| h3 | 20sp w700 | -0.2 ls | 섹션 타이틀, AppBar |
| lead | 18sp w400 | — | intro body |
| body | 15sp w400 | — | 본문 |
| caption | 13sp w400 muted | — | 부연 설명 |
| micro | 13sp w500 ls+0.4 muted | — | 수치 보조 (P0-8 11→13 상향) |
| sectionLabel | 11sp w700 ls+1.2 muted | — | 섹션 구분 라벨 (대문자) |
| brandLogo | 72sp w800 ls-2.4 | — | Splash "FACING" 전용 |
| tierLabel | 12sp w800 ls+1.4 | — | TierBadge 전용 |
| bannerLabel | 12sp w700 ls+1.0 | — | Offline 배너 |
| quote | 14sp italic | — | 명언 |
| Bodoni Moda Italic | 다양 | w700~800 | 영문 hero 헤드라인 + 명언 |

### 6-3. Voice 11원칙 (V1~V11)
- V1 명령형 기본 / 단어 1개 라벨 마침표 없음 / 1줄 선언 마침표 유지
- V2 숫자 없는 동기부여 금지
- V3 한 문장 10단어 이하
- V4 이모지 금지 (화살표·체크·점·원만 허용)
- V5 2인칭 금기 (당신/귀하)
- V6 영문 전문 용어 번역 안 함 (1RM / AMRAP / Metcon 등)
- V7 실패도 전술적 ("Offline. 연결 시 동기화.")
- V8 짧은 UI 라벨·헤드라인 영문 단독
- V9 한 문장 내 영문-한글 혼합 금지
- V10 부연 설명 한글 허용 (영문 헤드라인 + 한글 캡션 수직 stack)
- V11 동작명/등급명/메트릭은 항상 영문

### 6-4. 절대 차단
- 그래픽 이모지 (제품 UI)
- 그라디언트 / 다중 box-shadow / 디자인 토큰 외 hex 직접
- 사진·일러스트 (타이포+수치 중심)
- 라이트 모드 (다크 전용)

---

## 7. 게이미피케이션 시스템 (rules/gamification.md 화이트햇 7원칙)

### 7-1. 절대 차단 (블랙햇 7종)
1. 랜덤 보상 (loot box 가변 비율)
2. 회복 결제 (스트릭 복구 결제 — Duolingo 모델)
3. Lv 차감 패널티 (엘리트 21%+ 이탈)
4. 시간 한정 희소성 (FOMO 루프)
5. 강제 리더보드 (opt-in 없는 공개)
6. 회피형 스트릭 카피 ("100일 잃습니다")
7. 색상 단독 등급 표시 (WCAG fail)

### 7-2. 화이트햇 채택
- **자율성**: Streak Freeze = Rest Pass (사용자 선택, 1주 1회 무료)
- **유능감**: 결정론적 unlock 임계 (e.g., Engine 80+ 5회)
- **관계성**: 박스 리더보드 opt-in (기본 비공개)

### 7-3. 12 컴포넌트 (코어)
| 모듈 | 위치 | 와이어드 | 테스트 |
|---|---|---|---|
| LevelSystem (Lv 1~50, 5 XP source) | core/level_system.dart | trends LEVEL 카드 | 8 ✓ |
| PrDetector (countPrs / isPrAgainst) | core/pr_detector.dart | trends + wod_session | 20 ✓ |
| EngineDecay (30~180일 -3%/30days, 캡 -20%) | core/engine_decay.dart | history + mypage | 11 ✓ |
| StreakFreezeStore (1주 1회) | core/streak_freeze.dart | attendance + streak 통합 | 6 ✓ |
| SeasonBadgeService (Open/QF/SF/Games) | core/season_badges.dart | result + wod_session + panel_b | 6 ✓ |
| Panel B (20 titles) | core/titles_catalog.dart | panel_b_screen | 11 ✓ |
| WornTitleStore (1개 착용) | core/worn_title_store.dart | mypage + panel_b 토글 | 6 ✓ |
| Tier (5단계) | core/tier.dart | 8개 화면 | 10 (matrix) ✓ |
| Season (시즌 판별) | core/season.dart | season_badges 내부 | 간접 ✓ |
| Haptic.achievementUnlock | core/haptic.dart | unlock_toast 외 3곳 | side-effect |
| UnlockToast (rarity 색·confetti·toast) | features/achievement/unlock_toast.dart | onboarding_grade + wod_session | — |
| AchievementState (백엔드 trigger) | features/achievement/achievement_state.dart | onboarding + wod_session check() | — |

---

## 8. 기술 스택

| 레이어 | 선택 | 비고 |
|---|---|---|
| 프론트 | **Flutter 3.x stable + Dart 3.5+** | Android 우선 (MVP) |
| 상태관리 | **Provider 6.x** (project-level 결정) | rules/mobile.md Riverpod 권장이나 기존 코드베이스 유지 |
| HTTP | **dio 5.x** + 인터셉터 | X-Device-Id 헤더 자동 |
| 로컬 저장 | **shared_preferences 2.x** | 디바이스 ID, 프로필, 칭호, 단위, freeze 사용 기록 |
| 폰트 | **Pretendard Variable** + Google Fonts (Bodoni Moda) | 런타임 fetch + Pretendard fallback |
| 공유 | **share_plus 10.x** | WOD 결과 텍스트 공유 |
| 백엔드 | **services/facing/** (Flask) | 별도 repo. localhost:5060 (dev) / Railway (prod) |
| 백엔드 시드 | services/facing/data/personas.json + seed_personas.py | 10 페르소나 |
| 백엔드 회귀 | services/facing/tests/test_personas_e2e.py | endpoint × 10 페르소나 |
| API 응답 | Envelope `{ok, data, error?, code?}` | rules/common/patterns.md |

### 8-1. 폴더 구조
```
lib/
├── main.dart
├── app.dart (없음 — main.dart 내 FacingApp)
├── core/                       # 공유 도메인 + 유틸
│   ├── api_client.dart
│   ├── theme.dart              # FacingTokens + FacingTheme
│   ├── tier.dart
│   ├── level_system.dart
│   ├── engine_decay.dart
│   ├── streak_freeze.dart
│   ├── season_badges.dart
│   ├── season.dart
│   ├── pr_detector.dart
│   ├── titles_catalog.dart
│   ├── worn_title_store.dart
│   ├── haptic.dart
│   ├── quotes.dart
│   ├── exception.dart
│   └── ... (state/repository 외)
├── features/
│   ├── splash/ intro/ onboarding/ auth/
│   ├── home/ shell/ profile/ mypage/
│   ├── wod_builder/ pacing_result/
│   ├── gym/ wod_session/ inbox/
│   ├── announcements/ leaderboard/ messages/
│   ├── history/ attendance/ trends/ goals/
│   ├── achievement/
│   └── _debug/ (페르소나 스위처)
├── models/                     # API DTO
│   ├── achievement.dart
│   ├── coach_note.dart
│   ├── coach_group.dart
│   ├── gym.dart
│   ├── movement.dart
│   ├── pacing_plan.dart
│   └── preset_wod.dart
└── widgets/                    # 공용 UI
    ├── tier_badge.dart
    ├── avatar.dart
    ├── grain_overlay.dart
    ├── hero_background.dart
    ├── offline_banner.dart
    └── quote_card.dart
```

---

## 9. 데이터 흐름

### 9-1. 사용자 식별
- 익명 device_id (UUID v4) — 최초 실행 시 SharedPreferences 저장
- 모든 API 요청에 `X-Device-Id` 헤더 — dio 인터셉터 자동
- 디버그: PersonaSwitcher 가 device_id 덮어쓰기 → 백엔드 seed personas 매칭

### 9-2. Engine 측정
1. 온보딩 Benchmarks (5 카테고리 폼)
2. POST /api/v1/grade/calculate
3. ProfileState.gradeResult 저장 + SharedPreferences persist
4. EngineSnapshotRecord 자동 저장 (history)
5. 6 카테고리 점수 → overall_number 1~6 → Tier 매핑

### 9-3. WOD Calc
1. WodBuilder → MovementPicker → 동작·횟수·중량 입력 + WodType (For Time / AMRAP / EMOM)
2. POST /api/v1/pacing/calculate (profile_overrides 동봉)
3. PacingPlan 응답 → ResultScreen 표시 (분할 / 버스트 / 예상 시간 / 근거)
4. WodHistoryItem 자동 저장 (history)
5. SeasonBadge unlock 체크 (active 시즌만)

### 9-4. WOD 세션
1. BoxWodScreen → WodDetail → WodSessionScreen (타이머)
2. 완료 → _saveRecord:
   a. PR 사전 비교 (forTime 모드, prior best vs new totalSec)
   b. POST /api/v1/history/wod
   c. POST /api/v1/gyms/{id}/wods/{id}/results (리더보드, owner/approved 만)
   d. WodSessionBus.bump() → attendance / history 자동 reload
   e. PR unlock toast (Haptic heavy + SnackBar)
   f. SeasonBadgeService.recordSessionToday()
   g. AchievementState.check(throttle: true) → 신규 unlock 시 UnlockToast.showAll
3. anyUnlockShown → 마지막 '기록 저장' SnackBar 생략

### 9-5. Inbox (코치-멤버 통신)
- coach owner: ComposeNoteScreen → POST /api/v1/inbox/notes (target: individual / group / all)
- 멤버: GET /api/v1/inbox → 4 탭 분류 (NOTES / ASSIGNMENTS / + ALL / + OUTBOX coach 만)
- 멤버 액션: markRead / accept / complete / decline / askCoach → optimistic update + 서버 동기화
- 인박스 게이트: `isOwner || isApprovedMember` 만 _InboxEntry 노출

---

## 10. 검증·테스트 현황 (2026-04-28 기준)

### 10-1. 백엔드 회귀
`services/facing/tests/test_personas_e2e.py` — 10 페르소나 × 8 endpoint 회귀 (health / profile/info / history/wod / gyms/mine / wods 권한 등).

### 10-2. 프론트 단위 + 위젯 (106 tests)
| 파일 | 테스트 | 영역 |
|---|---|---|
| level_system_test.dart | 8 | LevelSystem XP 곡선 |
| engine_decay_test.dart | 11 | EngineDecay decay/applyDecay/statusCaption |
| pr_detector_test.dart | 20 | countPrs + isPrAgainst |
| streak_freeze_test.dart | 6 | StreakFreezeStore CRUD |
| season_badges_test.dart | 6 | SeasonBadgeService |
| titles_catalog_test.dart | 11 | Panel B catalog + Unlocker |
| worn_title_store_test.dart | 6 | WornTitleStore CRUD |
| persona_matrix_test.dart | 31 | 10 페르소나 × 4 기능군 분기 |
| achievements_screen_test.dart | 4 | AchievementsScreen 렌더 분기 (위젯) |
| widget_test.dart | 1 | placeholder smoke |
| **총계** | **106** | flutter analyze: clean |

### 10-3. 통합 테스트 (emulator 필요)
`integration_test/persona_smoke_test.dart` — PersonaSwitcher 위젯 + 10명 시드 표시 검증.

### 10-4. 미커버 영역
- WodSessionScreen 저장 시퀀스 위젯 테스트 (mock 5+ 의존성)
- InboxScreen 게이트 위젯 테스트
- 실 디바이스 dogfood (PR / Season unlock / 4 toast 시퀀스)

---

## 11. 로드맵·백로그

### 11-1. 완료 (현 시점)
- Phase 1: 온보딩 + WOD Calc + History
- Phase 2: Box / Inbox / Coach Tools / Gamification 코어
- Phase 2.5: Panel B + Streak Freeze + Season Badge + PR XP
- Phase 3: 위젯 테스트 1차 + share_plus + Panel B 보강 + FCM 가이드

### 11-2. 즉시 가능 (백엔드 의존 없음)
- InboxScreen / WodSessionScreen 위젯 테스트 보강
- 칭호 unlock 카드 이미지 공유 (RepaintBoundary + shareXFiles)
- 데모 계정 정합성 추가 (5 demo accounts × 페르소나 매핑)
- /qa 자동화 회귀 회복

### 11-3. 백엔드 의존
- Panel B 5 signal 추출 (ub50PlusSessions / du50Unbroken / hspu10Unbroken / mus5Unbroken / openRegistered)
- 신규 endpoint: /api/v1/season/current (현재 mock)
- 코치 노트 카테고리·필터링 강화

### 11-4. 인프라
- FCM Push 통합 (docs/PHASE3_PUSH.md 가이드 따라)
- Firebase 프로젝트 생성 + google-services.json
- 백엔드 device_push_tokens 테이블 + 발송 트리거
- iOS 빌드 (Phase 4)

### 11-5. 디자인·UX
- Bodoni Moda Italic 폰트 로컬 번들 (오프라인 보장)
- Confetti 애니메이션 미세조정 (Epic/Legendary)
- Toast 큐잉 정책 검토 (4건 시퀀스 시 가독성)
- 커뮤니티 챌린지 opt-in UI

### 11-6. 비즈니스
- Whoop / Garmin OAuth (선택)
- Cloud 백업 (사용자 데이터 영속)
- Friends / Follow / 비공개 PR 공유

---

## 12. 절대 차단 (위반 시 즉시 중단)

### 12-1. 배포
- 사용자 명시 "배포해" 전까지 git push / Railway / store 금지 (CLAUDE.md 최상위)
- main 브랜치 force push 금지
- main 직접 push 금지 (PR 경유)
- COPY .env Dockerfile 금지

### 12-2. 콘텐츠
- 운동 / 헬스 / 다이어트 / 건강 / 체중관리 / 웰니스 용어 사용 금지
- "쉬운" / "편리한" / "누구나" 금지
- 그래픽 이모지 금지

### 12-3. 게이미피케이션
- 블랙햇 7종 (rules/gamification.md §1)

### 12-4. 데이터
- SHA256 / MD5 패스워드 단독 금지 → bcrypt cost ≥ 12 또는 argon2id
- GET 엔드포인트에서 state 변경 금지
- 시크릿 하드코딩 금지

---

## 13. 관련 문서

| 역할 | 경로 |
|---|---|
| 본 문서 (snapshot) | `docs/PROJECT_CHARTER.md` |
| 비주얼 컨셉 SSOT | `docs/VISUAL_CONCEPT.md` |
| 디자인 플레이북 | `docs/DESIGN_PLAYBOOK.md` |
| 프로젝트 룰 (배포 금지·voice 11원칙·페르소나 등) | `CLAUDE.md` |
| QA 마스터 | `docs/QA/QA-2026-04-27.md` |
| FEATURES 매트릭스 | `docs/QA/FEATURES_CHECKLIST.md` |
| FCM 통합 가이드 | `docs/PHASE3_PUSH.md` |
| 직전 세션 인계 | `docs/HANDOFF.md` |
| 백엔드 페르소나 시드 | `services/facing/data/personas.json` |
| 백엔드 E2E 회귀 | `services/facing/tests/test_personas_e2e.py` |

---

## 14. 변경 이력 (본 문서)

| 날짜 | 변경 |
|---|---|
| 2026-04-28 | 초안 작성 — Phase 3 완료 직후 (commit 9effd0a 기준) |
