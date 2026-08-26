# HANDOFF - 2026-08-26 18:03

## 완료 (이 세션 — 16:18~18:03)
- [x] 인계장(16:05) archive 이동 · 회원권 발급 → 예약 흐름 3면 실주행 확인 (member2, 기간제 — 캡처 `C:\dev\project\hyphen-journey-2026-08-26\membership\00~13`).
- [x] **D57 횟수권 신설 (사용자 지시 "3회 9,900 이벤트" + 차감 규칙)** — 3면 커밋·푸시·배포 완료:
  - 서버 `ed461ee` — `api/_membership.py`(정본: pick_membership · recompute_session_charges · session_summary · LATE_CANCEL_MINUTES=20 · FREE_NO_SHOWS=1 · FREE_LATE_CANCELS=1), `gym_memberships.session_total` + `class_reservations.membership_id/late_cancel/session_charged`, 마이그레이션 `_migrate_session_pass_columns`(**`_migrate_class_tables` 뒤에** — 앞이면 표 재생성으로 컬럼 소실), 게이트 `classes._membership_blocked` → `(err, pass_id)`, 취소 응답 `late_cancel·session_charged·message`, 폰/PC 응답 session_* 7필드, PC 요금제 어댑터 `session_count`. `tests/test_session_pass.py` 10건 — 257 passed 1 skipped. `railway up` 17:42 부팅.
  - PC 웹 `3342d3e` — settings_plans 횟수 칸·열 · member_detail 발급/수정 모달 횟수·이력 "1/3회 사용 · 잔여 · 면제" · members 잔여. `railway up` 완료(200).
  - 앱 `abb3100`·`ec0677f`·`c15e455` — `Membership.isSessionPass/sessionRemaining` · `coversDay` 잔여 0=false('회원권 필요' 재사용) · mypage "N회 남음"·면제 잔여 · `class_flows` 20분 경고(`kLateCancelMinutes`)+서버 문구 스낵바 · `GymState.refreshMemberships()` 예약/취소 뒤 호출 · 골든 `state_14_mypage_session_pass` (59장) · 앱 199. 브리프 D57 · GLOSSARY 4용어 · 이름사전 +1 · 갭대장 23차 · 메모리 `project-session-pass-rule`.
  - 에뮬 실주행 (member3 = 승인→3회권 발급→예약 2건→늦은 취소 1회 면제·2회째 차감→내 정보 "1회 남음" 즉시 갱신) — 캡처 `membership/20~42`, PC `pc_04~06`.
  - 갤S22 릴리즈 APK(prod URL, c15e455) 17:52 설치 (무선 adb 192.168.1.101:5555). 화면 미확인.

- [x] **18:08~18:22 사용자 지시 "PC 에뮬레이터로 — 코치거 줬다가 회원권 삭제·수정·권한·기능수정 체크"** (컨텍스트 경고 뒤 "더 가자" 로 계속):
  COACH/1234(role coach) PC 로그인 → 횟수 수정(3→5→4→5→6)·즉시 해지·재발급·요금제 수정/삭제(비활성)/복구 전부 OK.
  수정 3건: 서버 `ae06234` 즉시 해지 환불 잔여 횟수 비례(+테스트, 258 passed) · 웹 `97ece22` 미리보기 동일 ·
  앱 `GymState._reloadTriggers` +membership.updated/paused/resumed · 내 정보 해지/만료 표기. 브리프 D57 추가 문단.
  '회원권 삭제' 기능은 없음 — 해지만 (설계). 캡처 `membership/43~51`. 에뮬 `INSTALL_FAILED_INSUFFICIENT_STORAGE`
  가 "첫 빌드 누락" 의 정체 — `adb uninstall` 후 설치, `dumpsys package … lastUpdateTime` 으로 확인.

- [x] **19:54 사용자 지시 D58 — "해지·일시정지·만료되면 그 권으로 예약된 건 사라지게" + "예약은 매일 전날 오전 11시부터 (보기는 언제든지)"**:
  서버 `190d091` `revoke_uncovered_reservations`(해지·정지·수정 훅 + 매시 스윕) · `booking_open_hour`(기존 체육관 11) · BOOKING_NOT_OPEN · 265 passed(+7).
  웹 `7fca203`·`0a3f0fa` 예약 설정 '예약 오픈 시각' 셀렉트 · revoked 토스트 · 미리보기 문구. 앱 `f1d0523` '오픈 전' 배지 · 골든 60 (state_15).
  에뮬 실주행: 금 28 '오픈 전' → 탭 "예약은 8/27 11:00 부터 가능합니다." · 21:34 예약 → 코치 즉시 해지 → 서버 예약 소멸(환불 9,900 = 소멸 뒤 6/6)
  · **발견**: 보드가 SSE 로 수업 목록을 다시 안 받아 '예약됨' 잔상 → `WeekBoard` SSE 구독 추가(커밋 전, 검증 중). 캡처 `membership/60~66`.
  브리프 D58 · GLOSSARY 오픈 전/오픈 · 이름사전 +1 · 갭대장 24차. 프로드 `railway up` 완료(20:03 부팅).

  → WeekBoard SSE 재조회 `f2796e4` 커밋 — 에뮬 재검증(21:34 예약 → 코치 해지 → 보드 즉시 '회원권 필요') 통과. 캡처 `membership/67~75`.
- [x] **20:15 사용자 지시 "에뮬레이터 안에 싹 지우고 우리꺼 설치해"** — `emulator -avd Medium_Phone_API_36.1 -wipe-data` (저장공간 560MB→4.9GB 확보), KST 설정,
  디버그 APK(로컬 5060) 설치·member3 로그인 상태. 갤S22 릴리즈 APK(20:16 빌드, D58 포함) 는 무선 adb 끊김으로 미설치 — `/연결` 뒤 `adb install -r build/app/outputs/flutter-apk/app-release.apk`.

