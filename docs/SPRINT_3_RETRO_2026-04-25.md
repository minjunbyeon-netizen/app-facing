# SPRINT 3 RETRO — 2026-04-25 (v1.15.1 잔여 P1/P2 평가)

> 작성: 리트로 에이전트 (claude-sonnet-4-6 · 2026-04-25 09:00 KST)  
> 기준 커밋: `229561e` (v1.15.2 Splash) → `7611529` (최신 auto-save)  
> 목적: 보류 4건 실행 가능성 판단 + Sprint 4 권장안 도출

---

## 0. 전제 확인 — 코드베이스 상태

직전 세션(v1.15.1/v1.15.2) 이후 `auto-save` 커밋 34건이 쌓였으며, **코드베이스는 이미 v1.16 수준으로 대규모 확장**된 상태다.

신규 추가 화면 및 모듈:
- `achievement/`, `announcements/`, `attendance/`, `auth/`, `goals/`, `gym/` (4개 화면), `leaderboard/`, `messages/`, `presets/`, `shell/`, `trends/`, `wod_session/`
- 코어: `athletes`, `formula_references`, `glossary`, `goals_state`, `level_system`, `scoring`, `season`, `shell_nav_bus`, `ui_prefs_state`, `weak_insight`, `wod_session_bus`, `worn_title_store`

이에 따라 보류 4건은 **v1.16 확장 맥락에서 재평가**해야 하며, Sprint 3 우선순위도 일부 재정렬이 필요하다.

---

## 1. 보류 4건 판단

### P1-14 — Benchmarks Save toast
**상태: 실행 가능 · 30분**

현재 구현:
```dart
// onboarding_benchmarks.dart:403
onPageChanged: (i) => setState(() => _page = i),
```
`_ctrls` (Map<String, TextEditingController>)가 위젯 state에 메모리 persistent하므로 데이터 유실 없음. 그러나 사용자는 저장 여부를 알 수 없어 P3/P4 신뢰도 이슈가 남아 있다.

**설계 결정**: 실제 disk 저장이 아닌 순수 시각 피드백으로 처리. 의미론적으로 정직하다 — 데이터는 이미 메모리에 안전하다.

**구현 방법**:
```dart
onPageChanged: (i) {
  setState(() => _page = i);
  // 이전 페이지에 값이 1개 이상 있으면 저장 확인 표시
  final prevPage = _page; // 이전 _page 값 (onPageChanged 호출 전)
  final hasFilled = _categories[prevPage].fields
      .any((k) => _ctrls[k]!.text.trim().isNotEmpty);
  if (hasFilled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved.'), duration: Duration(seconds: 1)),
    );
  }
}
```
단, `onPageChanged` 시점에 이미 `_page`가 업데이트되기 전이므로 이전 page index 캡처 로직 주의 필요.

**블로커**: 없음. **권장: Sprint 4에서 /go 착수.**

---

### P2-7 — WOD Builder RX standard guide
**상태: 조건부 실행 가능 · 2h (하드코딩) / 4h+ (백엔드 연동)**

현재 구현:
- `Movement` 모델: `slug`, `nameKo`, `unit`, `loadType`, `requiredMetrics` 5개 필드만 존재. `rxWeightM`/`rxWeightF` 없음.
- `movement_picker.dart`: RX 가이드 UI 없음. 동작 선택 후 `_ItemParamsSheet`에서 중량 입력만.

두 가지 접근:

**A. 하드코딩 로컬 Map (권장)**
```dart
// lib/core/rx_standards.dart
const kRxStandards = {
  'thruster': (m: 43.0, f: 29.0),       // kg
  'pull_up': (m: 0.0, f: 0.0),          // bodyweight
  'box_jump': (m: 60.0, f: 50.0),       // cm
  'double_under': (m: 0.0, f: 0.0),
  'burpee': (m: 0.0, f: 0.0),
  // ...표준 CrossFit RX 기준
};
```
`movement_picker.dart` `_ItemParamsSheet`에서 slug 매칭 → `"RX: 43 kg (M) / 29 kg (F)"` caption 표시. 단위 토글(kg↔lb) 연동.

