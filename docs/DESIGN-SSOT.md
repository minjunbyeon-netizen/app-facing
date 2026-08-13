# DESIGN-SSOT — 화면 양식 정본 (v2.2 · 2026-08-12)

> **모든 레이아웃·크기·폰트 굵기·카피 결정의 단일 정본.** 화면 작업은 이 양식 안에서만 움직인다.
> 새 수치·새 variant 가 필요하면 **이 문서와 HKit/토큰에 먼저 추가한 뒤** 화면에 쓴다 (역순 금지).
> 상위 정본: 공통 조상 토큰 = `lib/core/appkit.gen.dart` (AppKit — `C:/dev/tools/appkit` 마스터,
> `python sync.py` 재생성) → hyphen 재수출 = `lib/core/theme.dart` (HyphenTokens) →
> 컴포넌트 = `lib/widgets/hkit.dart` (HKit) + `lib/widgets/brand_logo.dart` (BrandLogo).

## 0. 집행 규칙 (강제)

- 인라인 `fontSize:` 숫자 금지 — `test/copy_lint_test.dart` 가 차단 (theme.dart 만 예외).
- 인라인 `FontWeight` 는 아래 §2 굵기 정책 4단만 허용. 새 굵기 필요 시 이 문서 갱신 먼저.
- 간격·모서리·크기는 `HyphenTokens.sp*` / `r*` / `touchMin·buttonH·appBarH` 상수만.
  (미세 보정 ±2px 이내 리터럴은 허용 — 예: 배지 vertical 3, 도트 크기.)
- 카드·배지·섹션 라벨·통계 타일·빈/에러/로딩 상태·소셜 버튼·전면 로딩은 **HKit 것만** 사용.
- UI 를 바꾸면 골든 재생성 (`flutter test --update-goldens test/golden`) + 갤러리 갱신이 완료 조건.

## 1. 타이포 스케일 (토큰 = 유일 출처)

| 토큰 | 크기/굵기/자간 | 용도 (여기 없는 용도 금지) |
|---|---|---|
| `display` | 72 w900 -2.4 | 화면당 ≤1 "영혼 숫자" (Engine 점수·총시간) |
| `displayCompact` | 56 w900 (조상) | LEVEL 숫자·Tier 배지 큰 숫자 |
| `h1` | 28 w700 (조상) | 화면 단일 헤드라인 (인트로·풀스크린 화면) |
| `h2` | 22 w700 (조상) | 섹션 큰 타이틀 (AppBar 없는 화면 한정) |
| `h3` | 17 w600 (조상) | 카드 타이틀 · AppBar title (테마 기본) |
| `lead` | 18 w400 (조상) | 인트로 본문 등 큰 본문 |
| `body` | 15 w400 (조상) | 본문 기본 |
| `caption` | 13 w400 muted | 부연 설명 |
| `micro` | 13 w500 muted | 수치 보조 (개수·%·포인트) |
| `sectionLabel` | 12 w600 +1.32 muted | 섹션 구분 라벨 — HkSectionLabel 로만 사용 |
| `tierLabel` | 14 w900 +1.6 | TierBadge 내부 전용 |
| `bannerLabel` | 12 w600 +1.0 | 오프라인 등 배너 전용 |
| `quote` | 14 w500 italic | 영어 명언 전용 |

**계층 규칙**: R1 화면당 h1 1개 (AppBar 있으면 h1·h2 헤드라인 금지) · R2 동일 지표 = 동일 토큰
(화면 막론) · R3 섹션 헤더 = HkSectionLabel 단독 · R4 하드코드 fontSize 금지 · R5 한글 자간 음수
(조상이 보장 — copyWith 로 0/양수 자간 금지, 대문자 영문 라벨만 예외).

## 2. 폰트 굵기 정책 (4단만)

| 굵기 | 허용 용도 |
|---|---|
| w400 | 본문·캡션 기본 |
| w500 | micro·quote |
| w600 | 버튼 텍스트 · h3 · sectionLabel · bannerLabel · 리스트 항목 강조 |
| w700 | h1 · h2 · 이름/값 강조 (`body.copyWith(fontWeight: w700)` 만 허용되는 인라인) |
| w800~900 | **BrandLogo·display·tierLabel 전용** — 일반 텍스트 금지 |

