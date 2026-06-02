# HANDOFF - 2026-06-02 14:05

## 완료
- [x] **화면 재배치 Phase 1~5** (`docs/RESTRUCTURE_TODO.md` Move A~G) — 에뮬 검증 + 로컬 커밋
  - A: Home 점수카드 → Profile `ENGINE` 섹션(그래프 X, 숫자만)
  - B: Attend 게이미피케이션(Level·업적·Milestones) → Home / 출석 캘린더는 Attend 전담
  - C: Home 최상단 NOTICE 공지 아코디언(쪽지+공지 최신순)
  - E: Home WOD 카테고리 → WOD 탭 하단 `CALCULATE WOD` 아코디언
  - F: Notice 박스정보(GymInfoCard) → WOD 탭 최상단 `BOX INFO` 아코디언 (`gym_info_card.dart`에 margin 옵션 추가)
- [x] **D7 되돌림** — 종(🔔)은 전 화면 공통 메시징 진입이라 Home에도 복원 (`home_screen.dart`)
- [x] **stray 'Test' 박스(gym 5, busan) 삭제** — 박지훈 코치 `/gyms/mine`이 FACING SEONGSU(gym 2) 가리키게. 로컬 SQLite 데이터 변경 (`data/facing.db` gitignore, 커밋 대상 아님)
- [x] **회원↔코치 양방향 쪽지 (카톡식)** — 4단계(회원발신·코치수신·코치답장·회원수신) 전부 에뮬 검증
  - 회원 NOTICE = 코치와 1:1 대화뷰(공지핀+말풍선+입력바)
  - 코치 NOTICE = 회원별 대화목록 → 탭하면 1:1 채팅
  - 백엔드: `GET /gym/<id>/messages`(보낸것+받은것, `?peer` 1:1 필터) + `GET /gym/<id>/threads`(코치 목록)
  - 발신: 회원=`member-report`, 코치=`post_note(individual)`
- [x] **새 쪽지 실시간 자동 갱신** — 백엔드 `note.new` SSE publish(post_note·member_report·ask_coach) → 앱 대화/목록이 0.4초 디바운스 후 자동 reload. 에뮬에서 "REALTIME PUSH" 자동 표출 확인

## 진행중
- (없음) — 메시징 기능 일단락

## 대기 (다음 후보)
- [ ] 안 읽은 쪽지 배지를 하단 탭·종 아이콘에 실시간 반영
- [ ] 쪽지 도착 시 폰 푸시 알림(앱 종료 시)
- [ ] D8: 코치/신규 페르소나 5탭 추가 검증
- [ ] 라이트/다크 테마 — 앱이 라이트로 뜸(CLAUDE.md는 다크 #0A0A0A 기본). 이번 작업 무관, 별건

## 관련 파일
- 앱: `lib/features/inbox/inbox_screen.dart` (대화뷰·스레드목록·1:1·SSE), `lib/models/chat_message.dart` (ChatMessage·CoachThread), `lib/features/inbox/inbox_repository.dart` (listMessages/peer·listThreads), `lib/features/announcements/announcements_state.dart` (items getter)
- 앱 재배치: `lib/features/home/home_screen.dart`, `lib/features/mypage/mypage_screen.dart`, `lib/features/attendance/attendance_screen.dart`, `lib/features/gym/box_wod_screen.dart`, `lib/widgets/gym_info_card.dart`, `lib/features/shell/main_shell.dart`
- 백엔드(별도 repo `C:\dev\services\facing`): `api/coach_note.py` (messages/threads/peer + `_publish_note_new`)
- SSOT 문서: `docs/RESTRUCTURE_TODO.md`, `docs/ARCHITECTURE_BRIEF.md`

## 결정사항 / 주의
- **배포 금지** — 이 세션 전부 로컬 커밋만. push·Railway 안 함 (`CLAUDE.md` 최상위 룰)
- 종(🔔) = 모든 화면 공통 메시징 진입. 회원·코치 둘 다 카톡식 대화로 통일
- SSE는 박스(gym_id) 단위 broadcast. `note.new` 1개로 회원/코치 양쪽 화면 갱신
- 백엔드 자동 리로드 안 됨 — `coach_note.py` 수정 시 백엔드 수동 재시작 필요
- 좀비 주의: flutter run / `python app.py` 재시작 시 옛 프로세스 정리. 백엔드 죽으면 `netstat :5060` 확인 후 `cd C:\dev\services\facing && python app.py` 재기동
- 현재 상태: 백엔드 5060 가동중, 에뮬 emulator-5554에 **회원(김도윤)** 페르소나로 앱 떠 있음. 페르소나 전환 = Profile 하단 QUICK SWITCH (박지훈=코치 SEONGSU)
- gym_coach_profiles→gym_managers FK가 깨져있어 gym 삭제 시 cascade 에러 → FK OFF 후 삭제 필요 (기존 이슈)

## 다음 세션 권장 첫 프롬프트
`/resume`
