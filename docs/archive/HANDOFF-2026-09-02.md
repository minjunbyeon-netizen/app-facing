# HANDOFF - 2026-09-02 13:48

> 주제: **인계 잔여 2건(movement_id 필터·프로드 차감 문구) → 사용자 "1.2.3 전부" 지시로
> 규칙 SSE + 앱 동작 필터 + 에뮬 스모크까지 전부 구현·배포·실물 검증 완료.**
> 서버 680 passed·1 skipped / 앱 234 passed / 골든 86장. 서버 railway up 2회 SUCCESS+health 200.
> 진행중 없음 — 사용자가 다음 작업으로 "별건 2건"(아래 대기 1)을 선택한 시점에 인계.

## 완료
- [x] **movement_id 서버 필터 (D95 잔여 마감)**: `GET /history/wod?movement_id=` — '기록에 어떤
  동작이 들었나' 정의를 `program_lines.result_movement_ids` 한 곳으로 (result_has_movement·
  post_has_movement·검색 ids_by_item 전부 위임). q 병행 시 필터 뒤 연관도순, 비숫자 400.
  게이트 = `test_ssot_history_lint`(재정의 금지) + e2e d89 `test_15`. **운동 데이터 6단계 잔여 0**
  (메모리 project-movement-data-flow 갱신됨).
- [x] **횟수권 프로드 차감 문구 실검증 (08-30 잔여)**: 프로드 gym 2(HYPHEN)에 검증 전용 회원
  생성(가입 신청→승인→3회 횟수권) → 검증 수업 2건 늦은 취소. 1차 "이번은 면제되어 차감되지
  않았습니다." · 2차 **"횟수권 1회가 차감되었습니다."** + 잔여 3→2 정확 · 토스트 "9월, 2회째
  레이트 캔슬…" · cancel-preview 문구 전부 정문구. 로스터 폴백 "이름 미입력 (앱 가입 · 해시8)" 도
  프로드 실물 확인.
- [x] **시간표 규칙 CRUD SSE (잔존 갭 해소)**: 발행 정본 `api/classes.py publish_wod_posted`
  (공용 추출, 세션 좌표 선택 — `_publish_wod_posted` 는 위임). `class_schedule_rules.py` 생성
  (실체화>0)·슬롯이 바뀐 수정·삭제(프룬>0)가 좌표 없이 **한 발**씩, 슬롯 불변이면 무발행.
  게이트 = `test_rule_crud_publishes_wod_posted`. fork 구현 → 메인 검토·커밋·배포.
- [x] **앱 동작 필터**: 히스토리 상세 맨 아래 '동작별 기록 보기' HkBadge(내 동작별 값 ∪ 그날 운동,
  사전 번호 dedup) 탭 → 목록 pop 후 `?movement_id=` 필터. 필터 중 검색 칸 자리에 같은 규격
  읽기 전용 칸('동작: Thruster') — y 불변. `WodMovementRef` DTO 신설(movementLines 는 파생 getter).
  골든 hist_05 신규 + hist_04 재생성 = **86장**, 갤러리·CLAUDE.md 갱신.
- [x] **에뮬 스모크 (전부 실물 확인)**: 로컬 5060 재기동(최신 코드) + 로컬 URL 릴리즈 APK 빌드·설치.
  로그인(member/1234) → 수업 탭 프로그램 칸 → **앱 켜 둔 채** 코치 API 수업 생성 = 즉시 반영(D106)
  → **규칙 생성 = 29슬롯 즉시 등장 · 규칙 삭제 = 즉시 걷힘**(오늘 갭 해소 실증) → 히스토리 배지 탭 =
  Thruster 2건만 필터·해제 시 4건 복귀. 마지막에 **프로드 URL 릴리즈 빌드 재설치 + pm clear** —
  에뮬은 깨끗한 로그인 화면 상태.

## 진행중
- 없음.

## 대기
- [ ] 1. **별건 2건 (사용자 1번 선택 — 새 세션 첫 작업)**: ① 서버 `member_reservation_created`
  이벤트를 앱이 안 들음(관찰만) → 청취 여부 판단·배선 ② PC '현재 회원권 고르기' 판정
  (`web/facing-admin/templates/members.html:574·633` 등, 정본 후보 `governing_membership`) 서버 창구화.
- [ ] 2. 갤S22 실기기 프로드 확인 (제안만 한 상태 — 지시 없음).
- [ ] 3. 자동 노쇼 — 사용자 "추후" 그대로.

## 결정사항 / 주의
- **동작 포함 판정 정본 = `program_lines.result_movement_ids`** · **wod.posted 발행 정본 =
  `classes.publish_wod_posted`** — 둘 다 재정의 감지 게이트 있음. 조회 진입 자동 연장
  (`classes.py` 읽기 경로 materialize)은 **의도적으로 무발행** (재조회 연쇄 노이즈 방지).
- **프로드 검증 흔적 (gym 2 = HYPHEN)**: 회원 id 11 "차감문구 검증(테스트 계정)"(메모 있음) ·
  횟수권 membership 8(3회 중 1 차감·잔여 2) · 휴강 수업 325·326 · 코치 자동 쪽지 2건. 데이터
  보존 규칙대로 삭제 안 함. **프로드에 member/1234 로그인 계정 없음**(INVALID_LOGIN 확인 —
  TEST-ACCOUNTS.md 의 3계정 중 coach 만 실재. seed_test_accounts.py 파일 자체가 부재).
- 로컬: 5060 서버 최신 코드로 백그라운드 재기동됨 · 8081 admin 웹은 그대로 · 로컬 DB gym 1
  (이름 "RESV POLICY GYM" — 테스트 잔재 개명) 에 스모크 수업 BUILD id 17 잔재.
- 에뮬레이터(Medium_Phone_API_36.1) 시간대 = UTC — 시각 표시가 KST-9 로 보이는 건 규약
  (표시만 기기 시간대)이지 결함 아님.
- 커밋: 앱 `72f571a`(archive)·`5bab0d4`(동작 필터) · 서버 `70213de`(movement_id 필터)·
  `b6a15ad`(규칙 SSE) — 전부 push, 서버 railway up 2회 SUCCESS.

## 관련 파일
서버 `api/history.py`(?movement_id=) · `services/program_lines.py`(result_movement_ids) ·
`api/classes.py`(publish_wod_posted) · `api/class_schedule_rules.py`(발행 3곳) ·
`tests/test_{ssot_history_lint,e2e_sessions_flow_d89,class_schedule_rules}.py` ·
`docs/SSOT/{INDEX.md,배선지도-D88~D91.md}`(09-02 부록 갱신) /
앱 `lib/features/history/{history_models,history_repository,history_screen,history_detail_screen}.dart` ·
`test/golden/{fakes,screens_golden_test}.dart` · `tool/golden_gallery.py` · `CLAUDE.md`(골든 86장)

## 다음 세션 권장 첫 프롬프트
`/resume` → 대기 1(별건 2건) 착수.
