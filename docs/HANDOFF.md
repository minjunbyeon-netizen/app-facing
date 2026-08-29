# HANDOFF - 2026-08-29 23:29

> 이 세션 주제: **저녁 지시 6건 집행 (D82~D87) + 운동 데이터 연동 6단계 합의(D88, 미착수).**
> 21:14 ~ 23:29. 3 repo 전부 커밋·푸시 완료, 워킹트리 깨끗. 앱 빌드 **3020 → 3025** (최신 3025, 폰·에뮬 설치·릴리즈).
> 관리자 웹 Railway 배포 SUCCESS (23:20). 서버 코드 변경 없음(문서만). ⚠ app 저장소는 public — 자격증명 금지.

## 한 줄 요약

앱 `flutter test` **253** · `analyze` 0 · 골든 **75장**. 다음 일 = **D88 운동 데이터 연동 1단계(동작 사전 + 코치 드롭다운)** 착수.
결정 대기 0건 (D88 기본값 4개는 사용자 미답 — 반대 없으면 그대로 적용).

---

## 완료 (D 번호 순 — 상세는 `docs/ARCHITECTURE_BRIEF.md`)

| D | 내용 | 면 | 빌드 |
|---|---|---|---|
| D82 | 예약 오픈 전: '예약' 버튼 그대로, 누르면 담담한 캐릭터 스낵바 "예약 가능한 시간이 아니에요 / M/D HH:MM 부터" (서버 안 두드림, 409 도 같은 문구). 1단 플레이스홀더(3020)는 폐기·HkSlotNote 삭제 | 앱 | 3021 |
| D83 | 내 정보 메뉴 항상 펼침 · '알림 받기' 메뉴 안 한 줄 · **'체육관 정보' 화면 신설**(`gym_info_screen.dart`, 수업 종류 노출 복구 — 어제 결정 대기 해소) · 겹친 구분선 정리 | 앱 | 3022 |
| D84 | **히스토리 검색·연관도순** — 정본 `lib/features/history/history_search.dart rankHistory` (낱말 AND · 칸 가중치 · 동점 최근순), 단위 검사 7건, 저장소 100건씩 전부 로드(서버 무변경). 줄 제목 = 수업 내용 첫 줄 | 앱 | 3023 |
| D85 | 회원 셸 **4탭 = 홈 · 수업 · 히스토리 · 내 정보** (`HistoryScreen(embedded)`). 에뮬레이터+로컬 서버 실검증(목록·'squat'·'8/23' 검색) | 앱 | 3024 |
| D86 | 예약 확정 시 **세 줄 토스트**(`HkSnack.info(detail:)`) + **화면 중앙 폭죽**(`HkConfetti.burst`, 외부 패키지 없음, 고정 시드, 애니메이션 줄이기 존중). 대기 등록은 종전 한 줄 | 앱 | 3025 |
| D87 | PC 수업 관리: 취소한 수업이 빨간 칩 그대로 → **취소된 칩 흐림+취소선+'취소됨'** (`web/facing-admin templates/classes.html`). 연동은 정상이었고 그리기 결함. 로컬 playwright 재현·SSE 2.5초 반영 검증 · Railway 배포 SUCCESS | PC | — |
| D88 | **운동 데이터 연동 6단계 합의** (아래 §대기) — 문서·메모리만 | 문서 | — |

### 검증·배포
- 앱: 매 빌드 `analyze` 0 · 전량 테스트 · 골든 재생성 · 갤S22(172.30.1.50:5555)·에뮬레이터 설치 · GitHub Releases v1.0.0-30xx (최신 **3025**)
- 에뮬레이터는 **프로드 빌드 3025** 로 되돌려 둠 (검증용 로컬 빌드 → 프로드로 복구, 23:02). 로컬 서버 5060·8081 **꺼짐**.
- PC: `design/lint.py` baseline 유지. 프로드 `web-facing-admin` 배포 4352d013 SUCCESS.
- 실폰 화면 캡처는 오늘 내내 못 함(PIN 잠금) — 골든·에뮬레이터로 확인.

## 진행중

- [ ] 없음. 3 repo 워킹트리 깨끗.

## 대기 (다음 세션)

