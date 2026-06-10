# 론칭 D-Day 체크리스트 — 2026-06-10 (오늘 전량 처리 목표)

> 원본: `docs/QA-LAUNCH-2026-06-10.md` (4파트 40항목 QA). 위에서 아래 순서대로 처리.
> 규칙: 배포 금지 (로컬 commit 만, push·Railway·스토어 X). 각 항목 완료 시 `[x]` + 검증 방법 실행.
> 좌표 표기: `(앱)` = apps/facing-app, `(백)` = services/facing, `(웹)` = web/facing-admin

---

## A. P0 — 론칭 차단 5건 (최우선, 오전 내 목표)

### A-1. (백) 회원 계약 조회·전자서명 403 버그 — 예상 15m
- [ ] `api/contracts.py:329` — `m.device_hash != device_id` → `m.device_hash != hash_device_id(device_id)` 수정
- [ ] `api/contracts.py:382` — 동일 수정 (서명 POST 쪽)
- [ ] hash_device_id import 확인 (다른 라우트가 쓰는 동일 헬퍼 재사용)
- [ ] 검증: `curl GET /api/v1/member/contracts/12 -H "X-Device-Id: persona-member-kim-doyun-2026"` → 200 (이전 403)

### A-2. (백) 로그인 rate limit noop — 예상 20m
- [ ] `api/admin.py:422-437` `_rate_limit_login` 빈 데코레이터 제거 또는 실구현
- [ ] `/api/v1/admin/login` 에 `@limiter.limit("5 per 5 minutes")` 실적용
- [ ] `/api/v1/coach/pair` 에도 시도 제한 적용 (예: `10 per hour`) — P2-9 동시 해소
- [ ] 검증: wrong pw 6연속 curl → 6번째 429 응답 확인
- [ ] 주의: limiter in-memory storage 는 로컬 단일워커라 동작함. 멀티워커 경고 주석만 유지

### A-3. (웹) 계약서 다운로드·QR 검증 404 — 예상 20m
- [ ] `templates/contracts.html:213` — `window.open('/api/v1/admin/contracts/<id>/pdf')` → `/api/proxy/contracts/<id>/pdf` 로 교체
- [ ] `templates/contracts.html:207` — QR 검증 링크 `/api/v1/contracts/<id>/verify` → 백엔드 절대 URL(5060/프로덕션 BASE_URL) 또는 프록시 경로로 교체. QR 은 외부인(회원 폰)이 찍는 링크이므로 **백엔드 공개 URL** 이 정답인지 먼저 판단
- [ ] 검증: 8081 로그인 후 다운로드 클릭 → PDF 수신, QR 링크 curl → 200

### A-4. (앱) 신규 회원 가입 신청 고아 라우트 배선 — 예상 40m
- [ ] `/signup/self` (SelfSignupScreen) 진입점 추가 — signup_screen(로그인 화면)에 "박스 가입 신청" 버튼 또는 온보딩 흐름에서 연결 (UI 위치 결정 포함)
- [ ] `/onboarding/create-gym` (CreateGymScreen) 진입점 추가 — 사장/코치용 흐름에서 연결, 또는 이번 릴리즈 대상이 아니면 라우트·화면 주석 처리로 명시적 비활성 (방치 금지)
- [ ] `self_signup_screen.dart:127` — 성공 다이얼로그 이동 `/home` → `/shell` 수정
- [ ] 검증: 에뮬레이터에서 로그인 화면 → 가입 신청 화면 도달 → 빈값 제출 시 검증 토스트 확인

### A-5. (앱+백) 소셜 로그인 방향 결정 + 처리 — 예상 결정 5m + 작업 30m~
- [ ] **결정 필요**: ① 스텁 유지 론칭 (오늘 권장 — 백엔드 `/auth/social` 미구현 상태 그대로, 실 OAuth 빌드 플래그 OFF 고정 + StaffLinkScreen 진입 차단) vs ② 백엔드 `/auth/social`·`/auth/link-staff` 오늘 구현
- [ ] ①안 채택 시: `USE_REAL_AUTH` 류 플래그가 release 빌드에서 절대 true 안 되도록 가드 + StaffLinkScreen 네비 진입점 차단/숨김
- [ ] ②안 채택 시: 백엔드 auth 블루프린트 신설 (social token 검증 + member 매핑 + link-staff), 앱 스텁 → 실서비스 전환
- [ ] 검증: release 모드 빌드에서 로그인 경로 전부 동작 (스텁이면 데모/박스가입 경로만 노출되는지)

