# facing-app DESIGN PLAYBOOK

> **v1.0.0 — 2026-04-23**
> 디자인 관련 모든 결정의 SSOT. `CLAUDE.md`의 "디자인 시스템" 섹션은 이 문서의 요약. 충돌 시 이 문서가 이김.
>
> 근거는 Material 3, Apple HIG, WCAG 2.1 AA, NNG(Nielsen Norman Group), WHOOP·Strava·Garmin·Hevy 등 엘리트 피트니스 앱 벤치마크에서 수집. 섹션별 각주로 출처 링크.

---

## 0. 적용 범위 & 우선순위

- 적용: `apps/facing-app/lib/**` 내 모든 Flutter UI 코드
- 충돌 시: **이 문서 > CLAUDE.md > rules/common/* > 프로젝트별 CLAUDE.md**
- 실행 규칙: 신규 화면·컴포넌트 설계 전에 이 문서 해당 섹션 먼저 읽고, 결정 3개 이상 이탈 시 문서 업데이트 제안
- 문서 수정: 사용자 승인 없이 자동 편집 금지

---

## 1. Voice & Tone (요약)

상세는 `CLAUDE.md` v1.13.0 "Voice & Tone" 섹션 참조. 이 문서는 **시각적 결정**을 다루며, 어투는 CLAUDE.md가 SSOT.

핵심:
- 명령형·반말 (V1)
- 영문 UI 라벨 + 한글 부연 설명 (V8, V10)
- 마침표 3분류: 단어 1개 = 없음, 선언문 = 유지, 수치 = 유지 (V1)
- 이모지 금지 (V4)
- 벤치마크 브랜드: HWPO, NOBULL, Mayhem, CompTrain

---

## 2. 타이포그래피

### 2.1 근거
- Material 3 Type Scale<sup>[1]</sup>: display/headline/title/body/label 5계층
- Apple HIG Typography<sup>[2]</sup>: Dynamic Type, 최소 11pt
- Modular Scale<sup>[3]</sup>: 1.2(Minor Third) ~ 1.333(Perfect Fourth) 모바일 권장

### 2.2 facing-app 스케일 (Pretendard 기반)

| 토큰 | size(sp) | weight | letterSpacing | line-height | 용도 |
|---|---|---|---|---|---|
| `brandLogo` | 72 | 800 | -2.4 | 1.0 | Splash "FACING" 전용 |
| `display` | 64 | 800 | -1.6 | 1.05 | 히어로 숫자 (총시간, Engine 점수) |
| `h1` | 44 | 800 | -1.1 | 1.12 | 화면 단일 히어로 (intro, split pattern) |
| `h2` | 30 | 700 | -0.6 | 1.18 | 화면 주 타이틀 (AppBar 없을 때) |
| `h3` | 20 | 700 | -0.2 | 1.30 | 섹션 타이틀, AppBar 기본, segment slug, pace |
| `lead` | 18 | 400 | 0 | 1.45 | intro body, segment estimated time |
| `body` | 15 | 400 | 0 | 1.50 | 본문 |
| `caption` | 13 | 400 muted | 0 | 1.45 | 부연 설명 |
| `sectionLabel` | 11 | 700 muted | +1.6 | 1.20 | **섹션 구분 라벨 전용**, 대문자 필수 |
| `micro` | 11 | 500 muted | +0.4 | 1.40 | 수치 보조 (items, %, points) |
| `tierLabel` | 12 | 800 | +1.8 | 1.0 | TierBadge 내부 |
| `bannerLabel` | 12 | 700 | +1.2 | 1.0 | Offline 등 배너 전용 |
| `quote` | 14 | 500 italic muted | +0.1 | 1.50 | 명언 전용 |

**스케일 비율 (실측)**: 11→13(1.18)→15(1.15)→18(1.20)→20(1.11)→30(1.50)→44(1.47)→64(1.45). 평균 1.27. Major Third(1.25) 근사. **건전**.

### 2.3 규칙 (T1~T8)

- **T1.** 하드코드 `TextStyle(fontSize: N)` 금지. 반드시 `FacingTokens.*` 토큰 참조.
- **T2.** 헤드라인(h1/h2)은 w700~800 + 음수 letterSpacing.
- **T3.** 대문자 라벨(sectionLabel/tierLabel/bannerLabel)은 양수 letterSpacing(+1.2~+1.8) + 코드에서 `toUpperCase()`.
- **T4.** 숫자 출력은 `fontFeatures: FacingTokens.tabular` (tabular figures) 적용. display/h1 이외에도 Split 숫자·Engine 점수·time display에 확장.
- **T5.** 본문 line-height 1.4~1.6, 헤드라인 1.0~1.2. 그 외 범위 금지.
- **T6.** 최소 글꼴 **11sp**. 더 작은 글자 필요하면 콘텐츠를 줄일 것, 글자 크기를 줄이지 말 것 (Apple HIG).
- **T7.** "섹션 헤더"로 사용할 스타일은 `sectionLabel` **1종만**. `micro`/`caption`/`h2 inline body.w800` 대체 사용 금지.
- **T8.** 동일 지표는 동일 토큰. "500m pace"=h3, "총 예상시간"=display, "TierBadge 라벨"=tierLabel — 화면 막론 고정.

---

## 3. 컬러 시스템

### 3.1 근거
- WCAG 2.1 AA<sup>[4]</sup>: 본문 4.5:1, 큰 텍스트 3:1
- Material 3 Tonal Surfaces<sup>[5]</sup>: elevation = surface lightness
- Dark Mode Best Practices<sup>[6]</sup>: OLED 번짐 방지 → pure black 지양

### 3.2 팔레트

| 토큰 | HEX | 용도 | WCAG |
|---|---|---|---|
| `bg` | `#0A0A0A` | 기본 배경 (L0) | - |
| `surface` | `#141414` | 카드/시트 (L1) | - |
| `surfaceOverlay` *(추가 예정)* | `#1E1E1E` | 모달/바텀시트 (L2) | - |
| `fg` | `#F5F5F5` | 본문 텍스트 | on bg: **19:1** ✓ |
| `muted` | `#8A8A8A` | 보조 텍스트 | on bg: **4.9:1** ⚠ 경계 |
| `border` | `#2A2A2A` | 테두리/divider | - |
| `accent` | `#EE2B2B` | CrossFit red (primary CTA) | large text ≥ 3:1 ✓ |
| `accentPressed` | `#CC2020` | 눌림 | - |
| `success` | `#22C55E` | +델타, 성취 | on bg: **8:1** ✓ |
| `warning` | `#F59E0B` | 주의 | on bg: **9.5:1** ✓ |
| Tier×5 | `#5A5A5A`/`#EE2B2B`/`#FF6B00`/`#C8A84B`/`#E8E8E8` | 티어 배지 fill | 각 TierBadge.textColor로 대비 확보 |

### 3.3 규칙 (C1~C7)

- **C1.** 순수 검정(`#000000`) 배경 금지. `#0A0A0A`부터 시작.
- **C2.** 순수 흰색(`#FFFFFF`) 텍스트 금지. `#F5F5F5`까지.
- **C3.** 본문 대비비 **4.5:1 이상**. 큰 텍스트/아이콘 **3:1 이상**.
- **C4.** 표면 계층 최대 3단계(bg/surface/surfaceOverlay). 더 필요하면 component별 border로 구분.
- **C5.** accent 색은 **CTA + 경고/destructive + Tier-RX 3가지 목적에만** 사용. 장식용 accent 금지.
- **C6.** 상태 색(success/warning) 의미 고정. 임의로 다른 곳에 사용 금지.
- **C7.** Tier 컬러는 `TierBadge`와 `_CategoryCard 좌측 bar`에서만. 다른 곳(텍스트·아이콘) 사용 금지.

### 3.4 Action Items
- [ ] `muted=#8A8A8A` 대비비 경계값 → `#929292` 이상으로 상향 검토
- [ ] `surfaceOverlay=#1E1E1E` 신규 토큰 추가 (모달/바텀시트용)

---

## 4. 공간 체계 (8pt Grid)

### 4.1 근거
- Material 3 Spacing<sup>[7]</sup>: 8dp 배수 원칙
- Apple HIG Layout<sup>[8]</sup>: 16pt 기본 수평 마진

### 4.2 토큰

| 토큰 | 값 | 용도 |
|---|---|---|
| `sp1` | 4 | 텍스트 간 최소 간격, 아이콘 padding |
| `sp2` | 8 | 인접 요소 최소 간격 (터치 안전거리) |
| `sp3` | 12 | Row 간 간격, 카드 내부 padding 경량 |
| `sp4` | 16 | 화면 좌우 마진, 카드 내부 padding 표준 |
| `sp5` | 24 | 섹션 간 수직 간격 |
| `sp6` | 32 | 대형 섹션 간격, hero 영역 |
| `sp7` | 48 | 화면 수직 중간 여백 |
| `sp8` | 64 | 화면 최상·최하 여백 |

### 4.3 Radius 토큰

| 토큰 | 값 | 용도 |
|---|---|---|
| `r1` | 4 | 입력 필드, 작은 배지 |
| `r2` | 8 | 버튼, 카드 표준 |
| `r3` | 12 | 카드 large, 로딩 다이얼로그 |
| `r4` | 16 | pill(토글), 배지 larger |
| `r5` *(추가 예정)* | 28 | 모달 시트, 전체 화면 카드 |

### 4.4 규칙 (S1~S4)

- **S1.** 모든 spacing/padding/margin은 **`FacingTokens.spN`만 사용**. 하드코드 숫자 금지.
- **S2.** 화면 좌우 가장자리 **최소 `sp4`(16dp)**.
- **S3.** 섹션 간 **`sp5`(24dp) 이상**, 카드 내부 padding **`sp4`(16dp) 이상**.
- **S4.** 인접 터치 타깃 간격 **최소 `sp2`(8dp)**. 실수 탭 방지.

---

## 5. 컴포넌트 규칙

### 5.1 버튼

| 종류 | 높이 | 패딩 | 배경 | 텍스트 | 용도 |
|---|---|---|---|---|---|
| `ElevatedButton` | `buttonH=52` | sp5 H / sp4 V | `accent` | `fg` w800 | Primary CTA (화면당 1개) |
| `OutlinedButton` | 52 | sp5 H / sp4 V | 투명 | `fg` w700, border 1px | Secondary action |
| `TextButton` | 48 | sp3 H | 투명 | `muted` or `accent` | Tertiary / destructive |

**규칙 (B1~B4)**:
- **B1.** 화면당 ElevatedButton 1개만. 2개 이상 Primary가 필요하면 우선순위 재검토.
- **B2.** 모든 탭 가능 위젯 최소 **48×48dp** 터치 영역. 시각 크기와 별개.
- **B3.** 버튼 text에 마침표 없음 (`Save`, `Next`, `Start WOD`). 단 "Calculating." 같은 진행 상태는 예외.
- **B4.** Destructive(Reset data) 액션은 `TextButton` + `foregroundColor: accent`로 격하.

### 5.2 카드 vs Divider vs Whitespace

**결정 트리** (H2 리서치 기반):
```
콘텐츠 구분이 필요한가?
├─ NO → Whitespace만 (sp5 간격)
└─ YES ↓
    탭/스와이프 가능한가?
    ├─ YES → 카드 (surface fill + 모서리 r2)
    └─ NO ↓
        같은 섹션 내 여러 아이템인가?
        ├─ YES → Divider 1px (border 색)
        └─ NO → Whitespace + 섹션 헤더(sectionLabel)만
```

**예시 매핑**:
- History 목록 = Divider (WOD 기록 row 반복)
- MyPage BODY/SETTINGS = Whitespace + sectionLabel (수직 스택)
- WOD Builder 동작 아이템 = 카드 (Dismissible 스와이프 가능)
- Grade Category = Divider + 좌측 tier bar (읽기 전용 결과)
- Result Segment = 카드 (폭발 segment는 accent border로 강조)

**규칙 (L1~L3)**:
- **L1.** 카드는 **탭 가능하거나 강조 필요**할 때만. 단순 정보 나열이면 Divider 또는 Whitespace.
- **L2.** 카드 중첩 금지 (카드 안에 카드). 필요하면 surface fill + border 대신 padding으로 구분.
- **L3.** Divider는 `height: 1, color: border`. 두께 증가·색 변형 금지.

### 5.3 입력 필드

- OutlineInputBorder 1px, radius r2
- focus 시 border color `fg` (accent 아님 — 진행 중이지 destructive 아님)
- hint는 `caption` + muted. label은 상단 body + w700
- 숫자 입력은 `tabular figures` 자동 적용 (body + tabular)

### 5.4 TierBadge

- fill 방식 (v1.13~): 배경 = `tier.color`, 텍스트 = `tier.textColor`
- 기본 fontSize 12 (Row 내 인라인), 큰 표시 시 24
- padding: 작은 것 H8/V3, 큰 것 H12/V6
- radius `r2`, border 없음
- **배지 외부에 Tier 이름 텍스트 반복 금지** (정보 중복)

### 5.5 명언 카드

- `quote` 스타일 (14sp italic muted)
- 카드 경계 없음 (순수 텍스트 + padding)
- Splash/Grade/Loading 3곳 고정

---

## 6. 화면 패턴

### 6.1 AppBar 정책

- **titleTextStyle**: `h3` (theme 기본). 오버라이드 금지.
- **centerTitle**: `true`.
- **height**: 52 (`appBarH`).
- **border**: 하단 1px `border` 색 (구분선).
- **title 길이**: 짧은 식별자만. "Step 1 / 6", "Profile", "History" 식. **카테고리명/상세 정보는 title에 넣지 않음**.
- 화면 내 주 타이틀(h2)이 있으면 AppBar title은 **위치/식별자 전용**, 중복 금지 (v1.14 규칙 R1).

### 6.2 결과 화면 (Grade / Result / History Detail)

- 최상단: 히어로 숫자(`display` 64sp) + 단위/설명(`caption`)
- 그 아래: TierBadge(24sp) + Score 1줄 — **최대 2겹**
- 섹션: `sectionLabel` 대문자 라벨 + Divider
- 폭발 정보: `accent` border 2px (시각적 강조)

### 6.3 리스트 화면 (History / Presets)

- `ListView.separated` + `Divider(height: 1, color: border)`
- 각 row: 좌측 식별자/배지 + 중앙 텍스트 2단(w700 + caption) + 우측 수치(h3)
- InkWell로 전체 row 탭 가능

### 6.4 온보딩 위저드 (Basic / Benchmarks / Grade)

- AppBar: `Step N / 6` (진행 위치만)
- 상단: 진행바(`LinearProgressIndicator` 4dp)
- 본문 상단: h2 주 타이틀 (Body / POWER / OLYMPIC…)
- 본문: caption 부연 설명 (한글 허용)
- 하단 nav: Back(Outlined) + Next(Elevated) Row

### 6.5 MyPage / 설정 화면

- Divider 구조 (카드 없음)
- 섹션 헤더: `sectionLabel` 대문자
- 각 섹션은 좌우 sp4 padding, 섹션 간 sp5
- Destructive 액션(Reset)은 TextButton + accent

---

## 7. 정보 계층 규칙 (H1~H6)

- **H1.** 화면당 **H1 1개**만. AppBar title + 화면 h2 = 이중 타이틀 금지.
- **H2.** 최대 중요도 정보는 **display 또는 h1**로 1개만. 다른 정보는 그 크기를 넘지 말 것.
- **H3.** Z-pattern 적용 — 좌상단 시작, 우상단 액션, 좌하단 보조, 우하단 CTA.
- **H4.** Gestalt proximity — 관련 정보는 sp3 이하 간격, 무관 정보는 sp5 이상.
- **H5.** Gestalt similarity — 같은 종류 정보는 같은 토큰/컴포넌트 사용.
- **H6.** Dieter Rams "Less but better" — 정보 표시 3겹 이상 중복되면 제거 후보.

---

## 8. 접근성 최소 기준 (A1~A6)

- **A1.** 본문 대비 **4.5:1**, 큰 텍스트 **3:1** 이상 (WCAG 2.1 AA).
- **A2.** 최소 터치 타깃 **48×48dp** (Material 3). iOS 44pt도 최소 기준 충족.
- **A3.** 최소 글꼴 **11sp**. 그 이하는 정보 축약.
- **A4.** 색만으로 정보 전달 금지 (색맹 대응). Tier는 색 + 라벨 텍스트 병행.
- **A5.** `SafeArea` 모든 화면에 적용 (노치/홈 인디케이터 회피).
- **A6.** Android 물리 Back 버튼 처리 (`PopScope` 또는 `WillPopScope`). 위저드 화면은 단계별 back 제공.

---

## 9. 금지 사항 (Anti-patterns)

### 9.1 타이포
- `Text(..., style: TextStyle(fontSize: N))` 인라인 하드코드
- 섹션 헤더에 `micro` / `caption` / `body.w800 inline` 사용
- 11sp 미만 글꼴
- 순수 흰색(#FFFFFF) 또는 순수 검정(#000000) 텍스트

### 9.2 컬러
- pure black 배경
- accent를 장식용으로 사용 (CTA/경고/Tier-RX 아닌 곳)
- Tier 컬러를 텍스트 색으로 사용

### 9.3 레이아웃
- 카드 안에 카드 (중첩)
- 한 화면에 Primary ElevatedButton 2개 이상
- AppBar title + 화면 h2 이중 타이틀
- 동일 정보 3겹 이상 중복 표시 (예: OVERALL 라벨 + N/6 숫자 + TierBadge + Score)
- 하드코드 `EdgeInsets.all(20)` 등 8dp 배수 아닌 spacing

### 9.4 모션
- 300ms 초과 화면 전환
- 과도한 scale animation (0.95 미만)
- 무분별한 `HapticFeedback.heavyImpact` (PR 달성 등 의미 있는 순간 한정)

### 9.5 카피
- 이모지 (V4)
- 한 문장 내 영문-한글 혼용 ("Split**이** 순위를")
- 단어 1개 라벨 뒤 마침표 (`Save.` `Next.`)

---

## 10. 레퍼런스 링크

### 공식 가이드라인
1. [Material Design 3 — Type Scale Tokens](https://m3.material.io/styles/typography/type-scale-tokens)
2. [Apple Human Interface Guidelines — Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
3. [Material 3 — Corner Radius Scale](https://m3.material.io/styles/shape/corner-radius-scale)
4. [WCAG 2.1 SC 1.4.3 — Contrast Minimum](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)
5. [Material 3 — Tone-based Surfaces](https://m3.material.io/blog/tone-based-surface-color-m3)
6. [Atmos — Dark Mode UI Best Practices](https://atmos.style/blog/dark-mode-ui-best-practices)
7. [Material 3 — Spacing](https://m3.material.io/foundations/layout/understanding-layout/spacing)
8. [Apple HIG — Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
9. [Material 3 — Motion Tokens](https://m3.material.io/styles/motion/easing-and-duration/tokens-specs)
10. [Material 3 — Navigation Bar](https://m3.material.io/components/navigation-bar)
11. [Material 3 — Color Roles](https://m3.material.io/styles/color/roles)
12. [Flutter — HapticFeedback API](https://api.flutter.dev/flutter/services/HapticFeedback-class.html)
13. [Flutter — Shimmer Loading Cookbook](https://docs.flutter.dev/cookbook/effects/shimmer-loading)

### UX 이론
14. [NNG — Visual Hierarchy in UX](https://www.nngroup.com/articles/visual-hierarchy-ux-definition/)
15. [NNG — F-Shaped Pattern Eye Tracking](https://www.nngroup.com/articles/f-shaped-pattern-reading-web-content-discovered/)
16. [IxDF — Visual Hierarchy & Eye Movement](https://ixdf.org/literature/article/visual-hierarchy-organizing-content-to-follow-natural-eye-movement-patterns)
17. [IxDF — Dieter Rams 10 Principles](https://ixdf.org/literature/article/dieter-rams-10-timeless-commandments-for-good-design)
18. [Tubik Studio — Visual Dividers in UI](https://blog.tubikstudio.com/visual-dividers-user-interface/)
19. [Modular Scale Generator](https://www.modularscale.com/)

### 벤치마크 앱
20. [WHOOP Developer Design Guidelines](https://developer.whoop.com/docs/developing/design-guidelines/)
21. [WHOOP — New Home Screen](https://www.whoop.com/us/en/thelocker/the-all-new-whoop-home-screen/)
22. [Strava UI/UX Case Study (Medium)](https://medium.com/@wjun8815/ui-ux-case-study-strava-fitness-app-0fc2ff1884ba)
23. [DesignRush — Strava Design](https://www.designrush.com/best-designs/apps/strava-2)
24. [DC Rainmaker — Garmin Connect Revamp](https://www.dcrainmaker.com/2024/01/garmin-connect-mobile-revamp-walk-through.html)
25. [SugarWOD 공식](https://www.sugarwod.com/)

### 브랜드 보이스 벤치마크
26. HWPO Training — 공식 디자인 스펙 비공개. [앱스토어 스크린샷](https://apps.apple.com/us/app/hwpo-training-app/id1605177791)
27. [NOBULL Project](https://www.nobullproject.com)
28. [Mayhem Nation](https://www.mayhemnation.com/)
29. [CompTrain](https://comptrain.com)

### Shape Up
30. [Shape Up — Basecamp](https://basecamp.com/shapeup)

---

## 부록 A. 개편 Action Items (우선순위)

### P0 (이번 스프린트)
- [ ] `surfaceOverlay=#1E1E1E` 토큰 추가 (theme.dart)
- [ ] `r5=28` 토큰 추가 (theme.dart) — 모달 시트용
- [ ] `touchMin` 44→48 상향 (theme.dart) — M3 표준 맞춤
- [ ] `muted=#8A8A8A` 대비 재측정 → 필요 시 `#929292` 이상으로 상향

### P1 (다음 스프린트)
- [ ] 결과 로딩 → `shimmer` 스켈레톤 UI 도입
- [ ] Split·Engine 수치 위젯에 `tabularFigures` 적용 확장
- [ ] Android `PopScope`로 Back 버튼 처리 전수 점검
- [ ] `HapticFeedback.lightImpact` 주요 버튼 적용 (첫 단계)

### P2 (v2 확장 시)
- [ ] Bottom Navigation 도입 (탭 3~5개 확장 시)
- [ ] `surfaceOverlay` 기반 모달/바텀시트 컴포넌트 추가
- [ ] Dynamic Type 대응 (iOS 진입 시)

---

## 부록 B. 앱별 벤치마크 한 줄 요약

| 앱 | 테마 | Accent | 차용할 패턴 |
|---|---|---|---|
| WHOOP | 다크 | 시안 #00D4FF | 큰 metric 다이얼 3개 (Recovery/Strain/Sleep 패턴) |
| Strava | 다크/혼합 | 주황 #FC5200 | Leaderboard row (현재 사용자 하이라이트) |
| Garmin Connect | 다크 | 중립 | 4~8개 KPI 타일 그리드 (사용자 재배치 가능) |
| Hevy | 다크 | 파랑 | Sharp 카드, 모서리 r1~r2, 강한 경계 |
| Peloton | 다크 | 네온 빨강 #FF1744 | 실시간 leaderboard + 큰 CTA |
| SugarWOD | 다크 | 원색 강렬 | WOD 기록 row + 점수 강조 배지 |
| HWPO | 공개 스펙 없음 | Black/White/Cream 추정 | 섹션식 네비게이션, 미니멀 |
| NOBULL | 라이트 | 모노크롬 | Whitespace 중심, ALL-CAPS 섹션 |
| Mayhem | 라이트 | 검정 | 카드 + 여백, 대문자 섹션 라벨 |
| CompTrain | 라이트 | 검정 | 카드 최소, 내러티브 중심 |

---

## 버전 이력
- **v1.0.0 (2026-04-23)**: 최초 작성. H1(타이포), H2(계층·Gestalt), H3(벤치마크 10앱), S1(M3+HIG 체크리스트 30) 리서치 종합.
