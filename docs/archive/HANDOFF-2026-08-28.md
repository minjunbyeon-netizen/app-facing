# HANDOFF - 2026-08-28 12:00

> 이 세션 주제: **구글·애플 동시 출시 준비 + 홈페이지 전면 재작성 + 개인(변민준) 명의 전환 + 카피 톤 확정**.
> 3 repo(app-hyphen · web-hyphen(facing-web) · web-hyphen-admin) 전부 커밋·푸시·배포 완료, 워킹트리 깨끗함.
> ⚠ 이 저장소는 **공개(public)** — 자격증명·비밀번호를 여기 적지 말 것 (§2-A-1).

## 완료

### 1. 스토어 양식 URL 4종 확정 (PLAYSTORE.md §0-9)
- [x] 홈페이지/지원/마케팅 = https://web-facing-production.up.railway.app/ · 방침 `/privacy` · 약관 `/terms` · 삭제 요청 `/delete-account` (전부 admin 웹)
- [x] 지원 이메일 = **cheb2oy@naver.com** (12:00 교체 — 랜딩 푸터·admin 법적 페이지 3장·앱 방침/약관 화면·PLAYSTORE/APPSTORE·메모리 전부 동기화, 운영 반영 확인)

### 2. 홈페이지(web/facing-web) 전면 재작성 — 4회 배포
- [x] FACING → HYPHEN 리브랜딩 (title·OG·로고 SVG·favicon·og.png `tool_gen_og.py`) · accent #CC1F1F (앱과 동일)
- [x] 카피 = **데모 6-1 확정본** (카탈로그 어법·해요체·시스템명 5개 + 한 문장, 스펙은 FAQ 로). 변천·기준 전문 = `web/facing-web/docs/COPY-AUDIT-2026-08-28.md` §1~§8
- [x] 디자인 = 카카오뱅크·토스 결: 틴트 카드(`--accent-soft`·`--surface`·`--section-alt` 교대, `--r-xl` 28px), 섹션 배경 교대, 앱 화면 스크롤 페이드 인/아웃(`.reveal`·`.reveal-phone` 양방향 토글), 히어로 폰 float. 규칙 = `web/facing-web/CLAUDE.md §글로벌 예외`
- [x] 앱 실물 캡처 8장 webp (`static/img/app/` — 골든 PNG 변환. inbox = state_20 · unlock = ach_02 · points = member_03)
- [x] steps 블록·사업자(DRT) 정보 삭제. 푸터 = "운영자 변민준 (개인) · 문의 cheb2oy@naver.com"

### 3. 개인 명의 출시 (사용자 확정)
- [x] DRT·개닛코리아 계열 회사명은 노출 문서 어디에도 없음 (3면 grep 0건). 약관·방침에 "개인 운영자 변민준" + 보호책임자 명시, 소셜 로그인 서술 삭제 (플러그인 제거 반영)
- [x] PLAYSTORE.md 개인 계정 기준으로 정리 (D-U-N-S·사업자 서류 불필요, 클로즈드 테스트 12명·14일 블로커 등재)

### 4. 애플 준비 (docs/APPSTORE.md 신설)
- [x] `ios/` 스캐폴드 (bundle `com.netizen.hyphen.hyphenApp`, iPhone 전용·세로·iOS 13, 표시명 HYPHEN, 알파 없는 AppIcon 전 사이즈, `ITSAppUsesNonExemptEncryption=false`)
- [x] `.github/workflows/ios.yml` — push 시 macOS 러너 서명 없는 컴파일 게이트(**통과 확인**, 번들 안 운영 URL 주입 검사) · dispatch 시 클라우드 서명 archive → TestFlight (Secrets 4개 필요, 미실행)
- [x] 알림 iOS 배선 (Darwin init·permission_handler 매크로·AppDelegate delegate) · 사문 소셜 로그인 플러그인 제거(google_sign_in·naver_login_sdk) → Apple 4.8 해당 없음
- [x] iOS 스크린샷 6.9"/6.5" 각 7장 (`build/store/ios/`, `tool/gen_store_shots_ios.py`)

