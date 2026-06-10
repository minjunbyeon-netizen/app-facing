# 론칭 D-Day 최종 체크리스트 v2 — 2026-06-10

> 원본 QA: `docs/QA-LAUNCH-2026-06-10.md` (4파트 40항목). v1 을 2차 병렬 비판 회의(완결성·기술 정확성·실행 계획 3검수관)로 재검증한 최종안.
> **v1 대비 변경 요지**: ① 좌표 오류 수정(A-1 은 382→379행, E-8 은 false positive 로 삭제) ② 우선순위 직렬(A→B→C→D)을 **검증 환경별 배치**(백엔드/앱/웹)로 재편 — 같은 파일 5회 왕복 제거 ③ 코드 외 론칭 준비 H 섹션 신설(기본 아이콘·debug 서명·dart-define 실측 확인) ④ "오늘 전량" → **P0+P1+H 필수, E 는 내일 이관 선언** (보정 추정 11.5h — E 포함 불가) ⑤ 결정 4건을 문서 맨 앞으로.
> 규칙: 배포 금지 (로컬 commit 만). 좌표는 QA 시점 스냅샷 — 착수 시 grep 재확인.

---

## 0. 시작 전 결정 4건 (작업 착수 전 일괄 확정 — 미응답 시 권장안 진행)

| # | 결정 | 권장안 | 미채택 시 영향 |
|---|---|---|---|
| 결정1 (A-5) | 소셜 로그인: 스텁 유지 vs 백엔드 구현 | **① 스텁 유지 + 진입 가드** | ②안은 백엔드 +2~4h — 오늘 계획 붕괴 |
| 결정2 (A-4) | create-gym 화면: 배선 vs 명시적 비활성 | **비활성** (사장 온보딩은 웹 admin) | 배선 시 앱 배치1 +30m |
| 결정3 (B-4) | 회원 셀프 QR 체크인 제공 여부 | **범위 제외** (사장 PC 디스플레이 운영) — 문서화 5m | 제공 시 +30m |
| 결정4 (B-6) | 앱 내 계약 화면 | **최소안: 목록+상세 조회만** (60m 타임박스). 서명패드는 내일 | 풀스펙(서명패드)은 실측 2.5~4h — v1 의 "60m" 은 과소추정 (목록 endpoint 도 백엔드에 없음) |

## 0-b. 운영 규칙 (오늘 하루)

- **클러스터 완료 시점에 체크박스 일괄 갱신 + 클러스터당 로컬 커밋 1개** (push 절대 금지)
- **blocker**: 막히면 해당 항목에 `[BLOCKED: 사유]` 메모 후 다음 항목 (기존 선호). 단 **A 섹션(P0) blocker 만 즉시 푸시 보고**
- **타임박스 2건**: D-2 재현 20m / B-6 60m — 초과 시 중단이 기본값
- **release 빌드는 하루 1회** (G 에서만). 낮 검증은 전부 디버그 모드. 백엔드 재기동은 배치당 1회
- **/compact 2회**: 배치2 종료 후(점심) + G 직전. 직전 `chore(compact)` 커밋
- **A-2 적용 후 주의**: rate limit(5/5min)이 이후 로그인 계열 검증(C-3·D-2·G)을 잠글 수 있음 — memory:// 라 백엔드 재기동으로 리셋됨

## 0-c. 시간대별 배치 (09:30 시작 가정)

```
09:30-11:00  배치1 백엔드 (A-1·A-2·C-3·C-1백 +E-7 ride) → 재기동 → 체크포인트① curl 스위트
11:00-13:00  배치2 앱 라우팅·인트로 클러스터 (A-4·B-2·A-5①·B-3) → 체크포인트② fresh-install 플로우 + F-1 편승
13:00-13:30  /compact + chore(compact) 커밋
13:30-15:00  배치3 앱 self_signup 클러스터 (B-7·C-1앱 +E-3/E-4 ride) + B-1 진행률
15:00-16:30  배치4 웹 (D-5a 최우선 → A-3+D-1 → D-3+C-1웹 → D-4 +E-13/E-14 ride) → 체크포인트③ 8081 smoke
16:30-17:00  배치4b D-2 박스 스위처 (20m 타임박스) + C-2 시드 (DB 백업 후 — §의존성 주의)
17:00-18:00  배치5 크로스 B-5 포인트 (백 신설 → 재기동 → 앱 표기)
18:00-19:00  배치6 조건부 B-6 최소안 (60m 타임박스)
19:00-21:00  G 최종 회귀 (release 빌드 1회 통합) + H 론칭 준비 + 보고서 갱신 + 커밋 정리
```

