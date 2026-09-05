# HYPHEN 스토어 제출 입력 시트 — 콘솔 화면 순서대로 붙여넣기

> 작성 2026-09-03. **입력 값의 정본은 이 시트다.** 근거·조사·이력은 `PLAYSTORE.md`(구글) ·
> `APPSTORE.md`(애플)에 있고, 두 문서의 값이 이 시트와 어긋나면 이 시트를 따르고 그쪽을 고친다.
> 제출 직전 `python tool/store_preflight.py` 가 **전부 PASS** 인지 본다 — 이 시트가 약속한 사실
> (URL 200 · 심사 계정 로그인 · 에셋 규격 · AAB 신선도 · 권한 · iOS 설정)을 실측하는 게이트다.
> 비밀번호는 공개 저장소라 여기 적지 않는다 — `services/hyphen` 폴더에서 `railway variables` 로 꺼낸다.

---

## 0. 두 스토어 공통 값

| 칸 | 값 |
|---|---|
| 앱 이름 | `HYPHEN - 체육관 코치·회원 소통` (20자. 애플에서 "HYPHEN" 단독은 이미 쓰이는 이름일 수 있어 같은 표기로 맞춘다) |
| 개발자 / 판매자 이름 | 변민준 (개인 — 사업자 정보·DRT 주소 사용 금지) |
| 지원 이메일 | cheb2oy@naver.com |
| 홈페이지 · 지원 URL · 마케팅 URL | https://web-facing-production.up.railway.app/ |
| 개인정보처리방침 URL | https://web-facing-admin-production-dca4.up.railway.app/privacy |
| 이용약관 URL | https://web-facing-admin-production-dca4.up.railway.app/terms |
| 계정·데이터 삭제 요청 URL | https://web-facing-admin-production-dca4.up.railway.app/delete-account |
| 버전 | 1.0.0 (빌드 3031) — pubspec `1.0.0+3031`. 구글 versionCode 3031 · 애플 CFBundleVersion 3031 (구 3027 = 09-04 D109·D111·D112·D113 / 구 3026 = 09-03 코치 쪽지 공지 픽스) |
| 카테고리 | 구글 **건강/운동** · 애플 기본 **건강 및 피트니스**, 보조 **스포츠** |
| 가격 · 광고 · 인앱결제 | 무료 · 광고 없음 · 인앱결제 없음 |
| 배포 국가 | 대한민국만 |
| 안드로이드 산출물 | `build/app/outputs/bundle/release/app-release.aab` (릴리즈 키 서명, 운영 URL 주입) |
| 스토어 에셋 | `build/store/` — 아래 §2-3 · §3-5 에 파일명 순서 |

---

## 1. 심사 계정 (두 스토어 공용)

운영 서버 체육관 **HYPHEN**(gym 2) 소속. 셋 다 로그인 속도 제한 예외(`REVIEW_LOGIN_IDS`)를 받는다.
아이디는 영문만 가능(서버 규칙 `[A-Za-z0-9._-]` 4~32자)이라 표시 이름을 한글로 짝지었다.

| 용도 | 아이디 | 표시 이름 | 비밀번호 (Railway `service-facing` 변수) | 심사팀이 보는 것 |
|---|---|---|---|---|
| 코치 | `testcoach1` | 테스트코치1 | `REVIEW_COACH_PASSWORD` | 예약 현황(오늘 수업·명단·가입 신청 승인) · 쪽지 |
| 회원 | `testmember1` | 테스트회원1 | `REVIEW_MEMBER_PASSWORD` | 홈 · 수업(프로그램·수업 시간·예약) · 히스토리 · 내 정보 (회원권 2027-12-31 까지) |
| 회원 (삭제 검증 전용) | `testmember2` | 테스트회원2 | `REVIEW_MEMBER2_PASSWORD` | 내 정보 → 개인정보처리방침 → **계정 삭제** 를 눌러도 되는 계정 |

- **삭제 검증용을 따로 두는 이유**: 심사팀이 testmember1 로 계정 삭제를 눌러 버리면 다음 심사 차례에
  회원 계정이 사라진다. 지침에 "계정 삭제는 testmember2 로" 라고 명시한다.