## 3. 컬러 사용처 (HyphenTokens)

- 면: `bg`(화면) / `surface`(카드) / `surfaceAlt`(중첩·hover)
- 텍스트: `fg`(본문) / `fgSecondary`(보조) / `muted`(흐림·비활성 전용) / `placeholder`(입력 안내)
  — 컬러 배경 위는 항상 `onColor`. **읽어야 하는 값에 `muted` 금지** (§7-D 4)
- 액션: `primary`(CTA 1개/화면) / `danger`(파괴) / `success·warning·info`(상태)
- **`primary` = #CC1F1F** (v2.2 — 구 #EE2B2B 는 흰 배경 4.01:1 · 흰 글씨 4.19:1 로
  양방향 AA 미달이었다. 값 정본은 `appkit.config.json` 브랜드 스킨 → `python sync.py`)
- 소셜: `naverGreen` / `googleSurface`+`googleBlue` (외부 브랜드 — 다른 용도 금지)
- 티어: `tierScaled~tierGames` 5색 (TierBadge 전용)

## 4. 스페이싱·모서리·크기

| 항목 | 값 |
|---|---|
| 화면 수평 패딩 | AppBar 화면 = `sp4`(16) · 풀스크린(스플래시·인트로·로그인) = `sp5`(24) |
| 섹션 사이 | `sp5`(24) — 섹션 라벨→내용 = `sp2`(8) |
| 카드 내부 | `sp4`(16) — HkCard 기본 |
| 요소 사이 | 밀접 `sp1`(4) · 기본 `sp2`(8) · 구분 `sp3`(12) |
| 모서리 | `r1`(4) 배지·선택칩 · `r2`(8) 입력·작은 버튼 · `r3`(12) 카드·소셜 버튼 · `r4`(16) CTA 버튼 · `r5`(28) 시트 |
| 크기 | 터치 최소 48 · 버튼 높이 52 · AppBar 52 · 탭바 64 · 스피너 22×22 stroke 2 |

## 5. HKit 컴포넌트 (여기 없으면 HKit 에 추가 후 사용)

| 컴포넌트 | 규격 |
|---|---|
| `HkButton` | **버튼 유일 규격 (v2.2)** — primary 채움 52 / secondary 외곽선 52 / tertiary 글자 48. 화면당 primary 1개. 옵션 `expand`·`neutral`·`danger` 뿐. 상세 = §7-D |
| `HkCard` | surface + 1px border + r3, 패딩 sp4 |
| `HkBadge` | **배지·선택칩 통합 유일 규격 (v1.32)** — 1px 컬러 보더 + 대문자 + r1(4) 사각, 원형 pill 금지. `onTap` 주면 선택 컨트롤(터치 48 보장), `selected` 면 면 채움 반전 |
| `HkSectionLabel` | sectionLabel + 대문자 강제 |
| `HkStatTile` | 라벨 위 + 값(h3) 아래 |
| `HkListRow` | **표 행 유일 규격** — 좌 아이콘(20) · 제목(body w600)/부제(caption) · 우 값(micro) · below 슬롯(진행바). 패딩 sp4×sp3. `onTap` 이 있고 우측 값이 없으면 **화살표 자동** (v2.2) |
| `HkRowCard` | 표 카드 — HkListRow 를 1px 구분선(indent sp4)으로 쌓음. 카드 1개 = 표 1개 |
| `HkAccordion` | **접힘 구획 유일 규격** — 기본 접힘 · sectionLabel 제목 + caption 부제(내용 preview) · muted 화살표 · 기본 divider 제거. `inset=true` 면 카드 내부 여백(sp3) |
| `HkEmptyState` | h3 제목 + caption 캡션 수직 스택 |
| `HkErrorState` | body 메시지 + "다시 시도" — `.fromError` 로 메시지 통일 매핑 |
| `HkLoading` | 22×22 stroke 2 muted 스피너 (인라인 로딩 유일 규격) |
| `HkLoadingScreen` | **전면 로딩 유일 규격** — BrandLogo + HkLoading + 선택 캡션 |
| `HkSocialButton` | 소셜 로그인 버튼 유일 규격 — 높이 52 · r3 · 마크+라벨 중앙 |
| `BrandLogo` | 브랜드 로고 정본 — **기본 폭 220 고정** (진입·로딩 화면 전부 동일) |
| `TierBadge` | 티어 표기 별도 정본 |

