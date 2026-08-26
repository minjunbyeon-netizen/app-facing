# HANDOFF - 2026-08-26 22:35

## 완료 (이 세션 — 20:48~22:35, 3면 전부 커밋·푸시, PC 웹 배포 완료)
- [x] 인계장 반영 · 갤S22 릴리즈(20:16 빌드) 설치 → 실기기 검증 뒤 **프로드 APK 재설치 완료** (`lastUpdateTime 22:27:15`, 로그아웃 상태 — 사용자 재로그인 필요).
- [x] **코치 PC 회원권 액션 5종 코치(COACH/1234) 실주행 전부 통과**: 발급·정지/정지 해제·연장(=다음 권 이어붙이기, `+ 회원권 연장` 모달 → 결제 이력 동시 기록)·수정·해지.
  서버 5 라우트 전부 `@require_staff` (`roles.STAFF_ROLES=(boss,manager,coach)`), PC 템플릿에 역할 분기 없음. 캡처 `C:\dev\project\hyphen-journey-2026-08-26\pause\00~11`.
  정지 → 폰 예약 즉시 소멸(D58) · 만료일 +2일 → 해제 시 쉰 일수 0 이라 원복 확인.
- [x] **사용자 결정 "정지하면 열람 가능, 만료 회원은 열람 불가"** — 코드 이미 일치(`services/hyphen/api/gym.py` WOD 목록 locked = `status=active AND end_date>=오늘`, 정지는 active 유지). 코드 변경 0.
  기록 = 브리프 §10 D58 블록 항목 · GLOSSARY 변경 이력 · 메모리 `project-booking-window-revoke` (앱 repo 커밋 완료).
- [x] **PC 정지 해제 뒤 헤더 '일시정지' 잔상 수정** — `web/facing-admin/templates/member_detail.html resumePause`: `_membersListPromise=null; loadHeader();` (회원 목록 페이지 캐시 F8 때문). 코치 실클릭 검증(일시정지→활성 즉시) · 커밋·푸시 · `railway up` 22:07 부팅 200.
- [x] **갤S22 실기기 D57·D58 재확인** — 프로드 쓰기 금지라 **LAN 디버그 빌드**(`--dart-define=API_BASE_URL=http://192.168.1.100:5060`, 폰 wlan 192.168.1.101 → PC 5060 도달 확인) 설치 후 member3 로:
  3회권 "3회 남음·30일 후 만료·면제 1회씩" → 23:00 예약 → "1회 사용·2회 남음" → 금 28 '오픈 전' 탭 → "예약은 8/27 11:00 부터 가능합니다." → 코치 해지 → 예약 13 소멸·환불 9,900·보드 '회원권 필요'(SSE). 캡처 `project/.../phone/00~15`.
- [x] `C:\dev\project` 캡처 repo 정리: phone 16장 + 지난 세션 미커밋 membership 68장 커밋·푸시. APK 백업본 삭제.

## 진행중
- [ ] 없음 (옵션 1 "폰 코치 셸 세션 만료 시 로그인 화면 자동 이동" 은 컨텍스트 99% 로 **시작 전** 멈춤 — 아래 대기 1번).

## 대기
- [ ] **폰 코치 셸 세션 만료 처리** (사용자 옵션 1 선택 22:33 — 다음 세션 첫 작업): 코치 셸(예약 현황·쪽지)에서 서버 세션이 만료되면 "로그인이 필요합니다 / 다시 시도" 에러 상태만 뜨고 로그인 화면으로 안 감. 로그아웃 아이콘(우상단)을 눌러야 진입 화면. 401 수신 시 세션 정리 + 진입 화면으로 보내는 처리 필요 — 시작점 = 코치 셸 화면의 에러 상태 렌더(HkErrorState '로그인이 필요합니다') 와 `lib/core/api_client.dart` 401 인터셉터. 골든 추가 의무.
- [ ] 지난 수업에 확정 예약이 남으면(코치가 명단 안 찍음) 배지가 '종료' 아닌 '예약됨' 잔상 (보고만 — 사용자 지시 없음).
- [ ] 폰 회원권 카드는 오늘을 덮는 권 하나만 표시(8/24 결정) — 다음 권(9/25 시작)이 예약돼 있어도 "N일 남음" 만 보임. "다음 권 예약됨" 한 줄 붙일지 사용자 결정.
- [ ] 프로드 gym 2 에 "이벤트 3회권 · 30일 · 3회 · 9,900원" 요금제 등록 (지시 없음 — 사용자 결정). 실데이터 오염 금지.
- [ ] **자동 노쇼 = 추후** (20:28 결정) — 먼저 제안하지 말 것.