- 두 회원 다 0원 '심사용 회원권'(~2027-12-31)이 들어 있어 예약이 막히지 않는다.
- testmember2 가 삭제되면 같은 절차(가입 신청 → 코치 승인 → 회원권)로 다시 만든다 — `PLAYSTORE.md` A-12.

### 1-1. 심사팀 안내문 (앱 액세스 지침 · App Review 메모 공용)

한글:

```
이 앱은 체육관 코치와 회원을 잇는 앱입니다. 로그인 없이는 아무 화면도 볼 수 없습니다.
아이디·비밀번호로 로그인합니다 (소셜 로그인·OTP 없음).

- 코치 계정 testcoach1 — 예약 현황(오늘 수업 명단, 가입 신청 승인)과 쪽지함을 봅니다. 코치의 전체 운영 화면은 PC 웹(https://web-facing-admin-production-dca4.up.railway.app)에 있고, 폰 앱은 보조 화면입니다.
- 회원 계정 testmember1 — 홈(공지·레벨·업적), 수업(프로그램·수업 시간·예약/취소), 히스토리, 내 정보(회원권·포인트·알림 설정·개인정보처리방침·계정 삭제)를 봅니다.
- 계정 삭제 기능을 확인하려면 testmember2 를 사용해 주세요 (내 정보 → 개인정보처리방침 → 계정 삭제). testmember1 은 삭제하지 말아 주세요.
- '회원 가입 신청'으로 새 계정을 만들면 코치 승인 전까지 대기 화면이 뜹니다. testcoach1 로 로그인해 '가입 신청'에서 승인하면 바로 로그인됩니다.
- 알림은 앱이 켜져 있을 때 서버 이벤트로 표시되는 로컬 알림입니다 (푸시 서버 없음).
- 쪽지는 같은 체육관의 코치와 회원 사이 1:1 뿐이며 회원끼리는 대화할 수 없습니다. 공개 피드·프로필 검색이 없습니다. 코치는 PC 웹에서 회원을 탈퇴 처리해 대화를 끊을 수 있고, 부적절한 내용은 지원 이메일(cheb2oy@naver.com)로 신고받아 처리합니다.
세 계정 모두 같은 체육관(HYPHEN)에 속하며 만료되지 않습니다.
```

영문 (구글은 영어 안내를 요구한다 — 같은 내용):

```
HYPHEN connects gym coaches and members. Nothing is visible without signing in.
Sign in with ID and password (no social login, no OTP).

- Coach account testcoach1: today's class roster, membership-request approvals, and the inbox. The coach's full admin UI is the web app (https://web-facing-admin-production-dca4.up.railway.app); the phone app is a companion.
- Member account testmember1: Home (notices, level, achievements), Classes (program, timetable, reserve/cancel), History, and My Info (membership, points, notification toggle, privacy policy, account deletion).
- To test account deletion please use testmember2 (My Info → Privacy Policy → Delete account). Please do not delete testmember1.
- "Sign-up request" creates a pending account; approve it from testcoach1 → "가입 신청" and it can sign in immediately.
- Notifications are local notifications driven by server events while the app is open (no push server).
- Messages are 1:1 between a coach and a member of the same gym only; members cannot message each other. There is no public feed or profile search. A coach can remove a member from the gym (web admin), and objectionable content can be reported to cheb2oy@naver.com.
All three accounts belong to the same gym (HYPHEN) and never expire.
```

---

## 2. Google Play Console — 화면 순서

### 2-1. 앱 만들기 (모든 앱 → 앱 만들기)

| 칸 | 값 |
|---|---|
| 앱 이름 | HYPHEN - 체육관 코치·회원 소통 |
| 기본 언어 | 한국어 (대한민국) – ko-KR |
| 앱 또는 게임 | 앱 |
| 무료 또는 유료 | 무료 |
| 선언 | 개발자 프로그램 정책 · 미국 수출법 두 칸 체크 |

### 2-2. 앱 설정 → 앱 콘텐츠 (정책 및 프로그램 > 앱 콘텐츠) — 위에서부터

a. **개인정보처리방침** — URL: https://web-facing-admin-production-dca4.up.railway.app/privacy

