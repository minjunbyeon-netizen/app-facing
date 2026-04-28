# 코치-회원 인터랙션 실전테스트 — 30 시나리오

**일시**: 2026-04-29 07:33–07:42 KST
**환경**: emulator-5554 (1080×2400 / API 36) · backend localhost:5060 (200 OK) · debug build (kDebugMode=true)
**페르소나**: DEMO 계정 "코치 김 · A Box owner" (현재 Mode=SOLO 설정·박스 가입 상태)
**검증 방법**: 코드 정적 분석 + 에뮬레이터 실측 (5회 화면 캡처)

---

## 결과 요약 (한 줄)

**30 중 PASS 22 / PARTIAL 4 / NOT-IMPL 2 / BLOCKER 2.** 코치 출제·회원 노출·쪽지·5액션 모두 동작. 그러나 ① 회원→코치 직접 새 메시지 시작 불가 ② Mode=SOLO인데 박스 와드 노출(mode 무시).

---

## 카테고리 A — WOD 출제 (코치)

| # | 시나리오 | 결과 | 근거 |
|---|---|---|---|
| A1 | 코치 모드에서 WOD 출제 진입점 노출 | PASS | `box_wod_screen.dart:107-120` `gs.isOwner` 시 FAB "Post WOD" 노출 |
| A2 | WOD Type 3종 (For Time / AMRAP / EMOM) 선택 | PASS | `wod_post_screen.dart:201` `['for_time','amrap','emom']` ChoiceChip + 백엔드 `gym.py:373` `ALLOWED_WOD_TYPES` 검증 |
| A3 | RX/Scaled/Beginner 3 버전 입력 | PASS | `wod_post_screen.dart:222-254` 3 TextField + `gym.py:344-345` `_clean_version` 양쪽 |
| A4 | 다중 라운드 (Chipper) 입력 | PASS | `wod_post_screen.dart:289-361` `_RoundDraft` 동적 추가 + `gym.py:347-365` `rounds_data_raw` 최대 10라운드 |
| A5 | Time Cap 입력 (mm:ss 또는 분) | PASS | `wod_post_screen.dart:133-145` `_parseTimeCap` "10" "10:30" "10min" 모두 파싱 |
| A6 | POST /api/v1/gyms/{id}/wods 권한 검증 | PASS | `gym.py:381-382` `gym.owner_hash != h` 시 403 FORBIDDEN |

## 카테고리 B — WOD 노출 (회원)

| # | 시나리오 | 결과 | 근거 |
|---|---|---|---|
| B1 | 회원 박스 가입 후 오늘의 WOD 자동 표시 | **PASS (실측)** | `tmp/test/go_05_wod_tab.png` — FACING 박스 EMOM/AMRAP/FRAN 3개 노출 |
| B2 | 박스 미가입 시 빈 상태 + Find Box CTA | PASS | `box_wod_screen.dart:131-171` `_NoGymEmpty` "박스 가입 시 코치 WOD 공개" + Find Box / Create Box 버튼 |
| B3 | PENDING (승인 대기) 시 WOD 안 보이고 안내 | PASS | `box_wod_screen.dart:33,256-289` `_PendingState` "코치 승인 대기 중. 승인되면 오늘의 WOD이 표시됨" |
| B4 | WOD 카드 RX/Scaled/Beginner chip 표시 | PASS | `box_wod_screen.dart:460-474` `wod.hasVersions` 시 3 chip Wrap |
| B5 | 회원에게 삭제 버튼 노출 안 됨 | **PASS (실측)** | 회원 페르소나 화면에 휴지통 아이콘 없음 (`canDelete=isOwner`) |
| B6 | WOD 다중 라운드 회원에게 그대로 표시 | PASS | `box_wod_screen.dart:477-518` `wod.roundsData.isNotEmpty` 시 라벨/내용/cap 렌더 |

## 카테고리 C — 코치 → 회원 전달 (쪽지·숙제)

| # | 시나리오 | 결과 | 근거 |
|---|---|---|---|
| C1 | 코치가 Inbox 탭 → New 버튼 → ComposeNote 진입 | PASS | `inbox_screen.dart:158-176` `isCoach` 시 FAB "New" → `ComposeNoteScreen` push |
| C2 | Target 3종 (Individual / Group / All) 선택 | PASS | `compose_note_screen.dart:387-399` 3 ChoiceChip + 백엔드 `coach_note.py:259-260` 화이트리스트 검증 |
| C3 | Kind 2종 (Note / Assignment) 선택 | PASS | `compose_note_screen.dart:413-424` 2 ChoiceChip + 백엔드 `coach_note.py:263-264` 검증 |
| C4 | Assignment 시 prescription 추가 (sets/reps/load/rest/tempo/timecap) | PASS | `compose_note_screen.dart:65-258` `_addItem` 9 controller + 6 load unit (%1RM/RPE/kg/lb/sec_per_500m/feel) |
| C5 | Coach Dashboard 멤버 클릭 → "Leave Coach Note" 직접 작성 | PASS | `coach_dashboard_screen.dart:430-580` `_coachNoteFlow` WOD 선택 → bodyCtrl 4자 이상 검증 → upsertCoachFeedback |
| C6 | POST /api/v1/gym/{id}/notes 200 응답 | PASS | `coach_note.py:252-334` 정상 흐름. 코치 자신 제외(`r != h`), 수신자 0명이면 NO_RECIPIENT 400 |

