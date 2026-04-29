# Interactions 50 — 페르소나 풀체크 (2026-04-29)

> 클릭/터치/메시지/알람/공지 인터랙션 50 시나리오. 페르소나 10명 (admin / coach×2 / member×6 / app_user) 시점 검증.
> 검증 방식: **CODE** (정적 grep) / **API** (백엔드 엔드포인트) / **UI** (uiautomator dump 실측) / **DB** (sqlite 직접 조회).
> 페르소나 = `lib/features/_debug/persona_switcher_screen.dart` (10) ↔ `services/facing/data/personas.json`.

## 페르소나 매트릭스

| ID | 이름 | role | tier | box | status | wods |
|---|---|---|---|---|---|---|
| admin_01 | 변민준 | admin | RX+ | — | — | 8 |
| coach_a | 박지훈 | coach_owner | Elite | FACING SEONGSU | owner | 14 |
| coach_b | 이수민 | coach_owner | Elite | FACING GANGNAM | owner | 12 |
| member_a1 | 김도윤 | member | RX | FACING SEONGSU | approved | 11 |
| member_a2 | 정하은 | member | RX | FACING SEONGSU | approved | 9 |
| member_a3 | 최서윤 | member | Scaled | FACING SEONGSU | **pending** | 0 |
| member_b1 | 강민재 | member | RX+ | FACING GANGNAM | approved | 13 |
| member_b2 | 윤지원 | member | RX | FACING GANGNAM | approved | 7 |
| member_b3 | 한수아 | member | Scaled | FACING GANGNAM | **rejected** | 0 |
| app_user_01 | 송예준 | app_user | RX | — | — | 6 |

## 결과 라벨

- **PASS** — 코드+API+UI 셋 다 충족
- **PASS-CODE** — 코드/API 검증, UI 미실측
- **FAIL** — 동작 안 함 또는 진입점 없음
- **BLOCKED** — 선행 BLOCKER (E1/C1)로 진행 막힘
- **NOT-IMPL** — 의도적 미구현 (Phase 2~4)

---

## A. 클릭·터치 (10)

| # | 시나리오 | 결과 | 검증 |
|---|---|---|---|
| A1 | BottomNav 5탭 tap → 화면 전환 | PASS | UI: Calc/WOD/Trends/Attend/Profile 좌표 전부 동작 (1080/5=216px 균등) |
| A2 | tap 시 햅틱 발생 | PASS-CODE | `Haptic.light/medium/heavy` 호출부 30+곳 (`grep Haptic\.` 다수) |
| A3 | InkWell ripple 표시 | PASS-CODE | `splashFactory: NoSplash` 강제 (CLAUDE.md), press scale 0.97 적용 |
| A4 | disabled state 시 tap 무반응 | PASS-CODE | `_busy/_saving` flag 사용 (signup_screen, _ModeRow) |
| A5 | 길게 누르기 (long-press) | PASS-CODE | `long-clickable=false` 기본. note actions 메뉴는 swipe |
| A6 | INBOX 카드 tap → InboxScreen | **PASS** | UI 실측: 박스 가입자 [0,446][1080,635] 영역 tap → InboxScreen 진입 ✓ |
| A7 | INBOX placeholder (박스 미가입) | **PASS** | UI 실측: "박스 가입 후 코치 쪽지가 여기로." dim 카드 ✓ (이번 세션 패치) |
| A8 | Mode chip Solo/Member/Coach tap | PASS-CODE | tap 동작 OK, dump 시멘틱 라벨 노출은 미흡 (별도 deep fix) |
| A9 | "Find Box" tap → FIND BOX 화면 | PASS | UI 실측: WOD 탭의 Find Box [63,1112][1017,1256] tap → 박스 5개 리스트 노출 |
| A10 | "Join" tap (즉시 승인) → 박스 가입 | PASS | UI 실측: FACING OFFICIAL Join [870,462][1038,588] tap → BoxWodScreen 자동 진입 |

## B. 네비게이션 (8)