b. **앱 액세스** — "일부 또는 모든 기능이 제한됨" → 지침 3세트 추가 (최대 5)

| 이름 | 사용자 이름 | 비밀번호 | 기타 지침 |
|---|---|---|---|
| Coach account | testcoach1 | Railway `REVIEW_COACH_PASSWORD` | §1-1 영문 안내문 전체 |
| Member account | testmember1 | Railway `REVIEW_MEMBER_PASSWORD` | "Member. Do not delete this account." |
| Member for deletion test | testmember2 | Railway `REVIEW_MEMBER2_PASSWORD` | "Use this account to test account deletion (My Info → Privacy Policy → Delete account)." |

c. **광고** — 광고 포함 안 함

d. **콘텐츠 등급** — 이메일 cheb2oy@naver.com · 카테고리 **유틸리티, 생산성, 커뮤니케이션 또는 기타**

| 설문 | 답 |
|---|---|
| 폭력 · 성적 콘텐츠 · 언어 · 약물/음주/담배 · 도박 · 공포 | 전부 없음 |
| 사용자 간 상호작용(채팅·메시지) | **예** — 같은 체육관 코치↔회원 1:1 쪽지, 불특정 공개 채팅 없음 |
| 사용자의 개인정보(이름·위치 등) 공유 | 위치 공유 없음. 이름은 같은 체육관 코치에게만 |
| 디지털 구매 · 인앱결제 | 없음 |
| 사용자 생성 콘텐츠 공개 게시 | 없음 (수업 내용은 코치가 쓰고 소속 회원만 열람) |
| 예상 결과 | 전체 이용가 (IARC 자동 산정 — 결과대로 따른다) |

e. **대상 연령층 및 콘텐츠** — 대상 연령: **18세 이상** 만 체크 (아동 대상 아님 → 이후 질문 없음). "아동의 관심을 끌 수 있음" 아니오.

f. **뉴스 앱** — 아니오

g. **데이터 보안** — "데이터 수집·공유 있음" 예. 아래 표대로. (분류 근거: 코치가 보는 것은 같은 서비스 안 열람이라 **제3자 공유 아님**. 운동 기록은 구글 정의상 피트니스 정보·회원권 기록은 구매 내역이라 **수집 예**로 넓게 신고 — 적게 신고해 정책 위반이 되는 쪽이 더 위험하다.)

| 데이터 유형 | 수집 | 공유 | 필수/선택 | 목적 |
|---|---|---|---|---|
| 개인 정보 > 이름 | 예 | 아니오 | 필수 | 앱 기능, 계정 관리 |
| 개인 정보 > 전화번호 | 예 | 아니오 | 선택 | 앱 기능 |
| 개인 정보 > 사용자 ID | 예 | 아니오 | 필수 | 앱 기능, 계정 관리 |
| 개인 정보 > 기타 정보 (생년월일·성별·운동 경력) | 예 | 아니오 | 선택 | 앱 기능 |
| 재무 정보 > 구매 내역 (회원권 기록 — 앱 내 결제 없음) | 예 | 아니오 | 선택 | 앱 기능 |
| 건강 및 피트니스 > 피트니스 정보 (수업 완료 기록: 동작·무게·횟수) | 예 | 아니오 | 선택 | 앱 기능 |
| 메시지 > 기타 인앱 메시지 (쪽지) | 예 | 아니오 | 선택 | 앱 기능 |
| 앱 활동 > 앱 상호작용 (예약·출석·포인트·업적) | 예 | 아니오 | 필수 | 앱 기능 |
| 앱 활동 > 기타 사용자 제작 콘텐츠 (전자계약 서명 이미지) | 예 | 아니오 | 선택 | 앱 기능 |
| 기기 또는 기타 ID (앱이 만든 익명 기기 식별값) | 예 | 아니오 | 필수 | 앱 기능, 계정 관리 |
| 위치 · 연락처 · 사진/동영상 · 오디오 · 파일 · 캘린더 · 앱 정보 · 웹 탐색 | 아니오 | – | – | – |

보안 관행: 전송 중 암호화 **예** · 데이터 삭제 요청 방법 제공 **예** (URL = §0 삭제 요청 URL) · 앱 내 삭제 경로 있음 · 독립 보안 검토 **아니오** · 임시 처리 없음.

