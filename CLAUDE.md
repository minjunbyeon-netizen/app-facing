⚠️ 세션 시작 시 먼저 `docs/HANDOFF.md`를 읽고 현재 작업 상태를 파악할 것.

⚠️ **UI·디자인·카피 관련 모든 결정은 먼저 `docs/VISUAL_CONCEPT.md` v1.0 (흑백·전사·Obsession 컨셉) → `docs/DESIGN_PLAYBOOK.md` v1.0 → 이 문서 순으로 확인**. 충돌 시 VISUAL_CONCEPT가 이김. 톤앤매너·스타일·컨셉 전부 SSOT는 VISUAL_CONCEPT.

## 🚫 배포 금지 규칙 (v1.16.1 · 최상위 강제)

**사용자가 명시적으로 "배포해"라고 말하기 전까지 어떤 형태의 배포도 절대 수행하지 말 것.**

구체적으로 금지되는 행위:
- `git push` 원격 푸시 (origin/main 포함 전체 브랜치)
- Railway·Vercel·Fly 등 **PaaS 배포 명령** (`railway up`, `vercel deploy`, `fly deploy` 등)
- `gh pr create`, `gh pr merge` · main 브랜치 병합
- `flutter build apk --release` 후 **배포 경로 복사·업로드**
- Google Play · App Store 등 **스토어 업로드**
- 프로덕션 DB 마이그레이션 실행
- 외부 배포 채널 공유 (APK 링크 · TestFlight 초대 등)

**허용되는 행위** (배포가 아님):
- 로컬 `git commit` (로컬 레포만 영향)
- 로컬 백엔드 재기동 (`python app.py`)
- 에뮬레이터 재실행 (`flutter run`)
- 로컬 APK 디버그 빌드 후 **에뮬레이터·연결된 디바이스에 한정** 설치
- 파일 편집 · 로컬 테스트 · 문서 작성

**사용자 배포 의사 확인 방법**:
"배포하자" · "push" · "출시" · "릴리즈" · "store 올리자" 같은 명시적 키워드 있을 때만 착수.
모호한 "진행해줘" · "해줘" 는 **로컬 작업만** 의미로 해석할 것.

**위반 시**: 롤백 · 사용자에게 즉시 보고 · `/handoff` 로 세션 기록.

# facing-app -- WOD 페이싱 전략 모바일 앱

> Flutter 기반 Android+iOS 앱. 백엔드 `services/facing/` API와 JSON 통신. UI/UX만 담당, 계산 로직 0%.

## 외부 자료 위치 (SSOT)
페이싱 공식·논문·벤치마크 자료는 **이 폴더에 없음**. 백엔드 쪽 단일 출처:
**`C:\dev\services\facing\docs\refer\{카테고리}\findings.md`** (10개 카테고리)
앱은 UI만 담당하므로 페이싱 알고리즘/공식 관련 질문이면 백엔드 docs/refer 참조. 사본 만들지 말 것 (헷갈림 방지).

## 프로젝트 개요
- 위치: `C:\dev\apps\facing-app\`
- Repo: `app-facing` (향후 생성)
- 플랫폼: Android (MVP) → iOS (v2)
- 배포: APK 직배포 (MVP) → Play Store / App Store (v2)
- 백엔드: `services/facing/` Flask API (로컬 `http://localhost:5060`, 배포 시 Railway URL)

## 기술 스택
- **Flutter 3.x (stable)** + Dart
- 상태관리: Riverpod (또는 Provider -- MVP 결정 후 고정)
- HTTP 클라이언트: `dio` (인터셉터 지원)
- 로컬 저장: `shared_preferences` (디바이스 ID, 마지막 프로필)
- 폰트: Pretendard (로컬 assets/fonts/ 포함)
- 테마: 글로벌 디자인 토큰 규칙 준수 (bg/fg/muted/border/accent 5색)

