# HANDOFF - 2026-08-12 22:00

> 주제: **회원 진입 동선 대폭 축소 + WOD·수업 화면 컴팩트화 (v2.3)**.
> 이번 세션은 `apps/facing-app` 과 `services/facing` **두 repo**를 만졌다 (PC 웹 0건).
> **push·배포 0건.** 로컬 커밋만.
> 사용자 지시의 큰 줄기: "이 앱은 **HYPHEN 한 박스 전용**이다. 회원에게 최소한만 묻고,
> 화면은 컴팩트하게."

## 완료

### 1. 로딩·로그인 화면 정리 — `f44cfab`
- [x] 스플래시 하단 **명언 카드 삭제** (`QuoteCard` 호출만 제거, 위젯은 등급·계산 로딩에서 계속 사용)
- [x] 로그인 첫 화면 **`코치·사장 로그인` 줄+구분선 제거** (`_kShowBossEntry=false`, 라우트 보존)
- [x] 라벨 명확화: `가입 신청` → **`박스 가입 신청`**, `가입 코드로 연결` → **`가입 코드 입력`**
      (뒤 문구는 `claim_code_screen` 제목과 표기 통일, §0-B)

### 2. 가입 동선 축소 + 로그인 계정 생성 — `c0e899c` (앱) / 백엔드는 `f6fb70a` 에 흡수
- [x] **박스 번호 칸 삭제.** 가입 화면 = 아이디 + 비밀번호 + 비밀번호 확인 **3칸**.
      박스는 `gyms-list` 에서 이름이 `HYPHEN` 인 행으로 자동 결정 (`_kBrandGymName`,
      폴백 `_kFallbackGymId=2`)
- [x] 백엔드 `member_self_signup` 이 `login_id`/`password` 를 받아 **MemberCredential 생성**
      (bcrypt cost 12). 아이디 선점 검사(회원·스태프 양쪽) → 409.
      **중복 기기 분기에서도 자격증명 upsert** — 기기로만 가입해 둔 회원이 아이디를 만드는
      유일한 경로라, 여기서 건너뛰면 폰 교체 시 계정을 잃는다
- [x] 이름 미전송 시 아이디를 표시용 이름으로 사용 (사장이 승인하며 실명으로 수정)
- [x] **실호출 6케이스 검증 완료**: 신규 201 / 아이디중복 409 / 로그인 200 / 틀린비번 401 /
      없는박스 404 / 짧은비번 400 (`scratchpad/test_signup.py`)

### 3. 온보딩 축소 + 인트로 삭제 — `c0e899c`
- [x] 온보딩 `/onboarding/basic` 을 **성별 + 경력 2문항**으로 재작성.
      체중·키·나이 삭제, **벤치마크 6단계(운동능력) 진입 삭제**, 7단계 진행바 삭제
- [x] 경력 = **1년 미만 / 1~3년 / 3년 이상** 3구간 (`_kExpBands`, 대표값 0.5·2·5년).
      사용자가 말한 경계(1년·3년)는 유지하되 "1년 이상"과 "3년 미만"이 겹치는 문제만 제거
- [x] **첫 실행 인트로 3장 진입 삭제** (`/intro` 화면·라우트는 보존). splash → 미로그인이면
      `/signup`, 로그인 상태면 `/shell` 직행
- [x] `hasGrade` 로 온보딩에 붙잡던 분기 전부 제거 (splash·member_login·self_signup)
- [x] 회원 로그인 화면(`member_login_screen`)의 `코치·사장이신가요?` 줄도 삭제

### 4. WOD·수업 화면 컴팩트 — `c0e899c`, `7345dcb`
- [x] **오늘 WOD 를 최상단으로.** 순서 = 오늘 → 예정 → 지난 → 수업 → 박스정보·공지
      (전에는 박스정보·공지·지난WOD 를 지나야 오늘 것이 나왔다)
- [x] 여백 축소: ListView `sp4→sp3`, 섹션 간격 `sp5→sp3`, `_kv` 줄 간격 `6→3`
- [x] **라운드가 1개면 `A. METCON` 행 생략** — 바로 위 본문과 같은 내용이 두 번 나왔다
- [x] 수업 카드 여백 `sp4→sp3` / margin `sp3→sp2`
- [x] 수업 정원 표기 `8/12` → **`8명 / 12명`** (날짜 8월 12일로 읽혔다)

### 5. 예약 → 코치 PC 반영 점검 (코드 변경 0건 — 이미 구현돼 있었다)
- [x] `GET /api/v1/admin/classes/<id>/reservations` 가 예약자·대기자 명단을 이름·전화·
      예약시각·상태로 반환 (고아 예약은 `탈퇴 회원` 으로 노출)
- [x] PC 웹 `web/facing-admin/templates/classes.html` 에 **예약자 명단 블록 + 출석 표시 버튼**
      존재 (D29)
- [x] PII: 코치는 `members_name_full` scope 로 **이름 평문**, 연락처만 마스킹 (D30 정책대로)
- [x] 실DB 확인 — 회원 `member`(member_id 123) 의 21:46 예약이 `confirmed` 로 정상 기록

### 검증
`flutter analyze` 0 issues · `flutter test` **134 passed** · 골든 4장 갱신
(`common_01_splash`·`common_05_signup`·`onb_01_basic`·`member_01_shell_wod`·`state_01_wod_error`) ·
갤러리 22장 · 에뮬레이터 실물 확인 완료