### 의존성 경고 (v2 신설 — 작업 전 숙지)
- **C-2 검증의 "DB 삭제"는 A-1(계약 12)·D-2(boss 계정)·F-1(WOD 126) 검증 데이터를 파괴** → C-2 는 별도 임시 DB(`FACING_DB` env 임시 경로)로 fresh 시나리오 검증하거나, 본 DB 는 백업 후 G 직전 실행
- **A-4 와 B-2 는 같은 플로우** (splash/signup 라우팅) → 배치2 에서 최종 플로우(Splash→intro→signup) 먼저 확정 후 한 흐름으로 작업
- **self_signup_screen.dart 는 4건(A-4잔여·B-7·C-1앱·E-3/E-4)이 수정** → 배치3 에서 일괄, 검증(가입 플로우 1회)도 통합

---

## 배치 1 — 백엔드 (api/admin.py · contracts.py 묶음, 재기동 1회)

### A-1. (백) 회원 계약 조회·전자서명 403 버그 [P0] — 15m
- [ ] `api/contracts.py:329` — `m.device_hash != device_id` → `m.device_hash != hash_device_id(device_id)`
- [ ] `api/contracts.py:379` — 동일 수정 (v1 의 382는 오기 — 379가 sign 쪽 비교 줄)
- [ ] `from models.profile import hash_device_id` import 추가 (contracts.py 는 현재 미import. 시그니처 `hash_device_id(device_id: str) -> str`, salt 인자 없음 — 사용 예 `api/classes.py:210`)
- [ ] 검증: `curl GET /api/v1/member/contracts/12 -H "X-Device-Id: persona-member-kim-doyun-2026"` → 200 (현재 403 재현 확인됨)
- [ ] 서명 POST 검증은 계약 12(signed)로 불가 — **'sent' 상태 계약(2·4·6·7·8 중 해당 회원 것)** 으로 G-8 에서 수행

### A-2. (백) 로그인 rate limit noop [P0] — 30~40m (v1 20m 보정)
- [ ] `api/admin.py:422-437` noop 데코레이터 `_rate_limit_login` 제거
- [ ] **순환 import 주의**: limiter 가 `app.py` create_app 내부 생성이라 `from app import limiter` 불가. 택1 —
  (a) `extensions.py` 신설: 모듈 레벨 `limiter = Limiter(...)` + create_app 에서 `limiter.init_app(app)` (정석)
  (b) create_app 안 late-binding: `limiter.limit("5 per 5 minutes")(app.view_functions["<bp>.admin_login"])`
- [ ] `/api/v1/admin/login` (admin.py:440 — 백엔드 유일 로그인 라우트) 에 `5 per 5 minutes`
- [ ] `/api/v1/coach/pair` (admin.py:2232) 에 `10 per hour`
- [ ] requirements pin 3.8.0 vs 설치 4.1.1 드리프트 확인 (API 차이 시 pin 갱신)
- [ ] 검증: wrong pw 6연속 curl → 6번째 429. 검증 후 재기동(이후 로그인 검증 잠금 해제)

### C-3. (백) user enumeration — 10m
- [ ] `api/admin.py:458,461` — "계정 없음"/"비밀번호 불일치" → 단일 메시지 "아이디 또는 비밀번호가 올바르지 않습니다"
- [ ] 계정 없을 때 더미 bcrypt 1회 (timing 균일화)
- [ ] 검증: 두 실패 케이스 응답 본문 동일