---

## B. P1 — 앱 7건 (오후 1차)

### B-1. 온보딩 진행률 "STEP 7 / 6 · 117%" — 예상 15m
- [ ] `onboarding_benchmarks.dart:409-433` — 분모 하드코드 "/6" 을 실제 총 스텝 수 상수로 교체 (카테고리 6개 + basic 1 = 7 또는 설계 의도 확인)
- [ ] `stepNumber = _page + 2` 로직 재검 (basic 화면 "STEP 1 / N" 과 정합)
- [ ] (P2 연동) onboarding_basic AppBar "STEP 1 / 6" 과 본문 "Step 1 / 6" 이중 표기 정리
- [ ] 검증: 온보딩 끝 페이지에서 "STEP 7 / 7 · 100%" 표시

### B-2. 인트로 첫 실행 미노출 (분기 역전) — 예상 20m
- [ ] 신규 유저 happy path 를 Splash → `/intro` → `/signup` 순으로 재배선 (intro_seen=false 면 로그인 전이라도 인트로 먼저)
- [ ] `splash_screen.dart:125-135` 분기 조건 수정 + `signup_screen.dart:78,136` 흐름 확인
- [ ] 검증: shared_preferences 초기화 후 첫 실행 → 인트로 3페이지 → Skip → 로그인 화면

### B-3. 인트로 콘텐츠 포지셔닝 불일치 — 예상 30m
- [ ] `intro_screen.dart:21-48` 3페이지 카피 재작성 — Primary value(수업 예약·박스 운영) 1~2페이지 + 페이싱 +α 1페이지
- [ ] Voice&Tone V1~V11 준수 (영문 헤드라인 + 한글 캡션 스택, 마침표 3분류, 금지 용어 제외)
- [ ] CLAUDE.md 카피 템플릿 동기화 ("Start." ↔ "Run it." SSOT drift 도 이 커밋에서 해소 — §0-B)
- [ ] 검증: 인트로 3페이지 카피가 CLAUDE.md 템플릿 표와 일치

### B-4. QR 체크인 정식 진입점 — 예상 30m
- [ ] **결정**: 회원 셀프 체크인 제공 여부 (사장 PC `/checkin` 디스플레이 운영 전제면 앱 화면 불필요 → 명시적으로 범위 제외 기록)
- [ ] 제공 시: `_debug/qr_input_screen.dart` 를 정식 feature 로 승격 (카메라 스캔 or 코드 입력), 홈/출석 화면에서 진입
- [ ] 검증: release 빌드 회원 계정에서 체크인 화면 도달

### B-5. 회원 포인트 잔액 조회 — 예상 40m
- [ ] (백) `GET /api/v1/member/points` (잔액 + 최근 내역) 신설 — admin 전용 로직 재사용
- [ ] (앱) 마이페이지에 잔액 표기 (적립 토스트 "+NP" 와 신뢰 일치)
- [ ] 검증: curl 잔액 응답 ↔ 앱 표시 일치

### B-6. 앱 내 계약 조회·서명 화면 — 예상 60m
- [ ] **결정**: 오늘 범위 포함 여부 (A-1 백엔드 수정으로 API 는 살아남 — 화면이 없으면 회원은 여전히 서명 불가, 단 현장/대리 서명으로 운영 가능)
- [ ] 포함 시: 마이페이지 → 내 계약 목록 → 상세 → 서명(서명패드 or 동의 버튼) 최소 구현
- [ ] 검증: 데모 회원으로 계약 상세 200 + 서명 POST 성공

### B-7. self-signup duplicate 분기 — 예상 10m
- [ ] `self_signup_screen.dart:99-104` — 응답 `duplicate==true` 시 "이미 승인 대기 중입니다" 별도 안내로 분기
- [ ] 검증: 같은 device 로 2회 신청 → 두 번째에 대기 중 안내

---

## C. P1 — 백엔드 3건 (오후 1차, B 와 병행 가능)

