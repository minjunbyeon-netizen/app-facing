## 📲 Rule 1 (이 프로젝트 1순위 — 2026-05-24 08:53)

**모든 작업 완료마다 `PushNotification` 으로 폰 푸시. 사용자가 30분 이상 답이 없으면 다시 발사.**

- 매 응답 종료 시 (단답·박스·긴 본문 무관) `PushNotification` 1회 호출. 응답 마지막 `✨ ... ✨` 푸터 직전에 발사.
- 메시지 형식: `[hyphen] {작업 요약 30자 이내}` (80자 권장, 200자 hard limit, 이모지는 → ✓ ● ○ 만)
- 사용자가 마지막 메시지를 보낸 뒤 **30분 무응답** 이면 idle-watcher 가 자동 재발사 — 같은 idle 구간에서 30분 단위 반복
- 안전장치 유지: rate limit (5분 2회 cap) · 무음 모드 (`"조용히"`·`"방해 금지"`·`"푸시 꺼"` 키워드 시 세션 종료까지 잠금)
- 글로벌 `rules/common/push-notification.md` Tier 3 (= 매 응답 푸시 금지) 룰을 사용자 의지로 override
- 메모리 SSOT: `~/.claude/projects/C--dev-apps-facing-app/memory/feedback-push-every-turn.md`

---

## 🔒 3면 공통 대전제 (강제·차단 · 사용자 지시 2026-08-12)

> app · web/facing-admin · services/facing **세 곳 전부 같은 문구로 박아둔 상위 규칙.**
> 정본 = `docs/ARCHITECTURE_BRIEF.md §2-0`. 다른 문서와 충돌하면 이 4줄이 이긴다.

1. **역할은 딱 셋 — 코치 · 회원 · 회원신청자.** 박스를 운영하는 사람은 전부 **'코치'** 하나다
   (사장·오너·매니저·관리자는 이 제품에 없는 말). 운영 권한을 역할로 가르지 않는다.
   → 넷째 역할 신설 금지 · 코치라서 막는 분기 신설 금지. super admin 은 나중에 (2026-08-12).
   → 표기 정본 = `docs/GLOSSARY.md` · 권한 정본 = 브리프 §2-0-1 · 자동 게이트 = `test/copy_lint_test.dart`
2. **회원은 폰(앱)에서만 쓴다.** 회원용 웹 화면을 만들지 않는다 (백엔드는 JSON API 만).
   → 이 repo 가 회원 창구의 전부다. 회원 기능을 브라우저로 옮기자는 제안 금지
3. **코치는 PC 에서도 쓴다** (PC 가 주, 폰이 보조).
   → 이 앱의 코치 화면은 PC 웹의 **보조**다. "코치는 폰 안 씀" 전제 금지
4. **전 체육관은 한국이다 — 시간대는 KST 하나.** (2026-08-26 사용자 "전부 한국이야, 확실히 못박아놔")
   → `gyms.timezone` 은 'Asia/Seoul' 한 값 · 서버 `api/_time.py tz_of` 는 항상 KST · 다른 시간대
   체육관 대비 작업(func.date 범위 전환·시간대 설정 화면) 금지. 폰·PC 는 표시만 기기 시간대.

5. **제품은 코치↔회원 4가지뿐 — 공지사항 · 쪽지 · 수업 예약 · 수업 공개(+게이미피케이션: 업적).**
   (2026-08-27 사용자 "그게 끝이야. 여기에 위배되거나 필요없는 건 없애도 된다니까")
   → 새 기능은 **"4기둥 중 어디냐"** 를 먼저 답한다. 못 답하면 만들지 않는다.
   → **4기둥은 신규 게이트다. 이미 있는 것을 걷어내는 근거로 쓰지 않는다** (2026-08-27 사용자
     "아니 놔둬, 지금 있는 것까지는 괜찮아"). 락커·통계·결제/환불·WOD 소셜·목표/최고기록/히스토리·
     전자계약서는 **존치 확정 — 제거 재제안 금지**. 집행된 제거는 D63·D64 까지가 끝.
   → 받침(회원 명단·가입 승인 · 회원권 · 수업 종류/시간표 · 인증 · 업적/포인트 설정 · 출석)은 남긴다.
   → 지우기 전 **호출처를 직접 재확인**한다 (2026-08-27 감사에서 "사문" 2건이 실제로는 살아 있었다).
   → **DB 테이블·사용자 데이터는 지우지 않는다** — 코드 경로만 끊고 휴면으로 남긴다.
   → 스코프 정본 = `apps/facing-app/CLAUDE.md §제품 스코프 — 코치↔회원 4기둥`

