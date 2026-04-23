# Changelog

## v1.14.0 — 2026-04-23 (타이포·계층 정비 + Playbook 수립)

### 신규 문서
- **`docs/DESIGN_PLAYBOOK.md`** v1.0.0 — 디자인 SSOT 수립. 10섹션 + 부록 2개. 근거(Material 3, Apple HIG, WCAG AA, NNG, 엘리트 피트니스 앱 벤치마크 10종) 포함.

### 디자인 토큰 (`lib/core/theme.dart`)
- **추가**: `sectionLabel` (11sp w700 ls+1.6 muted), `brandLogo` (72sp w800 ls-2.4), `bannerLabel` (12sp w700 ls+1.2), `surfaceOverlay` (#1E1E1E L2), `r5` (28px)
- **삭제**: `timer` (미사용 데드 토큰)
- **변경**: `muted` #8A8A8A → #9E9E9E (WCAG AA 4.9:1 경계 → 6.1:1 통과), `touchMin` 44 → 48 (Material 3 표준)

### 계층 규칙 (Voice & Tone V8, V10 + 신규 R1~R5)
- 화면당 H1 1개 원칙 (AppBar title + 화면 h2 이중 타이틀 금지)
- Tier 결과 화면 최대 2겹 (TierBadge 24sp + Score 한 줄)
- 섹션 헤더 `sectionLabel` 단독
- 동일 지표 동일 토큰 (500m pace = h3 통일)
- 하드코드 fontSize 금지

### 화면별 변경
- **Splash**: 하드코드 `TextStyle(fontSize: 72,...)` → `brandLogo` 토큰
- **Intro**: dot indicator margin/size 하드코드 → `sp1/sp2/sp5`, active dot accent 색 전환
- **Onboarding Basic**: AppBar `Step 1 / 6 · BODY` → `Step 1 / 6` (이중 타이틀 해소). Pill unselected 투명+border+muted
- **Onboarding Benchmarks**: AppBar 카테고리명 제거. `_meta` 22개 help 한글 복원. Loading dialog border 제거, surface fill만
- **Onboarding Grade**: `OVERALL` 라벨 + `N/6` 숫자 제거 → TierBadge(24) + Score 2겹. `_CategoryCard` inline body.w800 → sectionLabel, border → 좌측 tier color 3px bar
- **Home**: AppBar `FACING` + History/Profile 아이콘. sub 한글 전환. Benchmark 버튼 라벨 단순화 + 프리셋 이름 micro 서브
- **MyPage**: 카드 3개 → Divider 구조 전환. TierSnapshot 2겹 축약. `CURRENT TIER`/`BODY`/`SETTINGS` sectionLabel. AlertDialog `surfaceOverlay` + r5
- **History**: EngineRow border 제거 → ListView.separated + Divider. `OVERALL SCORE`/`ITEMS` sectionLabel. Score·총시간에 tabular figures
- **History Detail**: `ITEMS` sectionLabel. `est.` → `예상`. `No pacing plan stored.` → `페이싱 플랜 없음.`
- **Result**: 500m pace h2 → h3. Segment slug prettify (`pull_up` → `Pull Up`). estimated time tabular. 비폭발 segment border 제거, surface fill
- **WOD Builder**: `WOD Type`/`Movements` sectionLabel. 섹션 caption 대체. `_ItemRow` border → surface fill. index 번호 muted + tabular
- **Offline Banner**: `OFFLINE · SYNC ON RECONNECT` → `OFFLINE · 연결 시 동기화`. inline TextStyle → bannerLabel 토큰
- **TierBadge**: fill 방식 (border → 배경 색 + 대비 텍스트). 하드코드 padding 8/3/12/6 → sp2/sp1-1/sp3/sp2-2 토큰화

### 백엔드 (`services/facing/`)
- 신규 테이블 `engine_snapshots` + 인덱스 2개 (wods.profile_id+created_at, pacing_plans.wod_id)
- 신규 API: POST/GET `/api/v1/history/engine`, POST/GET/GET-detail/DELETE `/api/v1/history/wod`
- Profile 자동 upsert (device_id_hash 기반)

### 카피 정책 (CLAUDE.md v1.13.0~v1.14.0)
- 마침표 3분류 (단어 1개 없음 / 선언문 유지 / 수치 유지)
- 영문 헤드라인 + 한글 캡션 수직 스택 공식 허용
- HWPO / NOBULL / Mayhem / CompTrain 벤치마크 브랜드 명시

---

## v1.11.0 — 2026-04-22 (UX 풀패키지)
- Splash + Intro 3-페이지 swipe
- Onboarding 5 카테고리 분리 (Power / Olympic / Gymnastics / Cardio / Metcon)
- kg/lb 글로벌 토글
- "모름" 버튼 + 체중만 있으면 진행 가능
- 계산 중 로딩 오버레이
- Offline 배너 + connectivity_state
- 5 Tier 시스템 + TierBadge
- 10개 엘리트 명언

## v1.10.0 — 2026-04-21 (Formula 1.10)
- 6 카테고리 grading
- Power 카테고리 분리

## v1.0 — 초기 (Flutter wizard 기반)
