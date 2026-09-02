# HANDOFF - 2026-08-30 20:15

> 주제: **D99~D106 집행 + 회귀 검증 2회(1회차 완주·2회차는 사용자 중단 지시로 중간 종료).** 세 repo 전부 커밋·푸시됨(서버 `a94997a`·PC `3a195ff`·앱 아래 handoff 커밋).
> **배포·릴리즈 APK 는 하지 않았다** — 사용자 "다 끝나면 커밋 푸시 배포, 릴리즈 굽기까지" 지시가 있었으나 뒤이어 "이제 그만하라니까"·`/handoff` 가 와서 멈춤.
> 프로드는 D99~D101 까지만 올라가 있음(18:37 배포). 서버 전량 665 passed · 앱 232 passed · 골든 84장. 에뮬레이터에 앱 없음(디버그 빌드 제거됨).

## 완료 (상세 = `docs/ARCHITECTURE_BRIEF.md` D99~D106)
| # | 내용 |
|---|---|
| D99 | 휴강 = 예약 리셋+횟수 반환(종전) 게이트 · 규칙 수정·삭제에도 휴강 슬롯·취소 줄 보존(`_prune_future_slots`) — **프로드 배포됨** |
| D100 | 늦은 취소 토스트(서버 `notice{month,nth,toast}`·코치 자동 쪽지 `send_coach_note`) + 완료 저장 토스트(로딩바 → 하이피 "예____ 화이팅!!!!") — **프로드 배포됨** |
| D101 | 동작 사전 연관도순 검색 `GET /admin/movement-library?q=` + 띄어쓰기 무시 + PC 동작 칸 검색창 — **프로드 배포됨** |
| D102 | 전자계약 `contract_flags` 정본·초안 재생성·계약번호/발급일 `contract_auto_variables`·'계약서 도착' 쪽지·회원 서명 창구 검증(이미 있었음) — 미배포 |
| D103 | 리워드 트리거 매트릭스 17건·`reward_engine.progress_count`·`reward-meta`/`preview`·PC 빌더 JS 표 제거 — 미배포 |
| D104 | 회원권 생애주기 13건·`membership_calendar_fields`·`status_label`·`membership-plans/<id>/period`·정지 기간 밖 400·앱 Dart 계산 삭제 — 미배포 |
| D105 | 회원 활동 요약 `member_activity_summary`(출석 일수·최근 30일·자주 오는 시간) PC 회원 상세 헤더·수강 이력 탭 — 미배포 |
| D106 | 1회차 미비 수정: 이원화 2·라벨 사본·인라인 96→0·세션 공통↔D 프로그램 이동·`wod.posted` SSE·`attendance_added`·U+2011·`member_display_name`·요금제 기간 null — 미배포 |

## 진행중
- 없음 (2회차 검증 fork 는 중단됨 — 결과는 아래 대기 2).

## 대기
- [ ] **1. 배포 + 릴리즈 (사용자 지시분, 미집행)** — 순서: `cd C:\dev\services\hyphen && railway up --detach` → `cd C:\dev\web\hyphen-admin && railway up --detach` → health 200 확인(`/api/v1/health`, admin `/login`) → 앱 `flutter build apk --release --dart-define=API_BASE_URL=https://service-facing-production.up.railway.app` → `adb install -r build/app/outputs/flutter-apk/app-release.apk`(emulator-5554). 프로드 DB 마이그레이션은 `migrate_db()` 부팅 시 자동(신규 컬럼 없음 — D102~D106 은 표 추가 없음, 확인 필요: `grep -n "add_column\|CREATE TABLE" models/base.py` 최근 변경).
- [ ] **2. 2회차 검증 미완 항목 재확인** (V2 fork 중단): 앱 계약 서명 흐름·PC '서명 완료'(2회차 미도달) · V6 첫 저장 '출석 +1' 갈래·히스토리 상세 동작별 칸·도전 카드 · R1 세션 공통→D 실물 · R4 픽토그램 육안 · R5 회원 상세 계약서 탭 member_name.
- [ ] **3. 2회차에서 새로 의심된 것 (미확인)**: (a) 앱 쪽지함 활동 칸에 **'계약서 도착' 이 안 보임** — 알림 항목 `contract` 토글/SSE/필터 어느 쪽인지 미확인, 재현 = PC 발급 → 앱 활동 칸. (b) PC 에서 새 수업 등록 시 앱 **수업 시간 칸(시간표)** 은 주 이동 재조회 전까지 안 보임(프로그램 칸은 SSE 로 갱신됨). (c) 프로그램 카드 "Thruster 10회" 에 40kg 미표시 — fork 가 보낸 payload 키(`load_value`) 규약 차이 가능성, 결함 단정 못 함. (d) 계약 편집 모달 가격 필드 `#ecvar_price` 두 번째 열기 selector 타임아웃(playwright 측 문제일 수 있음).
- [ ] 4. 범위 밖 잔여 이원화(보고만): 락커 D-day(`models/locker.dart`, 서버 미제공) · 회원 상세 환불 미리보기 JS 계산 · 회원권 표 '수정·해지' 링크 노출 PC 판정 · 계약 SSE/이메일 `"(이름 없음)"` 4곳 · PC 픽토그램 라벨 55종 JS.
- [ ] 5. 사용자 원문 "기록 이내/기록 이상"(무게·시간 임계) 트리거는 **제품에 없음** — 추가 여부는 사용자 결정(먼저 제안 금지).
- [ ] 6. 횟수권 회원 프로드 차감 문구 확인 · 자동 노쇼(추후) — 이전 인계 그대로.

