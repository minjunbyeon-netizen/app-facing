# HANDOFF - 2026-05-24 21:38

## 완료 (이번 세션)

### 핵심: PC↔폰 양방향 실시간 동기화 완성
- [x] **PC↔폰 1:1 매핑 전수조사** — 8 mismatch 모두 해소 (회원 신원·클래스 등록·코치 화면 이름)
- [x] **백엔드 신규 endpoint 2개** — `GET /api/v1/member/classes` (회원 폰: 자기 박스 클래스 + 본인 예약 상태) · `GET /api/v1/member/reservations` (본인 예약+waitlist)
- [x] **`/gyms/mine` 응답에 `member_id` + `member_profile` 13 필드 노출** — PC 사장이 GymMemberProfile 입력한 신원정보 폰 즉시 표시
- [x] **`/gyms/{id}/members` 응답에 GymMemberProfile join** — 코치가 폰에서 회원 실명·level·전화 표시 (device hash → 실명)
- [x] **백엔드 SSE 9 mutation 보강** — leave / decide_member / wod.posted / messages / wod_result / announcement / coach_feedback / member_request 신규·응답 (api/gym.py)
- [x] **폰 SSE 클라이언트** — `lib/core/sse_client.dart` 신설, dio stream + LineSplitter + exponential backoff 재연결 (1→64s) + listener 0명 disconnect
- [x] **GymState SSE 자동 reload** — 13 trigger 이벤트 listen + 1s debounce + loadMine()
- [x] **PC dashboard SSE 토스트 22 type 매핑** — `_layout.html` 의 기존 EventSource 인스턴스에 listener 만 추가 + tone(success/info/warn/danger)별 좌측 색 바
- [x] **클래스 detail 모달 + 클래스 취소 버튼** — `classes.html`. timezone 버그 동시 fix (isoDate 가 toISOString UTC 기준이라 KST 자정 전후 chip 사라지던 것)
- [x] **퍼포먼스 — proxy 2350ms → 330ms (7배)** — 진범: Windows IPv6 fallback. `BACKEND_URL` 을 `localhost` → `127.0.0.1`. 덤으로 N+1 fix, requests.Session pool 재사용, threaded=True 둘 다.
- [x] **owner SSE listen fix** — `api/profile.py` `/member/me/events` 가 owner (코치 박지훈) 박스 이벤트도 받게 (`Gym.owner_hash==h` 합집합 추가)
- [x] **사장 session 만료 자동 재로그인** — backend 401 → `/login?next=현재경로` 자동 redirect → 재로그인 → 원위치 복귀 (open redirect 방지 internal path 만 echo)
- [x] **member_detail.html prefix 404 버그 fix** — `/api/proxy/v1/admin/members/...` 가 proxy 자동 prefix 와 중복돼 `/api/v1/admin/v1/admin/...` 404 → `/api/proxy/members/...`
- [x] **Rule 1 — 매 작업 푸시 + 30분 idle 재발사** — CLAUDE.md 최상단 + memory + `.claude/settings.local.json` env.CC_IDLE_THRESHOLD=1800 동기화

### 검증·시연
- [x] APK 빌드 (178MB debug) + 에뮬 설치 + launch
- [x] 폰 logcat 으로 SSE 연결 + recv + reload trigger 추적 (debugPrint)
- [x] **end-to-end 실측**: PC POST 회원 등록 → 폰 SSE recv (1.1s) → debounce 1s → loadMine done (총 2.2s)
- [x] PC playwright 토스트 1초 내 표시 (회원 등록 + 22 type 다 매핑)
- [x] member_detail 회원권 발급 200 + membership_id=10
- [x] 8 어드민 페이지 + 13 fetch endpoint 모두 200 OK
- [x] session 만료 시뮬레이션 (backend SECRET_KEY 바꿔 재시작) → /login?next=/members 자동 redirect → 재로그인 → /members 복귀 시연

## 진행중

- [ ] **실기 Galaxy S22 APK 설치 대기** — 사용자 외출 중 무선 ADB 응답 X (192.168.1.101:5555 → 무응답). 집 도착 후 폰 IP:포트 받으면 즉시 connect + tcpip 5555 재진입 + APK 설치. 절차는 `~/.claude/projects/C--dev-apps-facing-app/memory/project-pending-phone-apk-install.md`

## 대기 (사용자 요청 + 후속 후보)

