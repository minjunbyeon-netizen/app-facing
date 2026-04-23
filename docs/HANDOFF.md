# HANDOFF - 2026-04-23 (v1.15 VISUAL_CONCEPT 전환 중)

> **이전 HANDOFF (v1.11)는 `docs/archive/` 로 이동 권장.** 이 문서는 v1.14 타이포 계층 정비 완료 + v1.15 VISUAL_CONCEPT (흑백·전사·Obsession) 대전환 진행 중 상태.

## 완료 (이번 세션)
- [x] **Level 1-7 완료**: foundation tokens / Splash-Intro / Onboarding 3 / Home-MyPage / History-Profile / Builder-Presets-Result / 공용 위젯 + CHANGELOG
- [x] **`docs/DESIGN_PLAYBOOK.md` v1.0** — M3+HIG 기반 타이포·컬러·공간 체계 + 30 체크리스트
- [x] **`docs/VISUAL_CONCEPT.md` v1.0** — 사용자 제공 10장 레퍼런스(흑백·전사·Obsession) SSOT. 5 라운드 /go 분석 통합.
- [x] **Tier 색 재배치** (v1.15 흑백 통일): Scaled #4A4A4A / RX #EE2B2B(유일 유채색) / RX+ #929292 / Elite #E0E0E0 / Games #FFFFFF
- [x] **Tier enum subtitle + quote** 추가: Motivation/Discipline/Obsession 3단 서사
- [x] `fontFamilySerif = 'BodoniModa'` 예약 (번들은 미완)
- [x] **Persona Round 1 (5명 명시)** 피드백 반영: Tier 색 +15% 밝기, Result 상단 컨텍스트 바
- [x] **Persona R2-R11 통합 consolidated** (25 액션 A1~A25). P0 5개 + P1 3개 실제 반영:
  - A7 `lib/core/glossary.dart` 신규 (20 용어)
  - A10/A16 Result 에러 V7 + 재시도 버튼
  - A11 Result _SegmentCard 'BURST' sectionLabel (accent)
  - A14 Home 헤드라인 한글 SSOT 일치 ("오늘 WOD.\nSplit 뽑아라.")
  - A17 Grade null 빈 상태 개선 (Start Onboarding CTA)
  - A19 _Pill ConstrainedBox minHeight 48
  - A20 Tier quote stableQuote → tier.quote 직결 (불일치 버그 수정)
- [x] **CHANGELOG.md** v1.14.0 기록
- [x] **GitHub 연동 + 자동 commit+push** (이번 세션 14+ 커밋)