## 폴더 구조 (`flutter create` 실행 후 생성 + 커스텀)
```
apps/facing-app/
├── lib/
│   ├── main.dart
│   ├── app.dart                    # MaterialApp + 라우팅
│   ├── core/
│   │   ├── theme.dart              # 색상/타이포 토큰
│   │   ├── api_client.dart         # dio 인스턴스 + 인터셉터
│   │   └── device_id.dart          # 익명 디바이스 ID 생성/저장
│   ├── features/
│   │   ├── profile/                # Max 프로필 입력/저장
│   │   │   ├── profile_screen.dart
│   │   │   ├── profile_state.dart
│   │   │   └── profile_repository.dart
│   │   ├── wod_builder/            # WOD 구성 화면 (동작 카테고리 → 선택 → 횟수)
│   │   │   ├── builder_screen.dart
│   │   │   ├── movement_picker.dart
│   │   │   └── wod_type_selector.dart
│   │   └── pacing_result/          # 계산 결과 화면 (분할, 폭발 시점, 근거)
│   │       ├── result_screen.dart
│   │       ├── segment_card.dart
│   │       └── rationale_panel.dart
│   └── models/                     # API 응답 Dart 모델 (json_serializable)
│       ├── profile.dart
│       ├── movement.dart
│       ├── wod.dart
│       └── pacing_plan.dart
├── assets/
│   ├── fonts/
│   │   └── PretendardVariable.ttf
│   └── images/
├── test/
│   ├── widget_test.dart
│   └── features/
├── android/
├── ios/                            # v2 진입 시 활성
├── pubspec.yaml
└── README.md
```

## 화면 플로우 (MVP 3화면)
1. **프로필 화면** -- 최초 진입 시 Max 입력 (FS 1RM, T2B Max UB, Run 500m 등). 저장 후 언제든 수정.
2. **WOD 빌더** -- 동작 카테고리(짐내스틱/맨몸/카디오/역도) → 동작 선택 → 횟수/중량/거리 입력 → WOD 타입(For Time/AMRAP/EMOM) 선택.
3. **결과 화면** -- 분할 시퀀스 (예: `15-12-10-8-5`), 세트간 레스트, 폭발 시점, 논문 근거 요약.

## API 통신
- Base URL: 환경별 상수 (`dev: http://10.0.2.2:5060` 에뮬레이터, `prod: https://...railway.app`)
- 모든 요청에 `X-Device-Id` 헤더 (최초 실행 시 UUID v4 생성 후 `shared_preferences` 저장)
- 응답 포맷은 백엔드 표준: `{ok: bool, data: {...}, error?: ..., code?: ...}`
- 실패 시 사용자 친화 에러 메시지 (dio interceptor에서 공통 처리)

## 브랜드 포지셔닝 (단일 진원지 -- v1.12.0 확정)
> **"CrossFit Games 출전자급 엘리트를 위한 전용 앱."**
> 일반 피트니스/헬스/다이어트 앱 아님. Scaled→RX→RX+→Elite→Games 티어 사용자 전용.
> "운동", "헬스", "다이어트", "건강", "체중관리", "웰니스" 용어 전면 금지.
> 타깃 정체성: Rich Froning / Mat Fraser / Tia Toomey 세대.

### 벤치마크 레퍼런스 (톤·카피·레이아웃 기준)
모든 UI·카피·비주얼 결정은 아래 4개 브랜드를 기준점으로 삼는다. 신규 화면 설계 시 "이 4곳이라면 뭐라고 쓸까"부터 먼저 질문.

| 브랜드 | 톤 키워드 | 벤치마크 포인트 |
|---|---|---|
| **HWPO** (Mat Fraser) | "Earn it." 명령형·자부심 | 짧은 영문 명령어, 고대비 타이포, 장식 제로 |
| **NOBULL** | Stoic·blacked out | 모노 블랙/화이트, 긴 설명 없이 이미지+단어 하나 |
| **Mayhem** (Rich Froning) | Team·discipline | 숫자·기록 우선, 과시 없음 |
| **CompTrain** (Ben Bergeron) | Coach·analytical | 데이터·근거 제시, 교조적 문장 |

언어 결정이 애매할 때 순서: (1) HWPO가 쓸 것 같은가? (2) NOBULL에서 잘릴까? (3) Mayhem 수치 기준 통과? (4) CompTrain 근거 있는가?