## 결정사항 / 주의
- **휴강은 코치가 다시 열기 전까지 휴강**(되살리는 창구 없음, 옛 예약 자동 복원 안 함) · **"N회째 레이트 캔슬" 은 회원×달 단위, 정책에 걸린 모든 선(경고만인 선 포함)** · **'출석 +1' 은 `attendance_added` 가 true 일 때만** · **쪽지함 상단 '공지' 카드는 D81 원문대로 존치**.
- 마스코트 이름 = **하이피**(메모리 `project-mascot-name-hipi`). 작업 방식 = fork 병렬 + 앱 worktree 격리 + 서버/PC 는 fork 커밋 금지 후 메인 통합(메모리 `feedback-use-subagents-actively`), 2회 검증·솔직 보고(`feedback-verify-twice-honest-gaps`).
- 로컬 `.env` `PORT=5060` 이 env 를 덮으므로 다른 포트는 `python -c "from app import app; app.run(port=N)"` 로. 로컬에 포트 없는 유휴 `python app.py` 프로세스 몇 개 잔존(fork 잔여, 5100 은 workcheck — 죽이지 말 것). 8081 netstat 에 죽은 소켓 항목 다수.
- 로컬 DB(gym 1): 검증 데이터는 원복됨. post 4 제목 "검색 검증 수업" 은 1회차 잔여(내용은 AMRAP·Thruster·Row 원복). 회원 `member`/1234.
- 서버 pytest 는 `pytest tests/` 전량으로. 앱 골든 84장, 갤러리 `python tool/golden_gallery.py` 양방향 OK.
- 실수 기록: F3 브랜치를 ff 실패 뒤 삭제했다가 해시(`cd1de03`)로 머지 복구 — 브랜치 삭제는 머지 확인 뒤에.

## 관련 파일
서버 `api/_membership.py`·`_metrics.py`·`admin.py`·`classes.py`·`contracts.py`·`gym.py`·`profile.py`·`reward_rules.py`·`notifications/note.py`·`services/reward_engine.py`·`services/history_search.py`·`contracts/pdf_generator.py`·`tests/test_{contract_flow_d102,reward_triggers_matrix,membership_lifecycle,membership_status_label_f2,member_activity_summary,late_cancel_toast_d100,class_cancel_reset_d99}.py`·`tests/test_ssot_{contract,reward,membership_label,history}_lint.py` / PC `templates/{contracts,member_detail,members,settings_achievements,settings_plans,_layout}.html`·`static/{pictogram.js,program_editor.js,style.css}` / 앱 `lib/features/classes/class_flows.dart`·`gym/wod_result_sheet.dart`·`history/*`·`profile/member_contracts_screen.dart`·`models/membership.dart`·`widgets/hkit.dart`(HkSnack.progress/dismiss)·`test/golden/*`

## 다음 세션 권장 첫 프롬프트
`/resume` → 대기 1(배포·릴리즈) 집행 여부 확인 후 실행 → 대기 2·3 재확인.
