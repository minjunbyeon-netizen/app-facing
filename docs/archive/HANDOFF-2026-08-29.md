# HANDOFF - 2026-08-29 04:40

> 이 세션 주제: **테스터 답 9건 반영 → 이음매 왕복 점검 8갈래 → 이원화 금지 게이트.**
> 3 repo(app-hyphen · service-hyphen · web-hyphen-admin) 전부 커밋·푸시 완료, 워킹트리 깨끗.
> ⚠ app 저장소는 **공개(public)** — 자격증명·비밀번호 금지 (§2-A-1).

## 이 세션에서 확정된 판단 기준

**"각자 다른 걸 말하는 이원화 현상이 주된 이유다. 명백히 법적으로 막아라."** (사용자, 2026-08-29)

결함 24건의 뿌리가 전부 이것이었다. 브리프 **§2-0 대전제 6** 으로 박았고
자동 게이트 둘로 강제한다. 앞선 D47·D48 에서 같은 병을 UI 에 대해 두 번 고쳤는데
서버 쪽에서 또 났다 — **문서 문구만으로는 뚫린다**는 것이 이 세션의 교훈.

---

## 완료

### 1. 테스터 답 9건 반영 (전부 배포됨)
- **1번 취소 시한** — 막지 않는다. 시한 후 취소는 코치에게만 기록(`deadline_cancel`).
  60~20분은 차감 없음, 20분 이후는 D57 그대로. 브리프 D69
- **2번 1시간 전 알림** — 원래 되어 있었음 (`reminderLeadMinutes = 60`)
- **3번 알림** — 종류별 폐기, **스위치 하나**(내 정보). 끄면 쪽지·수업 알림 함께 멈추고
  예약분까지 `cancelAll`. 관문은 `NotificationService` 한 곳
- **6번 수업 줄** — 룸 이름만 제거. 정원·대기는 남김(예약 판단 근거)
- **7번 회원권 해지** — 즉시 해지분은 목록에서 빠짐(서버 응답이 정본,
  `include_cancelled=1` 로만 조회). 해지 예정은 남김
- **8번 수업·프로그램 분리** — B안. 수업 탭에 `수업 시간`/`프로그램` 두 칸(HkSegment)
- **9번 전화** — 번호 탭 → 전화. 실패 시 번호 복사. 터치 48 확보
- **4·5번은 사용자 지시로 추후** (FCM · 동작 영상 라이브러리)

### 2. 잔손질
관리자 웹 주색 `#EE2B2B` → `#CC1F1F`(앱·홈페이지와 통일) · 도달 불가 화면 2개 삭제
(BoxProfileScreen·CoachDetailScreen, README 대장 36) · 회원 목록 이름 칸에
'이번 주 늦은 취소'(기준선 초과만) · 회원권 발급 창 **[이어서 시작]** 버튼

### 3. 이음매 왕복 점검 8갈래 → **결함 24건**
검사 146건 신설(`tests/test_roundtrip_*.py` 8벌). **제품 코드는 한 줄도 안 고쳤고**
결함은 전부 `xfail(strict=True)` 로 코드에 박았다 — 고치는 순간 XPASS 로 뒤집혀 알려 준다.

정리 문서: https://claude.ai/code/artifact/3e6659d1-166b-41e6-8b7f-e9402e9c068e

### 4. 이원화 금지 게이트 3종
- `api/_metrics.py` — 세는 함수 정본. 각 함수에 **정의 한 문장** 필수.
  예약 인원·대기 인원을 본보기로 이관(동작 무변경)
- `tests/test_ssot_metrics_lint.py` — 정의를 정본 밖에서 다시 적으면 실패.
  baseline(예약 5·대기 1·매출 5·만료 3), **늘면 실패·줄면 낮추라고 알림**
- `tests/test_ssot_agreement.py` — 창구 **등록제**. AST 로 라우트를 훑어 미등재 차단
- 셋 다 **실제로 뚫어 보고** 잡히는 것을 확인

### 5. 검증·배포
- 서버 `pytest tests/` **477 passed · 1 skipped · 24 xfailed** (세션 시작 343 → +146)
- 앱 `flutter test` **250** · `analyze` 0 · 골든 **71장**
- 관리자 웹 `design/lint.py` baseline 유지
- 배포: 백엔드·관리자 웹 `railway up` SUCCESS, 프로드 실화면 확인. 앱 **APK 3013**
- **에뮬레이터 실기 검증** — `Medium_Phone_API_36.1` 에 설치, 첫 실행 알림 권한 팝업 ·
  로그인 · 수업 탭 2칸 · 예약 오픈 전 게이트 동작 확인

## 진행중
- [ ] 없음. 3 repo 워킹트리 깨끗.