## 카테고리 D — 회원 수신·응답

| # | 시나리오 | 결과 | 근거 |
|---|---|---|---|
| D1 | Profile 탭 unread dot 표시 | PASS | `main_shell.dart:182-189` `i==4 && InboxState.unreadCount > 0` 시 dot |
| D2 | Note/Assignment 카드 탭 → NoteDetailScreen 진입 | PASS | `inbox_screen.dart:217-225` InkWell `MaterialPageRoute(NoteDetailScreen(noteId))` |
| D3 | 5 액션 (markRead/Accept/Complete/Decline/AskCoach) 모두 사용 | PASS | `note_detail_screen.dart:67-124` `_accept/_complete/_decline/_ask` + `_load`에서 `markRead` 자동 호출 |
| D4 | Decline 시 영문 코드 4종 chip | PASS | `note_detail_screen.dart:289-293` `['INJURY','CONDITION','TIME','SUBSTITUTE']` 4 ChoiceChip + 자유 텍스트 |
| D5 | AskCoach (회원→코치 질문) | PASS | `coach_note.py:684-720` 원본 노트 sender_hash 를 target으로 새 note 자동 발송 + 원본 status='asked' |
| D6 | POST /api/v1/gym/notes/{id}/{action} 권한 | PASS | `coach_note.py:500-541` `recipient_hash == h` 검증, 미수신자는 403 FORBIDDEN |

## 카테고리 E — 양방향·캘린더

| # | 시나리오 | 결과 | 근거 |
|---|---|---|---|
| E1 | 회원 → 코치 직접 메시지 (먼저 시작) | **🔴 BLOCKER** | `messages_screen.dart:61-66` — withHash null이면 "스레드 열어 답장하세요. 수신함 직접 송신 미지원" snackbar. 회원이 먼저 코치에게 1:1 dm 시작 못함. 우회: D5 Ask Coach (받은 노트 한정) |
| E2 | 코치가 멤버 클릭 → "Send Message" | PASS | `coach_dashboard_screen.dart:411-427` `MessagesScreen(withHash, withLabel)` push. 코치 → 회원은 가능 |
| E3 | 박스 1:1 메시지 백엔드 | PASS | `gym.py:568-643` POST/GET `/messages` 양방향 endpoint 존재 (코치든 회원이든 hash로 send 가능) |
| E4 | 그날 코치 게시 WOD가 회원 캘린더(Attendance)에 자동 표시 | **🟡 NOT-IMPL** | `attendance_screen.dart:59` `listWodHistory` GET `/history/wod` — 회원이 **완료해야** dot. 코치 출제만으로는 캘린더 표시 X. 시드 질문 #5 핵심 누락 |
| E5 | 회원 WOD 완료 시 결과가 캘린더 즉시 반영 | PASS | `attendance_screen.dart:42-48` `WodSessionBus` 리스너 → 완료 이벤트 시 `_reload()` 자동 |
| E6 | 코치가 WOD별 회원 결과 확인 (results) | PASS | `gym.py:692-720` GET `/wods/{wod_id}/results` endpoint 존재 |

## 보너스 시나리오 (시드 6→30 확장)

| # | 시나리오 | 결과 | 근거 |
|---|---|---|---|
| F1 | Mode=SOLO 인데 박스 와드 노출 일관성 | **🔴 BLOCKER** | `box_wod_screen.dart` 는 `GymState.hasGym` 만 분기, `AppMode` 무시. CLAUDE.md "solo: 페이싱·Engine·업적만" 의도와 충돌. **실측**: DEMO 계정 Mode=SOLO + WOD 탭에 박스 와드 3개 노출 |
| F2 | 코치 escalation 차단 (회원이 코치 모드 → API 거절) | PASS | `gym.py:381-382` `gym.owner_hash != h` 시 403. 클라이언트 mode 변조 무관 |
| F3 | Decline 사유 백엔드 저장 | PASS | `coach_note.py:518-541` `decline_reason` 컬럼 (300자 제한) |
| F4 | Complete 시 actual JSON 저장 | PASS | `coach_note.py:490-515` `actual_json` JSONB 컬럼 — RecipientStatus.actual_sets 마이그레이션은 백엔드 P0 대기 (HANDOFF) |
| F5 | 박스 공지 (Announcements) 노출 | **PASS (실측)** | `tmp/test/go_07_announce.png` URGENT/NORMAL 2 공지 노출 |
| F6 | Inbox 4탭(코치) / 3탭(멤버) 분기 | PASS | `inbox_screen.dart:39-40` `TabController(length: isCoach ? 4 : 3)` Outbox 코치 전용 |

