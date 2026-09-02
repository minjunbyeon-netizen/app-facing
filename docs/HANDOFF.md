# HANDOFF - 2026-09-02 22:52

> 주제: **세션 이동 경고(D107) · 주간 예약 오픈(D108) · 완료 시트 초간소화(v3.45) ·
> 예약 직후 stale 배지 픽스 · 예약→완료→히스토리 프로드 E2E 실검증 + 상세 검은막대 픽스.**
> 서버 695 passed·1 skipped / 앱 237 passed / 골든 89장 / 서버·관리자 웹 Railway 배포 라이브.

## 완료
- [x] **D107 세션 이동 확인 게이트** — PC 수정 모달 '+ 세션 추가'(실은 이동)로 옛 세션의
  마지막 수업을 옮기면 게시물이 소멸하던 함정. 판정을 `_orphan_variant_post`(실제 삭제
  `_drop_orphan_variant_post` 와 같은 함수, 6-b)로 분리 → 확인 없이 온 이동은 409
  `VARIANT_MOVE_DROPS_POST`, PC 가 서버 문구 그대로 묻고 `confirm_drop_post` 재전송.
  PC 실물 검증(취소=무변화·확정=이동+게시물정리) 완료. 커밋 서버 `b05f829`·웹 `3225091`.
- [x] **D108 주간 예약 오픈** — `gym_class_settings.booking_open_weekday`(0=월~6=일, NULL=매일
  방식) 신설. 값 있으면 수업 주(월~일)의 **전 주 그 요일** `booking_open_hour` 시에 그 주
  전체 일괄 오픈. 판정 정본 `api/classes.py booking_open_at` 한 곳(앱 무변경). PC 예약설정
  방식 셀렉트(제한없음/매일/매주). PC 실검증(일요일 19시 저장·해제) 완료. 커밋 서버
  `3e1ad0f`·웹 `a1a1d9f`. 부팅 idempotent ALTER `_migrate_booking_open_weekday`.
- [x] **앱 v3.45 완료 시트 초간소화** — 사용자 "코치 운동 그대로 + 내 기록만". '내 결과'
  점수 칩(시간/라운드/무게)·난도(SCALED/RXD)·동작이름·strength 전용칸 전부 삭제. 남은 것 =
  수업 내용 + '내 기록'(코치 운동 목록 [한 횟수][무게] 프리필, 무게 칸 항상) + 저장. 점수·
  난도·메모 키 안 보냄 → 히스토리 label 빈 문자열, 요약은 동작별 값. 커밋 앱 `a248418`.
- [x] **예약·취소 직후 stale 배지 픽스** — 완료 배지(`completion_blocked`)는 회원별 판정인데
  예약 성공 후 classes·회원권만 재조회하고 wods 를 안 불러 '예약 필요'·"예약한 수업만" 옛
  판정이 남던 결함. `GymState.refreshWods()` 신설 + 주간보드 onReserve/onCancel 배선. 회귀 =
  state_27 흐름에 wods 재조회 검증(FakeApi.calls). 커밋 앱 `9d5b247`.
- [x] **프로드 E2E 실검증(에뮬 + gym 2)** — 예약(예약됨+폭죽) → 시작 후 완료(코치 40kg 프리필
  → 내 45kg 입력 저장) → 히스토리 요약 'Thruster 21-15-9·45kg'(내 값 반영) → 'Thruster'
  검색 필터 → 상세 동작별 기록/수업 내용(코치 40kg) 분리, 동작별 검색 배지. 전부 정상.
  서브에이전트로 서버 히스토리 API 표기·검색·필터 로직 코드 교차검증(설계대로).
- [x] **상세 검은막대 픽스** — v3.45로 점수 없는 기록의 상세가 빈 label('-')을 64sp 히어로로
  그려 검은 막대처럼 보임. label 있을 때만 히어로 줄(+난도 배지) 그리고 없으면 숨김. 골든
  hist_06_detail_no_score 신규(89장). 앱 237 통과. 커밋 앱 `91ca0e9`. 프로드 URL APK
  재빌드·에뮬 설치 완료.