### C-1. 전화번호 형식 검증 — 예상 20m
- [ ] (백) `api/admin.py:668` self-signup + admin 회원 등록 + CSV bulk-import 에 010 정규식 검증 (예: `^01[016789]-?\d{3,4}-?\d{4}$`, 하이픈 정규화 저장)
- [ ] (앱) `self_signup_screen.dart:229-231` 프론트 검증 + 자동 하이픈
- [ ] (웹) members.html 등록 폼에도 동일 검증
- [ ] 검증: invalid phone curl → 400 `INVALID_PHONE`

### C-2. 데모 계정 admin/1234 시드 단절 — 예상 20m
- [ ] `models/base.py:144-181` seed_superadmin 이 만드는 AdminUser 가 로그인 경로(GymManager 조회)와 단절 — 부팅 시드에 GymManager `admin/1234` 추가 (글로벌 룰 §3-A: 모든 환경 의무 시드, bcrypt 해싱)
- [ ] 슈퍼씨드(APP_TEST_ADMIN_ID env 기반)도 GymManager 경로로 동작하는지 확인
- [ ] 검증: DB 파일 삭제 후 재부팅 (또는 fresh DB) → admin/1234 로그인 200

### C-3. user enumeration — 예상 10m
- [ ] `api/admin.py:458,461` — "계정 없음" / "비밀번호 불일치" → "아이디 또는 비밀번호가 올바르지 않습니다" 단일 메시지 통합
- [ ] 계정 없을 때도 더미 bcrypt 1회 수행 (timing 균일화)
- [ ] 검증: 두 실패 케이스 응답 본문 동일 확인

---

## D. P1 — 관리자 웹 5건 (오후 2차)

### D-1. 계약 "수정" 버튼 전건 무동작 — 예상 15m
- [ ] `contracts.html:159` — onclick 인라인 JSON 주입 제거 → `data-id` 속성 + 이벤트 위임으로 교체 (variables 는 클릭 시 fetch 또는 메모리 캐시에서)
- [ ] 검증: 계약 수정 모달 정상 오픈 (콘솔 에러 0)

### D-2. 박스 스위처 쿠키 비동기화 — 예상 30m (재현 포함)
- [ ] 다중 박스 계정(boss — gym 1·7)으로 실로그인 → 박스 전환 → gym-scoped API 403 재현 확인
- [ ] 재현 시: `app.py:254-269` switch-gym 응답의 Set-Cookie 를 facing-admin 세션에 갱신 저장
- [ ] 검증: 전환 후 회원 목록·대시보드 정상 로드

### D-3. 회원 level 비표준 값 → /members 500 — 예상 15m
- [ ] `members.html:85` Jinja dict 인덱싱 → `.get(m.level, 'scaled')` fallback
- [ ] (백) level 입력 enum 검증 (Scaled/RX/RX+/Elite 외 거부 또는 정규화) — 등록·PATCH·CSV import 3경로
- [ ] 검증: level "Beginner" 인 행 있어도 /members 200

### D-4. SSE 토스트 XSS + scale_guide 미이스케이프 — 예상 20m
- [ ] `_layout.html:268-271` — 회원발 payload(쪽지 preview·건의 subject·공지 title) innerHTML → textContent 로 교체
- [ ] `wod.html:55` scale_guide 이스케이프 추가
- [ ] 검증: 쪽지에 `<img onerror>` 페이로드 → 토스트에 문자 그대로 표시

### D-5. 로그인 프리필 제거 + QR 외부 의존 제거 — 예상 30m
- [ ] `login.html:42,47,49` — boss_seongsu/1234 value 프리필·힌트 제거 (로컬 dev 에서만 보이게 하려면 환경 분기)
- [ ] 로그인 버튼 중복클릭 disabled 처리
- [ ] `checkin.html:61-62` — api.qrserver.com 외부 QR 생성 → 로컬 JS QR 라이브러리(qrcode.js 등 vendored)로 교체. 토큰 제3자 전송 차단
- [ ] `checkin.html` refreshToken 실패 시 음수 타이머·매초 재호출 → 백오프 추가
- [ ] 검증: 오프라인(외부망 차단)에서도 QR 렌더, 로그인 폼 빈값 시작

