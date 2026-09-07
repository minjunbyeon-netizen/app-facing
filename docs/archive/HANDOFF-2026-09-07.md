# HANDOFF - 2026-09-07 06:54

## 완료

- [x] **D125 리뷰 잔손질 3건** (ff1cea8) — 직전 세션 리뷰(읽기 전용, 차단 0)의 잔여 3건.
  1. `test/golden/stability_result_sheet_test.dart:54,142` · `test/result_axes_test.dart:278,385` 의
     `SingleChildScrollView(child: WodResultSheet(...))` 4곳 → `Scaffold(body: WodResultSheet(...))`
     직접 마운트. 고정 저장 바는 높이가 유한한 자리에서만 성립하므로 실물(HkSheet)과 같은 구조를 잰다.
  2. `wod_result_sheet.dart _MovementRow` 코치 무게 없는 동작의 무게 힌트 `'0'` → **`'선택'`** 복구(D125 전 값).
  3. 브리프 D125 항목에 잔손질 3줄 추가.
- [x] **골든 1장 재생성** — 인계장은 "골든 변화 예상 0" 이었으나 **틀렸다**. 무게 힌트가 보이는 픽셀이라
  `member_06b_result_sheet_strength.png` 가 바뀌었다(4·5세트 무게 칸 '0' → '선택'). 재생성 후 **91장 불변**.
- [x] **검증** — `flutter test` **342 passed** · `flutter analyze` **0 issues**.
- [x] **빌드 3035** — APK 62.7MB · AAB 50.8MB, 둘 다 `--dart-define=API_BASE_URL=https://service-facing-production.up.railway.app`.
- [x] **store preflight 24 PASS · 0 FAIL** — 첫 실행은 19 PASS·**5 FAIL**(스토어 에셋 16장이 "골든보다 오래됨").
  원인은 결함이 아니라 **골든 재생성으로 mtime 역전**. `tool/gen_store_shots.py` · `gen_store_shots_ios.py` ·
  `gen_store_assets.py` 3개를 다시 돌려 해소(에셋은 골든이 정본이므로 재생성이 정답).
- [x] **에뮬 3035 설치·실측** — `adb -s emulator-5554 install -r`(3034 → 3035 확인). 수업 탭 → 전 주 → 토 9/5 →
  14:30 BUILD 줄 펼침 → '기록 8R+12' 배지 → 완료 시트. 머리·저장 바 고정 · 본문만 스크롤 · 숫자 칸 오른쪽 정렬 ·
  단위 칸 밖 · 서버 힌트('캡 종료일 때만' · '10분 중') 정상 표시 확인.
- [x] 인계장 아카이브(1e26ed1) — `HANDOFF-2026-09-06-2.md` 로 이동, 09-04 제거(최신 3개 유지).

## 진행중

- 없음. 작업 트리 깨끗, origin/master 와 일치(ff1cea8).

## 대기

- [ ] **점검 보고서 §2 배지 3단** (가시성 점검 §2 · 사용자 옵션 2 — **다음 순위 1**) — `HkBadge` 한 곳에서:
  행동 배지 글자 `micro` 13 → `body` 15 w600 · 주 행동('예약' · '완료 표시') **채움** / 보조('메시지' · '자세히' ·
  '취소') **외곽선** / 이유('수업 시작 전' · '예약 필요') **테두리 없는 글자**. 골든 약 25장 재생성 예상.
  `test/touch_target_test.dart`(누르는 상자 48) · 밀림 게이트 통과 필수. 에뮬 실측 화면에서 '예약'·'예약됨'·
  '기록 8R+12'·'메시지'·'자세히' 가 한 줄에 모여 있어 3단 구분 효과가 바로 보인다.
