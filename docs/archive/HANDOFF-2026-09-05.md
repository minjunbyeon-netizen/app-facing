# HANDOFF - 2026-09-05 07:54

## 완료

- [x] **D114 알림 설정 보관함 탭 + 노쇼 정책 배열** (PC · 서버)
  - 탭 3개(알림 · 노쇼 정책 · 보관함). '발송 시각'·'최근 발송'을 보관함으로 이동.
  - 발송 기록은 `AuditLog(note.auto)` 라 **영구 보존**인데 화면은 최근 7일 100건만 꺼냈다 →
    기간(7·30·90일·전체)·항목·`before_id` 커서. 응답 모양 변경(배열 → `{items, next_cursor, …}`,
    호출처는 PC 한 곳뿐임을 확인). 선택지 정본 = `api/notifications/note.py` `LOG_RANGES` 계열.
  - 노쇼 정책: 카드 2장 + `.setting-row`(= '이름 왼쪽·조작 오른쪽' 전용 부품) → **규칙 표 한 장**.
    '삭제' 가 카드 밖으로 잘려 있던 것·빨간 버튼 둘이 양 끝으로 찢어져 있던 것 해소.
  - 부품 `.form-actions` 신설 (갤러리 §19·§20, `design/SSOT.md §16`).

- [x] **UI 인덱스 신설** — `docs/UI-INDEX.md` (사용자 "index화 해놓고, 있어? 없으면 만들고")
  - 서버·데이터 인덱스(`services/facing/docs/SSOT/INDEX.md`)는 있었고 **UI 인덱스는 없었다.**
  - 앱 부품 34종(실제 렌더 측정)·게이트·화면 35개 + PC 부품 170·화면 21·갤러리 대조.
  - 읽기 좋은 판 = 아티팩트 **「하이픈 자리 예약 감사」**
    https://claude.ai/code/artifact/bae98b93-89f6-4ee3-99d4-4cfe7d0f3de9 (3탭)

- [x] **D115 자리 예약 + 컨트롤 높이 통일** (앱 · PC)
  - 앱: 로딩 22 / 빈 70·97 / 에러 131 → **`stateSlotH` 132 공통**. `HkLoading()` 기본은 22 유지,
    자리 차지하는 쪽은 **`HkLoading.slot()`**. 게이트 `test/state_slot_test.dart`(실물 `getSize`).
  - PC: 세 상태 `--slot-msg` **76**. 원인은 `fetchTableInto` 만 스켈레톤을 안 깐 것(표 7화면).
    `.page-banner` display:none → `.is-empty`(visibility, 45px 밀림 차단).
    컨트롤 높이 33/35/29/26/34/28 → **`--ctrl-h` 34 하나**. 탭 그릇 → **`.tab-row`**(유령 `.tabs` 소멸).
  - 게이트 §7.5 유령 클래스 · §7.6 로딩 자리 신설 → 첫 실행 22건 **전부 수정**.

- [x] **D116 토스트 한 벌** (PC)
  - 두 벌인 줄 알았는데 **세 벌**이었고 정작 CSS 쪽은 아무도 안 썼다(갤러리가 그 사본을 보여 줌).
  - `.toast` 한 곳 + `--toast-tone` 하나만 바꾸는 상태 클래스. 게이트 **§7.7 `style.cssText` 금지**(0건).
  - 덤: 동기화 토스트 시각이 `slice(0,5)` 라 **"오후 10"** 으로 나오던 것 → 24시각 `hh:mm`.

- [x] **D117 앱 밀림 후보 6건** — **검사부터 쓰고** 고쳤다
  - 실측: 완료 시트 **27px** · 쪽지함 목록 **89px** · 22↔36 스왑 2곳 14px · 코치 주간 **앵커 소실**.
  - 검사 도구 추가 **`expectStableHeight`** — 기존 `expectStableAnchorY` 는 앵커의 시작 y 만 재서
    자리가 목록 맨 아래면 안이 132→43 이 돼도 안 걸린다(쪽지함이 그 상태였다).

- [x] 3면 커밋·푸시 완료. **PC 관리자 웹 Railway 배포 반영**(`--ctrl-h`·`toast-tone` 실물 확인).

## 진행중

- 없음. 작업 트리 깨끗(3면 모두). 앱은 푸시만 됨 — **APK 빌드·배포는 안 했다**.

## 대기

- [ ] **앱 밀림 후보 남은 4건** (`docs/UI-INDEX.md §11` 표)
  - 채팅 전송 아이콘 — **미확인**, 실측이 먼저 (`inbox/inbox_screen.dart:453`, 입력칸 안이라 제약 가능성)
  - 수업 상세 대체요청 시트 에러 — `gym/wod_detail_screen.dart:133`, 시트용 상태 절차를 새로 짜야 함
  - 홈 도전 섹션 — `home/challenge_section.dart:80`, 홈 마지막이라 위는 안 밀림(우선순위 낮음)
  - 계약 목록 2중 로딩 — `contracts/member_contracts_screen.dart:112·233`, 앵커 설계부터