## Voice & Tone (어투 11원칙 — v1.13.0 미니멀 패스)
V1. **명령형 기본.** "~하세요" 금지.
    - 단어 1개 라벨(버튼·탭·배지·헤더 단어 1개) = **마침표 없음**: "Enter" "Confirm" "Calculate" "Save" "Next" "Back" "Skip"
    - 1줄 선언 헤드라인(동사 포함·2단어 이상) = **마침표 유지**: "Start WOD." "Your Tier." "Earn it."
V2. **숫자 없으면 동기부여 문구 금지.** "할 수 있다!" 류 공허한 응원 제거. "Fran sub-2:00, 82%" 식 metric 기반만.
V3. **한 문장 10단어 이하.** 설명 길어지면 분리 또는 삭제.
V4. **이모지 금지.** 박수·불꽃 없음. 숫자·기호(→ : %) 만 허용.
V5. **2인칭 금기.** "당신/귀하" 쓰지 말 것. 영문 "you"는 "Your Tier" 같은 소유격 외 생략 기본.
V6. **영문 전문 용어는 번역 안 함.** 1RM, AMRAP, EMOM, Metcon, Chipper, Engine, Unbroken, Split, Burst 그대로.
V7. **실패도 전술적으로.** "오류 발생" → "Offline. 연결 시 동기화." 무기력이 아닌 리셋 프레임.
V8. **짧은 UI 라벨·헤드라인·버튼은 영문 단독.**
    - 버튼·탭·배지(단어 1개) = 마침표 없음 → "Save" "Next" "History" "Profile"
    - 헤드라인·진행형·선언문(동사 포함 1줄) = 마침표 유지 → "Calculating." "Start WOD." "Your Tier."
    HWPO/NOBULL 패턴: 단어 라벨 = 마침표 없음, 선언문 = 마침표 1개.
V9. **한 문장 내 영문-한글 혼합 금지.** 영문 명사 + 한글 조사("Split**이**", "Engine**을**") 구조 전면 폐기. 동사를 한글로 쓰려면 명사도 한글로(전문용어 제외) 또는 문장 전체를 영문으로.
V10. **부연 설명·힌트·캡션·지시문은 줄 수 무관 한글 허용 (v1.13 완화).**
    - 판단 기준: 영문 헤드라인이 "무엇"을 선언하면, 한글 캡션이 "왜·어떻게"를 보충
    - 허용 패턴: 영문 헤드라인 + 한글 캡션의 **수직 스택 구조**
    - 금지: 한 문장 내 영문-한글 혼용(V9 유지)
    - 버튼·탭·배지·토스트(단어 1~3개) = 여전히 영문 단독
V11. **번역 판단 기준:** 동작명/등급명/시스템명/메트릭명은 항상 영문. 보조 동사("하다/이다/있다") 포함 문장은 전체 영문으로 전환하거나 보조 동사 제거(명사+마침표 형식).

한 줄 브랜드 보이스: **"Games-Player의 언어로, 숫자로만 말한다."**

## 용어 팔레트
### 사용 (영문 단독 원칙)
`WOD` `AMRAP` `EMOM` `Metcon` `Chipper` `RX` `RX+` `Scaled` `Elite` `Games` `1RM` `Unbroken` `UB` `Box` `Engine` `Split` `Pacing` `Burst` `PR` `For Time` `Regionals` `Open`

### 병기 규칙 (v1.12.0 영문 중심 전환)
- **동작명**: 영문 단독 (Thruster / Pull-up / Box Jump / Back Squat / Snatch). 한글 번역 금지.
- **UI 라벨 (탭/버튼/헤더/배지)**: 영문 단독. "저장" → "Save", "계산" → "Calculate", "확인" → "Confirm", "건너뛰기" → "Skip", "다음" → "Next".
- **등급/시스템/메트릭**: 영문 단독 (RX, Games, Elite, Engine, Split, Burst).
- **2줄 이상 설명/힌트/에러 상세**: 한글 허용 (V10).
- **문장 내 영-한 혼용 금지**: "Split이 순위를" / "Engine을 측정" 같은 조사 결합 전부 제거.

