# HANDOFF - 2026-08-26 20:43

## 완료 (이 세션 — 16:18~20:43, 3면 전부 커밋·푸시·배포 완료)
- [x] 회원권 발급 → 예약 흐름 3면 실주행 확인 (member2 기간제). 캡처 `C:\dev\project\hyphen-journey-2026-08-26\membership\00~13`.
- [x] **D57 횟수권** (사용자 "3회 9,900 이벤트" + 차감 규칙 "노쇼·20분 전 이후 취소 각 회원권별 첫 1회 면제, 2회째부터 차감"):
  서버 `ed461ee`·`ae06234` (`api/_membership.py` 정본 — pick_membership · recompute_session_charges · session_summary ·
  LATE_CANCEL_MINUTES=20), `gym_memberships.session_total` + `class_reservations.membership_id/late_cancel/session_charged`,
  마이그레이션 `_migrate_session_pass_columns`(**`_migrate_class_tables` 뒤**). PC `3342d3e`·`97ece22` (요금제 횟수 칸·발급/수정 모달·이력 잔여·리스트).
  앱 `abb3100`·`0d73f8f` (Membership session_* · coversDay 잔여 0 · mypage "N회 남음"·면제·해지/만료 표기 · 취소 20분 경고 · refreshMemberships ·
  SSE membership.updated/paused/resumed). 골든 state_14.
- [x] **코치 권한 실주행** (COACH/1234 role coach): 수정·즉시 해지·재발급·요금제 수정/삭제/복구 OK. 회원권 '삭제' 는 없고 해지만(설계).
  수정 3건 = 횟수 비례 환불 · PC 수정 즉시 폰 반영 · 해지 표기. 캡처 `membership/43~51`.
- [x] **D58** (사용자 "해지·정지·만료면 그 권으로 예약된 건 사라지게" + "예약은 전날 오전 11시부터, 보기는 언제든지"):
  서버 `190d091` `revoke_uncovered_reservations`(즉시 해지·정지·수정 훅 + `sweep_uncovered_reservations` 매시 :05·부팅 직후) ·
  `gym_class_settings.booking_open_hour`(NULL=제한 없음, 기존 체육관 마이그레이션 11, PC 새 행 11) · 409 `BOOKING_NOT_OPEN` ·
  즉시 해지 환불 = **소멸 뒤** 잔여. 265 passed 1 skipped (`tests/test_booking_window_revoke.py` 7건).
  PC `7fca203`·`0a3f0fa` 예약 설정 '예약 오픈 시각' 셀렉트 · revoked 토스트. 앱 `f1d0523`·`f2796e4` '오픈 전' 배지(`ClassSessionDto.bookingOpenAt`) ·
  WeekBoard SSE 수업 목록 재조회(`_classReloadEvents`). 골든 60 (state_15). 앱 200.
  에뮬 실주행: 금 28 '오픈 전' → "예약은 8/27 11:00 부터 가능합니다." · 21:34 예약 → 코치 해지 → 보드 즉시 '회원권 필요'(환불 9,900). 캡처 `membership/60~75`.
- [x] 프로드: 백엔드·PC 웹 `railway up` 3회 (마지막 20:03 부팅, /health ok · 로그인 200). 마이그레이션은 컬럼 추가+설정 행 채움뿐(gym 2 booking_open_hour=11).
- [x] 에뮬레이터 초기화 (사용자 지시 "싹 지우고 우리꺼 설치") — `emulator -avd Medium_Phone_API_36.1 -wipe-data`, 560MB→4.9GB, KST, 디버그 APK(로컬 5060)·member3 로그인.
- [x] 문서: 브리프 D57·D58 · GLOSSARY(횟수권·차감·늦은 취소·면제·오픈 전·오픈) · CLAUDE.md 골든 60 · 이름사전 +2 · 갭대장 23·24차 ·
  메모리 `project-session-pass-rule`·`project-booking-window-revoke`.

## 진행중
- [ ] 없음.

## 대기
- [ ] **갤S22 릴리즈 설치** — `build/app/outputs/flutter-apk/app-release.apk` (20:16 빌드, 오늘 변경 전부 포함). 무선 adb 192.168.1.101:5555 끊김 —
  폰 잠금 해제·와이파이 뒤 `/연결` → `adb -s 192.168.1.101:5555 install -r ...` → `dumpsys package com.netizen.hyphen.hyphen_app | grep lastUpdateTime` 확인. 현재 폰 = 17:52 판.
