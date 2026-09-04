# HANDOFF - 2026-09-04 15:35

## 완료

- [x] **D109 파트** — 그날 운동을 한 수업 안 A·B·C 구간으로. 구 D89 세션(수업 시간에 글자 붙임) 폐기.
  - 정의 1곳 = `services/facing/services/program_lines.py` (`MAX_PARTS`·`part_label`·`part_title`·`api_rounds`·`normalize_program`·`apply_program`). PC·앱은 라벨·머리줄을 조립하지 않는다.
  - `class_sessions.variant`·`class_schedule_rules.variant`·`gym_wod_posts.variant` = **휴면**(읽지도 쓰지도 않음). 부팅 마이그레이션 `models/base.py _migrate_parts_d109` 가 값을 NULL 로 내리고 본문 첫 줄을 종류 이름으로 재렌더.
  - 프로드 실측 완료: 게시물 63(9/1)·64(9/3) 첫 줄 'SWEAT · B/A 세션' → 'SWEAT', `variant` 키 사라짐.
  - 덤 픽스: `services/reward_engine.py` — 한 완료로 업적 여럿 해금 시 앞 쪽지가 `database is locked` 로 죽던 것(세션당 리스너 1개 + 큐).
- [x] **D110 프로그램 보관함** — 코치가 파트 포함 프로그램을 이름 붙여 저장하고 수업 등록·수정·게시에서 불러온다.
  - 서버: 표 `gym_programs`(`models/gym_program.py`) + `api/programs.py` CRUD. 검증·미리보기·프리필은 전부 `program_lines` 재사용.
  - PC: `/programs` 페이지(보관함·동작 사전 두 탭, 사이드바 '수업' 그룹) · `templates/_movement_library_tab.html`(동작 사전 입구 복구 — 8/13 부터 사이드바에서 사라져 있었다) · `ProgramEditor.createLibraryPicker` 1벌을 세 모달이 공용.
  - 로컬 실브라우저 왕복 확인: 보관 → 수업 등록에서 불러오기 → 저장 → 회원 글 본문 렌더까지.
- [x] **D111 수업 탭 통합 한 줄** (사용자가 목업 3안 중 "1안" 선택) — 두 칸 세그먼트(프로그램/수업 시간)·요일 아코디언 폐기 → 주 이동 줄 + 요일 띠(`HkDayStrip`) + 그날 수업 줄.
  - 서버 전제 2줄: 모든 수업 직렬화(`class_public_fields`)에 `template_id` · 회원 `GET /gyms/<id>/wods` 에 `summary`(= `movement_summary`).
- [x] **D112 수업 탭 여닫기** (사용자 "오케이 이거 맞다" 로 확정) — 날짜를 누르면 **줄만**(시각·이름+화살표·정원·배지 넷뿐), 이름 옆 ∨ 나 줄 본문을 눌러야 그날 운동이 열리고 다시 누르면 닫힌다. **자동 펼침(구 `autoExpanded`) 폐기·함수 삭제**, 날짜·주를 옮기면 전부 닫힘, '프로그램' 밑 카드도 닫힌 채로.
  - D111 이 넣었던 접힌 줄 요약(`summary`) 줄은 삭제 (서버 키는 존치 — 지금은 앱이 안 그린다).
- [x] **D113 손가락 영역 48** — `HkBadge` 가 가로도 48(구 42), 요일 칸 48(칸 사이 간격 4→0), 여닫기 화살표 상자 48(구 32). 표시 전용 배지는 종전 크기.
  - 게이트 `test/touch_target_test.dart` — 상수를 비교하지 않고 실물 렌더를 `tester.getSize` 로 잰다.
- [x] **페르소나 5명 실사용 점검** — 실제 시간표 5타임으로 계측(임시 테스트는 삭제, 캡처만 사용자에게 전달). 이 점검이 D112·D113 을 낳았다.
- [x] **빌드 3027 · 배포** — 서버·PC 는 Railway 반영 완료, 앱은 master 푸시 + iOS CI 성공.
  - TestFlight 업로드 성공 (`gh run 33844109306`, app 6808162168). 안드로이드 APK/AAB 빌드 완료, 스토어 스크린샷 21장·아이콘·피처 그래픽 재생성, `tool/store_preflight.py` **24 PASS 0 FAIL**.
  - 폰 직배포 = GitHub Release `v1.0.0-3027` (arm64 25MB · universal 61MB). ⚠ split APK 는 `versionCode` 가 5027 로 찍힌다(Flutter ABI 오프셋) — Play 업로드는 AAB 로.