h. **정부 앱** — 아니오

i. **금융 기능** — "앱이 금융 기능을 제공하지 않음"

j. **건강 앱** — **활동 및 피트니스** 항목에 해당 (운동 기록 저장). 건강 데이터(심박·체중)·Health Connect 없음. 의료·임상 기능 없음.

k. **광고 ID** — 사용 안 함

### 2-3. 스토어 등록정보 (성장 > 스토어 등록정보 > 기본 스토어 등록정보)

| 칸 | 값 |
|---|---|
| 앱 이름 (30자) | HYPHEN - 체육관 코치·회원 소통 |
| 간단한 설명 (80자) | 체육관 코치와 회원을 잇는 앱. 수업 예약·공지·쪽지, 그리고 업적과 포인트로 운동을 재밌게. |
| 자세한 설명 (4000자) | 아래 블록 그대로 |
| 앱 아이콘 (512×512) | `build/store/icon_512.png` |
| 피처 그래픽 (1024×500) | `build/store/feature_1024x500.png` |
| 휴대전화 스크린샷 (1080×1920 · 7장, 이 순서) | `phone_01_member_08_classes_reserved` 예약 → `phone_02_member_02b_home_notice` 공지 → `phone_03_state_20_inbox_threads` 쪽지 → `phone_04_ach_02_unlock_toast` 업적 달성 → `phone_05_member_12_achievements_all` 업적 목록 → `phone_06_member_02_shell_home` 홈 레벨 → `phone_07_member_03_shell_profile` 내 정보 |
| 7인치 · 10인치 태블릿 스크린샷 | 비움 (폰 전용) |

자세한 설명:

```
HYPHEN(하이픈)은 체육관 코치와 회원을 잇는 앱입니다. 체육관에 정말 필요한 다섯 가지에만 집중했습니다.

수업 예약
이번 주 시간표를 보고 폰에서 바로 예약합니다. 정원이 차면 대기로 들어가고, 자리가 나면 쪽지로 알려 줍니다. 예약은 수업 전날 열리고, 시작 20분 전까지 취소하면 횟수권이 차감되지 않습니다.

공지
코치가 올린 공지가 홈 화면 맨 위에 뜹니다. 휴관일, 일정 변경 같은 체육관 소식을 단톡방에 묻히지 않고 받아봅니다.

쪽지
회원은 수업 화면에서 코치에게 쪽지를 보내고, 코치는 답합니다. 예약 확정, 대기 승격, 회원권 만료 같은 알림도 따로 없이 쪽지 하나로 옵니다.

업적
출석과 수업 기록이 쌓이면 업적이 열립니다. 첫 열 번, 3주 연속, 첫 PR — 달성하는 순간 화면이 축하하고, 모은 업적은 트로피 룸에 남습니다.

포인트
출석, 수업 결과 저장, 업적 달성마다 포인트가 쌓이고 레벨이 오릅니다. 적립 기준과 쓰임새는 각 체육관의 코치가 정합니다.

이 외에 회원 가입 신청, 회원권 조회, 수업 내용 열람, 출석 기록, 전자계약서 확인 기능을 제공합니다.

코치는 PC 웹에서도 동일한 정보를 관리합니다. 이 앱은 코치의 이동 중 확인과 회원과의 즉시 소통을 보조하는 역할입니다.

로그인은 아이디와 비밀번호로 합니다 (소셜 로그인 없음). 코치·회원 구분은 가입한 체육관 정보에 따라 서버에서 자동으로 판정합니다. 회원 가입은 소속 체육관 코치의 승인 후 이용 가능합니다.
```

### 2-4. 스토어 설정 (성장 > 스토어 설정)

| 칸 | 값 |
|---|---|
| 앱 카테고리 | 앱 · **건강/운동** |
| 태그 (최대 5, 콘솔 고정 목록에서 가장 가까운 것) | 피트니스 · 스포츠 · 커뮤니케이션 순으로 고르고 없으면 비움 |
| 스토어 등록정보 연락처 | 이메일 cheb2oy@naver.com · 웹사이트 https://web-facing-production.up.railway.app/ · 전화 비움 |
| 외부 마케팅 | "Google Play 외부에서 앱 마케팅 안 함" 체크 |

