# HYPHEN 구글 플레이 스토어 출시 준비 문서

> 작성일 2026-08-27. 조사는 tavily/WebSearch로 2026년 8월 시점 기준 확인. 확인 못 한 항목은 "미확인"으로 표기.
> 앱 기술 현황(서명 키스토어 연결·릴리즈 AAB 빌드 성공·applicationId 확정 등)은 이미 완료된 상태를 전제로 작성했다.

---

## 0. 최우선 블로커 요약

1. **Play Console 개발자 계정이 아직 없다.** 결제(25달러)와 신원 확인(신분증·주소 증빙·사업자 서류)은 Claude가 대신 못 한다 — A 섹션 참고.
2. **계정 유형(개인 vs 사업자) 결정이 전체 일정을 좌우한다.** 사업자 계정을 권장한다 — B 섹션 참고.
3. ~~스크린샷은 별도 제작 중.~~ **완료 (2026-08-28).** `build/store/` 에 폰 스크린샷 7장 + 아이콘 + 피처 그래픽이 모두 들어 있다.
   전부 **1080×1920(1:1.78)** 로 만들어 2:1 상한 안이다 — 갤럭시 S22 실기 해상도(1080×2340, 약 2.17:1)를
   그대로 쓰면 반려되므로 실기 캡처로 바꾸지 말 것. 재생성 = `python tool/gen_store_shots.py`,
   `python tool/gen_store_assets.py` (소스는 골든 PNG·런처 아이콘 기하 — 앱이 바뀌면 골든 갱신 후 다시 실행).

---

## A. 지금 당장 사용자가 해야 할 일 (Claude가 대신 못 하는 것)

전부 구글 계정 로그인·본인 명의 결제·실물 서류 업로드가 필요해 Claude가 대행할 수 없다. 순서대로 진행할 것.

1. **Play Console 계정용 구글 계정 준비.** 개인 구글 계정과 분리된 전용 계정 권장(미확인 — 회사 구글 워크스페이스 계정이 있다면 그쪽 권장).
2. **console.play.google.com 접속 → 개발자 등록 → 25달러 결제.** 1회성, 환불 불가. 선불카드·일부 가상카드는 결제 거부되므로 실물 신용/체크카드 사용.
3. **계정 유형 선택 — 사업자(조직) 계정 권장.** 사업자등록번호 617-22-96247(상호 디알티/D.R.T)로 등록. 판단 근거는 B 섹션.
4. **D-U-N-S 번호 발급 신청.** 사업자 계정에는 D-U-N-S 번호(Dun & Bradstreet 발급, 무료)가 필요하다. 콘솔 내 링크로 신청 가능하며 **최대 영업일 30일** 소요된다는 보고가 있음(미확인 — 실제 소요는 케이스마다 다를 수 있어 최대한 일찍 신청 권장).
5. **개발자 신원 확인 서류 업로드.**
   - 계정 소유자 또는 공식 대리인 신분증(주소 기재·사진 부착 정부 발급)
   - 사업자 등록증(조직 서류)
   - 결제 프로필 정보와 서류 내용이 정확히 일치해야 함
6. **결제 프로필(Payments profile) 등록.** 사업자 정보와 동일하게 입력.
7. **한국 개발자 정보란 입력.** 사업자등록번호·주소·연락처. 통신판매업 신고번호는 앱 내 결제(인앱결제) 여부에 따라 필요 여부가 갈리는데, 이 앱은 인앱결제가 없으므로(D 섹션 근거) 신고 대상이 아닐 가능성이 높다 — **최종 판단은 관할 지자체 통신판매업 신고 시스템 또는 세무사 확인 필요(미확인)**.
8. **앱 등록 후 AAB 업로드.** `build/app/outputs/bundle/release/app-release.aab` (51.1MB, 릴리즈 키 서명 완료) 그대로 사용 가능.
9. **개인정보처리방침·이용약관 URL 입력.** 이미 공개돼 있음 — 아래 URL 그대로 입력.
   - 개인정보처리방침: https://web-facing-admin-production-dca4.up.railway.app/privacy
   - 이용약관: https://web-facing-admin-production-dca4.up.railway.app/terms