- [ ] **D88 운동 데이터 연동 — 1단계 착수**: 동작 사전(체육관 공용 · 이름/분류/기록 단위, 기존 `movements` 23종 기본 세트 + 코치 추가)
      + PC 수업 관리 그날 운동을 **드롭다운 동작 선택 + 횟수/무게 + 라운드/캡** 구조로. 자유 메모는 보조.
      2단계 = 회원 완료 입력(**예약자만** — `api/gym.py submit_wod_result` 에 예약 검사 추가, 동작별 값).
      3단계 = 리워드 엔진 동작 기반 조건(누적 N회·무게 ≥ Y·N종 경험) + 히스토리 동작 검색.
      기본값(반대 없으면 적용): 완료는 수업 시작 후 · 현장 참여는 코치 PC 대리 출석+기록 · 무게/횟수 동작만 필수 입력.
      기존 자유 텍스트 기록·표는 지우지 않는다. 정본 = 브리프 D88 · 메모리 `project-movement-data-flow`.
- [ ] (작음) PC 수업 관리: 다른 탭에서 수업 **생성**은 SSE 사건이 없어 안 뜸 (취소는 뜸). 만든 탭은 스스로 갱신.
- [ ] (작음) 로컬 DB 테스트 계정 `member` 가 '체육관 미가입' 으로 뜸 — 회원 행 기기 해시 불일치. 검증엔 지장 없었음.
- [ ] 어제 이월: 미수금 환불 차단 프로드 미검증 · 매출 결제 축 노출 여부 · 프로드 데이터 2건 · 스토어 준비.

## 결정사항 / 주의

- **사용자 교정 2건 (이 세션)**: "예약 가능한 시간이 아닙니다" 플레이스홀더 → 사용자가 원한 건 **버튼은 살려 두고 누르면 스낵바** (지시를 두 번 읽고 확인 질문 1회로 잡음). 에뮬레이터 검증 뒤 **프로드 빌드로 되돌려 놓지 않아** 사용자가 '백엔드 Off' 를 봄 — 앞으로 에뮬 검증 끝나면 반드시 프로드 APK 재설치.
- 선택지는 이름으로, ①② 기호 금지, 매 응답 푸시 (프로젝트 Rule 1) 유지.
- 히스토리 검색 순위는 **앱 한 곳**(history_search.dart) — 기록이 수천 건 되면 서버 `q=` 로 옮기되 규칙 표 그대로.
- 폭죽·토스트는 HKit 한 벌(`HkConfetti`·`HkSnack detail`) — 다른 모양 신설 금지.
- 골든 카운트 기록은 `CLAUDE.md §화면 골든 캡처` 첫 줄(75장) · 장별 설명은 `tool/golden_gallery.py`.
- 갤S22 무선 adb `172.30.1.50:5555` (오늘 그대로). PIN 잠금은 adb 로 못 넘김.
- 디자인 린트: `--muted` 는 폐기 토큰 → `--fg` + `opacity:var(--dim)`. `--dim` 은 색이 아니라 **불투명도 값**(0.65).

## 관련 파일

| 영역 | 경로 |
|---|---|
| 예약 흐름·문구 정본 | 앱 `lib/features/classes/class_flows.dart` (kBookingNotOpenSnack · kReservedTitle/Detail) |
| 스낵바·폭죽 | 앱 `lib/widgets/hkit.dart` (HkSnack.info detail · HkConfetti) |
| 체육관 정보 화면 | 앱 `lib/features/gym/gym_info_screen.dart` + `lib/widgets/gym_info_card.dart` |
| 히스토리 검색 | 앱 `lib/features/history/history_search.dart` · `history_screen.dart` · `test/history_search_test.dart` |
| 회원 셸 4탭 | 앱 `lib/features/shell/main_shell.dart` |
| PC 달력 취소 표시 | `web/facing-admin/templates/classes.html` (renderCalendar `is-cancelled`) |
| 결과 제출(예약 검사 없음 — D88 2단계 대상) | `services/hyphen/api/gym.py submit_wod_result` |
| 동작 표(D88 1단계 기반) | `services/hyphen/models/movement.py` · `data` movements 23종/4분류 |
| 리워드 엔진 트리거 | `services/hyphen/services/reward_engine.py` |
| 결정 이력 | `docs/ARCHITECTURE_BRIEF.md` D82 ~ D88 |
| 테스트 계정·로컬 실행 | `services/hyphen/docs/TEST-ACCOUNTS.md` (admin/1234 · member/1234, 백엔드 5060 · 관리자 웹 8081) |

## 다음 세션 권장 첫 프롬프트

`/resume` → **D88 1단계 착수**: 동작 사전 모델·API·PC 관리 화면 + 수업 관리 드롭다운 입력. 브리프 D88 의 표 4개·기본값 그대로.
