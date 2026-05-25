# HANDOFF - 2026-05-25 19:28

> 어제 21:38 → 오늘 14:49 v1.16.2 마무리 → 15:48 1차 핸드오프 → 이번 세션 16:00~19:28 v1.17 "로컬 푸시 알림" 인프라 구축.
> Firebase 없이 자체 SSE + flutter_local_notifications + flutter_foreground_task 패키지로 사장·코치 폰 알림 받게 함. 실 시연만 남음.

## 완료 (16:00 → 19:28, 약 3시간 30분)

### 핵심 — v1.17 로컬 푸시 알림 (Firebase 없이 자체 인프라)

- [x] **백엔드 `services/facing/api/admin.py` 신설 endpoint** — `GET /api/v1/staff/me/events` (device_hash 인증, 사장·코치 운영하는 모든 박스 채널 multi-fanout 구독). Commit `74bbd99`.
- [x] **Flutter 패키지 3개 추가** — `flutter_local_notifications: ^17.2.3`, `flutter_foreground_task: ^8.10.2`, `permission_handler: ^11.3.1`
- [x] **AndroidManifest 권한 5개** — `POST_NOTIFICATIONS`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED` + `flutter_foreground_task` Service 컴포넌트 선언
- [x] **`android/app/build.gradle.kts`** — `isCoreLibraryDesugaringEnabled = true` + `desugar_jdk_libs:2.1.4` (flutter_local_notifications 요구사항)
- [x] **`lib/core/notification_service.dart` 신설** — OS 알림 채널 2개 (`facing_staff` importance=HIGH, `facing_member` importance=DEFAULT), SSE 이벤트별 알림 매핑 7종 (member_join_request·member.created·membership.issued·announcement.posted·wod.posted·attendance_checked silent)
- [x] **`lib/core/staff_push_service.dart` 신설** — BossAuthState 변화 listen → 자동 start/stop, dio SSE 클라이언트, 1·2·4·8·16·32·64s 지수 백오프 재연결, NotificationService 자동 호출
- [x] **`lib/main.dart` 통합** — 부팅 시 NotificationService.init() + BossAuth listener 등록
- [x] **`lib/features/splash/splash_screen.dart`** — 첫 진입 시 알림 권한 1회 요청 (Android 13+ 다이얼로그, 그 이하 자동 grant)
- [x] **APK release 빌드 + 폰(192.168.1.101) install** — `v0.1.17+3000`, 60.3MB, 로컬 백엔드 `192.168.1.100:5060` 가리킴
- [x] **알림 채널 OS 등록 검증** — `dumpsys notification | grep facing` 결과 두 채널 다 정상 등록, POST_NOTIFICATION = allow

## 진행 중

(없음 — 모든 코드·빌드·설치 끝)

## 대기 (다음 세션)

### 우선순위 높음 — v1.17 시연 마무리
- [ ] **사장 로그인 진입로 분리** — SignupScreen 에 "사장으로 로그인" 버튼이 없어요. 박지훈 데모 카드는 AuthState 진입이라 BossAuthState 가 안 켜져서 staff SSE 호출 0회. SignupScreen 또는 RoleEntryScreen 에 BossLoginScreen 진입 분기 추가 필요. **1~2시간 작업**.
- [ ] **device_hash 페어링 흐름** — staff SSE 가 403 NO_GYM 안 띄우려면 폰 device_hash 가 `gym_managers.device_hash` 컬럼에 등록돼야 함. boss login 성공 시 자동 등록 또는 페어링 코드 흐름. 현재 DB 에는 coach_phase4 만 페어링 완료, 나머지 사장·코치 다 NULL.
- [ ] **알림 실 시연** — 위 2단계 끝나면 가짜 가입 신청 1건 트리거(`POST /api/v1/gyms/2/join`) → 폰 알림바 "[FACING] 새 가입 신청" 떠야 정상. logcat `[STAFF_SSE]` 태그 + 백엔드 access log `GET /api/v1/staff/me/events 200` 확인.

### 우선순위 중간 — Foreground Service v1.18
- [ ] **flutter_foreground_task TaskHandler 통합** — 현재 SSE 는 앱 포그라운드/백그라운드 한정. 앱 종료 후에도 알림 받으려면 isolate 기반 Foreground Service 필요. AndroidManifest 컴포넌트는 이미 선언, 코드만 추가하면 됨. `flutter_foreground_task` 의 `FlutterForegroundTask.init()` + `startService()` + TaskHandler 별도 dart entry point. 추가 2~4시간.

### 우선순위 낮음 — 누적 대기
- [ ] **백엔드 admin override 시드 endpoint** (이전 세션 인계) — gym profile PATCH·WOD POST device-hash 인증이라 admin JWT 로 호출 불가. seed_demo.py 자동화 위해 별도 endpoint 필요.
- [ ] **코치 프로필 시드 (gym_coach_profiles)** — coach_user_id 가 admin API 에 노출 안 됨. admin override 와 같이 처리.
- [ ] **services/facing untracked 3건 정리** — `.err.log`, `.run.log`, `data/contracts/contract_*.html` 를 `.gitignore` 추가.
- [ ] **PHASE5 §1.3 사장 폰 회원 list+상세 6탭** (1주 plan)
- [ ] **PHASE4 P0 잔여** — Toss 빌링키 자동결제·재시도·grace.

## 결정사항 / 주의

### Firebase 안 쓰는 이유 (사용자 결정)
- 사용자: "구글 안 끼고 우리 자산으로 진행" — FCM 검토 안 함
- 대안 결정: **자체 SSE + flutter_local_notifications + Foreground Service** 조합. 무료, 외부 의존 0
- iOS 는 보류 — Apple 이 백그라운드 SSE 안 허용. APNs 도 Apple Developer $99/년 필요. v2 작업

### 실 시연 막힌 이유 (정확한 진단)
- 폰 logcat: `[SSE] error: 403 → reconnect in 32s` (member SSE 만 시도, 403 NO_GYM)
- 백엔드 access log: `/api/v1/staff/me/events` 호출 **0회**
- 즉 `StaffPushService.start()` 가 실행 안 됨 → `bossAuth.isLoggedIn` 이 false 상태
- 폰 화면의 "DEMO · 코치 김 · A Box owner" 는 `ProfileState.appMode = Coach` UI 토글일 뿐, 백엔드 `BossAuthState` 가 아님
- **해결**: SignupScreen 에 "사장으로 로그인" 진입로 추가 + `BossAuthState.login()` 호출 → `isLoggedIn=true` → main.dart listener 가 `staffPush.start()` 호출 → staff SSE 시작

### 검증된 인프라
- `dumpsys notification | grep facing` → facing_staff (importance=4 HIGH) + facing_member (importance=3 DEFAULT) 둘 다 OS 에 등록 확인
- 알림 권한 `appops POST_NOTIFICATION` → "allow" 기본
- `curl POST /api/v1/staff/me/events` 페어링 없는 device 로 → 403 NO_GYM 정상 반환 (엔드포인트 살아있음)
- `curl POST /api/v1/gyms/2/join` 가짜 device → row id=62 pending insert + sse_publish 발행 확인

### 폰 환경
- 무선 디버깅: `192.168.1.101:5555` (tcpip 5555 모드, 폰 재부팅 전까지 유지)
- 폰 슬립 모드 들어가면 5555 포트 reject — 다음 연결 시 단계 d (사용자에게 새 IP:포트 요청)
- 폰 install 된 APK: `v0.1.17+3000` (60.3MB, LAN IP `192.168.1.100:5060` 가리킴) — prod URL APK 가 아니니까 prod 환경 시연 불가

### Git 상태
- `services/facing` master: `74bbd99 feat(api): v1.17 — staff SSE endpoint` (push 안 함, "배포 금지" 룰)
- `apps/facing-app` master: auto-save hook 으로 모든 변경 commit 완료. 최신 `3f9cafd chore: auto-save 17:23`. push 안 함
- 둘 다 ahead, 사용자 명시 "배포해" 명령 시 push

## 이번 세션 commit 목록

| 시각 | repo | commit | 내용 |
|---|---|---|---|
| 17:09 | apps/facing-app | (auto-save) | notification_service.dart 신설 |
| 17:23 | apps/facing-app | (auto-save) | pubspec version 0.1.17+3000 |
| 17:23 | apps/facing-app | (auto-save) | build.gradle.kts desugaring + staff_push_service |
| 19:28 | services/facing | `74bbd99` | feat(api): v1.17 staff SSE endpoint |

## 외부 자료 / URL

- 백엔드 staff SSE: `services/facing/api/admin.py:954` (`staff_events_stream` 함수)
- Flutter 알림 코어: `apps/facing-app/lib/core/notification_service.dart`
- Flutter staff SSE 클라: `apps/facing-app/lib/core/staff_push_service.dart`
- Boss 로그인 화면 (작성 필요): `apps/facing-app/lib/features/boss/boss_login_screen.dart` (이미 존재, 라우트 `/boss/login`)
- 사인업 화면 (진입로 추가 대상): `apps/facing-app/lib/features/auth/signup_screen.dart`

## 다음 세션 권장 첫 프롬프트

`/resume`

그 후 우선순위:
- (a) **SignupScreen 에 사장 로그인 진입로 추가** + BossAuthState 통합 — staff SSE 시작 트리거 (1~2h)
- (b) **device_hash 페어링** — boss login 성공 시 자동 등록 또는 페어링 코드 흐름 (1h)
- (c) **알림 실 시연** — 가짜 가입 신청 트리거 → 폰 알림바 캡쳐 (15분)
- (d) **Foreground Service v1.18** — 앱 종료 후에도 알림 (2~4h)
