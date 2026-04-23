# HANDOFF - 2026-04-23 20:07

> 직전 버전(2026-04-22)은 QA 1~2 기준. 이 문서는 v1.11.0 브랜드/UX 풀패키지 작업 반영 최신판.

## 완료
- [x] **브랜드 리포지셔닝 "Games-Player의 언어로, 숫자로만 말한다"** — 일반 피트니스/다이어트 앱에서 CrossFit Games 출전자급 엘리트 톤으로 전면 전환
- [x] **CLAUDE.md SSOT 작성** (`C:/dev/apps/facing-app/CLAUDE.md`): 포지셔닝, Voice & Tone 7원칙, 용어 팔레트, 5-티어 시스템, 디자인 토큰, 명언 시스템, 카피 템플릿
- [x] **다크 팔레트 전환** (`lib/core/theme.dart`): bg #0A0A0A / surface #141414 / fg #F5F5F5 / accent #EE2B2B(CrossFit red) / 5개 티어 컬러
- [x] **Tier 시스템** (`lib/core/tier.dart`): SCALED/RX/RX+/ELITE/GAMES — backend `overall_number` 1-6 → frontend 5 티어 매핑 (`Tier.fromOverallNumber(n)`)
- [x] **영어 명언 시스템** (`lib/core/quotes.dart`): 10개 elite quote + `randomQuote()` / `stableQuote(seed)`
- [x] **UX 풀패키지 8항목**:
  - Splash screen (`lib/features/splash/splash_screen.dart`): facing 72sp + Engine · Split · Burst + quote
  - Intro 3-페이지 swipe (`lib/features/intro/intro_screen.dart`): "Split이 순위를 만든다" / "6개 지표. Engine을 측정한다" / "시작해라"
  - Wizard 1/6 라벨링: BODY + POWER/OLYMPIC/GYMNASTICS/CARDIO/METCON (v1.10.0 6 카테고리 분리 반영)
  - kg/lb 글로벌 토글 (`lib/core/unit_state.dart` + AppBar TextButton)
  - "모름/건너뛰기" 버튼 (onboarding_basic: 체중만 있으면 진행)
  - 계산 중 로딩 애니메이션 ("Engine 측정 · 6 카테고리 Tier 산출")
  - Offline 배너 (`lib/widgets/offline_banner.dart` + `lib/core/connectivity_state.dart`)
  - TierBadge (`lib/widgets/tier_badge.dart`, 2px solid border + 대문자 라벨)
- [x] **Copy 전면 리라이팅**: 반말·명령형 통일, 한 문장 12어절 이하, 영어 기술용어(WOD/AMRAP/EMOM/Split/Burst/Engine) 유지
- [x] **E2E 스크린샷 15장** (`qa/e2e_v3/`): emulator-5554 1080x2400, splash→intro 3p→1/6 body→2/6 power→loading→grade→home 전 플로우 다크 전환 확인
- [x] **flutter build apk --debug 통과** (7.8s, analyze 0 errors)
- [x] **v1.11.0 커밋 2개 완료**: `8cef530 feat: UX 풀패키지`, `4ae818a test: E2E 15장`

## 진행중
- [ ] **현재 working tree 변경사항 커밋 필요** (세션 마지막에 누락된 파일):
  - `M CLAUDE.md`
  - `M lib/core/theme.dart`, `M lib/features/{home,intro,splash}/**`, `M lib/features/onboarding/{basic,benchmarks,grade}.dart`, `M lib/widgets/offline_banner.dart`
  - `?? lib/core/{quotes,tier}.dart`, `?? lib/widgets/{quote_card,tier_badge}.dart`, `?? qa/e2e_v3/`
  - → 다음 세션 첫 스텝으로 `git add -A && git commit -m "chore(handoff): v1.11 톤앤매너 최종 상태 저장"` 실행.

## 대기
- [ ] **GitHub 원격 repo 생성 + push**: `gh repo create minjunbyeon-netizen/app-facing --private` → `git remote add origin ...` → `git push -u origin master`
- [ ] **Custom WOD Builder 톤앤매너 점검**: `lib/features/wod_builder/` — 홈 "Custom WOD Builder" 버튼 뒤 플로우는 v1.11 톤앤매너 미적용. 카피/색/레이아웃 전수 점검.
- [ ] **Presets (Benchmark WOD) 톤앤매너 점검**: Fran/Grace/Murph 프리셋 화면 동일 점검.
- [ ] **Result (페이싱 결과) 화면 톤 점검**: Split/Burst 실제 결과 화면이 elite 보이스인지. `plan.estimatedTotalDisplay`, `splitPattern` 표시 영역.
- [ ] **Profile 재입력 화면** (홈 상단 person 아이콘): 이미 입력한 사용자가 다시 들어왔을 때의 flow. 현재 `/profile` 라우트 상태 미확인.

## 결정사항 / 주의