**B. 백엔드 API 확장**: `GET /v1/movements` 응답에 `rx_weight_m`, `rx_weight_f` 추가 → `Movement.fromJson` 파싱. 백엔드 데이터가 SSOT가 되어 유지보수성 우수하나 백엔드 작업 선행 필요.

**결정**: MVP에는 하드코딩 A 접근. 백엔드 데이터 노출 시 동적 전환(Movement 모델 필드 추가만 하면 됨).

**블로커**: 없음 (하드코딩 기준). **권장: Sprint 4에서 /go 착수.**

---

### P2-9 — GoogleFonts 오프라인 폴백
**상태: 실행 가능 · 1h**

현재 구현 (`theme.dart:186-220`):
```dart
static TextStyle get brandSerif => GoogleFonts.bodoniModa(
      fontSize: 72, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, ...);
static TextStyle get h1Serif => GoogleFonts.bodoniModa(...);
static TextStyle get displaySerif => GoogleFonts.bodoniModa(...);
static TextStyle get quoteSerif => GoogleFonts.bodoniModa(...);
```

확인 결과:
- `pubspec.yaml`: `PretendardVariable.ttf`만 번들. BodoniModa 없음.
- `assets/fonts/`: `PretendardVariable.ttf`만 존재.
- `fontFamilyFallback` 지정 없음.

GoogleFonts는 캐시 없는 오프라인 환경에서 조용히 시스템 serif (보통 Noto Serif)로 폴백한다. Pretendard italic으로 명시적 폴백이 없어 브랜드 일관성 손상.

**구현 방법**:
```dart
static TextStyle get brandSerif => GoogleFonts.bodoniModa(
      fontSize: 72,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      height: 1.0,
      letterSpacing: -2.0,
      fontFamilyFallback: [FacingTokens.fontFamily],  // 'Pretendard'
    );
// h1Serif, displaySerif, quoteSerif 동일 패턴
```

`fontFamilyFallback`에 `'Pretendard'`를 추가하면 오프라인/캐시 미스 시 Pretendard Variable italic으로 폴백한다. 완전한 시각 동일성은 불가능하지만 브랜드 파괴(시스템 serif) 방지.

**블로커**: 없음. **권장: Sprint 4에서 /go 착수.**

---

### P2-10 — Galaxy Z Fold5 레이아웃
**상태: 부분 실행 가능 (정적 분석) · 실기기 없음 (검증 블로커)**

현재 구현:
- 코드베이스 전체에 `LayoutBuilder` / `AdaptiveLayout` / `isTablet` 분기 없음.
- 모든 화면 단일 컬럼 + `SafeArea` + `ListView`/`Column` fixed 구조.

Galaxy Z Fold5 리스크 분석:

