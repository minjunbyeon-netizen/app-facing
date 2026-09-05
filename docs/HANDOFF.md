# HANDOFF - 2026-09-06 07:22

## 완료

- [x] **D118 밀림 잔여 4건 + 버튼 폭 + 수업 탭 거짓말** — 채팅 전송 아이콘(입력바 65→129 원인은 가로: Center 가 폭을 먹음, `HkLoading.icon()` 신설) ·
      수업 상세 시트(바텀시트는 위로 자라 '아래로 내리기' 무효, `slotRequestNoticeH` 38) · 홈 도전 섹션(항상 세움) · 계약 목록(`HkReservedSlot`) ·
      `HkButton(busy:)` 폭 57.6→360 튐(투명 글자로 폭 붙듦, `test/button_busy_width_test.dart`) ·
      수업 탭이 실패를 '체육관 미가입' 으로 말하던 것(`class_tab_error_test.dart`). **§4 밀림 후보 10건 전부 해소.**
- [x] **D118-PC** 사문 부품 13건 전량 삭제 · 페이지 `<style>` 10→2 · 게이트 §7.8(사문 부품)이 3건 추가 검출(`.page-banner-slot` = 배너 아래 여백 3주 결함). 관리자 웹 Railway 배포됨.
- [x] **D119** 수업 줄 오른쪽 비우기 — '종료'·'오늘/이번 주 예약 완료' 배지 폐기, 높이 48 유지(`_emptyAction`, `test/class_row_clean_test.dart`).
- [x] **D120** 완료 시트 '수업 내용' `maxLines: 4` 잘림 해소(B 파트 안 보이던 것).
- [x] **D121** 파트 종류가 기록 칸을 정한다 — 계약 `docs/CONTRACT-result-axes.md`, 정본 `services/facing/services/result_axes.py`.
      **배포 직후 프로덕션 500 사고 수습**: `migrate_db` 가 `engine.connect()`(비커밋)라 D109 의 UPDATE 뒤 DDL 이 롤백됨 → 명시 `conn.commit()` + `tests/test_migrate_commits.py`.
- [x] **거짓 RXD 배지 삭제** — 고른 사람 없는 `scale_level='rx'` 를 히스토리 상세가 단정. `test/no_false_scale_badge_test.dart`.
- [x] **D122 전부 집행** (계약 `docs/CONTRACT-result-axes-2.md`, 사용자 "전부 집행") — 근력 무게 파생(v3.45 이후 죽어 있던 헤드라인·PR·1RM 보드·묶기 복구) ·
      강도 지문으로 비교 분리('20kg 로는 첫 기록') · 축을 서버가 내려줌(`score_keys` 등, 앱 종류 리터럴 0건) · EMOM '완료한 분' ·
      AMRAP `+ 회`·`round_reps`·PC 라운드 칸 잠금 · `set_reps` 프리필 · 히스토리 `parts[]`(완성 문장 `line`)·캡 배지 · 종류 5개 동결.
      서버 **771** · 앱 **329** · PC 린트 0. 서버 Railway 배포 반영 확인(첫 조회부터 OK).
- [x] **D123 체육관 시각 하나** — 사용자 "업계 표준대로": 표시·날짜 묶음·'오늘'·조회 범위 전부 Asia/Seoul. `.gym()`/`.gymDay()`(`lib/core/time_format.dart`),
      `lib/**` `.toLocal()` 51곳 교체, 기기 자정 생성 4곳 교체, 린트 2종(`test/ssot_lint_test.dart`). 사용자가 본 '예약 필요'·'예약 잔존' 증상 = UTC 에뮬의 날짜 묶음 어긋남이었고 해소 확인.
- [x] 빌드 **3033** AAB/APK · `store_preflight` 24 PASS · 에뮬레이터 설치·실측 완료. 3면 커밋·푸시 완료(앱 202661e · 서버 4b16da8 · PC 6a68bfc).

## 진행중

- 없음. 세 repo 작업 트리 깨끗, origin 과 일치.

## 대기

- [ ] **PC 관리자 웹 배포 안 됨** — D122 PC 커밋(6a68bfc: AMRAP 라운드 칸 잠금·라벨 서버화)은 푸시만 됨. `cd C:/dev/web/facing-admin && railway up`.
- [ ] **6-b 잔여 리터럴**: PC `static/program_editor.js` 상단 `ROUNDS_NOT_PRESCRIBED`·`SET_BASED_TYPES`(코치용 `program-meta` 에 축 실어야 지울 수 있음) ·
      앱 `lib/features/gym/wod_type_label.dart`(8곳 조립 — 서버 글 응답에 `wod_type_label` 이미 실림) · 앱 힌트 문구 `N 미만`·`N분 중`(서버 `score_hints` 후보).
