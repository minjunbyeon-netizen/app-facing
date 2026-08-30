# HANDOFF - 2026-08-30 17:51

> 주제: **D91~D98 여덟 건 집행·검증·배포 완료.** 히스토리 완전 통합(정본 `gym_wod_results` 하나) → 연속일 서버 → 출석 하루 1회 → 동작별 완료 값 →
> 서버 검색 → 노쇼 정책 탭 → 노쇼 안내 알림 → 세션 칩(반복 시간표·게시 모달). 마지막에 **프로드 실검증 한 바퀴**(세션 규칙·게시 모달·취소 안내·노쇼 쪽지)
> 까지 통과. 세 repo(`services/hyphen`·`web/hyphen-admin`·`apps/facing-app`) 전부 커밋·푸시·배포됨, 워킹트리 깨끗. 에뮬레이터 = 프로드 APK(로그아웃됨 —
> 검증 회원 `d98test` 는 프로드에서 삭제). 로컬 서버 꺼짐. 서버 전량 594 passed · 앱 골든 100.

## 완료 (상세 = `docs/ARCHITECTURE_BRIEF.md` D91~D98 + 배선 정본 `services/hyphen/docs/SSOT/배선지도-D88~D91.md`(D98 까지 갱신))
| # | 내용 |
|---|---|
| D91 | 히스토리 완전 통합 — 탭·검색·상세·XP·카탈로그 업적·리워드·코치 명단이 `api/_metrics.py class_results_of` 계열로 `gym_wod_results` 직독. 거울 `history_mirror.py`·앱 `PrDetector`·`POST /history/wod` 폐기. `wods`·`pacing_*` 휴면. 게이트 `test_ssot_history_lint.py` |
| D92 | 홈 연속일 = 서버 `meta.streak_days`, Streak Freeze 폐기 |
| D93 | 출석 = 회원×체육관×날짜 1행 — `api/_metrics.attended_on` 관문(쓰는 손 4·세는 창구 3), FACTS 등재 |
| D94 | 동작별 완료 값 — 표 `gym_wod_result_movements`, 시트 코치값 프리필 → `movements[]`, 요약·판정 서버(`program_lines`), 골든 `state_28` |
| D95 | 히스토리 검색 서버 이관 — `GET /history/wod?q=` 연관도순 + 동작 사전 번호 일치(`services/history_search.py`) |
| D96 | 노쇼 정책 — 표 `gym_noshow_policies`, `_membership.py` 정본(gym_policies·cancel_policy_for·cancel_notice·cancel_message·charged_count·ledger_tier), 취소 스냅샷·`charged_sessions`, PC 알림 설정 [노쇼 정책] 탭, 앱 `cancel-preview` |
| D97 | 알림 항목 `noshow` '늦은 취소 · 노쇼 안내' — 취소·노쇼 처리 즉시 쪽지 (`policy_outcome`, 기간제는 '차감 없음' 문구) |
| D98 | 세션 칩 — 반복 규칙 `class_schedule_rules.variant`(실체화·변경 반영·`variant_options`) · 게시 모달 [수업 종류]×[세션] upsert(`free_items`·`display_name`) · 규칙 재실체화 flush 결함·수정 모달 제목 줄 결함·`esc` 미정의·프록시 PUT 405 잡음 |
| 실검증 | 로컬 PC 브라우저(노쇼 정책 탭·시간표 세션·게시 모달) + **프로드**(admin/1234 = 체육관 HYPHEN gym 2, 임시 회원 d98test → 삭제) |

## 진행중
- 없음.

## 대기 (사용자 결정)
- [ ] **취소된 수업의 남은 예약 정리 규칙** — 휴강 뒤 되살린 수업의 예약·횟수 점유 처리 (완료 게이트 `services/completion_gate.py`). 사용자에게 설명함(17:25), 결정 대기.
- [ ] 횟수권 회원으로 프로드 차감 문구('횟수권 1회가 차감') 확인 — 로컬 테스트로만 검증됨.
- [ ] 자동 노쇼(코치가 안 찍으면 노쇼 안 됨) — 사용자 "추후" (메모리 project-session-pass-rule).

## 결정사항 / 주의
- **출석은 하루 1회** (사용자 "1일은 1회만 출석임") · **노쇼 정책은 체육관 설정**(행 없으면 D57 기본) · 앱은 취소 판정을 하지 않는다(`cancel-preview`).
- 프로드 `gym 2 = HYPHEN` 이 **실제 체육관**(회원 실명 존재). 검증은 임시 회원 만들고 끝나면 삭제하는 방식으로만. 프로드 `member/1234` 없음(고정 계정 시드 삭제됨).
- 관리자 웹 프록시(`web/hyphen-admin/app.py proxy_passthrough`)에 PUT 추가됨 — 새 PUT 라우트는 이제 통과.
- 서버 pytest 는 `pytest tests/` 전체 또는 여러 파일 묶음으로(단일 파일은 모델 import 순서 오류). 테스트 DB 는 임시 폴더(conftest).
- 로컬 DB(gym 1) 검증 데이터는 정리됨(규칙·D 세션 글·노쇼 정책 기본으로). 에뮬레이터 TZ=GMT(표시 -9h).
- `SessionLocal(autoflush=False)` — 삭제 뒤 같은 트랜잭션에서 재조회하는 코드는 `s.flush()` 필요 (D98 에서 잡힌 유형).

## 관련 파일
서버 `api/_metrics.py`·`api/_membership.py`·`api/history.py`·`api/class_settings.py`·`api/class_schedule_rules.py`·`api/admin.py`(wod-posts)·`api/classes.py`(cancel·cancel-preview)·`services/history_search.py`·`services/program_lines.py`·`models/gym_noshow_policy.py`·`models/gym_social.py`·`tests/test_ssot_history_lint.py`·`test_noshow_policy_d96.py`·`test_session_chips_d98.py`·`test_e2e_sessions_flow_d89.py`(test_10~13) / PC `templates/notifications.html`·`class_templates.html`·`wod.html` / 앱 `lib/features/history/*`·`gym/wod_result_sheet.dart`·`classes/class_flows.dart`·`home/home_screen.dart` / 메모리 `project-movement-data-flow.md`·`project-session-pass-rule.md`

## 다음 세션 권장 첫 프롬프트
`/resume` → 대기 1(취소된 수업 예약 정리 규칙) 사용자 결정 받기.
