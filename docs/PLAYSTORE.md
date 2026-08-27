# HYPHEN 구글 플레이 스토어 출시 준비 문서

> 작성일 2026-08-27. 조사는 tavily/WebSearch로 2026년 8월 시점 기준 확인. 확인 못 한 항목은 "미확인"으로 표기.
> 앱 기술 현황(서명 키스토어 연결·릴리즈 AAB 빌드 성공·applicationId 확정 등)은 이미 완료된 상태를 전제로 작성했다.
> **2026-08-28 갱신**: 미사용 `flutter_foreground_task` 플러그인 제거로 F-0·F-1·F-2·F-3 의 포그라운드
> 서비스 반려 위험이 해소됨(권한 6개로 축소) · 릴리즈 빌드 보안 설정 2건(평문 HTTP 차단·백업 차단) 반영 ·
> 버전 `1.0.0+3008` · 운영 서버 로그인 실측(코치 계정 정상, 회원 계정 부재) · 로그인 속도 제한(F-7) 신규 반영.

---

## 0. 최우선 블로커 요약

1. **Play Console 개발자 계정이 아직 없다.** 결제(25달러)와 신원 확인(신분증·주소 증빙·사업자 서류)은 Claude가 대신 못 한다 — A 섹션 참고.
2. ~~계정 유형(개인 vs 사업자) 결정이 전체 일정을 좌우한다.~~ **결정됨 (2026-08-28 사용자 지시) — 개인 계정, 명의 변민준.**
   DRT(디알티) 사업자 정보·주소는 어디에도 쓰지 않는다 (홈페이지 푸터·콘솔 개발자 정보 전부 개인). 그 대신 개인 계정
   의무인 **클로즈드 테스트(테스터 12명 · 14일 연속)** 가 프로덕션 전 필수 단계가 된다 — B 섹션 참고.
3. ~~로그인 속도 제한이 심사 통과를 방해할 수 있다.~~ **해소됨 (2026-08-28, 운영 실증 완료).**
   심사 계정만 상한을 올리는 예외를 넣고 배포했다. 운영 서버에서 심사 계정 연속 10회 로그인 전부 200,
   일반 아이디는 6번째부터 429 로 그대로 막히는 것까지 확인했다 — F-7 참고.
4. ~~심사용 회원 계정 값이 아직 확정 전이다.~~ **해소됨 (2026-08-28).** 코치 `googletest2`·회원
   `googletest1` 두 계정을 운영 서버에 만들고 로그인 200 을 확인했다. 비밀번호는 공개 저장소인
   이 repo 에 적지 않는다 — 보관 위치는 A-12 참고.
5. ~~계정·데이터 삭제 요청용 웹 URL이 없다.~~ **해소됨 (2026-08-28).** 공개 페이지를 새로 만들어 배포했다 —
   **https://web-facing-admin-production-dca4.up.railway.app/delete-account**
   (앱에서 직접 삭제하는 경로 · 앱 없이 요청하는 경로 · 삭제 항목 · 전자계약서 법정 보존 예외 · 처리 기간).
   데이터 보안 양식의 '계정 삭제 요청 URL' 칸에 이 주소를 그대로 넣으면 된다.
6. **사전 출시 보고서 크롤러가 로그인 화면을 못 넘을 수 있다.** Flutter 커스텀 렌더링 UI라 Google 의 자동
   자격증명 주입(표준 Android 위젯/Compose 전용) 대상이 아닐 가능성 — Robo 스크립트 녹화로 우회 필요, F-4 참고.
7. ~~스크린샷은 별도 제작 중.~~ **완료 (2026-08-28).** `build/store/` 에 폰 스크린샷 7장 + 아이콘 + 피처 그래픽이 모두 들어 있다.
   전부 **1080×1920(1:1.78)** 로 만들어 2:1 상한 안이다 — 갤럭시 S22 실기 해상도(1080×2340, 약 2.17:1)를
   그대로 쓰면 반려되므로 실기 캡처로 바꾸지 말 것. 재생성 = `python tool/gen_store_shots.py`,
   `python tool/gen_store_assets.py` (소스는 골든 PNG·런처 아이콘 기하 — 앱이 바뀌면 골든 갱신 후 다시 실행).
8. ~~포그라운드 서비스 타입 `dataSync` 가 부팅 재기동과 충돌.~~ **해소됨 (2026-08-28).** 원인이던
   미사용 `flutter_foreground_task` 플러그인(코드 참조 0건 확인)을 통째로 제거했다 — 매니페스트에서
   `FOREGROUND_SERVICE`·`FOREGROUND_SERVICE_DATA_SYNC`·`RECEIVE_BOOT_COMPLETED` 권한과 서비스·리시버
   선언이 전부 사라졌다(릴리즈 APK 실측 확인, 권한 6개로 축소). 앱을 완전히 종료하면 알림이 오지 않는다는
   제약은 남는다(포그라운드 서비스가 없으므로) — F-0·F-1·F-2·F-3 참고.
9. **스토어 양식에 넣는 URL 4개 — 전부 확정 (2026-08-28).** 구글 플레이·앱스토어 공통.

   | 양식 칸 | URL |
   |---|---|
   | 홈페이지 / 마케팅 URL / 지원(Support) URL | **https://web-facing-production.up.railway.app/** |
   | 개인정보처리방침 URL | https://web-facing-admin-production-dca4.up.railway.app/privacy |
   | 이용약관 URL | https://web-facing-admin-production-dca4.up.railway.app/terms |
   | 계정 삭제 요청 URL (데이터 보안 양식) | https://web-facing-admin-production-dca4.up.railway.app/delete-account |

   홈페이지는 같은 날 HYPHEN 브랜드로 전면 재작성해 배포했다 (`web/facing-web` — 4기둥 기능 소개 ·
   앱 실물 캡처 · 코치 로그인 · APK 다운로드 · 약관/방침/삭제 요청 링크 · 개인 운영자 푸터 "변민준 (개인)").
   커스텀 도메인은 없다 — Railway 기본 도메인이 곧 공식 주소. 지원 이메일 = `n1665@naver.com` (삭제 요청 페이지·홈페이지 푸터와 동일 —
   개인 계정의 지원 이메일은 구글 계정 주소와 달라도 된다).
10. **애플 동시 출시 목표 (2026-08-28 사용자 지시) — iOS 준비는 `docs/APPSTORE.md` 가 정본.** 같은 날
    사문이던 소셜 로그인 플러그인(google_sign_in·naver_login_sdk)을 제거해 버전 **`1.0.0+3009`** 로 올렸다 —
    AAB·APK 를 이 버전으로 다시 만들어 올릴 것 (3008 산출물은 폐기). 이 문서의 3008 표기는 이력.

---

## A. 지금 당장 사용자가 해야 할 일 (Claude가 대신 못 하는 것)

전부 구글 계정 로그인·본인 명의 결제·실물 서류 업로드가 필요해 Claude가 대행할 수 없다. 순서대로 진행할 것.

1. **Play Console 계정용 구글 계정 준비.** 개인 구글 계정과 분리된 전용 계정 권장(미확인 — 회사 구글 워크스페이스 계정이 있다면 그쪽 권장).
2. **console.play.google.com 접속 → 개발자 등록 → 25달러 결제.** 1회성, 환불 불가. 선불카드·일부 가상카드는 결제 거부되므로 실물 신용/체크카드 사용.
3. **계정 유형 선택 — 개인 계정 (2026-08-28 사용자 확정).** 개발자명 = 실명 **변민준**. 사업자등록번호·D-U-N-S 번호 불필요. 신원 확인은 정부 발급 신분증(주소 기재)으로 하며, 콘솔 개발자 정보란의 주소·전화·이메일은 사용자가 콘솔에서 직접 입력한다 (주소 공개 여부는 콘솔 설정으로 선택).
4. ~~D-U-N-S 번호 발급 신청.~~ **불필요** — 개인 계정 확정(A-3)으로 사업자 계정 전용 절차는 건너뛴다.
5. **개발자 신원 확인 서류 업로드.** 개인 계정 = 본인 신분증(주소 기재·사진 부착 정부 발급) 1종.
   결제 프로필의 이름·주소와 신분증 내용이 정확히 일치해야 함. (사업자 등록증은 쓰지 않는다 — A-3)
