# HANDOFF - 2026-08-25 12:55

## 다음 세션 1순위 — 로그인 통합 (사용자 강한 지시, 미착수)

> 2026-08-25 12:54 사용자 지시 원문 요지. 메모리 SSOT = `project-single-login-entry`.

1. **'코치 로그인' 별도 진입을 없앤다.** 로그인 창구는 하나. 사람이 자기 역할을 골라
   들어가는 구조 자체가 틀렸다.
2. **로그인 화면에서 HYPHEN 로고(BrandLogo)를 없앤다.**
3. **그냥 로그인하면 계정 유형대로 화면이 갈린다** — 아이디가 코치면 코치 화면,
   회원이면 회원 화면. 판정은 서버가 한다.

### 착수 좌표 (조사해 둔 것 — 바로 이어가면 됨)
- 로그인 랜딩의 '코치 로그인' 줄 = `lib/features/auth/signup_screen.dart:254`
- 코치 로그인 화면 = `lib/features/boss/boss_login_screen.dart` (h1 '코치 로그인' = :124)
- 회원 로그인 화면 = `lib/features/auth/member_login_screen.dart`
- BrandLogo 노출 = 위 두 로그인 화면 + `signup_screen.dart` (스플래시·인트로는 지시 대상 아님)
- 현재 인증 경로 2개:
  - 회원 `POST /api/v1/auth/member-login` → device_id 채택(`DeviceIdService.adopt`) → `/shell`
  - 코치 `POST /api/v1/admin/login` → 세션 쿠키 + `BossAuthState.save` → `/boss/dashboard`

### 통합 방식 2안 (결정 필요 — 사용자에게 물을 것)
- **A안 (앱만 수정, 백엔드 0)**: admin/login 먼저 → 실패면 member-login 재시도 → 성공한 쪽으로 라우팅.
  함정: 로그인 rate limit(Flask-Limiter) 한도를 2배로 소모, 429 응답이 HTML 이라 파싱 주의.
- **B안 (백엔드 통합 엔드포인트)**: `POST /api/v1/auth/login` 신설 — login_id 로 GymManager/회원
  어느 쪽 계정인지 판정해 `kind: coach|member` + 각자 payload 반환. 앱은 1회 호출. 서버 회귀 필요.
  (권장 — 재시도 없음·rate limit 정상·판정 책임이 서버에 있음)

### 같이 손봐야 하는 것
- `RememberedLogin` scope 2칸(member/coach) 구조 재검토 — 창구가 하나면 한 칸으로 합칠지 결정
- 골든 재생성: `boss_01_login` · `common_08_member_login` · `state_09_login_remembered` ·
  `common_05_signup`(로고 포함) + `tool/golden_gallery.py` SECTIONS + `CLAUDE.md` 장수(현재 61장) 동기화
- `CLAUDE.md` 카피 템플릿의 로그인 행("Splash / 로그인 / 전면 로딩 = BrandLogo") 수정
- flutter analyze · 전체 테스트(현재 198) · copy_lint·button_lint·clock_lint 게이트
- APK 재빌드 + 갤S22 설치·실기 확인 (adb `192.168.1.101:5555`, 데모 계정 admin/1234)

## 완료 (이 세션)
- [x] **회원권 정지 시 뒤 회원권 겹침 수정** (서버 1040400) — 갱신은 '앞 만료일+1' 체이닝 별도 행이라
  정지가 앞 회원권 만료일만 밀어 뒤 회원권 기간을 덮어썼다. `_shift_following_memberships()` 신설
  (정지=+계획일수, 해제=실제-계획 차액). PC 는 이동 건수 토스트 + 모달 안내
- [x] **자기반박 2건 처리** (서버 521e068) — 이동 대상을 '이동 전 만료일을 **넘겨** 시작' 으로 좁힘
  (동시 진행 회원권 보호) + 잔존 겹침 `overlaps` 보고(응답·SSE·audit, PC 경고 토스트) +
  연장(extend) 경로에도 같은 규약
- [x] **표기 한글화 2건** — 코치 설정 요금제(`time_based`·`-d`·`200000₩` → `630,000원 · 90일 · 기간제`,
  앱 `core/plan_labels.dart` 정본) · 계약 상세 항목 이름(서버 `variable_labels` 동봉,
  rename `PREVIEW_PLACEHOLDERS → VARIABLE_LABELS`, 문구 박스→체육관)
- [x] **로그인 '아이디 기억하기 (30일)'** (앱 5c6299f) — `core/remembered_login.dart`(아이디만 저장,
  비밀번호 저장 안 함, 30일 만료, 회원/코치 칸 분리) + HKit `HkCheckRow` 신설.
  ⚠ **위 1순위 지시로 구조가 바뀔 수 있음**
- [x] 배포: 서버·관리자 웹 `railway up` 2회 전부 SUCCESS · health/login 200 · 신빌드 마커 확인
- [x] 갤S22 릴리즈 APK 재빌드·설치 3회 + 실기 검증 (요금제 한글 표기 · 아이디 기억 왕복)
- [x] 갭대장 15차 처리 이력 · 골든 61장(member_22·boss_09·state_09 신규)

## 대기
- [ ] (보고만, 이월) 회원권 **직접 수정**으로 만료일을 늘릴 때는 동반 이동·겹침 경고 없음
- [ ] (보고만, 이월) 폰 요금제 생성 시트가 `plan_type='time_based'` 하드코딩 — 횟수제 요금제를 폰에서 못 만듦
- [ ] (보고만, 이월) 회원 예약 원시 타임라인 / 90일+ 출석 누적 없음
- [ ] 계약 항목 한글 라벨은 서버 사전에 있는 키만 — 체육관 커스텀 변수는 여전히 raw 키

## 결정사항 / 주의
- **로그인 창구는 하나** (위 1순위) — 역할별 입구·역할 선택 UI 신설 금지. 메모리 `project-single-login-entry`
- 정지 이동 규약: 대상 = '이동 전 만료일을 넘겨 시작하는 같은 회원 active 행'. 같은 날 시작 행은
  안 옮기고 `overlaps` 로 보고만 (동시 진행 PT 권 보호)
- 아이디 기억은 **아이디만** — 비밀번호 저장 금지 (폰 분실 시 계정 이전)
- 앱 시각 접근은 `appClock.now()` 만 — `DateTime.now()` 는 `test/clock_lint_test.dart` 가 차단
- pytest 는 `python -m pytest tests` (bare pytest = _archive 수집 에러)
- hyphen 배포는 `railway up` 수동 (push ≠ 배포). 프로드 gym_id=2 실데이터 오염 금지
- 프로드 회원권 겹침 실데이터 없음 (member id=4, 회원권 0건) — 보정 작업 불필요

## 다음 세션 권장 첫 프롬프트
`/resume` → 로그인 통합 (A안/B안 결정부터)