## 진행중 — 남은 Persona P1/P2 (asset 없이 가능)
- [ ] **A5** Grade `_CategoryCard` Score LinearProgressIndicator 2px (tier.color)
- [ ] **A8** `GlossaryTip` 위젯 신규 + WOD Builder / Result long-press 툴팁
- [ ] **A9** WOD Builder 카테고리 첫 진입 hint SnackBar (1회 flag)
- [ ] **A12** Result 컨텍스트 바 tier 문자열 → `TierBadge` 위젯 교체
- [ ] **A13** Home: 마지막 WOD 1줄 요약 (history_repository 비동기)
- [ ] **A15** Result 로딩 상태 → `CircularProgressIndicator` + 랜덤 QuoteCard
- [ ] **A18** 11sp 미만 글꼴 금지 확인 (grep 후 승격)
- [ ] **A22** ElevatedButton scale press 0.97→1.0 (100ms) 애니메이션
- [ ] **A23** 주요 CTA에 `HapticFeedback.lightImpact()` 추가
- [ ] **A24** AppBar 아이콘 outlined 계열 통일
- [ ] **A25** _CategoryCard Scaled(#4A4A4A) border 대비 fallback (muted)

## 대기 — Asset 수급 필요
- [ ] **Bodoni Moda 폰트 번들**: `assets/fonts/BodoniModa/` 6 파일 다운로드 + pubspec.yaml 등록 + `google_fonts` 패키지. 그 후 `displaySerif`/`h1Serif`/`quoteSerif` 토큰 실제 적용
- [ ] **halftone PNG 2종**: `grain_subtle.png` (256×256, Unblast CC0) + `grain_strong.png` (512×512). `assets/textures/` 배치. `GrainOverlay` 위젯 구현
- [ ] **영웅 이미지 5~8장**: Unsplash CC0 (runner/warrior/barbell/athlete). `assets/images/hero_*.jpg`. Splash/Intro 3/Grade 화면 배경
- [ ] **스틱맨 SVG 3종**: `assets/icons/stickman_{motivation,discipline,obsession}.svg` (VC 섹션 6 스펙). A4 의존
- [ ] **pubspec.yaml** 의존성: `flutter_svg`, `google_fonts`

## 결정사항 / 주의

### 1. SSOT 우선순위
```
VISUAL_CONCEPT.md v1.0 > DESIGN_PLAYBOOK.md v1.0 > CLAUDE.md 디자인 시스템
```
시각 결정 충돌 시 VISUAL_CONCEPT가 이김. CLAUDE.md 최상단에 명시됨.

### 2. 컬러 정책 (v1.15)
- 흑백 + Red `#EE2B2B` **단일 accent**. 사용처 3곳 전용: Primary CTA 1개 / Burst segment / Destructive(Reset)
- `success #22C55E` / `warning #F59E0B` 토큰 유지하되 **실사용 금지**
- pure black/white 텍스트 금지 (#F5F5F5 ~ #9E9E9E)

### 3. Tier 서사
- overall_number 1~6 → 5 Tier 라벨 유지
- 서브타이틀: Motivation → Discipline → Obsession
- **RX만 유일한 유채색**
- `tier.quote` getter로 Tier별 고정 명언 (stableQuote는 Splash용만)

### 4. 폰트 정책
- 영문 선언 헤드라인 → Bodoni Moda Italic (번들 완료 후)
- 한글·UI·숫자 → Pretendard 유지
- `fontFamilyFallback: ['Pretendard']`

### 5. halftone 2단계
- 일상 배경: `grain_subtle` 0.04 opacity
- 드라마틱 순간: `grain_strong` 0.12

### 6. 법적 경고
- m1ndshoot / OPUS ATHLETICS 원본 이미지 **픽셀 복제·파생 금지**
- Unsplash/Pexels/Pixabay **CC0만** 사용
- 다운로드 시 라이선스 스크린샷 보관

### 7. 자동 commit+push
- `C:/dev/` 하위 → 자동 커밋·푸시 정책 유지
- Remote: `https://github.com/minjunbyeon-netizen/app-facing` (master)
- 최종 커밋: `79a525b feat(persona-r2-r11-p1): BURST label + Grade empty state + _Pill touchMin`

## 다음 세션 권장 첫 프롬프트
```
/resume
```
또는:
```
facing-app v1.15 asset 수급. 1) Unsplash CC0 runner silhouette 1장 → Splash 배경 적용 테스트 → 2) Bodoni Moda 번들 → 3) 남은 Persona P1 (A5/A8/A12/A15/A18)
```

## 관련 경로
| 역할 | 경로 |
|---|---|
| VISUAL CONCEPT SSOT | `docs/VISUAL_CONCEPT.md` |
| DESIGN PLAYBOOK | `docs/DESIGN_PLAYBOOK.md` |
| 프로젝트 CLAUDE.md | `CLAUDE.md` |
| CHANGELOG | `CHANGELOG.md` |
| 디자인 토큰 | `lib/core/theme.dart` |
| Tier | `lib/core/tier.dart` |
| 용어 glossary (신규) | `lib/core/glossary.dart` |
| 명언 | `lib/core/quotes.dart` |
| 백엔드 history | `services/facing/api/history.py` (5060) |

## 이전 HANDOFF
- `docs/archive/HANDOFF-2026-04-22.md` 로 이동 권장 (v1.11 기준)
