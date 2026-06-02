# HANDOFF - 2026-06-02 22:28

## 완료
- [x] **화면 재배치 Phase 1~5** (`docs/RESTRUCTURE_TODO.md` Move A~G) — 에뮬 검증 + 로컬 커밋
  - A 점수→Profile ENGINE(숫자만) / B 게이미피케이션→Home·캘린더→Attend / C Home 공지 아코디언 /
    E WOD 카테고리→WOD 하단 / F BOX INFO→WOD 최상단 아코디언 / D7 종(🔔) 전 화면 복원
- [x] **stray 'Test' 박스(gym 5) 삭제** — 박지훈 코치 `/gyms/mine`이 FACING SEONGSU(gym 2) 가리키게 (로컬 SQLite, 커밋 대상 아님)
- [x] **회원↔코치 양방향 쪽지 (카톡식) 완성** — 4단계 + 다중 코치 구조 + 실시간 + 먼저 말걸기까지 전부 에뮬 검증
  - 회원 NOTICE = 공지핀 + **코치별 대화목록** → 탭하면 1:1 채팅 + 하단 "코치에게 쪽지" FAB(받은적 없어도 시작)
  - 코치 NOTICE = **회원별 대화목록** → 탭하면 1:1 채팅 + "New"(브로드캐스트)
  - 1:1 채팅 = 말풍선(내것 우측 accent / 상대 좌측), 입력바 역할별 힌트
  - 발신: 코치=`post_note(individual)`, 회원=`member-report(to=peer)`
  - **실시간 자동 갱신**: 백엔드 `note.new` SSE publish → 앱 대화/목록 0.4초 디바운스 reload (검증 OK)

## 진행중
- (없음) — 쪽지 시스템 일단락

## 대기 (다음 후보)
- [ ] **다중 코치 데이터** — 현재 박스당 코치=오너 1명 구조. 코치/매니저 역할(여러 명이 post_note 가능)은 백엔드 작업 필요. `gym_managers` 테이블은 존재. UI는 이미 다중 코치 준비됨(목록 N줄 자동)
- [ ] 안 읽은 쪽지 배지를 하단 탭·종 아이콘에 실시간 반영
- [ ] 쪽지 도착 시 폰 푸시 알림(앱 종료 시)
- [ ] D8: 코치/신규 페르소나 5탭 추가 검증
- [ ] 라이트/다크 테마 — 앱이 라이트로 뜸(CLAUDE.md는 다크 #0A0A0A 기본). 별건

## 관련 파일
- 앱 (cwd `C:\dev\apps\facing-app`): `lib/features/inbox/inbox_screen.dart` (대화목록·1:1·SSE·FAB — 핵심),
  `lib/models/chat_message.dart` (ChatMessage·CoachThread), `lib/features/inbox/inbox_repository.dart` (listMessages/peer·listThreads),
  `lib/features/gym/gym_repository.dart` (memberReport to 옵션), `lib/features/announcements/announcements_state.dart` (items getter),
  `lib/models/gym.dart` (GymSummary.ownerHash)
- 백엔드 (별도 repo `C:\dev\services\facing`): `api/coach_note.py` — `/messages`(?peer), `/threads`(회원 허용), `member-report`(to=특정코치), `_publish_note_new`(SSE)
- SSOT 문서: `docs/RESTRUCTURE_TODO.md`, `docs/ARCHITECTURE_BRIEF.md`

## 결정사항 / 주의
- **배포 금지** — 이 세션 전부 로컬 커밋만. push·Railway 안 함 (`CLAUDE.md` 최상위 룰)
- 종(🔔) = 모든 화면 공통 메시징 진입. 회원·코치 둘 다 대화목록→1:1 통일
- SSE는 박스(gym_id) 단위 broadcast. `note.new` 1개로 회원/코치 양쪽 화면 갱신
- 백엔드 자동 리로드 안 됨 — `coach_note.py` 수정 시 백엔드 수동 재시작(`cd C:\dev\services\facing && python app.py`)
- 좀비 주의: 백엔드/flutter 재시작 시 옛 프로세스 정리. 백엔드 죽으면 `netstat :5060` 확인
- 현재 상태: 백엔드 5060 가동중, 에뮬 emulator-5554에 **회원(김도윤)** 페르소나로 앱 떠 있음. 페르소나 전환 = Profile 하단 QUICK SWITCH (박지훈=코치 SEONGSU)
- 큰 스크린샷은 API 거부됨 → PIL thumbnail(760,1680) 로 다운스케일 후 Read
- gym_coach_profiles→gym_managers FK 깨짐 — gym 삭제 시 FK OFF 후 삭제 필요(기존 이슈)

## 다음 세션 권장 첫 프롬프트
`/resume`
