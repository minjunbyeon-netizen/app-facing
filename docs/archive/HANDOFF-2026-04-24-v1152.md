# HANDOFF - 2026-04-24 11:58 (v1.15.2 · 페르소나 P0/P1/P2 일괄 반영 + Splash 플로우 단순화)

> 직전 세션 (v1.15 자산 연결)에서 이어받은 세션. 페르소나 10명 UX 피드백 조사 → P0 1 + P1 15 + P2 10 분류 → P0/P1 14건 + P2 7건 반영 → Splash 플로우 단순화 (Intro bypass) 완료. 내일 아침 리트로 에이전트 예약됨.

## 완료 (이번 세션 · 4시간)

### Phase 1 — 페르소나 10명 UX/UI 피드백 조사 (/go 파이프라인)
- [x] **Haiku×3 페르소나 시뮬레이션** — P1~P3(Scaled/RX 진입), P4~P6(RX·RX+ 중견), P7~P10(Elite/Games/Masters)
- [x] **Sonnet 코드 교차검증** — 터치 타겟·타이포·WCAG·카피·hero 대비·Haptic·Semantics·Benchmarks·Loading·Grade 10 체크항목 전수
- [x] **SSOT 문서**: `docs/PERSONA_FEEDBACK_v1.15.md` 작성 (P0 1 / P1 15 / P2 10 = 26건 분류 + Sprint 로드맵 + HWPO/NOBULL 7.3/10 평가)
- [x] **HANDOFF 아카이브**: `docs/archive/HANDOFF-2026-04-24.md` 이관
- [x] commit `93d2b17` push

### Phase 2 — v1.15.1 P0/P1/P2 일괄 반영 (23/26건)
- [x] **P0-1** Loading 다이얼로그 Cancel 버튼 + 8s timeout (onboarding_benchmarks + result_screen)
- [x] **P1-1/P1-2** `lib/core/haptic.dart` 유틸 신설 + 주요 CTA (Next/Sex/모름/Start WOD/Benchmark WOD/Custom WOD/Skip/Start Onboarding) 적용
- [x] **P1-3** TierBadge + _Pill × 2개 화면 Semantics (button/selected/label)
- [x] **P1-4** '모름' TextButton 28dp → 48dp (21 필드)
- [x] **P1-5** kg↔lb 토글 시 이미 입력된 weight 값 자동 재변환 (UnitState listener)
- [x] **P1-6** TextField labelText 추가 (basic 4필드 + benchmarks 21필드 = 25)
- [x] **P1-7** 버튼 카피 통일 ('계산 중'/'Measure Engine'/'Skip · Tier 확인' → 'Calculating.'/'Next'/'Skip')
- [x] **P1-8** Grade 화면 hero darken gradient 추가 (카드 텍스트 가독성)
- [x] **P1-9** result_screen mounted 가드 + 8s timeout + 'Calculating.' 통일
- [x] **P1-10** Tier Elite #C8C8C8 / Games #F5F5F5 (명도 격차 확대, 순백 피로 완화)
- [x] **P1-11** Grade 카테고리 카드 micro(11sp) → caption(13sp) (Masters 노안 대응)
- [x] **P1-12** Voice V9 영-한 혼용 제거 (home "Split 뽑아라" → "Pull your Split", intro "1분 all-out은" → "초반 전력 질주는")
- [x] **P1-13** Onboarding Step 1 LinearProgressIndicator 17% 추가
- [x] **P1-15** Skip TextButton 48dp 터치 타겟
- [x] **P2-1** Quote author — `tier.quoteAuthor` getter 추가 + onboarding_grade에서 실사용
- [x] **P2-2** Intro 3 'Start.' → 'Run it.' (Start 버튼과 중복 제거)
- [x] **P2-3** Back 버튼 '← Back' → Icon.arrow_back_ios_new + 'Back'
- [x] **P2-4** 하드코딩 TextStyle(fontSize:12) → FacingTokens.caption / Splash CircularProgress accent→muted
- [x] **P2-5** Intro 3단계 서사 라벨 MOTIVATION/DISCIPLINE/OBSESSION 추가
- [x] **P2-6** Grade 카테고리 Score 수치 강조 (fontSize 18 w800)
- [x] **release APK 빌드**: 54.7MB · 에뮬레이터 설치 · 7장 실기 캡처 (v1.15.1_*.png)
- [x] commit `5fd1e37` push

### Phase 3 — v1.15.2 Splash 플로우 단순화
- [x] **auto-advance 제거**: backend health 준비 후 `_ready=true`만 세팅 (1.2s 타이머 삭제)
- [x] **"시작하기" 버튼 추가**: 빨간 full-width CTA + HapticFeedback.medium()
- [x] **앱 정체성 2줄 추가**: "CrossFit Games-Player 전용 / WOD Pacing Intelligence"
- [x] **Intro 3장 bypass**: Splash → Onboarding Step 1 직행 (hasGrade 시 /home)
- [x] **에뮬레이터 실기 검증**: v1.15.2_splash.png + v1.15.2_after_start.png 캡처
- [x] commit `229561e` push

### Phase 4 — 내일 아침 에이전트 예약
- [x] `/schedule` 로 remote routine 생성: `trig_018i5aDi4Lf1CQJEnVu4ymWi`
- [x] 실행 시점: **2026-04-25 09:00 KST** (`2026-04-25T00:00:00Z` UTC)
- [x] 모델: claude-sonnet-4-6 · 환경: Default
- [x] 수행 작업: 잔여 P1-14/P2-7/P2-9/P2-10 4건 판단 + Sprint 3 권장안 문서 (`docs/SPRINT_3_RETRO_2026-04-25.md`) 작성

