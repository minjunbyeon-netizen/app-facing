# HANDOFF - 2026-08-21 13:31

> v3.3(앱) + admin 인라인 전량 정리(v4/v4.1) + 에뮬레이터 실 APK 검증 세션 인계.
> 직전 인계장 = `docs/archive/HANDOFF-2026-08-21-1117.md`.

## 완료
- [x] **앱 v3.3** (`fb7ae8c`·`d586145`·`63fa3a8`, push 안 함):
      ① 인트로 2p 코드째 삭제 — 화면·`/intro` 라우트·골든 2장 (README §제거된 기능 대장 11)
      ② 진입 화면 로고 위치 고정 — `HkEntryLogoGap`(화면 높이 24%) 을 스플래시·로그인·
         전면 로딩 3곳 적용 (DESIGN-SSOT §6 갱신, Spacer 중앙정렬 금지 명문화)
      ③ 가입 신청 실시간 검증 — Form `autovalidateMode.onUserInteraction` (자동 하이픈·형식
         검증은 v2.6 input_formatters 그대로, **API 필드·형식 변경 0** — PC 명단과 안 꼬임)
      ④ `flutter_localizations` ko 배선 (main.dart + `test/golden/harness.dart` 동일) —
         날짜·시간 다이얼로그 전부 한글 (Select date/Cancel/OK → 날짜 선택/취소/확인)
      ⑤ 코치 대시보드 헤더 생 role 'OWNER' → `roleKoLabel` '코치' + Box→체육관·툴팁 한글
      ⑥ 골든 47→45장 재생성 (갤러리 장수 SECTIONS 자동 산출 — "41장" 낡은 표기 소멸),
         전체 170 테스트 그린, 갤러리 47→45장 육안 검수 완료
- [x] **admin 인라인 스타일 전량 클래스화** (web/facing-admin `14895e1`·`18aae23`, push 안 함):
      546→**20건** (잔존 = Jinja/JS 동적 값 + 토큰 없는 색 스와치 — 전부 정당).
      도구 = `scripts/inline_style_sweep.py` (멱등·`--check`). 유틸리티 233종 = style.css 말미
      AUTO 블록. 초기 숨김 = `is-hidden` 클래스 + `display=''` 해제 28곳 `classList.remove` 병기.
      모달 백드롭 중복 인라인 삭제. hex→토큰 var() 승격 3종(#EE2B2B·#10B981·#F59E0B — 값 동일).
      검증: 21페이지 전/후 픽셀 대조 **21/21 동일** · is-hidden 메커니즘 17페이지 전수 ·
      모달/검색 필터/업적 빌더 실클릭 스모크 통과 · design lint 위반 0 · baseline 20 갱신
- [x] **에뮬레이터 실 APK(디버그 빌드) 검증 4종 통과**: 스플래시↔로그인 로고 밴드 픽셀 동일 ·
      생년월일/연락처 자동 하이픈 + 제출 없이 실시간 빨간 안내 · 코치 헤더 "코치" ·
      날짜("2026년 8월·일월화수목금토·취소/확인")/시간("오전/오후") 다이얼로그 한글.
      코치 로그인 = admin/1234 (로컬 백엔드 5060)

## 진행중
- (없음)

## 대기
- [ ] **갤S22 실기기 검증** — 무선 ADB 끊김 (캐시 192.168.1.100:5555 거부, 재부팅으로 포트
      소멸 추정). 사용자에게 IP:포트 요청해 둔 상태 (푸시 발송됨).
      연결 절차: `powershell C:/dev/tools/phone/phone-connect.ps1` (새 IP:포트 입력) →
      실기용 빌드는 프로드 URL 주입: `flutter build apk --debug
      --dart-define=API_BASE_URL=https://service-facing-production.up.railway.app` →
      `adb install -r build/app/outputs/flutter-apk/app-debug.apk` → 에뮬레이터와 같은 4종 검증.
      ⚠ 프로드 코치 계정 유무 미확인 — 로그인 안 되면 pre-auth 화면(로고·가입 검증)만 확인하고 보고

## 결정사항 / 주의
- **push 전부 안 함** (배포 금지 룰 v1.16.1) — 앱 3커밋 + admin 2커밋 로컬만. 배포는 사용자 명시 시
- admin 유틸리티 = 3중 클래스(인라인급 우선 서열)·**!important 금지** (JS el.style 직접 조작이
  이겨야 기존 토글 유지) — 근거 주석 = `scripts/inline_style_sweep.py` 헤더
- `is-hidden` 패턴: 앞으로도 `el.style.display=''` 로 보이게 하는 코드엔
  `el.classList.remove('is-hidden')` 병기 (안 하면 초기 숨김 요소가 안 보임)
- 앱 로케일: `main.dart` 와 `test/golden/harness.dart` 의 ko 배선 동일 유지 의무 (§0-B)
- 로컬 서버 2개 기동 중: 백엔드 5060 · admin 8081 (admin/1234). 골든 갤러리 서버 8123 도 기동 중
- 에뮬레이터(emulator-5554)에 디버그 APK 설치·코치 로그인 상태로 남아 있음 (무해)

## 다음 세션 권장 첫 프롬프트
`/resume` (+ 갤S22 무선 디버깅 IP:포트 한 줄)