10. **스토어 등록정보 에셋 업로드.** 전부 제작 완료 — `build/store/` 폴더 그대로 올리면 된다.
    - 앱 아이콘: `icon_512.png` (512×512, 투명도 없음)
    - 피처 그래픽: `feature_1024x500.png` (1024×500)
    - 폰 스크린샷: `phone_01`~`phone_07` (각 1080×1920). 순서대로 올리면 홈·수업·예약·공지·쪽지·업적·내 정보 흐름이 된다.
11. **데이터 보안 양식·콘텐츠 등급 설문·타겟층 선언 작성.** D 섹션 답안 초안을 그대로 옮겨 입력 가능.
12. **앱 액세스 안내에 심사팀용 테스트 로그인 계정 입력.** 로그인 없이는 아무 화면도 못 보는 앱이라 이 항목을 비우면 반려된다. 시드 계정은 `services/hyphen/models/base.py` 가 환경 무관으로 심는다.
    - 코치용: `admin` / `1234` (역할 boss) 또는 `COACH` / `1234` (역할 coach — 권한 동일)
    - 회원용: `member` / `1234`
    - **운영 서버에서 실제로 되는지는 아직 확인 안 했다.** 운영 DB 접촉을 피하려고 로컬에서만 확인했다 (로컬은 `member`/`1234` 로그인 200 확인 완료). 콘솔에 적기 전에 운영 주소로 한 번 직접 로그인해 볼 것.
13. **(개인 계정을 선택했을 경우만) 클로즈드 테스트 트랙 생성 → 12명 테스터 14일 연속 확보 → 프로덕션 신청.** 사업자 계정이면 이 단계는 생략될 가능성이 높음(B 섹션).
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
| 결론 | 빠르게 시작하고 싶다면 가능하지만 이후 14일+ 테스트 구간이 추가됨 | **권장.** 이미 사업자등록번호를 보유하고 있어 서류 추가 부담이 크지 않고, 테스터 12명 확보라는 불확실 요소를 아예 없앨 수 있음 |

**결론: 사업자 계정으로 등록할 것을 권장한다.** D-U-N-S 번호 신청이 지연 요소이므로 A 섹션 4번을 최대한 빨리 시작할 것.

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