---

## E. P2 — 론칭 후 개선 (오늘 여력 시, 위 전부 끝난 뒤)

### E-앱 (4건)
- [ ] E-1. Splash 고정 2500ms 지연 단축(예: 1200ms) + 죽은 애니메이션 슬롯 3~5 정리
- [ ] E-2. 출석 캘린더 `attendance_screen.dart:79-85` snap.hasError 분기 추가 ("Load failed + Retry")
- [ ] E-3. self_signup_screen 토큰화 (하드코드 fontSize 16 ×2, Colors.white, radius 직접값 → FacingTokens)
- [ ] E-4. self_signup/create_gym 친근체("~해 주세요") → V1 명령형, V9 혼용 문장 수정
- [ ] E-5. BoxLeaderboardScreen dead screen 처리 — 삭제 또는 회원 허용 endpoint 신설 후 배선
- [ ] E-6. 빈 프로필 `{}` 등급 산출 — 최소 1개 입력 요구 검토

### E-백엔드 (3건)
- [ ] E-7. SECRET_KEY 미설정 시 prod fail-fast (현 "facing_default_salt" fallback 제거)
- [ ] E-8. `admin.py:1653` leaderboard 라우트 문자열 백슬래시(`\a` 제어문자) 확인·수정
- [ ] E-9. require_csrf 실적용 — 결제·삭제 계열 POST 부터

### E-웹 (6건)
- [ ] E-10. 저장·게시 버튼 중복클릭 방지 (회원 추가·WOD 게시)
- [ ] E-11. WOD Benchmark·동작 라이브러리 placeholder 탭 숨김
- [ ] E-12. app.js 데드 함수 4종(`submitNewMember` 등 /api/members* 호출) + `_member_form_fields.html` 미사용 partial 삭제
- [ ] E-13. modal_preview.html 공개 서빙 차단
- [ ] E-14. 보안 헤더 (X-Frame-Options, CSP 최소셋)
- [ ] E-15. SSE 토스트 이모지(📋🏁✉ 등) → → ✓ ● ○ 교체 (디자인 룰)
- [ ] E-16. 로그인/레이아웃 meta description 차별화 + 가치 제안 1줄 + "v0.4 · Phase 2 (베타)" 표기 정리

---

## F. 잔여 인계 작업 (전 세션)
- [ ] F-1. WOD 상세 동작 행(`_MovementRow`) 에뮬레이터 시각 확인 — WOD 126 [STRUCT-0609], demo 회원 로그인 상태. `adb exec-out screencap` → 다운스케일 → Read (MSYS_NO_PATHCONV=1 주의)

## G. 최종 회귀 검증 (전 항목 완료 후)
- [ ] G-1. (앱) `dart analyze` No issues
- [ ] G-2. (백) 백엔드 재기동 → health + A-1/A-2 재검 curl
- [ ] G-3. (웹) 8081 로그인 → 계약 다운로드/수정·회원 목록·WOD 게시 smoke
- [ ] G-4. 에뮬레이터 release-모드 빌드로 신규 유저 플로우 1회 완주 (인트로 → 가입 신청 → 승인 대기)
- [ ] G-5. QA 보고서(`QA-LAUNCH-2026-06-10.md`)의 P0/P1 항목 옆에 해소 표기 갱신
- [ ] G-6. 양 repo 로컬 커밋 정리 (push 금지 유지 — 사용자 "배포해" 명시 시까지)

---

### 결정 대기 항목 (사용자 판단 필요 — 작업 착수 전 확인)
| # | 결정 | 기본 권장 |
|---|---|---|
| A-5 | 소셜 로그인: 스텁 유지 vs 백엔드 오늘 구현 | ① 스텁 유지 + 진입 가드 (오늘 완료 가능) |
| A-4 | create-gym 화면: 배선 vs 명시적 비활성 | 비활성 (사장 온보딩은 웹 admin 경로 운영) |
| B-4 | 회원 셀프 QR 체크인 제공 여부 | 사장 PC 디스플레이 운영 전제 → 범위 제외 |
| B-6 | 앱 내 계약 서명 화면 오늘 포함 여부 | 포함 권장 (전자계약이 핵심 셀링 포인트) |