### 금지 용어
운동 · 헬스 · 다이어트 · 건강 · 체중관리 · 체력증진 · 웰니스 · 칼로리 소모 · "쉬운" · "편리한" · "누구나"

## 티어 시스템 (등급 표기 SSOT)
백엔드 응답 `overall_number` (1~6) → 프론트에서 5 티어로 매핑:

| number | Tier | 색상 토큰 | 설명 |
|---|---|---|---|
| 1 | **Scaled** | `tierScaled` #5A5A5A 회색 | Novice. 스케일드 동작 위주 |
| 2 | **Scaled** | 동일 | Intermediate low |
| 3 | **RX** | `tierRx` #EE2B2B 빨강 | RX 표준 달성 |
| 4 | **RX+** | `tierRxPlus` #FF6B00 주황 | Advanced |
| 5 | **Elite** | `tierElite` #C8A84B 금색 | Regionals 급 |
| 6 | **Games** | `tierGames` #E8E8E8 실버 | Games 출전급 (최상위) |

- UI에 "RXD 4/6" 같은 백엔드 내부 코드 노출 금지. 항상 위 5티어 라벨만 사용.
- 티어 배지: 2px solid 티어 컬러 + 대문자 라벨 + 얇은 padding. 아이콘 없음.

## 디자인 시스템 (v1.14.0 타이포 계층 정비)
### 컬러 토큰 (FacingTokens 기준)
| 토큰 | 값 | 용도 |
|---|---|---|
| `bg` | `#0A0A0A` | 기본 배경 (다크) |
| `surface` | `#141414` | 카드 / 시트 |
| `fg` | `#F5F5F5` | 본문 텍스트 |
| `muted` | `#8A8A8A` | 보조 텍스트 |
| `border` | `#2A2A2A` | 구분선 / 입력 외곽 |
| `accent` | `#EE2B2B` | CrossFit red (primary CTA) |
| `accentPressed` | `#CC2020` | 눌림 |
| `success` | `#22C55E` | +델타, 성취 |
| `warning` | `#F59E0B` | 주의 |
| 5 tier 색 | 위 표 참조 | 티어 배지 전용 |

### 타이포그래피 (v1.14.0 계층)
- Pretendard 유지 (Variable, weight 400/700/800).
- display/h1/h2는 w800 + negative letterSpacing.
- `timer` 토큰 삭제됨 (미사용). 큰 숫자는 `display`(64sp) 사용.
- Phase 2에 Barlow Condensed 영문 전용 추가 검토.

#### 토큰 스케일 (v1.14.0 최종)
| 토큰 | 크기 | weight | 용도 |
|---|---|---|---|
| `display` | 64sp w800 ls-1.6 | 히어로 숫자·총시간 (result/history) |
| `h1` | 44sp w800 ls-1.1 | 화면 단일 히어로 헤드라인 (intro, split pattern) |
| `h2` | 30sp w700 ls-0.6 | 화면 주 타이틀 (AppBar 없는 화면 한정) |
| `h3` | 20sp w700 ls-0.2 | 섹션 타이틀, AppBar title (테마 기본), segment slug, pace |
| `lead` | 18sp w400 | intro body, segment estimated time |
| `body` | 15sp w400 | 본문 |
| `caption` | 13sp w400 muted | 부연 설명 |
| `micro` | 13sp w500 ls+0.4 muted | 수치 보조(items, %, points) 전용. v1.19 P0-8 노안 가독성 11→13 상향 |
| `sectionLabel` | **11sp w700 ls+1.6 muted** | **섹션 구분 라벨 전용. 대문자 필수(코드에서 toUpperCase).** |
| `tierLabel` | 12sp w800 ls+1.8 | TierBadge 내부 전용 |
| `brandLogo` | **72sp w800 ls-2.4** | **Splash "FACING" 전용** |
| `bannerLabel` | **12sp w700 ls+1.2** | **Offline 등 배너 라벨 전용** |
| `quote` | 14sp italic | 명언 전용 |

