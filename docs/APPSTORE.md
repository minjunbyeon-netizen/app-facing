# HYPHEN 애플 앱스토어 출시 준비 문서

> 작성일 2026-08-28. 목표 = **구글·애플 동시 통과 = 출시** (사용자 지시). 구글 쪽 정본은 `docs/PLAYSTORE.md`,
> 이 문서는 애플 쪽만 다룬다. 두 문서가 공유하는 값(버전·URL·심사 계정·스크린샷 카피)은 여기서 다시 적지 않고 그쪽을 가리킨다 (§0-B).
> 출시 명의 = **개인 변민준** (DRT 사업자 정보 사용 금지 — PLAYSTORE.md §0-2).
> 이 저장소는 **공개(public)** 다 — 인증서·API 키·비밀번호를 여기 적지 않는다.

---

## 0. 현재 상태 한 줄

**이 PC(Windows) 에서 할 수 있는 iOS 준비는 전부 끝났다.** 남은 것은 Apple Developer Program 등록(사용자·유료)과
그 뒤 GitHub Secrets 4개 입력 → 워크플로 실행뿐이다. 계정 승인이 나면 당일 TestFlight 까지 갈 수 있게 배선돼 있다.

| 항목 | 상태 | 근거 |
|---|---|---|
| iOS 프로젝트 | **있음** (2026-08-28 신설) | `ios/` — bundle `com.netizen.hyphen.hyphenApp`, 표시명 HYPHEN, iPhone 전용, 세로 고정, 배포 타깃 iOS 13 |
| 컴파일 검증 | GitHub Actions macOS 러너 `ios / compile` (push 마다) | `.github/workflows/ios.yml` — 서명 없이 `flutter build ios` 후 번들 안 운영 URL 주입까지 검사 |
| 앱 아이콘 | **있음** — 전 사이즈 + 1024 마케팅, 알파 없음 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (런처 아이콘과 같은 기하) |
| 스크린샷 | **있음** — 6.9" 1320×2868 · 6.5" 1284×2778 각 7장 | `build/store/ios/{6.9,6.5}/` — `python tool/gen_store_shots_ios.py` 재생성 |
| 알림 | iOS 초기화·권한 요청·전면 배너 배선 완료 | `lib/core/notification_service.dart` · `ios/Podfile` 매크로 · `AppDelegate.swift` delegate |
| 소셜 로그인 | **없음** (사문 플러그인 제거) → Sign in with Apple 의무(4.8) 해당 없음 | 로그인 = 아이디·비밀번호뿐 |
| 계정 삭제 | 앱 안 삭제 버튼 + 공개 페이지 → 5.1.1(v) 충족 | PLAYSTORE.md §0-5 |
| 수출 규정 | `ITSAppUsesNonExemptEncryption = false` → 업로드마다 묻는 암호화 프롬프트 생략 | `ios/Runner/Info.plist` (HTTPS 표준 암호화만 사용) |
| 심사 계정 | 구글과 동일 2개 (`googletest2` 코치 · `googletest1` 회원) | PLAYSTORE.md A-12 (비밀번호 보관 위치 포함) |
| URL 4종 | 구글과 동일 | PLAYSTORE.md §0-9 |
| Apple Developer 계정 | **없음 — 사용자 몫** | §A |

---

## A. 사용자가 해야 할 일 (Claude 가 대신 못 하는 것)

1. **Apple ID 2단계 인증 켜기.** Developer Program 은 2FA 가 켜진 Apple ID 만 받는다.
2. ~~Apple Developer Program 등록 — 개인(Individual).~~ **신청 완료 (2026-08-28, 사용자) — 인증 대기 중.** 승인 메일이 오면 **§G 런시트**.
3. **App Store Connect 접속 → 사용자 및 액세스 → 통합(Integrations) → App Store Connect API → 팀 키 생성.**
   역할 **Admin** (App Manager 는 서명용 인증서 발급 권한이 부족할 수 있음 — 미확인이라 Admin 권장).
   여기서 나오는 세 값 + 팀 ID 를 GitHub Secrets 에 넣는다 (§B). **.p8 파일은 한 번만 내려받을 수 있다** — 잃으면 키를 새로 만든다.
4. **App Store Connect → 나의 앱 → + 신규 앱.**
   - 플랫폼 iOS · 이름 **HYPHEN** · 기본 언어 한국어 · 번들 ID `com.netizen.hyphen.hyphenApp`
     (번들 ID 는 Certificates, Identifiers & Profiles 에 먼저 등록돼 있어야 목록에 뜬다 —
     워크플로의 `-allowProvisioningUpdates` 가 자동 등록해 주지만, 수동으로 먼저 만들어도 된다)
   - SKU `hyphen-ios` (내부 식별용, 자유)
