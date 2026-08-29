# HANDOFF - 2026-08-29 15:00

> 이 세션 주제: **왕복 점검 결함 24건 전부 수정 → 회원 쪽지함 '코치/활동' 분리 → 배포·실기 회귀.**
> 3 repo(app-hyphen · service-hyphen · web-hyphen-admin) 전부 커밋·푸시·배포 완료, 워킹트리 깨끗.
> ⚠ app 저장소는 **공개(public)** — 자격증명·비밀번호 금지 (§2-A-1).

## 한 줄 요약

`pytest tests/` 의 **xfail 이 0** 이 됐다 (501 passed · 1 skipped · 0 xfailed).
어제 세션이 `xfail(strict=True)` 로 박아 둔 결함 24건을 **전부 고치고 마커를 걷었다.**

---

## 완료

### 1. 결함 24건 — 브리프 D70·D71·D73

**D70 돈 6건** — 취소 원장(`class_reservation_cancels`) 신설이 뿌리 수정.
예약 줄은 (수업, 회원) UNIQUE 라 재예약하면 되살아나며 취소 기록을 지웠다 →
코치가 보는 '시한 후 취소' 누적이 사라지고 **늦은 취소 무료 1회가 되채워져
횟수권이 영영 안 깎였다.** 취소는 사건이므로 append-only 표로 분리.
세는 자리 3곳(`recompute_session_charges`·`session_summary`·`deadline_cancel_counts_bulk`)
을 원장 기준으로 이관, 쓰는 자리는 `record_cancel` 한 곳.
나머지 — 미수금 환불 차단(상한 = 받은 돈) · 가격 수정 시 결제이력 동기화 ·
겹친 회원권은 가장 엄한 한도가 이김(`plan_limits_on`) · 선결제 매출 이중 기준 해소.

**D71 숫자 4건** — 만료 임박(프로필 inner join 으로 이름 없는 회원이 빠짐) ·
대기 인원(제품 경로로 안 생기는 상태값을 세어 **언제나 0**) · 오늘 예약(건수가
아니라 사람 수) · 수강 이력 총계(top 5 만 합산). 전부 `_metrics.py` 정본으로 이관.
**이원화 기준선 3종이 0** 이 됐다 (예약 인원 5→0 · 대기 인원 1→0 · 만료 임박 3→0).

**D73 나머지 10건** — 공지 원문 보존(저장 escape 제거, 막는 자리는 PC `esc()`) ·
페어링 코치도 공지 게시(대전제 1) · 회원↔회원 쪽지 차단(대전제 5) ·
쪽지 상태 역행 금지 + `asked` 도 읽음 · 회원권 없으면 수업 내용도 잠금 ·
회원 출석은 `source='self'` 로 분리 · 리워드 스윕이 Profile 없이도 돎 · 탈퇴자 재신청.

### 2. 회원 쪽지함 '코치 / 활동' 분리 — D72 (사용자 지시)

> "쪽지는 쪽지고(코치와 대화), 업적알림 가입 예약완료 등등 이런건 활동로그
>  이런걸 만들어서 거기에 그냥 쌓이게"

- 가르는 판정은 **서버 한 곳** `coach_note._is_conversation()` (auto_kind 유무).
  '활동' 은 그 여집합 — 한 쪽지가 두 칸에 겹치거나 새지 않는다.
- `build_threads`/`build_messages` 에 `include_auto` — **회원 창구만** False.
  PC 코치 화면은 종전과 같다 (**코치 PC 분리는 사용자가 "할 필요없음" 확정**).
- 새 창구 `GET /api/v1/gym/<id>/activity`.
- **자동 통보 4종 신설** (NOTE_TEMPLATES 4 → 8): `booking`·`promotion`·`signup`·`achievement`.
  `signup` 은 승인만 (반려자는 쪽지함 403 — 못 읽는 쪽지를 안 쌓는다).
  `achievement` 는 `after_commit(once)` — `_grant` 가 호출부 트랜잭션 안이라 SQLite 잠김 회피.
- 공지 알림 토글 소비처 복구 (저장만 되고 읽는 코드가 0건이었다).
- 앱: `MessagingFeed` StatefulWidget + `HkSegment('코치','활동')`, 활동 칸은 `retainError`.

### 3. 검증·배포