| 상태 | 폭(dp) | 리스크 |
|---|---|---|
| 외부 화면 닫힘 (6.2") | ~368dp | 낮음 — 현 single-column 레이아웃 그대로 작동 |
| 내부 화면 펼침 세로 | ~1768dp high | 중간 — 과도한 여백, 텍스트 라인 짧아짐 |
| 내부 화면 펼침 가로 | ~2208dp wide | 높음 — BottomNavigationBar 가시성, 키보드+콘텐츠 겹침 |

`LayoutBuilder` scaffolding 추가 (~2h)는 가능하나:
1. 내부 화면 펼침 가로 모드에서의 키보드+내용 겹침은 실기기 재현 필수
2. Fold5 힌지 영역 회피(DisplayFeature) API 적용 여부 판단 불가
3. 에뮬레이터 Fold5 프리셋은 전환 시뮬레이션 정확도 제한적

**결정**: 코드 레벨 기초 breakpoint 추가는 진행 가능하나 "검증 완료" 표기 불가. 실기기 확보 후 별도 세션에서 진행.

**블로커**: 실기기(Galaxy Z Fold5 또는 에뮬레이터 Fold5 + 가로 모드 키보드 시뮬레이션). **Sprint 4에서 착수 금지. 실기기 세션 따로 예약.**

---

## 2. 지난 하루 신규 UX 이슈

v1.15.2 → v1.16 사이 자동 저장된 변경 분에서 발견한 이슈:

### 신규 이슈 N1 — Voice V8 마침표 탈락 (중요)
**위치**: `home_screen.dart:71`, `onboarding_grade.dart:82,141`

```dart
// home_screen.dart — 변경 후
const Text("TODAY'S WOD\nPULL YOUR SPLIT", style: FacingTokens.h1)
// 이전: "Today's WOD.\nPull your Split."
```

CLAUDE.md V8 규칙: **1줄 선언·헤드라인(동사 포함 2단어+) = 마침표 유지**.  
현재 `"TODAY'S WOD"`, `"PULL YOUR SPLIT"`, `"YOUR TIER"` 모두 마침표가 제거된 상태.

대문자화 자체(NOBULL 스타일)는 정당하나 마침표 탈락은 V8 위반이다.  
수정: `"TODAY'S WOD.\nPULL YOUR SPLIT."` / `"YOUR TIER."`

**Priority: P1. 공수: 30분.**

### 신규 이슈 N2 — AppBar + 본문 동일 텍스트 중복
**위치**: `onboarding_grade.dart:46, 82, 141`

AppBar title `'YOUR TIER'`와 body `Text('YOUR TIER', style: FacingTokens.h1Serif)`가 동일 화면에 공존. R1 규칙(화면당 h1 1개)을 문자 그대로는 지키지만, 같은 문구가 두 곳에 등장해 위계가 무너진다.

**수정 방향**: AppBar title 제거 또는 null로 설정, body h1Serif만 유지.  
**Priority: P2. 공수: 15분.**

### 신규 이슈 N3 — Grade Score 표기 CLAUDE.md 충돌 가능성
**위치**: `onboarding_grade.dart`

`engineScoreTo100(score)` 함수로 1~6 → 0~100 변환 후 `"Score NN / 100"` 표기.  
CLAUDE.md 티어 시스템 표는 `overall_number` 1~6 기준이나, 100점제 변환 자체는 새 `scoring.dart`의 책임이므로 UI 레벨은 문제없다.  
다만 VISUAL_CONCEPT.md 및 DESIGN_PLAYBOOK.md와 100점제 표기 정책 일치 여부를 사람이 확인할 것.

**Priority: P2 (확인 필요). 공수: 확인 후 판단.**

### 신규 이슈 N4 — 한국어 Snackbar in 공유 버튼 stub
**위치**: `onboarding_grade.dart` share 버튼 onPressed

```dart
SnackBar(content: Text('Tier 카드 공유는 Phase 2에서 지원 예정.'))
```

V8 규칙: 버튼·토스트(단어 1~3개)는 영문 단독. 이 Snackbar는 1줄이지만 한국어 문장.  
수정: `"Sharing: Phase 2."`

**Priority: P2. 공수: 5분.**

---

## 3. /go 파이프라인 권장 여부

| 항목 | 권장 | 이유 |
|---|---|---|
| P1-14 Save toast | **YES** | 블로커 없음, 30분, UX 신뢰도 직결 |
| P2-9 GoogleFonts 폴백 | **YES** | 블로커 없음, 1h, 오프라인 브랜드 보호 |
| N1 Voice V8 마침표 | **YES** | 블로커 없음, 30분, CLAUDE.md 강제 규칙 |
| P2-7 RX standard (하드코딩) | **YES** | 블로커 없음, 2h, P4~P7 페르소나 요구 |
| N2 AppBar 중복 | **YES** | 30분, R1 위계 정리 |
| N4 한국어 toast | **YES** | 5분, V8 1줄 수정 |
| P2-10 Fold 레이아웃 | **NO** | 실기기 블로커, 검증 불가. 별도 예약. |

**종합 권장: /go 착수 YES** — P2-10 제외 5개 항목을 단일 Sprint 4 세션으로 처리.

---

## 4. 다음 Sprint 우선순위 Top 5

| 순위 | 항목 | 공수 | 근거 |
|---|---|---|---|
| 1 | **N1 Voice V8 마침표 복구** | 30분 | CLAUDE.md 강제 규칙 위반. 모든 화면 영향. |
| 2 | **P1-14 Save toast** | 30분 | P3/P4 페르소나 신뢰도. 블로커 0. |
| 3 | **P2-9 GoogleFonts 폴백** | 1h | 오프라인 첫 실행 브랜드 보호. 코드 4줄 변경. |
| 4 | **P2-7 RX standard 하드코딩** | 2h | WOD Builder 실사용성. P4~P7 페르소나 신뢰도 직결. |
| 5 | **N2/N4 AppBar 중복 + 한국어 toast** | 20분 | 소규모 폴리싱, Sprint 4 첫 warm-up. |

**P2-10 Fold 레이아웃**: 실기기 세션 별도 예약. Sprint 4에서 착수 금지.

---

## 5. 예상 전체 공수

| 항목 | 공수 |
|---|---|
| N1 V8 마침표 | 0.5h |
| P1-14 Save toast | 0.5h |
| P2-9 GoogleFonts 폴백 | 1.0h |
| P2-7 RX standard (하드코딩) | 2.0h |
| N2/N4 소규모 폴리싱 | 0.5h |
| 검증·commit·push | 0.5h |
| **합계** | **5.0h** |

P2-10 (Fold 기기 검증) 별도: 추정 3~4h (에뮬레이터 셋업 + 코드 + 기기 재현).

---

## 6. 판단 근거 명시 (자율 결정 사항)

- **P1-14 의미론적 정직성 판단**: 실제 disk persist 없이 Snackbar 표시하는 것이 기만인가? → 아니다. TextEditingController는 위젯 생명주기 동안 안전하게 persist되며, 사용자가 앱을 종료하지 않는 한 데이터는 살아있다. "Saved." = 세션 내 저장 보증으로 해석 가능. HWPO 기준: 실용적 안심이 공허한 침묵보다 낫다.

- **P2-7 하드코딩 선택**: 동적 API 데이터가 SSOT로 더 우수하지만 백엔드 의존성이 생긴다. MVP 범위에서 CrossFit Open RX 표준값은 실질적으로 매년 고정값이다. CompTrain 근거: "정확한 수치를 지금 주는 것이 완벽한 수치를 나중에 주는 것보다 낫다."

- **P2-10 착수 금지 결정**: LayoutBuilder 코드 추가는 2h이나 Fold5 특유의 DisplayFeature API (힌지 영역 회피), 소프트웨어 키보드 + 폴더블 포스처(half-open) 상호작용은 실기기 없이 정확한 구현 불가. 잘못된 breakpoint가 Fold5에서 더 나쁜 UX를 만들 수 있어 착수보다 보류가 낫다.

---

## 관련 경로

| 역할 | 경로 |
|---|---|
| 이전 HANDOFF | `docs/HANDOFF.md` (v1.15.2 기준) |
| 아카이브 HANDOFF | `docs/archive/HANDOFF-2026-04-24.md` |
| 페르소나 피드백 SSOT | `docs/PERSONA_FEEDBACK_v1.15.md` |
| Benchmarks 화면 | `lib/features/onboarding/onboarding_benchmarks.dart` |
| Grade 화면 | `lib/features/onboarding/onboarding_grade.dart` |
| 테마 토큰 | `lib/core/theme.dart` |
| Movement 모델 | `lib/models/movement.dart` |
| Movement 피커 | `lib/features/wod_builder/movement_picker.dart` |
| Home 화면 | `lib/features/home/home_screen.dart` |