### 2-5. 국가/지역

프로덕션·비공개 테스트 트랙 모두 **대한민국** 만 추가.

### 2-6. 테스트 → 비공개 테스트 (개인 계정 필수 관문: 테스터 12명 · 14일 연속)

| 칸 | 값 |
|---|---|
| 트랙 | 비공개 테스트 → 트랙 만들기 → 이름 `closed-1` |
| 테스터 | 이메일 목록 만들기 → 지인·회원 구글 계정 **12명 이상 여유 있게** (중간 이탈 시 카운트 리셋) — 초대 문구 = `PLAYSTORE.md` §G 테스터 초대 문구 |
| App Bundle | `build/app/outputs/bundle/release/app-release.aab` 업로드 — 첫 업로드에서 **Play 앱 서명 사용** 동의 |
| 출시 이름 | 1.0.0 (3031) |
| 출시 노트 (ko-KR) | `HYPHEN 첫 테스트 버전. 수업 예약·공지·쪽지·업적·포인트.` |
| 검토 → 출시 시작 | 비공개 테스트는 검토 뒤 테스터에게 열림 |

### 2-7. 프로덕션 액세스 신청 (14일 뒤 대시보드에 "프로덕션 액세스 신청" 이 뜬다)

| 질문 | 답 요지 |
|---|---|
| 테스터 모집 방법 | 체육관 회원과 지인에게 직접 초대 링크 배포 |
| 참여 정도 | 로그인 → 수업 예약·취소 → 코치 쪽지 왕복 → 업적 확인 |
| 받은 피드백 | 실제로 받은 것만 두세 줄 (지어내지 않는다) |
| 반영 사항 | 반영한 커밋이 있으면 요약, 없으면 "없음" |

### 2-8. 프로덕션 출시

프로덕션 → 새 버전 만들기 → 같은 AAB 선택(또는 "테스트 트랙에서 승격") → 국가 대한민국 → 검토 → 출시.
심사는 보통 며칠. 반려 메일이 오면 사유 원문을 그대로 붙여 주면 대응한다.

---

## 3. App Store Connect — 화면 순서

### 3-1. 나의 앱 → + 신규 앱

| 칸 | 값 |
|---|---|
| 플랫폼 | iOS |
| 이름 | HYPHEN - 체육관 코치·회원 소통 ("이미 사용 중" 이면 `HYPHEN 하이픈 - 체육관 코치·회원 소통`) |
| 기본 언어 | 한국어 |
| 번들 ID | com.netizen.hyphen.hyphenApp (Identifiers 에 먼저 등록돼 있어야 목록에 뜬다) |
| SKU | hyphen-ios |
| 사용자 액세스 | 전체 액세스 |

### 3-2. 앱 정보

| 칸 | 값 |
|---|---|
| 이름 · 부제 | HYPHEN - 체육관 코치·회원 소통 · 코치와 회원을 잇는 체육관 앱 |
| 기본 카테고리 · 보조 | 건강 및 피트니스 · 스포츠 |
| 콘텐츠 권한 | 제3자 콘텐츠 포함 안 함 |
| 연령 등급 (신 설문 4+/9+/13+/16+/18+) | 폭력·성·약물·도박·공포·의료/웰니스 주제 전부 "없음" · 무제한 웹 액세스 아니오 · **메시지/채팅 기능 있음**(같은 체육관 코치↔회원 1:1, 공개 피드 없음) · 사용자 생성 콘텐츠 "제한적" · 부모 통제/인앱 제어 없음 · 광고 없음 → 산출 등급대로 (4+ 예상) |
| 라이선스 계약 | 애플 표준 EULA |

### 3-3. 가격 및 사용 가능 여부

| 칸 | 값 |
|---|---|
| 가격 | 무료 |
| 사용 가능 국가 | **대한민국** 만 |
| 사전 주문 | 없음 |
| 계정 설정 → 규정 준수 (EU DSA) | **판매자 아님** (한국만 배포하는 개인 계정) |

### 3-4. 앱 개인정보 보호 (App Privacy)

