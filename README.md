# hyphen_app

HYPHEN — 체육관 수업·기록 관리 앱 (회원 폰 창구 + 코치 간단 셸)

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 추후 작업 (deferred to later)

- **W-prime (Critical Power) 페이싱 정밀화** — PHASE4 §2.1. Skiba 2012 모델 기반 회원별 CP·W' 추정 + WOD depletion 시뮬레이션 + split 추천. 한 번 구현·15 pytest 통과까지 갔으나 (`services/facing@4469bb4`) 통합 시점 보류로 revert (`cf06238`). 재시작 시 commit 4469bb4 의 6 파일 (`engine/wprime.py`·`api/wprime.py`·`models/member_wprime.py`·`tests/test_wprime.py` + register 2건) 복원 후 facing-app UI 통합.
- **전자계약서 서명 보내기 (회원 폰 ↔ PC 어드민 양방향 흐름)** — 사장이 PC 에서 계약서 발급 → 회원 폰 SMS·알림톡으로 서명 링크 → 회원 폰에서 서명 → 사장 PC SSE 알림 + signed PDF 자동 보관. 현재 사장 대리 서명 (`POST /api/v1/admin/contracts/<id>/proxy-sign`) 만 구현. 회원 self-sign endpoint (`POST /api/v1/member/contracts/<id>/sign`) 는 device_id 인증 기반으로 존재하지만, 회원 폰 ↔ 알림 전송 ↔ 사장 대시보드 연동 흐름이 빠짐. 작업 범위 크니 별도 phase 배정 권장 (1주+ plan).

## 제거된 기능 대장 (v3.2 · 2026-08-20 — 코드 삭제, 기록만 보존)

> 사용자 지시 "지금 당장 할 수 없는 기능은 글로만 남기고 깨끗하게 다 지워"에 따라
> 도달 불가 화면·죽은 배선을 코드까지 삭제했다 (구 "숨김 = 코드 보존" 정책 종료).
> 복원 좌표: `git log --full-history -- <파일 경로>` 로 삭제 커밋의 부모에서 꺼낸다.
> 백엔드(services/facing) API 는 건드리지 않았다 — PC 웹이 계속 쓴다.

1. **출석 캘린더 탭 (Attend)** — `lib/features/attendance/attendance_screen.dart`.
   v1.27 셸 3탭 개편으로 숨김 → 삭제. 출석 수치는 홈 탭 마일스톤이 계속 표시.
2. **재활 가이드 (Rehab)** — `lib/features/rehab/` 4파일 + 구 Notice 탭
   `InboxScreen` 클래스(`inbox_screen.dart`) + `test/inbox_screen_test.dart`.
   동작·통증부위 브라우즈 → 가이드 플로우. 셸에서 빠진 뒤 도달 불가.
3. **체육관 리더보드** — `lib/features/leaderboard/box_leaderboard_screen.dart`.
   어떤 화면도 밀어주지 않던 완전 고아.
4. **공지 전용 화면** — `lib/features/announcements/announcements_screen.dart`.
   공지는 홈 아코디언 + 수업 탭 + 종(알림함)이 대체 (`announcements_state.dart` 는 사용 중).
5. **데이터 가져오기 (CSV·Wodify·Whoop 연동 구상)** — `lib/features/mypage/import_screen.dart`.
   "가상 UI" 껍데기 — 연동 실배선 0.
6. **체육관 개설 (앱 내)** — `lib/features/onboarding/create_gym_screen.dart` +
   `box_wod_screen.dart` 의 `_showCreateGymSheet`. 개설은 PC 웹 admin 전용 (결정2 · 2026-06-10).
7. **체육관 검색/찾기** — `lib/features/gym/gym_search_screen.dart`. 1인 샵 전용 결정(v2.6)으로 폐기.
8. **직원 계정 연결** — `lib/features/auth/staff_link_screen.dart` + `/auth/link-staff` 라우트.
   코치 = 본인 1명이라 연결할 직원 없음 (BRIEF D37). 백엔드 endpoint 는 유지.
9. **Tier 잔재** — `lib/widgets/tier_badge.dart`(TierBadge) + `GoalsState.targetTier`.
   Tier 사다리는 D34·D36 으로 소멸 — 회원 레벨은 경력 3단(SCALED·RXD·ELITE).
