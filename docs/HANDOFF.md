# HANDOFF - 2026-08-13 12:01

> 주제: **없는 기능 광고 전면 제거 → 가입 코드 폐기 → 가입 신청서 확대 + 승인 전 차단**.
> 세 repo 를 만졌다: `apps/facing-app` · `services/facing` · `web/facing-admin`.
> **배포·푸시 모두 사용자 승인 하에 수행** (백엔드 5회, PC 웹 5회, APK 릴리스 2회).
> ⚠ **이 세션 내내 다른 세션이 같은 repo 3곳을 병행 작업했다** — 아래 §주의 2 참조.

## 완료

### 1. 없는 기능 광고 제거 (앱 + PC 웹)
- [x] 앱: 프로필 메뉴 **'알고리즘'**(Engine 6카테고리·Tier 1~6·SPLIT/BURST 산식)과
      **'데이터 가져오기'**(파일 첫 줄에 "가상 UI" 라고 적힌 BTWB/Wodify 껍데기) 행 삭제.
      코치 상세 **'PT 예약'** 죽은 버튼 제외. 코치 대시보드의 '부상 메모·목표 기록은
      준비 중' 기본 안내 → 할 말 있을 때만 노출.
- [x] 앱 FAQ 전면 현행화 — 박스 찾기→가입 코드→가입 신청, `Profile/Classes/Attend`
      영문 경로 → 실제 한글 화면, 'Tier·Engine 점수' 문답 폐기 → **'내 레벨은 어떻게
      정해지나요'**(경력 3단).
- [x] PC 랜딩: **'페이싱 엔진' 서사 통째 삭제**(hero·meta 2곳·Split/Burst 섹션·.edge CSS).
      기능 태그 `Owner` → `Coach`.
- [x] PC 온보딩: **'카카오 알림톡 8 템플릿' 카드 삭제**(발신 프로필 없어 한 통도 못 나감).
- [x] 약관·개인정보: '페이싱 계산'·'Engine 점수·Tier' 삭제, 수집 항목을 실제 값으로 정정.
      표기 통일 — 박스 운영자·이용자·사장 → **코치·회원** (GLOSSARY).
- [x] `_layout`: D18 **박스 스위처 삭제**(1인 샵 · role 값 노출 자리였음).
- [x] `member_detail`: **'앱 연결 코드' 발급 버튼·모달 삭제**.

### 2. 가입 코드 전면 폐기 → 가입은 신청·승인 한 길 (D38)
- [x] 앱 진입점·PC 발급 창구·백엔드 API 까지 3면 동시 폐기. 남은 길은 하나 —
      **회원이 앱에서 신청 → 코치가 PC '가입 관리'에서 승인**.
- [x] 운영 검증: `claim-code` API 가 **404**(폐기 확인), 승인 API `PATCH .../status` 는
      **401**(생존). 인계장이 지목했던 "앞면만 배포된 기능"(승인 버튼 404) 해소.

### 3. 가입 신청서 확대 + 승인 전 앱 전체 차단 (v2.8)
- [x] **승인 대기 게이트** — `main_shell` 입구에서 `membership.isPending` 이면 셸 전체를
      '승인 대기중입니다' 화면으로 대체. 탭마다 막으면 빠뜨리므로 한 곳에서 막는다.
      **로그아웃 버튼 유지**(없으면 승인 전까지 앱에 갇힘).
- [x] **신청서가 받는 값 7종** — 이름·생년월일·성별·연락처·크로스핏 경력(3단)·
      해온 종목(선택)·부상 이력/주의사항(선택). 생년월일·전화 자동 하이픈.
      경력 고르면 내 레벨(SCALED/RXD/ELITE) 즉시 표시.
- [x] 신청서가 다 받으므로 직후 **'내 정보' 단계 생략** → 곧바로 셸(=대기 화면).
- [x] 경력 구간 상수를 **`Tier.bands`** 로 일원화 (신청서·프로필 수정이 각자 들고 있었음).

### 4. 값이 코치 PC 로 흐르는 경로 (사용자 지시로 2회 조정)
- [x] **표에서 한눈에**: 회원 목록 칸 = 이름·성별·생년·전화·레벨·**경력**·회원권·시작·종료·D-day·상태.
- [x] **이름 아래 배너**: 부상 이력·주의사항(`safety_note`) — 값 있을 때만.
- [x] **메모**: 코치가 직접 적는 내용(`note`) — 신청서 값과 분리.
- [x] `sports_history` **DB 컬럼 신설**(gym_member_profiles) + 마이그레이션 + 회원 수정 창 입력칸.
      처음엔 note 에 섞었다가 "메모 배지로만 보인다"는 지적으로 제 칸으로 분리.

### 5. 계정·배포·릴리스
- [x] **코치 계정 `COACH` / `1234`** 부팅 시드에 추가 (role `coach`, 대표 박스 HYPHEN).
      권한은 boss 와 동일 (`api/roles.py` STAFF_ROLES — 역할로 가르지 않음).
- [x] **로그인 아이디 대소문자 무시** — `coach`·`COACH`·`Coach` 모두 통과. 비밀번호는 구분.
- [x] **뉴비 흐름 E2E 실검증** — 앱 경로로 신청 → 코치 PC 목록에 이름·연락처·시각 도착 확인.
      테스트 행은 hard delete 로 정리 완료.
- [x] **APK 릴리스 2회** — v1.0.0-3002, **v1.0.0-3004**(현재 최신). 설치 페이지
      `https://minjunbyeon-netizen.github.io/app-facing/` 표기를 **HYPHEN** 으로 통일.
