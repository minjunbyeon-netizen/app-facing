# HANDOFF - 2026-08-27 02:01

## 완료 (이 세션 — 22:41~23:10, 3 repo 커밋·푸시, Railway 백엔드·PC 웹 배포 LIVE)
- [x] **D59 폰 코치 셸 세션 만료 → 로그인 화면 자동 이동** (인계장 대기 1번).
  `BossApiClient._checkSession`(401 UNAUTHORIZED → `BossAuthState.expire()`) · `CoachShell` 리스너(`_leaving` 빗장, S1 뒷정리 뒤 `/signup` 위 `/login` + `LoginScreen.argNotice`) · 로그인 화면 "로그인이 만료되었습니다. 다시 로그인해 주세요." 1회 표시.
  골든 `state_16_coach_session_expired` 신규(61장, 하네스 `routes` 주입구 · `FakeBossApi.unauthorizedPaths` · `FakeBossAuth.loggedIn` 가변). `flutter test` 201 통과. 브리프 §10 D59.
- [x] **D60 PC 웹 개편 6건 + 알림 = 앱 쪽지 하나** (사용자 지시 22:41, 작업자 4명 병렬 → 통합 검증).
  - 백엔드 `services/hyphen`: `api/notifications/note.py` 신설(`NOTE_TEMPLATES`·`send_member_note`·`describe_templates`·`SEND_HOUR=15`). 발송 4지점(해지 admin.py·수업 취소 classes.py·결제 payments_admin.py·만료 expiry_scheduler) 통일. 만료 안내 = 매일 15:00 KST 잡 `daily_expiry_notify_15`(AuditLog note.auto 멱등), 03:30 은 상태 전환만. `notification-settings` 응답에 `send_hour`·`templates[]`, quiet_* 폐기. `alimtalk-logs` → `notification-logs`. kakao.py·webhooks/kakao.py → `_archive/dead-2026-08-26/`. pytest **270 passed**. docs/SSOT 11개 갱신.
  - PC 웹 `web/facing-admin`: 사이드바 '공지 · 일정' 하나(`/announcements` = 월 달력 막대 + 공지 표 + 모달, `/calendar` 302) · '처음 시작하기' 링크 삭제(라우트 존치) · 푸터 로그아웃만 · 케어 필요 표 2개(`tr.is-urgent td:first-child` inset rail) · 수업 안내 시간표 = 요일 스트립 + 시각, 편집은 수정 모달 안(규칙 diff POST/PATCH/DELETE) · 수업 관리 시간 축 = 수업 앞 1시간~끝 시각, 2시간+ 빈 구간 접힌 행(1시간 구멍은 표시) · 알림 설정 = 서버 templates 로 실제 문구 노출, 야간 카드 삭제, 발송 시각 오후 3시 · member_detail 막대 인라인 → `data-w`(lint 8→7 baseline 갱신) · `.nav-onboarding` 규칙 제거 · onboarding/gallery 알림톡 문구 정정.
  - 회귀 검증 1회(playwright, COACH/1234, 8081): 사이드바/공지·일정(달력 6주·막대 3·표 2행·막대→모달)/케어/수업 안내+수정 모달/수업 관리/알림 설정(토글 왕복 OK)/`/calendar` 리다이렉트. 콘솔 에러 0. 캡처 `apps/facing-app/.playwright-mcp/pc-01~07*.png`(gitignore).
  - 브리프 §10 D60(알림톡 옛 언급 3곳 폐기 표기) · 메모리 `project-notifications-app-note`.
- [x] 프로드 검증: 백엔드 `/health` 200 · `notification-logs` 401(새 라우트) · PC 웹 `/calendar` → `/announcements` 302.

## 진행중
- [ ] 없음.

## 대기
- [ ] **D59 프로드 APK 갤S22 설치** — `build/app/outputs/flutter-apk/app-release.apk`(22:58 빌드, prod URL 주입) 준비됨. 갤S22 무선 디버깅 포트가 풀려 `adb` 미도달(`phone_connect.ps1` NEEDADDR). 사용자가 `IP:포트` 주면 `/연결 <주소>` → `adb -s <addr> install -r …`. 현재 폰엔 22:27 프로드(D59 이전) 설치 상태.
- [ ] **알림 발송 시각 재결정** — "뭐든지 오후 3시" 를 만료 배치에만 적용(결제·수업 취소·해지는 즉시, Claude 판단·브리프 D60 명시). 전부 3시로 바꾸려면 `note.py` 한 곳 + 큐잉 설계 필요.
- [ ] 수업 안내 수정 모달: 템플릿 저장 후 규칙 호출 일부 실패 시 템플릿만 남고 토스트만(재시도 없음) — 보고만.
- [ ] 자동 쪽지는 회원 프로필 없으면 "회원님" 표기 — 보고만.
- [ ] 프로드(gym 2) 화면에서 수업 관리 접힌 행·공지 달력 1회 눈 검증 권장 (로컬은 매시간 수업이라 접힌 행이 안 생김).
- [ ] (지난 인계 잔여) 지난 수업 확정 예약 '예약됨' 잔상 · 폰 회원권 카드 다음 권 예약 표시 · 프로드 gym 2 이벤트 3회권 등록 · 자동 노쇼 추후 · PC 발급 모달 시작일 변경 시 종료일 미재계산 — 전부 사용자 지시 없음.

## 결정사항 / 주의
- 알림 채널 = 회원 앱 쪽지 하나 (카카오·NHN·SMS 제안 금지). 문구 SSOT = 백엔드 `NOTE_TEMPLATES`, PC 하드코딩 금지. `sms.py`·`email.py` 는 미참조 잔존(보고만).
- 코치 로그아웃·세션 만료 모두 `DeviceIdService.reset()`(S1) 후 진입 화면 — 회원 API(X-Device-Id)엔 세션 없음.
- PC 웹 페이지 전용 CSS 는 템플릿 `<style>` 10블록 래칫 유지(lint style_blocks 10). 인라인 style baseline 7.
- 로컬 잔여물: 백엔드 5060(23:05 재시작)·PC 웹 8081(23:08 재시작) 켜 둠 · 에뮬 켜 둠 · 수업 60·59·57·58 등 테스트 데이터 그대로.
- 프로드 접촉은 /health·railway logs·`railway up` 만. gym 2 실데이터 오염 금지.

## 에뮬·실기기 재주행 절차
- 지난 인계장(`docs/archive/HANDOFF-2026-08-26-2235.md` §에뮬·실기기 재주행 절차) 그대로 유효. PC playwright 는 세션 쿠키가 호스트 종속이라 **127.0.0.1:8081 로만** 접속(localhost 섞으면 로그인 풀림). 스크린샷은 `filename` 에 `.playwright-mcp/` 절대경로를 줘야 repo 루트에 안 떨어짐.

## 다음 세션 권장 첫 프롬프트
`/resume` → 폰 무선 디버깅 주소 받아 D59 APK 설치, 또는 대기 2번(알림 시각) 사용자 결정.