6. **한 사실은 한 곳에서만 센다 — 이원화 금지.** (2026-08-29 사용자 "각자 다른 걸 말하는
   이원화 현상이 주된 이유다. 명백히 법적으로 막아라")
   → 화면에 보이는 **모든 수치·판정은 세는 함수 한 개**에서만 나온다. API 도 화면도
     부르기만 한다. 정본 = `api/_metrics.py` (`_membership.py`·`_time.py` 와 같은 결).
   → **같은 사실을 두 곳에서 세면 값이 우연히 같아도 결함이다** — 한쪽만 고치는 순간
     두 화면이 다른 숫자를 말한다.
   → **새 창구는 일치 검사 목록(`tests/test_ssot_agreement.py` WINDOWS)에 등재**해야 한다.
   → 사실이 바뀌는 **사건은 덮어쓰지 말고 쌓는다** (취소 이력이 지워져 결함 두 건이 났다).
   → 위반은 게이트 둘이 자동으로 잡는다 — `tests/test_ssot_metrics_lint.py`(정의 중복,
     baseline 방식: 늘면 실패·줄면 낮추라고 알림) + `tests/test_ssot_agreement.py`(등록제).
     값 대조 정본은 `tests/test_roundtrip_numbers.py`.
   → **6-b 이음새 (2026-08-29 사용자 "절대규칙으로 이음새, 이원화, api, 같은 곳을 보고, 같은 것을
     계산하고, 이거 정말 중요하다")**: 수치 밖에도 적용한다. 앱↔서버↔PC 를 건너는 모든 것 —
     **허용값(enum)·라벨·검증 규칙·표시 텍스트 렌더링·정렬 기준·범위 정의** — 은 정의 1곳에서만
     나오고 나머지는 부르기만 한다. PC JS·앱에 매핑 표·검증·정책 계산을 복제하지 않는다 (API
     응답의 값·라벨을 그대로). 서버 안에서도 같은 리터럴 집합을 두 파일에 적지 않는다 (import 로
     파생). 정의를 만들면 **같은 커밋에 정적 게이트**(재정의 감지 테스트)를 만든다 — 문서로만
     막는 것은 위반. 예 = D88 `services/program_lines.py`(wod_type·본문 렌더) +
     `models/movement_library.py`(단위·분류 라벨) + `tests/test_ssot_program_lint.py`.
---

⚠️ **최우선 — 모든 작업은 `docs/ARCHITECTURE_BRIEF.md` 를 따른다.**
이 브리프가 Hyphen 시스템(폰 + PC + 백엔드 + RBAC + SSE + DB 모델) 전체 합의 SSOT 예요.
신규 기능·코드 변경 시:
1. 브리프 먼저 읽고 충돌 여부 확인
2. 충돌 발견 시 사용자에게 보고 → 브리프 갱신 승인 후 코드 변경
3. 브리프 §11 변경 절차 준수 (코드만 갱신·브리프 방치 금지)
관련: `services/facing/`·`web/facing-admin/` 작업 시에도 같은 브리프 적용.

⚠️ 세션 시작 시 `docs/HANDOFF.md` 도 함께 읽고 현재 작업 상태를 파악할 것.

⚠️ **UI·디자인·카피 관련 모든 결정은 먼저 글로벌 `~/.claude/reference/{mobile,ux,design}.md` → 이 문서 순으로 확인**. 충돌 시 reference/가 이김. 프로젝트 전용 카피 SSOT(티어 시스템·용어 팔레트·V1~V11 어투·카피 템플릿)는 본 문서 하단에 유지.

## ✅ 전면 자동 승인 규칙 (2026-08-24 사용자 지시 — 구 v1.16.1 배포 금지 룰 폐기)

**이 프로젝트(hyphen 3면: apps/facing-app · services/hyphen · web/facing-admin) 안에서는
Claude 가 사용자에게 아무것도 묻지 않고 전부 실행한다. 배포 포함.**

- `git push` · `railway up`(백엔드·관리자 웹) · 릴리즈 APK 빌드·실기기 설치 · 프로덕션 DB
  마이그레이션 적용 — 전부 확인 없이 즉시 실행하고 결과만 보고
- 글로벌 CLAUDE.md §4 "사용자 확인 후 실행" 항목도 이 프로젝트 범위에서는 **상시 사전 승인**
  상태로 간주 (외부 시스템 쓰기·배포·DB 적용 포함)
- "배포할까요?" · "진행할까요?" 류 질문 금지 — 진짜 갈림길(취향·전략 A/B)만 예외적으로 질문 허용
- 권한 팝업 제거 = `.claude/settings.local.json` `defaultMode: bypassPermissions`
  (2026-08-24 사용자 직접 적용) · `.nopush` 게이트 마커 3면 모두 제거 (같은 날)

**잔여 예외 (글로벌 절대 차단 — 프로젝트 룰로 못 푸는 것)**:
- main 브랜치 force push (§2-A-6) · 시크릿 하드코딩/커밋 (§2-A-1) · `git reset --hard` 류 파괴 git
- 하니스 자체 차단(분류기·훅)에 걸리면 우회하지 않고 보고

(구 배포 금지 규칙 전문은 git log 2026-08-24 이전 커밋에 보존)

# facing-app -- WOD 페이싱 전략 모바일 앱

> Flutter 기반 Android+iOS 앱. 백엔드 `services/facing/` API와 JSON 통신. UI/UX만 담당, 계산 로직 0%.

## 외부 자료 위치 (SSOT)
페이싱 공식·논문·벤치마크 자료는 **이 폴더에 없음**. 백엔드 쪽 단일 출처:
**`C:\dev\services\facing\docs\refer\{카테고리}\findings.md`** (10개 카테고리)
앱은 UI만 담당하므로 페이싱 알고리즘/공식 관련 질문이면 백엔드 docs/refer 참조. 사본 만들지 말 것 (헷갈림 방지).

## 제품 스코프 — 코치↔회원 4기둥 (v3.29 · 2026-08-27 사용자 지시 · **최상위 스코프 기준**)

> 사용자 원문: "이건 코치와 회원 간의 — **공지사항 · 쪽지 · 수업 예약 · 수업 공개(이것에 따른
> 게이미피케이션: 업적)** 그게 끝이야. 여기에 위배되거나 필요없는 건 없애도 된다니까."

**이 제품은 다음 4가지뿐이다. 전부 코치와 회원 사이의 것이다.**
1. **공지사항** — 코치 → 회원
2. **쪽지** — 코치 ↔ 회원 (자동 알림 쪽지 포함 — D60 "알림 = 앱 쪽지 하나")
3. **수업 예약** — 회원 → 수업 (자격 판정 = D57 횟수권 차감 · D58 예약 오픈/소멸)
4. **수업 공개** — 코치가 수업 내용 게시 + **그에 따른 게이미피케이션 = 업적**

**받침 (지우면 기둥이 무너지므로 남긴다)**: 회원 명단·가입 승인 · 회원권(예약 자격) ·
수업 종류/시간표(예약 대상) · 로그인/인증 · 업적·포인트 설정(4번의 설정면) · 출석
(리워드 엔진 트리거 — **하루 1회**, 2026-08-30 사용자 "1일은 1회만 출석임", 정본
`api/_metrics.py attended_on`) · 체육관 1곳 식별.

**적용 규칙 (강제)**
- 새 기능 제안·추가 전에 **"이게 4기둥 중 어디냐"** 를 먼저 답한다. 못 답하면 만들지 않는다.
- 4기둥 밖 기능을 발견하면 **제거 대상으로 올린다** (구 "갭은 보고만" 은 *추가* 에 대한 것 —
  *제거* 는 이 지시로 승인됨). 단 **호출처·참조를 직접 재확인한 뒤** 지운다 — 2026-08-27
  감사에서 "사문" 이라던 것 중 2건이 실제로는 살아 있었다(`openPanelB`·`services/leaderboard.py`).
- **DB 테이블·사용자 데이터는 지우지 않는다.** 코드 경로만 끊고 컬럼·표는 휴면으로 남긴다
  (선례 = `gym_profiles.instagram`, 2026-08-27 D63).

### 구 3기둥 서술 (v1.27 · 2026-07-28 — 앱 셸 탭 축, 위 4기둥이 상위)
회원 앱에 게이미피케이션 · 수업 보드 · 내 프로필 3개만 노출한다는 서술이었다. **셸 3탭은
사실로 유효**하나, 스코프 판정 기준은 위 4기둥이다 (내 프로필은 기둥이 아니라 받침·표시면).
- 셸 = **4탭** (홈 · 수업 · 히스토리 · 내 정보 — D85 2026-08-29 히스토리 탭 추가, 구 3탭은 v3.0 2026-08-14 표기. 기본 landing = 수업(구 WOD) 탭)
- **3기둥 밖 도달 불가 화면은 코드까지 삭제 (v3.2 · 2026-08-20 사용자 지시 — 구 "숨김 = 코드 보존" 정책 종료)**
  — Attend·Rehab·리더보드·체육관 개설/검색·데이터 가져오기 등 일괄 제거. 목록·복원 좌표 =
  `README.md §제거된 기능 대장` (엔진 화면은 `_archive/lib-engine/`). 백엔드 배선은 유지.
- UI 컴포넌트 SSOT = `lib/widgets/hkit.dart` (HKit) — 아래 디자인 원칙 참조

## 리브랜딩 — 표기 브랜드 HYPHEN (v1.28 · 2026-07-28 사용자 지시)
- **HYPHEN 으로 통일**: MaterialApp title · 런처 라벨(AndroidManifest) · 스플래시/인트로/로그인 로고
  (BrandLogo) · 공유 문구("HYPHEN WOD") · appkit 스킨 brand.name · 런처 아이콘
  (`tool/gen_launcher_icon.py` 로 재생성 — BrandLogo 와 동일 기하)
- **2026-08-13 사용자 결정으로 전량 개명 집행됨 (applicationId 포함 — 재설치 필요)**:
  applicationId·namespace `com.netizen.facing.facing_app` → `com.netizen.hyphen.hyphen_app`
  (구 설치본과 업그레이드 연속성 끊김 — 재설치 필요) · 코드 심볼(FacingTokens→HyphenTokens·
  FacingTheme→HyphenTheme·FacingApp→HyphenApp·Fk\* 위젯→Hk\*·`fkit.dart`→`hkit.dart` 전량) ·
  pubspec `facing_app`→`hyphen_app` · 백엔드 계약 값(GymSummary is_official 판정 문자열
  'FACING'→'HYPHEN HQ' — 백엔드 `services/facing` 쪽 동시 마이그레이션 필요) · 노출 문구
  (알림 타이틀·약관 화면 등) 전량 HYPHEN. **아직 미개명 (다른 repo·GitHub·Railway 소관)**:
  repo·폴더명(facing-app / app-facing) · 백엔드/랜딩 서비스명(service-facing 등) ·
  실도메인 URL(`service-facing-production…`) · Naver OAuth URL scheme 기본값('facing' 유지 —
  Naver 개발자 콘솔 등록값과 동기화 필요, 임의 변경 금지)

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

## 브랜드 포지셔닝 (단일 진원지 -- v1.16.2 갱신 2026-05-24)

### Primary value (NEW)
> **"수업을 간편하게 — 관리하는 CrossFit 앱."**
> 회원·코치·사장 모두를 위한 박스 운영 + 수업 관리. 클래스 예약·결제·계약·공지·코치 정보가 메인.

### 보조 value / 차별점 (NEW)
> **페이싱 엔진은 Hyphen 만의 +α.** Wodify/PushPress 가 못 따라오는 선수 도구. 메인 가치는 아니지만 우리만의 hook.

### 톤·언어 정책 (유지)
> Voice & Tone V1~V11 (HWPO/NOBULL/Mayhem/CompTrain 4 벤치마크) 그대로. CrossFit Games 의 미감을 일반 박스 운영 앱에 입혀서 차별화.
> 단, "Games 출전자급 엘리트 전용" 한정 문구는 폐기 (v1.12.0 → v1.16.2). 회원층은 RX-aspiring 부터 Games 까지 다 포함.
> 금지 용어(헬스·다이어트·웰니스) 는 그대로 유지 — CrossFit 정체성 보존.

### 벤치마크 레퍼런스 (톤·카피·레이아웃 기준)
모든 UI·카피·비주얼 결정은 아래 4개 브랜드를 기준점으로 삼는다. 신규 화면 설계 시 "이 4곳이라면 뭐라고 쓸까"부터 먼저 질문.

| 브랜드 | 톤 키워드 | 벤치마크 포인트 |
|---|---|---|
| **HWPO** (Mat Fraser) | "Earn it." 명령형·자부심 | 짧은 영문 명령어, 고대비 타이포, 장식 제로 |
| **NOBULL** | Stoic·blacked out | 모노 블랙/화이트, 긴 설명 없이 이미지+단어 하나 |
| **Mayhem** (Rich Froning) | Team·discipline | 숫자·기록 우선, 과시 없음 |
| **CompTrain** (Ben Bergeron) | Coach·analytical | 데이터·근거 제시, 교조적 문장 |

언어 결정이 애매할 때 순서: (1) HWPO가 쓸 것 같은가? (2) NOBULL에서 잘릴까? (3) Mayhem 수치 기준 통과? (4) CompTrain 근거 있는가?

> **4 벤치마크 충돌 시 우선순위**: 카피 결정은 **HWPO** 톤이 이긴다. 비주얼 결정은 **NOBULL**이 이긴다. 단, 실제 우선순위는 `~/.claude/reference/{mobile,ux,design}.md > 본 문서 (CLAUDE.md)` (위가 우위). — §9 Differentiation 6-pager FAQ Q7.

## Voice & Tone v2.0 — 한글 기본 (v1.29 · 2026-07-28 사용자 지시)
> **SSOT = `docs/DESIGN-SSOT.md §7`** (구 V1~V11 영문 중심 원칙 폐기 — "안에 너무 영어가 많다" 지시로 전환). 요지:
- **기본 언어 = 한글.** 버튼·탭·헤더·섹션 라벨·안내·에러 전부 한글.
- **영문 유지 = 도메인 고정어만**: `HYPHEN`(브랜드) · `AMRAP` `EMOM` `RX` `RX+` `Scaled`
  `Elite` `Games` `1RM` `PR` `UB` `Metcon` `For Time` `Engine` `Split` `Burst` · 단위 `kg/lb` ·
  `XP` · 동작명(Thruster 등) · Engine 카테고리(POWER/OLYMPIC/…) · 명언(원문 유지, 저자 병기).
- **크로스핏 표기 철수 (v3.0 · 2026-08-14 "이 제품은 크로스핏장이 아니다")**: 노출 문구에서
  박스→체육관 · WOD 게시물→수업 내용 · 시간표 면→수업 시간 · 크로스핏 경력→운동 경력 ·
  "박스 가입 신청"→"회원 가입 신청". 고유명사(Fran·Girls/Hero/Games WOD·CrossFit Open/Games·
  명언 원문)와 내부 코드·API·DB 이름은 예외 — 정본 = `docs/GLOSSARY.md §2 v2`.
- **톤**: 명사형 간결체 ("오늘의 수업" · "불러오기 실패"). 버튼 = 2~4자 동사 ("저장" "다음" "다시 시도").
  공허한 응원·이모지 금지 유지. 숫자 기반 서술 유지 (Mayhem/CompTrain 계승).
- **혼용 허용**: 도메인 영단어 + 한글 조사 결합 OK ("1RM 을 갱신했습니다") — 구 V9 금지 폐기.
- 공통 문자열(건너뛰기·다음·저장·취소·불러오는 중 등) 정본 = `appkit.config.json > strings`.

### 금지 용어 (copy_lint_test 차단 — v3.0 갱신)
박스 · 크로스핏 · WOD(일반 명칭 — 고유명사 제외) · 헬스 · 다이어트 · 건강 · 체중관리 · 체력증진 · 웰니스 · 칼로리 소모 · "쉬운" · "편리한" · "누구나" · 당신 · 귀하
('운동' 은 v3.0 에서 해제 — '운동 경력' 이 정본)

## 티어 시스템 (등급 표기 SSOT)
백엔드 응답 `overall_number` (1~6) → 프론트에서 5 티어로 매핑:

| number | Tier | 색상 토큰 | 설명 |
|---|---|---|---|
| 1 | **Scaled** | `tierScaled` #52525B 회색 | Novice. 스케일드 동작 위주 |
| 2 | **Scaled** | 동일 | Intermediate low |
| 3 | **RX** | `tierRx` #CC1F1F 빨강 | RX 표준 달성 |
| 4 | **RX+** | `tierRxPlus` #C05000 주황 | Advanced |
| 5 | **Elite** | `tierElite` #92700A 금색 | Regionals 급 |
| 6 | **Games** | `tierGames` #606060 실버 | Games 출전급 (최상위) |

> 값 정본 = `lib/core/theme.dart`. 위 6색은 v2.0 라이트 전환 때 흰 배경 4.5:1 을
> 맞추려 전부 어둡게 내린 값이며, 문서만 다크 시절 값에 머물러 있던 것을
> 2026-08-12 실측 대조로 바로잡았다 (§0-B).

- UI에 "RXD 4/6" 같은 백엔드 내부 코드 노출 금지. 항상 위 5티어 라벨만 사용.
- 티어 배지: 2px solid 티어 컬러 + 대문자 라벨 + 얇은 padding. 아이콘 없음.

## 디자인 시스템 (v1.15.0 — 콘트라스트 강화 + 액센트 4색 분리)
> v1.15.0 변경 내용: 다크 콘트라스트 강화, surface 4단계 확장, 액센트 4색(primary/success/info/danger) 분리. code-level 버전은 theme.dart v1.23. 사용자 승인: 2026-05-23.

> ⚠ **아래 표는 v1.15 다크 시절 기록이다 — 현재 값이 아니다.**
> v2.0(2026-05-24)에서 라이트 톤으로 전면 전환하며 bg·surface·fg·muted 가 전부 뒤집혔고,
> v2.2(2026-08-12)에서 `primary` 가 #EE2B2B → **#CC1F1F** 로 내려갔다 (흰 배경 4.01:1 →
> 5.32:1, 흰 글씨 4.19:1 → 5.55:1 로 양방향 AA 통과). **현재 값 정본은
> `lib/core/appkit.gen.dart` + `lib/core/theme.dart`**. 표 전면 교체는 사용자 승인 대기.