- [x] 골든 3장 추가(가입 신청 2 + 승인 대기 1), 진입점 없는 가입 코드 골든 삭제 → **22장**.
      골든 시각 흔들림 원인 제거(가짜 수업 시각을 now+N분 → 20:00/21:00 고정).

## 진행중

없음. 세 repo 모두 커밋·푸시·배포 완료 상태.

## 대기

- [ ] **새 APK(3004)로 실기 검증** — 가입 신청 → 승인 대기 화면 → 코치 승인 → 열림.
      표의 '경력' 칸에 값이 차는 것은 **3004 로 가입한 회원부터**다 (기존 행은 `—`).
- [ ] **가입 관리 표에 경력·부상 요약 한 줄** — 코치가 회원 상세를 안 열고 승인 판단.
- [ ] **골든 날짜 흔들림 근본 해결** — 주간 보드가 날짜 기준이라 날이 바뀌면 통째로
      달라진다. `package:clock` 도입해 `DateTime.now()` **47곳(26파일)** 교체 필요. 별건.
- [ ] `applyPersonaSnapshot()` 이름 잔재 · `button_lint_test.dart` 신설 · `_kShowSocialLogin=false`.

## 결정사항 / 주의

1. **가입 경로는 하나다** — 앱 신청 → PC 승인. 가입 코드는 3면에서 폐기됐다.
   백엔드 `api/claim.py` 파일은 남아 있으나 라우트가 없어 실질 폐기.
2. **다른 세션이 같은 repo 3곳을 병행 작업했다.** 이 세션은 충돌을 피해
   *그쪽이 만지는 파일을 건드리지 않는* 방식으로 일했다 (`self_signup_screen.dart`
   초기 편집분, `members_join.html`, 전 템플릿 인라인 스타일 스윕 등).
   **다음 세션도 작업 전 `git status` 로 남의 dirty 파일부터 확인할 것.**
3. **`railway up` 은 커밋이 아니라 작업 폴더를 통째로 올린다.** 남의 미완성 파일이
   섞여 올라간다. 이 세션은 배포 직전 **템플릿 파싱 + 디자인 린트**를 돌려
   깨진 상태가 아님을 확인하고 진행했다. 같은 절차를 유지할 것.
4. **배포 순서는 의존 방향으로**: 기능을 *추가*하면 백엔드 먼저, *제거*하면 웹 먼저.
   (승인 API 추가 = 백엔드 먼저 / 가입 코드 삭제 = 웹 먼저)
5. **'운동' 은 copy lint 금지 용어** — `해온 종목` 으로 썼다. `flutter test` 가 잡는다.
6. **"숨김 = 코드 보존"** 유지. 진입점만 끊고 화면 파일은 남긴다
   (`algorithm_screen`·`import_screen`·`_PtBookCard`·`gym_search_screen`·`/wod`).
7. **골든 규칙**: 진입점 없는 화면은 골든에서 뺀다. UI 를 바꾸면 골든 재생성 +
   갤러리 갱신이 완료 조건 (`python tool/golden_gallery.py` 가 양방향 검출).
8. 이 repo 에서 **`dart format` 금지** (옛 SDK 포맷 — 대량 재포맷).
9. auto-save 훅이 중간 커밋을 만든다. 코드는 HEAD 에 정상.

## 관련 파일

| 경로 | 역할 |
|---|---|
| `lib/features/shell/main_shell.dart` | **승인 대기 게이트** (`_PendingGate`) |
| `lib/features/signup/self_signup_screen.dart` | 가입 신청서 7항목 |
| `lib/core/tier.dart` | `Tier.bands` 경력 구간 SSOT · `fromExperienceYears` |
| `lib/core/input_formatters.dart` | 생년월일·전화 자동 하이픈 SSOT |
| `lib/features/mypage/faq_screen.dart` | 현행화된 FAQ |
| `test/golden/states_golden_test.dart` | `state_05_pending` 승인 대기 골든 |
| `tool/golden_gallery.py` | 갤러리 SECTIONS (22장) |
| `services/facing/models/base.py` | `seed_gym_managers` (COACH 시드) · sports_history 마이그레이션 |
| `services/facing/api/admin.py` | `member_self_signup`(확장 수신) · 대소문자 무시 로그인 · 목록 응답 |
| `services/facing/api/roles.py` | 권한 정본 — boss=manager=coach |
| `web/facing-admin/templates/members.html` | 회원 목록 **'경력' 칸** |
| `web/facing-admin/templates/member_detail.html` | 이름 줄 요약 + **부상 배너** |
| `web/facing-admin/templates/_member_form_fields.html` | 경력 입력칸 |
| `apps/facing-app/docs/GLOSSARY.md` | 표기 SSOT (역할 3종·금지 표기) |

## 로컬 실행 메모

```
빌드     flutter build apk --release --dart-define=API_BASE_URL=https://service-facing-production.up.railway.app
릴리스   gh release create v1.0.0-XXXX <apk> --title "HYPHEN 1.0.0 (XXXX)" --notes-file <md> --latest
골든     flutter test --update-goldens test/golden && python tool/golden_gallery.py
배포     cd C:/dev/services/facing && railway up --detach   (웹은 C:/dev/web/facing-admin)
검사     python design/lint.py (웹) · python -m pytest tests -q -s -p no:cacheprovider (백엔드)
```
운영: PC 웹 `https://web-facing-admin-production-dca4.up.railway.app` ·
백엔드 `https://service-facing-production.up.railway.app` ·
APK 설치 `https://minjunbyeon-netizen.github.io/app-facing/` (현재 v1.0.0-3004).
코치 로그인 = `coach` / `1234`.

## 다음 세션 권장 첫 프롬프트

`/resume` → 새 APK(3004) 설치 후 가입 신청 → 승인 대기 → 코치 승인 흐름 실기 검증부터.
