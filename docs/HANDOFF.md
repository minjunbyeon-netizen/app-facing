# HANDOFF - 2026-08-13 08:13

> 주제: **용어·역할 SSOT 확정(GLOSSARY·D35~D37) + 없는 기능 광고 제거 + 회원 정보 입력 신설**.
> 세 repo 를 만졌다: `apps/facing-app`(주) · `services/facing`(API 1개 추가) · `web/facing-admin`(표기·코치 관리 폐기).
> **푸시·배포 모두 사용자 승인 하에 수행함** (PC 웹 2회, 백엔드 1회 배포).
> 사용자 지시의 큰 줄기: "코치=사장 한 단어로" → "역할 셋뿐" → "레벨은 경력으로" →
> "코치 관리 없앤다" → "지금 없는 건 다 지워" → "1인 샵이니 박스 찾기·만들기도 없앤다".

## 완료

### 1. 용어·역할 SSOT — `docs/GLOSSARY.md` 신설 (표기 정본)
- [x] **운영자 호칭 '코치' 하나로 통일.** 사장·오너·매니저·관리자·운영자·짐매니저 전부 폐기.
      앱 문구 22곳 수정(로그인·가입·설정·수업·프로필·약관·개인정보·FAQ) +
      `lib/core/role_labels.dart` 매핑 4종 → 코치 + pending 라벨 '가입 대기' → **'회원신청자'**.
- [x] **자동 게이트**: `test/copy_lint_test.dart` 에 '운영자 호칭 1종' 테스트 추가 — 다시 쓰면 깨진다.
- [x] **D35 — 역할은 셋뿐** (코치 · 회원 · 회원신청자). 브리프 §2-0-1 전문 + 3면 CLAUDE.md
      대전제 동기화(`services/facing`·`web/facing-admin` 각각 커밋). super admin 은 나중.
- [x] **D36 — 회원 레벨 = 크로스핏 경력 3단** (1년 미만 SCALED / 1~3년 RXD / 3년 이상 ELITE).
      경계 SSOT = `Tier.fromExperienceYears` + 서버 `_level_from_experience`.
      PC 표기도 RX → **RXD**, "앱 사용 후 자동 산정" → "가입 시 경력 기준 자동".
- [x] **D37 — 코치 '관리' 면 전면 폐기.** PC 온보딩 STEP2 '코치 등록+페어링 코드' 카드와
      `/coaches` 링크 3곳, 랜딩·통계 문구, 앱 프로필 '직원 계정 연결' 행 삭제.

### 2. 앱 — 없는 기능 광고 제거 + 화면 정리
- [x] **ENGINE 섹션 폐기**(D34) — `lib/features/mypage/score_section.dart` 로 이관 보존.
- [x] **인트로 3p 'Tier' 삭제** → 2p. **프로필 수정의 Benchmarks 카드 삭제**.
- [x] **WOD 행 액션 3개(완료 표시·메시지·자세히) → FkBadge 한 규격** (수업 예약 배지와 동일 크기).
- [x] **결과 시트**: 버튼 '제출하고 출석' → **'저장'** + 아래 한 줄 "저장하면 오늘 출석도 함께
      기록됩니다." · 스케일 순서 **SCALED → RXD → ELITE** · 스낵바 영문 → 한글.
- [x] **박스 찾기·박스 만들기 전면 폐기** (1인 샵) — 미가입 화면은 '가입 코드 입력' 하나.
      거절 화면의 '다른 박스 찾기'도 제거. 검색 화면·생성 시트·탈퇴 흐름은 코드 보존.
- [x] 프로필 로그아웃 줄에 내부 코드값 `MEMBER_ID` 노출되던 것 제거(실기에서 발견).

### 3. 신규 기능 — 회원이 자기 인적사항 입력
- [x] 백엔드 **`GET/PATCH /api/v1/member/me/profile`** (`services/facing/api/profile.py` 끝).
      소속 박스가 여러 곳이면 모든 행에 같은 값. level 은 경력에서 계산한 값만 저장(직접 지정 금지).
- [x] 앱 온보딩 화면 '기본 정보' → **'내 정보'**: 이름(필수)·생년월일·전화 + 성별·경력·레벨 배지.
      코치가 PC 에 적어둔 값이 있으면 GET 으로 prefill. 전송 실패해도 진입은 막지 않는다.
- [x] **생년월일 자동 하이픈 + 검증** — `lib/core/input_formatters.dart`(SSOT) + 단위 테스트 10건.

### 4. 검증·배포
- [x] **가입 코드 E2E 실검증 성공**: 코치 PC 에서 '코드테스트 뉴비' 등록 → 앱 연결 코드
      `200034` 발급 → 에뮬레이터에서 입력 → "HYPHEN 연결 완료" → 프로필이 그 회원으로 전환.
      재발급 시 **"이미 기기와 연결된 회원입니다"** 로 정상 차단.
- [x] **PC 웹 치명 버그 수정**: 배포본 `style.css` 에 `.modal-backdrop` 이 두 번 정의돼
      (뒤엣것 `display:flex`) **모든 모달이 로드 즉시 열려 화면이 잠겼다.** 재배포로 해소.
