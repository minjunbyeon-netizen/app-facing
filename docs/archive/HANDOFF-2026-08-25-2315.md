# HANDOFF - 2026-08-25 23:15

## 완료 (이 세션 — 앱 v3.19~v3.28 · 서버 6커밋 · 관리자 웹 1커밋, 전부 배포·갤S22 실기 확인)

### 로그인·인증
- [x] **로그인 창구 통합** (브리프 D42) — `POST /api/v1/auth/login` 이 `kind: coach|member` 판정.
  앱 `lib/features/auth/login_screen.dart` 한 화면, 로고 없음, '코치 로그인' 별도 입구·BossLoginScreen 삭제.
  아이디 대소문자 무시 양쪽 통일(`models/member_credential.find_credential`). 진입 화면 로고도 제거.
  구 창구 2개(`/admin/login`·`/auth/member-login`)는 PC·구 APK 용 유지.
- [x] **코치 다중 기기 페어링** (D50) — 서버 `gym_manager_devices` 표 + `roles.staff_rows_for_device()` 단일 판정
  (is_staff_device·SSE·gym.py 폴백 2곳·classes.py 수업 조회 5곳 통일). 에뮬 로그인 뒤 갤S22 유지 실기 확인.

### 폰 코치 축소 (D43·D44·D45·D51)
- [x] 폰 코치가 하는 것 = **예약 현황(주간 수업/예약·인원·명단·출석/노쇼) · 가입 신청 승인 · 쪽지** 뿐.
  삭제: 수업 내용 게시/삭제 · 수업 등록/수정/취소 · 회원 명단/통계/상세 · 코치 노트 · 회원 요청 ·
  만료 임박 · 체육관 프로필 수정 · 요금제 탭 · 설정 화면 전체(알림·예약 한도 → PC) ·
  **자동 가입 승인 기능 자체 폐기(서버 포함)** · 코치 '수업' 탭(회원 주간보드 재사용).
  목록·복원 좌표 = `README.md §제거된 기능 대장 15~21`.
- [x] **코치 앱 2탭** — `lib/features/shell/coach_shell.dart` (예약 현황 · 쪽지).
  주간 예약 현황 = `lib/features/boss/coach_week_classes.dart` (코치 세션 API `GET /admin/gyms/<id>/classes`,
  `BossApiClient.getList` 신설). 회원 화면의 코치 분기(isOwner) 전부 제거.
- [x] **쪽지 단순화** — '그룹' 삭제, '새 쪽지' = `lib/features/inbox/new_note_screen.dart`
  (내 회원 목록 → 탭 → `ChatThreadScreen` 에서 입력·전송). 구 작성 화면·그룹 화면·그룹 모델 삭제.
  API 그대로(`POST /gym/<id>/notes` individual·note) — PC 쪽지함 연동 유지.

### 앱 UI 골격 SSOT (D46~D50)
- [x] 상단바 = `HkAppBar`/`.identity`(회원·코치 셸 하나) · 다이얼로그 `HkDialog` · 시트 `HkSheet` · 탭바 `HkTabBar` ·
  버튼 `HkButton`(원시 버튼 0) · 카드 `HkCard`(radius/borderColor/clip/width 슬롯) · 섹션라벨/스피너/빈상태/통계타일 ·
  입력칸 스타일 테마 1벌 · 날짜함수 `core/time_format.dart` · 수업 줄 `classes/class_line.dart`(.coach/.member) ·
  대기화면 `gym/membership_status_view.dart` · 공지 행 `announcements/announcement_row.dart`.
- [x] 게이트 `test/ssot_lint_test.dart` 10패턴 + `button_lint_test.dart` baseline 빈 집합.
- [x] 잔존(카드 아님·보고만): 업적·칭호 왼쪽 색띠, 코치 사진 원형, 채팅 말풍선, 주간보드 요일 타일,
  `hyphen_pictogram.dart` hex 32개(픽토그램 팔레트), `history_detail._formatDate` 1개.

### 서버 갭 처리
- [x] 정원 증가 시 대기 자동 승격 — `api/classes._promote_waitlist()` 한 곳(취소·정원 변경 공유). 갭대장 16차.
- [x] 회원권 직접 수정도 동반 이동·겹침 보고 — `admin_edit_membership` + PC member_detail 토스트. 갭대장 17차.

## 진행중
- 없음 (전부 커밋·푸시·배포 완료. 마지막 앱 커밋 ca3f221 verify / ec8c439 app · 서버 마지막 배포 = 회원권 직접 수정 커밋)

## 대기 (지시 시)
- [ ] 회원 쪽지 화면도 코치와 같은 식으로 단순화 점검 (제안만)
- [ ] PC 요금제 화면 횟수제 지원 여부 점검 (폰 요금제 탭은 삭제돼 폰 이월 항목 해당 없음)
- [ ] 회원 예약 원시 타임라인 / 90일+ 출석 누적 (기능 추가 성격 — 제1원칙상 지시 대기)
- [ ] 계약 항목 한글 라벨은 서버 사전 키만 — 체육관 커스텀 변수는 raw 키

## 결정사항 / 주의
- **정본(SSOT)은 부품이지 화면이 아니다** — 역할별 화면 조립은 달라도 됨. 한 위젯 안 `isOwner` 분기 = 이원화 (D51).
- **로그인 창구 하나·역할 판정은 서버** (메모리 `project-single-login-entry`). 역할 선택 UI·로고 재도입 금지.
- 폰 코치는 "오늘 돌리는 것"만 — 만들기·고치기·들여다보기는 PC (D44·D45). 되살리기 전 사용자 확인.
- 자동 가입 승인 기능은 서버까지 폐기 — `GymProfile.auto_approve_joins` 휴면 컬럼, 되살리지 말 것.
- 코치 기기 페어링은 표 기반 N개. `GymManager.device_hash` 는 '마지막 로그인' 표시용(PC 쪽지함 신원) — 판정 근거로 쓰지 말 것.
- 골든 54장 (`CLAUDE.md` 장수 서술 동기). 골든은 `flutter test --update-goldens test/golden` 후 `python tool/golden_gallery.py`.
- 앱 시각은 `appClock.now()` 만 · pytest 는 `python -m pytest tests` · 배포는 `railway up` 수동 (서버·관리자 웹 각 폴더).
- 프로드 gym_id=2 실데이터 오염 금지 — 검증은 골든·테스트·에뮬(로컬/프로드 읽기) 우선.
- 갤S22 adb `192.168.1.101:5555` (끊기면 `adb connect`), 데모 계정 admin/1234. 에뮬 `emulator-5554` 에도 같은 계정 로그인돼 있음.
- 서버 SSOT: `services/hyphen/docs/SSOT/대차대조표.md` 부록 4·5, `갭대장.md` 16·17차.

## 다음 세션 권장 첫 프롬프트
`/resume`
