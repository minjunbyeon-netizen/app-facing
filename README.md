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
19. **회원 별도 수업 예약 화면 `/classes` (v3.25 · 2026-08-25 사용자 지시 "따로 있는 것
    전부 통일")** — `lib/features/classes/classes_screen.dart`(ClassesScreen·
    ClassesSection·`_ClassCard`) + `/classes` 라우트 + 내 정보 탭 '수업' 버튼.
    수업 탭 주간보드 안에서 예약이 끝나는데 내 정보 → 수업 으로 들어가는 두 번째
    예약 화면이 카드 모양으로 따로 있었다. 예약·취소 흐름 함수만
    `classes/class_flows.dart` 로 남기고 화면은 삭제. 골든 4장(member_07·08·state_07·08)은
    주간보드(BoxWodScreen)로 재촬영 — 같은 fake 를 소비하므로 상태 변형은 그대로.
20. **코치 앱 '수업' 탭 (v3.28 · 2026-08-25 사용자 결정 "니 말대로 1")** — 코치 셸이
    회원 주간보드(BoxWodScreen/WeekBoard)를 `isOwner` 분기로 재사용하던 탭. 한 위젯 안에서
    회원판·코치판이 if 로 갈리는 것도 이원화라 폐지. 대체 = 예약 현황 탭의
    `boss/coach_week_classes.dart`(주간 수업/예약 — 같은 부품: 주간 헤더 규격·ClassLine.coach·
    명단 시트, 데이터는 코치 세션 API `GET /admin/gyms/<id>/classes`). 회원 화면에서 코치
    분기 전부 제거 — week_board·box_wod(배지·가입 신청 아이콘)·wod_row(완료 표시·메시지 가드)·
    wod_detail(배지·요청 버튼 가드)·mypage('가입 신청' 버튼·'코치' 라벨). 코치 셸 = 2탭.
    골든 `coach_02_shell_board` 삭제.
21. **폰 쪽지 그룹·작성 화면 (v3.28 · 2026-08-25 사용자 지시)** —
    `inbox/group_management_screen.dart`(그룹 만들기·회원 추가) · `inbox/compose_note_screen.dart`
    (대상 individual/group/all · 종류 note/assignment · 제목·근거·기한·동작 표) ·
    `models/coach_group.dart` · `InboxRepository` 그룹 메서드 4종. 쪽지 탭 '그룹' 버튼 삭제,
    '새 쪽지' = `inbox/new_note_screen.dart` (내 회원 목록 → 탭 → 그 회원과의 대화에서 입력·전송).
    전송 API 는 종전과 같은 `POST /gym/<id>/notes` individual·note — PC 쪽지함 연동 그대로.
    그룹·숙제(assignment) 서버 API 는 PC 용으로 유지.

22. **체육관 프로필 인스타그램·로고 이미지 URL (v3.29 · 2026-08-27 사용자 결정
    "이건 코치와 회원 간의 공지사항·쪽지·수업 예약·수업 공개(+업적) 그게 끝이야")** —
    `models/gym.dart` 의 `GymProfile.instagram`·`logoUrl` 필드·생성자 인자·`fromJson` 파싱.
    4기둥 밖이고 앱에 이미지를 그리는 코드 자체가 없어(`Image.network` 0건) 코치가 채워도
    어느 화면에도 안 나왔다. PC 입력칸 2개(`settings_gym_profile.html`)·백엔드 직렬화·PATCH
    수용도 같은 날 삭제 — DB 컬럼 `gym_profiles.instagram`·`logo_url` **만** 휴면으로 존치
    (운영 DB 에 실값이 있어 DROP = 데이터 손실. `models/gym_profile.py` 주석 참조).
23. **폰 체육관 프로필 편집 경로 (v3.29 · 2026-08-27 · 22 와 같은 커밋)** —
    `GymState.updateGymProfile`(gym_state.dart) · `GymRepository.updateGymProfile`
    (gym_repository.dart). 편집 화면(구 `gym_profile_edit_screen.dart`)이 진작 사라져
    `lib/` 전체 호출처 0건이던 죽은 배선. 체육관 프로필 편집 창구는 PC 코치 웹 하나다.
    서버 `PATCH /api/v1/gyms/<id>/profile` 은 PC 가 쓰므로 그대로 유지.