#### 계층 규칙 (v1.14.0)
R1. **화면당 h1 1개.** AppBar title이 있으면 화면 내 헤드라인 h2 제거.
R2. **Tier 결과 화면 최대 2겹.** TierBadge(크게, fontSize 24) + Score 한 줄. `OVERALL` 라벨·`N/6` 숫자 금지.
R3. **섹션 헤더는 `sectionLabel` 단독.** micro/caption/h2 inline/body.w800 섹션 헤더 사용 금지.
R4. **동일 지표 동일 토큰.** "500m pace"=`h3`, "총 예상시간"=`display` 화면 막론 고정.
R5. **하드코드 fontSize 금지.** 모든 텍스트 크기는 `FacingTokens` 상수 참조. 인라인 `TextStyle(fontSize: N)` 커밋 전 리뷰 거절.

### 인터랙션
- splashFactory = NoSplash 유지.
- 버튼 press scale 0.97 → 1.0 (100ms).
- PageView 전환 250ms easeInOut.
- 카운트다운/결과 공개 시점에 HapticFeedback.heavyImpact (Phase 2).

## 명언 시스템 (Quote)
`lib/core/quotes.dart` 에 상수 배열로 관리. 3곳에 랜덤/고정 노출:
1. SplashScreen 하단 (랜덤 1개)
2. 계산 로딩 오버레이 (랜덤 1개)
3. 등급 결과 화면 상단 (overall_number 해시로 고정 1개 — 같은 등급이면 같은 명언)

### 채택 명언 10개 (표시 시 저자 포함, 영문 그대로)
1. `"The only way out is through."` — Robert Frost
2. `"Do the work. Every day."` — Rich Froning Jr.
3. `"Train hard. Win easy."` — CrossFit community
4. `"Comfort is the enemy of progress."` — P.T. Barnum
5. `"Fatigue makes cowards of us all."` — Vince Lombardi
6. `"Earn it."` — HWPO
7. `"You don't rise to the level of your goals. You fall to the level of your systems."` — James Clear
8. `"Pain is temporary. The score is permanent."` — CrossFit Games
9. `"Impossible isn't far."` — Camille Leblanc-Bazinet
10. `"Everyone wants to win. Not everyone wants to prepare to win."` — Mat Fraser

추가 시 엘리트 athlete 인용 + 1줄 이내 + 동기부여가 아닌 사실 진술 성격만.

## 카피 템플릿 (화면별 SSOT — v1.12.0 영문 중심)
짧은 라벨·헤드라인·CTA·에러 토스트는 영문. 2줄 이상 설명·힌트는 한글 허용.

### 짧은 UI (영문 고정)
| 위치 | 카피 |
|---|---|
| App name (Splash) | **"FACING"** (단어 1개, w800) |
| Intro 1 headline | **"Split defines rank."** |
| Intro 2 headline | **"6 metrics. Measure Engine."** |
| Intro 3 headline | **"Start."** |
| Home headline | **"Today's WOD."** / 2줄 **"Pull your Split."** |
| Home sub (1줄) | **"RX to Games. Auto Split · Burst."** |
| Step 1 title | **"Enter 1RM."** |
| Benchmarks title | **"Benchmarks."** |
| Submit 버튼 | **"Measure Engine"** |
| Loading 제목 | **"Calculating."** |
| Grade header | **"Your Tier."** |
| CTA 홈 이동 | **"Start WOD"** |
| Offline 배너 | **"OFFLINE · Sync on reconnect"** |
| Calc error 토스트 | **"Calc failed. Retry."** |
| Empty profile | **"No 1RM. Enter first."** |
| MyPage entry | **"Profile"** |
| History entry | **"History"** |
| kg/lb 토글 | **"kg"** / **"lb"** |
| Skip 버튼 | **"Skip"** |
| Next 버튼 | **"Next"** |
| Back 버튼 | **"Back"** |
| Save 버튼 | **"Save"** |
| Reset 버튼 | **"Reset data"** |