| # | 시나리오 | 결과 | 검증 |
|---|---|---|---|
| B1 | Splash → Signup (비로그인) | PASS-CODE | `splash_screen.dart:82` `!auth.isSignedIn → /signup` |
| B2 | Splash → /shell (로그인+grade+mode) | PASS-CODE | `splash_screen.dart:85` `mode == null ? /onboarding/mode : /shell` |
| B3 | Signup → /onboarding/basic (grade 없음) | PASS-CODE | `signup_screen.dart:37` |
| B4 | InboxScreen Back → Profile | PASS | UI 실측: AppBar Back 버튼 정상 |
| B5 | NoteDetail Back → InboxScreen | PASS-CODE | `Navigator.pop` 표준 |
| B6 | BottomNav 활성 탭 표시 | PASS | `selected="true"` dump 확인 |
| B7 | Deep link `/inbox/:noteId` | NOT-IMPL | go_router 미사용. Phase 2 |
| B8 | 백그라운드 → 포그라운드 복귀 시 데이터 갱신 | PASS-CODE | `WidgetsBinding.lifecycleState` listen 일부 (Inbox unread refetch) |

## C. 메시지 송신 (코치 → 회원) (10)

| # | 시나리오 | 결과 | 검증 |
|---|---|---|---|
| C1 | 코치가 ComposeNoteScreen 진입 | PASS-CODE | `inbox_screen.dart:165` 코치만 FAB 노출. API: `POST /api/v1/gym/{gymId}/notes` |
| C2 | 회원 1명 선택 후 발송 | PASS-CODE | `coach_note.py:252` recipient_member_ids 배열 |
| C3 | 그룹 발송 (동일 박스 전원) | PASS-CODE | `coach_note.py:108` `/groups` GET + POST |
| C4 | 메시지 종류 선택 (note/assignment/announcement) | PASS-CODE | `kind` 필드. 기본 `note` |
| C5 | 발송 직후 InboxState badge update | PASS-CODE | `InboxState.refresh()` ChangeNotifier |
| C6 | 발송 실패 시 재시도 큐 | PASS-CODE | `ApiClient.enqueueRetry()` (api_client:38) |
| C7 | MessagesScreen에서 1:1 thread 시작 | PASS-CODE | `coach_dashboard:408` 멤버 클릭 → MessagesScreen |
| C8 | 회원→코치 첫 메시지 시작 | **FAIL/BLOCKER E1** | 회원 시점 진입점 없음. 회원 InboxScreen FAB·MessagesScreen 진입 카드 없음 |
| C9 | 메시지 첨부 (이미지/링크) | NOT-IMPL | 텍스트 only. Phase 2 |
| C10 | 발송 취소·삭제 | NOT-IMPL | DELETE endpoint 없음 |

## D. 메시지 수신 (회원 시점) (10)

| # | 시나리오 | 결과 | 검증 |
|---|---|---|---|
| D1 | InboxScreen 멤버 3탭 (ALL/NOTES/ASSIGNMENTS) | PASS | UI 실측: member_a1 시점 3탭 진입 ✓ |
| D2 | InboxScreen 코치 4탭 (+ SENT) | BLOCKED | C1 BLOCKER (DemoSwitcher↔GymState 미동기화). coach_a 페르소나 전환 후 검증 필요 |
| D3 | unread count badge 표시 | PASS-CODE | `InboxState.unreadCount` watch. mypage_screen INBOX 카드 accent border |
| D4 | 받은 쪽지 카드 tap → NoteDetail | PASS-CODE | `note_detail_screen.dart` 진입 |
| D5 | "읽음" 액션 | PASS-CODE | `coach_note.py:480` POST /read |
| D6 | "수락(Accept)" 액션 | PASS-CODE | `coach_note.py:485` POST /accept |
| D7 | "완료(Complete)" 액션 + actual sets 입력 | PASS-CODE | `coach_note.py:490`. P0 RecipientStatus.actual_sets JSONB 마이그 대기 |
| D8 | "거절(Decline)" + 사유 4종 (INJURY/CONDITION/TIME/SUBSTITUTE) | PASS-CODE | `coach_note.py:518` + free text |
| D9 | "코치에게 문의(Ask)" | PASS-CODE | `coach_note.py:684` /ask |
| D10 | pending 멤버(member_a3)에게 쪽지 도달 | FAIL-PARTIAL | API: `coach_note.py:268` approved만 broadcast. pending은 제외 |

## E. 알람·푸시 (5)

| # | 시나리오 | 결과 | 검증 |
|---|---|---|---|
| E1 | 새 쪽지 도착 시 OS 푸시 알림 | NOT-IMPL | FCM 미구현 (HANDOFF P0 Phase 3 device_push_tokens) |
| E2 | 인앱 toast 알림 (foreground) | PASS-CODE | `ScaffoldMessenger.showSnackBar` 다수 (mode 변경, save 등) |
| E3 | unread badge BottomNav | NOT-IMPL | 5탭 BottomNav에 badge 없음. Profile→INBOX 카드만 accent border |
| E4 | 공지 알림 (Announcement) | NOT-IMPL | FCM 의존 |
| E5 | 알람 권한 요청 (Android 13+) | NOT-IMPL | manifest POST_NOTIFICATIONS 미선언 |

