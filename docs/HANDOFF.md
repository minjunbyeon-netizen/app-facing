# HANDOFF - 2026-04-24 07:18 (v1.15 자산 연결 완료 · 페르소나 10명 조사 대기)

> 이전 HANDOFF (v1.15 전환 중)는 commit `7228034`에 스냅샷. 이 문서는 자산 파이프라인 일괄 생성 + 3 화면 실제 연결 완료 후 상태. **다음 세션 첫 작업 = 페르소나 10명 × 전 단계 UX/UI 피드백 조사.**

## 완료 (이번 세션 추가분 — 14m)

- [x] **Halftone PNG 2종 자체 생성** — Python PIL (`scripts/gen_grain.py`)
  - `assets/textures/grain_subtle.png` 256² (opacity 0.04)
  - `assets/textures/grain_strong.png` 512² (opacity 0.12)
- [x] **Hero placeholder 5장 자체 생성** — Python PIL (`scripts/gen_hero.py`)
  - `assets/images/hero_{splash,intro_1,intro_2,intro_3,grade}.jpg` (1080×1920)
  - 흑백 dark radial gradient + noise + vignette + rim light band
  - 추후 Unsplash CC0 실사진으로 덮어쓰기 가능 (파일명 그대로 교체)
- [x] **Stickman SVG 3종 직접 작성** — `assets/icons/stickman_{motivation,discipline,obsession}.svg`
  - motivation: 직립 정면, ground line
  - discipline: 달리는 mid-stride + motion dashes
  - obsession: Sisyphus 바위 밀기 (slope + boulder + 양팔 push)
- [x] **의존성 추가** — `google_fonts ^6.2.1` + `flutter_svg ^2.0.10+1`
  - Bodoni Moda는 런타임 fetch (번들 파일 불필요, SIL OFL)
- [x] **theme.dart serif 토큰 실제 연결** — `brandSerif` / `h1Serif` / `displaySerif` / `quoteSerif` (GoogleFonts.bodoniModa italic)
- [x] **GrainOverlay + HeroBackground 위젯 신규** — `lib/widgets/{grain_overlay,hero_background}.dart`
- [x] **Splash / Intro 1-3 / Grade 연결** — HeroBackground + GrainOverlay + Bodoni Italic 헤드라인 실 적용
- [x] **release APK 재빌드 + 에뮬레이터 설치 + 3 화면 캡처 검증**
  - `docs/screenshots/v1.15_{splash,intro2,intro3,current}.png`
  - Intro 1/2/3 스틱맨·halftone·Bodoni Italic 모두 실기 렌더링 확인
- [x] **commit `e930298` push 완료** (origin/master)

## 진행중 — 다음 세션 첫 작업 (사용자 직접 지시)

### [ ] **페르소나 10명 × 전 단계 UX/UI 피드백 조사 (/go 파이프라인)**
사용자 지시 원문: "페르소나 10명 데리고와서, 체중입력부터해서 전부 직접 시켜보고, ux, ui 적인 측면에서 피드백 조사 /GO"

**실행 계획**:
1. 페르소나 10명 정의 (성별·연령·Tier·디바이스 친숙도·CrossFit 경력 다양성 확보)
2. 각 페르소나 → Onboarding Step 1 (체중·키·성별·경력) → Step 2 (Benchmarks) → Loading → Grade → Home 전 단계 시뮬레이션
3. 단계별 피드백 수집:
   - 터치 타겟(48dp), 가독성(WCAG AA), 용어 이해도, 속도 인지, 혼동 지점, 미학·브랜드 톤
4. 공통 이슈 P0/P1/P2 분류
5. P0 즉시 반영 → 재빌드 → 재검증 → commit+push
6. 결과 `docs/PERSONA_FEEDBACK_v1.15.md` SSOT 문서화

**권장 팀 구성** (Phase 2 병렬):
- Haiku × 3: 페르소나 프로파일 생성(페르소나 1-3/4-6/7-10), 각 페르소나별 단계별 나레이션+피드백 리포트
- Sonnet × 2: 종합 이슈 분류 P0/P1/P2, `PERSONA_FEEDBACK_v1.15.md` 최종 초안 작성

## 대기 — Asset 업그레이드 (선택)

- [ ] **Hero placeholder → Unsplash CC0 실사진 교체** (5장)
  - 검색어: `black and white athlete`, `barbell dark`, `runner silhouette`, `crossfit monochrome`
  - 라이선스 스크린샷 필수 보관
  - 파일명 그대로 덮어쓰기 → 재빌드만 하면 끝
