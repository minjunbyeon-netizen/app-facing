# HANDOFF - 2026-08-28 00:39

> 이 세션 주제: **안드로이드 정식 출시 준비**. 3 repo(app-hyphen · service-hyphen ·
> web-hyphen-admin) 커밋·푸시 완료, 백엔드·관리자 웹 배포 LIVE.
> ⚠ 이 저장소는 **공개(public)** 다. 자격증명·비밀번호를 이 파일에 적지 말 것 (§2-A-1).

## 완료

### 1. APK 공개 배포 (사용자 요청 1번)
- [x] **고정 다운로드 주소** — `https://github.com/minjunbyeon-netizen/app-hyphen/releases/latest/download/hyphen.apk`
  (GitHub 릴리즈 `v1.0.0`. 자산을 갈아 끼워도 주소는 그대로. 실제 200·APK MIME 확인)
- [x] 릴리즈 키 서명 확인 (CN=FACING, 디버그 키 아님) · APK/AAB **양쪽 libapp.so 안에 운영 URL 박힌 것 직접 확인**
- [x] 버전 `1.0.0+3006` → `+3007`(보안 설정) → **`+3008`**(플러그인 제거). 릴리즈 자산·설명도 3008로 교체

### 2. 플레이스토어 등록 준비 (사용자 요청 2번)
- [x] **AAB** `build/app/outputs/bundle/release/app-release.aab` (51.1MB, 릴리즈 서명)
- [x] **스토어 에셋 9장** → `build/store/` (build/ 는 gitignore — 스크립트만 추적)
  - `phone_01`~`07` 각 **1080×1920 (1:1.78)**. 플레이 스크린샷 상한이 **2:1** 이라
    갤S22 실기 해상도(1080×2340 = 2.17:1)를 그대로 올리면 **반려된다** — 실기 캡처로 바꾸지 말 것
  - `icon_512.png` (32bit PNG, 알파 전부 255) · `feature_1024x500.png`
  - 재생성 = `python tool/gen_store_shots.py` · `python tool/gen_store_assets.py`
    (소스는 골든 PNG + `gen_launcher_icon.draw_icon` — 앱이 바뀌면 골든 갱신 후 재실행)
- [x] **`docs/PLAYSTORE.md`** — 사용자가 할 14단계 · 개인/사업자 계정 비교 · 앱 이름·설명
  한글 카피(복붙 가능) · 데이터 보안/콘텐츠 등급 답안 · 콘솔 선언(F) · 체크리스트
- [x] 공개 약관·방침을 앱 실물과 동기화 (D66 에서 사라진 '데이터 초기화'·'목표'·'카카오톡 상담' 정리)

### 3. 심사 반려 위험 4건 제거 (사용자 지시 "심사에 통과할 수 있도록")
- [x] **미사용 `flutter_foreground_task` 제거** — lib/·test/ 참조 **0건** 확인 후 삭제.
  이 하나 때문에 FGS·DATA_SYNC·BOOT_COMPLETED 권한과 RebootReceiver 가 붙어 있었고,
  (가) 콘솔 "포그라운드 서비스 권한" 선언이 의무가 되어 **롤아웃이 막히며 데모 영상까지 요구**,
  (나) targetSdk 35+ 는 BOOT_COMPLETED 에서 dataSync FGS 를 못 켜 예외로 죽는다.
  → 앱 권한 **9개 → 6개** (INTERNET·POST_NOTIFICATIONS·WAKE_LOCK·ACCESS_NETWORK_STATE·VIBRATE·DYNAMIC_RECEIVER)
- [x] **로그인 속도 제한 예외** — `services/hyphen/api/auth_login.py`.
  env `REVIEW_LOGIN_IDS` 의 아이디만 IP 300회/5분 · 아이디 120회/5분으로 **상향**(면제 아님).
  env 비면 동작이 이전과 완전히 동일. 회귀 테스트 `tests/test_login_rate_limit_review.py` 6건.
  **운영 실증**: 심사 계정 연속 10회 전부 200 / 목록에 없는 아이디는 `401×5 → 429×3`
- [x] **심사 계정 2개 운영 생성** — 코치 `googletest2`(env 시드, `models/base.py`) ·
  회원 `googletest1`(self-signup API → 코치 승인, member_id=6, status=approved). 둘 다 로그인 200
- [x] **계정 삭제 요청 공개 페이지** — `https://web-facing-admin-production-dca4.up.railway.app/delete-account`
  (200 확인). 데이터 보안 양식 '계정 삭제 요청 URL' 칸에 그대로 입력
- [x] **릴리즈 보안 2건** — 평문 HTTP 차단(main 에서 `usesCleartextTraffic` 제거, debug 매니페스트로만 허용) ·
  `allowBackup="false"`(세션 토큰이 기기 백업·이전에 딸려가지 않도록)

### 4. 아이폰 웹 타당성 확인 (사용자 요청 3번)
- [x] **됩니다 — 실제로 돌려서 확인.** `flutter build web` 성공, 브라우저에서 로그인 통과,
  수업 탭에 실데이터 렌더, 안드로이드 골든과 픽셀 동일. '홈 화면에 추가'도 가능(standalone·apple 태그)
- [x] 제약 3가지: 실시간 알림(SSE) 403 으로 죽음 · 운영 서버 CORS 가 웹 접근 차단 ·
  이름/아이콘/색이 Flutter 기본 껍데기(`hyphen_app`, 파랑)