### C-1백. (백) 전화번호 형식 검증 — 15m
- [ ] `api/admin.py:668` self-signup + admin 등록 + CSV bulk-import 3경로에 010 정규식 (`^01[016789]-?\d{3,4}-?\d{4}$`, 하이픈 정규화 저장)
- [ ] 검증: invalid phone curl → 400 `INVALID_PHONE`

### E-7 (ride-along, P2→승격). SECRET_KEY prod fail-fast — 10m
- [ ] `app.py:102`·`models/profile.py:16` — `FLASK_ENV=production` 이고 SECRET_KEY 미설정이면 RuntimeError (한국어, fail-fast). 로컬은 fallback 유지
- [ ] 검증: env 빼고 FLASK_ENV=production 부팅 → 즉시 실패

### ✅ 체크포인트① — 백엔드 curl 스위트 (재기동 후 일괄)
- [ ] A-1 계약 200 / A-2 429 / C-3 동일 메시지 / C-1 400 / health 200

---

## 배치 2 — 앱 라우팅·인트로 클러스터 (한 플로우로 설계 후 일괄 수정)

### 플로우 확정 (선행 5m)
- [ ] 최종 신규 유저 플로우 합의: **Splash → (intro_seen=false) /intro → /signup → 가입신청 or 로그인 → /onboarding/basic → ... → /shell**

### B-2. 인트로 첫 실행 미노출 — 20m
- [ ] `splash_screen.dart:125-135` 분기 수정 — 로그인 전이라도 intro_seen=false 면 `/intro` 먼저
- [ ] intro `_finish()` 목적지를 `/signup`(로그인 전) / `/onboarding/basic`(로그인 후) 분기
- [ ] 검증: prefs 초기화 후 첫 실행 → 인트로 3p → Skip → 로그인 화면

### A-4. 신규 회원 가입 신청 배선 [P0] — 60~75m (v1 40m 보정)
- [ ] `signup_screen.dart` 에 "박스 가입 신청" 진입 버튼 추가 (소셜 2버튼·DEMO 리스트·약관 링크 구조 — 약관 위쪽이 자연스러움) → `/signup/self`
- [ ] `/onboarding/create-gym` — 결정2 권장안: 라우트·화면 명시적 비활성 처리 (주석 + 사유 기록, 방치 금지)
- [ ] `self_signup_screen.dart:127` — 성공 다이얼로그 이동 `/home` → `/shell` (참고: `/home` 라우트는 실존 — 크래시 아니고 하단 탭 셸 우회가 문제)
- [ ] 검증: 로그인 화면 → 가입 신청 화면 도달 → 빈값 제출 검증 토스트

### A-5①. 소셜 로그인 스텁 유지 + 진입 가드 [P0] — 30~40m
- [ ] `USE_REAL_AUTH` 류 플래그가 release 빌드에서 true 불가 가드 (assert or 빌드 분기)
- [ ] StaffLinkScreen(`/api/v1/auth/link-staff` 404 의존) 네비 진입점 차단/숨김
- [ ] 검증(열거형 — "전부 동작" 금지): 데모 로그인 OK / 박스 가입 신청 도달 OK / 소셜 실연동 버튼 비노출 또는 스텁 명시 확인

### B-3. 인트로 카피 재작성 — 30m
- [ ] `intro_screen.dart:21-48` — Primary value(수업 예약·박스 운영) 1~2p + 페이싱 +α 1p, V1~V11 준수
- [ ] CLAUDE.md 카피 템플릿 동시 갱신 ("Start." ↔ "Run it." drift 해소 — §0-B 같은 커밋)
- [ ] 완료 기준: **사용자 카피 승인** (v1 의 "템플릿 표와 일치"는 이 작업이 템플릿을 고치므로 순환 기준 — 교체)

### ✅ 체크포인트② — 디버그 fresh-install 플로우 1회
- [ ] prefs 초기화 → 인트로 → 가입신청 → 로그인 → 온보딩 → 셸 완주, 콘솔 예외 0
- [ ] **F-1 편승**: 같은 에뮬레이터 세션에서 WOD 126 [STRUCT-0609] 상세 → `_MovementRow` 렌더 screencap 확인 (전 세션 잔여. MSYS_NO_PATHCONV=1 주의)

