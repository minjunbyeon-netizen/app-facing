# HANDOFF - 2026-06-11 17:13

## 완료 (이번 세션)
- [x] **keystore 외부 백업** — `C:\Users\USER\Documents\facing-keystore-backup\` (keystore + key.properties + zip). 클라우드 2차 보관은 사용자 수동 권장
- [x] **백엔드+admin 프로덕션 배포 완료** (사용자 승인 "2") — runbook §0 대로 `BASE_URL` + `CORS_ORIGINS`(admin 도메인 한정) Railway 등록 후 `railway up`. admin 웹은 오늘 자 변경(카카오 옐로·로그인 리디자인) 라이브 확인
- [x] **P0 사고 1 — 첫 배포 부팅 사망 → 픽스·복구**: Railway `APP_TEST_ADMIN_ID` 가 'admin' 이라 데모 계정과 이중 INSERT → UNIQUE 충돌 → 워커 부팅 실패 + 구 컨테이너까지 내려가 prod 일시 502. 조치: `models/base.py:seed_gym_managers` 중복 가드(su_id=='admin' 제외 + _seen dedupe) + Railway env 를 글로벌 표준(cheb2oy)으로 교정. health 정상(managers 5)·데모/슈퍼씨드 로그인 200 검증
- [x] **P1 사고 2 — 로그인 레이트리밋 prod 무력화 → 픽스**: Railway 엣지가 요청마다 다른 내부 IP(100.64.x)로 전달 → IP 키 분산 → 5/5min 한도가 영영 안 참. `app.py` 에 ProxyFix(x_for=1) 추가. prod 에서 6번째 401 후 429 실측 확인
- [x] **P1 사고 3 — 앱·백엔드 클래스 권한 계약 불일치 → 픽스**: 앱(`classes_screen.dart:111`)은 owner 조회 의도, 백엔드 `GET /api/v1/member/classes` 는 회원만 허용 → 코치 폰 CLASSES "Load failed". `api/classes.py` 에 GymManager(device_hash) 읽기 전용 폴백 추가 (예약/취소 POST·DELETE 는 회원 전용 불변). 로컬 + prod 검증 (회원 김도윤 200)
- [x] **runbook 배포 후 검증 4항목 전부 통과** — health·데모 로그인·rate limit 429·BASE_URL(env 등록, 코드가 요청 시점 read)
- [x] **폰(갤S22) 실기기 검증** — prod APK 앱 WOD 탭 정상, admin 웹 E2E(로그인→대시보드) playwright 통과

## 진행중
- [ ] **예약→취소 smoke (사용자 선택 "1")**: 중단 지점 = **신 APK 설치 실패**.
  - 상태: 폰은 데모 **김도윤(회원)** 으로 로그인됨 (구 박지훈 코치 세션은 Sign Out 함 — 데모 계정 선택 화면에서 재로그인 가능). 회원 Classes 화면 정상 로드 확인. prod 에 **SMOKE TEST CLASS (id=32, 2026-06-11 21:00, 정원 12)** 생성됨. 폰 리스트에 표시까지 확인
  - 블로커: 폰 설치본이 P0(카드 내 Reserve 버튼 dead) 픽스 **이전** 구버전 → Reserve 버튼 안 그려짐. `adb install -r dist/facing-1.0.0+3001-prod.apk` 가 `INSTALL_FAILED_UPDATE_INCOMPATIBLE` (기존 = 다른 서명, 아마 debug 서명)
  - 다음 스텝: `adb uninstall com.netizen.facing.facing_app` → `adb install dist/facing-1.0.0+3001-prod.apk` (데이터 초기화되지만 데모 계정 재로그인이면 충분) → 김도윤 로그인 → Profile→Classes→Reserve→Cancel 완주 → 스크린샷
  - 정리 의무: smoke 후 **SMOKE TEST CLASS 삭제** (admin 세션으로 DELETE /api/v1/admin/.../classes/32 또는 admin 웹 수업 관리에서 삭제. 엔드포인트는 api/classes.py 에서 확인)

## 대기 (이전 세션 승계)
- [ ] **[U] 네이버/구글 OAuth 키** — 키 수령 시 `--dart-define` 4종 빌드 + GOOGLE_SERVER_CLIENT_ID 등록. (폰 Link Staff 흐름이 소셜 로그인 선행 요구 — 키 없으면 막힘 확인됨)
- [ ] **[U] NHN 알림톡 키 3종** — 등록 전까지 prod 알림톡 stub
- [ ] **GitHub push** — 오늘 자 백엔드 커밋 3건(시드 가드·ProxyFix·클래스 권한) 로컬만. 배포 금지 룰대로 push 보류 (Railway 는 railway up 이라 무관)
- [ ] keystore 클라우드 2차 백업 (Documents 만으론 PC 사망 시 분실)

## 결정사항 / 주의
- **Railway 슈퍼씨드 env 변경됨**: APP_TEST_ADMIN_ID=cheb2oy (구 admin/1234 폐기). 데모 admin/1234 는 코드 시드로 유지
- **CORS_ORIGINS 가 admin 도메인 한정으로 좁혀짐** — 다른 origin 에서 API 직접 호출하는 웹이 생기면 추가 필요
- ProxyFix 로 액세스 로그에 실 클라이언트 IP 찍힘 (100.64.x 아님) — 정상
- 폰 무선 ADB 연결 살아있음 (adb-R5CT503NB5M). 풀해상도 screencap 은 API 거부 → PIL thumbnail 540px 축소 후 Read
- admin 웹 회원 승인 버튼 없음 (승인 = 코치 앱 PATCH gyms/{id}/members/{mid}) — 추후 admin 웹에 승인 UI 추가 검토 가치
- prod 회원 리스트에 (미입력) 행 3개 — 과거 실기기/테스트 디바이스 가입 흔적. 정리 후보
- Rule 1: 매 응답 PushNotification + 30분 idle 재발사

## 다음 세션 권장 첫 프롬프트
`/resume`