### 긴 설명 / 힌트 (한글 허용, 2줄+)
| 위치 | 카피 |
|---|---|
| Step 1 sub | "체중·키는 등급 산정 기준." (1줄이지만 맥락 유지 위해 한글 허용 — 예외) |
| Benchmarks hint | "아는 것만. 빈 칸은 자동 추론." |
| Loading sub | "6 카테고리 Engine 측정." |
| Grade sub | "Tier에 맞춰 Split · Burst 자동 조정. 언제든 Profile에서 수정." |
| Error detail (2줄+) | "연결 실패. 백엔드 재시도 중. 잠시 후 다시 시도." |

### 혼합 문장 예시 (허용 vs 금지)
- 허용(영문 전체): `"Your Tier."`, `"Engine: 82/100"`, `"Start WOD"`
- 허용(한글 설명 블록): `"Tier에 맞춰 Split과 Burst 자동 조정."` (동사+조사+마침표 완결, 2줄 블록 안)
- 금지(한 문장 혼용): `"Split이 순위를 만든다."` → `"Split defines rank."` 로
- 금지(한 문장 혼용): `"Engine을 측정한다."` → `"Measure Engine."` 로

### 영문 헤드라인 + 한글 캡션 수직 스택 (허용 패턴 — v1.13)
| 화면 | 헤드라인(영문) | 캡션(한글) |
|---|---|---|
| Onboarding Step 1 | `Enter 1RM.` | `체중·키는 등급 산정 기준.` |
| Onboarding Step 2 | `Benchmarks.` | `아는 것만 입력. 빈 칸은 자동 추론.` |
| Grade 결과 | `Your Tier.` | `Tier에 맞춰 Split과 Burst 자동 조정. Profile 수정 가능.` |
| Loading 오버레이 | `Calculating.` | `6 카테고리 Engine 측정.` |
| Offline 배너 | `OFFLINE` | `연결 시 동기화.` |
| History 빈 상태 | `No Engine history` | `등급 계산 후 자동 저장.` |
| Home 부연 | `Today's WOD.` / `Pull your Split.` | `RX부터 Games까지. Split과 Burst 자동 계산.` |

### 마침표 3분류 (v1.13 규칙 요약)
| 유형 | 마침표 | 예시 |
|---|---|---|
| 단어 1개 라벨 (버튼·탭·배지·네비) | **없음** | `Save` `Next` `Back` `Skip` `History` `Profile` `Loading` `Body` |
| 1줄 선언·헤드라인 (동사 포함 2단어+) | **유지** | `Start WOD.` `Your Tier.` `Calculating.` `Measure Engine.` |
| 수치/열거 (숫자+단위+명사) | **유지** | `Engine: 82/100.` `Split: 15-12-10.` |

## 디자인 원칙 (글로벌 + facing 전용)
- 이모지 금지 (V4)
- 다크 배경 기본 (`bg=#0A0A0A`). 라이트 모드 제공 안 함.
- 색상 9토큰 + 5 tier 색 (bg/surface/fg/muted/border/accent/accentPressed/success/warning + tier×5)
- 폰트 Pretendard 1종 (weight 400/700/800)
- 그라디언트/과도한 그림자 금지
- ROW 우선, 여백 충분히
- 사진/일러스트 없음. 타이포+수치 중심.

## 로컬 실행
```bash
cd apps/facing-app
flutter pub get
flutter run                      # 기본 연결된 기기/에뮬레이터
flutter run -d emulator-5554     # 특정 에뮬레이터
```

## 빌드 & 배포 (MVP)
```bash
flutter build apk --release      # APK 생성
# 생성물: build/app/outputs/flutter-apk/app-release.apk
# → 갤럭시에 직접 설치 (USB 디버깅 or 파일 전송)
```
v2: Play Store Internal Testing → Closed Testing → Production.

## 금지
- NEVER 계산 로직을 앱에 구현 (백엔드 `services/facing/engine/` 책임)
- NEVER API 키/토큰을 Dart 코드에 하드코딩
- NEVER 사용자 Max 데이터를 서버 백업 없이 로컬에만 저장 (MVP는 익명이라 유실 OK, v2부터는 서버 백업 필수)
- NEVER React Native/Ionic/Capacitor 라이브러리 혼용 (Flutter 순수 스택)
