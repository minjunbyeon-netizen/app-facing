# HANDOFF - 2026-09-06 11:59

## 완료

- [x] **D124 (3면)** — 6-b 잔여 사본 3곳 제거. 서버 `result_axes.part_score_hints`(파트 `score_hints` 문장)·`editor_axes`(program-meta `rounds_prescribed`·`set_based`) → 앱 `wod_type_label.dart` 삭제(모델 `GymWodPost.wodTypeLabel`)·힌트 조립 삭제 · PC `ROUNDS_NOT_PRESCRIBED`·`SET_BASED_TYPES` 삭제(`typeMeta()`). 게이트 3면 심어서 잡힘 확인. 커밋 서버 2228d51 · PC 935723c · 앱 0a936dd.
- [x] **배포** — 서버 `railway up` 반영 확인(실서버 응답 `score_hints`·`wod_type_label`) · PC 관리자 웹 `railway up` 반영 확인(배포 JS 에 `typeMeta`, 옛 리터럴 0). 앱 3034 APK/AAB 빌드 · preflight 24 PASS · 에뮬 설치·실행 확인.
- [x] **가시성 점검 보고서** — `docs/audit-visibility-2026-09-06.html`(a13753b, 브라우저로 열어 렌더 확인). 증상 3 → 원인 4(A 숫자 칸 전폭 · B placeholder 라벨 2.56:1 · C 행동 배지 micro 13sp · D 묶음 제목 위계 역전) + 대비 실측표 + 화면별 소견.
- [x] **D125 완료 시트 가시성 집행** (사용자 "1" → "ㄱ", 826330c) — `HkNumberField`(HKit 신설, worktree fork 5035577 merge) · 세트 한 줄 `1세트 [100] kg × [5] 회` · `HkSectionLabel(strong:)` · 시트 3층(머리 고정·본문 스크롤·저장 바 고정) · 검사·골든은 `Scaffold(body:)` 에 직접 마운트. 골든 5장 재생성(member_06·06b·state_28·29·34) 91장 불변. 전체 342 passed · analyze 0. 브리프 D125 · DESIGN-SSOT §5 · 보고서 §1 "집행 완료".
- [x] 메모리 `project-prod-data-access-blocked.md` 신설(분류기 차단 사실). 인계장 09-03 아카이브 삭제(최신 3개 유지).

## 진행중

- 없음 (작업 트리 깨끗, origin 과 일치 826330c). 단, 아래 "대기" 첫 두 항목은 D125 의 마무리다.

## 대기

