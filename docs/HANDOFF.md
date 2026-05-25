# HANDOFF - 2026-05-25 22:57

> 어제 21:38 → 오늘 19:28 까지 v1.17 로컬 푸시 알림 인프라 완성 → 22:57 PHASE5 6 Phase 분해 plan 작성. 알림 실 시연 보류, 다음 세션에서 Phase 1 시작 권장.

## 완료 (오늘 19:28 → 22:57)

- [x] **SignupScreen 에 "Box Owner Login" 진입로 추가** — 카카오 버튼 아래 OutlinedButton. `/boss/login` push. 이게 BossAuthState.save() → main.dart listener → staffPush.start() 도미노 첫 단추.
- [x] **BossApiClient.login() 에 X-Device-Id 헤더 추가** — DeviceIdService.get() 으로 폰 device_id 가져와서 헤더에 동봉. 백엔드가 device_hash 자동 등록하도록.
- [x] **백엔드 admin_login 에 device_hash 자동 등록** — 폰에서 ID/PW 로그인 시 X-Device-Id 헤더로 GymManager.device_hash 자동 갱신. 페어링 코드 단계 우회. multi-gym fanout 위해 active 행 전부 갱신. audit log 에 device_hash 앞 8자 prefix.
- [x] **APK release 2회 빌드 + 폰 설치** — 1차는 default `10.0.2.2:5060` 박혀서 실기 폰에서 백엔드 OFF, 2차 `--dart-define=API_BASE_URL=http://192.168.1.100:5060` 으로 LAN IP 박아서 재빌드. v0.1.17+3000 폰 설치 완료.
- [x] **폰 듀얼 앱(user 95) facing 삭제** — 옛 시연 잔존물 정리.
- [x] **PHASE5 plan 6 Phase 분해** — `docs/PHASE5_PLAN.md` 작성. 의존성 순서로 묶음. Phase 1 (설정 마스터) → 2 (회원 화면) → 3 (운영자 도구) → 4 (자동화) → 5 (수업·커뮤니티) → 6 (홈 대시보드).

## 진행 중 / 직전 보류

- [ ] **v1.17 알림 실 시연 (5~15분 작업)** — APK install·백엔드 활성·logcat 모니터링 까지 다 끝났고 폰에서 `boss_seongsu` / `1234` 로그인 → 가짜 가입 신청 트리거 → 알림바 캡쳐만 남음. 사용자 손이 한 번 필요. Phase 1 시작 전 또는 도중 끼워서 처리 가능.

## 대기 — PHASE5 (큰 작업, 다음 세션 본격 시작)

상세는 `docs/PHASE5_PLAN.md` 참조. 6 Phase 분해 + Sprint 예상치.

- [ ] **Phase 1 — 설정 시스템 기반 (Sprint 1, 1주)** — 회원권/포인트/알림 마스터. 모든 phase 의존.
- [ ] **Phase 2 — 회원 화면 핵심 (Sprint 2, 1주)** — D-7 강조·이전 회원권·수강이력·포인트·메모·기간정지.
- [ ] **Phase 3 — 운영자 도구 (Sprint 3, 1.5주)** — 시급정산 4대보험·이탈관리·락카 자동완성.
- [ ] **Phase 4 — 자동화 흐름 (Sprint 4, 1.5주)** — 자동 가입·자동 계약서·자동 금액.
- [ ] **Phase 5 — 수업·커뮤니티 (Sprint 5, 1주)** — 메뉴 rename·리더보드 분리·공지·달력·클래스 수정.
- [ ] **Phase 6 — 홈 대시보드 + 청소 (Sprint 6, 3~5일)** — 매출/예약 위젯·옛 페이지 삭제.

## 대기 — 누적 옛 작업 (PHASE5 보다 우선순위 낮음)

