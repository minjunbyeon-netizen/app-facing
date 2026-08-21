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