6. **결제 프로필(Payments profile) 등록.** 변민준 개인 명의·개인 주소로 입력 (DRT 정보 금지).
7. **한국 개발자 정보란 입력.** 개인 계정이므로 사업자등록번호·통신판매업 신고번호 칸은 비운다 (인앱결제 없는 무료 앱 — 개인은 신고 대상 아님으로 본다). 이름 변민준 · 이메일 · 전화 · 주소만 입력. **DRT 사업자 정보는 쓰지 않는다** (2026-08-28 사용자 지시).
8. **앱 등록 후 AAB 업로드.** `build/app/outputs/bundle/release/app-release.aab` (51.1MB, 릴리즈 키 서명 완료) 그대로 사용 가능.
9. **홈페이지·개인정보처리방침·이용약관 URL 입력.** 이미 공개돼 있음 — 아래 URL 그대로 입력 (§0-9 표와 동일).
   - 홈페이지(마케팅·지원 URL): https://web-facing-production.up.railway.app/
   - 개인정보처리방침: https://web-facing-admin-production-dca4.up.railway.app/privacy
   - 이용약관: https://web-facing-admin-production-dca4.up.railway.app/terms
10. **스토어 등록정보 에셋 업로드.** 전부 제작 완료 — `build/store/` 폴더 그대로 올리면 된다.
    - 앱 아이콘: `icon_512.png` (512×512, 투명도 없음)
    - 피처 그래픽: `feature_1024x500.png` (1024×500)
    - 폰 스크린샷: `phone_01`~`phone_07` (각 1080×1920). 순서대로 올리면 홈·수업·예약·공지·쪽지·업적·내 정보 흐름이 된다.
11. **데이터 보안 양식·콘텐츠 등급 설문·타겟층 선언 작성.** D 섹션 답안 초안을 그대로 옮겨 입력 가능.
12. **앱 액세스 안내에 심사팀용 테스트 로그인 계정 입력.** 로그인 없이는 아무 화면도 못 보는 앱이라 이 항목을 비우면 반려된다.

    **심사용 계정 2개를 운영 서버에 만들어 두었다 (2026-08-28, 실제 로그인 200 확인).**

    | 역할 | 아이디 | 비밀번호 | 만든 방법 | 확인 |
    |---|---|---|---|---|
    | 코치 | `googletest2` | Railway 환경변수 `REVIEW_COACH_PASSWORD` | 부팅 시 시드 (`models/base.py`) | 로그인 200, 역할 coach |
    | 회원 | `googletest1` | Railway 환경변수에 없음 — 아래 참조 | 가입 신청 API + 코치 승인 | 로그인 200, 상태 approved, 체육관 HYPHEN |

    > **비밀번호를 이 문서에 적지 않는 이유**: 이 저장소(`app-hyphen`)는 **공개(public)** 다.
    > 자격증명을 커밋하면 그대로 공개된다 (글로벌 §2-A-1 시크릿 커밋 금지).
    > - 코치 비밀번호는 Railway `service-facing` 환경변수 `REVIEW_COACH_PASSWORD` 에서 꺼낸다
    >   (`railway variables` 또는 대시보드).
    > - 회원 비밀번호는 어디에도 저장돼 있지 않다 — 만들 때 세션에서 사용자에게 직접 전달했다.
    >   분실하면 코치 계정으로 로그인해 해당 회원의 비밀번호를 다시 발급하거나,
    >   같은 방식(가입 신청 + 승인)으로 새 계정을 하나 더 만들면 된다.

    - 이 두 아이디는 Railway `REVIEW_LOGIN_IDS` 에 등록돼 있어 **로그인 속도 제한 예외 상한**을 받는다 (F-7).
    - 코치용 데모 계정 `admin` / `1234` 도 운영에서 살아 있고 로그인된다(200, role boss). 다만
      **심사팀에는 `googletest2` 를 주는 것을 권한다** — `admin` 을 속도 제한 예외에 넣으면
      널리 알려진 약한 비밀번호의 무차별 대입 천장까지 같이 올라간다.
    - 아이디 형식 제약: `[A-Za-z0-9._-]` 4~32자 — **한글 아이디는 불가** (그래서 '구글테스트1' 이 아니라 `googletest1`).
    - 콘솔 입력 시 지침 문구 예: "아이디·비밀번호로 로그인하십시오. 코치 계정은 수업·회원 관리
      화면, 회원 계정은 홈·수업·내 정보 3개 탭을 볼 수 있습니다. 두 계정 모두 같은 체육관(HYPHEN)에 속합니다."
13. **클로즈드 테스트 트랙 생성 → 테스터 12명 · 14일 연속 확보 → 프로덕션 신청.** 개인 계정이므로 **필수** (B). 테스터는 실제 안드로이드 기기 + 구글 계정 보유자여야 하고 중간 이탈 시 카운트가 리셋된다 — 체육관 회원·지인으로 12명 이상 여유 있게 모집.
14. **프로덕션 심사 제출.**

---

## B. 개인 계정 vs 사업자 계정 비교

핵심 쟁점은 **12명 테스터 14일 연속 클로즈드 테스트 요건**이다.

| 항목 | 개인(Individual) 계정 | 사업자(Organization) 계정 |
|---|---|---|
| 등록비 | 25달러(1회) | 25달러(1회) — 동일 |
| 추가 서류 | 신분증 + 주소 증빙 | 사업자등록증 + D-U-N-S 번호 + 신분증 |
| 신원 확인 소요 | 상대적으로 빠름 | D-U-N-S 발급까지 최대 영업일 30일 소요 가능(미확인) |
| **12명·14일 클로즈드 테스트** | **2023-11-13 이후 생성 계정은 의무.** 구글 공식 고지에 개인 계정에만 적용된다고 명시됨 | **면제.** 공식 문서에 조직 계정 예외가 명문화돼 있진 않으나, 요건 자체가 "개인 계정" 대상으로 한정 서술돼 있고 다수의 2차 자료(테스트 커뮤니티 블로그 등)가 조직 계정 면제로 일관되게 보도함 |
| 테스터 확보 난이도 | 실제 안드로이드 기기·구글 계정 보유자 12명을 14일 연속 유지해야 함(에뮬레이터·봇·중복 계정 불인정, 중간 이탈 시 카운트 리셋) — 소규모 체육관 앱 특성상 확보가 번거로울 수 있음 | 해당 없음 |
| Play Console에 표시되는 개발자명 | 실명 | 상호명(디알티/D.R.T) |
| 결론 | **채택 (2026-08-28 사용자 확정 — 변민준 개인 명의).** 14일+ 클로즈드 테스트 구간을 일정에 넣는다 | 미채택 — DRT 사업자 정보를 이 앱에 쓰지 않기로 함 |

**결론: 개인 계정(변민준)으로 등록한다 — 사용자 확정 (2026-08-28).** 위 비교표는 결정 근거로 보존. 일정의 지연 요소는 D-U-N-S 가 아니라 **클로즈드 테스트 14일**이므로 계정 생성 직후 테스터 모집을 시작할 것 (A-13).

