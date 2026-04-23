⚠️ 세션 시작 시 먼저 `docs/HANDOFF.md`를 읽고 현재 작업 상태를 파악할 것.

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

## 디자인 원칙 (글로벌 CLAUDE.md 준수)
- 이모지 금지
- 색상 5토큰 (bg/fg/muted/border/accent)
- 폰트 Pretendard 1종, weight 400/700
- 그라디언트/과도한 그림자 금지
- ROW 우선, 여백 충분히

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