- 서버 `pytest tests/` **501 passed · 1 skipped · 0 xfailed** (세션 시작 477·24)
- 앱 `flutter test` **251** · `analyze` 0 · 골든 **72장**
- 관리자 웹 `design/lint.py` baseline 유지
- 배포: 백엔드·관리자 웹 `railway up` 전부 SUCCESS
- **에뮬레이터 실기 회귀** (`Medium_Phone_API_36.1`) — 프로드 읽기 전용 원칙에 따라
  **로컬 서버 + 로컬 APK** 로 파괴적 조작까지 돌렸다. 화면으로 확인: 로그인 · 가입 승인 ·
  예약(정원 1/8) · **쪽지함 두 칸** · 활동 칸에 예약 완료·가입 승인 2건 ·
  코치 칸엔 대화만 · 공지 `1+1 & 경품` 원문 · 회원권 9회 남음 · 알림 받기 토글.
  API 왕복 **15항목 전부 통과** (`scratchpad/verify.py`).
- **프로드 직접 확인** — 코치 전용 공지로 원문 보존·멱등 실증 후 삭제.
  `/activity`·`/threads`·`/messages` 403(404 아님) = 라우트 살아 있음.
  공지 이관은 돌았고 **바꿀 행이 0** 이었다(기존 공지 2건에 특수문자 없음).
- 검증 후 APK 는 **프로드 주소로 다시 구워** 에뮬레이터에 재설치, 로컬 서버·검증 DB 정리.
- **갤S22 실기 검증 (15:55 · 프로드 읽기 전용)** — 폰 IP 가 바뀌어 있었다
  (구 `192.168.1.103` → **`172.30.1.41:5555`**, `tools/phone/last-addr.txt` 갱신).
  회원 계정 '김존이'(회원권 없음)로 확인: 수업 탭 2칸 · **쪽지함 '코치/활동' 두 칸** ·
  빈 문구가 칸 이름을 따름(코치 '코치 쪽지 도착 시 표시.' / 활동 '아직 활동 없음.') ·
  재시작 시 기본 진입 = 코치 · **회원권 없으면 프로그램이 '회원권 만료' 로 잠김**
  (D73 실증 — '프로그램 없음'·'게시 전' 과 구분돼 표시) · 알림 받기 토글.
  프로드 쓰기는 하지 않았다 (예약 오픈 규칙 D58 상 예약 가능한 수업도 없었다).
  그래서 **활동 칸이 실제로 채워지는 것은 에뮬레이터에서만** 봤다.

## 진행중

- [ ] 없음. 3 repo 워킹트리 깨끗.

## 대기 (사용자 결정 / 다음 세션)

- [ ] **'칭호' 화면(Panel B)이 채울 수 없는 값을 읽는다 — 2026-08-29 16:40 발견.**
      업적 화면 우상단 '칭호' 버튼(`achievements_screen.dart:78 openPanelB`)으로 **도달 가능**한데,
      해금 판정이 `profile.benchmarks[...]`(back_squat_1rm_lb·snatch·run_5km_sec·fran_sec …)를 읽는다.
      그 값은 **폰 로컬 저장(SharedPreferences)에만 있고 서버엔 없으며**,
      `setBenchmark` 를 부르는 화면이 **0곳**이다 (Benchmarks 온보딩이 v2.6/v3.2 에서 삭제됨).
      → 신규 설치 회원은 그 조건의 칭호가 **영원히 안 풀린다**. 살아 있는 신호는
      `hasGym`·`coachNotesSent/Received` 정도. 제1원칙(화면이 거짓말하지 않을 것) 저촉.
      **제거 제안 아님** — 대전제 5 존치 확정 목록(목표·최고기록·히스토리)에 걸린다. 사용자 판단 필요.
- [ ] **매출 축 — 결제 축을 코치 화면에 노출할지** (2026-08-29 "일단 추후").
      코치가 보는 '이번 달 매출'은 **정가 축 하나뿐**이고, D70 에서 합친 결제 축 두 API
      (`this_month_revenue`·`net_revenue`)는 **어느 화면도 안 쓴다**(전수 grep 0건).
      합치는 것은 답이 아니다 — 서로 다른 사실이라 하나로 만들면 둘 다 틀려진다.