10. **(선행 이동분) 페이싱 계산기·Benchmarks·Tier 결과·Engine 화면** — 이 커밋이 아니라
    이전 정리에서 `_archive/lib-engine/` 으로 이동됨. 복원 시 그 폴더에서 시작.
11. **첫 실행 인트로 2p (v3.3 · 2026-08-21)** — `lib/features/intro/intro_screen.dart` +
    `/intro` 라우트 + 골든 `common_02`·`common_03`. v2.3(2026-08-12)에서 진입이 끊긴 채
    코드만 남아 있었고, "기록이 레벨이 된다" 등 실물과 안 맞는 약속 문구라 사용자 지시로
    코드째 삭제. 앱 흐름은 스플래시 → 로그인 직행 그대로.
12. **오늘의 수업 내용 화면 (v3.13 · 2026-08-23)** — `lib/features/wod/wod_today_screen.dart`
    + `/wod/today` 라우트. daily-plans API 를 읽는 유일한 앱 화면이었는데 어떤 화면도
    이 라우트를 밀어주지 않던 고아. PC 의 '오늘 수업 내용 배치' 섹션(같은 표를 쓰던
    짝)도 같은 날 삭제 — "폰 회원에게 즉시 노출" 안내가 실제로는 거짓이었다.
    회원 수업 내용의 정본은 wod-posts(수업 탭 보드) 하나. 백엔드 daily-plans API 는
    반복 스케줄 실체화(materialize_rules)의 설명 폴백으로 남아 있어 유지.
13. **'당일 공개' 잠금 (v3.15 · 2026-08-23 사용자 결정 "당일공개 폐지")** — 미래
    게시물을 회원에게 잠그던 정책. 서버 `future_locked`(services/facing api/gym.py
    2곳) + 앱 `LockedWodBanner` 의 미래 분기(week_board.dart)·'당일 공개.' 문구
    삭제. 코치가 미리 적는 새 흐름과 충돌해 폐지 — 잠금 사유는 회원권 만료 하나만
    남음 (LockedWodBanner 는 그 용도로 존치).
14. **코치 설정 '포인트' 탭 + gym_point_settings (2026-08-24 포인트 이원화 정리)** —
    `settings_screen.dart` 의 `_PointsTab`(적립률·사용 최소 단위·만료 일수) + 백엔드
    `api/point_settings.py`·`models/gym_point_settings.py`. 저장만 되고 읽는 코드가
    0 인 고아였다 (earn_rate 자동 적립·redeem_unit 검증·만료 처리 전부 미구현).
    DB 표는 존치. 같은 날 WOD 첫 기록 100P 하드코딩(api/gym.py `WOD_RESULT_POINTS`)도
    폐기 — 포인트 지급은 리워드 규칙 엔진(자동) + PC 수동 지급 프리셋 두 경로로 정리.
15. **코치 전용 로그인 화면 + '코치 로그인' 진입 (v3.19 · 2026-08-25 사용자 지시
    "로그인 창구는 하나")** — `lib/features/boss/boss_login_screen.dart`(BossLoginScreen)
    + `/boss/login` 라우트 + 진입 화면(`signup_screen.dart`)의 '코치 로그인' 줄
    (`_kShowBossEntry`) + 골든 `boss_01_login`. 사람이 자기 역할을 골라 들어가는
    구조 자체를 폐기 — 아이디·비밀번호만 받고 코치/회원 판정은 **서버**가 한다
    (`POST /api/v1/auth/login` → `kind`). 로그인 화면 하나 = `login_screen.dart`
    (구 `member_login_screen.dart`, 골든 `common_08_login`). 백엔드 구 창구 2개
    (`/api/v1/admin/login`·`/api/v1/auth/member-login`)는 관리자 웹·구 APK 때문에 유지.