---

## 배치 3 — 앱 self_signup 클러스터 + 진행률 (같은 파일 일괄)

### B-7. duplicate 분기 — 10m
- [ ] `self_signup_screen.dart:99-104` — `duplicate==true` 시 "이미 승인 대기 중" 별도 안내

### C-1앱. 전화번호 프론트 검증 — 10m
- [ ] `self_signup_screen.dart:229-231` — 정규식 검증 + 자동 하이픈

### E-3/E-4 (ride-along). 토큰화 + 어투 — 20m
- [ ] 하드코드 fontSize 16 ×2·Colors.white·radius 직접값 → FacingTokens
- [ ] "~해 주세요" → V1 명령형, V9 혼용 문장 수정 (create_gym 은 비활성 처리라 제외)

### B-1. 온보딩 진행률 "STEP 7/6 · 117%" — 20m
- [ ] `onboarding_benchmarks.dart:410-411` — `stepNumber = _page + 2`, 분모를 **7** 로 (basic 1 + 카테고리 6. 하드코드 "/6"은 414·433 2곳)
- [ ] `onboarding_basic.dart:62,66,91` — "STEP 1 / 6" → "/ 7" 동기화 + AppBar/본문 이중 표기 정리
- [ ] 검증: 마지막 BODY 페이지에서 "STEP 7 / 7 · 100%"
- [ ] 배치3 검증: 가입 플로우 1회로 B-7·C-1앱·E-3/4 통합 확인

---

## 배치 4 — 관리자 웹 (8081 로그인 세션 1회로 일괄)

### D-5a (승격: P1 묶음→최우선 분리). 로그인 프리필 제거 — 5m
- [ ] `login.html:42,47,49` — boss_seongsu/1234 value·힌트 제거 (공개 URL 에 실 크리덴셜 노출 — 사실상 P0급)
- [ ] 로그인 버튼 중복클릭 disabled — 5m

### A-3. 계약 PDF·QR 검증 404 [P0] — 20m
- [ ] `contracts.html:213` — `window.open('/api/v1/admin/contracts/${cid}/pdf')` → `/api/proxy/contracts/${cid}/pdf` (199-200행 미리보기와 동일 패턴. 프록시는 바이너리 Content-Type/Disposition 보존 확인됨 — app.py:446-451)
- [ ] `contracts.html:207` QR 검증 링크 — 백엔드 **공개 URL** 로 교체 (라우트 `/api/v1/contracts/<id>/verify` 는 백엔드 실재·무인증 — contracts.py:769. 프록시는 admin prefix+로그인 강제라 부적합). **전제: 백엔드 `BASE_URL` env (contracts.py:218,406 의존) — H-4 와 연동**
- [ ] 검증: 다운로드 클릭 → PDF 수신, QR URL curl → 200

### D-1. 계약 "수정" 버튼 무동작 — 15m
- [ ] `contracts.html:159` — onclick 인라인 JSON 주입 → `data-id` + 이벤트 위임 (variables 는 클릭 시 조회)
- [ ] 검증: 수정 모달 오픈, 콘솔 에러 0

### D-3 + C-1웹. members.html 묶음 — 20m
- [ ] `members.html:85` Jinja dict 인덱싱 → `.get(m.level, 'scaled')` fallback
- [ ] (백) level enum 검증 — 등록·PATCH·CSV 3경로 (배치1 에서 미처리 시 여기서)
- [ ] 등록 폼 전화번호 검증 + 저장 버튼 disabled
- [ ] 검증: level "Beginner" 행 있어도 /members 200

### D-4. SSE 토스트 XSS + scale_guide — 20m
- [ ] `_layout.html:268-271` — 회원발 payload innerHTML → textContent
- [ ] `wod.html:55` scale_guide 이스케이프
- [ ] 검증: `<img onerror>` 페이로드 쪽지 → 문자 그대로 표시 + **정상 토스트(공지·쪽지)도 여전히 표시** (정상 경로 회귀)