## 6. 진입·로딩 화면 양식 (로그인·로딩 통일 — v1.29)

모든 진입 계열 화면(스플래시·인트로·로그인·전면 로딩)은 같은 골격:

```
┌──────────────────────────┐
│        (Spacer)          │
│     BrandLogo (220)      │   ← 항상 기본 폭 220 · 수평 중앙
│        (Spacer)          │
│   [화면별 콘텐츠 슬롯]      │   ← 로그인: 소셜 버튼 스택 / 스플래시: 명언+스피너
│                          │      전면 로딩: HkLoadingScreen (로고+스피너+캡션)
└──────────────────────────┘  패딩 sp5 · 배경 bg
```

- 로그인 진행 중(_busy) 화면 = `HkLoadingScreen(caption: '로그인 중')` — 버튼 비활성만으로 때우지 않는다.
- 소셜 버튼 순서: 네이버(실서비스 1순위) → 구글. 규격은 HkSocialButton 만.
- 네이버 실 로그인 배선: `RealSocialAuthService` + `--dart-define=USE_REAL_AUTH=true`
  (키 주입 절차 = `docs/NATIVE_AUTH_SETUP.md`, 키 하드코딩 금지).

## 7. 카피 규칙 v2.0 — 한글 기본 (2026-07-28 사용자 지시로 영문 중심 폐기)

- **기본 언어 = 한글.** 버튼·탭·헤더·섹션 라벨·안내·에러 전부 한글.
- **영문 유지 (도메인 고정어만)**: 브랜드 `HYPHEN` · CrossFit 용어 `WOD` `AMRAP` `EMOM` `RX`
  `RX+` `Scaled` `Elite` `Games` `1RM` `PR` `UB` `Metcon` `For Time` `Engine` `Split` `Burst` ·
  단위 `kg/lb` · `XP` · 벤치마크 WOD 이름(Fran 등) · 동작명(Thruster 등) · 명언(원문).
- **문장 톤**: 명사형 간결체 ("오늘의 WOD" · "불러오기 실패"). 완곡·응원·이모지 금지는 유지.
  버튼 = 동사 명령형 2~4자 ("저장" "다음" "다시 시도"). "~하세요" 남발 금지, 안내문은 "~합니다/됩니다" 격식.
- **혼용 허용**: 도메인 영단어 + 한글 조사 결합 허용 ("코치가 올린 오늘의 WOD") — 구 V9 금지 폐기.
- **금지 용어 유지**: 운동·헬스·다이어트·웰니스·체중관리·쉬운·편리한·누구나·당신·귀하 (copy_lint).
- 공통 문자열(건너뛰기·다음·저장·취소 등)은 appkit 스킨 `appkit.config.json > strings` = 정본.

## 7-A. 나열형 데이터 표기 (v1.30 · 2026-08-06 사용자 지시)

- **한 줄에 한 항목.** 업적·마일스톤처럼 개수가 늘어나는 목록은 `HkRowCard` + `HkListRow` 표로만
  표기한다. **색 채운 타일 그리드 금지** (rarity 색 배경 3열 그리드가 산만 — v1.30 폐기).
- 색은 면이 아니라 **아이콘·우측 값 글자색**으로만 (rarity·달성 여부). 면은 항상 `surface` 1색.
- 목록이 길면 상단 헤더에 `n / m` + "전체 보기", 본문은 **최대 5줄** + "그 외 N개" 마지막 행.
- 항목 상세(해금일·조건 등)는 행에 싣지 않고 탭 → 상세 시트에서 노출.

## 7-B. 메뉴·설정 항목 표기 (v1.31 · 2026-08-07 사용자 지시)

