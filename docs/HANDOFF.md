# HANDOFF - 2026-08-06 20:43

> 3개 레포 동시 작업 세션. 전부 **로컬 커밋만** (배포 금지 규칙 유지, push 0건).
> facing-app `8237e7b` · services/facing `d3e4f1b` · web/facing-admin `a62c3e6`

## 완료

### A. 홈 화면 정돈 (facing-app · v1.30)
- [x] 업적 3열 색 타일 그리드 → **한 줄 한 항목 표** (최대 5줄 + "그 외 N개")
- [x] FKit 신설: `FkListRow`(표 행 유일 규격) · `FkRowCard`(1px 구분선 표 카드)
      — `lib/widgets/fkit.dart`
- [x] 마일스톤 3종도 같은 표 카드로, 레벨 카드는 `FkCard` 로 교체
- [x] `docs/DESIGN-SSOT.md` §5 컴포넌트 표 + **§7-A 나열형 데이터 표기** 신설
      (색 타일 그리드 금지·최대 5줄·상세는 시트로)
- [x] 죽은 코드 제거 (`_GridTile`·`_OverflowTile`), 빈 상태 한글화

### B. 업적 한글 칭호 전수 (facing-app)
- [x] 서버 카탈로그 **56종 전수 매핑** — 구 매핑 40개 중 14개가 서버에 없는 옛 코드였음
- [x] 중복 칭호 제거: '분석가'(SCORE_80↔TITLE_SCHOLAR) · '삼중의 위협'(EGG↔VOL)
- [x] `AchievementCard.displayTitle(catalog)` 신설 — 홈 표·전체 보기 그리드·featured
      패널이 같은 표기 사용. featured 는 한글 제목 + 영문 고유명 부제로 뒤집음
- [x] `lockedHint(catalog)` — 잠금 조건 문구를 **서버 description 우선**으로
      (정적 힌트가 신규 코드를 못 따라가 "미공개 조건." 뜨던 문제 차단)
- [x] 전체 보기 필터 재분류: TIER 잡동사니 통 → **ENGINE 신설**, CF_* 는 시즌으로.
      칩 한글화(전체·연속·시즌·누적·히든)
- [x] BLOCKER fix: featured 패널 '달성 · 날짜' 가로 6.6px 오버플로우
- [x] 가드 테스트 `test/achievement_titles_test.dart` (56종 커버·중복 0)

### C. PC 회원 쪽지 (services/facing + web/facing-admin) — 이번 세션 최대 건
- [x] 백엔드: `coach_note.build_threads()`·`build_messages()` 추출 → 폰(device 인증)·
      PC(세션 인증) **공용 SSOT**. 기존 `/gym/<id>/threads`·`/messages` 는 위임만
- [x] admin 3종 신설 (`api/admin.py` 파일 끝):
      `GET /api/v1/admin/gyms/<id>/message-threads` ·
      `GET .../messages?peer=&read=1` · `POST .../messages` (+`@require_csrf`)
- [x] PC 신원 환산 `_staff_device_hash()`: boss·manager = `gyms.owner_hash`,
      coach = 페어링된 `gym_managers.device_hash`
- [x] PC 페이지 `web/facing-admin/templates/messages.html` — 좌 대화목록(안읽음 배지)·
      우 타임라인·하단 회신(Ctrl+Enter). 카드 높이 고정(내부 스크롤)
- [x] 사이드바 "회원 쪽지" + **전 페이지 공통 안읽음 배지** (`_layout.html`)
- [x] **BLOCKER fix**: PC 가 `message.received` 를 듣고 있었으나 백엔드는 그 이름을
      한 번도 발행한 적 없음(사문) → `note.new` 로 교체 + payload 에
      `preview`·`sender_name` 동봉 (발행 3곳 전부)
- [x] SSE 를 DOM 이벤트 `facing:sse` 로 재방송 → 페이지 스크립트가 자기 화면 갱신
- [x] 실기 검증: 회원 폰 발송 → PC 토스트 "쪽지 — 김도윤: CHECK-0806…" 즉시,
      PC 회신 → 회원 타임라인 반영, 열람 시 읽음 처리, 대시보드에서도 배지 점등