16. **폰 코치의 수업 내용 게시·삭제 (v3.20 · 2026-08-25 사용자 지시 "수업내용 게시
    하는건 굳이 폰에는 넣지말자 — 그런 상세내역은 pc에서")** —
    `lib/features/gym/wod_post_screen.dart`(WodPostScreen 작성 폼) + 수업 탭의
    '수업 내용 게시' FAB(`box_wod_screen.dart`) + WodRow 삭제 아이콘·확인
    다이얼로그(`wod_row.dart` `canDelete`·`_confirmDelete`) + 그 배선
    (`gym_state.postWod`·`deleteWod` · `gym_repository.postWod`·`deleteWod` ·
    `week_board` 의 `isOwner` 전달). 폰의 수업 탭은 코치에게도 **보는 화면**이다.
    삭제까지 같이 내린 이유: 폰에서 지울 수는 있는데 다시 쓸 수는 없으면 그게 더
    나쁜 상태다. 백엔드 라우트(`POST/DELETE /api/v1/gyms/<id>/wods`)는 PC 가
    계속 쓰므로 그대로 둔다. 골든 `coach_02_shell_board` 재생성.
17. **폰 코치 화면 축소 7건 (v3.21 · 2026-08-25 사용자 지시)** — "코치가 폰에서
    되는 것" 목록을 사용자가 직접 추려 내린 결과. 폰은 **오늘 돌리는 것**만 남기고
    만들고·고치고·들여다보는 건 전부 PC 로 넘겼다.
    · 수업 등록 — `lib/features/boss/class_compose_sheet.dart` + 대시보드
      '수업 등록' 버튼(`_openCompose`) + 골든 `boss_04_class_compose`·
      `boss_06_compose_datepicker`
    · 수업 수정·수업 취소 — `class_roster_sheet.dart` 의 `_editClass`·`_cancelClass`
      + 두 버튼 + 골든 `boss_05_roster_cancel`·`boss_07_class_edit`
    · 대기자 수동 승격 — 원래 버튼이 없었다. 서버가 이미 자동으로 올린다
      (`api/classes.py cancel_reservation` — 앞사람이 취소하면 대기 1번이
      confirmed. 하루 예약 한도 초과자는 건너뛰고 다음 대기자).
      명단의 '승격' 은 버튼이 아니라 상태 배지다.
    · 회원 명단·활동 통계·회원 상세 — 구 `CoachDashboardScreen` 의 로스터·
      `_RosterRow`·`_MemberDetailSheet`. 화면은 가입 승인만 남아
      **`MemberApprovalsScreen`(`member_approvals_screen.dart`)** 으로 개명.
    · 코치 노트 — 위 상세 시트와 함께 삭제 (쪽지와 중복이었다)
    · 회원 요청 — `member_requests_screen.dart` (쪽지로 대체)
    · 만료 임박 — 대시보드 섹션 + `_ExpiringCard` (백엔드 `expiring_soon` 응답은
      PC 가 계속 쓰므로 유지)
    · 체육관 프로필 수정 — `gym_profile_edit_screen.dart`
    · 요금제 탭 — `settings_screen.dart` 의 `_PlansTab` (설정 4탭 → 3탭:
      알림·자동 가입·예약) + 골든 `boss_09_settings_plans`
    백엔드 API 는 전부 그대로다 — PC 웹이 쓴다. 폰 창구만 닫았다.
    rename: CoachDashboardScreen → MemberApprovalsScreen (coach_dashboard_screen.dart
    → member_approvals_screen.dart)
18. **폰 코치 설정 화면 전체 (v3.22 · 2026-08-25 사용자 지시)** —
    `lib/features/boss/settings_screen.dart`(BossSettingsScreen 3탭) +
    `/boss/settings` 라우트 + 대시보드 AppBar 톱니 + 골든
    `boss_08_settings_reservation`. 탭별 사유가 다르다:
    · 알림 on/off → **PC** (`web/facing-admin/templates/notifications.html` 존재)
    · 하루 예약 한도 → **PC** (`settings_reservations.html` 존재)
    · 자동 가입 승인 → **기능 자체 폐기** ("내가 항상 승인해서 하는걸로").
      백엔드도 같이 내렸다: `GET/PATCH /api/v1/admin/gyms/<id>/auto-approve`
      삭제 · `api/gym.py` 가입 분기에서 `auto_approve_joins` 제거(항상 pending) ·
      `models/gym_profile.auto_approve_joins` 는 휴면 컬럼으로만 존치.
      공식 HYPHEN HQ 체육관 즉시 승인(데모용 `OFFICIAL_GYM_NAME` 분기)은 별개라 유지.
    폰 코치 AppBar 에 남는 것은 로그아웃 하나.

