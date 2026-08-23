# HANDOFF - 2026-08-23 22:03

## 완료 (이 세션)
- [x] **보드 기록 배지 즉시 갱신 수정 (v3.17)** — 지난 세션 진행중 항목 종결
  - `lib/features/gym/wod_row.dart` `_openResultSheet` — 시트 pop(true) 를 await 로 받아
    저장 성공 시 `GymState.loadMine()` 재조회. week_board 카드 배지·wod_row 배지 둘 다
    GymState 원천이라 한 곳 배선으로 양쪽 갱신
  - 테스트 186건 통과·골든 변화 없음 (동작 변경만)
- [x] **에뮬 실물 왕복 검증** — 새로고침 없이 배지 즉시 갱신 확인
  - 첫 저장: "완료 표시"(빨강) → 즉시 "기록 10R"(초록) + 스낵바 (저장됨·출석+1·+100P)
  - 덮어쓰기(버그 원 시나리오): 재열기 프리필(10)+덮어쓰기 안내 → 9 재저장 → 즉시 "기록 9R"
  - 쓰기는 전부 로컬 demo(gym 1) — 프로드(gym 2) 접근 없음
- [x] **push + 배포 집행 (사용자 승인)** — 앱 7커밋·서버 3커밋 push, 서버 `railway up` 성공
  - Railway 헬스체크 [1/1] 통과 + 프로드 `/health`·`/api/v1/health` healthy 확인
- [x] **릴리즈 APK 빌드** — `build/app/outputs/flutter-apk/app-release.apk` (64.5MB)
  - 프로드 URL 주입 완료 (`--dart-define=API_BASE_URL=https://service-facing-production.up.railway.app`)

## 진행중 (다음 세션 첫 작업)
- [ ] **릴리즈 APK 실기기(갤S22) 설치** — 중단 지점 = 폰 무선 디버깅 연결 실패(NEEDADDR)
  - 연결 스크립트(기존 주소·mDNS) 전부 실패 — 폰 쪽 무선 디버깅 꺼짐/포트 풀림
  - 사용자에게 IP:포트 한 줄 요청해 둔 상태 (설정 > 개발자 옵션 > 무선 디버깅)
  - 받으면: `/연결 <IP:포트>` → `adb -s <addr> install -r build/app/outputs/flutter-apk/app-release.apk`
    → 실행해 로그인·수업 탭 배지 동작 확인. INSUFFICIENT_STORAGE 나면 uninstall 후 install
    (applicationId `com.netizen.hyphen.hyphen_app`, 재로그인 필요)

## 대기
- [ ] (선택) 오늘 에뮬 검증이 남긴 demo 기록 정리 — gym 1, member 계정, 8/23 EMOM 9R

## 결정사항 / 주의
- 배포는 이번 세션 사용자 명시 승인("1")으로 집행됨 — push·railway up 모두 완료 상태
- `railway up` 은 반드시 `C:/dev/services/facing` 폴더에서 (앱 폴더 cwd 는 No linked project)
- `railway up` 이 자동모드 권한 분류기에 차단될 수 있음 — 사용자 `!` 직접 실행 or 허용 등록
- 에뮬 `install -r` INSUFFICIENT_STORAGE 재현 시 uninstall 후 install (member/1234 재로그인)
- 에뮬 현 상태: debug 빌드(로컬 10.0.2.2:5060) + member/1234 로그인 + 8/23 EMOM 9R 기록
- 로컬 백엔드(:5060) 이 세션에서도 계속 실행 중 — 새 세션에선 재기동 필요할 수 있음
- ESC(keyevent 111)는 Flutter 바텀시트를 닫음 — 키보드 닫기는 keyevent 4(BACK)
- 실 체육관(gym_id=2) 프로드 오염 금지 — 쓰기는 로컬 demo(gym 1)만

## 다음 세션 권장 첫 프롬프트
`/resume` → 폰 무선 디버깅 IP:포트 확보 후 릴리즈 APK 실기기 설치부터
