# HANDOFF - 2026-08-26 11:24

## 완료 (이 세션)
- [x] 인계장(8/25 23:15) archive 이동 · 자동 게이트 실행 — 앱 `flutter test` 194건 전건 통과(골든 54장 포함) · 서버 `python -m pytest tests` 220 passed 1 skipped.
- [x] **로컬 서버 + 에뮬레이터(emulator-5554) 로 회원 1바퀴 · 코치 1바퀴 실주행** — 캡처 37장 보고서
  아티팩트: https://claude.ai/code/artifact/02ec5800-def2-4903-b286-34622bbae768
  (캡처 원본 사본 = `C:\dev\project\hyphen-journey-2026-08-26\*.png`)
- [x] 통과 흐름 10개: 한 창구 로그인 역할 판정 · 예약→취소→재예약 · 종료 수업 예약 차단 · 홈 XP/업적 ·
  회원권 D-83 · 가입 신청 제출(201) · 코치 승인 · 명단·출석 · 새 쪽지→회원 수신→답장 · 만석 대기 등록→대기 취소.
- [x] 코드 변경 0 (제1원칙 — 갭은 보고). 레포 커밋은 archive 이동 1건(663b124)뿐.

## 진행중
- [ ] **사용자 지시 "1 하고 다시보고"** = 아래 대기 1~4 수정 → 앱·서버 테스트 → 배포(railway up · APK) → 에뮬 재주행 → 보고서 갱신.
  컨텍스트 99% 경고로 착수 직전 인계. 중단 지점 = 수정 0건 착수 전.

## 대기 (지시 받은 순서 — "1" 선택분)
1. [ ] **치명 S1** 로그아웃 뒤 같은 폰 가입 신청이 기존 승인 회원에 붙음
   - 앱: `lib/core/device_id.dart:35 adopt()` 는 있는데 초기화(reset) 가 없음. 회원 로그아웃(`lib/features/mypage/mypage_screen.dart` 로그아웃 핸들러)과
     코치 로그아웃(`lib/features/shell/coach_shell.dart:85 _logout`)에서 device_id 를 새 UUID 로 되돌릴 것 (SharedPreferences `device_id` 키).
   - 서버: `services/hyphen/api/admin.py:843` "같은 device + 박스 중복 가입 방지" 분기가 **다른 login_id** 로 들어온 신청까지 기존 행에 `_upsert_credential` — 
     기존 행의 자격증명 login_id 와 다르면 새 회원 행으로 분기하거나 409 로 막을 것. 재현: member 로그인→로그아웃→member2 신청 → DB 새 gym_members 행 없음.
2. [ ] **버그 S2** `services/hyphen/api/classes.py:1206` 회원 주간 목록 reserved_count 가 `status == "confirmed"` 만 — 485·395행처럼 `in_(("confirmed","attended"))` 로.
3. [ ] **버그 S3** 수업 시작 전 출석 체크 통과 — `PATCH /api/v1/admin/reservations/<id>/status` 에 start_at 이전이면 attended/no_show 거부(409) + 폰 명단 시트 버튼 잠금.
4. [ ] **정합 S4** 쪽지 발신자 'facing' — 코치 쪽지 sender_hash 가 HQ 시드 `seeds/seed_hq_gym.py:22 OFFICIAL_HQ_OWNER_HASH="facing_official_owner_…"`.
   `api/coach_note.py:128 _profile_display` 가 프로필 없으면 해시 조각을 이름으로 씀 → 코치는 GymManager.name 으로 표시. 프로드 gym 2 owner_hash 확인.
5. [ ] 수정 후: 앱 `flutter test` · 서버 `python -m pytest tests` · 골든 갱신 시 `--update-goldens` + `python tool/golden_gallery.py` · 서버 `railway up`(services/hyphen) ·
   에뮬 재주행(아래 절차) · 보고서 아티팩트 같은 URL 로 재발행(`C:devprojecthyphen-journey-2026-08-26build_report.py` 재사용 (shots.json 은 캡처 PNG 에서 재생성)).

## 보고만 (지시 없으면 손대지 않음)
- S5 회원권 없는 회원도 예약·대기 가능 (`api/classes.py:520` 예약 POST 에 회원권 게이트 없음) — 정책 결정 필요
- S6 가입 폼 BACK 한 번에 입력 소실 (`lib/features/signup/self_signup_screen.dart`) — 확인 다이얼로그 없음
- S7 시각만 지난 open 수업에 '예약' 버튼 활성 (`lib/features/classes/class_line.dart`) — 탭 후 서버 차단 스낵바
- S8 서버 문구 '박스 없음.' 등 금지어 8곳 폰 노출 (`api/admin.py:807,1568,1588,2103,2161,2394` · `api/coach_note.py:680,703`)
- S9 가입 대상 체육관을 이름 'HYPHEN' / 폴백 id 2 하드코딩 (`self_signup_screen.dart:78-93`)
- S10 코치 로그아웃 확인 없음(회원은 다이얼로그) · 명단 시트 코치 표기 'admin'(login_id)
- S11 검증 환경: 에뮬에 릴리즈 서명 APK 남으면 `adb install -r` 디버그 조용히 실패 → 프로드에 붙은 채 테스트됨. 반드시 `adb uninstall` 후 설치.

## 에뮬 재주행 절차 (이 세션에서 검증된 순서)
1. `services/hyphen`: `PORT=5060 python app.py` (좀비 확인 `netstat -ano | grep :5060`) · `web/facing-admin`: `python app.py` (8081, 리로더 자식 1개 더 뜸)
2. 앱: `flutter build apk --debug` → `adb -s emulator-5554 uninstall com.netizen.hyphen.hyphen_app` → `adb install build/app/outputs/flutter-apk/app-debug.apk`
3. 로컬 DB(`data/hyphen.db`) 상태: gym 1 이름 'HYPHEN'(이 세션에서 'HYPHEN HQ'→변경, 앱 가입 판정 상수와 일치) · 회원 member/1234(id 1, 승인, 회원권 有) ·
   member2/1234(id 2, 승인, 회원권 無, device 'emu-member2-device') · 코치 admin/1234 · 수업 8(금 06:00) 정원 12 복원됨 · 예약 4 = member attended.
4. 조작은 `adb shell input tap/text` + `exec-out screencap` (한글 입력 불가 — ASCII 만). 첫 실행은 알림 권한 팝업이 탭을 먹으니 6초 대기 후 캡처로 확인.
5. 서버 요청 확인은 `_run.err` 의 werkzeug 줄 (HTTP/1.0 도 있으니 "GET \|POST " 로 grep).

## 결정사항 / 주의
- 프로드 접촉: 실패 로그인 3회(401)만 — 쓰기 없음. 프로드 gym_id=2 실데이터 오염 금지 유지.
- 로컬 서버·PC 웹은 세션 말미에 전부 종료(리스너 0). 에뮬레이터는 켜 둠.
- 골든 54장 · 앱 시각 `appClock.now()` · 배포 `railway up` 수동 · 제1원칙(기능 추가 금지) 유지.
- 갤S22 adb-tls 연결돼 있음(`adb devices` 2줄). 실기 재검증은 프로드 읽기 전용으로.

## 다음 세션 권장 첫 프롬프트
`/resume` → 대기 1~5 순서대로 실행 (사용자 "1 하고 다시보고" 지시 이미 받음 — 추가 확인 불필요)