5. **GitHub Secrets 4개 입력 → 워크플로 `ios` 를 dispatch (upload_testflight = true).** §B.
6. **TestFlight 에서 빌드 확인 → 내부 테스터(본인 아이폰)로 설치해 로그인·수업 탭·알림 권한 팝업 확인.**
7. **App Store Connect 등록 정보 채우기.** §C (카피는 PLAYSTORE.md §C 재사용).
8. **App Privacy(앱 개인정보 보호) 답안 입력.** §D.
9. **연령 등급 설문.** §D-3.
10. **심사 정보: 데모 계정 + 연락처 + 메모.** §E.
11. **심사 제출.** 첫 심사는 보통 24~48시간(미확인).

---

## B. 서명·업로드는 GitHub Actions 가 한다 (맥 없이)

이 PC 에는 Xcode 가 없다. 대신 저장소가 public 이라 GitHub 의 macOS 러너를 무료로 쓴다.

### B-1. Secrets 4개 (저장소 → Settings → Secrets and variables → Actions)

| Secret | 값 | 어디서 |
|---|---|---|
| `ASC_KEY_ID` | API 키 ID (10자) | App Store Connect API 키 화면 |
| `ASC_ISSUER_ID` | Issuer ID (UUID) | 같은 화면 상단 |
| `ASC_KEY_P8_BASE64` | `AuthKey_XXXX.p8` 파일을 base64 한 한 줄 | PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_XXXX.p8"))` |
| `APPLE_TEAM_ID` | 팀 ID (10자) | developer.apple.com → Membership details |

### B-2. 실행

Actions 탭 → `ios` → Run workflow → `upload_testflight` 체크 → Run.
순서: 서명 없는 컴파일(게이트) → `xcodebuild archive` 클라우드 서명(인증서·프로파일 자동 발급) →
App Store 용 ipa export → `fastlane pilot` 로 TestFlight 업로드 → ipa 를 아티팩트로도 남김.

### B-3. 처음 실행에서 막힐 수 있는 곳 (미리 아는 함정)

- **"No profiles for 'com.netizen.hyphen.hyphenApp'"** — API 키 역할이 낮아 자동 발급 불가. 키를 Admin 으로 다시 만든다.
- **번들 ID 미등록** — `-allowProvisioningUpdates` 가 등록해 주지만 실패하면 Identifiers 에서 수동 등록 후 재실행.
- **TestFlight 업로드는 됐는데 빌드가 안 보임** — 처리 중(5~30분). 수출 규정 프롬프트는 Info.plist 로 이미 답했다.
- **fastlane pilot 인증 실패** — `.p8` base64 가 줄바꿈 포함으로 깨진 경우. 한 줄인지 확인.
- 이 절차는 **Apple 계정이 없는 2026-08-28 시점에는 실행해 보지 못했다** — 계정 생기면 첫 실행 로그를 보고 고친다.
  `compile` job 은 계정 없이 돌아가며 그것이 지금 검증된 범위다.

---

## C. 등록 정보 (App Store Connect → 앱 → 1.0 준비 중)

| 칸 | 값 |
|---|---|
| 이름 | HYPHEN |
| 부제 (30자) | 코치와 회원을 잇는 체육관 앱 |
| 카테고리 | 기본 건강 및 피트니스 · 보조 스포츠 (구글 카테고리와 대응 — PLAYSTORE.md D-4) |
| 설명 | PLAYSTORE.md §C "자세한 설명" 그대로 (4000자 한도 동일) |
| 키워드 (100자) | 체육관,코치,수업 예약,공지,쪽지,회원권,출석,업적 |
| 지원 URL | https://web-facing-production.up.railway.app/ |
| 마케팅 URL | 같은 주소 |
| 개인정보 처리방침 URL | https://web-facing-admin-production-dca4.up.railway.app/privacy |
| 저작권 | 2026 변민준 |
| 스크린샷 | `build/store/ios/6.9/01~07` (필수 슬롯) · `build/store/ios/6.5/01~07` (구형 기기 슬롯). iPad 슬롯은 iPhone 전용 앱이라 없음 |
| 버전 | pubspec `1.0.0+3009` → CFBundleShortVersionString 1.0.0 · CFBundleVersion 3009 (구글과 같은 번호) |