## 진행중

- 없음. 작업 트리 깨끗(`git status` 0), 서버·PC·앱 3면 모두 커밋·푸시·배포 완료.

## 대기

- [ ] **실기 확인** — 사용자가 APK/TestFlight 설치 후 수업 탭을 직접 눌러 보기. 지금까지는 골든·가짜 백엔드·로컬 브라우저 검증뿐이고 실기 확인은 없음.
- [ ] **구글 플레이 업로드** — AAB 3027(`build/app/outputs/bundle/release/app-release.aab`, 49MB)을 콘솔 테스트 트랙에 올리기. 절차 = `docs/STORE-SUBMIT-SHEET.md`.
- [ ] **사용자 미결 개선 3건** (페르소나 점검에서 제안, 폭 48 만 채택됨)
  - 요약 두 줄 + 펼친 카드 머리에 수업 이름 · 지난 수업 한 줄 접기 · 하루 한도/대기 이유 한 줄.
  - 비교 데모: https://gist.githack.com/minjunbyeon-netizen/6d10338fdebcdb4f73aa774fd525e11b/raw/class-tab-fixes.html
- [ ] **프로드 회원 피드 실기 확인** — 9/1·9/3 SWEAT 카드가 폰에서 한 장으로 뜨는지 눈으로. 서버 테스트·fakes 로만 검증됨.
- [ ] (선택) 홈 '오늘 내 예약' 카드를 수업 줄 문법에 맞추기 — 지금은 문법이 다름.

## 결정사항 / 주의

- **파트 ≠ 세션.** A·B·C 는 한 수업 안의 구간이지 다른 운동이 아니다. "세션을 수업 시간에 붙이자" 재제안 금지. 정본 = 브리프 D109.
- **수업 탭은 닫힌 채로 연다.** 자동 펼침 재도입 금지. 접힌 줄은 네 가지(시각·이름·정원·배지)만. 정본 = 브리프 D112 · `lib/features/gym/week_board.dart`.
- **정의는 서버 한 곳** — 라벨·머리줄·요약·검증·완료 게이트 전부 `program_lines`/`completion_gate`. PC JS·앱은 API 값을 그대로 그린다(6-b 절대규칙).
- **검사가 펼친 본문에 닿을 때** = `test/golden/harness.dart` 의 `openClassRow(tester, classId)` · `openProgramCard(tester, postId)`.
- 서버 테스트는 반드시 `python -m pytest tests/ -q` (인자 없이 돌리면 수집 오류).
- 선택지는 번호·기호(가/나/다) 대신 **이름**으로 제시할 것 — 이번 세션에서 '가' 가 답변마다 달라져 사용자가 혼동했다.

## 관련 파일

- 계약 정본: `docs/ARCHITECTURE_BRIEF.md` D109·D110·D111·D112·D113
- 앱: `lib/features/gym/week_board.dart` · `lib/features/classes/class_line.dart` · `lib/widgets/hkit.dart`(HkBadge·HkDayStrip) · `lib/models/gym.dart`·`class_session.dart`
- 앱 검사: `test/golden/class_tab_test.dart` · `test/golden/stability_wod_test.dart` · `test/golden/program_order_test.dart` · `test/touch_target_test.dart` · `test/golden/harness.dart`
- 서버(`C:/dev/services/facing`): `services/program_lines.py` · `api/classes.py` · `api/gym.py` · `api/admin.py` · `api/programs.py` · `models/gym_program.py` · `models/base.py _migrate_parts_d109` · `tests/test_program_parts_d109.py` · `tests/test_programs_library_d110.py`
- PC(`C:/dev/web/facing-admin`): `static/program_editor.js` · `templates/programs.html` · `templates/_movement_library_tab.html` · `templates/classes.html` · `templates/wod.html` · `templates/class_templates.html`
- 스토어: `docs/STORE-SUBMIT-SHEET.md` · `tool/store_preflight.py` · `build/store/**`

## 검증 상태

| 대상 | 결과 |
|---|---|
| 서버 pytest | 706 passed, 1 skipped |
| 앱 flutter test | 246 passed · analyze 0 |
| 골든 | 89장 (D112 19장 · D113 21장 재생성) |
| PC design lint | 위반 0 · baseline 유지 |
| 스토어 preflight | 24 PASS 0 FAIL |

## 다음 세션 권장 첫 프롬프트

`/resume`