- [ ] **미수금 환불 차단만 프로드 미검증** — 결제 행을 만들어야 해서 안 했다
      (로컬 실서버 왕복·pytest 로는 통과).
- [ ] **프로드 데이터 2건** — 이민지(회원 7) 회원권 4장에 결제 기록 부족 ·
      겹친 회원권 정리(시험 데이터라 하셨음).
- [ ] 스토어: 개발자 인증 메일 대기 · 클로즈드 테스터 12명.
- [ ] 공수체크(별건): PC 화면 디자인 방향 — `C:\dev\services\workcheck\docs\TODO-PC-DESIGN.md`

## 결정사항 / 주의

- **구 D60 개정** — "알림 = 앱 쪽지 하나" 의 **채널은 그대로 하나**(카카오·FCM 없음).
  달라진 것은 한 화면 안에서 갈래를 나눈 것뿐이다.
- **코치 PC 쪽지함은 안 나눈다** (2026-08-29 사용자 "코치pc함은 할 필요없음").
- **회원 '알림 받기' 토글은 이미 하나** — 쪽지·업적·수업 리마인더가 전부
  `NotificationService` 관문을 지난다. 꺼도 쪽지·활동은 **조용히 쌓인다**.
- **게이트 사각 1종 추가 관측** — 검사가 화면과 **똑같이 틀린 정의**를 쓰면 초록으로
  보인다. 실제로 `test_dashboard_roster` 헬퍼가 제품 경로로 안 생기는 가짜 상태를
  직접 넣고 있었다. 테스트 디렉터리는 린트 스캔 밖이라 사람이 봐야 하고,
  실질적 방어는 **제품 창구끼리 값을 맞대는 왕복 검사**다 (린트 머리말에 기록).
- **공지 이관은 한 번만 돈다** — 완료 표시 = `audit_logs.action='announcement.unescape_once'`.
  두 번 돌면 코치가 진짜로 '&amp;' 라 적은 글이 깨진다.
- APK 는 **프로드 주소로 다시 구워 뒀다**. 로컬 검증용으로 `10.0.2.2:5060` 을 주입해
  구운 적이 있으니, 배포 전 `--dart-define=API_BASE_URL` 을 항상 확인할 것.
- 서버 pytest 는 반드시 `pytest tests/` 로 경로 명시.
- 프로드 검증 원칙 — 파괴적 조작은 로컬, 프로드는 읽기 전용(불가피하면 코치 전용 + 즉시 삭제).
- DB 컬럼·표는 추가만 · 사용자 데이터는 지우지 않는다.
- 앱 repo 커밋 하나가 훅 자동저장이라 메시지가 `chore: auto-save` 다 (df46919).
  내용은 정확하나 main 강제 푸시 없이는 못 고쳐 그대로 뒀다.

## 관련 파일

| 영역 | 경로 |
|---|---|
| 취소 원장 | `services/hyphen/models/class_reservation_cancel.py` · `api/_membership.py record_cancel` |
| 세는 함수 정본 | `services/hyphen/api/_metrics.py` |
| 이원화 게이트 | `services/hyphen/tests/test_ssot_metrics_lint.py` · `test_ssot_agreement.py` |
| 왕복 검사 8벌 | `services/hyphen/tests/test_roundtrip_*.py` (xfail 0) |
| 자동 통보 정본 | `services/hyphen/api/notifications/note.py` (NOTE_TEMPLATES 8종) |
| 활동/코치 판정 | `services/hyphen/api/coach_note.py _is_conversation · build_activity` |
| 앱 쪽지함 2칸 | `apps/facing-app/lib/features/inbox/inbox_screen.dart MessagingFeed` |
| 마이그레이션 | `services/hyphen/models/base.py _migrate_cancel_ledger · _migrate_unescape_announcements` |
| 대전제·결정 이력 | `apps/facing-app/docs/ARCHITECTURE_BRIEF.md` (D70~D73) |

## 다음 세션 권장 첫 프롬프트

`/resume` → '칭호' 화면 처리 방향 결정 (채울 경로를 만들지 / 그 조건만 감출지 / 그대로 둘지).
결함 대장은 비었으니, 새 결함을 찾으려면 왕복 점검을 다른 갈래로 한 벌 더 뜨는 것이 다음 수다.