### 컬러 토큰 (구 v1.15.0 다크 — 이력 보존용)
| 토큰 | 값 | 용도 |
|---|---|---|
| `bg` | `#0A0A0A` | 기본 배경 (변경 없음) |
| `surface` | `#161616` | 카드 1단 (↑밝게) |
| `surfaceHigh` | `#1F1F1F` | 카드 2단 (모달·중첩) — 신규 |
| `surfaceMax` | `#2A2A2A` | 액티브 highlight — 신규 |
| `surfaceOverlay` | → `surfaceHigh` | @deprecated v1.24 제거 |
| `fg` | `#FFFFFF` | 본문 텍스트 (순백 강화) |
| `fgSecondary` | `#D4D4D4` | 보조 텍스트 — 신규 |
| `muted` | `#9CA3AF` | 보조 텍스트 (↑밝게) |
| `mutedStrong` | `#6B7280` | 더 어두운 muted — 신규 |
| `border` | `#333333` | 구분선 (콘트라스트 ↑) |
| `accent` | `#B97A4A` | HWPO 탠 (brand action, @deprecated v1.24→primary) |
| `primary` | `#EE2B2B` | CrossFit Red — 기본 CTA·강조 — 신규 |
| `primaryPressed` | `#B91C1C` | primary 눌림 — 신규 |
| `success` | `#10B981` | PR 달성·성공 (Emerald 변경) |
| `warning` | `#F59E0B` | 주의 (변경 없음) |
| `info` | `#3B82F6` | 정보·툴팁·링크 — 신규 |
| `danger` | `#DC2626` | 해지·에러 (primary 와 분리) — 신규 |
| `error` | → `danger` | @deprecated v1.24 제거 |
| 5 tier 색 | 위 표 참조 | 티어 배지 전용 (변경 없음) |

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
| `tierLabel` | 12sp w800 ls+1.8 | 구 TierBadge 전용 (위젯은 v3.2 삭제 — 토큰만 잔존) |
| `brandLogo` | **72sp w800 ls-2.4** | **Splash "HYPHEN" 전용** |
| `bannerLabel` | **12sp w700 ls+1.2** | **Offline 등 배너 라벨 전용** |
| `quote` | 14sp italic | 명언 전용 |