> 금지 용어(박스·크로스핏·WOD·헬스·다이어트·건강·"쉬운"·"누구나"…)는 애플 카피에도 동일 적용 — 단 **카테고리 이름 "건강 및 피트니스" 는 애플 고정 명칭**이라 예외.

---

## D. App Privacy (앱 개인정보 보호) 답안

근거는 PLAYSTORE.md D-1 (구글 데이터 보안 양식) 과 같은 실측. 애플 분류로 옮긴 것.

| 애플 데이터 유형 | 수집 | 사용자와 연결 | 추적 | 목적 |
|---|---|---|---|---|
| 연락처 정보 — 이름 | 예 | 예 | 아니오 | 앱 기능 |
| 연락처 정보 — 전화번호 | 예 | 예 | 아니오 | 앱 기능 |
| 연락처 정보 — 이메일 | 아니오 | - | - | (앱은 이메일을 받지 않음 — 삭제 요청만 이메일로) |
| 사용자 콘텐츠 — 기타 사용자 콘텐츠 | 예 | 예 | 아니오 | 앱 기능 (쪽지 · 수업 결과 · 전자계약 서명 이미지) |
| 식별자 — 사용자 ID | 예 | 예 | 아니오 | 앱 기능 (로그인 아이디 · 앱이 만든 익명 기기 식별값) |
| 사용 데이터 — 제품 상호작용 | 예 | 예 | 아니오 | 앱 기능 (수업 예약·출석·포인트·업적) |
| 건강 및 피트니스 | **아니오** | - | - | 체중·1RM 수집 경로는 v2.3 폐기 — 운동 경력(텍스트)만 남음 |
| 위치 | 아니오 | - | - | 권한 없음 |
| 재무 정보 | **아니오로 답하되 미확인** | - | - | 회원권 금액이 기록되지만 앱 내 결제 없음 — 구글과 같은 쟁점(PLAYSTORE.md D-1) |
| 진단 | 아니오 | - | - | 크래시 SDK 없음 |

- **추적(Tracking)** = 아니오 전부. 광고 SDK·ATT 없음 → `NSUserTrackingUsageDescription` 불필요.
- **민감 정보** 수집 아니오. **생년월일·성별**은 애플 분류에 별도 항목이 없어 "기타 데이터 유형 — 기타"로 수집 예.
- 답한 내용과 개인정보처리방침 본문이 어긋나면 반려 사유 — 방침 본문은 `web/facing-admin/templates/legal_privacy.html`.

### D-3. 연령 등급
전 항목 "없음" (폭력·성·도박·약물·공포 없음, 무제한 웹 접근 없음, 사용자 생성 콘텐츠 = 쪽지·수업 결과이지만 체육관 안 소속 회원끼리만) → **4+** 예상. 미확인: 애플이 1:1 쪽지를 "사용자 생성 콘텐츠" 로 보고 12+ 를 요구할 수 있음 — 설문 결과대로 따른다.

---

## E. 심사 정보 (App Review Information)