- [ ] **D125 리뷰 잔손질 3건 (5분)** — 리뷰 에이전트(읽기 전용) 결론 "차단 0". ① `test/golden/stability_result_sheet_test.dart:54,142` ② `test/result_axes_test.dart:279,386` 의 `SingleChildScrollView(child: WodResultSheet(...))` 4곳을 `Scaffold(body: WodResultSheet(...))` 로 (통과는 하지만 실물과 다른 구조를 잼) ③ `wod_result_sheet.dart _MovementRow` 코치 무게 없는 동작의 무게 힌트 `'0'` → `'선택'` 복구. 골든 변화 예상 0(재생성으로 확인).
- [ ] **빌드 3035** — pubspec 은 이미 3035(826330c). `flutter build apk --release --dart-define=API_BASE_URL=https://service-facing-production.up.railway.app` + appbundle · `python tool/store_preflight.py` · `adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk` · 에뮬에서 완료 시트 열어 실측(9/5 수업 줄 → 완료 표시).
- [ ] **점검 보고서 §2 배지 3단** (사용자 옵션 2) — `HkBadge` 한 곳: 행동 배지 글자 micro 13 → body 15 w600, 주 행동('예약'·'완료 표시') 채움 / 보조('메시지'·'자세히'·'취소') 외곽선 / 이유('수업 시작 전'·'예약 필요') 테두리 없는 글자. 골든 약 25장 재생성 예상. `touch_target_test`·밀림 게이트 통과 필수.
- [ ] **점검 보고서 §4·§5 잔손질** — 홈 업적 아래 90dp 공백(도전 섹션 예약 자리) · 쪽지함 빈 공지 카드 170dp · 로그인 약관 링크 굵기(가입 신청보다 무거움) · 내 정보 이름 중복 · 회색 상자(#F5F5F5) 위 12sp muted 라벨 4.43:1.
- [ ] **검증 데이터 삭제 — 분류기 차단, 사용자 직접 실행 필요** — `railway ssh` 와 관리자 API 스크립트 둘 다 auto-mode 분류기가 막음(우회 안 함). 스크립트 = scratchpad `prod_review_data.py`(세션 임시 폴더라 새 세션엔 없음 — 필요하면 다시 만든다: `railway variables --json` 으로 REVIEW_COACH_ID/PASSWORD 읽어 `/api/v1/admin/login` → `inventory` / `delete-posts <id>` / `cancel-classes <id>` / `delete-attendances <aid>`). 데이터는 **gym_id=2(실제 체육관)** 안: 9/5 AWAKE 12:30·SWEAT 14:00·BUILD 14:30 수업(testmember1 예약됨) + 9/5·9/7·9/10 글. 수업은 삭제 API 가 없어 `cancel`(휴강·예약 리셋·통보)만 가능.
- [ ] 폰(갤S22) 미설치 — mdns 광고 없음(무선 디버깅 꺼짐). 켜 주면 `adb -s adb-R5CT503NB5M-r4Y2MU._adb-tls-connect._tcp install -r …`.
- [ ] 구글 플레이 AAB 업로드(사용자 몫) · `migrate_db` 명시 커밋 근본 정리 · PC `dead_utilities` 16 · 타이머 흐름(`wod_session_screen.dart`) 옛 형식 제출 — 직전 인계장 그대로.
- [ ] git worktree 정리 — `.claude/worktrees/agent-a3f7d71f0ae1b48ac`(merge 됨) + 옛 4개. `git worktree prune`·브랜치 삭제는 확인 후.

## 결정사항 / 주의

- **완료 시트 수업 내용 본문은 접지 않는다** — 점검 보고서 §1-3 제안과 달리 D120("B 파트 안 보임")·v3.45("코치 운동이 그대로 불러와지고") 를 지켜 색만 fgSecondary. 재제안 금지.
- **`HkSectionLabel(strong:)` 은 폼 안 묶음 제목용 한 단어 상태** — 화면 섹션 헤더는 기본형(R3 유지). `sectionLabel` 토큰 자체를 키우는 것은 전 화면 골든 60장+ 영향, 별건.
- **`WodResultSheet` 는 높이가 유한한 자리에만** — Flexible 3층 구조. 검사·골든에서 `SingleChildScrollView` 로 감싸면 실물과 다른 구조(죽지는 않음, 리뷰어 재현 확인).
- 숫자 칸 폭 표 = `wod_result_sheet.dart _W` 한 곳. 새 숫자 칸 variant 금지 — `HkNumberField` 폭만 바꿔 쓴다.
- **이 세션의 Bash heredoc 은 `\\` 를 `\` 로 접는다** — 정규식·`\n` 이 든 파이썬을 heredoc 으로 쓰면 깨진다(두 번 당함). 스크립트는 Write 도구로 파일에 쓰고 실행하거나 Edit 도구로.
- 서브에이전트 사용 지시(사용자 "필요시 서브 에이전트 적극활용, 병렬구성") — 이번 세션: fork(worktree) 1 + code-reviewer(sonnet, 읽기 전용) 1. 글로벌 §5 위임 규칙(조회 haiku·검증 sonnet·판단 기본) 적용.
- 검사 수는 러너가 센 값만. 서버 pytest = `python -m pytest tests/ -q`(772). 앱 전체 342.
- 커밋은 `git -C <repo>` 로 폴더 명시(직전 인계장 주의 유지).

## 관련 파일

- 앱: `lib/features/gym/wod_result_sheet.dart`(D125 · `_W`) · `lib/widgets/hkit.dart`(`HkNumberField`·`HkSectionLabel(strong)`) · `lib/models/gym.dart`(`wodTypeLabel`·`scoreHints`) · `test/number_field_test.dart` · `test/result_axes*_test.dart` · `test/golden/stability_result_sheet_test.dart` · `test/ssot_lint_test.dart`(D124 3패턴)
- 문서: `docs/audit-visibility-2026-09-06.html` · `docs/ARCHITECTURE_BRIEF.md` D124·D125 · `docs/DESIGN-SSOT.md §5` · `docs/CONTRACT-result-axes-2.md`(`score_hints`)
- 서버: `services/result_axes.py`(`part_score_hints`·`editor_axes`) · `api/movement_library.py`(program-meta) · `tests/test_ssot_result_axes_lint.py` · `tests/test_result_axes_d122.py` 3·3b·3c · `tests/test_program_d88.py` j
- PC: `static/program_editor.js`(`typeMeta`) · `design/lint.py §7.10` · `design/SSOT.md §21.2·21.4`
- 메모리: `~/.claude/projects/C--dev-apps-facing-app/memory/project-prod-data-access-blocked.md`

## 검증 상태

| 대상 | 결과 |
|---|---|
| 서버 pytest | 772 passed, 1 skipped (D124) |
| 앱 flutter test · analyze | 342 passed · 0 (D125) |
| 앱 골든 | 91장 (D125 5장 재생성) |
| PC design lint --strict | 위반 0 (심기 검사 통과) |
| 배포 | 서버·PC 반영 확인 · 앱 에뮬 3034(3035 미빌드) · 폰 3031 |
| 코드 리뷰(D125) | 차단 0 · 잔손질 3(대기 첫 항목) |

## 다음 세션 권장 첫 프롬프트

`/resume` → "리뷰 잔손질 3건 반영하고 3035 빌드·에뮬 설치까지" 또는 "배지 3단 집행"
