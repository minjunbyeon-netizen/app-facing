# facing-app VISUAL CONCEPT — 흑백·전사·Obsession

> **v1.0.0 — 2026-04-23**
> 사용자가 제공한 10장 레퍼런스 이미지(Muhammad Ali running, Sisyphus, Jon Snow, stickman evolution, halftone serif quotes 등)를 **5 라운드 /go 조사**로 분석하여 도출한 비주얼 컨셉 SSOT.
>
> **이 문서 > DESIGN_PLAYBOOK.md > CLAUDE.md 디자인 시스템**. 시각 관련 결정 충돌 시 이 문서가 이김.

---

## 0. 한 줄 컨셉

> **"흑백. 전사. Obsession."**
> motivation → discipline → obsession 3단 진화 서사. don't give up 정신. halftone grain 인쇄물 질감. 극도 절제된 color + 풀블리드 영웅 이미지.

---

## 1. 핵심 시각 DNA (6 Keyword)

| # | Keyword | 의미 |
|---|---|---|
| 1 | **Monochrome Absolutism** | 흑백 100%, 유일한 유채색 = `#EE2B2B` (RX tier + burst + CTA) |
| 2 | **Halftone Texture Layer** | 인쇄물 dot/grain, 디지털이 아닌 아날로그 신뢰감 |
| 3 | **Serif Italic Authority** | Bodoni Moda Italic — 법전·경전·선언문의 무게 |
| 4 | **Heroic Narrative Arc** | Ali / Jon Snow / Sisyphus / chained warrior — 개인의 투쟁과 승리 |
| 5 | **3-Phase Metamorphosis** | motivation → discipline → obsession, Tier 진화 서사 |
| 6 | **Negative Space Dominance** | 텍스트는 절제, 이미지와 여백이 무대 |

---

## 2. 레퍼런스 이미지 10장 — 무드 참조용 (복제 금지)

사용자 제공 이미지 (m1ndshoot 인스타 게시물 / OPUS ATHLETICS 워터마크):
1. **Muhammad Ali 러닝** — `[discipline]` + "Do what's necessary, not what's easy"
2. **스틱맨 진화 (비 내리는 배경)** — motivation 엎드림 → discipline 엎드림 → obsession 달림
3. **스틱맨 진화 (명확 버전)** — 3단 러닝 포즈 진화
4. **Sisyphus 잉크 스케치** — `"Yes."` + 거대 구체 밀어올리기
5. **"what if I fall? bro what if you fly"** — halftone grain serif italic
6. **"i must. become better."** — 세리프 이탈릭 손 실루엣
7. **"Winner."** — 사전 정의 포맷 "noun: someone who does not make excuses"
8. **Jon Snow Battle of Bastards** — `"No risk. No story."` 흑백 영화 프레임
9. **사슬 근육 전사 (Darth Vader-esque)** — halftone, 사슬 찢기
10. **인스타 릴스 포맷 참고용** — 세로 9:16, 하단 소셜 오버레이

**법적 경고**: 위 이미지들은 OPUS ATHLETICS © 2024 및 m1ndshoot 저작물. **픽셀 복제·파생 금지**. "스타일·구성·톤" 학습 레퍼런스로만 활용. facing-app 자체 이미지는 **Unsplash/Pexels/Pixabay CC0**에서만 수급.

---

## 3. 확정 결정 (5 라운드 분석 결과)

### 3.1 컬러 팔레트 — 안 B 채택 (흑백 + Red 단일 accent)

| 토큰 | Before (v1.14) | After (v1.15 — 이 컨셉) | WCAG on bg |
|---|---|---|---|
| `bg` | `#0A0A0A` | `#0A0A0A` | - |
| `surface` | `#141414` | `#141414` | - |
| `surfaceOverlay` | `#1E1E1E` | `#1E1E1E` | - |
| `fg` | `#F5F5F5` | `#F5F5F5` | 19:1 ✓ |
| `muted` | `#9E9E9E` | `#9E9E9E` | 6.1:1 ✓ |
| `border` | `#2A2A2A` | `#2A2A2A` | - |
| `accent` | `#EE2B2B` | `#EE2B2B` (용도 1개로 축소) | 3.2:1 ✓ large |
| `success` | `#22C55E` | **흰색 `#F5F5F5`로 대체** | - |
| `warning` | `#F59E0B` | **muted `#9E9E9E`로 대체** | - |