### 톤앤매너 SSOT
- **마스터 문서**: `C:/dev/apps/facing-app/CLAUDE.md`. 모든 카피/색/용어는 여기 기준. 충돌 시 이 파일이 이김.
- **One-line voice**: "Games-Player의 언어로, 숫자로만 말한다."
- **타깃**: Rich Froning / Mat Fraser / Tia Toomey 급. 일반 피트니스/다이어트 앱 아님.
- **어투**: 전부 반말·명령형. 존칭 금지. 한 문장 12어절 이하. 이모지 금지.

### 용어 팔레트 (고정)
- 영문 그대로: WOD, AMRAP, EMOM, RFT, Chipper, Split, Burst, Engine, Unbroken, UB, RX, RX+, Scaled, Elite, Games, 1RM
- 한국어: UI 라벨, 설명문만 (예: "체중", "다음", "건너뛰기")
- 금지: "운동", "헬스", "다이어트", "칼로리", "건강"

### 티어 시스템
- Backend `overall_number` (1~6) → Frontend 5 티어:
  - 1-2 → `Tier.scaled` (SCALED, #5A5A5A)
  - 3 → `Tier.rx` (RX, #EE2B2B)
  - 4 → `Tier.rxPlus` (RX+, #FF6B00)
  - 5 → `Tier.elite` (ELITE, #C8A84B)
  - 6 → `Tier.games` (GAMES, #E8E8E8)
- 표기: "RX 3/6", "ELITE 5/6" 형식

### 디자인 토큰 (`lib/core/theme.dart`)
- bg #0A0A0A / surface #141414 / fg #F5F5F5 / muted #8A8A8A / border #2A2A2A / accent #EE2B2B
- 타이포: timer 80sp w800, h1 40sp, h2 28sp, body 16sp, caption 13sp, micro 11sp, tierLabel 12sp letterSpacing 1.8
- weight 400/700/800만. 이탤릭은 `quote` 스타일 한정.

### 단위
- 체중: kg 저장 → UI 표시는 `UnitState.kgToDisplay()` 변환
- 리프트: lb 저장 → UI 표시는 `UnitState.displayToLb()` 변환
- 토글: AppBar 우측 TextButton ("kg" / "lb")

### 명언 시스템
- 장식 아님. `stableQuote(seed)`로 화면/사용자별 고정 시드. 매 랜덤 X.
- Splash는 `randomQuote()` 허용 (앱 실행마다 다름).
- Grade 화면은 `overall_number * 7 + 3` 시드로 등급별 고정.

### FORMULA_VERSION 1.10.0 고정
- 백엔드 계산식 불변. 프론트 변경은 UX/카피만.
- Split/Burst 결과 값은 절대 수정 금지. 해석/표시만 변경 허용.

### 개인정보
- 사용자 1RM/Max는 평문 로그 금지. 백엔드 `engine/rationale.py`, `api/pacing.py` 확인 필요.

### 에뮬레이터 E2E
- 디바이스: `emulator-5554`, 1080x2400
- 스크린샷: `qa/e2e_v3/` (v1.11 15장 완료)
- 다음 회차는 `qa/e2e_v4/`로 디렉토리 분리

## 이전 세션 잔여 (HANDOFF-2026-04-22에서 이월, 아직 미확인)
- [ ] 29개 preset WOD 중 `distance_m` 누락 건 재확인 (Helen/Christine/Nancy/Kelly/Eva/Murph/Jerry/Michael)
- [ ] QA 5~7 (Presets / Builder / Result) — v1.11 톤앤매너 재점검과 함께 병합 진행 권장

## 다음 세션 권장 첫 프롬프트
```
/resume
```

또는 명시적으로:
```
facing-app v1.11 working tree 변경사항부터 chore(handoff) 커밋. 그 다음 Custom WOD Builder / Presets / Result 3개 화면 톤앤매너 점검 시작.
```

## 관련 경로 요약
| 역할 | 경로 |
|---|---|
| 브랜드 SSOT | `C:/dev/apps/facing-app/CLAUDE.md` |
| 디자인 토큰 | `lib/core/theme.dart` |
| 티어 | `lib/core/tier.dart` |
| 명언 | `lib/core/quotes.dart` |
| 단위 토글 | `lib/core/unit_state.dart` |
| 오프라인 | `lib/core/connectivity_state.dart` |
| Splash | `lib/features/splash/splash_screen.dart` |
| Intro | `lib/features/intro/intro_screen.dart` |
| Onboarding | `lib/features/onboarding/{basic,benchmarks,grade}.dart` |
| Home | `lib/features/home/home_screen.dart` |
| 위젯 | `lib/widgets/{tier_badge,quote_card,offline_banner}.dart` |
| E2E 스크린샷 | `qa/e2e_v3/` (v1.11) |
| 백엔드 | `C:/dev/services/facing/` (port 5060) |
