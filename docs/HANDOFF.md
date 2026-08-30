# HANDOFF - 2026-08-30 11:38

> 주제: **D89 수업 세션(A·B·C) + 3중 E2E 검증 + D90 히스토리 정본화(거울 단계) 완료. 다음 = 사용자 지시 "완전 통합하고 어디에 무엇을 배선해 뒀는지 적어 두고 저장해 둬".**
> 세션 09:52 ~ 11:38 (컨텍스트 99% 워치독). 3 repo 커밋·푸시 완료, 워킹트리 깨끗. 백엔드·관리자 웹 Railway 배포 완료(D89·D90). 에뮬레이터 = 프로드 APK, 로그아웃 상태. 로컬 서버 꺼짐.

## 한 줄 요약
코치 프로그램 → 완료 시트 자동 반영 → 결과 → 포인트·업적은 세 방식(UI·HTTP 테스트·DB 재계산)이 같은 값. 히스토리 탭은 D90 으로 **서버가 같은 트랜잭션에서 거울 행을 쓰는 단계**까지 왔고, **정본을 직접 읽는 완전 통합**이 다음이다.

## 완료 (상세 = `docs/ARCHITECTURE_BRIEF.md` D89 · D90)
| # | 내용 | 면 |
|---|---|---|
| D89 | 수업 세션 A·B·C — `class_sessions.variant`·`gym_wod_posts.variant`, 정의 정본 `services/program_lines.py`(normalize_variant·variant_label·display_title·free_variants), 완료 게이트·게시물 키·취소 판정에 세션 포함, `GET /admin/gyms/<id>/program-variants`, 모든 수업 직렬화 `display_title` | 서버 |
| D89 | 수업 등록·수정 모달 세션 칩(공통·A·B·+세션 추가) + 등록 모달 운동 편집기 (`ProgramEditor.createVariantPicker`) | PC |
| D89 | 수업 줄·예약·알림 = `displayTitle`, 프로그램 카드 (종류×세션) 중복 판정·`displayName`, 골든 12장 | 앱 |
| 검증 | ① UI(PC playwright + 에뮬 adb) ② `tests/test_e2e_sessions_flow_d89.py` 8건 ③ 서브에이전트 DB 재계산 — 105P·RULE_2/3/4·활동 쪽지·PC 회원 상세 일치 | 3면 |
| D90 | 히스토리 거울: `services/history_mirror.py`(history_note·detect_pr·mirror_class_result) 가 `submit_wod_result` 와 같은 트랜잭션에서 `wods` 행 upsert(키 `wods.gym_result_id`, 백필·중복 연결 해제 멱등). 앱 2차 POST 삭제, 목록 `scoreDisplay`(시간 없으면 `5R`). `wod_my_history` 는 `wod_post_id` 로도 잡음. 카탈로그 업적 쪽지 = `send_member_note` 일원화(`achievement_checker._send_congratulation`). 테스트 `tests/test_achievement_note_d90.py` | 서버·앱 |

## 진행중 — 사용자 지시 (다음 세션 첫 작업)
- [ ] **히스토리 완전 통합** — 히스토리 탭·검색·상세, XP/레벨, 카탈로그 업적(`achievement_checker.wod_count`·`_detect_pr` XP)이 **`gym_wod_results` 를 직접 읽고 세게** 하고 거울(`wods` 쓰기)을 폐기. 지금 원천 지도:
  - 히스토리 탭 목록 = `GET /api/v1/history/wod`(`api/history.py list_wod_history`, 표 `wods`+`pacing_plans`) ← 앱 `lib/features/history/history_repository.dart`·`history_models.dart WodHistoryItem`·`history_screen.dart`·`history_search.dart`
  - 히스토리 상세 = `GET /api/v1/history/wod/<id>`(`get_wod_detail`, items·plan·segments) ← `history_detail_screen.dart`
  - 게시물별 내 기록 = `GET /gyms/<g>/wods/<post>/my-history`(`api/gym.py wod_my_history`, 이미 정본)
  - XP·레벨 = `wods.xp_awarded`(PR 250) — 홈 레벨 카드 원천을 찾을 것(`api/achievement.py`·`services/achievement_checker.py` 근처)
  - 카탈로그 업적 `wod_count`·`season_wod_count` = `achievement_checker._wod_count`(표 `wods` profile_id 기준)
  - 거울 쓰기 = `services/history_mirror.py mirror_class_result` ← `api/gym.py submit_wod_result`
  - 설계 권장: 히스토리 API 가 `gym_wod_results`(+게시물 rounds_data·display_name) 를 직렬화하고 id 공간을 결과 id 로 통일, 옛 `wods` 행(엔진 시절·'수업 #' 아닌 것)은 읽기 전용 병합 또는 제외 — **표·데이터는 지우지 않는다**. PR/XP 는 `wod_compare`(is_pr) 한 곳으로.
- [ ] **배선 문서** — "어디에 무엇을 배선해 뒀는지" 를 한 곳에: 후보 = `services/hyphen/docs/SSOT/` 에 `배선지도-D88~D90.md`(원천 표 → API → 앱/PC 화면 → 게이트 테스트, 한 줄씩) + INDEX 상단 링크 + 브리프 D91. 위 원천 지도를 씨앗으로.

## 대기
- [ ] 출석 규칙(하루 여러 수업 완료 = 1회?) 사용자 결정 · 반복 시간표 규칙에 세션 지정 · wod.html 게시 모달 세션 칩 · 취소된 수업 예약 정리(완료 게이트) · 앱 동작별 완료 값 입력(D88 2단계 잔여).

## 결정사항 / 주의
- 로컬 검증 DB(gym 1): 규칙 2·3·4, 수업 13·14·15, 결과 2·3·4, `wods` 46 은 미연결 중복 행(보존). 프로드 무변경(데이터).
- 에뮬레이터 TZ=GMT(표시 -9h). adb 로 시트 입력 시 ESC(keyevent 111) 는 시트를 닫는다 · IME 도구막대(x<170) 가 왼쪽 칩을 가린다.
- 서버 pytest 는 `pytest tests/` 전체로(단일 파일은 모델 import 순서로 에러).

## 관련 파일
`services/hyphen/services/history_mirror.py` · `api/gym.py`(submit_wod_result·wod_my_history) · `api/history.py` · `services/achievement_checker.py` · `models/wod.py`·`models/base.py _migrate_wod_columns` · `tests/test_e2e_sessions_flow_d89.py`·`test_achievement_note_d90.py`·`test_program_variants_d89.py` · 앱 `lib/features/history/*`·`lib/features/gym/wod_result_sheet.dart` · 브리프 D89·D90 · `services/hyphen/docs/SSOT/INDEX.md`

## 다음 세션 권장 첫 프롬프트
`/resume` → 진행중 1·2 (완전 통합 → 배선 문서 → 테스트·배포).