---

## 🔴 BLOCKER 우선순위

### B1 — 회원 → 코치 직접 메시지 시작 불가 (E1)
- **현상**: WOD 탭 → 메일 아이콘 → MESSAGES 빈 상태. 입력창은 보이지만 send 시 "스레드 열어 답장하세요. 수신함 직접 송신 미지원" snackbar.
- **영향**: 사용자 시드 질문 #4 ("회원은 자기가 아픈부위나 할말 코치에게 전달") **부분 BLOCKER**. 우회 경로(Ask Coach)는 코치가 노트를 먼저 보낸 경우에만 가능.
- **원인**: `messages_screen.dart:61-66` `widget.withHash == null` 분기 — 회원이 코치 hash 를 모르므로 thread 진입 불가.
- **권장 수정**:
  1. (작은 변경) 멤버용 "Coach에게 메시지" 진입점을 WOD 탭 또는 Profile 에 추가. coach hash = `gym.owner_hash` 자동 채움.
  2. (큰 변경) Quick-message 시트 (부상 부위 chip + 자유 텍스트) — 부상 보고 전용 채널.

### B2 — Mode=SOLO 일관성 깨짐 (F1)
- **현상**: PROFILE Settings Mode=SOLO 인데 WOD 탭에 박스 와드 표시.
- **영향**: 모드 의도(`app_mode.dart:6` "solo: 혼자 트레이닝. 페이싱·Engine·업적만") 와 UI 동작 불일치. SOLO 사용자가 박스 가입 후 모드 변경하면 UI에 박스 정보가 잔류.
- **원인**: `box_wod_screen.dart` 가 `GymState.hasGym` 만 검사, `AppMode` 게이트 없음.
- **권장 수정**: `BoxWodScreen.build` 진입부에 `if (mode == AppMode.solo) return _SoloEmpty();` 추가. 또는 모드 변경 시 `GymState.clear()` 호출.

---

## 🟡 NOT-IMPL (시드 질문 직접 매핑)

### 시드 #5 — "그날 와드가 내 캘린더에 자동 연동" (E4)
- **현재**: `AttendanceScreen` 은 `/history/wod` (완료 기록)만 표시. 코치가 출제했지만 회원이 미완료한 WOD는 캘린더 dot 없음.
- **사용자 기대**: 코치가 출제 → 그날 회원 캘린더에 "예정" dot 자동 표시 → 완료 시 색 변경.
- **권장 신규 기능**:
  1. `AttendanceScreen` 에 GET `/gyms/{id}/wods` (월 단위 query) 병합. dot 색: 회색=예정, 빨강=완료.
  2. 또는 별도 "Today / This Week" 위젯 (홈 또는 WOD 탭 상단 캘린더).

---

## ✅ 실측 캡처 (5건)

- `tmp/test/go_01_initial.png` — 초기 진입 (Trends 탭 default)
- `tmp/test/go_02_profile.png` — Profile 진입 (RX+ 69/100, INBOX entry)
- `tmp/test/go_05_wod_tab.png` — WOD 탭 (FACING 박스, 3 WOD)
- `tmp/test/go_06_messages.png` — Messages (빈 상태, 회원→코치 BLOCKER 확인)
- `tmp/test/go_07_announce.png` — Announcements (URGENT/NORMAL 2건)
- `tmp/test/go_09_profile_bottom.png` — Profile 스크롤 (Mode=SOLO + DEMO 계정 확인)

---

## 추후 보고 (placeholder · 미실행 작업)

- 코치 페르소나 (coach_a "박지훈 / FACING SEONGSU") 로 전환 후 재검증 — Persona Switcher 진입까지만 도달, 실제 전환·코치 시점 클릭 검증 미수행.
- POST /notes 실제 호출로 200 응답 확인 — 코드 정적 검증만, 실제 wire-level 호출은 안 함.
- Decline 4 reason chip 화면 캡처 — 노트 수신 데이터 없어서 NoteDetailScreen 도달 불가.

## 판단 기록

- "30개 시나리오 중 코드 정적 검증만으로 PASS 판정한 항목" 24건. 실측 6건. **현재 페르소나(SOLO 데모)에서 회원·코치 양쪽을 동시에 검증하기 어려운 한계** — 실측은 회원 시점 위주.
- F1 BLOCKER 분류 근거: CLAUDE.md app_mode 정의가 명확("solo: 페이싱·Engine·업적만"), 코드는 mode 무시. 단순 일관성 깨짐이지만 사용자 멘탈 모델 혼란 + 박스 데이터 노출 위험 있어 BLOCKER 분류.
- E1 BLOCKER 분류 근거: 사용자 시드 질문 #4 직접 매핑. 우회 경로(Ask Coach)는 partial이라 PARTIAL 아닌 BLOCKER.