- [x] 골든 22 → 19(진입점 없는 3장 제거) → **20장**(WOD 결과 입력 시트 추가).
      갤러리 라벨도 실물과 대조해 정정(소셜 로그인·Tier·'사장' 표기).
- [x] `flutter analyze` 0 · `flutter test` **138 통과** · 3 repo 푸시 완료.

## 진행중

없음.

## 대기

- [ ] **새 빌드로 뉴비 흐름 실기 확인** — 가입 코드 입력 → '내 정보' 입력 → PC 회원 목록에
      이름·생년월일·전화·레벨이 뜨는지. (지금 에뮬레이터에 깔린 APK 는 이 화면 이전 빌드다.)
- [ ] `/onboarding/find-gym` 라우트 차단 (`lib/main.dart:209`) — 버튼은 없앴으나 딥링크로는 열린다.
- [ ] PC 웹 랜딩·온보딩에 남은 "박스를 만들어" 류 문구 훑기 (앱만 정리했다).
- [ ] 테스트로 만든 회원 **'코드테스트 뉴비'** 정리 (운영 DB, gym HYPHEN, member id 1).
- [ ] 생년월일 외 전화번호 자동 하이픈은 미적용.
- [ ] `button_lint_test.dart` 신설 · `applyPersonaSnapshot()` 이름 잔재 · `_kShowSocialLogin=false`.

## 결정사항 / 주의

1. **배포는 반드시 커밋 상태에서.** `railway up` 은 git 이 아니라 **작업 폴더를 그대로 올린다** —
   다른 세션의 미완성 `style.css` 가 섞여 올라가 PC 모달이 전부 열리는 사고가 났다.
2. **다른 세션이 "하드코딩 일괄 삭제 / 백지 상태" 작업을 병행 중이다** (`scripts/blank_slate.py`,
   app.py 고정 계정 시드 삭제). 회원·요금제·락커가 사라져도 **손실이 아니다. 복구 시도 금지**
   (사용자 명시).
3. **`.nopush` 마커가 세 repo 모두에 있다** — push = 배포로 취급. 사용자 명시 승인 후에만.
4. **"숨김 = 코드 보존"** 원칙 유지. 진입점만 끊고 파일은 남긴다. 분석 경고가 나면
   `// ignore: unused_element` + 사유 주석(박스 생성 시트·`_confirmLeave`) 또는 별도 파일 이관
   (`score_section.dart`).
5. **골든 규칙(신설)**: *진입점이 없는 화면은 골든에서 뺀다.* 되살릴 때 캡처도 같이 되살린다.
6. UI 를 바꾸면 **골든 재생성 + 갤러리 갱신이 완료 조건**.
7. **이 repo 에서 `dart format` 금지** (옛 SDK 포맷 — 대량 재포맷).
8. auto-save 훅이 중간 커밋을 만든다. 코드는 HEAD 에 정상.
9. 백엔드 `level` 허용값은 `Scaled/RX/RX+/Elite` — **표기만** RXD 로 바꾼다(저장값은 RX).

## 관련 파일

| 경로 | 역할 |
|---|---|
| `docs/GLOSSARY.md` | **표기 SSOT (신설)** — 역할 3종·금지 표기·경력 레벨표·자동 게이트 |
| `docs/ARCHITECTURE_BRIEF.md` | §2-0-1 역할 셋 · D34~D37 |
| `test/copy_lint_test.dart` | 금지 용어 + **운영자 호칭 1종** 게이트 |
| `lib/core/role_labels.dart` | 역할 라벨 번역 유일 지점 (전부 '코치') |
| `lib/core/tier.dart` | `fromExperienceYears` · `memberLevelLabel`(RXD) |
| `lib/core/input_formatters.dart` | 생년월일 하이픈·검증 SSOT |
| `lib/features/onboarding/onboarding_basic.dart` | '내 정보' 화면 (이름·생년월일·전화·성별·경력) |
| `lib/features/mypage/score_section.dart` | 폐기된 ENGINE 섹션 보존소 |
| `lib/features/gym/box_wod_screen.dart` | 미가입·거절 화면 (박스 찾기 제거됨) |
| `services/facing/api/profile.py` | `GET/PATCH /api/v1/member/me/profile` (파일 끝) |
| `web/facing-admin/templates/members.html` | 레벨 RXD 표기 · "가입 시 경력 기준 자동" |

## 로컬 실행 메모

```
빌드   flutter build apk --debug --dart-define=API_BASE_URL=https://service-facing-production.up.railway.app
설치   adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
골든   flutter test --update-goldens test/golden && python tool/golden_gallery.py
배포   cd C:/dev/web/facing-admin && railway up --detach   (백엔드는 services/facing 에서)
```
운영 PC 웹 `https://web-facing-admin-production-dca4.up.railway.app` ·
백엔드 `https://service-facing-production.up.railway.app`.
폰(192.168.1.100:5555)은 무선 adb 가 끊긴 상태 — 재연결 필요.

## 다음 세션 권장 첫 프롬프트

`/resume` → 새 빌드 설치 후 뉴비 흐름(가입 코드 → 내 정보 → PC 반영) 실기 검증부터.
