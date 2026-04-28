# Redesign Gap Report — facing-app v2.0

> 생성: 2026-04-28 22:05 · /go 파이프라인 (8 sub-agent 병렬)
> 갱신: 2026-04-28 22:14 · 프로젝트 SSOT(VISUAL_CONCEPT/DESIGN_PLAYBOOK) 폐기 → reference/ 단독 소스화
> 입력: `~/.claude/reference/{mobile,ux,design}.md` + 프로젝트 CLAUDE.md (티어·V1~V11·카피 템플릿)
> 범위: lib/features/** 57개 + lib/core/theme.dart + 카피 규칙
> 비범위: 로직·API·상태관리·페이싱 계산 (전적으로 무시)
> **변경 결정**: 흑백 절대주의·Bodoni Italic·Heroic Narrative·3-Phase Metamorphosis 등 VISUAL_CONCEPT 고유 컨셉은 폐기. 디자인 시스템은 reference/design.md 일반 원칙(다크 테마·8pt grid·9컬러 토큰·Pretendard) 기준으로 재정렬.

## TL;DR

| 영역 | 이슈 수 | P0 | P1 | P2 | 예상 LOC |
|---|---|---|---|---|---|
| 토큰/테마 (theme.dart) | 14 위반 + 10 권고 | 2 | 5 | 3 | 30 |
| 진입·온보딩 (8 파일) | 30 | 10 | 13 | 7 | 60 |
| WOD·페이싱 (10 파일) | 31 | 4 | 15 | 12 | 50 |
| 코치·짐·Inbox (15 파일) | 49 | 10 | 25 | 14 | 90 |
| 성취·히스토리 (10 파일) | 30 | 3 | 14 | 13 | 80 |
| MyPage·설정 (5 파일) | 19 | 7 | 8 | 4 | 30 |
| **합계** | **173** | **36** | **80** | **53** | **~340** |

**SSOT vs 코드 drift**: theme.dart에 정의된 토큰 9종이 CLAUDE.md 명세값과 불일치 (v1.15 흑백 재배치 후 문서 미반영). 코드가 정본·문서가 구버전.

## 가장 자주 위반된 5 패턴 (이거 5개만 잡아도 80% 정리됨)

### #1. R5 위반 — `micro.copyWith(letterSpacing: 1.2)` 반복 인라인
- **출현**: 15+ 사례 (coach_dashboard / member_requests / wod_detail / box_wod / inbox / note_detail / compose / group_management / messages / leaderboard / attendance / mypage / algorithm 등)
- **원인**: micro 토큰(13sp w500 ls+0.4)에 letterSpacing을 1.2로 강제 override. 디자인 의도는 "조금 더 강조된 마이크로 라벨"인데 토큰이 없음
- **해결**: theme.dart에 `microLabel = micro.copyWith(letterSpacing: 1.2, fontWeight: w700)` 추가 → 인라인 override 전수 제거

### #2. V8/V9 위반 — 한국어 버튼 라벨 + 영문 명사 + 한글 조사
- **출현**: 50+ 사례. 가장 만연한 패턴
- **예시**:
  - `Text('취소')` → `Text('Cancel')`
  - `Text('계산하기')` → `Text('Measure Engine')`
  - `Text('동작 선택')` → `Text('Select Movement.')`
  - `'Split이 순위를 만든다'` → `'Split defines rank.'`
  - `'Profile에서 변경'` → `'Change in Profile.'`
- **해결**: 카피 SSOT 일괄 변환 — 단어 1개=영문/마침표X, 선언문=영문/마침표O

### #3. R1 위반 — AppBar title + 본문 h2/h3 이중 헤드라인
- **출현**: 6 파일 (mode_select, onboarding_basic, onboarding_benchmarks, create_gym, achievements_screen, history_detail, box_wod, leaderboard, note_detail)
- **해결**: AppBar title 있는 화면에서 본문 h2 → h3 또는 sectionLabel로 강등

### #4. R3 위반 — `micro.copyWith(w800, ls:1.0)`을 섹션 헤더로 사용
- **출현**: result_screen.dart L404/L422 (PACING FORMULA / REFERENCES), mypage L1418 (SIGNATURE WOD)
- **해결**: 모두 `FacingTokens.sectionLabel`로 교체

### #5. R4 위반 — 히어로 숫자 토큰 불일치 (display vs displayCompact vs h1)
- **출현**: achievements_screen L229, panel_b L323, history L211, history_detail L143, trends L181, mypage L450
- **해결**: 결과/총시간 = `display`(64sp) 고정. displayCompact는 카드 내 보조 숫자 전용

## §2 절대 차단 위반 (즉시 수정)

| 파일 | 라인 | 위반 |
|---|---|---|
| `onboarding_grade.dart` | 113 | `BoxDecoration(gradient: LinearGradient(...))` — 그라디언트 금지 |
| `attendance_screen.dart` | 734 | `boxShadow: [BoxShadow(blurRadius:6, ...)]` — 다중/단일 boxShadow 금지 |
| `signup_screen.dart` | 25-26 | `Color(0xFF03C75A)` `Color(0xFFFEE500)` — 인라인 hex 직접 작성 |

## 토큰/테마 drift (theme.dart 정본 vs CLAUDE.md 구버전)

| 토큰 | 코드 (theme.dart) | CLAUDE.md 명세 | 결정 |
|---|---|---|---|
| tierScaled | #4A4A4A | #5A5A5A | 코드 유지, 문서 갱신 (R1) |
| tierRxPlus | #929292 | #FF6B00 (주황) | 코드 유지, 문서 갱신 (v1.15 흑백 재배치) |
| tierElite | #C8C8C8 | #C8A84B (금색) | 코드 유지, 문서 갱신 |
| tierGames | #F5F5F5 | #E8E8E8 | 코드 유지, 문서 갱신 |
| muted | #9E9E9E | #8A8A8A | 코드 유지 (WCAG AA 상향) |
| sectionLabel ls | +1.2 | +1.6 | 코드 유지 (v1.15.3 가독성 복원) |
| tierLabel ls | +1.4 | +1.8 | 코드 유지 |
| bannerLabel ls | +1.0 | +1.2 | 코드 유지 |

**누락 토큰** (theme.dart에 정의됐으나 CLAUDE.md 미명세):
- `displayCompact` (56sp w800)
- `quoteSerif` `brandSerif` `h1Serif` `displaySerif` (Bodoni Moda v1.15 신규)
- `surfaceOverlay` (#1E1E1E)
- `error` (accent 별칭) `overdue` (warning 별칭)

**신규 추가 권고**:
- `microLabel` = micro.copyWith(letterSpacing: 1.2, fontWeight: w700) — 위 #1 해결용
- `codeBlock` = caption.copyWith(fontFamily: 'monospace') — result_screen 수식 블록용
- `naverGreen` `kakaoYellow` — signup 소셜 버튼 인라인 hex 제거용

## 카피 SSOT 갱신 (CLAUDE.md vs 실제 코드)

| 위치 | CLAUDE.md SSOT | 실제 코드 | 결정 |
|---|---|---|---|
| Splash 슬로건 서브 | `'Engine · Split · Burst'` (caption) | micro 토큰 사용 중 | caption으로 교체 |
| Intro 3 headline | `'Start.'` | `'Run it.'` | SSOT 갱신 또는 코드 수정 |
| Step 1 title | `'Enter 1RM.'` | AppBar `'STEP 1 / 6'` | 양쪽 다 살리되 본문 헤드라인 통일 |
| Loading sub | `'6 카테고리 Engine 측정.'` | `'6 카테고리 Engine 측정 중.'` | "중" 제거 |
| Empty profile | `'No 1RM. Enter first.'` | `'1RM 없음. 먼저 입력.'` | 영문으로 |
| Home sub | `'RX to Games. Auto Split · Burst.'` | `'RX부터 Games까지. Split과 Burst 자동 계산.'` | 영문으로 |

## 인터랙션 결손

- **Press scale 0.97→1.0 (100ms)**: _GridCell, _TitleCard, achievement card, panel_b — AnimatedScale 또는 GestureDetector wrap 필요
- **HapticFeedback.lightImpact**: 주요 버튼 (Phase 2 도입 예정으로 표기됐으나 현재 미적용)
- **HapticFeedback.heavyImpact**: PR 달성·결과 공개 시점 훅 위치 확보 필요
- **Confetti**: 입자 34개 (스펙 30개 초과) + overlay lifetime 1500ms vs animation 1400ms 불일치
- **Reduced-motion**: 결과 공개 애니 비활성 분기 미구현

## reference 적용 우선순위 (P0~P2)

**P0 (즉시 적용)** — 8개:
1. 하드코드 fontSize 즉시 제거 → FacingTokens 참조 (design_rules #3, #6)
2. sectionLabel toUpperCase() 코드 적용 (design_rules #6)
3. 터치 타깃 24×24px 미만 보완 (ux_rules #6)
4. 로딩 상태 3단계 (<200ms 숨김 / <1s 스피너 / <5s 스켈레톤) (ux_rules #1)
5. safe-area bottom inset 처리 (ux_rules #9)
6. 그라디언트 1건 제거 (onboarding_grade)
7. boxShadow 1건 제거 (attendance)
8. 인라인 hex 3건 제거 (signup, main_shell)

**P1 (다음)** — 8개:
- 빈 상태 4유형 텍스트 통일 (History/Profile)
- 에러 토스트 포맷 통일 ("무엇 + 다음 행동")
- AsyncNotifier 패턴 점검 (StateNotifier 신규 작성 금지)
- build() 위젯 분리 (result_screen segment)
- Primary CTA 하단 1/3 배치 점검
- Bottom sheet 도입 (movement picker)
- display 토큰 화면당 1회 점검
- tier 배지 N/6 노출 제거

**P2 (Polish)**:
- @riverpod 코드젠 도입
- Impeller 활성 확인
- prefers-reduced-motion 분기
- HapticFeedback heavyImpact 위치 확보
- Press scale 통일

## 실행 순서 (실 편집 단계)

> **이번 /go = 분석만**. 실제 패치는 별도 /go 호출.

| Phase | 범위 | 예상 LOC | 세션 |
|---|---|---|---|
| **P1-1** 토큰/테마 정합 | theme.dart drift 수정 + microLabel/codeBlock/naverGreen 추가 + CLAUDE.md spec 동기화 | 50 | 1 |
| **P1-2** §2 절대 차단 | 그라디언트 1건 + boxShadow 1건 + 인라인 hex 3건 | 30 | 0.5 |
| **P2** 컴포넌트 원자화 | TierBadge + sectionLabel 통일 + AnimatedScale wrapper + CoachBadge 누락 보완 | 80 | 1 |
| **P3-1** R5 letterSpacing 일괄 | micro.copyWith(ls:1.2) 15+건 → microLabel | 60 | 1 |
| **P3-2** R1/R3/R4 레이아웃 | AppBar+h2 중복 6건 + 섹션헤더 sectionLabel 교체 + 히어로숫자 display 통일 | 50 | 1 |
| **P3-3** §2 절대 + 인터랙션 보완 | Confetti 30개·1400ms 통일 + press scale + reduced-motion | 40 | 0.5 |
| **P4-1** 카피 V8 한국어 라벨 일괄 | 버튼·다이얼로그 라벨 50+건 영문 변환 | 80 | 1.5 |
| **P4-2** 카피 V9 영-한 혼합 일괄 | "Profile에서" "Split과" 등 30+건 분리/영문화 | 40 | 1 |
| **P5** 회귀 검증 | flutter analyze 0 issues + flutter test 114 pass 유지 + 위젯 골든 갱신 | - | 0.5 |
| **합계** | | **~430 LOC** | **~8 세션** |

## 위험 / 주의

- **로직 영향**: 모든 변경이 `preserves_logic: true` 체크됨. API 시그니처·상태관리·라우팅·dio 인터셉터 0줄 변경
- **테스트 회귀 위험**: persona_matrix_test 31 + widget test 114 = 145 케이스 중 카피 라벨 직접 비교 테스트 있을 시 영문화로 인한 실패 가능. P4 적용 시 동시 갱신 필요
- **카피 갱신**: CLAUDE.md 카피 템플릿 §짧은 UI vs §긴 설명 표가 일부 코드와 불일치. P4-1 시작 전 사용자 컨펌 필요한 항목 — Intro 3 headline ('Start.' vs 'Run it.'), Step 1 title 등 소수
- **Bodoni Moda Serif 토큰 4개** (brandSerif/h1Serif/displaySerif/quoteSerif): VISUAL_CONCEPT 폐기로 사용 정책 재결정 필요. reference/design.md 권장은 Pretendard 단일 폰트(weight 400/700/800). **결정 옵션**: (A) Serif 토큰 4개 모두 제거 → splash/intro/grade에서 Pretendard로 대체 / (B) Serif 토큰 유지 + 사용처 정책만 명문화 (Splash·Tier 결과 한정 등) / (C) 절충 — quoteSerif만 유지(명언 전용), 나머지 제거. **권고: A** (reference/design.md 단일 폰트 원칙 정합)
- **흑백 절대주의 폐기 영향**: tier 색상 5종(Scaled #4A4A4A / RX #EE2B2B / RX+ #929292 / Elite #C8C8C8 / Games #F5F5F5)은 v1.15 흑백 재배치 결과로 남음. reference/design.md 9컬러 토큰 + tier 5색 패턴과 정합 — 그대로 유지 권고. **다만** "Monochrome Absolutism" 컨셉은 더 이상 SSOT가 아니므로 향후 success(#22C55E)·warning(#F59E0B) 본래값 복원 검토 가능
- **Halftone grain overlay**: VISUAL_CONCEPT §5에 "드라마틱 순간 grain_strong opacity 0.10~0.12" 명세가 있었음. 코드 유지 (`lib/widgets/grain_overlay.dart` + `assets/grain_subtle.png` `grain_strong.png`). 정책 결정 필요 — **권고: 유지** (시각 차별화 요소이며 reference/design.md와 충돌 안 함)
- **3-Phase Metamorphosis (Motivation→Discipline→Obsession)**: tier.dart subtitle 필드로 코드화됨. 폐기 SSOT의 컨셉이지만 코드 동작 영향 0. **권고: 유지**
- **master 브랜치**: 사용자 명시 "배포해" 전 push 금지 (CLAUDE.md). 모든 변경은 로컬 commit만

## 추후 보고 (placeholder)

없음. 이번 단계는 분석만 — 외부 시스템 쓰기 0, 시크릿 0, 마이그레이션 0.

## 산출물

- ~~`tmp/go/ssot.json`~~ (폐기 — VISUAL_CONCEPT/DESIGN_PLAYBOOK 삭제와 함께)
- `tmp/go/reference.json` 68 rules — **새 단독 디자인 소스**
- `tmp/go/theme-audit.json` 14 violations + 10 recommendations
- `tmp/go/screens-onboarding.json` 30 issues
- `tmp/go/screens-wod.json` 31 issues
- `tmp/go/screens-coach.json` 49 issues
- `tmp/go/screens-progress.json` 30 issues
- `tmp/go/screens-mypage.json` 19 issues
- `docs/REDESIGN_GAP_REPORT.md` (이 문서)

---

**다음 액션**: 사용자 컨펌 후 P1-1(토큰/테마)부터 별도 /go 호출로 실 편집 시작.
