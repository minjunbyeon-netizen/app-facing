# HANDOFF - 2026-05-26 14:32

> /resume 후 이어받은 세션. PHASE5 6 카테고리 100% + 검증 5회 통과 + 인계.

## 완료 (이번 세션, 13:10 ~ 14:32)

### Phase 4-3 — 회원권 발급 모달 plan dropdown
- [x] admin `member_detail.html` 회원권 발급 모달 종류 select 를 `/api/v1/admin/gyms/<gid>/plans` 마스터 fetch 로 교체
- [x] plan 선택 시 `data-price`/`data-days` 로 가격·종료일 자동 채움 (시작일 + duration_days)
- [x] plan 미설정 박스 fallback (옛 6 옵션) 유지

### TASK A-4·5·6 — 버튼 토큰 SSOT
- [x] 글로벌 `static/style.css` 에 `.btn-ghost`·`.btn-danger`·`.btn-primary` (`.btn` alias)·`.btn-sm`·`.btn-danger-outline` 추가
- [x] `member_detail.html` 7 곳 inline `style="..."` 제거 → 토큰 클래스만
- [x] `classes.html` 의 로컬 `.btn-ghost`/`.btn-danger` 중복 정의 제거 → 글로벌 SSOT
- [x] `onboarding.html`·`payroll.html`·`dashboard.html` 3 페이지 inline style 정리
- [x] **잠재 버그 fix**: classes.html 의 `.btn-primary` 가 어디에도 정의 안 돼 있던 거 → 글로벌 alias 추가로 5 곳 살아남
- [x] 잔존 inline 3 군데 (_layout SSE 재연결·members 업로드 label·stats 시작) 는 다음 사이클 후보로 표 기록

### Phase 3-4·3-5 락카 자동 연장 검증
- [x] backend 3 hook 동작 확인 (`admin_assign_locker`·`admin_extend_membership`·신규 issue locker bump)
- [x] DB drift 7건 발견 (옛 시드가 hook 도입 전에 깔린 흔적) → backfill 후 drift = 0
- [x] `tests/test_locker_membership_sync.py` 4 tests all pass — 회귀 방지

### Phase 6-3 공지사항 자동 푸시 wiring
- [x] `GymNotificationSettings` settings JSON 에 `announcement` key (default true) 추가
- [x] `notification_settings.py` `_ALLOWED_KEYS` 에 announcement 포함 (PATCH endpoint 토글 수락)
- [x] `admin_post_announcement` 에 fan-out 로직 — `enabled && announcement` on 일 때 `approved` 회원 device_hash 모두에게 `send_push(title, body, data={"type":"announcement","id":N})`
- [x] `tests/test_announcement_push.py` 4 tests all pass
- [x] live 검증 — 공지 ann=10 발행 시 `[FCM stub] no token` 18 줄 + `[announcement.push] gym=2 ann=10 sent=0/18` 요약 한 줄 로그 확인

### class-templates fetch 일시 실패 자동 재시도
- [x] `_fetchWithRetry(url, opts)` 헬퍼 — 첫 실패 시 250ms 후 1회 더 시도. SSE+threaded Flask 일시 stall 패턴 우회

### Flutter analyze 0
- [x] `self_signup_screen.dart` 2 info 정리 — HTML doc `<gid>` backtick 감싸기, `(_, _)` Dart 3 wildcard

### 검증 5 회 사이클 (마지막)
- [x] 1 admin 6 페이지 console 0 (dashboard·members·classes·calendar·contracts·announcements)
- [x] 2 backend `/health` 200 + pytest 8 (locker 4 + announcement 4) all pass
- [x] 3 Phase 4-3 plan dropdown 가격 330000 + 종료일 2026-08-24 자동 재현
- [x] 4 Phase 6-3 push fan-out 공지 ann=10 stub 로그 18 + summary 1 확인
- [x] 5 flutter analyze `No issues found!`

### 진행 doc 동기화
- [x] `docs/PHASE5_PLAN.md` Phase 1·2·3·4·5·6 모든 항목 [x] 갱신 + commit 해시 명시
- [x] `docs/PHASE5_FOLLOW.md` TASK A-4·5·6 완료 + 버튼 SSOT 표 추가

## 진행중
(없음 — 사용자 명시 `/handoff` 트리거)

## 대기 (다음 세션 후보)
- [ ] **Phase 0-1 APK 실기 install** — 메모리 `project-pending-phone-apk-install` 트리거 (집 도착 후)
- [ ] `_layout.html:140` SSE 재연결 새로고침 버튼 inline style 정리 (마이너)
- [ ] `members.html:12` 파일 업로드 label inline style 정리 (마이너)
- [ ] `stats.html:34` 처음 시작하기 a 링크 inline style 정리 (마이너)
- [ ] `settings/notifications` 페이지에 announcement 토글 UI 추가 (현재 백엔드만, UI 없음)
- [ ] 회원 폰에서 `/api/v1/devices/fcm-token` 호출하는 register 흐름 확인 (Phase 6-3 sent=0/18 의 원인)
- [ ] `FIREBASE_CREDENTIALS` 등록 후 stub → live 모드 전환 시 실 발사 e2e

## 결정사항 / 주의
- **배포 금지** 룰 유지 — git push·Railway·gh PR 일체 X. commit 만 누적
- **검증 시드 잔재**: gym 2 에 `Calendar Flow Verify` 클래스 (id=28), `Push wiring test` (id=8), `Push wiring re-verify` (id=9), `Verify round 4 push fan-out` (id=10) 4 건 남아있음 — 운영 데이터 아니므로 다음 cleanup 사이클에 삭제 가능
- **DB drift**: 락카 7건 backfill 완료. tests/test_locker_membership_sync.py 가 회귀 잡음. 다음 시드/마이그레이션이 깨면 pytest 가 잡아줌
- **8081 admin 서버 좀비 PID 4건**: 실제 listener 는 1개, 나머지는 Windows TCP table 잔재. taskkill 안 됨 — 정상 서비스 중. 새 인스턴스 띄울 일 있으면 Get-NetTCPConnection 으로 alive PID 만 kill
- **백엔드 reload 안정성**: Flask debug=True 인데 자동 reload 가 가끔 안 됨. 코드 변경 후 검증 안 보이면 `Stop-Process -Id <5060PID>` → `python app.py` 수동 재시작
- **세션 commit 분포**: facing-app 4개, facing-admin 3개, services/facing 2개 — 3 레포 모두 동기화 상태
- **3 레포 모두 `overnight/2026-05-25` 브랜치** — 다음 세션도 같은 브랜치 이어가거나 master 머지 결정 필요

## 다음 세션 권장 첫 프롬프트
`/resume`