## 진행중 — 보류 4건 (내일 에이전트가 평가)

- [ ] **P1-14 Save toast** — PageView 전환 시 toast. 구조적 미스매치 (TextEditingController 내 persistent). 재설계 필요.
- [ ] **P2-7 WOD Builder RX standard guide** — 각 동작(Thrusters/Pull-up)에 RX 무게 가이드 표기. 동작 메타데이터 확장 필요.
- [ ] **P2-9 GoogleFonts 오프라인 폴백** — Bodoni Moda 런타임 fetch 실패 시 Pretendard italic 명시적 fallback.
- [ ] **P2-10 Fold 레이아웃** — Galaxy Z Fold5 세로/가로 모드 레이아웃 검증 (실기기 필요).

## 대기 — 다음 세션 검토 대상

- [ ] **Intro 1~3 screens**: 현재 orphan 코드 (Splash에서 bypass). 유지 vs 삭제 결정 — "앱 소개 보기" secondary entry로 재활용 가능
- [ ] **실 backend 연결 상태 Haptic 실기 체감 검증**: 에뮬레이터는 햅틱 미지원, 실기기 필요
- [ ] **Home TierBadge 탭 → Grade 라우팅** (P5 페르소나 요구)
- [ ] **Grade 카테고리 카드 세부 breakdown 확장** (P4 페르소나 요구)
- [ ] **Hero placeholder Unsplash CC0 실사진 교체** (직전 세션 HANDOFF에서 이관된 asset 업그레이드 작업)

## 결정사항 / 주의

### 1. SSOT 우선순위 (변동 없음)
```
VISUAL_CONCEPT.md v1.0 > DESIGN_PLAYBOOK.md v1.0 > CLAUDE.md 디자인 시스템
```

### 2. Splash 플로우 확정 (v1.15.2)
- 신규: `Splash(수동 시작하기) → Onboarding(Step 1~6) → Grade → Home`
- Intro 1~3 라우트 코드는 유지 (지움 X). 향후 "앱 소개 보기" 진입점으로 재활용 가능.
- 에뮬레이터는 햅틱 미지원 → 실기기에서 Haptic 체감 재검증 필요

### 3. Tier 색상 변경 (v1.15.1 P1-10)
- Elite `#E0E0E0` → `#C8C8C8` · Games `#FFFFFF` → `#F5F5F5`
- 명도 격차 확대 + Games 순백 피로 완화
- VISUAL_CONCEPT.md v1.0 (흑백 obsession gradient) 범위 내 조정

### 4. Voice V9 일관성 (v1.15.1 P1-12)
- 한 문장 내 영-한 혼용 전면 금지 재확인
- "Split 뽑아라" / "1분 all-out은" 같은 복합문은 순영문 또는 순한문으로 분리

### 5. Haptic 정책 (v1.15.1 P1-1)
- `lib/core/haptic.dart` 단일 유틸. `Haptic.light/medium/heavy/selection` 4종
- 실기기 체감 후 strength 조정 여지 있음. 현재는 의미론적 매핑만 확정.

### 6. 내일 에이전트 실행
- `trig_018i5aDi4Lf1CQJEnVu4ymWi` · 2026-04-25 09:00 KST
- 산출물 `docs/SPRINT_3_RETRO_2026-04-25.md`를 commit + push까지 수행
- 실행 후 해당 파일 확인 후 Sprint 3 착수 여부 결정

### 7. 자동 commit+push 정책 유지
- 이번 세션에서 5건 push 완료: `5fd1e37` (P0/P1/P2 반영) · `229561e` (Splash 단순화) · 외 3건 (docs/scheduled routines)

## 다음 세션 권장 첫 프롬프트

```
/resume
```

또는 내일 에이전트 산출물 확인:

```
docs/SPRINT_3_RETRO_2026-04-25.md 읽고 Sprint 3 시작 여부 판단해줘
```

## 관련 경로

| 역할 | 경로 |
|---|---|
| **페르소나 피드백 SSOT** | `docs/PERSONA_FEEDBACK_v1.15.md` |
| VISUAL CONCEPT SSOT | `docs/VISUAL_CONCEPT.md` |
| DESIGN PLAYBOOK | `docs/DESIGN_PLAYBOOK.md` |
| 프로젝트 CLAUDE.md | `CLAUDE.md` |
| 디자인 토큰 | `lib/core/theme.dart` |
| **Haptic 유틸 (신규)** | `lib/core/haptic.dart` |
| Tier + quoteAuthor | `lib/core/tier.dart` |
| Splash (v1.15.2) | `lib/features/splash/splash_screen.dart` |
| Onboarding Step 1 | `lib/features/onboarding/onboarding_basic.dart` |
| Onboarding Step 2~6 | `lib/features/onboarding/onboarding_benchmarks.dart` |
| Grade 결과 | `lib/features/onboarding/onboarding_grade.dart` |
| Home | `lib/features/home/home_screen.dart` |
| Intro (orphan) | `lib/features/intro/intro_screen.dart` |
| 실기 스크린샷 | `docs/screenshots/v1.15.{1,2}_*.png` (10장) |

## 이번 세션 주요 커밋

- `93d2b17` docs(persona-v1.15): 페르소나 10명 UX/UI 피드백 SSOT + HANDOFF 아카이브
- `5fd1e37` feat(v1.15.1-ux): 페르소나 피드백 P0+P1+P2 일괄 반영 (20 files · +389 / -117)
- `229561e` feat(v1.15.2-splash): 로딩 화면 + 시작하기 CTA 수동 진입, Intro 3장 bypass

## 이전 HANDOFF
- `docs/archive/HANDOFF-2026-04-24.md` (직전 세션 · v1.15 자산 연결 완료 상태 스냅샷)