## 보고만 (지시 없음, 수정 안 함)
- PC 발급 모달: 종류 선택 뒤 시작일 변경 시 종료일 미재계산 (D57 이전부터).
- Playwright 일반 클릭이 PC 링크에 간헐적으로 안 먹음 → JS 클릭(`el.click()`·`form.requestSubmit()`·`#faConfirmOk`)으로 진행. 스크린샷 저장은 `.playwright-mcp/` 만 허용 → 복사.
- 로컬 잔여물: 수업 60(오늘 23:00 '코치 정지 소멸 테스트')·59·57·58 · member3 회원권 3~8 전부 해지 · 로컬 서버(5060)·PC 웹(8081, 22:06 재시작) 켜 둠 · 에뮬(member3 로그인) 켜 둠.

## 에뮬·실기기 재주행 절차 (검증된 순서 — 8/26 22:27 실측)
1. `services/hyphen`: `PORT=5060 python app.py > _run.out 2> _run.err &` · PC 웹 `web/facing-admin`: `python app.py &`(8081, **템플릿 수정 시 재시작** — `netstat -ano | grep :8081` → `taskkill //PID … //F`). pytest `python -m pytest tests/`.
2. 로컬 DB: gym 1 · member/1234(기간제) · member2/1234(기간제 8/27~9/25) · member3/1234(승인, 회원권 전부 해지) · member4 대기 · admin/1234(boss) · COACH/1234(coach). 요금제 `gym_plan` 표(회원권 설정 페이지) — 이벤트 3회권(session 3·9,900)·성인 1개월권(150,000)·검증0819 3개월권.
3. PC playwright 좌표: 로그인 `#lid #lpw` + `form.requestSubmit()` · 정지 모달 `#pauseStart #pauseEnd #pauseReason` + '정지 등록' 버튼 · 해제 = '정지 해제' 링크 → `#faConfirmOk` · 발급/연장 = `openExtend()` → `#msPlanSelect`(change 이벤트) → `#membershipModal form`.requestSubmit() · 해지 API body `{membership_id, cancel_type:'immediate'}` · 수업 생성 `POST /api/proxy/gyms/1/classes {start_at:'…+09:00', title}`.
4. 에뮬(1080×2400) 좌표: 내 정보 (900,2256) · 회원권 아코디언 (540,490) · 수업 탭 (540,2256) · 보드 `swipe 540 1900 540 600` 뒤 23:00 행 예약 (959,1717).
5. **갤S22(1080×2340)**: serial `adb-R5CT503NB5M-r4Y2MU._adb-tls-connect._tcp` (mDNS, `adb devices` 에 잡힘). 앱 실행 `am start -n com.netizen.hyphen.hyphen_app/.MainActivity` (monkey 는 안 뜸). 알림 허용 (539,1956) · 진입 로그인 (539,769) · 아이디 (539,666)·비번 (539,870)·로그인 (539,1217) · 내 정보 탭 (898,2174)·수업 탭 (539,2174) · 회원권 아코디언 (539,480) · 보드 스크롤 뒤 23:00 예약 (958,1233) · 금 28 행 (539,1510) → 배지 (937,1177) · 우상단 로그아웃 (993,149) → 확인 (778,1296).
   LAN 빌드는 `flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.100:5060` → 서명 달라 `adb uninstall` 뒤 설치. 끝나면 **반드시 프로드 릴리즈로 복구** (`build/app/outputs/flutter-apk/app-release.apk` = 20:16 프로드 빌드 그대로).
6. 빌드는 단독으로 (analyze/test 와 동시 실행 시 gradle 실패).

## 결정사항 / 주의
- D57 차감 규칙·D58 원문·정지 열람 허용 = 메모리 `project-session-pass-rule`·`project-booking-window-revoke`. 규칙 변경은 사용자 결정.
- 정지 = 열람 O·예약 X / 만료·해지 = 열람 X. 정지 전용 잠금 분기 신설 금지.
- 프로드 접촉: /health · railway logs · `railway up` 만. gym 2 실데이터 오염 금지 — 실기기 회원 흐름은 LAN 빌드+로컬 DB 로.
- 제1원칙(기능 추가 금지·갭은 보고만) 유지 — 대기 항목은 사용자 지시 있을 때만.

## 다음 세션 권장 첫 프롬프트
`/resume` → 대기 1번(폰 코치 셸 세션 만료 → 로그인 화면 자동 이동) 바로 착수.
