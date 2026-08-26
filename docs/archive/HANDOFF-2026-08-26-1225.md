# HANDOFF - 2026-08-26 12:25

## 완료 (이 세션)
- [x] 인계장(8/26 11:24) 대기 1~5 전부 실행 — **S1~S4 수정 → 테스트 → 배포 → 에뮬 재주행 → 보고서 같은 URL 재발행**.
  보고서: https://claude.ai/code/artifact/02ec5800-def2-4903-b286-34622bbae768 (2차 캡처 = `C:\dev\project\hyphen-journey-2026-08-26\after\*.png`, 빌더 `build_report_v2.py`, dev-root 커밋 9ee2a78).
- [x] S1 앱: `lib/core/device_id.dart reset()` · `AuthState.signOut` · `coach_shell._logout` 이 device_id 새 UUID + `GymState.resetLocal()` (로그아웃 4경로). 서버: self-signup 같은 기기·다른 아이디 → `DEVICE_BOUND_TO_OTHER_ACCOUNT` 409 (`api/admin.py`).
  후속 2건: 로그아웃 다이얼로그 문구(기기 연결 해제) · 신청 직후 `GymState.loadMine()` (안 하면 '체육관 미가입' 표시 — member4 로 '승인 대기' 재검증).
- [x] S2: 회원 주간 목록 reserved_count attended 포함 + **동종 3곳** (명단 시트 confirmed_count `classes.py:967` · 대시보드 오늘 예약 `admin.py:3217` · 오늘 수업 인원 `admin.py:3289`).
- [x] S3: `PATCH /admin/reservations/<id>/status` 시작 전 attended·no_show → `CLASS_NOT_STARTED` 409 · 폰 명단 시트 `_notStarted` 배지 잠금 + '출석 체크는 수업 시작 후'. 골든 `state_10_roster_before_start` 신규 · `boss_03` fake 09:00 이동 (55장).
- [x] S4: `coach_note._profile_display` 폴백 = 체육관 대표 스태프(boss 우선·재직) 이름 → 체육관 이름. 프로드 owner_hash 무관.
- [x] 게이트: 서버 229 passed 1 skipped (+9) · 앱 195건 · 골든 55장. `railway up` 2회(11:44 KST 부팅·/health 200). 릴리즈 APK(prod URL) 갤S22 설치. 브리프 D52 · 갭대장 18차 · 이름사전 2행 · CLAUDE.md 골든 55장. 커밋: 앱 ed8418c·f4f4c28·071e0ec · 서버 912946b·35638d7.

## 진행중
- [ ] 없음 — 아래 대기 착수 전 인계 (컨텍스트 99%).

## 대기 (사용자 결정 2026-08-26 11:59 — "회원권 없으면 예약·대기 당연히 안 된다. 2번은 하고")
1. [ ] **S5 회원권 게이트 (결정: 차단, 무료 제공 없음)** — 서버 `api/classes.py` 예약 POST(520)·재활성·대기 신청 3진입로에 `_daily_limit_blocked` 와 같은 자리로 **한 곳** 게이트 (`_membership_blocked` 식). 유효 = 오늘(KST)이 active 회원권 기간 안 + 일시정지 아님 (모델 `models/gym_membership.py`, 정지 판정은 앱 `Membership.isPausedNow` 와 같은 규칙). 에러 코드 신설 → 이름사전 등재. 대기 승격(`_promote_waitlist`)도 재검사. 폰: `class_line.dart` 예약 버튼 회원권 없을 때 '회원권 필요' 상태 + 스낵바. 회귀 `tests/test_reservation_policy.py` + 골든 상태 1장. 브리프 D53 · 갭대장 19차.
2. [ ] **S8** 서버 문구 금지어 8곳 ('박스 없음.' 등 → 체육관) — `api/admin.py:807,1568,1588,2103,2161,2394` · `api/coach_note.py:680,703`. 테스트 문구 assert 도 같이 grep.
3. [ ] **S10** 코치 로그아웃 확인 다이얼로그 (`coach_shell.dart _logout` — 회원 `HkDialog.confirm` 과 같은 골격) · 명단 시트 코치 표기 'admin'(login_id) → 이름 (서버 `admin_list_class_reservations` 에 coach_name 동봉 또는 앱 매핑).
4. [ ] 수정 후: 앱 `flutter test` · 서버 pytest · 골든 갱신 · `railway up` · 에뮬 재주행(아래 절차) · 보고서 재발행(`build_report_v2.py` — after2/ 폴더 추가하는 식).

## 보고만 (지시 없음)
- S6 가입 폼 BACK 입력 소실 · S7 시각만 지난 open 수업 '예약' 버튼 활성 · S9 가입 대상 체육관 이름/id 하드코딩 · S11 검증환경.
- 자기 반박 미해결: 코치 로그아웃 device 리셋으로 `gym_manager_devices` 행 누적 · 시작 전 판정 앱=기기 시각/서버=KST (TZ 다르면 어긋남) · 쪽지 발신자는 공용 해시라 개별 코치명 불가(발신 스태프 컬럼 없음).
- 사용자 지적: "S5 정책 결정" 을 추천 1번에 올린 것이 허용 권고처럼 읽혔음 — 갭 보고 시 "막을까요" 를 추천 자리에 두지 말 것.

## 에뮬 재주행 절차 (검증된 순서)
1. `services/hyphen`: `PORT=5060 python app.py > _run.out 2> _run.err &` (좀비 `netstat -ano | grep :5060`).
2. 앱: `flutter build apk --debug` → `adb -s emulator-5554 uninstall com.netizen.hyphen.hyphen_app` → install. **에뮬 시계 UTC → `adb shell cmd alarm set-timezone Asia/Seoul`** 후 앱 재시작 (안 하면 KST 수업이 '시작 전').
3. 로컬 DB: gym 1 'HYPHEN' · member/1234(id1) · member2/1234(id2, device 'emu-member2-device') · **member3(id3)·member4(id4) pending 잔존** · 코치 admin/1234(boss 'Demo Admin') · 수업 55(8/26 20:00 EVENING RX, member 확정)·56(8/26 11:30 NOON RX, 1·2 출석) 이 세션 삽입분.
4. 조작 `adb shell input tap/text` + `exec-out screencap` (ASCII 만). 첫 실행 알림 권한 팝업 Allow (540,1303). 가입 폼은 키보드 닫은 뒤(keyevent 4) 스크롤·재캡처 후 좌표 잡을 것 (경력 선택 시 레벨 칩이 생겨 아래가 밀림).
5. 요청 확인 `_run.err` grep.

## 결정사항 / 주의
- 프로드 접촉: /health GET 만. 프로드 gym 2 실데이터 오염 금지 유지.
- 로컬 서버·에뮬 앱 종료 상태(리스너 0). 에뮬레이터는 켜 둠. 갤S22 adb-tls 연결·릴리즈 APK 설치됨 (프로드 읽기 전용 재검증 가능).
- 제1원칙(기능 추가 금지·갭은 보고) 유지 — S5 는 사용자 결정으로 예외 승인됨.

## 다음 세션 권장 첫 프롬프트
`/resume` → 대기 1~4 순서대로 (S5 차단·S8·S10 은 지시 완료 — 추가 확인 불필요)