- **같은 모양 버튼을 세로로 쌓지 않는다.** 화면 진입만 하는 메뉴 항목이 3개를 넘으면
  `HkAccordion`(기본 접힘) **1개** 안에 `HkRowCard` 표로 넣는다 — 접힘 상태에서 헤더 한 줄.
  (구 프로필 탭의 OutlinedButton 10개 세로 나열은 v1.31 폐기.)
- 아코디언 부제에 내용 preview 를 넣어 펼치지 않아도 무엇이 들어 있는지 보이게 한다.
- **화면 하나에 세로로 이어지는 구역이 많으면 구역 자체를 `HkAccordion` 으로 접는다.**
  화면의 정체성·핵심 지표(프로필의 신원·Engine 등)만 펼친 채 두고 나머지는 접힘 기본.
- **접으면 안 되는 값은 부제로 끌어올린다.** 만료·잔여일·경고처럼 놓치면 손해인 값은
  헤더 부제에 실어 접힌 상태에서도 읽히게 한다 (예: `회원권 / 만료됨 · 락커 A-08`).
  부제가 고정 문구면 내용 나열, 값이 있으면 값 우선.
- 아코디언 헤더에는 제목·부제만. 동작 버튼(변경·삭제 등)은 펼친 본문 안으로.
- 파괴적 동작(데이터 초기화 등)은 표 밖·아코디언 **안** 맨 아래에 `danger` 텍스트 버튼으로.
- 부연 안내(응대 시간 등)는 별도 줄로 띄우지 말고 해당 행의 `subtitle` 로 흡수.

## 7-D. 버튼 1종 강제 · 가시성 (v2.2 · 2026-08-12 사용자 지시 "가시성·버튼 편의 리디자인")

> 배경: 링코(`com.linkcoach`) 화면 27장 분석(`C:/dev/tools/linko-screens/REVIEW.md`)을
> 우리 골든 22장에 같은 잣대로 대본 결과. 링코가 지적당한 F1·F6·F7·F8 과 **구조가 같은
> 결함이 우리 앱에도 있었다** — 아래는 그 재발을 막는 규격이다.

### 버튼 = `HkButton` 하나뿐 (배지 1종 강제와 같은 등급)

| 종류 | 모양 | 쓰는 자리 |
|---|---|---|
| `HkButton.primary` | 채움 + 흰 글씨 · 높이 52 · r4 | **화면당 1개.** 지금 해야 할 단 하나 |
| `HkButton.secondary` | 외곽선 · 높이 52 · r4 | 같이 놓이는 대등한 선택지 |
| `HkButton.tertiary` | 글자만 · 터치 48 | 부수 동작·이동 |

- 옵션은 셋뿐이다: `expand`(전체폭 여부) · `neutral`(tertiary 글자색을 중립으로) ·
  `danger`(되돌릴 수 없는 동작 — primary 는 danger 채움, secondary 는 danger 테두리).
- **금지**: 화면에서 `GestureDetector`+`Container` 로 버튼 모양 직접 그리기 ·
  `minimumSize` 를 48 아래로 낮추기 · `TextButton.styleFrom(foregroundColor: muted)`
  (비활성처럼 보인다 — 중립이 필요하면 `neutral: true` = `fgSecondary`).
- 터치 48 은 `theme.dart` 의 `textButtonTheme`·`iconButtonTheme` 이 앱 전역에서 보장한다.
  화면에서 되돌리지 말 것.

### 가시성 규칙 (링코 대조로 도출)

1. **면을 브랜드색으로 덮지 않는다** (링코 F1). 카드 전체를 연한 브랜드색으로 채우면
   그 안 글자·라벨이 전부 색 위에 얹혀 대비가 깎인다. 강조는 **좌측 4px 바** 또는
   테두리 한 곳으로. 본문은 흰 면 위에 둔다.
2. **한 카드/화면에 브랜드색은 3곳까지.** 구획(바) → 분류(타입 라벨) → 동작(버튼) 순으로
   양보한다. 넷째부터는 `fg`/`fgSecondary` 로 내린다.
