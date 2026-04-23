# facing-app HANDOFF

> 작성일: 2026-04-22
> 목적: 이전 세션에서 진행 중이던 QA 테스트를 새 세션이 이어받기 위한 인수인계 문서.

---

## 1. 프로젝트 개요

- **프로젝트**: `facing` -- WOD(CrossFit Workout Of the Day) 페이싱 전략 계산기
- **구성**:
  - 백엔드: `C:\dev\services\facing\` (Flask 3.1, SQLAlchemy, SQLite, gunicorn + gevent)
  - 모바일 앱: `C:\dev\apps\facing-app\` (Flutter 3.41.7, Dart 3.11.5, Provider 6.1.2)
- **핵심 공식**: `출력 = N × f(T)` (N = Max 능력치, T = WOD 진행도 [0,1])
  - 논문 근거: W′ theory, Central Governor, Hazard Score, Even Pacing
  - 등급별 파라미터: `elite → scaled` 6단계, 각각 `f_baseline`, `t_boundary` 다름
- **MVP 범위**: 익명(디바이스 ID 기반), 로그인 없음, 안드로이드 단일 플랫폼
- **현재 목적**: **버튼 하나씩 눌러보고 실제로 작동하는지 체크하고, 검수** (사용자 원문)
- **엔진**: 백엔드 `POST /api/v1/pacing/calculate` (grade, profile_overrides, wod 입력)
- **등급 진단**: 백엔드 `POST /api/v1/profile/grade` (benchmark 7개 입력 → 6단계 등급)

---

## 2. 완료된 작업

### Phase 1~5 (이전 세션)
- 엔진 TDD (`engine/formula.py`, `splitter.py`, `wod_types.py`, `rationale.py`)
- API (`api/core.py`, `movements.py`, `profile.py`, `pacing.py`, `wods.py`, `presets.py`)
- DB 모델 + seed (29개 benchmark WOD: Girls + Heroes)
- Flutter 3-screen smoke → 실제 3화면 → Preset 라이브러리
- 62 tests PASS (test_formula, test_splitter, test_grading, test_formula_grade 등)

### Phase 6 (이전 세션 마지막)
- 수능식 등급제 구현:
  - 백엔드: `engine/grading.py` 신설 (9 tests)
  - `engine/config.py`에 `GRADE_PROFILES` (elite/advanced/rxd/intermediate/beginner/scaled)
  - `engine/formula.py`가 grade 인자 받음 (`pacing_ratio(t, grade)`)
  - `api/profile.py`에 `POST /api/v1/profile/grade` 추가
- 프론트: 온보딩 3-step wizard
  - `features/onboarding/onboarding_basic.dart` (Step 1: 체중/키/성별/경력)
  - `features/onboarding/onboarding_benchmarks.dart` (Step 2: 7개 벤치마크)
  - `features/onboarding/onboarding_grade.dart` (Step 3: 등급 공개)
- `profile_state.dart` 전면 리팩토링 (benchmarks map + gradeResult + `toOverrides()`)
- `main.dart`: `initialRoute: profile.hasGrade ? '/home' : '/onboarding/basic'`
- `home_screen.dart`: 등급 뱃지(Ignition Red pill) 추가

### QA 1 (이번 세션, `#41 completed`)
- [QA1-1 PASS] Step1에서 비활성화된 "다음" 버튼 탭 → 네비게이션 안 일어남 (`qa_02_disabled_next.png`)
- [QA1-2 PASS] 성별 여성 토글 시 시각 swap 확인 (`qa_03_female_toggle.png`)
- [QA1-3 PASS] 체중 75kg + 키 176cm 입력 후 "다음" 버튼 Ignition Red 활성화 (`qa_04_filled.png`)

---

## 3. 진행 중이던 작업 -- QA 2 (`#42 in_progress`)

### 목표
Onboarding Step 2 (`onboarding_benchmarks.dart`) 모든 인풋 + "등급 확인하기" 버튼 동작 검증.
그 결과 `POST /api/v1/profile/grade` 호출 성공 및 `ProfileState.gradeResult` 저장 확인.

### 지금까지 진행된 스텝
1. Step 1에서 75kg, 176cm 입력 후 "다음" 탭 → Step 2 진입 성공
2. Step 2에서 AppBar 뒤로 화살표 (좌표 80, 130) 탭 → Step 1 복귀
3. `qa_06_back_to_step1.png` 캡처 완료 -- **데이터 보존(75, 176) 여부 검증 필요**

### 다음에 해야 할 정확한 스텝
1. `qa_06_back_to_step1.png` 검증: 체중 75, 키 176이 남아 있는지 확인
   - 남아 있으면 PASS
   - 초기화되었다면 BUG 리포트 (QA8에 등록)