- [ ] 백엔드 admin override 시드 endpoint (gym profile PATCH·WOD POST device-hash 인증 우회용)
- [ ] 코치 프로필 시드 (gym_coach_profiles) — admin API 노출
- [ ] services/facing untracked 3건 정리 — `.err.log`, `.run.log`, `data/contracts/contract_*.html` 를 `.gitignore` 추가
- [ ] PHASE4 P0 잔여 — Toss 빌링키 자동결제·재시도·grace
- [ ] v1.18 Foreground Service — 앱 종료 후에도 알림 (flutter_foreground_task TaskHandler 통합)

## 결정사항 / 주의

### PHASE5 분해 원칙
- 의존성 순서. 회원권 설정 마스터 없으면 Phase 4-3 자동 금액 매핑 불가, 포인트 설정 없으면 Phase 2-4 포인트 표시 불가.
- "오늘 처리할 일" 페이지는 사용자 미사용 명시 → Phase 6 에서 삭제.

### v1.17 알림 인프라 검증
- 백엔드 staff SSE endpoint 살아있음 (curl 검증)
- 폰 OS 알림 채널 등록 정상 (dumpsys notification | grep facing → facing_staff HIGH + facing_member DEFAULT)
- 폰 device_hash 자동 등록 코드 작성 완료 (admin_login)
- LAN IP 박힌 APK 폰 설치 완료
- **남은 단 1단계** = 사장 로그인 1회 → BossAuthState 활성 → staffPush.start() → SSE 200

### 백엔드 detach 패턴 (Windows)
- PowerShell run_in_background 또는 Start-Process -WindowStyle Hidden 은 PowerShell session 종료 시 child 도 같이 죽음
- 진짜 detach: `Start-Process cmd.exe -ArgumentList '/k','...' -WindowStyle Minimized` — 별도 cmd 창 (최소화) 띄움. 사용자 직접 닫지 않으면 살아있음
- 작업 표시줄에 까만 cmd 창 = 백엔드. 닫지 말 것.

### 폰 환경
- 무선 디버깅 페어링 변동성 — 매 세션 새 페어링 IP:포트 + 6자리 코드 필요. 가능하면 USB 케이블 (단, USB 모드 "파일 전송" + 데이터 통신 가능 케이블 필수)
- 메인 무선 디버깅: `192.168.1.102:41527` (이번 세션 기준)
- 폰 device 사용자: user 0 (메인 MJ EHTAN). user 95 (DUAL_APP) 의 facing 은 삭제 완료

### Git 상태
- `services/facing` master: admin_login device_hash 자동 등록 추가 (commit 안 함, 배포 금지 룰)
- `apps/facing-app` master: signup·boss_api_client 변경 + PHASE5_PLAN.md 신설 + HANDOFF 갱신 (auto-save hook 처리)
- 둘 다 push 안 함. 사용자 "배포해" 명령 시 push

## 다음 세션 권장 첫 프롬프트

`/resume`

그 후 우선순위:
- (a) **알림 실 시연** — Phase 0-1, 15분 컷
- (b) **Phase 1 시작** — 회원권 마스터 설정 DB·API·UI (1주 sprint, 본 세션엔 plan 만 확인하고 다음 세션에 본격 착수)

## 외부 자료 / URL

- PHASE5 plan: `apps/facing-app/docs/PHASE5_PLAN.md`
- 백엔드 staff SSE: `services/facing/api/admin.py:960` (staff_events_stream)
- 백엔드 admin_login: `services/facing/api/admin.py:442` (device_hash 자동 등록 v1.17)
- Flutter SignupScreen: `apps/facing-app/lib/features/auth/signup_screen.dart`
- Flutter BossApiClient: `apps/facing-app/lib/features/boss/boss_api_client.dart`
- Flutter staff SSE 클라: `apps/facing-app/lib/core/staff_push_service.dart`
- 페이싱 외부 자료 SSOT: `services/facing/docs/refer/{카테고리}/findings.md` (10 카테고리)