#### 계층 규칙 (v1.14.0)
R1. **화면당 h1 1개.** AppBar title이 있으면 화면 내 헤드라인 h2 제거.
R2. **Tier 결과 화면 최대 2겹.** TierBadge(크게, fontSize 24) + Score 한 줄. `OVERALL` 라벨·`N/6` 숫자 금지.
R3. **섹션 헤더는 `sectionLabel` 단독.** micro/caption/h2 inline/body.w800 섹션 헤더 사용 금지.
R4. **동일 지표 동일 토큰.** "500m pace"=`h3`, "총 예상시간"=`display` 화면 막론 고정.
R5. **하드코드 fontSize 금지.** 모든 텍스트 크기는 `HyphenTokens` 상수 참조. 인라인 `TextStyle(fontSize: N)` 커밋 전 리뷰 거절.

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

## 카피 템플릿 (화면별 정본 — v1.29 한글 기본)
> 규칙 SSOT = `docs/DESIGN-SSOT.md §7`. 대표 카피만 여기 유지 (구 v1.12 영문 표 폐기).

| 위치 | 카피 |
|---|---|
| Splash / 전면 로딩 | **HYPHEN 로고** (BrandLogo 기본 폭 220) — 전면 로딩은 FkLoadingScreen. 로고가 남는 자리는 이 둘뿐 |
| 진입 화면 | **없음** — v3.31(2026-08-27 사용자 승인, D66)에서 갈림길 화면 삭제. 스플래시 다음이 곧바로 로그인 |
| 로그인 화면 (= 앱 첫 화면) | **로고 없음** (v3.19 사용자 지시) — 제목 '로그인' + 아이디/비밀번호 + '아이디 기억하기 (30일)' + [로그인]. 그 아래 작은 줄로 '회원 가입 신청'(→ 가입 신청서), 맨 밑에 이용약관 · 개인정보처리방침. 역할 선택 없음 (코치·회원 판정은 서버) |
| 로그인 버튼 | "네이버 아이디로 로그인" (1순위) · "구글로 시작" — FkSocialButton |
| 로그인 진행 | HkButton(busy: true) — 버튼 자리 그대로, 그 안에서 스피너만 (v3.33 D67) |
| 셸 4탭 | 홈 · 수업 · 히스토리 · 내 정보 (v3.0 크로스핏 표기 철수 · D85 2026-08-29 히스토리 탭) |
| 공지 (홈에서만) | **검정 바탕 · 흰 글자 · 꽉 채워 흐르는 전광판** (v3.43 · 2026-08-29 사용자 "검정바탕에 흰글자가 꽉채워서 흐르게 · 공지는 홈에서만"). `HkMarquee(fill: true)` — 짧은 글도 이어 붙여 줄을 채우고 항상 흐른다. 공지 0건이면 '등록된 공지 없음' 이 서 있다. 수업 탭 하단 공지·체육관 정보 아코디언은 삭제 (README 대장 38) |
| 쪽지 2칸 | **코치** · **활동** (v3.38 · 2026-08-29 D72 "쪽지는 쪽지고(코치와 대화), 업적알림 가입 예약완료 등등 이런건 활동로그"). HkSegment 한 줄 — 기본 진입 = 코치. 코치 칸 = 사람이 쓴 대화만, 활동 칸 = 자동 통보만(예약·대기 승격·결제·만료·해지·가입 승인·업적). 가르는 판정은 서버 `coach_note._is_conversation()` 한 곳. 빈 문구는 칸 이름을 따른다 — 코치 '코치 쪽지 도착 시 표시.' / 활동 '아직 활동 없음.' 코치 셸에는 칸을 두지 않는다 |
| 수업 탭 2칸 | **프로그램** · **수업 시간** (v3.37 분리 · **v3.40 순서 뒤집음** — 2026-08-29 사용자 "수업시간-프로그램 순서 바꾸자. 프로그램 누르면 그날 되는 운동목록이 한번에 보이게"). HkSegment 한 줄 — **기본 진입 = 프로그램**(탭을 열면 "오늘 뭐 하지"가 먼저 답해진다). 프로그램 칸으로 갈 때는 **오늘을 펼친다** (그 주에 오늘이 있을 때만). 주는 두 칸 공용. 빈 문구는 칸 이름을 따른다 — 수업 시간 '등록된 수업 없음.' / 프로그램 '아직 게시 전.'·'게시된 프로그램 없음.' **프로그램 칸(v3.41)**: 그날 프로그램을 **첫 수업 시각 순**으로 세우고(서버 `first_class_at`) 같은 수업 종류는 **한 번만**, 카드는 **전부 펼친다**. 카드 제목은 `AWAKE · FOR TIME` (수업 종류 · 운동 종류). 정본 = `week_board.dart visibleProgram`, 회귀 = `test/golden/program_order_test.dart`. **세션(D89 · 2026-08-30)**: 같은 종류라도 세션이 다르면 카드가 따로 선다 — 이름표는 서버 `display_name` 그대로(`AWAKE · A 세션`), 수업 줄도 서버 `display_title`. 앱은 '세션' 글자를 붙이지 않는다 |
| 온보딩 | "1RM 입력" → "Benchmarks" → "내 Tier" · 제출 "Engine 측정" · 진행 "계산 중" |
| 오프라인 배너 | "오프라인" + "연결 시 동기화." |
| 에러 공통 | FkErrorState — 메시지 + "다시 시도" |
| 빈 상태 예 | "수업 기록 없음" / "오늘 수업 내용 없음." / "아직 업적 없음." |
| 다이얼로그 확인형 | "~할까요?" + 취소/확정 2버튼 ("수업 내용을 삭제할까요?") |