**accent 사용 허용처 (3곳 전용)**:
- Primary CTA 버튼 1개 (화면당)
- Burst segment border (Result 화면 폭발 세그먼트 강조)
- 파괴적 액션 텍스트 (Reset data)

### 3.2 Tier 재설계 — 라벨 유지 + 명도 재배치 + 서브타이틀 추가

| # | Tier | Before color | After color | 서브타이틀 | 명언 (고정) |
|---|---|---|---|---|---|
| 1-2 | Scaled | `#5A5A5A` | `#4A4A4A` | **Motivation.** | "The only way out is through." |
| 3 | **RX** | `#EE2B2B` | `#EE2B2B` **(유일 유채색)** | **Discipline.** | "Do the work. Every day." |
| 4 | RX+ | `#FF6B00` | `#929292` | **Discipline+.** | "Comfort is the enemy of progress." |
| 5 | Elite | `#C8A84B` | `#C8C8C8` | **Obsession.** | "Impossible isn't far." |
| 6 | Games | `#E8E8E8` | `#F0F0F0` | **Obsession.** | "Everyone wants to win. Not everyone wants to prepare." |

**논리**: 어둠에서 빛으로. 숫자가 올라갈수록 명도 상승. RX는 유일한 Red — "기준선, 넘으면 비로소 보인다."

### 3.3 폰트 — Bodoni Moda Italic (영문) + Pretendard (한글/UI/숫자)

**최종 선택**: **Bodoni Moda** (Google Fonts, SIL OFL)
- URL: https://fonts.google.com/specimen/Bodoni+Moda
- 선정 이유: Didone 극고대비 flat serif → 다크 배경에서 hairline 소실 최소. 14sp quote부터 64sp display까지 가독. CrossFit 긴장감과 완벽 매치.
- 비선 후보: Cormorant Garamond (14sp flicker 위험), Playfair Display (2023 기준 너무 흔함)

**이중 폰트 매핑**:

| 용도 | 폰트 |
|---|---|
| 영문 선언 헤드라인 (`display`, `h1`) | Bodoni Moda Italic w700~800 |
| 명언 (`quote`) | Bodoni Moda Italic w500 |
| 한글 본문 + UI 라벨 + 버튼 텍스트 | Pretendard (기존 유지) |
| 숫자 타이머·결과 | Pretendard w800 tabular (기존 유지) |

`fontFamilyFallback: ['Pretendard']` — 혼용 문장에서 한글 자동 fallback.

### 3.4 halftone — 2종 PNG overlay

| 파일 | 크기 | 강도 | 용도 |
|---|---|---|---|
| `assets/textures/grain_subtle.png` | 256×256 tileable | opacity 0.04, BlendMode.overlay | 모든 화면 기본 배경 레이어 |
| `assets/textures/grain_strong.png` | 512×512 tileable | opacity 0.10~0.12, BlendMode.overlay | Splash, Grade 결과, Result 숫자 뒤 (드라마틱 순간) |