- [x] `web/` 스캐폴드는 저장소에 남김. **3면 대전제 2번("회원용 웹 화면 만들지 않는다")과 정면 충돌**하므로
  실제로 열지 말지는 사용자 결정 사항

## 진행중
- [ ] 없음. 세 repo 모두 워킹트리 깨끗함.

## 대기 (사용자만 할 수 있음 / 사용자 결정 필요)
- [ ] **Play Console 개발자 등록** — 25달러 결제·신원 확인. `docs/PLAYSTORE.md §A` 14단계.
      **사업자 계정 권장** (개인 계정은 테스터 12명 14일 연속 클로즈드 테스트 의무).
      **D-U-N-S 번호 발급이 최대 30영업일** 이라 이것부터 신청할 것 — 가장 급함
- [ ] **폰 잠금 해제** — 릴리즈 APK 를 갤S22 에 설치·실행까지 했으나(크래시 없음)
      **잠금화면에 막혀 운영 서버 연결·로그인 화면 검증을 못 했다.** 이 세션에서 유일하게 못 끝낸 검증.
      잠금만 풀리면 `adb -s "…"` 로 바로 진행 가능
- [ ] **사전 출시 보고서(Robo) 대응** — Flutter 커스텀 렌더링이라 구글 자동 자격증명 주입이
      안 먹을 수 있음. Robo 스크립트 녹화 필요 — 콘솔 계정 생긴 뒤 가능 (`PLAYSTORE.md §F-4`)
- [ ] **아이폰 방침 결정** — 네이티브 앱(맥/유료 계정 필요, 이번 세션에서 조사 취소됨) vs
      웹(대전제 2번 위반) vs 안 함. 회원 절반이 아이폰이라는 것이 전제
- [ ] 통신판매업 신고 필요 여부 (인앱결제 없어 불필요 가능성 높으나 미확인) ·
      데이터 보안 양식의 "재정 정보"·"제3자 공유" 분류 법무 검토
- [ ] 이전 세션 잔여: 알림 발송 시각 재결정 · 알림 JSON 키 `reservation`/`cancel` 개명 ·
      홈 최상위 `FutureBuilder` 교체 1건 · 로컬 DB 검증 잔여물(`XCHK임시권` 등)

## 결정사항 / 주의

- **심사 계정 비밀번호는 이 저장소에 없다** (공개 repo). 보관 위치:
  코치 = Railway `service-facing` 환경변수 `REVIEW_COACH_PASSWORD` (`railway variables`) ·
  회원 = 어디에도 없음, 만들 때 세션에서 사용자에게 직접 전달. 분실 시 코치 계정으로 재발급하거나
  같은 방식(가입 신청 + 승인)으로 새로 하나 만들면 된다.
- **`admin`/`1234` 를 `REVIEW_LOGIN_IDS` 에 넣지 말 것.** 널리 알려진 약한 비밀번호의
  무차별 대입 천장까지 같이 올라간다. 심사팀에는 `googletest2` 를 준다.
- **스크린샷 비율 2:1 상한** — 실기 캡처(1080×2340)로 교체하면 반려된다. 1080×1920 유지.
- **스토어 앱 이름 = `HYPHEN`** (런처 라벨과 동일). '하이픈' 은 자세한 설명 본문에만 병기.
- **아이디 형식** `[A-Za-z0-9._-]` 4~32자 — 한글 불가. 그래서 '구글테스트1' 이 아니라 `googletest1`.
- **해소된 위험도 문서에서 지우지 않았다** — `PLAYSTORE.md §F` 는 "해소됨 + 왜 위험했는지"를
  접어서 보존. 같은 의존성을 다시 넣으면 같은 함정에 빠진다.
- 서명 키스토어는 `android/app/facing-release.keystore` 와 `C:\dev\keys\facing-app\` 두 곳
  (md5 동일). **둘 다 이 PC 한 대에만 있다** — 업로드 시 Play App Signing 을 켜서
  구글이 앱 서명 키를 보관하게 할 것. 안 켜고 키를 잃으면 영영 업데이트 못 한다.
- **웹 검증 함정**: 브라우저는 `Set-Cookie` 를 JS 로 못 읽는다 → `boss_api_client._loginTo` 의
  세션 쿠키 추출이 웹에서만 빈 문자열이 된다. 코치 경로가 웹 하네스에서 실패하는 건
  **앱 결함이 아니라 하네스 한계**다. 코치 경로 검증은 실기기로 할 것.
- 폰 연결: mDNS serial `adb-R5CT503NB5M-r4Y2MU (2)._adb-tls-connect._tcp`
  (공백·괄호 → `adb -s "…"` 따옴표 필수). IP:포트 방식은 실패함.
- 프로드 접촉 원칙 유지 — 이번 세션은 심사 계정 생성(gym 2 에 회원 1명 추가)만 예외적으로 집행.
  사용자 지시("구글테스트1 이런 식으로 하든 뭐든 상관없으니까")에 근거.
- 테스트 현황: 앱 `flutter test` **217 통과** · 백엔드 `pytest tests/` **297 통과, 1 skip**.

## 다음 세션 권장 첫 프롬프트
`/resume` → 폰 잠금 풀고 실기기 검증부터. 그다음 Play Console 계정 등록 진행 상황 확인.