- 출처: [App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)(공식, 원문 확인 완료 — "personal developer accounts created after November 13, 2023"으로 한정), [Google Play Closed Testing Requirements 2026](https://www.testerscommunity.com/blog/google-play-closed-testing-requirements-2026), [Personal vs Organization Google Play Account](https://ontest.app/blog/personal-vs-organization-google-play-account-12-testers), [Google Play Developer Verification 2026](https://testerbee.com/blog/google-play-developer-verification-2026)

---

## C. 스토어 등록정보 한글 카피

카피 규칙 적용: 금지 용어(박스·크로스핏·WOD·헬스·다이어트·건강·체중관리·웰니스·칼로리 소모·"쉬운"·"편리한"·"누구나"·당신·귀하) 미사용, 이모지 없음, 명사형 간결체. 제품 실체 = 공지사항·쪽지·수업 예약·수업 공개(+업적) 4가지.

### 앱 이름 (30자 이내)

```
HYPHEN - 체육관 코치·회원 소통
```

(20자)

> 런처 라벨(`AndroidManifest android:label`)이 `HYPHEN` 이라 스토어 이름도 같은 표기로 맞췄다.
> 폰 아이콘 밑 이름과 스토어 이름이 다르면 같은 앱인지 알아보기 어렵고, 프로젝트 이름 일원화 원칙(§0-B)에도 어긋난다.
> 한글 '하이픈' 은 아래 자세한 설명 본문에 한 번 넣어 검색에 걸리게 했다.

### 간단한 설명 (80자 이내)

```
체육관 코치와 회원을 연결하는 공지사항·쪽지·수업 예약·수업 공개 앱입니다.
```

(약 42자)

### 자세한 설명 (4000자 이내)

```
HYPHEN(하이픈)은 체육관 코치와 회원을 연결하는 앱입니다.

공지사항
코치가 등록한 공지사항을 회원이 확인합니다. 휴관일 안내, 운영 변경 사항 등 체육관 소식을 앱 안에서 바로 받아봅니다.

쪽지
코치와 회원이 1:1로 쪽지를 주고받습니다. 예약, 회원권 등 앱에서 발생하는 알림도 쪽지함에서 함께 확인합니다.

수업 예약
회원권 종류에 맞춰 수업을 예약합니다. 기간제·횟수권 구분에 따라 예약 가능 여부를 자동으로 판정하고, 예약 오픈 시각과 취소 규정을 화면에 표시합니다.

수업 공개
코치가 그날의 수업 내용을 게시합니다. 회원은 지난 수업 기록을 확인하고, 참여와 기록에 따라 업적을 획득합니다. 획득한 업적과 칭호는 내 정보 화면에 표시됩니다.

이 외에 회원 명단·가입 승인, 회원권 조회, 수업 시간표, 출석 기록, 전자계약서 확인 기능을 제공합니다.

코치는 PC 웹에서도 동일한 정보를 관리합니다. 이 앱은 코치의 이동 중 확인과 회원과의 즉시 소통을 보조하는 역할입니다.

로그인은 아이디와 비밀번호로 합니다 (소셜 로그인 없음). 코치·회원 구분은 가입한 체육관 정보에 따라 서버에서 자동으로 판정합니다. 회원 가입은 소속 체육관 코치의 승인 후 이용 가능합니다.
```

(약 750자, 4000자 여유 있음 — 추가 설명이 필요하면 이 위에 덧붙이는 방식 권장)

---

## D. 등록 폼 답변 초안

### D-1. 데이터 보안(Data safety) 양식

앱 실제 수집 항목 근거: `lib/features/mypage/privacy_screen.dart`, `android/app/src/main/AndroidManifest.xml`(릴리즈 APK 실측 권한 6개(2026-08-28) — `INTERNET`·`POST_NOTIFICATIONS`·`WAKE_LOCK`·`ACCESS_NETWORK_STATE`·`VIBRATE`·`com.netizen.hyphen.hyphen_app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` — 미사용 `flutter_foreground_task` 플러그인 제거로 `FOREGROUND_SERVICE`·`FOREGROUND_SERVICE_DATA_SYNC`·`RECEIVE_BOOT_COMPLETED` 소멸. 카메라·위치·연락처·마이크 권한 없음), `pubspec.yaml`(광고 SDK·분석 SDK 미포함 확인).

| 데이터 카테고리 | 수집 | 공유 | 비고 |
|---|---|---|---|
| 위치 | 아니오 | 아니오 | 권한 자체 없음 |
| 개인 정보 — 이름 | 예 | 조건부 | 가입한 체육관 코치에게 제공(같은 서비스 내부 열람 — 제3자 공유 해당 여부는 법무 검토 권장) |
| 개인 정보 — 전화번호 | 예 | 조건부 | 상동 |
| 개인 정보 — 생년월일·성별 | 예 | 조건부 | 상동 |
| 개인 정보 — 사용자 ID(로그인 아이디) | 예 | 아니오 | 아이디·비밀번호 로그인 식별값, 인증 목적. 소셜 로그인 플러그인(google_sign_in·naver_login_sdk)은 2026-08-28 제거 — 소셜 식별값 수집 없음 |
| 건강/피트니스 | **아니오** | - | 체중·키·1RM·벤치마크 수집 경로는 v2.3에서 이미 폐기됨 — 운동 경력(텍스트)만 남아 있고 이는 "개인 정보 > 기타" 항목으로 분류 권장 |
| 메시지 | 예 | 아니오 | 코치-회원 1:1 쪽지, 앱 기능 목적 |
| 사진 및 동영상 | 예 | 조건부 | 전자계약 서명 이미지 — "사진" 또는 "기타 사용자 콘텐츠" 중 분류 미확정(법무 검토 권장) |
| 앱 활동 | 예 | 아니오 | 수업 예약·출석·포인트·업적 |
| 기기 또는 기타 ID | 예 | 아니오 | 앱이 생성한 익명 기기 식별값(서버에는 알아볼 수 없게 변환해 전송) — 2026년 정책상 기기 ID는 명시 신고 대상 |
| 재정 정보 | **미확정** | - | 회원권 금액(price)이 기록되지만 앱 내 결제(Google Play Billing 등)는 발생하지 않음 — "재무 정보" 신고 필요 여부는 법무 검토 권장 |

- **전송 중 암호화**: 예 (HTTPS) — 2026-08-28 릴리즈 매니페스트에서 `usesCleartextTraffic="true"` 를 제거해 평문 HTTP 자체가 API 28+ 기본값(차단)으로 돌아갔다 (개발 빌드는 `android/app/src/debug/AndroidManifest.xml` 오버라이드로 계속 허용).
- **삭제 요청 가능**: 예 (앱 내 "계정 삭제" 버튼 — `/api/v1/member/me` DELETE, 서버·로컬 데이터 영구 삭제)
- **독립 보안 검토**: 아니오(미확인 — 진행 이력 없음)
- **광고 목적 수집**: 아니오 (광고 SDK 미탑재)
- **참고**: `privacy_screen.dart` 코드 주석에 "정식 출시 시 법무 검토 권장"이 이미 박혀 있음 — 데이터 보안 양식 최종 제출 전 이 검토를 마칠 것.
- **F-6 조사로 갱신**: "재정 정보" 항목의 미확정을 F-6 에서 좁혔다 — Google Data safety 분류상 회원권 금액 기록은
  결제 SDK 연동 여부와 무관하게 "Financial info > Purchase history"로 볼 가능성이 높다(공식 근거는 F-6). 최종
  문구는 여전히 법무 검토 후 확정.

### D-2. 콘텐츠 등급 설문(IARC) 예상 답변

- 폭력·성적 콘텐츠·도박·마약/음주 묘사: 전부 없음
- 사용자 간 소통: 있음(코치-회원 1:1 쪽지 — 불특정 다수 공개 채팅 아님, 같은 체육관 소속으로 한정된 폐쇄형)
- 사용자 위치 공유: 아니오
- 인앱 구매/디지털 상품 판매: 아니오
- 사용자 생성 콘텐츠의 공개 게시: 아니오(수업 공개 게시물은 코치가 작성, 같은 체육관 회원만 열람)
- **예상 등급: 전체 이용가(Everyone / 3세 이상)** — 실제 등급은 설문 제출 후 IARC가 자동 산정하므로 확정치 아님(미확인)

### D-3. 대상 연령층 및 콘텐츠(Target audience) / 광고

- 광고 포함 여부: **포함 안 함**
- 대상 연령층: 만 18세 이상 성인 대상으로 한정할 근거는 없음(체육관 회원 전반) — "13세 이상" 또는 "전체 연령"으로 설정하되 **어린이 대상(Designed for Families) 프로그램에는 포함하지 말 것** (로그인 필수·회원 승인제 앱으로 아동 타겟 앱 정책과 무관)
- 뉴스 앱 여부: 아니오

### D-4. 카테고리 추천

- 1순위: **건강/운동**(Google Play 공식 카테고리명) — 이 명칭 자체에 카피 금지어 "건강"이 포함되나, 이는 사용자가 작성하는 마케팅 카피가 아니라 구글이 고정한 시스템 분류명이라 카피 규칙 적용 대상이 아니라고 판단함. 다만 원치 않으면 아래 대안 사용.
- 대안: **라이프스타일**
- 정확한 카테고리 목록·명칭은 Play Console 등록 화면에서 최종 확인 필요(미확인 — 목록이 주기적으로 개편됨)

### D-5. 태그

Play Console은 검색 노출용 태그를 앱 정보에서 최대 5개까지 고정 목록 중 선택하게 하는데, **정확한 현재 고정 태그 목록은 미확인**(콘솔 내 실시간 확인 필요). 방향성 후보: 수업 예약, 회원 관리, 체육관 운영, 코치 소통, 출석 관리.

---

## F. 콘솔 선언 항목

> 조사 시점 2026-08-28, tavily/WebSearch 로 Android 공식 문서(developer.android.com)와
> Play Console 공식 지원 문서(support.google.com/googleplay) 원문을 직접 확인했다. 조사 당시
> 이 앱의 `android/app/src/main/AndroidManifest.xml` 실측 권한은 `INTERNET`·`POST_NOTIFICATIONS`·
> `FOREGROUND_SERVICE`·`FOREGROUND_SERVICE_DATA_SYNC`·`WAKE_LOCK`·`RECEIVE_BOOT_COMPLETED` 였고,
> `flutter_foreground_task` 의 ForegroundService 가 `android:foregroundServiceType="dataSync"`
> 로 등록돼 있었다.
>
> **같은 날 안에 해소됨**: `flutter_foreground_task` 가 `lib/`·`test/`·`integration_test/`
> 어디서도 호출되지 않는 미사용 의존성(참조 0건)으로 확인돼 통째로 제거됐다. 그 결과
> F-0·F-1·F-2·F-3 이 다루던 `dataSync` 포그라운드 서비스·`RECEIVE_BOOT_COMPLETED` 재기동
> 문제는 원인 자체가 사라져 해소됐다 — 각 항목 맨 위에 해소 표시를 남기고 조사 본문은
> "왜 위험했었는지" 기록으로 접어서 보존한다. 릴리즈 APK 실측 권한은 이제 `INTERNET`·
> `POST_NOTIFICATIONS`·`WAKE_LOCK`·`ACCESS_NETWORK_STATE`·`VIBRATE`·
> `com.netizen.hyphen.hyphen_app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` 6개뿐이다
> (aapt2 dump badging 실측, BOOT_COMPLETED 리시버 잔존 0건 확인). 알림 자체는 남아 있다 —
> `flutter_local_notifications` 로 **앱이 떠 있는 동안** SSE 로 받은 사건을 기기 알림으로
> 띄우며, 앱을 완전히 종료하면 알림이 오지 않는다(포그라운드 서비스가 없으므로).
> 이 섹션은 문서 조사만 담당 — `android/`·`lib/` 코드 변경은 별도 담당자 범위.

### F-0. 가장 위험한 발견 — `dataSync` 타입이 부팅 재기동과 정면충돌한다

**해소됨 (2026-08-28) — 원인 의존성 제거.** 아래에서 지적한 `dataSync` 포그라운드 서비스와
`RECEIVE_BOOT_COMPLETED` 재기동 로직의 원인은 `flutter_foreground_task` 플러그인 자체였다.
`lib/`·`test/`·`integration_test/` 전체를 grep 한 결과 참조 0건인 미사용 의존성으로 확인돼
통째로 제거했고, 매니페스트에서 `FOREGROUND_SERVICE`·`FOREGROUND_SERVICE_DATA_SYNC`·
`RECEIVE_BOOT_COMPLETED` 권한과 `ForegroundService` 서비스·`RebootReceiver` 리시버 선언이
전부 사라졌다(릴리즈 APK 실측 확인). 아래는 해소 전 "왜 위험했는지" 조사 기록 — 보존용.

<details>
<summary>해소 전 조사 기록 (원문 유지)</summary>

앱은 `dataSync` 타입 포그라운드 서비스로 SSE 연결을 유지하고 `RECEIVE_BOOT_COMPLETED`
로 재부팅 후 이 서비스를 되살린다. 그런데 **Android 15(API 35) 이상을 타깃하는 앱은
`BOOT_COMPLETED` 브로드캐스트 리시버에서 `dataSync` 타입 포그라운드 서비스를 시작할 수
없다** — 시도하면 `ForegroundServiceStartNotAllowedException` 이 던져진다. HYPHEN 은
compileSdk/targetSdk **36** 이므로 이 제한을 그대로 맞는다. "재부팅하면 알림 연결이
자동으로 되살아난다"는 설계가 실기기에서 이미 죽어 있을 가능성이 높다 — 스토어 심사
통과 여부와 무관한 **기능 결함**이다.

- 공식(제한 대상 타입 목록 — dataSync 포함): [Behavior changes: Apps targeting Android 15 or higher](https://developer.android.com/about/versions/15/behavior-changes-15) — "BOOT_COMPLETED receivers are not allowed to launch the following types of foreground services: dataSync, camera, mediaPlayback, phoneCall, mediaProjection, microphone"
- 공식(예외 타입 목록 — dataSync 는 여기 없음): [Compatibility framework changes (Android 15)](https://developer.android.com/about/versions/15/reference/compat-framework-changes) — `FGS_BOOT_COMPLETED_RESTRICTIONS`. BOOT_COMPLETED 에서도 여전히 허용되는 타입은 `location`·`connectedDevice`·`remoteMessaging`·`health`·`systemExempted`·`specialUse` 6종뿐.
- 실사례(동일 크래시 재현): [flutter_local_notifications issue #2611](https://github.com/MaikuB/flutter_local_notifications/issues/2611) — 로그 원문 "FGS type dataSync not allowed to start from BOOT_COMPLETED!"

**타입 재검토 권장**: `dataSync` 대신 `remoteMessaging`(`FOREGROUND_SERVICE_REMOTE_MESSAGING`)
로 바꾸면 이 BOOT_COMPLETED 제한을 피하고, 아래 F-2 의 6시간 실행시간 상한도 피한다.
Google 공식 FGS 타입 표에서 `TYPE_REMOTE_MESSAGING` 의 정의는 "다른 기기로 텍스트 통신을
중계 — SMS 에 한정되지 않음"이며, 실무 해설 자료들은 이 타입을 "Signal 같은 실시간
암호화 채팅 앱의 수신 유지" 용도로 설명한다(2차 자료 — Google 원문이 "코치·회원 쪽지
알림처럼 단일 기기에서 실시간 수신을 유지"하는 유스케이스를 예시로 직접 들지는 않으므로
100% 정확한 매치라고 단정하지 않는다). 반대로 `dataSync` 의 공식 유스케이스는 "사용자가
직접 트리거한 백업/복원·업로드/다운로드·가져오기/내보내기"로, "항상 연결을 열어 두고
서버 메시지를 수신 대기"하는 이 앱의 실제 동작과 의미가 어긋난다. **결론(코드 담당자
확인 필요)**: `dataSync` → `remoteMessaging` 전환 검토를 최우선 권장. 전환이 어렵다면
최소한 BOOT_COMPLETED 재기동 로직을 없애거나, 앱이 포그라운드로 올라올 때만 재연결하는
방식으로 바꿔야 한다.

- 공식(타입별 정의 표 — TYPE_DATA_SYNC vs TYPE_REMOTE_MESSAGING): [Understanding foreground service and full-screen intent requirements](https://support.google.com/googleplay/android-developer/answer/13392821?hl=en-GB)
- 2차(remoteMessaging 실사용 예 서술): [Android Foreground Services: Types, Permissions and Limitations](https://softices.com/blogs/android-foreground-services-types-permissions-use-cases-limitations)

</details>

### F-1. 포그라운드 서비스 권한 선언(Foreground service permissions declaration)

**해소됨 (2026-08-28) — 원인 의존성 제거.** 매니페스트에 FGS 권한이 더는 선언돼 있지
않으므로(F-0 참고), 이 콘솔 선언 양식 자체가 뜨지 않을 것으로 판단한다(콘솔에서 최종
확인 권장 — 실물 화면은 앱 등록 후에만 볼 수 있어 미확인). 데모 영상 준비도 불필요해졌다.
아래는 해소 전 조사 기록 — 보존용.

<details>
<summary>해소 전 조사 기록 (원문 유지)</summary>

Android 14+ 를 타깃하는 앱이 매니페스트에 FGS 권한(`FOREGROUND_SERVICE_DATA_SYNC` 등)을
선언하면, Play Console **Policy 및 프로그램 > 앱 콘텐츠 > Foreground service
permissions** 에 1회성 선언 양식이 자동으로 뜬다. 완료하지 않으면 **롤아웃 자체가
막힌다** — 이 단계에서 배포가 며칠씩 막힌 사례들이 실제로 보고돼 있다.

선언 시 타입(현재는 Data sync)마다 다음을 제출해야 한다(공식):
1. 기능 설명 — 이 서비스가 무엇을 하는지
2. 사용자 영향 — 작업이 지연·중단되면 무슨 일이 생기는지
3. **데모 영상 링크**(YouTube 권장, 또는 mp4 등 클라우드 저장소 링크) — 사용자가 실제로
   이 기능을 트리거하는 장면을 보여줘야 한다. 커뮤니티 글 중 "영상 없이 google.com 링크로
   눙쳤다"는 사례도 보이지만 같은 스레드에 반려 사례도 섞여 있어 신뢰할 방법이 아니다 —
   실제 영상을 준비할 것.
4. 리뷰어용 사용 지침(선택)

HYPHEN 기준 준비할 영상: 로그인 후 앱을 백그라운드로 내리거나 화면을 끈 상태에서 코치가
보낸 공지·쪽지가 알림으로 뜨는 장면을 몇십 초 분량으로 화면 녹화. F-0 의 타입 전환
여부가 먼저 결정돼야 어떤 타입으로 선언할지 확정된다.

- 공식: [Understanding foreground service and full-screen intent requirements](https://support.google.com/googleplay/android-developer/answer/13392821?hl=en-GB)
- 공식(선언 누락 시 롤아웃 차단 실사례): [Foreground service declaration cannot be found or edited](https://support.google.com/googleplay/android-developer/thread/457369545/foreground-service-declaration-cannot-be-found-or-edited?hl=en)

</details>

### F-2. Android 15/16 에서 `dataSync` 실행시간 제한 — 24시간 중 6시간

**해소됨 (2026-08-28) — 원인 의존성 제거.** `dataSync` 타입 포그라운드 서비스 자체가
코드에서 사라졌으므로 6시간 실행 제한도 더는 이 앱에 해당하지 않는다. 다만 아래 조사가
지적한 "제품 핵심 가치가 스스로 무너지는" 문제의식은 여전히 유효하다 — 이제는 포그라운드
서비스가 아예 없으므로 **앱을 완전히 종료하면 알림이 전혀 오지 않는다**(F 섹션 상단 헤더
참고). 아래는 해소 전 조사 기록 — 보존용.

<details>
<summary>해소 전 조사 기록 (원문 유지)</summary>

공식 문서: `dataSync` 와 `mediaProcessing` 타입 포그라운드 서비스는 **24시간 중 누적
6시간까지만** 실행 가능하다(두 타입은 별도로 집계). 6시간을 채우면 시스템이
`Service.onTimeout()` 을 호출해 몇 초 안에 스스로 멈춰야 하고, 못 멈추면
`RemoteServiceException` 으로 강제 종료된다. 이후 사용자가 앱을 포그라운드로 가져와야
타이머가 리셋된다 — 그 전에 서비스를 다시 시작하려 하면
`ForegroundServiceStartNotAllowedException`("Time limit already exhausted for
foreground service type dataSync")이 던져진다.

**이 앱에 미치는 영향(추정)**: 알림 수신을 위해 SSE 연결을 하루 종일 유지하는 설계라면,
화면이 꺼진 채로 6시간이 누적되는 시점(하루 중 한 번 이상 있을 가능성이 높다)마다 연결이
강제로 끊기고 — 사용자가 직접 앱을 열기 전까지 코치·회원 쪽지·공지 알림이 조용히
끊긴다. 매니페스트 선언 문제가 아니라 **제품의 핵심 가치(4기둥 중 공지·쪽지의 실시간성)가
실기기에서 매일 스스로 무너지는** 구조적 문제다. `remoteMessaging` 타입은 이 6시간 상한
대상에 **포함되지 않는다**(공식 문서가 명시하는 대상은 dataSync·mediaProcessing 둘뿐) —
F-0 의 타입 전환이 이 문제도 같이 해결한다.

부가로, Android 16(API 36, 이 앱의 targetSdk)부터는 포그라운드 서비스에서 시작한
백그라운드 작업(JobScheduler·WorkManager 포함)도 일반 실행 쿼터를 그대로 적용받는다 —
콘솔 선언 항목은 아니고 엔지니어링 참고 사항.

- 공식: [Foreground service timeouts](https://developer.android.com/develop/background-work/services/fgs/timeout)
- 공식: [Behavior changes: Apps targeting Android 15 or higher](https://developer.android.com/about/versions/15/behavior-changes-15)
- 공식(Android 16 백그라운드 작업 쿼터): [Changes to foreground services](https://developer.android.com/develop/background-work/services/fgs/changes)

</details>

### F-3. `RECEIVE_BOOT_COMPLETED` 자체의 정책 제약

**해소됨 (2026-08-28) — 원인 의존성 제거.** `RECEIVE_BOOT_COMPLETED` 권한 자체가 매니페스트에서
사라졌다(F-0 참고, `RebootReceiver` 포함 잔존 0건 확인). `WAKE_LOCK` 은 여전히 남아 있으나
아래 조사대로 원래도 일반 권한이라 선언 대상이 아니었다. 아래는 해소 전 조사 기록 — 보존용.

<details>
<summary>해소 전 조사 기록 (원문 유지)</summary>

`RECEIVE_BOOT_COMPLETED` 와 `WAKE_LOCK` 은 Android 분류상 "일반(normal)" 권한이다 — Play
Console 의 민감 권한 선언 양식 대상이 아니고, 선언 자체만으로 반려되지 않는다. 다만
F-0 에서 짚었듯 **이 권한으로 무엇을 재기동하느냐가 문제** — dataSync 타입 포그라운드
서비스를 부팅 리시버에서 시작하는 조합 자체가 OS 레벨에서 막혀 있다. 즉 반려 위험은
권한 선언이 아니라 권한을 쓰는 방식(F-0)에서 나온다.

- 2차(normal 권한 분류 정리): [\[Fixed\] Android Permissions For Google Play Approval](https://www.technetexperts.com/android-play-store-permissions) — normal 권한 분류 자체는 Android 공개 문서 일반 지식이며 별도 반려 사례가 보고되지 않음.

</details>

### F-4. 사전 출시 보고서(Pre-launch report)

테스트 트랙(비공개·공개 테스트)에 AAB 를 올릴 때마다 자동 생성된다. Google 실기기 랩에서
앱을 설치·실행해 몇 분간 크롤링하며 크래시·성능·접근성 이슈를 찾는다.

로그인 화면 뒤 콘텐츠까지 보게 하려면 **Test and release > Testing > Pre-launch report >
Settings > Test-account credentials** 에 아이디/비밀번호를 입력한다(공식). "구글로
로그인"을 지원하면 자동 로그인되지만, HYPHEN 은 아이디·비밀번호 로그인(Flutter 커스텀 위젯)이라 이 경로에
안전하게 기대면 안 된다.

**미확인이지만 위험도가 높은 발견**: Google 공식 문서 원문 — "Credentials can only be
automatically inserted into Android apps that use **standard Android widgets**."
같은 크롤러 엔진을 쓰는 Firebase Test Lab Robo 문서는 더 명확히 "Robo test can
automatically sign in to apps built with **standard Android widgets or Compose
applications**"라고 못박는다. HYPHEN 은 Flutter 앱이라 네이티브 Android View 도 Jetpack
Compose 도 아닌 자체 렌더링(Skia) UI 를 쓴다. 이번 조사에서 `lib/` 전체를 grep 한 결과
`autofillHints`·`AutofillGroup` 등 Flutter 의 Android 자동입력 연동 코드가 **한 줄도
없었다** — 즉 로그인 아이디/비밀번호 필드에 크롤러가 자동으로 값을 채워 넣지 못할
가능성이 있다(Google 이 Flutter 앱을 내부적으로 어떻게 처리하는지는 공개 문서에 없어
최종 확정은 못 함 — "미확인"). 이 경우 사전 출시 보고서는 로그인 화면 이후를 전혀 못
보고 끝난다.

**대응책(공식 절차)**: Android Studio > Tools > Firebase > Test Lab > Record Robo
Script 로 로그인 과정(아이디 필드 탭 → 입력 → 비밀번호 필드 탭 → 입력 → 로그인 버튼
탭)을 직접 녹화한 스크립트 파일을 만들어 Pre-launch report Settings 의 "Control how
pre-launch report explores your app"에 업로드한다. Firebase 계정 없이도 만들 수 있다.
Firebase 문서가 "게임처럼 표준 위젯이 아닌 화면"의 공식 대안으로 이 방법을 제시한다.

사전 출시 보고서는 프로덕션 심사의 **필수 통과 관문은 아니다**(개인 계정의 12명·14일
비공개 테스트 요건과는 별개 절차) — 다만 로그인 뒤가 전부인 이 앱 특성상 건너뛰면 품질
확인 기회를 통째로 날리는 셈이라 준비해 둘 것을 권장.

- 공식: [Use a pre-launch report to identify issues](https://support.google.com/googleplay/android-developer/answer/9842757?hl=en)
- 공식(자동 로그인 지원 범위 — 같은 크롤러 계열): [Run a Robo test (Android) | Firebase Test Lab](https://firebase.google.com/docs/test-lab/android/robo-ux-test)
- 공식(Robo 스크립트 녹화 절차): [Run a Robo script (Android) | Firebase Test Lab](https://firebase.google.com/docs/test-lab/android/run-robo-scripts)

### F-5. 앱 액세스 권한(App access / Sign-in details) 선언 — 정확한 입력 항목

위치: Play Console **App content(정책 및 프로그램 > 앱 콘텐츠) > Sign-in details**
(구 명칭 "App access"). 입력 절차(공식):
1. "Start" 클릭
2. "All or some functionality is restricted" 선택 (HYPHEN 은 로그인 없이 아무 화면도
   못 보므로 이쪽)
3. "+ Add new instructions" 클릭 → 아이디·비밀번호 입력 + "Any other instructions"
   자유 텍스트 필드 (OTP·2단계 인증·소셜 로그인 전용·필드 3개 이상 같은 특이사항을 여기
   적는다)
4. 저장

**최대 5세트**까지 입력 지침을 추가할 수 있다 — HYPHEN 은 코치용 1세트 + 회원용 1세트를
따로 등록해 두는 걸 권장한다 (기존 A-12 항목의 두 계정을 "코치 계정" "회원 계정"으로
라벨만 명확히 나눠 넣으면 된다).

입력하는 자격 증명 자체에 대한 요건(공식): 상시 유효(만료 없음)·재사용 가능·리뷰어
위치와 무관하게 작동(지오게이팅이 걸려 있으면 우회되는 "마스터" 계정 제공)·기본 언어가
한국어라도 안내 문구는 영어로 제공.

- 공식: [Prepare your app for review](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en)
- 공식(자격 증명 요건 상세): [Requirements for providing sign in details for review](https://support.google.com/googleplay/android-developer/answer/15748846?hl=en)

### F-6. 그 외 이 앱에 해당 가능한 선언

- **광고 ID(AD_ID) 선언** — HYPHEN 은 광고 SDK 를 포함하지 않는다 (기존 D-1 확인:
  `pubspec.yaml` 에 광고·분석 SDK 없음). Play Console 질문에는 **"아니오, 광고 ID를
  사용하지 않습니다"**로 답하면 된다. 단, 제출 직전 병합된 매니페스트
  (`android/app/build/.../AndroidManifest.xml` 또는 bundletool dump manifest)에
  `com.google.android.gms.permission.AD_ID` 가 다른 라이브러리에 의해 자동 병합돼
  들어와 있지 않은지 한 번 더 확인할 것 — 선언과 실제 매니페스트가 어긋나면 릴리즈가
  막힌다(공식 안내).
- **금융 기능(Financial features) 선언** — 2023-08-31 이후 **금융 기능이 전혀 없는 앱도
  포함해 모든 개발자가 필수로 제출**해야 하는 별개 양식이다(공식 — 매 릴리즈마다 확인).
  HYPHEN 은 대출·은행·투자 등 금융 서비스를 제공하지 않으므로 "The app does not provide
  any financial features"(해당 기능 없음)로 답하면 된다. 기존 D-1 표의 "재정 정보"
  항목(Data safety 소관)과는 별개 질문이니 혼동하지 말 것 — **체크리스트에 누락돼
  있었음, E 섹션에 추가함.**
- **정부 앱 선언** — HYPHEN 은 민간 체육관 SaaS 이며 정부 발행 앱이 아니므로 해당 없음.
  콘솔에 양식이 뜨면 "아니오"로 답한다(양식이 실제로 뜨는지 여부는 미확인 — 콘솔에서
  직접 확인 필요).
- **뉴스 앱 선언** — 해당 없음, 뜨면 "아니오".
- **계정·데이터 삭제 요청용 웹 URL — 해소됨 (2026-08-28).** 공개 페이지를 만들어 배포했다:
  **https://web-facing-admin-production-dca4.up.railway.app/delete-account**
  (소스 `web/facing-admin/templates/legal_delete_account.html`, 라우트 `app.py:/delete-account`).
  데이터 보안 양식의 '계정 삭제 요청 URL' 칸에 이 주소를 그대로 넣는다.
  아래는 왜 필요했는지에 대한 원 조사 기록이다. Google 공식 정책(Account
  Deletion Requirements)은 앱 안에서 계정 생성이 가능한 앱에 대해 (1) 앱 내 계정·데이터
  삭제 경로 **그리고** (2) 앱을 설치하지 않고도 접근 가능한 **웹 URL** 로 삭제를 요청할
  수 있는 경로, 둘 다를 요구한다. 이 웹 URL 은 Data safety 양식에 기입해야 하고 스토어
  등록정보 화면에도 그대로 노출된다. HYPHEN 은 (1)은 있다(`내 정보 → 개인정보처리방침 →
  계정 삭제`, 기존 D-1 근거 있음) — 이번 조사에서 공개된 개인정보처리방침 페이지
  (`/privacy`)를 직접 확인한 결과 **(2) 웹 접근 가능한 삭제 요청 페이지는 없다**
  (카카오톡 상담 채널 언급만 있고 URL 형태의 삭제 요청 창구는 없음). 이 웹 페이지를 새로
  만들어야 콘솔 제출이 가능하다 — `web/facing-admin`(정책 페이지가 있는 쪽) 담당자에게
  넘길 것.
- **Financial info(Data Safety) — 회원권 금액 분류 재확인**: 기존 D-1 표의 "재정 정보
  미확정" 항목은 이번 조사로 방향이 잡힌다. Google 의 Data safety 데이터 유형 분류상
  "Financial info"에는 결제수단 정보뿐 아니라 **Purchase history(구매·거래 내역)**도
  포함된다(공식). 회원권 금액이 기록·조회된다면 결제 SDK 연동 여부와 무관하게 "Purchase
  history 수집함"으로 답하는 쪽이 안전하다 — 다만 최종 문구는 기존 안내대로 법무 검토
  후 확정.

- 공식(AD_ID): [Advertising ID - Play Console Help](https://support.google.com/googleplay/android-developer/answer/6048248?hl=en)
- 공식(Financial features 전원 필수 제출): [Provide information for the Financial features declaration](https://support.google.com/googleplay/android-developer/answer/13849271?hl=en)
- 공식(계정·데이터 삭제 웹 URL 요건): [Understanding Google Play's app account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)
- 공식(Data safety Financial info 정의): [Provide information for Google Play's Data safety section](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
- 2차(계정 삭제 요건 요약): [Delete Account URL in Google Data Safety Form](https://www.termsfeed.com/blog/google-data-safety-form-delete-account-url)

### F-7. 로그인 속도 제한 — **해소됨 (2026-08-28, 운영 실증 완료)**

`POST /api/v1/auth/login` 백엔드에 **IP 당 20회/5분 + 아이디 당 5회/5분** 제한이 걸려
있다(별도 담당자가 지금 백엔드를 고치는 중 — 이 문서는 사실만 기록). 아이디 기준 제한은
접속 위치와 무관하게 합산되므로, Google 심사가 여러 실기기·여러 IP 에서 **같은** 심사
계정으로 동시 또는 짧은 간격으로 로그인을 시도하면 대부분이 429 로 막힐 수 있다.

이 위험이 특히 F-4(사전 출시 보고서)·F-5(앱 액세스 Sign-in details) 두 절차와 맞물린다 —
F-5 의 공식 요건은 "상시 유효·재사용 가능·리뷰어 위치와 무관하게 작동" 하는 자격 증명을
요구하는데, 여러 실기기 랩에서 동시에 같은 계정을 쓰는 Google 심사 관행과 아이디 단위
5회/5분 제한이 정면으로 부딪힌다. 로그인이 막힌 상태로 화면이 뜨지 않으면 심사자가
"로그인이 안 되는 앱"으로 판단해 반려할 위험이 있다.

**조치 (집행 완료)**: env `REVIEW_LOGIN_IDS` (쉼표 구분)에 적힌 아이디만 상한을 올린다 —
IP 300회/5분 · 아이디 120회/5분. **면제가 아니라 상향**이라 무차별 대입 천장은 남는다.
env 가 비면 아무에게도 적용되지 않으므로, 설정하지 않은 환경의 동작은 변경 전과 완전히 같다.

- 코드: `services/hyphen/api/auth_login.py` — 일반 상한과 심사 상한을 `exempt_when` 으로
  서로 반대로 걸어 두 벌이 겹치지 않게 했다.
- 회귀 테스트: `services/hyphen/tests/test_login_rate_limit_review.py` 6건
  (env 없을 때 기본 동작 · 심사 계정 통과 · 대소문자 무시 · **다른 아이디는 여전히 차단** ·
  틀린 비밀번호로도 상한 해제). `pytest tests/` 297 passed.
- 운영 서버 실증 (2026-08-28, 배포 후 직접 호출):
  - `googletest1` 연속 10회 로그인 → **전부 200** (고치기 전이라면 6번째부터 429)
  - 목록에 없는 아이디 연속 8회 → `401 401 401 401 401 429 429 429` — **일반 계정 보호는 그대로**
- Railway `service-facing` 환경변수에 `REVIEW_LOGIN_IDS=googletest1,googletest2` 등록 완료.

---

## E. 출시 체크리스트

### 블로커 (맨 위)

- [ ] Play Console 개발자 계정 미생성 — 결제 + 신원 확인 필요 (A-2~A-6)
- [ ] 클로즈드 테스트 — 개인 계정 의무: 테스터 12명이 14일 연속 참여 후 프로덕션 신청 가능 (B). 테스터 모집은 사용자 몫
- [ ] 데이터 보안 양식 중 "재정 정보"·"제3자 공유" 분류 법무 검토 (D-1 참고)
- [ ] 사전 출시 보고서용 Robo 스크립트 녹화 — 로그인 통과용 (F-4 — Flutter 커스텀 UI 라 자동 자격증명 주입이 안 될 가능성)

### 완료됨

- [x] 서명 키스토어 연결 (`android/key.properties`, alias=facing)
- [x] 릴리즈 AAB 빌드 성공 (`build/app/outputs/bundle/release/app-release.aab`, 51.1MB)
- [x] applicationId 확정 (`com.netizen.hyphen.hyphen_app`), versionName 1.0.0, versionCode **3008**(2026-08-28 — 3006→3007 보안 설정 2건→3008 미사용 플러그인 제거)
- [x] compileSdk/targetSdk 36 — 2026-08-31 신규 앱·업데이트 목표 API 요건(Android 16/API 36) 이미 충족, 추가 조치 불필요
- [x] 홈페이지 URL 확정·HYPHEN 재작성 배포 — https://web-facing-production.up.railway.app/ (2026-08-28, §0-9)
- [x] 계정 유형 확정 — 개인(변민준). DRT 사업자 정보 전면 배제, 통신판매업 신고번호 칸 비움 (2026-08-28, §0-2·A-3·A-7)
- [x] 개인정보처리방침 URL 공개 (`/privacy`)
- [x] 이용약관 URL 공개 (`/terms`)
- [x] 폰 스크린샷 7장 (`build/store/phone_01`~`07`, 각 1080×1920 = 1:1.78 — 2:1 상한 안)
- [x] 앱 아이콘 512×512 (`build/store/icon_512.png`, 32비트 PNG 불투명)
- [x] 피처 그래픽 1024×500 (`build/store/feature_1024x500.png`)
- [x] 공개 약관·방침 본문을 앱 실물과 동기화 (2026-08-27 — 없어진 '데이터 초기화'·'목표'·'카카오톡 상담' 정리)
- [x] 미사용 `flutter_foreground_task` 플러그인 제거 — `dataSync`·`RECEIVE_BOOT_COMPLETED` 반려 위험 해소, 릴리즈 권한 6개로 축소 (2026-08-28, F-0~F-3)
- [x] 릴리즈 빌드 보안 설정 2건 — 평문 HTTP(`usesCleartextTraffic`) 차단, `android:allowBackup="false"` 추가 (2026-08-28)
- [x] 코치용 테스트 계정 운영 서버 로그인 확인 — `admin`/`1234` 200, role boss (2026-08-28, A-12)
- [x] 심사용 계정 2개 운영 서버 생성·로그인 확인 — 코치 `googletest2`(시드), 회원 `googletest1`(가입 신청 + 코치 승인). 둘 다 200 (A-12)
- [x] 로그인 속도 제한 심사 계정 예외 배포·운영 실증 — 심사 계정 10회 연속 200, 일반 아이디는 6번째부터 429 (F-7)
- [x] 계정·데이터 삭제 요청 공개 페이지 배포 — `/delete-account` (F-6). 데이터 보안 양식에 그대로 입력

### 등록 단계

- [ ] 개발자 등록 25달러 결제
- [ ] 결제 프로필 등록
- [ ] 한국 개발자 정보란 입력 — 개인: 이름 변민준·이메일·전화·주소 (사업자·통신판매업 칸 비움, A-7)
- [ ] AAB 업로드
- [ ] 스토어 등록정보 카피 입력 (C 섹션 그대로 사용 가능)
- [ ] 데이터 보안 양식 제출 (D-1)
- [ ] 콘텐츠 등급 설문 제출 (D-2)
- [ ] 타겟층·광고 선언 (D-3)
- [ ] 카테고리·태그 선택 (D-4, D-5)
- [x] ~~포그라운드 서비스 권한 선언 제출~~ **해소됨 (2026-08-28)** — 매니페스트에 FGS 권한이 없어 이 선언 양식 자체가 뜨지 않을 것으로 판단(콘솔에서 최종 확인 권장, F-1)
- [ ] 사전 출시 보고서 테스트 계정 자격증명 입력 (F-4)
- [ ] 앱 액세스(Sign-in details) 코치용·회원용 지침 각 1세트 등록 — 회원용은 A-12 값 확정 후 (F-5)
- [ ] 광고 ID(AD_ID) 선언 — "사용 안 함" (F-6, 제출 전 병합 매니페스트 재확인)
- [ ] 금융 기능(Financial features) 선언 — "해당 기능 없음" (F-6, 모든 앱 필수 제출)
- [ ] (개인 계정 선택 시만) 클로즈드 테스트 12명·14일 진행
- [ ] 프로덕션 심사 제출

---

## 출처 목록

- [App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en) — 공식, 원문 인용 확인
- [Google Play 개발자 인증: 국가 및 지역별 필수 서류 - 대한민국](https://support.google.com/googleplay/android-developer/answer/15633622?hl=ko&co=GENIE.CountryCode%3DKR) — 공식, 원문 인용 확인
- [Meet Google Play's target API level requirement](https://developer.android.com/google/play/requirements/target-sdk) — 공식(2차 요약으로 확인, 직접 인용은 미완료)
- [Provide information for Google Play's Data safety section](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en) — 공식(2차 요약)
- [Content rating requirements for apps, games, and the ads served on both](https://support.google.com/googleplay/android-developer/answer/9859655?hl=en) — 공식(2차 요약)
- [Google Play Closed Testing Requirements 2026](https://www.testerscommunity.com/blog/google-play-closed-testing-requirements-2026) — 2차
- [Personal vs Organization Google Play Account](https://ontest.app/blog/personal-vs-organization-google-play-account-12-testers) — 2차
- [Google Play Developer Verification 2026](https://testerbee.com/blog/google-play-developer-verification-2026) — 2차 (D-U-N-S 소요 기간)
- [Google Play Screenshot Size: 1080×1920, 2:1 Rules](https://screenkit.tools/specs/google-play-screenshot-sizes) — 2차 (2:1 비율 제한)
- [Google Play Feature Graphic Size 2026: 1024x500](https://screenkit.tools/specs/google-play-feature-graphic-size) — 2차

### F 섹션 추가 출처 (2026-08-28 조사)

- [Understanding foreground service and full-screen intent requirements](https://support.google.com/googleplay/android-developer/answer/13392821?hl=en-GB) — 공식, FGS 타입 정의 표·선언 절차 원문 확인
- [Behavior changes: Apps targeting Android 15 or higher](https://developer.android.com/about/versions/15/behavior-changes-15) — 공식, dataSync 6시간 제한·BOOT_COMPLETED 제한 대상 타입 목록 원문 확인
- [Compatibility framework changes (Android 15)](https://developer.android.com/about/versions/15/reference/compat-framework-changes) — 공식, `FGS_BOOT_COMPLETED_RESTRICTIONS` 예외 타입 목록(dataSync 미포함) 원문 확인
- [Changes to foreground service types for Android 15](https://developer.android.com/about/versions/15/changes/foreground-service-types) — 공식
- [Foreground service timeouts](https://developer.android.com/develop/background-work/services/fgs/timeout) — 공식
- [Changes to foreground services](https://developer.android.com/develop/background-work/services/fgs/changes) — 공식, Android 16 백그라운드 작업 쿼터
- [Foreground service types | Background work](https://developer.android.com/develop/background-work/services/fgs/service-types) — 공식
- [Restrictions on starting a foreground service from the background](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start) — 공식
- [flutter_local_notifications issue #2611](https://github.com/MaikuB/flutter_local_notifications/issues/2611) — 실사례, dataSync+BOOT_COMPLETED 크래시 로그 원문
- [Android Foreground Services: Types, Permissions and Limitations](https://softices.com/blogs/android-foreground-services-types-permissions-use-cases-limitations) — 2차, remoteMessaging 실사용 예 서술
- [Foreground service declaration cannot be found or edited](https://support.google.com/googleplay/android-developer/thread/457369545/foreground-service-declaration-cannot-be-found-or-edited?hl=en) — 공식(포럼), 선언 누락 시 롤아웃 차단 사례
- [Use a pre-launch report to identify issues](https://support.google.com/googleplay/android-developer/answer/9842757?hl=en) — 공식, 테스트 계정 자격증명 입력 절차 원문 확인
- [Run a Robo test (Android) | Firebase Test Lab](https://firebase.google.com/docs/test-lab/android/robo-ux-test) — 공식, 자동 로그인 지원 범위(표준 위젯·Compose 한정) 원문 확인
- [Run a Robo script (Android) | Firebase Test Lab](https://firebase.google.com/docs/test-lab/android/run-robo-scripts) — 공식, Robo 스크립트 녹화 절차
- [Prepare your app for review](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en) — 공식, Sign-in details 입력 절차 원문 확인
- [Requirements for providing sign in details for review](https://support.google.com/googleplay/android-developer/answer/15748846?hl=en) — 공식, 자격 증명 요건 원문 확인
- [Advertising ID - Play Console Help](https://support.google.com/googleplay/android-developer/answer/6048248?hl=en) — 공식
- [Provide information for the Financial features declaration](https://support.google.com/googleplay/android-developer/answer/13849271?hl=en) — 공식, 전원 필수 제출 원문 확인
- [Understanding Google Play's app account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en) — 공식, 앱 내+웹 URL 이중 요건 원문 확인
- [Delete Account URL in Google Data Safety Form](https://www.termsfeed.com/blog/google-data-safety-form-delete-account-url) — 2차
- HYPHEN `/privacy` 페이지 직접 확인(WebFetch, 2026-08-28) — 웹 접근 가능한 계정 삭제 요청 URL 부재 확인
