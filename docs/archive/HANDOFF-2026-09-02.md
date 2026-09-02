# HANDOFF - 2026-09-02 17:49

> 주제: **회원 예약·완료 UX 3건 — 세션 추가 검증(보고만) + 하루 한도 배지(완결) +
> 완료 버튼 정직화·시트 다이어트 v3.44(코드 완결, 실물 확인만 남음).**
> 서버 687 passed·1 skipped / 앱 236 passed / 골든 88장 / Railway SUCCESS 16:13.

## 완료
- [x] **세션 추가 검증 (사용자 보고 "A 세션 날라감")**: 재현 성공 — 원인은 수정
  모달 "+ 세션 추가"가 추가가 아니라 **이 수업을 그 세션으로 이동**시키는 것.
  유일한 A 수업이 B 로 옮겨가면 서버 `_drop_orphan_variant_post`(D89 의도)가 A
  게시물 삭제 + PC 가 빈 program 을 실어 보내 `_carry_program_on_variant_move`
  보호도 무효 → 내용 소멸. 4경로 검증: 등록 모달·수업 내용 게시(/wod)·시간표
  규칙은 정상, 수정 모달만 함정. **코드 수정 안 함 — 보고만** (사용자 방향 미결정:
  경고 다이얼로그 안 ⭐ / 라벨 '세션 이동' 안 / 설계대로 안).
- [x] **하루 한도 배지 (사용자 지시)**: 예약한 날 다른 수업은 '예약' 대신
  '오늘 예약 완료'(주 한도 '이번 주 예약 완료') 배지, 탭하면 서버 409 문구 스낵바.
  서버 `reserve_limit_reached` 판정 분리(게이트 `_daily_limit_blocked` 는 409 포장만)
  → 회원 수업 목록 필드로 내려줌. 등록제 '예약 한도' 사실 등재 + 값 대조 2건.
  골든 state_32. **에뮬 실물 검증 완료** (예약 즉시 무접촉 배지 전환 + 탭 스낵바).
- [x] **완료 버튼 정직화 + 시트 다이어트 v3.44 (사용자 지시)**:
  · 예약 없는 글 '예약 필요' · 시작 전 글 '수업 시작 전' 배지 — 서버
    `completion_blocked`(제출 게이트 completion_check 와 같은 함수) + 문구.
    탭 = 서버 문구 스낵바, 시트 안 열림. 등록제 '완료 게이트' 등재 + d88 test_11~13.
  · 시트: 메모·'무게 기록(선택)' 병기·fallback 내 무게 칸 삭제 — 수업 내용 →
    점수 칩 → 동작별 기록(코치 값 프리필) → 저장뿐. notes 는 앱이 안 보내고
    서버가 키 없으면 종전 값 유지 (movements 와 같은 계약).
  · 덤 픽스: 저장 중 칩 onTap null 로 높이가 줄어 66px 밀리던 기존 결함 —
    onTap 유지+내부 가드로 고정 (stability_result_sheet_test 가 잡음).
  · 골든: state_33 신규 · member_06/06b·state_28/29 재생성 (88장). 갤러리·CLAUDE.md 갱신.
- [x] 검증·배포: 서버 pytest 687 / 앱 flutter test 236 / 두 레포 push /
  `railway up` SUCCESS(16:13) / 로컬 5060 신코드 재기동.

## 진행중
- [ ] v3.44 에뮬 실물 확인: 로컬 URL 릴리즈 APK **빌드까지 완료**(16:14,
  build\app\outputs\flutter-apk\app-release.apk = 로컬 URL 빌드) — 중단 지점 =
  에뮬(emulator-5554) 설치·확인 직전. 컨텍스트 80% 경고로 중단.
  확인 시나리오: member/1234 로그인 → 수업 탭 프로그램 칸 → 오늘 BUILD 카드가
  '완료 표시' 대신 **'예약 필요'**(member 는 오늘 예약 없음) → 탭 = 서버 문구 스낵바.

## 대기
- [ ] 1. **프로드 URL APK 재빌드** — ⚠ 현 디스크 산출물은 로컬 URL 빌드.
  `flutter build apk --release --dart-define=API_BASE_URL=https://service-facing-production.up.railway.app`
- [ ] 2. 갤S22 실기기 설치 (폰 adb 연결 시 — 현재 에뮬만 연결).
- [ ] 3. 세션 이동 UX 픽스 방향 결정 (위 '세션 추가 검증' 3안 — 사용자 결정 대기).
- [ ] 4. 완료 시트 잔여 개선(분석만): 시간 입력 자유 텍스트 — 오타·빈 값이면
  점수 없이 조용히 저장 (서버도 빈 점수 안 거름). 지시 없으면 착수 금지.

## 결정사항 / 주의
- **완료 = 예약자만·시작 후** 게이트는 종전대로 서버 정본 — 이번 건은 그 사실을
  버튼이 미리 말하게 한 것뿐. 코치 기기는 completion_blocked null.
- **notes 계약 변경**: 키 없으면 서버 보존. 옛 앱(notes 항상 전송)과 호환.
- **로컬 상태**: gym 1 `daily_reservation_limit=1` 로 바꿔 둠(한도 배지 검증용 —
  안 되돌림). 09-03 수업 25(10:30, member 예약 1건)·26(12:30) · 09-04 AWAKE A·B
  수업+게시물 잔재(세션 검증 증거). 8081 admin 웹 playwright 세션 로그인 상태.
- **에뮬**: 로컬 URL 구버전 APK + member/1234 로그인 상태 (새 APK 설치 전).
- 커밋: 앱 `360d905`(한도 배지)·`f36a46c`(v3.44) / 서버 `35eac48`(한도)·
  `20058d6`(완료 게이트) — 전부 push + Railway SUCCESS.

## 관련 파일
앱 `lib/features/gym/{wod_result_sheet,wod_row,gym_repository}.dart` ·
`lib/models/{gym,class_session}.dart` · `lib/features/classes/class_line.dart` ·
`test/golden/{states_golden_test,fakes,stability_result_sheet_test}.dart` /
서버 `api/gym.py`(list_wods·submit_wod_result) · `api/classes.py`(reserve_limit_reached) ·
`services/completion_gate.py`(정본, 변경 없음) ·
`tests/test_{completion_and_movement_rule_d88,reservation_policy,ssot_agreement}.py`

## 다음 세션 권장 첫 프롬프트
`/resume`