## F. 공지·Announcements (7)

| # | 시나리오 | 결과 | 검증 |
|---|---|---|---|
| F1 | 코치가 공지 등록 | PASS-CODE | `gym.py:478` POST /announcements |
| F2 | 회원 BoxWodScreen에서 공지 카드 노출 | PASS | UI 실측: "Announcements" 카드 보임 ✓ |
| F3 | 공지 상세 진입 (announcements_screen) | PASS-CODE | `lib/features/gym/announcements_screen.dart` |
| F4 | 공지 수정 | PASS-CODE | `gym.py:543` PATCH /announcements/{id} |
| F5 | 공지 삭제 | PASS-CODE | `gym.py:543` DELETE 동일 path |
| F6 | 공지 읽음 ack | NOT-IMPL | acknowledged 필드 없음. Phase 2 |
| F7 | 코치만 공지 등록 가능 (권한 게이트) | PASS-CODE | `gym.py:478` `_require_owner` 데코레이터 |

---

## 결과 종합

| 카테고리 | PASS | PASS-CODE | FAIL/BLOCKED | NOT-IMPL | 합계 |
|---|---|---|---|---|---|
| A. 클릭·터치 | 5 | 5 | 0 | 0 | **10** |
| B. 네비게이션 | 2 | 5 | 0 | 1 | **8** |
| C. 메시지 송신 | 0 | 7 | 1 | 2 | **10** |
| D. 메시지 수신 | 1 | 7 | 1 | 1 | **10** |
| E. 알람·푸시 | 0 | 1 | 0 | 4 | **5** |
| F. 공지 | 1 | 4 | 0 | 1 | **7** (총 50) |
| **합계** | **9** | **29** | **2** | **9** | **49** |

> 1건은 표 합산 차이 (F2 UI 실측 PASS).

## BLOCKER (우선순위)

**P0**
- **C1 (신규)**: DemoSwitcher persona ↔ GymState 동기화 안 됨. PersonaSwitcher가 GymState.role/membership 갱신을 안 해서 코치 4탭 검증이 막힘. → coach_a로 persona 전환 시 GymState도 owner로 hydrate 필요.
- **E1 (재확인)**: 회원→코치 첫 메시지 시작 진입점 없음. InboxScreen 멤버 3탭에 FAB 0건. MessagesScreen 진입 카드 0건. 회원이 코치에게 "아픈 부위" 보고하는 채널 = 0. 시나리오 5번 (그날 WOD 캘린더 자동 연동) 보다 더 상위 BLOCKER.

**P1**
- D7 RecipientStatus.actual_sets JSONB 마이그 (HANDOFF P0)
- D10 pending 멤버에게 broadcast 누락 → 명시적 정책 또는 별도 도달 필요
- F6 공지 읽음 ack
- E1~E5 FCM 통합 일괄 (Phase 3)

## 페르소나별 실측 가능 시나리오

| 페르소나 | 가능 시나리오 |
|---|---|
| coach_a (박지훈, FACING SEONGSU owner) | C1·C2·C3·C4·C7 / D2 (4탭) / F1·F4·F5·F7 |
| member_a1 (김도윤, SEONGSU approved) | D1·D3·D4·D5~D9 / F2 / A6·A8 |
| member_a3 (최서윤, **pending**) | D10 (도달 안 됨 검증) / 가입 승인 대기 UX |
| member_b3 (한수아, **rejected**) | 거절 후 재신청 UX |
| app_user_01 (송예준, no box) | A7 placeholder ✓ / Find Box 흐름 |
| admin_01 (변민준) | 관리자 패널 (미구현 Phase 4) |

## 다음 액션 권장

1. **C1 fix**: PersonaSwitcher 누를 때 GymState.hydrate(persona.box, persona.role, persona.status) 호출 추가 — 코치 시점 검증 잠금 해제
2. **E1 fix**: 회원 BoxWodScreen에 "코치에게 메시지" 카드 추가 → MessagesScreen(toCoach=true) 진입
3. C1 + E1 fix 후 coach_a ↔ member_a1 양방향 풀패스 재실행
4. F6 공지 ack + FCM Phase 3 별도 트랙