## 진행중
- (없음 — 지시 3건 + 파생 픽스 2건 전부 완결·배포)

## 대기
- [ ] 1. **프로드 테스트 잔여 정리** — E2E로 프로드 gym 2 에 만든 SWEAT 수업(id 328, 09-02
  22:34)과 그 완료 기록(회원 device — Thruster 45kg)이 실데이터에 남아 있음. 취소한 id 327
  도 cancelled 로 존재. 사용자 결정 대기(지울지/둘지). DB 사용자 데이터라 임의 삭제 금지.
- [ ] 2. **서브에이전트 의심점 4건** — ① movements=[] 빈 배열 제출 시 동작 행 전멸(v3.45
  경로는 구조화 글이면 안전하나 방어 필요) ② load_kg=0 허용 비대칭(게시물은 >0만) ③ 검색
  날짜 칸이 created_at(저장일) 기준 — 수업일과 다르면 안 맞음 ④ 검색·필터 상한 1000.
- [ ] 3. **시각 경과 자동 갱신** — 화면 연 채 수업 시작 시각이 지나도 완료 배지가
  자동으로 안 바뀜(지금은 새로고침/재조회 필요). 실사용엔 큰 문제 아니나 UX 개선 여지.
- [ ] 4. **apscheduler 미설치(기존 갭)** — 프로드 부팅 로그 "expiry_scheduler import 실패"·
  "APScheduler 미설치" — DB 백업·만료 자동 알림 스케줄러가 프로드에서 조용히 꺼져 있음
  (로컬만 동작). requirements 에 APScheduler 추가하면 살아남. 오늘 변경과 무관.

## 결정사항 / 주의
- **예약은 앱에서만·시작 전만** — 코치 대리 예약 API 없음(`api/classes.py:368` 주석). 주간보드
  `isOver`(시작 시각 경과)로 시작 후 수업은 '종료' 배지 → 예약 불가. 완료는 시작 후. E2E는
  '지금+2분 시작' 수업으로 예약 후 대기해 우회.
- **에뮬 타임존 = KST 필수** — 대전제(전 체육관 KST). 에뮬이 UTC면 수업 시각이 9시간 어긋나
  '종료'로 오판. `emulator -timezone Asia/Seoul` 로 기동. 프로덕션 빌드라 setprop 불가.
- **v3.45 부작용(수용)** — 새 완료 기록엔 점수가 없어 PR 비교·폭죽·1RM 보드가 새 기록엔
  동작 안 함(사용자 지시의 직접 결과). 상세 히어로/난도 배지도 새 기록엔 안 뜸.
- **에뮬 상태** — 프로드 URL v3.45 최신 APK 설치·로그인 유지. 로컬 5060/8081 서버는 D108
  코드로 기동 중(gym 1). PC playwright 는 프로드 관리자 웹(gym 2) 코치 로그인 상태.
- **커밋 전부 push + 서버·웹 Railway 라이브** (앱은 배포가 아니라 APK 빌드).

## 관련 파일
서버 `api/classes.py`(booking_open_at·_orphan_variant_post·admin_patch_class D107 게이트) ·
`api/class_settings.py`(weekday CRUD) · `models/gym_class_settings.py`·`models/base.py`
(마이그레이션) · `tests/test_program_variants_d89.py`·`test_booking_window_revoke.py`·
`test_class_settings.py` /
웹 `web/facing-admin/templates/settings_reservations.html`(예약 방식 셀렉트) ·
`templates/classes.html`(D107 다이얼로그) /
앱 `lib/features/gym/{wod_result_sheet,gym_state,week_board}.dart` ·
`lib/features/history/history_detail_screen.dart` · `test/golden/{fakes,states_golden_test,
screens_golden_test}.dart` · `tool/golden_gallery.py`

## 다음 세션 권장 첫 프롬프트
`/resume`