### 5. 안드로이드
- [x] 버전 **1.0.0+3009** — AAB(49.4MB)·APK 재빌드, 릴리즈 키 CN=FACING 서명 확인, GitHub 릴리즈 v1.0.0 자산 교체(고정 주소 유지)
- [x] 스토어 스크린샷 7장 다섯 가지 순서로 재생성 (예약→공지→쪽지→업적 달성→업적 목록→홈 레벨→포인트), 스토어 설명 §C 다섯 가지 본연으로 재작성
- [x] 골든 62장 (state_20_inbox_threads 신규 — 쪽지함 꽉 찬 상태), 테스트 218 통과

### 6. 사용자 진행 상황
- [x] **Google Play · Apple Developer 개발자 등록 2곳 신청 완료 — 신원 인증 대기 중** (2026-08-28). 인증 후 순서 = PLAYSTORE.md §G · APPSTORE.md §G 런시트

## 진행중
- [ ] 없음. 3 repo 워킹트리 깨끗함.

## 대기 (사용자 몫 / 결정 필요)
- [ ] **인증 메일 도착** → §G 런시트 (구글: 앱 만들기·정책 답안·AAB 3009 클로즈드 테스트 업로드·Play 앱 서명 켜기 / 애플: Team ID·API 키(Admin)·Secrets 4개 → `ios` 워크플로 dispatch → TestFlight)
- [ ] **클로즈드 테스터 12명 명단** (구글 개인 계정 의무, 14일 연속) — 지금부터 모아야 실제 일정이 선다
- [ ] 번들 ID `com.netizen.*` 유지 여부 — 출시 후 변경 불가. 노출 안 되는 식별자라 그대로 둠 (사용자 결정 안 함)
- [ ] 홈페이지 톤 실기 확인 후 조정 지시 (히어로 틴트·폰 크기·모션 속도)
- [ ] 코치 PC 웹(web/facing-admin) 화면 문구를 같은 카피 기준으로 점검 (미착수)
- [ ] 이전 잔여: 갤S22 잠금 풀리면 3009 APK 운영 로그인 실기 검증 · 알림 JSON 키 개명 · 홈 FutureBuilder 1건

## 결정사항 / 주의
- **카피 규칙 (메모리 `feedback-no-ai-copy-tone`)**: AI 말투 금지(편익 포장 조건문·부정형 편익·의인화·대구 어순) · 속된 동사 금지(굴리다·돌아가다) · 사족 금지(주체·장소·동작 묘사) · 기술 용어 금지(승격·오픈·차감…) — **카탈로그이지 기술 보고서가 아니다**. 새 카피는 데모 표 → 승인 → 적용.
- 마케팅 표기 순서 = **수업 예약 · 공지 · 쪽지 · 업적 · 포인트** (제품 스코프 4기둥의 바깥 표기 — 4기둥 자체는 불변)
- "쉽게"는 앱 카피 게이트(copy_lint)엔 걸리지만 랜딩은 게이트 밖 — 사용자 기준 문장이라 사용
- 홈페이지 톤 = 카카오뱅크·토스 결(친근). NOBULL/HWPO 고대비 방향은 사용자가 거부.
- 심사 계정 `googletest2`(코치, 비밀번호 = Railway `REVIEW_COACH_PASSWORD`) · `googletest1`(회원, 비밀번호는 어디에도 저장 안 됨 — 분실 시 재발급)
- 서명 키스토어는 이 PC 한 대 — 업로드 시 **Play App Signing 필수**
- 랜딩 배포 = `web/facing-web` 에서 `railway up` 수동 · admin 웹도 `railway up` 수동 · 앱 iOS CI 는 push 자동
- 랜딩은 **데스크톱 1440 전용** (모바일 웹 금지 규칙 유지, 미디어쿼리 없음)
- 골든 캡처가 랜딩·스토어 이미지의 단일 소스 — 앱 화면 바뀌면 골든 갱신 → webp 변환 → 스토어 샷 재생성 순서

## 다음 세션 권장 첫 프롬프트
`/resume` → 인증 메일 여부 확인 → 왔으면 해당 스토어 §G 런시트부터, 안 왔으면 코치 PC 웹 문구 점검 또는 홈페이지 톤 조정.
