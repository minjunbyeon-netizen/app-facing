# HANDOFF - 2026-08-30 09:50

> 주제: **D88 운동 데이터 연동 1~3단계 집행(서버·PC) + 사용자 지시 E2E(코치 운동 짜기 → 회원 예약 → 완료 → 포인트·업적) 진행 중.**
> 세션 2026-08-29 23:31 ~ 08-30 00:31 (컨텍스트 99% 워치독으로 중단, 사용자 /handoff 09:50). 3 repo 커밋·푸시 완료, 워킹트리 깨끗.
> **배포 안 함** (E2E 마무리 뒤 `railway up`). 앱 코드 무변경 — 에뮬레이터에 **로컬 백엔드용 APK** 가 설치돼 있음(프로드 복구 필요).
> 새 절대규칙: **대전제 6-b 이음새** — 3면 CLAUDE.md·브리프 §2-0·메모리 `feedback-single-seam-single-compute`.

## 한 줄 요약
서버 `pytest tests/` **555 passed**(자정 경계 flake 1건은 00:30 뒤 재실행 통과) · PC 린트 baseline 유지 · 로컬 E2E 는 **마지막 '저장' 직전**.

## 완료 (상세 = `docs/ARCHITECTURE_BRIEF.md` D88-1 · D88-2·3)

| # | 내용 | 면 |
|---|---|---|
| D88-1 | **동작 사전 = `movement_library`(60)** 에 gym_id·unit·has_load·is_active + (gym_id,name_en) 복합 unique 재작성 · 표시 이름 = 영문 하나(`display_name=name_en`) · API `api/movement_library.py`(GET/POST/PATCH) + `GET /admin/program-meta`(종류·단위·분류 선택지) | 서버 |
| D88-1 | **그날 운동 구조 = 게시물 `rounds_data`**(movement_id·unit, 메모=round[0].content) · 정본 `services/program_lines.py`(WOD_TYPES·normalize·apply·render·program_of) · 수업 POST/PATCH·wod-posts POST/PATCH 가 `program` 수용 · `_sync_wod_post` 구조 유지/명시 삭제 규칙 · 린트 `tests/test_ssot_program_lint.py` | 서버 |
| D88-1 | 공용 편집기 `static/program_editor.js`(수업 수정·게시 모달) · '동작 라이브러리'→'동작 사전' 탭(추가·빼기) · 읽기 표시는 서버 content 그대로 | PC |
| D88-2 | **완료 = 예약한 사람만·수업 시작 후** — `services/completion_gate.py completion_check` 한 곳, 403 RESERVATION_REQUIRED / CLASS_NOT_STARTED, `gym_wod_results.class_session_id` | 서버 |
| D88-3 | **동작 조건 업적** — `gym_reward_rules.movement_id`(wod_log 만), 판정 `program_lines.post_has_movement`, `_sentence` "Thruster 포함 수업 기록 누적 1회 달성 시 30P 적립 + 업적 부여" · wod_log 트리거가 수업 결과(`gym_wod_results`)도 셈(이음새 결함 수정) · 규칙 빌더 '동작 (선택)' 드롭다운 + 프리셋 | 서버·PC |
| 곁가지 | 규칙 삭제→재생성 시 카탈로그 `RULE_n` UNIQUE 500(선재) → `create_rule` upsert + 회귀 테스트 · 로컬 DB 회원 기기 해시 불일치 원인 = 서버 salt(어제 이월) 해소 | 서버 |
| 규칙 | 대전제 6-b 이음새 3면 CLAUDE.md·브리프 반영 · GLOSSARY 동작 사전·동작·목표·메모 4행 · 메모리 저장 | 문서 |

### 로컬 실검증(완료분)
PC 수정 모달에서 Thruster 21-15-9 43kg + Row 500 저장 → 회원 API `rounds_data` 에 movement_id·unit → 에뮬 앱 카드 동일 본문 · 시작 전 '저장' → 서버 403 + 폰 문구 "수업 시작 후에 완료할 수 있습니다." · PC 빌더로 규칙 생성 성공.

## 진행중 — E2E 마지막 3스텝 (중단 지점)

로컬 서버 5060·관리자 웹 8081 이 켜져 있었음(재부팅했으면 `services/hyphen: python app.py` · `web/facing-admin: python app.py`). 로컬 DB gym 1(RESV POLICY GYM), admin/1234 · 회원 member/1234(device `member-phone-001`).
- 코치: 템플릿 AWAKE(id 1) · 수업 7(**08-30 00:21 시작**, AMRAP 캡10 · Thruster 10회 40kg · Row 250m, 게시물 id 4) · 규칙 1 "Thruster 첫 완료"(wod_log · movement_id 50 · lifetime 1회 · 30P · 업적 First Thruster RULE_1).
- 회원(에뮬 emulator-5554, 로컬 APK 10.0.2.2:5060 설치, TZ=GMT 라 화면 시각 -9h): 수업 7 예약 확정. 완료 시트(라운드 3)가 열려 있었음 — 닫혔으면 수업 탭 → 일 30 AWAKE 펼침 → 완료 표시 → 라운드 3.
- 기준값(저장 전): member_points 합 0 · user_achievements = RULE_2 만 · gym_wod_results 0 · gym_attendances 0.