## 대기 (사용자 결정 / 다음 세션)

- [ ] **결함 24건 수정 — 어느 것부터 할지 미결정.** 사용자에게 3안 제시한 상태
      (돈 5건 먼저 / 새는 것 먼저 / 전부 순서대로). **돈 5건을 권했다.**
      - **재예약이 늦은 취소 무료 1회를 재충전** → 횟수권이 영원히 안 깎임 (가장 급함)
      - 미수금을 정가 전액 환불로 굳힘 · 가격 수정이 결제이력 미반영 ·
        주3회권이 무제한권에 묻혀 무력화(주 4회 예약 성공) · 선결제 매출 이중 기준
- [ ] **매출·만료 임박 정본 이관 — 어느 기준이 맞는지 사용자 결정 필요.**
      매출은 기준 3가지(회원권 정가×시작일 / 결제액×그 달 / 결제액×하한만),
      만료 임박은 모집단 3가지(대표 회원권 / 회원권 행 수 / 프로필 inner join).
      정하기 전에 옮기면 그게 곧 결함 수정이라 `_metrics.py` 머리말에 사유만 적어 뒀다
- [ ] **프로드 데이터 2건** — 이민지(회원 7) 회원권 4장 합계 ₩1,512,000 에 결제 기록 0건
      (직접 [기록] 으로 입력 or 소급 여부 지시) · 겹친 회원권 정리(시험 데이터라 하셨음)
- [ ] 스토어: 개발자 인증 메일 대기 · 클로즈드 테스터 12명 · 갤S22 실기 검증
- [ ] 공수체크(별건): PC 화면 디자인 방향 — `C:\dev\services\workcheck\docs\TODO-PC-DESIGN.md`

## 결정사항 / 주의

- **한 사실은 한 곳에서만 센다** (브리프 §2-0 대전제 6). 새로 세는 코드를 쓰면
  `test_ssot_metrics_lint.py` 가 파일·줄을 지목하며 막는다. 새 창구를 만들면
  `test_ssot_agreement.py` 의 `WINDOWS` 에 등재해야 통과한다.
- **결함은 xfail 로 박혀 있다.** 고치면 XPASS(strict)=실패로 뒤집히므로,
  고칠 때 그 xfail 마커를 함께 걷어야 한다.
- **게이트가 못 막는 것** — 같은 뜻을 다른 식으로 새로 쓰는 것 · 정본 호출 후 가공 ·
  헬퍼 위임 · **화면 쪽(PC JS·폰 Dart)** · 기준선을 사람이 올려 버리는 것.
- **예약 줄은 한 회원·한 수업당 하나뿐**이라 취소가 별도 이력으로 안 남는다.
  재예약 관련 결함 2건의 뿌리이고, 근본 해법은 취소를 append 로 남기는 구조 변경.
- APK 는 **프로드 주소로 다시 구워 뒀다**. 로컬 검증용으로 `10.0.2.2:5060` 을 주입해
  구운 적이 있으니, 배포 전 `--dart-define=API_BASE_URL` 을 항상 확인할 것.
- 서버 pytest 는 반드시 `pytest tests/` 로 경로 명시.
- 프로드 검증 원칙 — 파괴적 조작은 로컬, 프로드는 읽기 전용.
- DB 컬럼은 추가만 · 사용자 데이터는 지우지 않는다.

## 관련 파일

| 영역 | 경로 |
|---|---|
| 세는 함수 정본 | `services/hyphen/api/_metrics.py` |
| 이원화 게이트 | `services/hyphen/tests/test_ssot_metrics_lint.py` · `test_ssot_agreement.py` |
| 왕복 검사 8벌 | `services/hyphen/tests/test_roundtrip_*.py` |
| 회원권 선택·취소 판정 | `services/hyphen/api/_membership.py` |
| 예약·취소·대기 | `services/hyphen/api/classes.py` |
| 알림 쪽지 정본 | `services/hyphen/api/notifications/note.py` |
| 코치 PC 회원 상세 | `web/facing-admin/templates/member_detail.html` |
| 앱 알림 관문 | `apps/facing-app/lib/core/notification_service.dart` |
| 앱 수업 탭 2칸 | `apps/facing-app/lib/features/gym/week_board.dart` |
| 대전제 | `apps/facing-app/docs/ARCHITECTURE_BRIEF.md §2-0` |

## 다음 세션 권장 첫 프롬프트

`/resume` → **결함 24건 중 돈 5건부터 수정**. 재예약 구멍(`api/classes.py:768~776`
행 재사용 시 `late_cancel`·`deadline_cancel` 리셋)이 첫 대상이고,
고칠 때 `test_roundtrip_booking.py` 의 xfail 마커를 함께 걷을 것.