3. **진행도를 투명도로 표현하지 않는다.** 라이트 배경에서 반투명 브랜드색은 "덜 채워짐"이
   아니라 "비활성"으로 읽힌다. 채운 **길이**가 진행도를 말한다. 진행바 높이는 6.
4. **읽어야 하는 값에 `muted` 를 쓰지 않는다** (링코 F2). 내용은 `fg`/`fgSecondary`,
   `muted` 는 부연·비활성 전용. 입력 안내는 `placeholder`(#84848D).
5. **안내값과 입력값을 같은 모양으로 두지 않는다** (링코 F8). placeholder 는 색·굵기를
   낮추고, 숫자 모양(`000000`·`0kg`)보다 말(`6자리 숫자`)로 쓴다.
6. **같은 아이콘 2개를 라벨 없이 나란히 두지 않는다** (링코 F6). `TermTip` 은
   `showLabel: true` 로 용어 이름을 붙인다.
7. **빈 상태는 `HkEmptyState` 규격 하나** (링코 F7) — h3 제목 + caption. 화면마다
   제목 크기를 다르게 두지 않는다. 문구는 그 화면의 것으로 (다른 화면 문구 재사용 금지).
8. **같은 말을 두 번 쓰지 않는다.** AppBar title 과 화면 헤드라인(R1), 좌측 폼 라벨과
   입력칸 `labelText`, 섹션 라벨과 본문 첫 줄 — 겹치면 하나를 뺀다.
9. **누를 수 있는 행에는 신호를 준다.** `HkListRow` 는 `onTap` 이 있고 우측 값이 없으면
   화살표를 자동으로 붙인다.
10. **날짜·시각은 사람이 읽는 형식으로.** DB 원문(`2026-08-12T19:00:00`) 노출 금지.
    큰 수는 세 자리마다 쉼표(`1,570`).

## 7-C. 배지·칩 1종 강제 (v1.32 · 2026-08-07 사용자 지시 "1종으로 통합해라 강제로라도")

- **작은 라벨 조각은 `HkBadge` 하나뿐이다.** 표시(읽기 전용)든 선택(토글)이든 같은 위젯을 쓴다.
  구분은 인자로만 한다 — `onTap` 유무 = 표시/선택, `selected` = 면 채움 반전, `color` = 의미.
- **금지**: `_Pill`·`_MiniPill`·`_StatusChip`·`_CategoryChip`·`_PainChip`·`_chip` 같은
  화면 로컬 variant 신설. `BorderRadius.circular` 에 숫자 하드코드, `r4`(CTA 값) 를 칩에 사용,
  `Chip`/`ChoiceChip`/`FilterChip` 등 Material 기본 칩 위젯 사용.
  (v1.32 에서 위 11종 전수 폐기 — 모서리 5종·면 채움 3종이 난립했던 것이 원인.)
- 모양을 바꿔야 하면 **`hkit.dart` 의 HkBadge 부터** 고친다. 한 화면만 다르게 하고 싶다는 요구는
  거절 대상 — 색(`color`)으로만 구분한다.
- `TierBadge` 만 예외(티어 5색 전용 별도 정본). 코치 표시(`CoachBadge`)는 HkBadge 를 감싼
  **의미 배선**일 뿐 모양을 따로 갖지 않는다.
- **자동 게이트 = `test/badge_lint_test.dart`** (3종): ① 화면 로컬 Pill/Chip/Tag 선언 0건
  ② 인라인 선택 칩(`BoxDecoration` 안에서 `selected ?` 로 면·보더를 바꾸는 코드) 0건
  ③ Material 칩 위젯 0건. 배지가 아닌 컴포넌트(선택 상태를 갖는 카드 등)만
  `// badge-lint: ignore — 사유` 로 명시 면제한다.

## 8. 변경 절차

1. 양식 변경 = 이 문서 + 토큰/HKit 먼저 → 화면 적용 → 골든 재생성 → 갤러리.
2. 조상 값 변경은 `C:/dev/tools/appkit` 마스터에서 (`--check` 드리프트 0 유지).
3. CLAUDE.md 의 디자인·카피 요약이 이 문서와 어긋나면 이 문서가 이긴다 (§0-B 위임).