- [ ] **1. 폰 '저장'** (`adb -s emulator-5554 shell input tap 540 2233` 또는 시트 재진입) → 기대: 저장 성공.
- [ ] **2. 확인**: DB `gym_wod_results` 1건(class_session_id=7) · `member_points` +30("규칙 달성 — Thruster 첫 완료") · `user_achievements` RULE_1 · `gym_attendances` source=self · 알림 쪽지(업적 해금). 앱 내 정보 30P · 홈/업적 First Thruster · 쪽지함 '활동' 칸. PC 회원 상세 포인트.
- [ ] **3. 배포**: `pytest tests/` 재확인 → `services/hyphen: railway up --detach` · `web/facing-admin: railway up --detach` → 헬스 → 프로드 부팅 로그 D88 마이그레이션(컬럼 4 + 표 재작성 + reward movement_id + wod_result class_session_id) 멱등 확인.
- [ ] **4. 에뮬 프로드 APK 복구 (필수)** — 3025 재설치 또는 `flutter build apk --release --dart-define=API_BASE_URL=https://service-facing-production.up.railway.app` 후 `adb -s emulator-5554 install -r`. 로컬 서버 끄기.
- [ ] **5. 문서 마감**: 브리프 D88-2·3 에 E2E 결과 줄 · 메모리 `project-movement-data-flow` 를 "1~3단계 집행" 으로 갱신 · `services/hyphen/docs/SSOT/INDEX.md` 상단 D88 주석(사전 정본·program 구조·게이트) · CLAUDE.md 골든 서술 무변경(앱 미변경).

## 대기 (다음 세션 이후)
- [ ] **취소된 수업의 남은 예약** — 코치가 수업을 취소했는데 예약 행이 confirmed 로 남으면 완료 게이트가 열림(에이전트 자기반박). 취소 경로가 예약을 항상 정리하는지 확인, 아니면 `completion_gate` 에 `ClassSession.status != 'cancelled'` 조건.
- [ ] 앱(6-b): 프로그램 카드가 제목 줄·머리줄을 카드 헤더와 겹쳐 두 번 보여줌 → 본문 첫 두 줄 접기 · `wodTypeLabel`/`WodMovementItem.displayLine` 영문 라벨을 서버 `wod_type_label`·`unit_label` 로.
- [ ] 2단계 앱 부분: 완료 입력의 **동작별 실제 값**(지금은 시트의 동작별 난도·무게 기록 칩만) · 3단계 후반: 히스토리 **동작 검색**(`rounds_data.movement_id` 기준).
- [ ] wod_log 는 날짜당 1회 정규화 — "매주 2회" 를 하루 두 수업으로 못 채움(기존 규칙, 코치 기대와 다를 수 있음 — 사용자 결정).
- [ ] 어제 이월: 미수금 환불 차단 프로드 미검증 · 매출 결제 축 노출 여부 · 프로드 데이터 2건 · 스토어 준비.

## 결정사항 / 주의
- **동작 사전 정본 = `movement_library`(60)** — 브리프 D88 원문의 "구 `movements` 23" 은 폐기 엔진 표라 정정. 이름 정본 = 영문(`name_en`), 한글은 `name_ko` 곁들임.
- 종류·단위·분류 선택지 = 서버 `program-meta` 한 곳(6-b). PC JS 에 매핑 표 없음. 읽기 표시는 서버 `content`.
- `_sync_wod_post`: program 미지정 = 구조 유지(폰 시트) · program=None 명시 + 메모 없음 = 템플릿 게시물도 삭제.
- 프로드 영향: 게이트 도입으로 template 연결 게시물을 **예약 없이 완료하던 회원은 403** — 앱은 서버 문구를 그대로 띄움(무변경).
- 리더보드 제목 라벨이 `WOD_TYPE_LABELS` 통일로 `For Time`→`FOR TIME`(PC 표기 변화).
- 검증 스크린샷이 앱 repo 루트에 떨어져 auto-save 가 커밋한 사고 1회(제거 완료) — playwright 캡처는 `.playwright-mcp/`(gitignore) 또는 scratchpad 로.
- 갤S22 실폰 미사용. 에뮬 TZ 는 GMT(표시만 어긋남).

## 관련 파일
| 영역 | 경로 |
|---|---|
| 구조·렌더 정본 | `services/hyphen/services/program_lines.py` |
| 동작 사전 | `services/hyphen/models/movement_library.py` · `api/movement_library.py` · `seeds/seed_movement_library.py` |
| 완료 게이트 | `services/hyphen/services/completion_gate.py` · `api/gym.py submit_wod_result` |
| 동작 조건 업적 | `services/hyphen/models/gym_reward.py` · `api/reward_rules.py` · `services/reward_engine.py` |
| 수업↔게시물 | `services/hyphen/api/classes.py _sync_wod_post` · `api/admin.py` wod-posts |
| 마이그레이션 | `services/hyphen/models/base.py` `_migrate_movement_library_d88` · `_migrate_reward_rule_movement` · `_migrate_gym_wod_result_columns` |
| 테스트 | `tests/test_movement_library_d88.py` · `test_program_d88.py` · `test_completion_and_movement_rule_d88.py` · `test_ssot_program_lint.py` · `test_reward_rules.py` |
| PC | `web/facing-admin/static/program_editor.js` · `templates/classes.html` · `templates/wod.html` · `templates/settings_achievements.html` · `static/style.css .pe-*` |
| 문서 | `docs/ARCHITECTURE_BRIEF.md` D88-1·D88-2·3·§2-0 6-b · `docs/GLOSSARY.md` · 3면 `CLAUDE.md` 대전제 6/6-b |

## 다음 세션 권장 첫 프롬프트
`/resume` → **진행중 1번부터** (로컬 두 서버 켜기 → 폰 '저장' → 포인트·업적 확인 → 배포 → 에뮬 프로드 복구 → 문서 마감).