로그인은 네이버 또는 구글 계정으로 진행합니다. 코치·회원 구분은 가입한 체육관 정보에 따라 서버에서 자동으로 판정합니다. 회원 가입은 소속 체육관 코치의 승인 후 이용 가능합니다.
```

(약 750자, 4000자 여유 있음 — 추가 설명이 필요하면 이 위에 덧붙이는 방식 권장)

---

## D. 등록 폼 답변 초안

### D-1. 데이터 보안(Data safety) 양식

앱 실제 수집 항목 근거: `lib/features/mypage/privacy_screen.dart`, `android/app/src/main/AndroidManifest.xml`(권한: INTERNET·POST_NOTIFICATIONS·FOREGROUND_SERVICE·FOREGROUND_SERVICE_DATA_SYNC·WAKE_LOCK·RECEIVE_BOOT_COMPLETED — 카메라·위치·연락처·마이크 권한 없음), `pubspec.yaml`(광고 SDK·분석 SDK 미포함 확인).

| 데이터 카테고리 | 수집 | 공유 | 비고 |
|---|---|---|---|
| 위치 | 아니오 | 아니오 | 권한 자체 없음 |
| 개인 정보 — 이름 | 예 | 조건부 | 가입한 체육관 코치에게 제공(같은 서비스 내부 열람 — 제3자 공유 해당 여부는 법무 검토 권장) |
| 개인 정보 — 전화번호 | 예 | 조건부 | 상동 |
| 개인 정보 — 생년월일·성별 | 예 | 조건부 | 상동 |
| 개인 정보 — 사용자 ID(소셜 로그인 식별값) | 예 | 아니오 | 네이버·구글 로그인 식별값, 인증 목적 |
| 건강/피트니스 | **아니오** | - | 체중·키·1RM·벤치마크 수집 경로는 v2.3에서 이미 폐기됨 — 운동 경력(텍스트)만 남아 있고 이는 "개인 정보 > 기타" 항목으로 분류 권장 |
| 메시지 | 예 | 아니오 | 코치-회원 1:1 쪽지, 앱 기능 목적 |
| 사진 및 동영상 | 예 | 조건부 | 전자계약 서명 이미지 — "사진" 또는 "기타 사용자 콘텐츠" 중 분류 미확정(법무 검토 권장) |
| 앱 활동 | 예 | 아니오 | 수업 예약·출석·포인트·업적 |
| 기기 또는 기타 ID | 예 | 아니오 | 앱이 생성한 익명 기기 식별값(서버에는 알아볼 수 없게 변환해 전송) — 2026년 정책상 기기 ID는 명시 신고 대상 |
| 재정 정보 | **미확정** | - | 회원권 금액(price)이 기록되지만 앱 내 결제(Google Play Billing 등)는 발생하지 않음 — "재무 정보" 신고 필요 여부는 법무 검토 권장 |

- **전송 중 암호화**: 예 (HTTPS)
- **삭제 요청 가능**: 예 (앱 내 "계정 삭제" 버튼 — `/api/v1/member/me` DELETE, 서버·로컬 데이터 영구 삭제)
- **독립 보안 검토**: 아니오(미확인 — 진행 이력 없음)
- **광고 목적 수집**: 아니오 (광고 SDK 미탑재)
- **참고**: `privacy_screen.dart` 코드 주석에 "정식 출시 시 법무 검토 권장"이 이미 박혀 있음 — 데이터 보안 양식 최종 제출 전 이 검토를 마칠 것.

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

## E. 출시 체크리스트

### 블로커 (맨 위)

- [ ] Play Console 개발자 계정 미생성 — 결제 + 신원 확인 필요 (A-2~A-6)
- [ ] 계정 유형 확정 — 사업자 권장, D-U-N-S 번호 신청 필요 (A-4, B)
- [ ] 심사팀 제공용 테스트 로그인 계정이 **운영 서버에서** 되는지 직접 확인 (A-12 — 로컬만 확인함)
- [ ] 통신판매업 신고 필요 여부 최종 확인(인앱결제 없어 불필요 가능성 높음, 미확인)
- [ ] 데이터 보안 양식 중 "재정 정보"·"제3자 공유" 분류 법무 검토 (D-1 참고)

### 완료됨

- [x] 서명 키스토어 연결 (`android/key.properties`, alias=facing)
- [x] 릴리즈 AAB 빌드 성공 (`build/app/outputs/bundle/release/app-release.aab`, 51.1MB)
- [x] applicationId 확정 (`com.netizen.hyphen.hyphen_app`), versionName 1.0.0, versionCode 3006
- [x] compileSdk/targetSdk 36 — 2026-08-31 신규 앱·업데이트 목표 API 요건(Android 16/API 36) 이미 충족, 추가 조치 불필요
- [x] 개인정보처리방침 URL 공개 (`/privacy`)
- [x] 이용약관 URL 공개 (`/terms`)
- [x] 폰 스크린샷 7장 (`build/store/phone_01`~`07`, 각 1080×1920 = 1:1.78 — 2:1 상한 안)
- [x] 앱 아이콘 512×512 (`build/store/icon_512.png`, 32비트 PNG 불투명)
- [x] 피처 그래픽 1024×500 (`build/store/feature_1024x500.png`)
- [x] 공개 약관·방침 본문을 앱 실물과 동기화 (2026-08-27 — 없어진 '데이터 초기화'·'목표'·'카카오톡 상담' 정리)

### 등록 단계

- [ ] 개발자 등록 25달러 결제
- [ ] 결제 프로필 등록
- [ ] 한국 개발자 정보란(사업자등록번호 등) 입력
- [ ] AAB 업로드
- [ ] 스토어 등록정보 카피 입력 (C 섹션 그대로 사용 가능)
- [ ] 데이터 보안 양식 제출 (D-1)
- [ ] 콘텐츠 등급 설문 제출 (D-2)
- [ ] 타겟층·광고 선언 (D-3)
- [ ] 카테고리·태그 선택 (D-4, D-5)
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