- [ ] **폰(갤S22)에 3033 미설치** — 잠금으로 3031 까지만. `adb -s adb-R5CT503NB5M-r4Y2MU._adb-tls-connect._tcp install -r build/app/outputs/flutter-apk/app-release.apk`.
- [ ] 구글 플레이 AAB 업로드 (사용자 몫 — 계정·신분증).
- [ ] **검증 데이터 정리 여부(사용자 결정)** — 9/5 AWAKE 12:30·SWEAT 14:00·BUILD 14:30 수업+testmember1 기록, 9/7·9/10 AWAKE 글(사용자가 직접 작성). 하루 예약 한도는 1 로 복구됨.
- [ ] `migrate_db` 근본 정리 — D109 앞 33개도 명시 커밋 없음(조건부 DML 이라 잠복). `engine.begin()` 전환은 BEGIN 중첩·WAL 제약 얽혀 별건.
- [ ] PC `dead_utilities` 16(생성기 pruning) · 타이머 흐름(`wod_session_screen.dart`)이 옛 형식으로 제출(결과 쓰기 창구 둘).

## 결정사항 / 주의

- **표시도 체육관 시각(KST) 하나** — 대전제 4 의 '표시만 기기 시간대' 폐기(CLAUDE.md 반영됨, 메모리 `project-timezone-standard` 갱신). 사용자는 KST/UTC 논의 자체를 싫어함.
- **새 DDL 마이그레이션은 끝에 `conn.commit()`** — 없으면 롤백돼 프로덕션 500. `tests/test_migrate_commits.py` 가 D109 뒤를 강제.
- **기록 축 정본 = 서버 `services/result_axes.py` 하나.** 앱·PC 에 축 표·라벨 복제 금지(앱 린트: 종류 리터럴 집합 금지). 무게 축에는 강도 지문 필터 안 걸림(무게가 곧 점수).
- **난도 배지는 창구 없이 되살리지 않는다.** `scale_level` 은 휴면.
- 검사 수는 **러너가 센 값**만(D118 결정). 골든 **91장**.
- 서버 pytest 는 `python -m pytest tests/ -q`. 심사 계정 비번 = `services/facing` 에서 `railway variables`. 서버 확인은 `X-Device-Id: review-testmember1-device`.
- 에뮬레이터(UTC)는 이제 날짜 검증에 써도 됨(앱이 KST 표시). 폰 잠금 시 실기 확인 불가 — 사용자에게 해제 요청.
- **실수 주의**: 한 Bash 에서 `cd` 뒤 git 커밋이 다른 repo 로 들어간 일 2회 — 커밋은 폴더를 명시.

## 관련 파일

- 계약: `docs/CONTRACT-result-axes.md` · `docs/CONTRACT-result-axes-2.md` · 브리프 D118~D123 `docs/ARCHITECTURE_BRIEF.md`
- 앱 정본: `lib/core/time_format.dart`(gym/gymDay) · `lib/widgets/hkit.dart`(HkLoading.icon) · `lib/features/gym/wod_result_sheet.dart` · `lib/features/history/`
- 앱 게이트: `test/ssot_lint_test.dart`(toLocal·자정·종류 리터럴) · `test/result_axes2_test.dart` · `test/history_parts_test.dart` · `test/no_false_scale_badge_test.dart` · `test/class_row_clean_test.dart`
- 서버: `services/result_axes.py` · `services/program_lines.py` · `services/wod_compare.py` · `api/gym.py` · `api/history.py` · `models/base.py`(`_migrate_result_round_reps_d122`) ·
  `tests/test_result_axes_d122.py` · `tests/test_ssot_result_axes_lint.py` · `tests/test_migrate_commits.py`
- PC: `static/program_editor.js` · `templates/wod.html` · `design/lint.py` §7.8~§7.10 · `design/SSOT.md` §21

## 검증 상태

| 대상 | 결과 |
|---|---|
| 서버 pytest | 771 passed, 1 skipped |
| 앱 flutter test | 329 passed · analyze 0 |
| 앱 골든 | 91장 |
| PC design lint | 위반 0 · baseline 유지 |
| store_preflight | 24 PASS |
| 배포 | 서버 Railway 반영 확인 · **PC 관리자 웹 미배포(6a68bfc)** · 앱 에뮬 3033 설치, 폰 3031 |

## 다음 세션 권장 첫 프롬프트

`/resume`