24. **체육관 검색 배선 (v3.30 · 2026-08-27 사문 코드 정리)** — `GymRepository.search`
    (`GET /api/v1/gyms/search` 래퍼). 검색 화면은 대장 7 에서 이미 지웠는데 래퍼만
    남아 호출처 0건이었다. **서버 라우트는 존치** — `sanity_check.py:43` 과
    `tests/test_personas_e2e.py:131`(gym_id 조회 헬퍼)이 아직 쓴다.
25. **프로필 info 배선 (v3.30 · 2026-08-27)** — `InboxRepository.getProfileInfo`·
    `updateProfileInfo`(`/api/v1/profile/info`). 호출처 0건인 데다 **서버에 그 라우트가
    아예 없었다**(GET·POST 모두 미존재) — 눌렸으면 404 나던 죽은 배선. 프로필 편집 정본은
    `/api/v1/member/profile` 계열. 골든 fake 스텁 1줄도 같이 삭제.
26. **초대코드·코드 가입 (v3.30 · 2026-08-27)** — 앱 `InboxRepository.getInviteCode`·
    `regenerateInviteCode`·`joinByCode` 3종 + 서버 라우트 3개
    (`GET /api/v1/gym/<id>/invite-code` · `POST .../invite-code/regenerate` ·
    `POST /api/v1/gym/join-by-code`) + 헬퍼 `_generate_invite_code`
    (services/hyphen `api/coach_note.py`). 코드로 가입하는 화면이 폰·PC 어디에도 없어
    양쪽 다 소비처 0건. DB 컬럼 `gyms.invite_code` 는 휴면 존치 (시드가 값을 넣는다).
27. **쪽지 그룹 관리 라우트 4개 (v3.30 · 2026-08-27)** — 서버
    `GET/POST /api/v1/gym/<id>/groups` · `POST/DELETE .../groups/<gid>/members`
    (`api/coach_note.py`). 폰은 v3.28(대장 21)에 그룹 메서드를 뺐고 PC 웹은 처음부터
    부른 적이 없다. 표(`gym_groups`·`gym_group_members`)와 `post_note` 의
    `target_type="group"` 분기는 **휴면 존치** — 기존 행 대비. 새 그룹을 만들 창구는 없다.
28. **다중 체육관 전환 (v3.30 · 2026-08-27)** — 서버 `POST /api/v1/admin/switch-gym`
    (`api/admin.py`) + PC 프록시 `/api/proxy/switch-gym`(`web/facing-admin/app.py`).
    스위처 UI 는 2026-08-13 에 사라졌고 남은 배선을 부르는 화면이 0건이었다.
    `_layout.html` 의 "백엔드는 살아 있다" 주석도 현재 사실로 갱신.
29. **빈 feature 폴더 3개 (v3.30 · 2026-08-27)** — `lib/features/pacing_result/` ·
    `lib/features/presets/` · `lib/features/wod_builder/`. 엔진 화면 이동(대장 10) 뒤
    파일 0개인 껍데기만 남아 있었다.
30. **죽은 백엔드 서비스 모듈 3개 (v3.30 · 2026-08-27)** — services/hyphen
    `services/marketing_dashboard.py` · `services/cohort.py` · `services/receipt_pdf.py`.
    marketing_dashboard 는 참조 0건, cohort 는 marketing_dashboard 만 import 하던
    죽은 쌍이었다. 4기둥 밖(매출·cohort 잔존율·이탈 위험·영수증 PDF).
