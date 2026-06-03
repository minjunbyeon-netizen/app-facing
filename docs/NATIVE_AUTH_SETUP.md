# 소셜 로그인 네이티브 설정 가이드 (D26)

> 코드·SDK 스캐폴딩은 **이미 깔려 있음**. 아래는 **키 발급 후 값만 채우면** 실 로그인이
> 켜지는 체크리스트. 설계 SSOT: `services/facing/docs/AUTH_SOCIAL_DESIGN.md`.

현재 상태: 기본은 `StubSocialAuthService`(가짜 버튼). 아래 1~3 채우고
`--dart-define=USE_REAL_AUTH=true` 로 빌드하면 실 로그인 활성.

> **안드로이드 네이티브 파일(Manifest·strings.xml·MainActivity) 수정 0**. 두 패키지
> (`google_sign_in`·`naver_login_sdk`) 모두 키를 **Dart 빌드 플래그(--dart-define)** 로
> 주입하므로 `android/` 파일을 건드릴 필요가 없어요. (구 `flutter_naver_login` 은 현재
> Flutter 와 호환 안 돼서 유지보수되는 `naver_login_sdk` 로 교체함.)

---

## 0. 이미 되어 있는 것 (건드릴 필요 없음)

- pubspec — `google_sign_in` · `naver_login_sdk`
- 앱 코드 — `RealSocialAuthService` + `resolveSocialAuthService(USE_REAL_AUTH)`
  (구글 = google_sign_in id_token / 네이버 = NaverLoginSDK access_token → 백엔드 검증)
- 백엔드 — `/api/v1/auth/social`·`logout`·`me` 실 동작 (httpx 토큰검증)
- **디버그 APK 빌드 통과 확인** (키 없이도 빌드는 됨 — 런타임 로그인 시점에만 키 필요)

---

## 1. 네이버 (Naver Developers)

1. https://developers.naver.com → 애플리케이션 등록 → "네이버 로그인" 사용
2. Android 플랫폼 추가: **패키지명 = `com.netizen.facing.facing_app`**
3. 발급된 **Client ID / Client Secret** 을 빌드 시 주입 (아래 3번).
   `C:/dev/.env` 의 `NAVER_CLIENT_ID` / `NAVER_CLIENT_SECRET` 는 **이미 존재**(백엔드 검증용,
   동일 앱 키 재사용 가능).

## 2. 구글 (Google Cloud Console)

1. https://console.cloud.google.com → APIs & Services → Credentials
2. **OAuth 2.0 Client ID 2개 생성**:
   - **Android** 타입: 패키지명 `com.netizen.facing.facing_app` + 디버그/릴리즈 **SHA-1** 지문 등록
     (`cd android && ./gradlew signingReport` 로 추출)
   - **Web application** 타입: `id_token` 발급용 **server client id** (3·아래 백엔드에 사용)
3. 백엔드용 `C:/dev/.env` 에 추가 (배포 시 Railway 콘솔에도 동일):
   ```
   GOOGLE_CLIENT_ID=<Web client id>
   GOOGLE_CLIENT_SECRET=<Web client secret>
   ```

## 3. 빌드 시 주입 (앱) — 키는 전부 --dart-define 으로

```bash
flutter run \
  --dart-define=USE_REAL_AUTH=true \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<2번의 Web client id> \
  --dart-define=NAVER_CLIENT_ID=<1번 Client ID> \
  --dart-define=NAVER_CLIENT_SECRET=<1번 Client Secret> \
  --dart-define=NAVER_CLIENT_NAME=FACING \
  --dart-define=API_BASE_URL=http://10.0.2.2:5060
```
- `GOOGLE_SERVER_CLIENT_ID` = 백엔드 `GOOGLE_CLIENT_ID` 와 **같은 Web client id** 여야
  서버 `aud` 검증 통과.
- 빌드 플래그가 많으면 `--dart-define-from-file=env.json` 으로 묶어도 됨.

## 4. 검증 (AUTH_SOCIAL_DESIGN.md §9-7)

1. 백엔드 로컬 기동 (`python app.py`, 5060)
2. 위 명령으로 앱 실행 → 네이버·구글 버튼 → 실제 로그인 창 → 성공
3. 신규 계정이면 `role=solo` 로 온보딩 진입 확인
4. 배포 환경 1건 동일 검증

---

## 주의

- 구글 SHA-1 미등록 시 `ApiException 10` (DEVELOPER_ERROR) — 콘솔 지문 확인.
- 네이버 키·패키지명 불일치 시 로그인 창에서 바로 실패.
- `naver_login_sdk` ProGuard(릴리즈 난독화) 사용 시 keep 규칙 필요 →
  `android/app/proguard-rules.pro`:
  ```
  -keep public class com.nhn.android.naverlogin.** { public protected *; }
  -keep public class com.navercorp.nid.** { public *; }
  ```
- 키 비어 있어도(현재 상태) **빌드는 통과**. 런타임 로그인 시점에만 필요.