- [ ] **폰 화면 캡쳐로 reload 후 회원 list/카드 시각 갱신 확인** — 현재 logcat 으로 reload trigger 까지 검증. 실제 UI 갱신 시각 확인은 mobile-mcp 또는 scrcpy 캡쳐 필요.
- [ ] **다른 mutation end-to-end 시연** — membership.issued · wod.posted · class_cancelled 폰까지 도달 확인
- [ ] **PHASE5 §1.3 사장 폰 회원 list+상세 6탭** (1주 plan)
- [ ] **PHASE4 P0 잔여** — Toss 빌링키 자동결제·재시도·grace / 듀얼 포지셔닝 B2B2C
- [ ] **전자계약서 양방향 흐름** — 회원 폰 ↔ PC 어드민 (1주+)
- [ ] **W-prime 페이싱 정밀화** — services/facing@4469bb4 → cf06238 revert 됨. 6 파일 복원
- [ ] **debug 로깅 가드** — sse_client / GymState 의 `debugPrint` 가 verbose. release 자동 strip 이라 prod 영향 X지만 노이즈 거슬리면 kDebugMode 가드

## 결정사항 / 주의

- 사용자 명시 **배포 금지** (CLAUDE.md v1.16.1 최상위) — git push 절대 X. 로컬 commit 까지만. APK 도 에뮬·연결된 디바이스에 한정 설치만.
- 사용자 명시 **Rule 1** (2026-05-24 신설) — 매 응답 종료 시 PushNotification 발사 + 30분 무응답 시 idle-watcher 자동 재발사
- 사용자 명시 **오버나이트 모드** — 묻지 말고 자가 진행
- 백엔드 띄울 때 `python app.py` 단독 — SECRET_KEY 는 `C:/dev/.env` 의 fixed 값. 다른 값으로 띄우면 cookie 무효화 시뮬 가능
- **IPv6 fallback 함정** — facing-admin 의 `BACKEND_URL` 은 반드시 `127.0.0.1:5060` (localhost 쓰면 매 호출 ~2초 지연)
- 폰 SSE 가 `_subscribers[gym_id]` 채널을 공유 — 같은 박스의 다른 회원 이벤트도 받음. 회원별 분리 (보안 강화) 는 후속
- 폰 SSE 가 회원 (approved) + owner 둘 다 listen 가능하게 fix 완료

## 이번 세션 commit (로컬, push 안 함)

| repo | commit | 요약 |
|---|---|---|
| services/facing | 9b2dc09 | feat(sync): PC↔폰 회원 신원·클래스 1:1 동기화 채널 |
| services/facing | 1510511 | feat(sync): 폰→PC SSE 9 mutation 보강 |
| services/facing | fe33ce1 | fix(sse): owner SSE listen |
| services/facing | 36d0185 | perf(admin): N+1 fix + threaded=True |
| web/facing-admin | ea4058f | fix(proxy): member_detail prefix 404 |
| web/facing-admin | e0ce604 | feat(realtime): SSE 22 토스트 + 클래스 detail 모달 |
| web/facing-admin | 604bfee | perf(proxy): 2350ms → 330ms IPv6 fix |
| web/facing-admin | eb6a967 | feat(auth): 자동 /login redirect + 원위치 복귀 |
| apps/facing-app | 99b34db | feat(sync): GYM RECORD 카드 + Classes 화면 |
| apps/facing-app | bdba4ad | chore(rule): Rule 1 push |
| apps/facing-app | 355e6a7 | feat(realtime): 폰 SSE 클라이언트 |
| apps/facing-app | 978c0d5 | feat(sse): debug 로깅 + end-to-end 검증 |

## 외부 자료 / 참고

- ARCHITECTURE_BRIEF SSOT: `docs/ARCHITECTURE_BRIEF.md`
- 폰 좌표 메모리: `~/.claude/projects/C--dev/memory/reference_test_device_phone.md`
- 집 도착 시 APK 설치 절차: `~/.claude/projects/C--dev-apps-facing-app/memory/project-pending-phone-apk-install.md`
- 디자인 시스템: CLAUDE.md §디자인 시스템 v1.15.0
- linko 격차 분석: `docs/competitor/linko*.md`

## 다음 세션 권장 첫 프롬프트

`/resume`

그리고 (a) 실기 폰 IP:포트 알려주기 → 즉시 APK 설치 + 페르소나 스위처 검증, 또는 (b) `폰 화면 캡쳐로 reload 시각 갱신 확인` 이어가기.