### D. 자잘한 정리
- [x] 기록 제출 시트 한글화 (Mark Done·Submit & Attend·Time·Weight·Notes)
- [x] 알림함 제목 '공지'→'알림함', 재활 화면 '공지'→'재활 가이드', 종 tooltip 한글
- [x] 리더보드 기본 탭 Elite→**RXD** + 빈 탭이면 기록 있는 탭 자동 전환
- [x] 회원 목록 "(미입력)" 3행 → "이름 미입력 + 앱 가입 · {해시8}" (실제 앱 자가가입 회원)
- [x] PC 토스트 이모지 6개 → 기호 (📋🏁📢💬📄✍ → ≡ ⚑ ◆ ◇ ▤ ❖), `/favicon.ico` 404 해소
- [x] `member.self_signup` 토스트 누락 발견·추가 (발행↔수신 전수 대조 산물)

### E. 브리프 반영 (사용자 승인 후 §11 절차)
- [x] `docs/ARCHITECTURE_BRIEF.md`: §2 코치 클라이언트 '폰 주 + PC 보조' ·
      §10 **D28** · §13.1 경로 정정(`/api/v1/gym` **단수**, 문서는 복수 오기였음) ·
      §13.2 신규 3종 · §11.8 변경 등록 · §4 SSE 이벤트명 SSOT 명문화

## 진행중

없음. 착수한 항목 전부 완료 + 커밋 (working tree clean).

## 대기

- [ ] **폰 실기 확인** — PC 회신이 회원 폰 알림함에 보이는지 (API·PC 쪽은 검증 완료,
      에뮬레이터 쪽만 미확인). 에뮬레이터가 세션 중 종료됨 → 재기동 1~2분 필요
- [ ] **미페어링 코치 PC 쪽지** — 폰 페어링 없는 코치는 PC 에서 열람 불가(안내문 노출).
      `gym_managers` 에 staff 전용 식별 해시를 줄지 **사용자 결정 필요** (브리프 §11.8)
- [ ] FCM 푸시 — WOD·공지 게시 시 회원 폰 알림 (이전 세션 이월)
- [ ] 네이버 실 로그인 — `env.json` 키만 채우면 됨 (이전 세션 이월)
- [ ] 백엔드 `test_personas_e2e` 2건 실패 (로컬 dev DB 드리프트, 이전 세션 이월)

## 결정사항 / 주의

- **D28 (2026-08-06)**: 쪽지는 폰 + PC 양쪽. 데이터는 `gym_coach_notes` 1벌 그대로,
  조회 로직만 공용 함수로 추출. 스키마 변경 없음
- **SSE 이벤트명 규칙 (신규 명문화)**: 발행(`sse_publish` 호출부, 현재 35종) ↔
  수신(`_layout.html` `_eventToastMap` 키, 25종) **키 일치 의무**. 현재 사문 0건.
  토스트 없는 10종은 전부 PC 발 동작이라 의도적 무음
- **표 우선 원칙 (DESIGN-SSOT §7-A)**: 나열형 데이터는 `FkRowCard`+`FkListRow`.
  색은 면이 아니라 아이콘·우측 값 글자색으로만. 색 타일 그리드 금지
- ⚠ **포트 5060 유령 프로세스 함정**: 이전 세션 백엔드가 살아 있으면 Windows 에서
  같은 포트에 이중 바인딩되어 **새 코드와 옛 코드가 번갈아 응답**한다. 증상이
  "고쳤는데 안 고쳐짐"이면 `Get-CimInstance Win32_Process` 로 `app.py` PID 전수 확인
- ⚠ **facing 백엔드는 리로더 없음** — `api/*.py` 고치면 프로세스 재시작 필수
- ⚠ 배포 금지 규칙 유효: push·PaaS 배포·스토어 업로드 전부 사용자 명시 지시 전까지 금지

## 현재 환경

- 로컬 백엔드 5060 · PC 어드민 8081 **가동 중** (에뮬레이터는 종료됨)
- PC 로그인 = `boss_seongsu` / `1234` (FACING SEONGSU, gym_id=2)
- 앱 데모 계정 = 김도윤(`persona-member-kim-doyun-2026`) · 박지훈 코치
- 검증 스크립트 = 스크래치패드 `probe.py` (ann·send·coachbox·threads 서브커맨드)

## 다음 세션 권장 첫 프롬프트

`/resume`