## 디자인 원칙 (Hyphen 전용 — 공통 룰은 글로벌 SSOT 위임)
> 이모지 금지·그라디언트/과도한 그림자 금지 등 공통 디자인 차단은 글로벌 `rules/design-block.md`·`rules/design-presets.md` 가 SSOT.
> **레이아웃·크기·폰트 굵기·카피 양식 정본 = `docs/DESIGN-SSOT.md` (v1.29 신설)** — 화면 작업은 그 양식 안에서만. 아래는 요약.
- **레이아웃 안정성 = 공간 예약 (정본 `docs/DESIGN-SSOT.md §레이아웃 안정성`)** — 상태가 바뀌어도
  요소의 y 좌표가 변하지 않는다. 변할 자리(안내·에러·검증 문구·로딩)는 미리 고정 높이로
  잡아 둔다 — 조건부 상단바·조건부 블록·validator 에러 줄·로딩 스왑 4대 밀림 금지.
  회귀 게이트 = `test/golden/layout_stability.dart` (`expectStableAnchorY`, 브리프 D67).
- **UI 컴포넌트 SSOT = `lib/widgets/hkit.dart` (HKit — v1.27 신설, v1.29 확장, v3.24 골격 통일)**: 카드(HkCard)·배지(HkBadge)·
  섹션 라벨(HkSectionLabel)·통계 타일(HkStatTile)·빈/에러/로딩 상태(HkEmptyState/HkErrorState/HkLoading)·
  전면 로딩(HkLoadingScreen)·소셜 버튼(HkSocialButton)·**전광판 한 줄(HkMarquee — 넘칠 때만 흐름, v3.42)**·**상단바(HkAppBar/.identity)·다이얼로그(HkDialog)·
  바텀시트(HkSheet)·인라인 에러(HkInlineError)·버튼(HkButton — 원시 버튼 0건)**은 HKit 것만 사용.
  화면 코드에 `AppBar(`·`AlertDialog(`·`showModalBottomSheet`·`OutlineInputBorder(`·화면별 `_deco()` 가
  생기면 `test/ssot_lint_test.dart` 가 막는다 (v3.24 · 2026-08-25 사용자 지시 "인라인·이원화 전부 통일"). 화면마다 새 버튼·배지·레이아웃
  variant 신설 금지 — 필요하면 HKit 에 먼저 추가 후 사용 (글로벌 §3 코드·클래스 SSOT 의 프로젝트 배선).
  완전 원형 pill 금지(글로벌 design-block) — 배지는 r1 사각. (구 TierBadge 는 v3.2 삭제.)