- [ ] 프로드 gym 2(HYPHEN HYBRID GYM) 에 "이벤트 3회권 · 30일 · 3회 · 9,900원" 요금제 등록 (지시 없음 — 사용자 결정). 실데이터 오염 금지.
- [ ] **자동 노쇼 = 추후** (사용자 결정 20:28 "지금 구현하기는 어렵다, 넘어가자") — 먼저 제안하지 말 것. 재개 안 = 명단을 한 명이라도 찍은 수업만 종료 1시간 뒤 나머지를 노쇼.

## 보고만 (지시 없음)
- PC 발급 모달: 종류 선택 뒤 시작일 변경 시 종료일 미재계산 (D57 이전부터).
- 해지 미리보기는 소멸 전 잔여로 계산(실제 환불은 소멸 뒤라 더 클 수 있음 — 문구로 안내).
- Playwright 일반 클릭이 PC 링크(수정·해지·연장)에 간헐적으로 안 먹음 → JS 클릭(`a.click()`·`form.requestSubmit()`·`#faConfirmOk`)으로 진행.
- 로컬 테스트 잔여물: 수업 57·58(지남)·59(21:34 'D58 소멸 테스트') · member3 회원권 3장(id 3·4·5 전부 해지) · 로컬 서버(5060)·PC 웹(8081) 켜 둠.

## 에뮬 재주행 절차 (검증된 순서 — 8/26 20:17 실측)
1. `services/hyphen`: `PORT=5060 python app.py > _run.out 2> _run.err &` · PC 웹 `web/facing-admin`: `python app.py &`(8081, 템플릿 수정 시 재시작). pytest `python -m pytest tests/`.
2. **에뮬 저장공간** — `MSYS_NO_PATHCONV=1 adb shell df -h /data` 로 확인. 부족하면 `adb install -r` 이 "Success" 처럼 보여도 옛 앱이 남는다 →
   `dumpsys package … lastUpdateTime` 으로 반드시 확인. 해결 = `adb uninstall` 뒤 설치, 그래도 부족하면 wipe.
3. 첫 실행: 알림 권한 Allow (540,1303) → 진입 로그인 (540,765) → 아이디 (540,648)·비번 (540,852)·로그인 (540,1198). 초기화 직후 첫 기동은 14초+ 대기.
4. 로컬 DB: gym 1 · member/1234(기간제) · member2/1234(기간제 8/27~9/25) · member3/1234(승인, 회원권 전부 해지) · member4 대기 · admin/1234(boss) · COACH/1234(coach).
5. 좌표(1080×2400): 내 정보 탭 (900,2256) · 회원권 아코디언 (540,490) · 수업 탭 (540,2256). 보드는 `swipe 540 1900 540 600` 뒤 오늘 마지막 행 (959,1357) — **캡처 후 탭**.
   취소 다이얼로그 확인: 늦은 취소(3줄) (877,1376) · 일반(2줄) (810,1326).
6. PC playwright: 요금제 `#planName #planDuration #planSessions #planPrice #planSort #btnSubmitPlan` · 발급 `#msPlanSelect #msSessionTotal` · 수정 `#meSessions` ·
   해지 `#cancelModal select[name=cancel_type]` → `form.requestSubmit()` → `#faConfirmOk` · 예약 설정 `#rsOpenHour #rsDailyLimit`.
7. 빌드는 **단독으로** (analyze/test 와 동시 실행 시 gradle 실패). `flutter build apk --debug` 출력의 `√ Built` 와 APK mtime 확인.

## 결정사항 / 주의
- D57 차감 규칙 원문·D58 원문 = 메모리 2개 파일. 규칙 변경은 사용자 결정.
- 기간제 유효하면 횟수 안 깎음 · 잔여 0 = 예약·대기 차단 · 체육관 사정 취소 = 해제 · 오픈 시각은 승격 제외 · 이미 시작한 수업은 소멸 대상 아님.
- 프로드 접촉: /health · railway logs · `railway up` 만. gym 2 실데이터 오염 금지.

## 다음 세션 권장 첫 프롬프트
`/resume`