- [ ] **Home / WOD Builder / Result 화면 hero 배경** 미적용 (의도적 — 결과 화면 가독성 vs 배경 간섭 검토 필요)
- [ ] **stickman SVG 디테일 업그레이드** — 현재 minimal line art, 취향에 따라 거친 느낌 강화 가능

## 대기 — 남은 Persona P1 코드 액션 (asset 독립)

- [ ] **A5** Grade `_CategoryCard` Score LinearProgressIndicator 2px (tier.color)
- [ ] **A8** `GlossaryTip` 위젯 + WOD Builder / Result long-press 툴팁
- [ ] **A9** WOD Builder 카테고리 첫 진입 hint SnackBar (1회 flag)
- [ ] **A12** Result 컨텍스트 바 tier 문자열 → `TierBadge` 교체
- [ ] **A13** Home: 마지막 WOD 1줄 요약 (history_repository 비동기)
- [ ] **A15** Result 로딩 상태 → CircularProgressIndicator + 랜덤 QuoteCard
- [ ] **A18** 11sp 미만 글꼴 검증 (grep 후 승격)
- [ ] **A22** ElevatedButton scale press 0.97→1.0 (100ms)
- [ ] **A23** HapticFeedback.lightImpact() 주요 CTA
- [ ] **A24** AppBar 아이콘 outlined 통일
- [ ] **A25** _CategoryCard Scaled(#4A4A4A) border contrast fallback

## 결정사항 / 주의

### 1. SSOT 우선순위 (변동 없음)
```
VISUAL_CONCEPT.md v1.0 > DESIGN_PLAYBOOK.md v1.0 > CLAUDE.md 디자인 시스템
```

### 2. Bodoni Moda 사용 정책
- `google_fonts` 패키지 런타임 fetch 방식 채택 (번들 없음). 첫 실행 시 네트워크 필요.
- 오프라인 첫 실행 시 fallback = Pretendard w800 italic (Flutter 기본 동작).
- 완전 오프라인 보장 필요하면 차후 `assets/fonts/BodoniModa/` 6 파일 번들 + `pubspec.yaml` fonts 블록 추가.

### 3. Hero placeholder 특성
- 현재는 코드 생성 흑백 그라디언트 (인물 실루엣 없음). 시각적 임팩트는 약함.
- 실사진 교체만으로 즉시 v1.15 컨셉(전사·Obsession) 완성됨. 다음 세션 첫 시간 내 교체 권장.

### 4. Grade 화면 배경
- hero_grade.jpg가 `opacity: 0.35` + `subtle grain`으로 은은하게 깔려 있음.
- 카테고리 카드 4~5개가 배경 위에 얹히는 구조 → 가독성 검증 필요 (페르소나 조사에서 확인).

### 5. Home 화면 의도적 미적용
- Home은 정보 밀도 높음(Tier 배지 + 헤드라인 + 2 CTA + caption). 배경 넣으면 스캔 방해 우려.
- 페르소나 조사 결과 따라 hero 추가 vs 현행 유지 결정.

### 6. 자동 commit+push 유지
- `C:/dev/` 하위 자동 커밋 정책 준수 중 (이번 세션 2회 push).
- 최근 커밋: `e930298 feat(v1.15-assets): 자산 일괄 생성 + Bodoni Moda + halftone + stickman 실제 연결`

## 다음 세션 권장 첫 프롬프트
```
/resume
```
또는:
```
페르소나 10명 데리고와서, 체중입력부터해서 전부 직접 시켜보고, ux, ui 적인 측면에서 피드백 조사 /GO
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
| Glossary (v1.14) | `lib/core/glossary.dart` |
| 명언 | `lib/core/quotes.dart` |
| Hero 배경 위젯 (신규) | `lib/widgets/hero_background.dart` |
| Halftone 오버레이 (신규) | `lib/widgets/grain_overlay.dart` |
| Halftone 생성 스크립트 | `scripts/gen_grain.py` |
| Hero 생성 스크립트 | `scripts/gen_hero.py` |
| 백엔드 history | `services/facing/api/history.py` (5060) |
| 최신 스크린샷 | `docs/screenshots/v1.15_*.png` |

## 이전 HANDOFF
- commit `7228034` 스냅샷 (v1.15 전환 중 — asset 수급 대기 상태) 으로 archive 권장
- `docs/archive/HANDOFF-2026-04-23.md` 로 이동해도 됨 (git history에서도 복원 가능하므로 선택)