- 라이트 배경 기본 (`bg=#FAFAFA`, v2.0 라이트 전환 — 구 다크 #0A0A0A 폐기). 다크 모드 제공 안 함.
- 컬러·타이포·간격·모서리 = appkit 공통 조상 재수출 (HyphenTokens) + tier 5색 — 수치는 DESIGN-SSOT §1~4.
- 폰트 Pretendard 1종. 굵기 4단 정책(400/500/600/700, 로고·display 만 800~900) = DESIGN-SSOT §2.
  ※ 글로벌은 Pretendard 차단이나 Hyphen 앱은 예외 유지.
- ROW 우선, 여백 충분히
- 사진 없음. 타이포+수치 중심.
- **캐릭터 예외 (v3.5 · 2026-08-21 사용자 승인)**: 마스코트 캐릭터는 허용한다.
  단 **사용자가 직접 지정·허용한 그림만** `assets/character/` 에 들어간다
  (규칙·파일명 표 = 그 폴더 README.md). Claude 가 캐릭터를 생성·교체하지 않는다.
  노출 자리(온보딩·스낵바·업적 해금·홈 레벨카드)와 경로 매핑의 SSOT =
  `lib/widgets/mascot.dart` — 화면 코드에 에셋 경로를 적으면 §0-B 위반.
  사진 히어로·스틱맨 폐기(v1.27)는 그대로 유효 — 캐릭터는 사진이 아니다.
- **브랜드 로고 = HYPHEN 워드마크 (v1.27)**: `lib/widgets/brand_logo.dart` (BrandLogo — 모티프+워드마크
  벡터 재현, 테마 색 추종)가 SSOT. 원본 사진 = `docs/brand/hyphen-logo-source.png` (앱 번들 미포함).
  스플래시·인트로의 사진 히어로·스틱맨은 폐기 (v1.27) — 로고 중심 클린 레이아웃.

## 로컬 실행
```bash
cd apps/facing-app
flutter pub get
flutter run                      # 기본 연결된 기기/에뮬레이터
flutter run -d emulator-5554     # 특정 에뮬레이터
```

## 화면 골든 캡처 (골든스탠다드 — 2026-07-28 적용)
```bash
flutter test --update-goldens test/golden   # 전 화면 PNG → test/golden/goldens/
python tool/golden_gallery.py               # 단일 HTML 갤러리 (build/goldens_gallery.html)
```
가짜 백엔드(`test/golden/fakes.dart` — ApiClient implements, 네트워크 0)로 실물 픽셀 렌더
(갤S22 급 360×780·2x). 폰트는 `test/flutter_test_config.dart` 가 FontManifest 전체
(Pretendard·MaterialIcons)를 로드. 참조 아키텍처: `apps/writeplz-app` 골든스탠다드.
현재 **85장** (2026-09-02 잔여 검증 — state_31_inbox_activity_error 신규: 쪽지함 '활동' 칸 조회 실패가 '아직 활동 없음.' 으로 위장하지 않고 에러+다시 시도. 같은 날 수업 시간 칸이 wod.posted 를 듣게 됨 — 픽셀 변화 없어 재생성 없음. 직전 84장 = 2026-08-30 D102 전자계약 — member_28_contract_detail_signed(서명 완료 상세)·member_29_contract_sign_pad(서명 패드) 신규. 직전 82장 = 같은 날 D100 토스트 다섯 장 — 완료 저장: snack_06_saving('수업을 저장 중이에요' 로딩바)·snack_07_saved_fighting(웃는 하이피 '예____ 화이팅!!!!')·state_29_result_sheet_saving(저장 직후 버튼 자리 그대로 busy) / 늦은 취소: snack_05_late_cancel_toast(서버 문장 'N월, N회째 레이트 캔슬…코치에게 전송', 슬픈 하이피)·state_30_late_cancel_done(실흐름). 직전 77장 = 같은 날 D94 동작별 완료 값 — state_28_result_sheet_movements 신규: 완료 시트 '동작별 기록' 칸(한 횟수·무게 kg 가
코치 값으로 미리 채워짐). 직전 76장 = 같은 날 D91 히스토리 완전 통합 — hist_04_detail 신규(점수 라벨·난도·PR·메모·수업 내용), hist_02·hist_03 은
행이 수업 이름/그날 운동 요약/종류·일시 세 줄 + 점수 라벨(+PR 배지)로 재생성. 직전 75장 = 2026-08-29 D86 예약 완료 세 줄 토스트 + 폭죽 — snack_04_reserved · state_27_reservation_done 신규. 직전 = D85 회원 셸 4탭 — member_27_shell_history 신규(히스토리 탭). 직전 = D84 히스토리 검색 — hist_02_list(최근순)·hist_03_search('squat' 연관도순) 신규, hist_01 은 검색 칸이 얹혀 재생성. 순위 규칙 정본 `lib/features/history/history_search.dart` · 단위 검사 `test/history_search_test.dart`. 직전 70장 = D83 내 정보 메뉴 항상 펼침 · '알림 받기' 메뉴 안으로 · '체육관 정보' 화면 신설(수업 종류 노출 복구) — member_05_profile_menu_open 삭제(항상 펼침이라 member_04 와 같은 그림), member_04·25 재생성, member_25 는 이제 GymInfoScreen 실화면. 같은 날 D82 = state_15 가 '예약' 을 눌러 캐릭터 스낵바까지 캡처. 직전 = D81 홈 공지 검정 전광판 · 수업 탭 하단 2개 · 내 정보 3곳 삭제 — 19장 재생성(수 변화 없음). 직전 = D79 수업 안내 노출·공지 실시간 갱신 — member_25_gym_info 가 '수업 종류 (4)' 칸(이벤트 배지 포함)을 담아 재생성. 직전 = D78 프로그램 칸 정렬·중복 제거·전부 펼침 — member_26_program 이 오늘 세 종류(AWAKE·SWEAT·BUILD)를 시간 순으로 펼쳐 보여준다. 직전 = D77 수업 탭 칸 순서 뒤집기 — member_26_program 이 기본 진입이 되고 member_07_classes 는 칸 전환 뒤 캡처, 예약·취소가 걸린 상태 캡처 다수 재생성. 직전 71장 = D74 칭호 제거 — state_06_worn_title 삭제, ach_01·ach_02·member_12·state_21 은 '칭호' 버튼이 빠져 재생성. 직전 72장 = D72 활동 칸 분리 — state_26_inbox_activity 신규: 쪽지함 '활동' 칸(자동 통보만). 짝인 state_20_inbox_threads 는 '코치' 칸(사람이 쓴 대화만)으로, member_11_messaging 은 두 칸 세그먼트가 얹혀 재생성됐다. 직전 71장 = 2026-08-29 테스터 지시 "프로그램과 수업은 분리시킵니다" — member_26_program 신규: 수업 탭 '프로그램' 칸. 짝인 member_07_classes 는 '수업 시간' 칸으로 재생성됐다 (기본 진입). 두 칸 회귀 = `test/golden/week_pane_test.dart`, 칸 전환 밀림 = `test/golden/stability_wod_test.dart` 두 검사. 직전 70장 = 2026-08-28 알림 받기 — state_24_notifications_on · state_25_notifications_blocked 신규: 내 정보 '알림 받기' 한 줄 토글(종류별로 나누지 않음)과 폰 설정에서 막혀 있을 때의 표시. 관문 회귀 = `test/notification_gate_test.dart`, 행 높이 불변 = `test/golden/stability_mypage_test.dart` 7 상태. 직전 68장 = 2026-08-28 잔손질 — coach_05_member_approvals 신규: 가입 신청 화면 첫 캡처, 신청자 연락처가 탭 자리(터치 48)가 됐다. 직전 67장 = 테스터 확정 D69 — state_22_late_cancel_dialog · state_23_cancel_dialog 신규: 시작 20분 전을 지난 취소를 막지 않고 '늦은 취소 · 차감될 수 있음' 한 줄 고지, 20분 전까지는 무문구. 두 상태의 문구 유무 게이트 = `test/golden/cancel_dialog_notice_test.dart`. 직전 65장 = 2026-08-28 테스터 지시 — member_25_gym_info 신규: 체육관 정보 카드 주소·전화를 본문 크기로. 직전 64장 = v3.35 업적 E 안 — member_24_trophy_room(목록 행 탭 → 트로피 룸) ·
state_21_achievements_loading(스켈레톤) 신규, member_12·ach_01 은 분류별 목록으로 재생성.
안정성 게이트 = `test/golden/achievements_stability_test.dart`. 직전 62장 = 2026-08-28 실측 — state_20_inbox_threads 신규: 쪽지함 꽉 찬 상태(코치 쪽지+자동 알림), 홈페이지·스토어 스크린샷 소스. 직전 61장 = 2026-08-27 실측 — D67 로그인 고정 레이아웃으로 3장 증가:
state_17_login_error · state_18_login_validation · state_19_login_busy 신규,
common_08_login·state_09_login_remembered·state_16 재생성. 로그인 상태 절차 정본은
`test/golden/login_states.dart` — 골든과 y 좌표 검사(layout_stability_test.dart)가
같은 절차를 쓴다. 직전 58장 = v3.31 로그인 통합·내 정보 정리로 3장 감소:
common_05_signup(진입 갈림길) · member_16_goals · member_17_faq 삭제. 아래는 그 이전 이력.
구 61장 이력: 2026-08-26 실측 — 8/21 "45장" 서술 이후 v3.4~v3.28 증감 포함.
D57 횟수권 = state_14 내 정보 회원권 카드 신규 · D58 예약 오픈 전 = state_15 신규 ·
D59 코치 세션 만료 = state_16 로그인 화면 자동 이동 신규 (하네스 `routes` 주입구).
prefix 집계(2026-08-28 알림 받기): member 25 · state 25 · common 4 · splash 3 · snack 3 ·
coach 4 · ach 2 · boss 2 · hist 1 · onb 1 (= 70). 2026-08-26 S6 = state_13 가입 폼 BACK 다이얼로그 신규.
2026-08-26 S5·S10 = state_11 '회원권 필요' 배지 ·
state_12 코치 로그아웃 다이얼로그 신규 (boss_03·state_10 은 명단 코치 이름 재생성).
2026-08-26 S3 = state_10 시작 전 명단 잠금 신규 ·
boss_03 fake 를 시작 지난 수업(09:00)으로 이동. v3.28 = coach_02(수업 탭) 삭제 · coach_04(새 쪽지
회원 목록) 신규 — 코치 셸 2탭 (README 대장 20·21). 2026-08-25 폰 코치 축소(v3.21·v3.22)로 6장 삭제 =
boss_04 수업 등록 · boss_05 수업 취소 · boss_06 날짜 선택 · boss_07 수업 수정 ·
boss_09 요금제 탭 · boss_08 설정 예약 탭 (README §제거된 기능 대장 17·18).
같은 날 로그인 창구 통합(v3.19) 증감 = `boss_01_login` 삭제(코치 전용 로그인
화면 폐기) · `common_08_member_login` → `common_08_login` 개명. 신규 3장 = member_22
전자계약 상세(항목 이름 한글화) · boss_09 코치 설정 '요금제' 탭(금액·기간·종류
한글 표기) · state_09 로그인 '아이디 기억하기' 채워진 상태.
2026-08-24 신규 3장 = state_07 종료 수업 카드 · boss_08 코치 설정 '예약'
탭(하루 예약 한도) · state_08 대기 취소 다이얼로그(G30) — 브리프 D41.
장별 상세 목록 정본 = `tool/golden_gallery.py` SECTIONS).
2부 테스트 = `test/golden/screens2_golden_test.dart` (1부의 헬퍼를 import — rxProfile 등).
**진입점이 없는 화면은 골든에서 뺀다** — 페이싱 계산기(v1.27 숨김, git 의 calc_01~04) ·
Benchmarks·Tier 결과(v2.6, git 의 onb_02·onb_03) · 인트로 전체(v3.3 코드 삭제, git 의
common_02~04 — README §제거된 기능 대장 11).
숨김 화면 코드는 v3.2(2026-08-20)에서 삭제됨 — 되살리려면 git log·`_archive/lib-engine/`
에서 복원하고 그 커밋에서 캡처도 같이 되살릴 것 (README §제거된 기능 대장).
기능을 넣으면 그 상태의 캡처도 같이 넣는다 (골든 없는 기능 = 골든스탠다드 미달).
- `--update-goldens` 없이 `flutter test test/golden` 이 회귀 게이트 — 커밋된 PNG 와 1픽셀이라도 다르면 실패
- 명언 랜덤은 `quotes.dart` 의 `quoteRandom` 시드 교체로 결정론 확보. WOD·출석·클래스 날짜는
  실행 시점 상대값 (`fakes.dart` — writeplz generations 패턴)
- 갤러리 등재는 `golden_gallery.py` 가 양방향 검출 (누락 = PNG 없음 / 미등재 = SECTIONS 없음)
- 상태 변형은 `states_golden_test.dart` 분리 (본편 = screens_golden_test.dart)
- Future 를 필드에 보관하고 FutureBuilder 가 늦게 붙는 화면(숨은 탭·중첩 빌더)은
  `core/futures.dart retainError()` 로 감쌀 것 — 미적용 시 에러가 unhandled 로 새어 테스트 즉사
  (2026-07-28 골든에서 발견, history·panel_b 적용 완료)

## 빌드 & 배포 (MVP)
```bash
# 배포용 APK — 백엔드 URL 주입 필수 (누락 시 localhost로 박힘)
flutter build apk --release --dart-define=API_BASE_URL=https://service-facing-production.up.railway.app
# 생성물: build/app/outputs/flutter-apk/app-release.apk
# → 갤럭시에 직접 설치 (USB 디버깅 or 파일 전송)
```
> ⚠ `--dart-define=API_BASE_URL` 없이 `flutter build apk --release` 만 쓰면
> `lib/core/api_client.dart` 의 기본값 `http://10.0.2.2:5060` (에뮬레이터 전용 로컬)로 빌드된다.
> 실기기·배포 APK는 반드시 prod URL 을 주입할 것. (2026-06-09 릴리즈 검증 중 발견)

v2: Play Store Internal Testing → Closed Testing → Production.

## 금지
- NEVER 계산 로직을 앱에 구현 (백엔드 `services/facing/engine/` 책임)
- NEVER API 키/토큰을 Dart 코드에 하드코딩
- NEVER 사용자 Max 데이터를 서버 백업 없이 로컬에만 저장 (MVP는 익명이라 유실 OK, v2부터는 서버 백업 필수)
- NEVER React Native/Ionic/Capacitor 라이브러리 혼용 (Flutter 순수 스택)

## 구현 대차대조 SSOT 포인터 (2026-08-13)
- 3면(DB·API·폰·PC) 실구현 대차대조표·이름사전·갭대장 = `../../services/facing/docs/SSOT/` (`INDEX.md` 부터). 폰 화면이 어느 API·DB 컬럼에 닿는지의 정본.