### E-13/E-14 (ride-along, 승격). 보안 최소셋 — 15m
- [ ] modal_preview.html 공개 서빙 차단 (1줄)
- [ ] X-Frame-Options: DENY + X-Content-Type-Options: nosniff (풀 CSP 는 회귀 위험 — 내일)

### ✅ 체크포인트③ — 8081 smoke
- [ ] 로그인(빈 폼 시작) → 회원 목록 → 계약 다운로드/수정 → WOD 게시 화면 → 콘솔 에러 0

### D-2. 박스 스위처 쿠키 (20m 타임박스) — 30m
- [ ] boss 계정(gym 1·7)으로 전환 → gym-scoped API 403 재현 시도
- [ ] 재현 시: `app.py:263` 블록에 백엔드 Set-Cookie 갱신 저장 1줄 (`session["backend_session_cookie"] = r.cookies.get("session") or 기존값`)
- [ ] **20m 내 재현 실패 시 P2 강등 + `[BLOCKED]` 메모 후 다음**

### D-5b. QR 외부 의존 제거 — 조건부 (입구 디스플레이를 론칭 첫 주 운영 시에만 오늘, 아니면 내일)
- [ ] `checkin.html:61-62` api.qrserver.com → 로컬 qrcode.js vendoring / 음수 타이머 백오프
- [ ] 검증: 외부망 차단 상태 QR 렌더

---

## 배치 5 — 크로스: B-5 회원 포인트 잔액 — 40~60m
- [ ] (백) `GET /api/v1/member/points` 신설 — `api/admin.py:862-883` (`admin_member_points`: coalesce(sum) 잔액 + 최근 이력) 로직 재사용, 인증만 X-Device-Id→GymMember(device_hash) 로. 모델 `models/member_point.py` MemberPoint
- [ ] (앱) 마이페이지 잔액 표기 ("+NP" 적립 토스트와 신뢰 일치)
- [ ] 검증: curl 잔액 ↔ 앱 표시 일치

## 배치 6 — 조건부: B-6 앱 계약 최소안 (60m 타임박스, 결정4)
- [ ] (백) 회원 계약 **목록** endpoint 신설 (현재 단건 GET+sign 만 — 목록 없음 실측)
- [ ] (앱) 마이페이지 → 내 계약 목록 → 상세 조회 (서명패드 제외 — sign API 는 `signature_image_base64` 필수라 "동의 버튼"으로 못 끝냄. 서명은 현장/대리 운영, 패드는 내일)
- [ ] 검증: 데모 회원 계약 목록·상세 200

## C-2. 데모 계정 시드 (G 직전 실행 — DB 파괴 주의) — 30m
- [ ] GymManager `admin/1234` 부팅 시드 추가 (bcrypt rounds=12, `models/base.py:144-181` seed_superadmin 패턴 참조 — AdminUser 는 로그인 경로와 단절돼 있어 GymManager 로)
- [ ] **fresh DB 에는 박스가 부팅 시드에 없음** (`seed_gym_managers` 는 "FACING SEONGSU" 없으면 skip — base.py:106-141) → admin 시드에 기본 박스 생성 포함 or 첫 박스에 연결
- [ ] 슈퍼씨드(APP_TEST_ADMIN_ID env) 도 GymManager 경로로
- [ ] 검증: **본 DB 백업 후** `FACING_DB` 임시 경로 fresh DB 부팅 → admin/1234 로그인 200 → 본 DB 복귀. 기존 DB 재부팅 시에도 시드 들어가는지 1회 확인 (§3-A: 모든 환경 의무)

---

