# HANDOFF - 2026-09-02 12:55

> 주제: **인계 잔여 검증 → 개선 4건 → SSOT 감사 → 이원화 정본화 7건 → 결정 2건 집행, 전부 배포까지 완료.**
> 서버 677 passed·1 skipped / 앱 233 passed / 골든 85장. 서버 4회·admin 2회 배포 전부 SUCCESS+health 200,
> 릴리즈 APK 2회 빌드·에뮬(emulator-5554) 설치. 진행중 작업 없음 — 깨끗한 마무리.

## 완료
- [x] **잔여 검증 (인계 대기 2·3)**: 의심 4건 판정 = 실결함 1(수업 시간 칸이 wod.posted 미청취) ·
  환경 1(로컬 DB 고아 recipient 7행 × 쪽지 id 재사용 → 전 쪽지 무음 실패 — 데이터 수리로 해소) ·
  오탐 2(40kg 은 fork 의 `load_value` 키 착오 — 정본 `load_kg` / `#ecvar_price` 는 id 없는 name 필드).
  출석 +1 갈래·세션 공통↔D 이동·계약 서명 흐름·픽토그램·활동 요약(D105) 전부 정상 판정.
- [x] **개선 4건**: 앱 수업 시간 칸 `wod.posted` 청취(시간표 실시간) · 쪽지함 코치/활동 칸 hasError
  표시(골든 state_31, 85장) · 계약 발급 응답 note_sent/note_reason + 감사 `contract.note_failed`(무음 실패
  제거) · PC 계약 '대기'=signable + 발급 토스트 3갈래(구 'SMS 발송' 거짓 문구 폐기).
- [x] **SSOT 감사 (사용자 지시)**: 게이트 전벌 초록 확인 · 3면 CLAUDE.md 포인터 정상 ·
  `docs/SSOT/INDEX.md` 부록이 D88~D91 에서 멈춰 있던 것 발견 → D92~D106 + 09-02 부록 추가.
- [x] **이원화 정본화 7건** (각 건 정본+게이트 동시): 계약 SSE 이름 폴백 4곳 + 명단 로스터 5곳 =
  `member_display_name`(서버 "(이름 없음)" 리터럴 0, api·services 전역 린트) · 락커 D-day =
  `membership_dday`(앱 계산 삭제) · 환불 산식 = `_membership.refund_amount_for` + `GET
  members/<mid>/memberships/<msid>/cancel-preview`(preview==실행 게이트 4건) · 결제 refundable =
  `_metrics` 정본 필드 · 수정/해지 노출 = 서버 editable/cancellable 플래그 · 픽토그램 이름 55종 3벌 =
  팩 정본 + `picto_icons.gen.js` + sync --check·pytest 드리프트 게이트 2겹.
- [x] **결정 2건 집행**: 로스터 폴백 문구 통일("이름 미입력 (앱 가입 · 해시8)" — 로스터 테스트 갱신) ·
  수정 API 가드(`membership_actionable` 정본 한 곳, 해지 회원권 PATCH 422 NOT_EDITABLE — lifecycle test_13).
- [x] 계약 SSOT 린트 거짓 실패 해소 — **인계 커밋(a94997a) 시점부터 빨간불이었음** (08-12 원문 보기
  커밋의 '발급일' 라벨을 08-30 신설 린트가 몰랐음). 라벨 1줄 허용으로 정밀화, 가드 유지.

## 진행중
- 없음.

## 대기
- [ ] 1. **에뮬 스모크** — 설치된 릴리즈 앱 실행해 로그인·수업 탭·시간표 SSE 실물 확인 (오늘 안 함).
- [ ] 2. 시간표 **규칙** CRUD(`api/class_schedule_rules.py`) 는 SSE 무발행 — 규칙 실체화 슬롯은 여전히
  실시간 반영 안 됨 (수업 직접 등록·수정은 해결됨). 별건.
- [ ] 3. 서버 `member_reservation_created` 이벤트를 앱이 안 들음 (관찰만) · PC '현재 회원권 고르기'
  판정(`members.html:574·633` 등, 정본 후보 `governing_membership`) 서버 창구화 별건.
- [ ] 4. 이전 인계 잔여: movement_id 서버 필터 · 횟수권 회원 프로드 차감 문구 확인 · 자동 노쇼(추후).

## 결정사항 / 주의
- **폴백 문구 정본 = `admin.member_display_name` 하나** — "(이름 없음)" 은 서버 전역 린트 금지.
- **수정 가드 규약**: 만료일 지난 active 는 의도적으로 열려 있음(날짜 교정 용도) — 해지만 422.
- 로컬 DB(gym 1) 잔여물: 09-02 출석 1행(member 1) · 취소 휴면 수업 1행(id 16) · 서명 계약 #2(전자서명법상
  취소 불가) · 쪽지 id 9 · **데이터 수리 1건**(고아 recipient 7행 삭제 — raw sqlite 삭제가 남긴 오염이었음).
- 로컬 서버 2개 기동 중(5060·8081, 최신 코드) · 에뮬레이터 Medium_Phone_API_36.1 에 릴리즈 APK 설치됨.
- 도구 함정: bash grep -P 는 로케일로 침묵 실패 — Railway 상태는 `railway status --json` + python 파싱 ·
  curl 한글 body 는 파일 기반 전송 (콘솔 인코딩 400).
- 커밋: 서버 `9a5445b` 까지 5건 · PC `7c9f076` · 앱 auto-save 3건 — 세 repo 전부 push 완료.

## 관련 파일
서버 `api/_membership.py`(membership_actionable·refund_amount_for·refund_preview·membership_dday) ·
`api/admin.py`(로스터 폴백·수정 가드·cancel-preview·락커 d_day) · `api/contracts.py`(note_sent·이름 폴백) ·
`api/profile.py`(락커 d_day) · `api/payments_admin.py`(refundable) · `tests/test_{refund_preview_agreement,
membership_lifecycle,dashboard_roster,ssot_contract_lint,ssot_membership_label_lint,ssot_reward_lint,
locker_membership_sync,contract_flow_d102}.py` · `docs/SSOT/INDEX.md` /
PC `templates/{contracts,member_detail,settings_achievements,_layout}.html` · `tools/sync_pictograms.py` ·
`static/picto_icons.gen.js` /
앱 `lib/features/gym/week_board.dart`(wod.posted) · `lib/features/inbox/inbox_screen.dart`(hasError) ·
`lib/models/locker.dart` · `test/golden/states_golden_test.dart`(state_31) · `tool/golden_gallery.py`

## 다음 세션 권장 첫 프롬프트
`/resume` → 대기 1(에뮬 스모크) 실행 여부 확인.