2. Step 1 → "다음" 재탭 → Step 2 재진입
3. 7개 benchmark 필드 입력 (민준 데이터):
   - `back_squat_1rm_lb`: 315
   - `deadlift_1rm_lb`: 405
   - `front_squat_1rm_lb`: 255
   - `pull_up_max_ub`: 25
   - `toes_to_bar_max_ub`: 35
   - `run_mile_sec`: 330
   - `row_500m_sec`: 95
4. "등급 확인하기" 버튼 탭 → `POST /api/v1/profile/grade` 호출 모니터링 (백엔드 로그)
5. `pushReplacementNamed('/onboarding/grade')` 성공 → Step 3 화면 캡처
6. Step 2 edge case:
   - 일부 필드만 채우고 "등급 확인하기" 탭 (API는 빈 필드 허용하는지)
   - 음수/소수/문자 입력 시 `FilteringTextInputFormatter` 동작

### 관련 파일 경로
| 역할 | 경로 |
|---|---|
| Step 1 UI | `C:\dev\apps\facing-app\lib\features\onboarding\onboarding_basic.dart` |
| Step 2 UI | `C:\dev\apps\facing-app\lib\features\onboarding\onboarding_benchmarks.dart` |
| Step 3 UI | `C:\dev\apps\facing-app\lib\features\onboarding\onboarding_grade.dart` |
| State | `C:\dev\apps\facing-app\lib\features\profile\profile_state.dart` |
| Router | `C:\dev\apps\facing-app\lib\main.dart` |
| API 클라이언트 | `C:\dev\apps\facing-app\lib\core\api_client.dart` |
| 백엔드 등급 API | `C:\dev\services\facing\api\profile.py` |
| 백엔드 등급 엔진 | `C:\dev\services\facing\engine\grading.py` |
| QA 스크린샷 | `C:\dev\apps\facing-app\qa_*.png` (프로젝트 루트) |

---

## 4. 남은 작업 큐

### QA 3 (`#43 pending`) -- Onboarding Step 3 등급 공개 + 시작하기
- Step 3 진입 후 표시 확인: overall 등급 label (display 토큰, Ignition Red), `overall_number`/6, 점수, 3 카테고리 카드 (짐내스틱/역도/카디오)
- "시작하기" 버튼 탭 → `pushNamedAndRemoveUntil('/home')` → Home 진입
- Home AppBar 뒤로 화살표가 사라졌는지(`automaticallyImplyLeading: !widget.isOnboarding`) 확인
- 앱 재시작 시 `initialRoute: profile.hasGrade ? '/home' : ...` 로 바로 /home 진입하는지 (SharedPreferences 저장 확인)

### QA 4 (`#44 pending`) -- Home 화면
- 등급 뱃지 렌더링 (`overallGradeLabelKo`)
- h1 "오늘의 WOD\n전략이 필요합니까"
- `OutlinedButton` "프로필 입력" (isEmpty 일 때만 표시) → `/profile`
- `ElevatedButton` "유명 WOD (Fran, Grace...)" → `WodDraftState.clear()` → `/presets`
- `OutlinedButton` "직접 WOD 만들기" → `WodDraftState.clear()` → `/builder`
- AppBar `Icons.person_outline` 탭 → `/profile`

### QA 5 (`#45 pending`) -- Presets 화면
- 필터 탭 (전체/Girls/Heroes) 전환
- 프리셋 카드 탭 → `/result` 네비게이션 (WodDraftState에 프리셋 주입 확인)
- Pull-to-refresh (있으면)
- 빈 상태/에러 상태

### QA 6 (`#46 pending`) -- Builder 화면
- WOD 타입 세그먼트 (For Time/AMRAP/EMOM/RFT)
- 타임캡 입력 (분 단위)
- "동작 추가" → 동작 선택 피커 → 횟수/무게 입력
- 스와이프 삭제
- "초기화" 버튼
- "계산하기" 버튼 → `/result` 네비게이션

### QA 7 (`#47 pending`) -- Result 화면
- `FutureBuilder` 로딩 "계산 중" 표시
- 에러 시 AppException.messageKo 표시
- 성공 시:
  - `plan.estimatedTotalDisplay` display 토큰
  - `formula v{version}` micro 토큰
  - segment 카드들 (isExplosion 일 때 accent border 2px)
  - splitPattern "15-12-10-8-5" 렌더링, 마지막 폭발 세트는 accent 색
  - `targetPaceSecPer500m` 표시 (카디오)
- AppBar 뒤로 → Builder/Presets 복귀

### QA 8 (`#48 pending`) -- 버그 수정 + 재검수
- QA 1~7 중 발견된 버그 픽스
- 픽스된 항목 재검수
- 최종 commit + push