- **로그인 필요** 체크 → 데모 계정: 코치 `googletest2` / 회원 `googletest1` (비밀번호 = PLAYSTORE.md A-12 보관 위치).
- **연락처**: 변민준 · 전화 · `n1665@naver.com`.
- **메모 (심사팀에게)** 예:
  > 이 앱은 체육관 코치와 회원을 잇는 앱입니다. 회원은 앱에서 수업을 예약하고 공지·쪽지를 받습니다.
  > 코치의 운영 화면은 PC 웹(https://web-facing-admin-production-dca4.up.railway.app)이며, 폰 앱의 코치 로그인은
  > 예약 명단과 쪽지함만 보여 줍니다. 두 데모 계정은 같은 체육관(HYPHEN)에 속합니다.
  > 알림은 앱이 켜져 있을 때 서버 이벤트로 표시되는 로컬 알림이며 푸시 서버(APNs)를 쓰지 않습니다.
  > 계정 삭제: 내 정보 → 개인정보처리방침 → 계정 삭제.

### 반려 가능성이 있는 지침과 대응

| 지침 | 내용 | 대응 |
|---|---|---|
| 2.1 앱 완성도 | 크래시·빈 화면·더미 콘텐츠 | 데모 계정이 실데이터 있는 체육관(HYPHEN)에 속함. 공지 0건이면 "등록된 공지 없음" 빈 상태가 정상 |
| 4.2 최소 기능 | 웹 껍데기·단순 정보 앱 | 예약·쪽지·업적 등 네이티브 기능 — 해당 없음 |
| 4.8 Sign in with Apple | 제3자 소셜 로그인 제공 시 애플 로그인 의무 | 소셜 로그인 없음 (플러그인 제거) — 해당 없음 |
| 5.1.1(v) 계정 삭제 | 계정 생성이 있으면 삭제 경로 필수 | 앱 안 삭제 + 공개 페이지 |
| 5.1.1 권한 문구 | 권한 요청 목적 문자열 | 알림 권한은 시스템 문구로 충분. 카메라·사진·위치 권한 없음 → `NS*UsageDescription` 불필요 |
| 3.1.1 인앱결제 | 디지털 상품 결제 | 앱 내 결제 없음. 회원권 결제는 체육관 현장 — 앱에 결제 유도 문구 없음 확인 필요 (미확인: 회원권 금액 표시가 "결제 유도" 로 읽히는지) |
| 2.3 정확한 메타데이터 | 스크린샷·설명이 실물과 일치 | 스크린샷 = 골든 실물 렌더 |

---

## F. 출시 체크리스트

### 블로커
- [ ] Apple Developer Program 인증 대기 (등록 신청은 2026-08-28 완료) — 승인 후 §G 런시트
- [ ] App Store Connect API 키(Admin) 발급 → GitHub Secrets 4개 — 사용자
- [ ] 워크플로 `ios` dispatch → TestFlight 첫 업로드 성공 (첫 실행 함정은 §B-3)
- [ ] 본인 아이폰에서 TestFlight 설치 → 로그인·예약·알림 권한 실물 확인
- [ ] App Privacy·연령 등급·심사 정보 입력 (§D·§E) → 심사 제출

### 완료됨 (2026-08-28)
- [x] iOS 프로젝트 생성·브랜딩·iPhone 전용·세로 고정·iOS 13 타깃
- [x] AppIcon 전 사이즈 (알파 없음) · 스크린샷 6.9"/6.5" 각 7장
- [x] 알림 iOS 배선 (초기화·권한·전면 배너·Podfile 매크로)
- [x] 사문 소셜 로그인 플러그인 제거 → 4.8 해당 없음
- [x] 수출 규정 프롬프트 생략 (`ITSAppUsesNonExemptEncryption=false`)
- [x] GitHub Actions: 서명 없는 컴파일 게이트 + 클라우드 서명 TestFlight 워크플로
- [x] 계정 삭제 경로·URL 4종·심사 계정 — 구글과 공유

### 애플 계정 없이 검증한 범위 / 못 한 범위
- 검증함: macOS 러너에서 `flutter build ios --no-codesign` 성공 여부 (Actions `ios / compile` 결과가 정본 — 실패하면 그 로그부터).
- 못 함: 서명·archive·TestFlight 업로드·실기기 실행·심사 제출. 전부 계정 이후.

## G. 승인 당일 런시트 (2026-08-28 사용자: Apple Developer 등록 신청 완료 · 인증 대기)

> 승인 메일이 오면 이 순서대로. ★ = Claude 가 할 수 있음, ● = 사용자만.

1. ● developer.apple.com → Membership details → **Team ID** 복사.
2. ● App Store Connect → 사용자 및 액세스 → 통합 → **API 키 생성 (Admin)** → Key ID · Issuer ID 복사, `.p8` 내려받기(1회만 가능).
3. ● GitHub `app-hyphen` → Settings → Secrets → `ASC_KEY_ID` · `ASC_ISSUER_ID` · `APPLE_TEAM_ID` · `ASC_KEY_P8_BASE64` 입력 (§B-1).
4. ● App Store Connect → 나의 앱 → **+ 신규 앱** (HYPHEN · iOS · 한국어 · 번들 `com.netizen.hyphen.hyphenApp` · SKU `hyphen-ios`).
   번들 ID 가 목록에 없으면 Identifiers 에서 먼저 등록.
5. ★ Actions → `ios` → Run workflow → `upload_testflight` 체크 → 실행. 실패하면 §B-3 함정표 순서로 Claude 가 고쳐 재실행.
6. ● TestFlight → 내부 테스트 그룹에 본인 추가 → 아이폰 TestFlight 앱으로 설치 → 로그인·수업·알림 팝업 확인.
7. ● 앱 정보·가격(무료)·App Privacy(§D)·연령 등급(§D-3)·심사 정보(§E)·스크린샷(`build/store/ios/6.9`·`6.5`) 입력.
8. ● 빌드 선택 → **심사 제출**. 반려 시 사유를 그대로 붙여 주면 Claude 가 대응.