개인정보처리방침 URL = §0. "데이터를 수집합니다" 예. 추적(Tracking) **아니오** 전부.
모든 항목 "사용자와 연결됨" 예, 목적 "앱 기능".

| 애플 데이터 유형 | 세부 |
|---|---|
| 연락처 정보 | 이름 · 전화번호 |
| 건강 및 피트니스 | 피트니스 (수업 완료 기록) |
| 재무 정보 | 구매 내역 (회원권 기록 — 앱 내 결제 없음) |
| 사용자 콘텐츠 | 기타 사용자 콘텐츠 (쪽지 · 수업 기록 · 전자계약 서명) |
| 식별자 | 사용자 ID · 기기 ID |
| 사용 데이터 | 제품 상호작용 (예약·출석·포인트·업적) |
| 기타 데이터 | 생년월일 · 성별 · 운동 경력 |
| 위치 · 진단 · 검색 기록 · 탐색 기록 · 민감 정보 | 수집 안 함 |

### 3-5. iOS 앱 1.0 (버전 준비)

| 칸 | 값 |
|---|---|
| 스크린샷 6.9" (1320×2868 · 7장, 이 순서) | `build/store/ios/6.9/01_member_08_classes_reserved` → `02_member_02b_home_notice` → `03_state_20_inbox_threads` → `04_ach_02_unlock_toast` → `05_member_12_achievements_all` → `06_member_02_shell_home` → `07_member_03_shell_profile` |
| 스크린샷 6.5" (선택) | `build/store/ios/6.5/` 같은 7장 |
| iPad | 없음 (iPhone 전용 앱) |
| 프로모션 텍스트 (170자, 선택) | 체육관 코치와 회원을 잇는 앱. 수업 예약·공지·쪽지, 그리고 업적과 포인트로 운동을 재밌게. |
| 설명 | §2-3 "자세한 설명" 블록 그대로 |
| 키워드 (100자) | 체육관,코치,수업 예약,공지,쪽지,회원권,출석,업적 |
| 지원 URL · 마케팅 URL | https://web-facing-production.up.railway.app/ |
| 빌드 | TestFlight 에 올라온 1.0.0 (3031) 선택 |
| 저작권 | 2026 변민준 |
| 버전 | 1.0.0 |
| 앱 심사 정보 — 로그인 필요 | 체크 → 사용자 이름 `testmember1` · 비밀번호 Railway `REVIEW_MEMBER_PASSWORD` |
| 앱 심사 정보 — 연락처 | 이름 변민준 · 전화 (본인) · cheb2oy@naver.com |
| 앱 심사 정보 — 메모 | §1-1 한글 안내문 전체 (코치 testcoach1 · 삭제용 testmember2 비밀번호를 메모 안에 함께 적는다 — 심사 정보란은 비공개) |
| 버전 출시 | **수동으로 출시** (승인 뒤 구글과 같은 날 출시하려고) |

### 3-6. 심사 제출

"심사를 위해 추가" → 제출. 첫 심사는 보통 1~2일. 반려되면 Resolution Center 원문을 붙여 준다.

---

## 4. 심사팀이 실제로 눌러 볼 것 → 보여야 할 것 (2026-09-03 에뮬레이터 실측)

운영 서버 APK(1.0.0+3027 — 09-04 D109 파트·D111 통합 한 줄·D112 여닫기·D113 터치 48. 현재 산출물은 3031 = D115·D117·D118 밀림 집행분 + 수업 탭 실패 표시 픽스 + D119 줄 오른쪽 비우기)를 초기화한 뒤 실제로 눌러 본 결과. 골든 이름은 `test/golden/goldens/`.