## 진행중

없음.

## 대기 (사용자 결정 필요 / 다음 후보)

- [ ] **홈·프로필 탭은 아직 손대지 않았다.** WOD·수업과 같은 기준(여백·중복 표기)으로 정리 필요
- [ ] **코치 PC 화면을 브라우저로 직접 열어 명단 확인** — 이번엔 코드·DB 로만 확인했다
      (`web/facing-admin` 로컬 기동 + 코치 로그인 필요)
- [ ] **앱에서 신규 가입 성공 다이얼로그를 실물로 못 봤다.** API 6케이스는 통과했고 앱에서
      요청도 정상 전송되지만, 화면 캡처로 확인한 것은 "이미 가입된 회원" 분기까지다
- [ ] **벤치마크·등급 화면이 고아가 됐다.** `/onboarding/benchmarks`·`/onboarding/grade` 는
      살아 있고 `mypage/edit_profile_screen` 에서만 닿는다. 존치할지 진입점까지 뺄지 결정 필요
- [ ] `_kShowSocialLogin=false` (실 OAuth 키 대기) 는 그대로 둠
- [ ] `applyPersonaSnapshot()` 이름 잔재 (지난 세션 대기 항목, 그대로 남음)
- [ ] `button_lint_test.dart` 신설 (§7-D 버튼 규칙 자동 게이트, 지난 세션 대기 항목)

## 결정사항 / 주의

1. **이 repo 에서 `dart format` 금지.** 옛 SDK 포맷이라 118개 파일이 통째로 재포맷된다.
2. **auto-save 훅이 백엔드 커밋을 남의 커밋에 흡수한다.** 이번에도 `api/admin.py` 변경이
   다른 세션 커밋 `f6fb70a`("QR 출석 체크인 폐지")에 섞여 들어갔다. 코드는 HEAD 에 정상
   반영돼 있으나, 커밋 단위로 되돌리려 하면 남의 작업까지 딸려온다.
3. **백엔드는 `use_reloader=False`** 라 코드를 고치면 반드시 프로세스를 죽였다 다시 띄워야
   한다. 이번 세션에서 이걸 놓쳐 "가입이 안 된다"고 한 번 오진했다 (실제로는 백엔드가 꺼져 있었다).
4. **adb `keyevent 111`(ESC)은 Flutter 화면을 pop 시킨다.** 자동화로 키보드를 닫을 때 쓰면
   입력하던 화면이 뒤로 넘어간다 — 키보드는 그냥 두고 버튼을 누르는 편이 안전하다.
5. **폰(갤S22)에 있던 기존 앱이 서명 불일치로 삭제·재설치됐다** (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`).
   릴리즈 서명으로 깔려 있던 앱의 로컬 데이터(세션·기기 ID)는 초기화됐다.
6. **"숨김 = 코드 보존" 원칙 유지.** 인트로·코치사장 진입·벤치마크는 전부 상수/진입점만
   끊었고 화면·라우트·백엔드는 살아 있다. 되살리려면 상수 한 줄이면 된다.
7. **배포 금지 유지.** 사용자가 "배포해"라고 하기 전까지 push·railway up 금지.
8. UI 를 바꾸면 **골든 재생성 + 갤러리 갱신이 완료 조건**
   (`flutter test --update-goldens test/golden` → `python tool/golden_gallery.py`).

## 관련 파일

| 경로 | 역할 |
|---|---|
| `lib/features/signup/self_signup_screen.dart` | 가입 3칸 (박스 자동 결정 `_kBrandGymName`) |
| `lib/features/onboarding/onboarding_basic.dart` | 성별·경력 2문항 (`_kExpBands`) |
| `lib/features/splash/splash_screen.dart` | 인트로·hasGrade 분기 제거 |
| `lib/features/auth/signup_screen.dart` | 로그인 첫 화면 (`_kShowBossEntry`) |
| `lib/features/auth/member_login_screen.dart` | 아이디 로그인 (코치·사장 줄 제거) |
| `lib/features/gym/box_wod_screen.dart` | WOD 보드 순서·여백·`_kv`·라운드 중복 |
| `lib/features/classes/classes_screen.dart` | 수업 카드 여백·정원 표기 |
| `C:/dev/services/facing/api/admin.py` | `member_self_signup` + `_upsert_credential()` |
| `C:/dev/services/facing/api/classes.py` | `admin_list_class_reservations` (코치 명단) |
| `C:/dev/web/facing-admin/templates/classes.html` | PC 예약자 명단 UI (D29) |
| `C:/dev/tools/linko-screens/REVIEW.md` | 링코 결함 F1~F10 — 밀도·대비 판단 근거 |

## 로컬 실행 메모

```
백엔드   cd C:/dev/services/facing && python app.py          # 0.0.0.0:5060, 수정 시 재시작 필수
앱(에뮬) flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5060
앱(실기) flutter run -d 192.168.1.100:5555 --dart-define=API_BASE_URL=http://192.168.1.103:5060
```
테스트 계정: 회원 `member` / `1234` (gym 2 = HYPHEN, approved)

## 다음 세션 권장 첫 프롬프트

`/resume`

이어서 하려면 대기 항목 중 하나를 골라 지시:
1. 홈·프로필 탭도 같은 기준으로 컴팩트 정리
2. 코치 PC 화면 브라우저로 열어 예약자 명단 실사 확인
3. 벤치마크·등급 화면 존치 여부 결정
