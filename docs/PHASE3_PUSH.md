# Phase 3 — FCM Push 통합 가이드

> **상태**: 미구현 (Firebase 프로젝트 + 설정 파일 부재)
> **작성**: 2026-04-28 /go Phase 3
> **소요 추정**: 1-2일 (Firebase 설정 + 클라이언트 코드 + 백엔드 endpoint)

## 1. Firebase 프로젝트 설정 (사용자 수동)

1. Firebase Console (console.firebase.google.com) 접속
2. 신규 프로젝트 생성: `facing-app-prod`
3. Android 앱 등록:
   - 패키지명: `com.netizenworks.facing` (실제 applicationId 확인 필요)
   - SHA-1 fingerprint 등록 (디버그·릴리즈 별도)
   - `google-services.json` 다운로드 → `android/app/google-services.json`
4. iOS 앱 등록 (Phase 4 시점):
   - Bundle ID 등록
   - `GoogleService-Info.plist` 다운로드 → `ios/Runner/GoogleService-Info.plist`

**시크릿 관리**: `google-services.json` / `GoogleService-Info.plist` 는 git ignore.
배포 시 CI/CD secrets 에서 주입 (Railway env vars 또는 GitHub Actions).

## 2. 의존성 추가 (pubspec.yaml)

```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
```

설치 후 `flutter pub get`.

## 3. Android 설정

### 3-1. `android/build.gradle.kts` (Project 수준)

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}
```

### 3-2. `android/app/build.gradle.kts` (App 수준)

```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

### 3-3. AndroidManifest.xml

POST_NOTIFICATIONS 권한 (Android 13+) 추가:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

## 4. 클라이언트 코드 (placeholder — 본 commit 미작성)

```dart
// lib/core/push_service.dart (신규 파일)
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushService {
  static Future<void> init() async {
    await Firebase.initializeApp();

    final fm = FirebaseMessaging.instance;

    // 1. 권한 요청 (iOS + Android 13+)
    await fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. FCM 토큰 획득
    final token = await fm.getToken();
    if (token != null) {
      // 백엔드에 토큰 등록 (device_id 매핑)
      await _registerTokenWithBackend(token);
    }

    // 3. 토큰 갱신 리스너
    fm.onTokenRefresh.listen(_registerTokenWithBackend);

    // 4. 포그라운드 메시지 핸들러
    FirebaseMessaging.onMessage.listen((msg) {
      // 앱 내 SnackBar 또는 in-app banner
    });

    // 5. 백그라운드/탭 핸들러
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      // 알림 탭 시 적절한 화면으로 라우팅
    });
  }

  static Future<void> _registerTokenWithBackend(String token) async {
    // POST /api/v1/push/register
    // Body: { device_id, fcm_token, platform: 'android' | 'ios' }
  }
}
```

**main.dart 통합**: `await PushService.init();` 를 `main()` 의 `runApp()` 직전 호출.

## 5. 백엔드 요구사항 (services/facing/)

### 5-1. 신규 endpoint

- `POST /api/v1/push/register`: device_id + fcm_token 저장 (DB 컬럼 추가)
- `DELETE /api/v1/push/unregister`: 토큰 무효화 (logout 시)

### 5-2. 알림 발송 트리거

- 코치 노트 발송 시 → 수신자 device_id → fcm_token 조회 → 발송
- 시즌 배지 unlock → 자동 알림
- Streak 끊기기 직전 알림 (rules/gamification.md 화이트햇 패턴 — "Rest Pass 사용?" 형태)

### 5-3. Firebase Admin SDK (Python)

```python
# services/facing/integrations/push.py (신규)
import firebase_admin
from firebase_admin import credentials, messaging

cred = credentials.Certificate("/path/to/serviceAccountKey.json")
firebase_admin.initialize_app(cred)

def send_notification(fcm_token: str, title: str, body: str):
    msg = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        token=fcm_token,
    )
    return messaging.send(msg)
```

`serviceAccountKey.json` 도 시크릿 — Railway env var 주입.

## 6. 알림 카피 가이드 (rules/gamification.md 준수)

**금지 — 손실형 / FOMO**:
- "100일 streak 곧 사라집니다!"
- "오늘 운동 안 하면 모두 잃습니다"

**권장 — 이득형 / 자율형**:
- "Rest Pass 사용하시겠어요? 1회 무료 보호."
- "Engine 측정 90일 경과 — 재측정 시 STALE 해소."
- "박지훈 코치가 노트를 보냈습니다."

## 7. 실행 체크리스트

- [ ] Firebase 프로젝트 생성 + Android 앱 등록
- [ ] `google-services.json` 추가 + .gitignore
- [ ] `pubspec.yaml` firebase_core / firebase_messaging 추가
- [ ] `android/build.gradle.kts` google-services 플러그인
- [ ] AndroidManifest POST_NOTIFICATIONS 권한
- [ ] `lib/core/push_service.dart` 작성
- [ ] `main.dart` 에서 PushService.init() 호출
- [ ] 백엔드 `/api/v1/push/register` endpoint 추가
- [ ] DB 마이그레이션 — device_push_tokens 테이블
- [ ] Firebase Admin SDK + serviceAccountKey 백엔드 연결
- [ ] 코치 노트 발송 트리거 통합
- [ ] 알림 카피 화이트햇 검수 (rules/gamification.md 7원칙)
- [ ] 실 디바이스 테스트 (에뮬레이터는 일부 알림 미수신)

## 8. 이유 (왜 본 /go 에서 미구현)

1. **Firebase 프로젝트 부재**: 사용자 계정 / 결제 정보 / 프로젝트 ID 결정 필요
2. **`google-services.json` 미보유**: 코드만 작성 시 빌드 깨짐 (Firebase init 실패)
3. **백엔드 endpoint 부재**: 토큰 등록 받아주는 서버 측 작업 필요 (별도 repo)
4. **DB 스키마 변경**: device_push_tokens 테이블 추가 마이그레이션 필요

→ 가이드 문서 작성으로 후속 트랙 준비. 사용자가 Firebase 설정 완료 후 본 가이드 따라 구현 시 1-2일 소요 예상.