- [ ] **실기 확인** — 폰·PC 로 직접 눌러 로딩 자리·토스트·컨트롤 높이 눈으로. 지금까지 골든·
      좌표 검사·로컬 브라우저 실측뿐.
- [ ] **앱 릴리즈** — D115·D117 이 들어간 빌드는 아직 안 만들었다 (마지막 빌드 3027 = D113).
- [ ] 구글 플레이 AAB 업로드 (인계 전부터 대기, 절차 = `docs/STORE-SUBMIT-SHEET.md`)
- [ ] PC 잔여 — `.stack`(§17 승인받고 도입 0건) 등 죽은 부품 13건 정리 · 페이지 전용 `<style>` 6개

## 결정사항 / 주의

- **용어 정본은 앱 문서 하나** — `docs/DESIGN-SSOT.md §레이아웃 안정성`. PC(`design/SSOT.md §17`)는
  링크만 하고 옮겨 적지 않는다. 두 벌이 되면 한쪽만 고쳐진다.
- **문서만 만들고 게이트를 미루지 않는다** (대전제 6-b). D114~D117 모두 같은 커밋에 게이트를 넣었다.
- **골든 재생성으로 "고쳤다" 고 하지 않는다.** 골든은 한 상태의 그림만 잡는다. 밀림은 상태 사이의
  차이라 좌표·높이 검사만이 증명한다.
- **검사 도구 둘의 쓰임이 다르다** — `expectStableAnchorY`(위아래에 요소가 있을 때) /
  `expectStableHeight`(로딩·빈·에러가 갈아 끼워지는 자리, 특히 목록 맨 아래).
- `HkLoading()` 기본 생성자를 132 로 만들면 **버튼 안 스피너까지 부푼다** — `.slot()` 과 구분 유지.
- PC 게이트가 잡은 것은 **면제로 넘기지 말 것**. D115 에서 22건을 전부 고쳤고, 면제는 한 줄
  라벨 3종(`page-sub`·`page-title`·`modal-title`·`form-static`)뿐이다.
- 서버 테스트는 `python -m pytest tests/ -q` (인자 없이 돌리면 수집 오류).
- `services/facing` 에 untracked `_d111_pytest.txt` 가 남아 있다 (이전 세션 산출물, 내 것 아님).

## 관련 파일

- **인덱스·감사**: `docs/UI-INDEX.md` (§9 D115 · §10 D116 · §11 D117) ·
  아티팩트 「하이픈 자리 예약 감사」
- **계약 정본**: `docs/ARCHITECTURE_BRIEF.md` D114 · D115 · D116 · D117
- **앱 규격**: `docs/DESIGN-SSOT.md §레이아웃 안정성` · `lib/core/theme.dart`(`stateSlotH`) ·
  `lib/widgets/hkit.dart`(`HkLoading.slot`·`HkEmptyState`·`HkErrorState`·`HkReservedSlot`)
- **앱 검사**: `test/golden/layout_stability.dart`(헬퍼 둘) · `test/state_slot_test.dart` ·
  `test/golden/stability_*.dart`(25 검사)
- **앱 이번 수정**: `features/gym/wod_result_sheet.dart` · `features/boss/coach_week_classes.dart` ·
  `features/inbox/inbox_screen.dart` · `features/gym/membership_status_view.dart` · `features/gym/wod_row.dart`
- **PC**(`C:/dev/web/facing-admin`): `design/tokens.css`(`--ctrl-h`·`--slot-msg`) · `static/style.css`
  (`.tab-row`·`.table-skel-cell`·`.toast`·`.sse-banner`·`.head-stat`) · `static/app.js`(로더 둘) ·
  `templates/_layout.html`(토스트 두 함수) · `design/lint.py`(§7.5·§7.6·§7.7) ·
  `design/SSOT.md §16~§19` · `design/gallery.html §19~§22` · `CLAUDE.md`
- **서버**(`C:/dev/services/facing`): `api/notifications/note.py`(`LOG_RANGES`) · `api/admin.py`
  (`admin_notification_logs`) · `tests/test_notification_note_gates.py`

## 검증 상태

| 대상 | 결과 |
|---|---|
| 서버 pytest | 708 passed, 1 skipped |
| 앱 flutter test | **256 passed** · analyze 0 |
| 앱 골든 | 89장 (D115 1장 재생성 · D117 재생성 0) |
| 앱 안정성 검사 | **25** (전 20) |
| PC design lint | 위반 0 · baseline 유지 · 게이트 **6종**(전 3) |
| PC 토큰 드리프트 | 없음 |
| 배포 | PC 관리자 웹 Railway 반영 확인. **앱 APK 미빌드** |

## 다음 세션 권장 첫 프롬프트

`/resume`