- [ ] **점검 보고서 §4·§5 잔손질** — 홈 업적 아래 90dp 공백(도전 섹션 예약 자리) · 쪽지함 빈 공지 카드 170dp ·
  로그인 약관 링크 굵기(가입 신청보다 무거움) · 내 정보 이름 중복 · 회색 상자(#F5F5F5) 위 12sp muted 라벨 4.43:1.
- [ ] **검증 데이터 삭제 — 분류기 차단, 사용자 직접 실행 필요** — `railway ssh` 와 관리자 API 스크립트 둘 다
  auto-mode 분류기가 막는다(우회 안 함). 데이터는 **gym_id=2(실제 체육관)** 안: 9/5 AWAKE 12:30 · SWEAT 14:00 ·
  BUILD 14:30 수업(testmember1 예약·기록 있음) + 9/5·9/7·9/10 글. 이번 세션 에뮬 실측에서 **그대로 살아 있음을
  재확인**(9/5 세 줄 '예약됨', BUILD 에 기록 8R+12). 수업은 삭제 API 가 없어 `cancel`(휴강·예약 리셋·통보)만 가능.
  스크립트 재작성 = `railway variables --json` 으로 REVIEW_COACH_ID/PASSWORD 읽어 `/api/v1/admin/login` →
  `inventory` / `delete-posts <id>` / `cancel-classes <id>` / `delete-attendances <aid>`.
- [ ] **폰(갤S22) 미설치** — 여전히 3031. mdns 광고 없음(무선 디버깅 꺼짐). 켜 주면
  `adb -s adb-R5CT503NB5M-r4Y2MU._adb-tls-connect._tcp install -r build/app/outputs/flutter-apk/app-release.apk`.
- [ ] **구글 플레이 AAB 업로드**(사용자 몫) — `build/app/outputs/bundle/release/app-release.aab` 3035 준비됨,
  스토어 에셋도 갱신 완료(`build/store/` 16장 + 아이콘·피처).
- [ ] **git worktree 정리** — 5개(`agent-a3eea278` · `a3f7d71f`(D125 merge 됨) · `a4616ccf` · `a8482b70` ·
  `ae94a173`). `git worktree prune` + 브랜치 삭제는 되돌리기 어려워 확인 후.
- [ ] `migrate_db` 명시 커밋 근본 정리 · PC `dead_utilities` 16 · 타이머 흐름(`wod_session_screen.dart`)
  옛 형식 제출 — 직전 인계장 그대로.

## 결정사항 / 주의

- **스토어 에셋은 골든이 정본** — 골든을 1장이라도 재생성하면 `store_preflight.py` 가 에셋 16장을
  "골든보다 오래됨" 으로 FAIL 시킨다(`store_preflight.py:161,169` mtime 비교). **정답은 에셋 재생성**
  (`gen_store_shots` → `gen_store_shots_ios` → `gen_store_assets` 순, 각 수 초). preflight FAIL 을
  보고 코드를 의심하지 말 것 — 이번 세션에서 5 FAIL 이 전부 이 사유였다.
- **"골든 변화 없음" 예측은 믿지 말고 돌려서 확인** — 힌트·플레이스홀더 글자도 픽셀이다.
- **완료 시트 수업 내용 본문은 접지 않는다** — D120·v3.45 유지. 재제안 금지(직전 인계장에서 이어짐).
- **`WodResultSheet` 는 높이가 유한한 자리에만** — Flexible 3층. 검사·골든은 `Scaffold(body:)` 직접
  (이번 세션에서 잔여 4곳까지 통일 완료 — 이제 `SingleChildScrollView` 로 감싼 곳 0건).
- 숫자 칸 폭 표 = `wod_result_sheet.dart _W` 한 곳. 새 숫자 칸 variant 금지 — `HkNumberField` 폭만 바꿔 쓴다.
- **Bash heredoc 이 `\\` 를 접는다** — 정규식·`\n` 이 든 파이썬은 heredoc 금지. 이번 세션은 **Write 도구로
  스크래치패드에 .py 를 쓰고 실행**하는 방식으로 우회했고 잘 동작했다(치환 건수 단언 포함 — 권장 패턴).
- 검사 수는 러너가 센 값만. 앱 전체 **342** · 골든 **91**. 서버 pytest = `python -m pytest tests/ -q`(772).
- 커밋은 `git -C <repo>` 로 폴더 명시.

## 관련 파일

- 앱: `lib/features/gym/wod_result_sheet.dart`(무게 힌트 '선택' · `_W`) · `lib/widgets/hkit.dart`
  (`HkBadge` — 다음 작업 대상 · `HkNumberField` · `HkSectionLabel(strong)`) ·
  `test/golden/stability_result_sheet_test.dart` · `test/result_axes_test.dart` ·
  `test/golden/goldens/member_06b_result_sheet_strength.png` · `test/touch_target_test.dart`
- 문서: `docs/audit-visibility-2026-09-06.html`(§2 배지 3단 · §4 · §5 가 다음 작업) ·
  `docs/ARCHITECTURE_BRIEF.md` D125(잔손질 3줄 추가) · `docs/DESIGN-SSOT.md §5`
- 도구: `tool/store_preflight.py` · `tool/gen_store_shots.py` · `gen_store_shots_ios.py` · `gen_store_assets.py`
- 메모리: `~/.claude/projects/C--dev-apps-facing-app/memory/project-prod-data-access-blocked.md`

## 검증 상태

| 대상 | 결과 |
|---|---|
| 앱 flutter test · analyze | 342 passed · 0 issues |
| 앱 골든 | 91장 (member_06b 1장 재생성) |
| store preflight | 24 PASS · 0 FAIL (에셋 재생성 후) |
| 빌드 | APK 62.7MB · AAB 50.8MB · 3035 |
| 에뮬 | 3035 설치·실행·완료 시트 실측 OK |
| 폰(갤S22) | 3031 (무선 디버깅 꺼짐) |
| git | ff1cea8, origin/master 와 일치, 트리 깨끗 |

## 다음 세션 권장 첫 프롬프트

`/resume` → "배지 3단 집행" (점검 보고서 §2 — HkBadge 15sp · 채움/외곽선/글자 3단, 골든 약 25장 재생성)
