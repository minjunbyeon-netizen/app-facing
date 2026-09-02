# HANDOFF - 2026-09-02 14:52

> 주제: **인계 대기 1 "별건 2건" 전부 구현·검증·배포 완료 + 자동 노쇼 폐기 확정.**
> 서버 682 passed·1 skipped / 앱 234 passed(골든 픽셀 변화 없음) / 프로드 3면 신코드 실확인.
> 진행중 없음 — 깨끗한 상태에서 인계.

## 완료
- [x] **예약 생성 SSE 앱 배선 (별건 ①)**: `week_board.dart _classReloadEvents` 에
  `member_reservation_created` 추가 — 취소는 듣는데 생성만 안 듣던 비대칭 해소 (다른
  회원 예약 시 정원·마감 실시간). 코치 폰 셸은 SSE 청취 자체가 없어 대상 아님 (PC 가 주).
  **에뮬 실물 검증**: 로컬 URL 릴리즈 APK + member/1234 로그인 → 수업 시간 칸 띄운 채
  서버로 2번째 회원 예약 생성 → 무접촉 정원 0/8 → 1/8 즉시 갱신 확인.
- [x] **PC '현재 회원권' 판정 서버 창구화 (별건 ②)**: `admin_list_memberships` 응답에
  `is_current`(= `_membership.governing_membership`, 폰 profile.py 와 같은 이름·정본) 추가.
  PC 세 곳이 자체 판정 사본 대신 이 플래그만 읽음 — members.html 수정 프리필·수정 PATCH
  대상, member_detail.html 일시정지 대상(미래 선결제 폴백만 폰 선례대로 JS 잔존).
  게이트 2종 같은 커밋: `test_ssot_membership_label_lint`(PC 사본 재발 감지) +
  `test_membership_cancel_visibility`(governing 한 장에만 찍힘·미래만 있으면 0장).
- [x] **검증·배포**: 서버 pytest 682 passed / 앱 flutter test 234 passed / 로컬 playwright
  실물 3건(프리필 문구·API is_current·정지 대상) / `railway up` 2건(서버+관리자 웹) 후
  프로드 coach 로그인으로 백엔드 `is_current` 라이브 + 신 템플릿 서빙 실확인.
- [x] **자동 노쇼 폐기 확정 (사용자 지시)**: "어쩔 수 없는 영역, 그냥 폐기" — 메모리
  `project-session-pass-rule.md` 에 기록. 재제안 금지 · 인계 대기 목록에서 제거.
  노쇼 성립 = 코치 명단 수동 체크만 (D31) 유지, 반복자는 코치 구두 주의.
- [x] SSOT 대차대조표 갱신 (`member_reservation_created/cancelled` 앱 칸 = week_board
  reload, 편도-PC → 일치) · HANDOFF-2026-09-02 archive 이동.

## 진행중
- 없음.

## 대기
- [ ] 1. 갤S22 실기기 프로드 확인 (제안만 한 상태 — 지시 없음).

## 결정사항 / 주의
- **자동 노쇼 = 폐기 (2026-09-02)**. "추후" 아님 — 다시 대기 목록에 싣지 말 것.
- **is_current 엣지 (의도된 동작)**: 해지 예정 행(active+cancelled_at)이 대표로 잡히면
  수정 폼이 그 행을 프리필하고 PATCH 는 서버 가드 422 NOT_EDITABLE 로 시끄럽게 실패
  (종전 자체 판정은 조용히 겹침 새 발급 — 개선). 문구 안내는 여지로 남음.
- **로컬 상태**: 5060 서버 신코드로 백그라운드 재기동됨 · 8081 admin 웹 그대로 ·
  로컬 DB gym 1 에 스모크 잔재(SMOKE 수업 18 · 회원 2 device 'smoke-dev-2' · 예약 6 —
  시드 시 `hash_device_id` 가 SECRET_KEY 솔트를 쓰므로 .env 로드 필수였음, 주의).
- **에뮬**(Medium_Phone_API_36.1): 프로드 URL 릴리즈 APK + pm clear — 깨끗한 로그인 화면.
- 커밋: 앱 `406e677`(SSE 배선)·`6cc2216`(archive) · 서버 `0e9b26f`(is_current+게이트+
  대차대조표) · PC 웹 `8e3887c`(자체 판정 제거) — 전부 push + railway up SUCCESS.

## 관련 파일
앱 `lib/features/gym/week_board.dart` /
서버 `api/admin.py`(admin_list_memberships) · `api/_membership.py`(governing_membership —
변경 없음, 정본) · `tests/test_{ssot_membership_label_lint,membership_cancel_visibility}.py` ·
`docs/SSOT/대차대조표.md` /
PC `templates/members.html`(프리필·PATCH 대상) · `templates/member_detail.html`(openPause)

## 다음 세션 권장 첫 프롬프트
`/resume`