## G. 최종 회귀 검증 (19:00~)
- [ ] G-1. (앱) `dart analyze` No issues + **`flutter test` 전체 green** (13개 테스트 파일 실존 — copy_lint_test 가 B-3 회귀망)
- [ ] G-2. (백) **`pytest tests/` 전체 green** (11개 파일 — test_api_contract_onsite 가 A-1 직접 커버) + 재기동 → 체크포인트① 재실행
- [ ] G-3. (웹) 체크포인트③ 재실행 + SSE 정상 토스트 확인
- [ ] G-4. (앱) **release 빌드 1회 통합 검증** — A-5 가드·B-4 결정 반영·신규 유저 플로우 완주 (인트로→가입신청→승인대기). 이 빌드는 로컬 기본 URL — 배포용 빌드는 H-1 별도
- [ ] G-5. **실 쓰기 smoke 3종** (QA 검증 한계 #1 해소 — 이게 남으면 "론칭 가능" 판정 근거가 빔): 수업 예약 POST→취소 POST 1세트 / QR 토큰 체크인 1건 / 'sent' 계약 서명 POST 1건 (A-1 수정 후). 각 200 + DB 행 확인
- [ ] G-6. (앱) 기존 회원 렌더 smoke — 홈/예약/출석/마이페이지 4화면 진입, 예외 0
- [ ] G-7. QA 보고서 P0/P1 해소 표기 갱신 + 이 문서 최종 갱신
- [ ] G-8. 양 repo 로컬 커밋 정리 (**push 금지 유지** — "배포해" 명시 시까지)

## H. 론칭 준비 — 코드 외 (G 와 병행 가능, 전부 실측 근거)
- [ ] H-1. **배포용 release APK**: `flutter build apk --release --dart-define=API_BASE_URL=https://service-facing-production.up.railway.app` → 산출물 보관 (설치·배포 금지). 검증: APK 내 railway URL 존재 + `10.0.2.2` 부재 (어제 2026-06-09 실사고 재발 방지). **G-4 검증 빌드와 별개 2회임**
- [ ] H-2. **release 서명이 debug key** (`android/app/build.gradle.kts:36-40` 실측) — 실 keystore 생성 + key.properties(gitignore) 교체, 오늘 불가 시 "debug 서명 직배포" 결정으로 명시 기록
- [ ] H-3. **앱 아이콘 = Flutter 기본 로고, 라벨 = "facing_app"** (AndroidManifest:11 실측) — 라벨 "FACING" 교체 + flutter_launcher_icons 브랜드 아이콘 + 버전 bump 결정 (현 0.1.17+3000 → 1.0.0?)
- [ ] H-4. 백엔드 프로덕션 env 점검 (콘솔 확인만, 배포 아님): SECRET_KEY(E-7 연동)·FLASK_ENV·**BASE_URL(A-3 QR 링크의 전제)**·CORS_ORIGINS·RATELIMIT_STORAGE_URI(멀티워커 시). 검증: admin.py:2308-2313 integration status 엔드포인트 read-only curl
- [ ] H-5. 프로덕션 DB 시나리오: 기존 DB + 신코드 재부팅 시드 동작(C-2 검증에 포함) / persona-* 테스트 데이터 프로덕션 혼입 점검
- [ ] H-6. `railway up` runbook 1단락 기재 (service-facing 은 GitHub 자동배포 미연결 — 수동). 배포 승인 떨어지면 즉시 실행 가능하게
- [ ] H-7. 개인정보처리방침 본문 검토 — self-signup 전화번호 수집 신설·서명 이미지·계약서 보관이 반영됐는지 (`privacy_screen.dart` 실존 — 내용만 검토)

---

## 내일 이관 (오늘 공식 제외 — "여력 시" 상태 폐지)
- E-1 Splash 지연 단축·죽은 슬롯 / E-2 출석 캘린더 hasError / E-5 BoxLeaderboard dead screen / E-6 빈 프로필 등급 / E-9 require_csrf 실적용 / E-10 중복클릭 방지(웹 잔여) / E-11 WOD placeholder 탭 / E-12 app.js 데드 함수 4종+미사용 partial / E-15 SSE 이모지 / E-16 meta·가치제안·v0.4 표기 / E-17 전용 랜딩 페이지 결정(신설 — QA P2 누락분) / B-6 서명패드 / D-5b(조건 미충족 시) / 풀 CSP
- ~~E-8 admin.py:1653 백슬래시~~ — **삭제: false positive** (재검증 결과 정상 슬래시 라우트, 바이너리 스캔 이상 없음)