**소싱**:
- 기본: [Unblast Free Halftone Dot Textures](https://www.unblast.com/free-halftone-dot-textures-svg-png/) (CC0)
- 대안: [Transparent Textures](https://www.transparenttextures.com/) / [Unsplash Grain](https://unsplash.com/s/photos/grain-texture)

**구현**:
```dart
class GrainOverlay extends StatelessWidget {
  final Widget child;
  final String assetPath;
  final double opacity;
  const GrainOverlay({
    required this.child,
    this.assetPath = 'assets/textures/grain_subtle.png',
    this.opacity = 0.04,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      child,
      Positioned.fill(
        child: IgnorePointer(
          child: Image.asset(
            assetPath,
            repeat: ImageRepeat.repeat,
            fit: BoxFit.none,
            color: Colors.white.withOpacity(opacity),
            colorBlendMode: BlendMode.overlay,
          ),
        ),
      ),
    ]);
  }
}
```

### 3.5 영웅 이미지 — Unsplash CC0 5~8장

**검색 쿼리**:
1. `black and white runner silhouette` — Splash, Intro 1
2. `warrior silhouette dark dramatic` — Intro 3
3. `barbell overhead silhouette monochrome` — Intro 2
4. `athlete closeup portrait dark` — Grade 결과 (tier별 고정)
5. `strength training black white` — MyPage 히어로

**저장**: `assets/images/hero_*.jpg` (원본 JPEG, 모바일 1080×1920, 70% 압축)

---

## 4. 타이포그래피 토큰 재정의 (v1.15)

기존 FacingTokens 확장. 변경 파일: `lib/core/theme.dart`.

### 4.1 신규 토큰
- `fontFamilySerif = 'BodoniModa'`
- `displaySerif` — Bodoni Moda Italic 64sp w700 (영문 전용)
- `h1Serif` — Bodoni Moda Italic 44sp w700
- `h2Serif` — Bodoni Moda Italic 30sp w600 (카테고리·섹션 선언형)
- `quoteSerif` — Bodoni Moda Italic 14~16sp w500 muted

### 4.2 기존 토큰 유지
display/h1/h2/h3/body/caption/micro/sectionLabel/tierLabel/brandLogo/bannerLabel — 한글·UI·숫자 유지

### 4.3 Tier 재배치 (Tier enum / FacingTokens)
```dart
// core/theme.dart 색상 업데이트
static const Color tierScaled = Color(0xFF4A4A4A);   // 진회색
static const Color tierRx = Color(0xFFEE2B2B);       // 유일 유채색 (유지)
static const Color tierRxPlus = Color(0xFF929292);   // 중간 회색 (주황→회색)
static const Color tierElite = Color(0xFFC8C8C8);    // 밝은 회색 (금→회색)
static const Color tierGames = Color(0xFFF0F0F0);    // near-white (실버→near-white)

// 신규: Tier enum에 subtitle 추가
enum Tier {
  scaled('SCALED', 'Motivation.', tierScaled, fg),
  rx('RX', 'Discipline.', tierRx, fg),
  rxPlus('RX+', 'Discipline+.', tierRxPlus, bg),
  elite('ELITE', 'Obsession.', tierElite, bg),
  games('GAMES', 'Obsession.', tierGames, bg);
  // ...
}
```

---

## 5. 화면별 적용 스펙 (13화면)

| 화면 | Layout | Image | Fonts | Grain | Accent | Tier 표기 | P |
|---|---|---|---|---|---|---|---|
| Splash | 히어로 풀블리드 + 중앙 brandLogo + 하단 quote | runner silhouette | brandLogo Pretendard / quote Bodoni italic | strong 0.12 | circular progress | 없음 | P0 |
| Intro 1 | 이미지 상 60 / 텍스트 하 40 | box jump silhouette | h1Serif 40sp + caption | subtle 0.04 | 없음 | 없음 | P1 |
| Intro 2 | 풀블리드 + 중앙 정렬 | barbell overhead | h1Serif 36sp + caption | subtle 0.04 | bullet 6px circle | 없음 | P1 |
| Intro 3 | 풀블리드 + 하단 CTA | warrior silhouette | h1Serif 52sp | strong 0.12 | CTA bg | 없음 | P0 |
| Onboarding Basic | 폼 중심 | 없음 | h2 Pretendard title + body | 없음 | focus border | 없음 | P1 |
| Onboarding Benchmarks | 탑바 + 폼 | 없음 | cat label Bodoni italic + input | 없음 | focus border | 없음 | P1 |
| Onboarding Grade | 히어로 이미지 + Tier + Score + CTA | tier별 고정 이미지 | TierBadge 48 + h1Serif subtitle + timer Score | subtle 0.04 | RX만 accent | **48sp + subtitle + 명언** | P0 |
| Home | 헤드 + tier sm + CTA 2버튼 | 없음 | h1Serif 28sp | subtle 0.04 | CTA bg | 우측 상단 sm | P0 |
| MyPage | tier 중형 + 설정 리스트 | 없음 | Pretendard | 없음 | 없음 | 중앙 32sp | P2 |
| History | 타임라인 + sparkline | 없음 | 날짜 Bodoni italic + WOD Pretendard | 없음 | sparkline 선 | 카드 sm | P2 |
| History Detail | Result 재현 | 없음 | Result 동일 | subtle 0.04 | Result 동일 | - | P2 |
| Result | 메인 숫자 + split + segments | 없음 | timer 80 + segment Bodoni | subtle 0.04 | Burst 2px bar | 상단 우 sm | P0 |
| WOD Builder | 카테고리 탭 + 그리드 | 없음 | Pretendard | 없음 | 선택 border | 없음 | P1 |
| Presets | 카드 리스트 | 없음 | Pretendard | 없음 | 즐겨찾기 star | 없음 | P2 |
| Profile | 섹션 폼 | 없음 | Pretendard | 없음 | 저장 CTA | 없음 | P1 |

---

## 6. Obsession 스틱맨 아이콘 3종 (SVG)

**공통 스펙**: viewBox 0 0 24 24 / stroke #FFFFFF / strokeWidth 1.5 / fill none / transparent bg

- **Motivation** — 달리는 사람, 무게 중심 앞으로
- **Discipline** — 역기 들고 있는 사람 (overhead press)
- **Obsession** — 자세 잡고 응시 (대기·집중 포즈)

저장: `assets/icons/stickman_motivation.svg` / `_discipline.svg` / `_obsession.svg`. 패키지: `flutter_svg`.

---

## 7. 적용 순서 (P0 → P2)

### P0 — 브랜드 각인 (먼저)
1. Foundation: `theme.dart` Tier 색 재배치, 신규 토큰 (displaySerif 등), Bodoni Moda 번들
2. Splash — 히어로 + grain_strong
3. Intro 3 — 풀블리드 warrior + accent CTA bar
4. Onboarding Grade — Tier + subtitle + 명언
5. Home — 헤드 serif + tier sm
6. Result — timer 80sp + Burst accent

### P1 — 플로우 필수
7. Intro 1, 2
8. Onboarding Basic/Benchmarks
9. WOD Builder, Profile

### P2 — 보조
10. MyPage, History, History Detail, Presets

---

## 8. 금지 사항

- pure black `#000000` 배경
- accent를 장식용으로 사용 (CTA/Burst/Reset 외)
- Tier 컬러를 일반 텍스트·아이콘 색으로 사용
- 원본 레퍼런스 이미지(m1ndshoot, OPUS ATHLETICS) 픽셀 복제·파생
- 영문 헤드라인 + 한글 조사 혼용 (V9 유지)
- 11sp 미만 글꼴
- Bodoni Moda를 한글 본문에 사용 (fallback은 허용)

---

## 9. CLAUDE.md 참조 규칙

- 신규 UI/카피 작성 시 **항상 이 문서(VISUAL_CONCEPT.md) 섹션 확인**
- 톤앤매너 → 섹션 1 "핵심 시각 DNA"
- 스타일 → 섹션 4 "타이포 토큰"
- 컨셉 → 섹션 0 "한 줄 컨셉" + 섹션 2 "레퍼런스 이미지"
- Voice & Tone 관련은 `CLAUDE.md` v1.14 Voice & Tone 섹션과 병행 (충돌 시 이 문서가 이김)

---

## 10. 버전 이력

- **v1.0.0 (2026-04-23)** — 최초 작성. 5 라운드 /go 분석 결과 통합:
  - R1 이미지 패턴 추출 (4 agents)
  - R2 경쟁 브랜드 심화 (OPUS/HWPO/Rogue/Gymshark)
  - R3 폰트 최종 (Cormorant → Bodoni Moda 변경)
  - R4 halftone PNG 스펙 확정 (subtle/strong 2종)
  - R5 화면 매핑 + 등급 재설계 최종