31. **진입 갈림길 화면 (v3.31 · 2026-08-27 사용자 승인 "로그인 화면 하나로 합치는 것이
    맞습니다") — 브리프 D66(1)** — `lib/features/auth/signup_screen.dart`(SignupScreen) +
    `/signup` 라우트 + 골든 `common_05_signup`. 소셜 로그인은 v1.33 에서 내려갔고
    (`_kShowSocialLogin=false`) 코치 입구는 대장 15(v3.19)에서 사라져, [로그인]·[회원 가입
    신청] 두 버튼과 약관 링크만 남은 껍데기였다. 앱을 열면 곧바로 로그인 화면(`login_screen.dart`,
    골든 `common_08_login`)이고, '회원 가입 신청'(→ `/signup/self`)은 그 아래 작은 줄,
    약관·개인정보처리방침 링크는 그 밑으로 옮겼다. 진입점 전환 3곳 = 스플래시 미로그인 ·
    회원 로그아웃 · 코치 세션 만료(D59 — 2단 push 를 1단으로). **`social_auth_service.dart`
    는 남긴다** — 실 OAuth 복구용 자산 (되살릴 때 로그인 화면에 `HkSocialButton` 을 얹는다).
32. **내 정보 '목표' (v3.31 · 2026-08-27 사용자 지시) — 브리프 D66(2)** —
    `lib/features/goals/goals_screen.dart`(GoalsScreen) + 메뉴 행 + 골든 `member_16_goals`.
    **서버 목표 API·DB 는 존치**하고 `core/goals_state.dart`(GoalsState)도 남긴다 —
    착용 칭호(`wornTitle`)를 같은 상태가 들고 있어 내 정보 배지·업적 화면이 계속 쓴다.
    사라진 것은 목표를 편집하던 화면뿐.
33. **내 정보 'FAQ' (v3.31 · 2026-08-27 사용자 지시)** — `lib/features/mypage/faq_screen.dart`
    (FaqScreen, 시드 10문답) + 메뉴 행 + 골든 `member_17_faq`.
34. **내 정보 '고객지원' (v3.31 · 2026-08-27 사용자 지시)** — 카카오톡 채널 1:1 채팅
    `launchUrl('http://pf.kakao.com/_kxbxanX/chat')` 행. 화면은 원래 없어 행만 삭제
    (mypage 의 `url_launcher` import 도 함께 정리 — 앱 안 다른 사용처는 `wod_detail_screen` 하나).
35. **내 정보 '데이터 초기화' (v3.31 · 2026-08-27 사용자 지시)** — danger 버튼 +
    `MyPageScreen._confirmReset`(확인 다이얼로그 → `prefs.clear()` → `/splash`).
    `shared_preferences` import 도 이 파일에서 함께 정리. 서버 기록은 원래 지우지 않던 기능.
36. **체육관 프로필 화면 · 코치 상세 (v3.36 · 2026-08-28)** —
    `lib/features/gym/box_profile_screen.dart` + `lib/features/gym/coach_detail_screen.dart`.
    `BoxProfileScreen` 은 어떤 라우트도 밀어주지 않던 고아였고(참조 0건),
    `CoachDetailScreen` 은 그 화면에서만 진입하던 짝이라 함께 죽어 있었다.
    회원이 실제로 보는 체육관 정보는 `lib/widgets/gym_info_card.dart` 다 —
    2026-08-28 전화 걸기 배선 중 좌표가 갈리며 드러났다.
    `GymState.coaches`·`CoachProfile` 모델은 그 카드와 쪽지함이 계속 쓰므로 남긴다.
37. **칭호(Panel B) 일체 (v3.39 · 2026-08-29 사용자 지시 "그럼 없애야지, 지금 업적으로
    하는거잖아")** — `lib/features/achievement/panel_b_screen.dart`(칭호 화면) ·
    `lib/core/titles_catalog.dart`(kPanelBTitles 26종 · TitleUnlockSignals · PanelBUnlocker) ·
    `lib/core/share_count_store.dart`(Panel B 공유 카운트 전용) · 업적 화면 우상단 '칭호'
    진입 버튼 · 내 정보 이름 아래 착용 칭호 배지 · `GoalsState.wornTitle` 일체 ·
    골든 `state_06_worn_title` · 테스트 `titles_catalog_test`·`worn_title_store_test`.
    **없앤 이유**: 해금 판정이 `profile.benchmarks`(1RM·5km 등)를 읽는데 그 값을 넣는
    `setBenchmark` 호출처가 **0곳**이었다 — 입력 화면(Benchmarks 온보딩)이 v2.6/v3.2 에서
    삭제돼, 신규 회원은 그 칭호가 **영원히 안 풀렸다**(제1원칙 위반). 게이미피케이션은
    업적 하나로 통일한다.
    **남긴 것**: `lib/core/pr_detector.dart`(홈 화면이 쓴다) · 서버 `member_goals.worn_title`
    컬럼과 기존 값(휴면 — DB 는 지우지 않는다). 서버 PATCH 는 키가 있을 때만 갱신하도록
    바꿔, 앱이 안 보내도 지난 착용값이 지워지지 않는다.
38. **수업 탭 하단 '체육관 정보'·'공지' 아코디언 · 내 정보 '주소 줄'·'체육관 기록'·'내 체육관'
    (v3.43 · 2026-08-29 사용자 지시)** — `box_wod_screen.dart _GymInfoAccordion`·
    `_AnnouncementsAccordion` · `mypage_screen.dart _MyBoxSection`·`_ProfileRow`·체육관 기록 카드·
    신원 카드의 주소 `_ReservedLine`. 공지는 **홈에서만**(검정 전광판) 본다.
    **딸려 나간 것**: `lib/widgets/gym_info_card.dart`(GymInfoCard) 는 이제 **호출처 0곳** —
    D79 에서 붙인 '수업 종류(수업 안내)' 칸의 유일한 노출 자리였다. 위젯·모델·저장소·검사는
    남겨 두었다(골든 `member_25_gym_info` 가 카드를 직접 그린다). **회원이 수업 안내를 볼
    자리를 어디로 옮길지는 사용자 결정 대기.** 검사 앵커 `kGymInfo`·`kMyGym` 도 함께 제거.
    → **해소 (D83 · 2026-08-29 사용자 지시)**: 내 정보 메뉴 첫 줄 **'체육관 정보'** →
    `lib/features/gym/gym_info_screen.dart`(GymInfoScreen) 가 GymInfoCard 를 세운다 — 수업 종류
    노출 자리 복구. 같은 지시로 메뉴는 항상 펼침(아코디언 폐기) · '알림 받기' 는 메뉴 표 안 한 줄로 이동.
39. **클라이언트 PR 판정 · 엔진 표 히스토리 쓰기 (D91 · 2026-08-30 사용자 지시 "완전 통합")** —
    `lib/core/pr_detector.dart`(PrDetector — 폰이 시간 기록을 비교해 PR 을 판정) + `test/pr_detector_test.dart` ·
    `HistoryRepository.saveWodHistory/deleteWodRecord`(엔진 표 `/api/v1/history/wod` POST·DELETE) · 타이머 화면
    (`wod_session_screen.dart`)의 엔진 표 선저장 경로 · 히스토리 상세의 페이싱 플랜·세그먼트 렌더(`_SegmentCard`·`_ItemLine`).
    **원천은 서버 수업 결과 표 하나** — PR 은 응답 `is_pr`, 총 기록 수·PR 수는 히스토리 `meta`, 저장 창구는
    `GymRepository.submitWodResult` 하나. 게이트 = `test/ssot_lint_test.dart` (PrDetector·`/api/v1/history` POST 금지).
40. **Streak Freeze · 앱 연속일 계산 (D92 · 2026-08-30 사용자 지시 "3 하고")** — `lib/core/streak_freeze.dart`
    (StreakFreezeStore — 폰 로컬 SharedPreferences 로 하루 빠진 날을 보정) + `test/streak_freeze_test.dart` ·
    `home_screen.dart _GamificationBody._currentStreak/_uniqueDays`. 연속일은 **서버 `GET /api/v1/history/wod` meta.streak_days**
    (`api/_metrics.py class_streak_days` — 코치 명단과 같은 함수). 게이트 = `test/ssot_lint_test.dart` (StreakFreeze·_currentStreak 금지).