| 심사팀 행동 | 보여야 할 것 | 실측 |
|---|---|---|
| 앱 첫 실행 | 알림 권한 팝업 → 로그인 화면 (제목 '로그인', 아이디·비밀번호, 회원 가입 신청, 약관·방침 링크) | 통과 — common_08_login |
| testmember1 로그인 | 수업 탭이 먼저 열리고 오늘 프로그램이 펼쳐짐 (SWEAT · A 세션, '예약 필요' 배지) | 통과 — member_26_program |
| 수업 시간 칸 | 오늘 남은 수업에 빨간 '예약' 버튼, 지난 수업은 '종료' | 통과 — member_07_classes |
| 예약 누르기 | '예약됨' + 폭죽 스낵바, 홈 '오늘 내 예약' 에 반영 | state_27_reservation_done (골든) |
| 내 정보 | 테스트회원1 · HYPHEN · 회원권 484일 남음 · 포인트 · 메뉴 7개 · 알림 받기 토글 | 통과 |
| 히스토리 | 새 계정이라 '수업 기록 없음' 빈 상태 — 정상 | hist_01_empty |
| 홈 | 공지 전광판(없으면 '등록된 공지 없음') · 레벨 카드 · 업적 · 마일스톤 | member_02_shell_home |
| 쪽지 (수업 카드 '메시지') | 코치에게 쪽지 작성 → 쪽지함 '코치' 칸 | member_11_messaging |
| 계정 삭제 (testmember2) | 내 정보 → 개인정보처리방침 → 계정 삭제 → 확인 → 로그인 화면으로 | member_19_privacy |
| 회원 가입 신청 | 신청서 제출 → 승인 대기 화면. testcoach1 '가입 신청' 에서 승인 → 로그인 가능 | common_06_self_signup · state_05_pending · coach_05_member_approvals |
| testcoach1 로그인 | 코치 셸 2탭 — 예약 현황(오늘 예약·출석·주간 신규, 가입 신청 버튼, 주간 수업 명단) · 쪽지(상단 공지 카드에 'HYPHEN 앱 이용 안내' · 회원 이름별 스레드) | 통과 — coach_01_shell_reservations · coach_03_shell_messages (09-03 오후 재생성: 코치 셸이 공지 상태를 묶지 않아 카드가 늘 '등록된 공지 없음' 이던 결함 픽스 → 빌드 3026) |
| 홈 공지 전광판 (testmember1) | 'HYPHEN 앱 이용 안내' 가 흐른다 — 운영 공지 3건은 전부 기간 만료(end_at 08-11·08-17·09-01)라 09-03 오후 코치로 무기한 공지 1건 게시 | 통과 — API `/api/v1/member/announcements` 1건 |
| 오프라인 | 상단 '오프라인' 배너, 크래시 없음 | state_03_home_offline |

반려 가능성이 있던 것과 처리 (전부 2026-09-03 완료):

| 위험 | 처리 |
|---|---|
| 개인정보처리방침이 앱과 다름 (없어진 '착용 칭호' 항목) | 방침·삭제 안내·앱 화면에서 삭제, 갱신일 2026-09-03 |
| 스크린샷이 실물과 다름 (3탭 시절 · 'WOD Class' 가짜 수업명) | 4탭 셸 골든으로 재생성, 수업명 SWEAT/AWAKE |
| 심사 계정이 헷갈림 · 회원 비밀번호 분실 | testcoach1/testmember1/testmember2 로 개명, 비밀번호 Railway 변수 |
| 심사팀이 회원 계정을 삭제해 버림 | 삭제 검증 전용 testmember2 + 지침 명시 |
| 애플이 Xcode 26 미만 빌드 거절 (2026-04-28~) | CI 러너 macos-26 |
| iOS 개인정보 매니페스트 누락 | PrivacyInfo.xcprivacy 추가 |
| 데이터 보안 답과 실제 수집이 다름 | 운동 기록=피트니스 정보 · 회원권=구매 내역으로 넓게 신고, 건강 앱 선언 |

---

## 5. 제출 직전 10분

1. `python tool/store_preflight.py` → 전부 PASS (FAIL 이 있으면 그 줄이 곧 할 일).
2. 구글: 앱 콘텐츠 11개 항목에 초록 체크 · 앱 액세스 지침 3세트 · 스크린샷 7장 순서 · AAB 버전 3031.
3. 애플: 빌드가 '처리 완료' 인지 · 스크린샷 7장 · 심사 정보 메모에 계정 3개 · 연령 등급 설문 완료 · 판매자 아님.
4. 두 콘솔의 방침 URL 을 브라우저에서 한 번 열어 본다 (200 + '최종 갱신 2026-09-03').
5. 폰에서 testmember1 · testcoach1 실로그인 1회 (속도 제한 예외라 여러 번 해도 된다).