### 그 외 pending (이전 세션 잔여)
- 29개 preset WOD 중 `distance_m` 누락 건 재확인 (Helen/Christine/Nancy/Kelly/Eva/Murph/Jerry/Michael) -- 이전 세션에서 수동 픽스했다고 기록되어 있으나 실제 값 검증 필요
- Emulator `adb pull /sdcard/` MSYS path 변환 이슈 → PowerShell 사용

---

## 5. 최근 세션 주요 결정사항 및 제약조건

### 사용자 명시 요구사항
- **"처음에는 내 몸무게, 키, 성별, 와드수행능력 3대1rm 달리기실력 같이 좀 체크해서, 그걸 수능처럼 언어는 몇등급 뭐는 몇등급 엘리트, rxd, 중상, 등등 이런 등급으로 나누고 그다음에 전략을 자야지"**
  → 등급 진단이 페이싱 계산보다 선행 (Phase 6에서 구현)
- **"앱으로만들거야, 휴대폰에 설치하는거 갤럭시에 설치하는 앱 앱 앱"**
  → 웹 프론트 없음, Flutter Android만
- **"로그인도 필요없을수준 MVP"** → 디바이스 ID 기반 익명

### 기술 결정
- 6등급 스케일: `elite(6) / advanced(5) / rxd(4) / intermediate(3) / beginner(2) / scaled(1)`
- 가중치: 짐내스틱 0.30, 역도 0.40, 카디오 0.30
- 등급별 공식: `scaled`는 `t_boundary=1.01` (폭발 없음)
- 공식 버전: `FORMULA_VERSION = "1.1.0"`
- `round()` vs `floor()` -- splitter는 `round()` 필수 (민준 회귀 케이스 [15,12,10,8,5])

### 디자인 제약
- 5개 컬러 토큰만: bg `#FFFFFF` / fg `#1D1D1F` / muted `#6E6E73` / border `#E5E5E5` / accent `#D64545` (Ignition Red)
- 8 타이포 토큰: 56/40/28/20/18/15/13/11
- 폰트: Pretendard Variable (로컬 `assets/fonts/`)
- weight 400/700만
- gradient, 다중 box-shadow, filter 장식 금지

### 배포
- MVP는 로컬 (`localhost:5060`). Railway 배포는 나중.
- Android 에뮬레이터 → 호스트: `http://10.0.2.2:5060`

---

## 6. 주의사항 / 함정 / 재현된 이슈

### Emulator 불안정
- Medium_Phone_API_36.1 에뮬레이터가 수 분마다 죽음 (`adb.exe: device 'emulator-5554' not found`)
- 재현 시: 에뮬레이터 재부팅 → APK 재설치 → `adb shell pm clear com.facing.app` 필요
- 증상: 입력이 씹히면 거의 99% 에뮬레이터 hang

### MSYS 경로 변환
- git bash에서 `adb pull /sdcard/...` 실행 시 `/sdcard/`가 `C:/Program Files/Git/sdcard/`로 변환됨
- 해결:
  ```bash
  export MSYS_NO_PATHCONV=1
  # 또는 adb 호출은 PowerShell로
  ```

### APK 빌드 함정
- `profile_state.dart` API 변경(setBodyWeight → setBasic) 이후 `profile_screen.dart`도 연동 필요
- Phase 6 이후 빌드 실패 이력: `The method 'setBodyWeight' isn't defined` → `state.setBasic(bodyWeightKg: v)` 로 수정
- 현재 `profile_screen.dart:84` 이미 패치 반영됨

### 백엔드 실행
- `cd C:\dev\services\facing && .venv\Scripts\python app.py` (포트 5060)
- 헬스체크: `curl http://localhost:5060/health` → `{"ok": true, "service": "facing"}`
- gunicorn 아닌 Flask dev server (로컬 QA용)

### 계산 엔진 회귀
- 민준 T2B 50 @ Max UB 35 → split `[15, 12, 10, 8, 5]` 필수 (splitter 회귀 테스트)
- 이 케이스 깨지면 `engine/splitter.py` descending step 로직 확인

### QA 로그 관리
- 스크린샷 파일명: `qa_{NN}_{설명}.png` (프로젝트 루트)
- 현재 `qa_06_back_to_step1.png`까지 생성됨 -- 다음 번호부터 이어서

### 개인정보
- 사용자 1RM/Max는 **평문 로그 금지** (백엔드 `engine/rationale.py`, `api/pacing.py` 로그 점검)

### 금지 패턴
- Flask app.py 직접 라우트 등록 금지 (Blueprint만)
- LLM에 계산 위임 금지 (결정론 순수 함수)
- SQLite workers > 1 금지
- 동작 카탈로그 코드 하드코딩 금지 (DB seed)