## 진행중
- [ ] 없음.

## 대기 (사용자 마지막 지시 18:00 "2 하고 PC 에뮬레이터로 너가 테스트" — 컨텍스트 경고로 미착수)
- [ ] (사용자가 18:08 지시로 'PC 에뮬레이터' 로컬 검증으로 대체 — 프로드 등록은 지시 없음) **프로드 gym 2(HYPHEN HYBRID GYM) 에 "이벤트 3회권 · 30일 · 3회 · 9,900원" 요금제 등록** — PC 웹
  https://web-facing-admin-production-dca4.up.railway.app/settings/plans (계정은 프로드 코치 계정 — 로컬 admin/1234 아님, 메모리 `project-real-gym-data` 참조).
  실회원 데이터 오염 금지: 테스트 회원은 새로 가입 신청한 계정만 쓰고 끝나면 삭제.
- [ ] **에뮬레이터로 프로드 검증** — 디버그 APK 를 prod URL 로 빌드: `flutter build apk --debug --dart-define=API_BASE_URL=https://service-facing-production.up.railway.app` → 에뮬 재설치 → 가입 신청 → PC 승인 → 3회권 발급 → 예약 → (20분 안 수업은 PC 수업 관리에서 만들기) 늦은 취소 면제/차감 → 내 정보 잔여. 끝나면 테스트 회원·수업·요금제 정리 여부 보고.
- [ ] 갤S22 잠금 해제 후 육안 확인 (사용자 몫).

## 보고만 (지시 없음)
- **자동 노쇼 = 추후 (사용자 결정 2026-08-26 20:28 "지금 구현하기는 어렵다, 넘어가자")** — 코치가 명단에서 노쇼를 찍는 운영 전제 유지. 재개 시 안 = 명단을 찍은 수업만 종료 1시간 뒤 나머지를 노쇼(오찍 방지).
- PC 발급 모달: 종류 선택 뒤 시작일 변경 시 종료일 미재계산 (D57 이전부터).
- 첫 디버그 빌드에 재조회 코드가 안 실렸던 원인 미상 (재빌드로 정상 — 빌드 캐시 추정). 동시 실행한 `flutter analyze` 와 릴리즈 빌드가 충돌해 gradle 실패 1회 — **빌드는 단독으로**.
- 보고서 4차 PENDING "TZ-잔여" 잔존 (재발행 시 제거 + D57 반영).

## 에뮬 재주행 절차 (검증된 순서 — 8/26 17:50 실측 보강)
1. `services/hyphen`: `PORT=5060 python app.py > _run.out 2> _run.err &` · PC 웹 `web/facing-admin`: `python app.py &`(8081, **템플릿 수정 시 재시작 필요**). pytest 는 `python -m pytest tests/`.
2. 앱 루트에서 `flutter build apk --debug` → `adb -s emulator-5554 install -r ...` → 재설치 첫 실행 알림 권한 Allow (540,1303) → 진입 로그인 (540,765) → 아이디 (540,648)·비번 (540,852)·로그인 (540,1198). 디버그 첫 기동 느림 — 12초 대기 후 조작.
3. 로컬 DB (`data/hyphen.db`): gym 1 · member/1234(기간제 8/19~11/17) · member2/1234(기간제 8/27~9/25, 이 세션 발급) · **member3/1234 승인 + 이벤트 3회권(id 3, 2회 사용 1회 남음)** · member4 대기 · admin/1234. 테스트 수업 57·58(17:48·17:50, 지남) 잔존.
4. 좌표(1080×2400): 내 정보 탭 (900,2256) · 회원권 아코디언 (540,490) · 회원 로그아웃 (928,796)/(846,1400) · 수업 탭 (540,2256). 보드는 `swipe 540 1900 540 700` 뒤 오늘 수업 행: 17:48 (959,1016) · 17:50 (959,1187) · 20:00 (959,1357) — 로드 상태에 따라 어긋나니 **캡처 후 탭**. 취소 다이얼로그 확인: 늦은 취소(3줄) (877,1376) · 일반(2줄) (810,1326).
5. PC playwright: 로그인 폼 `#`없음 — 역할 textbox 로 채움. 요금제 모달 `#planName #planDuration #planSessions #planPrice #planSort #btnSubmitPlan`. 발급 모달 `#msPlanSelect #msSessionTotal #msPrice #msStartDate #msEndDate`, 제출 `#membershipModal button[type=submit]`. 회원 승인: `tr:has-text("이름") a:has-text("승인")` → `button:has-text("승인하기")`.

## 결정사항 / 주의
- **D57 차감 규칙 원문**: "횟수권은 1회 노쇼 및 (수업시간 20분전 취소까지는 노패널티), 2회노쇼부터는 차감 (20분 이후 취소도 1회는 노패널티, 2회부터는 차감)" — 정본 `api/_membership.py`, 변경은 사용자 결정.
- 기간제 유효하면 횟수 안 깎음 · 잔여 0 = 예약·대기 신청 차단 · 체육관 사정 취소 = 해제.
- 프로드 접촉: /health · railway logs · `railway up` 만. gym 2 실데이터 오염 금지 — 대기 항목 실행 시 테스트 회원 정리까지.
- 로컬 서버(5060)·PC 웹(8081) 켜 둠. 에뮬: 디버그(로컬 URL, member3 로그인). 갤S22: 릴리즈(prod, c15e455).

## 다음 세션 권장 첫 프롬프트
`/resume`
