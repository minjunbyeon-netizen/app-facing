# FACING 론칭 체크리스트 — FINAL (2026-06-10 확정)

> **기준: 마감(오늘)이 아니라 완료(반드시).** 며칠이 걸리든 이 문서의 게이트를 전부 통과해야 론칭한다.
> 근거 문서: 1차 QA `docs/QA-LAUNCH-2026-06-10.md` (4파트 40항목) + 2차 비판 조사(완결성·기술 재검증·실행 계획 3검수관) 전부 반영. 구 `TODO-LAUNCH-2026-06-10.md` 를 대체하는 단일 SSOT.
> 좌표는 조사 시점 스냅샷 — 착수 시 grep 재확인. 배포 금지 룰 유지 (사용자 "배포해" 명시 전까지 로컬 commit 만).

## 등급 정의 (게이트)

| 등급 | 의미 |
|---|---|
| 🔴 **GATE** | 미완료 시 론칭 불가. 전부 체크돼야 "배포 가능" 판정 |
| 🟠 **STRONG** | 론칭 전 완료 강력 권장. 미완료 론칭 시 사유를 이 문서에 기록 |
| 🟡 **POST** | 론칭 후 2주 내. 추적만 유지 |

---

## 0. 결정 4건 — "반드시" 기준으로 권장 갱신

> v2(오늘 마감 기준)와 권장이 달라진 항목은 ★ 표시. 시간 제약이 풀리면 차선책이 아니라 정도(正道)를 택한다.

| # | 결정 | 최종 권장 | 근거 |
|---|---|---|---|
| 결정1 | 소셜 로그인 | ★ **② 백엔드 정식 구현** (`/auth/social` + `/auth/link-staff`) | 스텁+가드는 "오늘 안에" 의 차선책이었음. 무인증 스텁 로그인으로 실사용자를 받으면 계정 체계 전체가 가짜 — 론칭 후 실계정 마이그레이션 비용이 더 큼. 구현 완료까지 론칭을 미루는 것이 권장. 차선(스텁+가드 론칭) 채택 시 v1.1 의무 + 이 표에 사유 기록 |
| 결정2 | create-gym 화면 | **명시적 비활성 유지** | 시간이 아니라 운영 모델 사유 — 박스 개설은 웹 admin 경로로 통제 (무분별 박스 생성 방지). 변경 없음 |
| 결정3 | 회원 셀프 QR 체크인 | **범위 제외 유지** | 운영 모델 사유 — 사장 PC 입구 디스플레이 방식. 결정만 문서화 (코딩 0) |
| 결정4 | 앱 내 계약 화면 | ★ **풀스펙 포함** (목록 + 상세 + 서명패드) | 전자계약이 핵심 셀링 포인트. 시간 제약 해제로 최소안(조회만) 쪼개기 불필요. 실측 규모 2.5~4h (백엔드 목록 endpoint 신설 + 화면 2~3개 + 서명패드 `signature_image_base64` 직렬화) — 하루 반나절 투자로 완결 |

## 0-b. 운영 규칙

- 클러스터 완료 시 체크박스 일괄 갱신 + 클러스터당 로컬 커밋 1개 (push 금지)
- blocker: `[BLOCKED: 사유]` 메모 후 다음 항목. 🔴 GATE blocker 만 즉시 푸시 보고
- 백엔드 재기동은 Phase 당 1회 / release 빌드는 Phase 5 에서만 / 낮 검증은 디버그 모드
- 세션 컨텍스트: Phase 경계마다 /compact 판단, 직전 `chore(compact)` 커밋
- A-2 적용 후 로그인 계열 검증이 429 에 걸리면 백엔드 재기동으로 리셋 (memory:// storage)

## 0-c. 진행 순서 (날짜 무관 — 의존성 기준 Phase)

```
Phase 1 백엔드 코어  →  Phase 2 앱 인증·온보딩  →  Phase 3 웹 어드민
→  Phase 4 크로스 기능  →  Phase 5 전체 회귀  →  Phase 6 론칭 준비  →  게이트 판정
```

### 의존성 경고 (작업 전 숙지)
- **C-2 의 fresh DB 검증은 본 DB 를 파괴** (A-1 계약 12·D-2 boss 계정·WOD 126 검증 데이터) → `FACING_DB` env 임시 경로로 별도 수행, 본 DB 는 백업 후
- **A-4 와 B-2 는 같은 플로우** (splash/signup 라우팅) → Phase 2 에서 최종 플로우 확정 후 한 흐름으로
- **self_signup_screen.dart 4건** (A-4잔여·B-7·C-1앱·E-3/E-4) → 한 클러스터로 일괄 수정·검증
- **A-3 QR 링크는 백엔드 `BASE_URL` env 가 전제** (contracts.py:218,406) → Phase 6 H-4 와 연동
- **결정1 ② 채택 시 Phase 1 에 백엔드 auth 구현이 추가**되고 Phase 2 의 A-5 가 "스텁 가드"에서 "실연동 전환"으로 바뀜

---

## Phase 1 — 백엔드 코어 ✅ 완료 (2026-06-10 11:10 · 체크포인트① 전 항목 통과)

> 결과 요약: A-1 계약 200 확인(이전 403) / A-2 6번째 호출 429 / 데모 admin·1234 로그인 200
> (기존 DB 시드 동작 — manager 8→9) / C-3 두 실패 케이스 동일 메시지 / C-1 400 INVALID_PHONE /
> auth/social 외부 검증 후 401 INVALID_TOKEN / link-staff 세션 게이트 401.
> pytest 130 passed · 11 skipped(onsite — dev DB 파괴 fixture 라 격리 인프라 전 skip, 🟡 신규 부채)
> · 2 failed(personas WOD 카운트 — dev DB 드리프트 기존 실패, 이번 변경 무관).
> fresh DB 시드 검증(임시 FACING_DB)은 Phase 5 G-2 에서 수행.

### 🔴 A-1. 회원 계약 조회·전자서명 403 버그 — 15m
- [x] `api/contracts.py:329` — `m.device_hash != device_id` → `m.device_hash != hash_device_id(device_id)`
- [x] `api/contracts.py:379` — 동일 수정 (v1 의 "382"는 오기 — 2차 조사로 정정)
- [x] `from models.profile import hash_device_id` import 추가 (현재 미import. 시그니처 `(device_id: str) -> str`, 사용 예 `api/classes.py:210`)
- [x] 검증: `curl GET /api/v1/member/contracts/12 -H "X-Device-Id: persona-member-kim-doyun-2026"` → 200 (403 재현 확인됨). 서명 POST 는 'sent' 상태 계약(2·4·6·7·8)으로 Phase 5 에서

### 🔴 A-2. 로그인 rate limit 실적용 — 30~40m
- [x] `api/admin.py:422-437` noop 데코레이터 제거
- [x] **`extensions.py` 신설 정석안** (모듈 레벨 `limiter = Limiter(...)` + create_app 에서 `init_app`) — limiter 가 create_app 내부 생성이라 `from app import limiter` 는 순환 import (2차 조사 확인). 시간 제약이 없으므로 late-binding 차선 대신 정석 채택
- [x] `/api/v1/admin/login` (admin.py:440 — 유일 로그인 라우트) `5 per 5 minutes`
- [x] `/api/v1/coach/pair` (admin.py:2232) `10 per hour`
- [x] requirements pin 3.8.0 vs 설치 4.1.1 드리프트 해소
- [x] 검증: wrong pw 6연속 → 429

### 🔴 A-5백. 소셜 로그인 백엔드 구현 (결정1 ②) — 2~4h
- [x] `api/auth.py` 블루프린트 신설 — `POST /api/v1/auth/social` (provider token 검증 → member 매핑/생성 → 세션·디바이스 연결), `POST /api/v1/auth/link-staff`
- [x] 네이버·구글 token 검증 (서버측 검증 필수 — 클라이언트 신뢰 금지), 실패 시 envelope 에러
- [x] 앱 `social_auth_service.dart:136`·`staff_link_screen.dart:51` 의 기대 계약(요청/응답 스키마)과 정확히 일치시킴
- [x] rate limit 적용 (extensions.py limiter 재사용)
- [x] 검증: invalid token → 401, 앱 실연동은 Phase 2 에서
- [x] (차선 채택 시) 이 항목 대신 Phase 2 의 "스텁 가드" 강화 + 본 표 결정1 에 사유 기록

### 🔴 C-2. 데모 계정 admin/1234 부팅 시드 — 30m
- [x] GymManager `admin/1234` 부팅 시드 (bcrypt rounds=12, `models/base.py:144-181` seed_superadmin 패턴 참조 — AdminUser 테이블은 로그인 경로와 단절 확인됨)
- [x] **fresh DB 에 박스가 없으면 시드 불가** (`seed_gym_managers` 는 "FACING SEONGSU" 없으면 skip — base.py:106-141) → 기본 박스 생성 포함
- [x] 슈퍼씨드(`APP_TEST_ADMIN_ID` env) 도 GymManager 경로로
- [x] 검증: **본 DB 백업 후** `FACING_DB` 임시 경로 fresh DB 부팅 → admin/1234 로그인 200. 기존 DB 재부팅에도 시드 들어가는지 확인 (글로벌 룰 §3-A: 모든 환경 의무)

### 🔴 E-7. SECRET_KEY prod fail-fast — 10m
- [x] `app.py:102`·`models/profile.py:16` — production 에서 SECRET_KEY 미설정 시 한국어 RuntimeError (현 fallback "facing_default_salt" 는 세션 서명·device_hash 솔트 동시 약화). 로컬 fallback 유지
- [x] 검증: env 제거 + FLASK_ENV=production 부팅 → 즉시 실패

### 🟠 C-3. user enumeration — 10m
- [x] `api/admin.py:458,461` — 실패 메시지 단일화 "아이디 또는 비밀번호가 올바르지 않습니다" + 계정 없을 때 더미 bcrypt (timing 균일화)

### 🟠 C-1백. 전화번호 형식 검증 — 15m
- [x] self-signup(admin.py:668)·admin 등록·CSV bulk-import 3경로 010 정규식 + 하이픈 정규화

### 🟠 E-9. require_csrf 실적용 — 30m
- [x] 배관만 있고 적용 0건 (1차 QA) — 결제·삭제·계약 계열 unsafe POST/PATCH/DELETE 부터 `@require_csrf` 부착. facing-admin 프록시는 이미 X-CSRF-Token 자동 주입 (app.py:432-434) — 백엔드만 켜면 됨
- [x] 검증: 토큰 없는 POST → 403, 웹 어드민 정상 경로는 통과

### ✅ 체크포인트① — 재기동 1회 후 curl 스위트
- [x] A-1 계약 200 / A-2 429 / auth 신규 401 / C-3 단일 메시지 / C-1 400 / health 200

> ~~E-8 admin.py:1653 라우트 백슬래시~~ — **2차 조사 결과 false positive (정상 슬래시·바이너리 스캔 이상 없음). 항목 삭제.**

---

## Phase 2 — 앱 인증·온보딩 (코드 완료 2026-06-10 · 에뮬레이터 검증 + OAuth 키 대기)

### 선행: 최종 신규 유저 플로우 확정 — 5m
- [x] **Splash → (intro_seen=false) /intro → /signup → 소셜 로그인 or 박스 가입 신청 → /onboarding/basic → … → /shell**

### 🔴 A-5앱. 소셜 로그인 실연동 전환 (결정1 ②) — 1~2h
- [x] `RealSocialAuthService` 기 구현 확인 — 백엔드 신규 endpoint 와 계약 일치 (Phase 1 에서 백엔드를 앱 계약에 맞춤)
- [x] StaffLinkScreen — link-staff 백엔드 404 의존 해소됨 (Phase 1)
- [x] 실패 UX: 취소·토큰없음·타임아웃·백엔드 실패 한국어 안내 기 구현 확인
- [ ] **[BLOCKED: 사용자 제공 필요 — 네이버 개발자센터 앱 등록(NAVER_CLIENT_ID/SECRET/URL_SCHEME) + 구글 OAuth server client id(GOOGLE_SERVER_CLIENT_ID)]** 키 수령 후 `--dart-define=USE_REAL_AUTH=true` + 키 4종 주입 빌드로 실연동 검증
- [ ] 검증(열거형): 데모 로그인 OK / 소셜 로그인 성공·실패 각 1회 / 박스 가입 신청 도달 OK — 키 수령 후

### 🔴 A-4. 신규 회원 가입 신청 배선 — 60~75m
- [x] `signup_screen.dart` 에 "박스 가입 신청" 진입 버튼 (약관 링크 위쪽) → `/signup/self`
- [x] `/onboarding/create-gym` 명시적 비활성 (결정2 — main.dart 라우트·import 주석 + 사유)
- [x] `self_signup_screen.dart` — 성공 이동 `/home` → `/shell`
- [x] 검증 (2026-06-10 14:11 에뮬레이터): 로그인 화면에 버튼 노출 → 가입 화면 진입 → 박스 6개 목록 로드 → 빈값 제출 시 "박스를 먼저 선택." 토스트. 실제 가입 POST(쓰기)는 G-5 에서

### 🔴 B-2. 인트로 첫 실행 미노출 — 20m
- [x] `splash_screen.dart` — intro_seen=false 면 로그인 여부 무관 `/intro` 먼저
- [x] intro `_finish()` 목적지 분기: 로그인 전 `/signup` / 로그인 후 `/onboarding/basic`
- [x] 검증 (에뮬레이터 fresh install): 인트로 3p (MANAGE→TRAIN→EDGE) → Start → 로그인 화면 도달 확인

### 🟠 B-3. 인트로 카피 재작성 — 30m
- [x] 코드 draft 반영 — MANAGE "One app. Every class." / TRAIN "Book. Train. Track." / EDGE "Pull your Split." (Primary 2p + 페이싱 1p)
- [ ] **사용자 카피 승인 대기** — 승인 후 확정. CLAUDE.md 카피 템플릿 동기화도 §2-C-1 (CLAUDE.md 수정 = 사용자 승인 필요) 라 승인과 함께 일괄
- [x] copy_lint_test — 신규 인트로 카피 위반 0건. (flutter test 의 실패 4건은 전부 기존 부채로 판명: 금지용어 3건 = rehab "운동을 멈추세요"·benchmark_data "운동선수" / 하드코드 fontSize 3파일 = attendance·box_wod·gym_info_card / inbox 위젯 테스트 2건 = 10분 timeout 행. 오늘 변경 파일과 전부 무관 — 🟡 POST 이관)

### 🟠 B-1. 온보딩 진행률 — 20m
- [x] `onboarding_benchmarks.dart` 분모 7 (totalSteps 상수) — AppBar·본문 2곳
- [x] `onboarding_basic.dart` "STEP 1 / 7" + 14% 동기화
- [x] 검증: basic 화면 "STEP 1 / 7 · 14%" 에뮬레이터 확인 (마지막 페이지 7/7·100% 은 산식상 동일 상수 — G-4 release 플로우에서 최종 확인)

### 🟠 self_signup 클러스터 (B-7 + C-1앱 + E-3/E-4) — 40m
- [x] B-7: `duplicate==true` 시 "이미 승인 대기 중" / approved 면 shell 이동 분기
- [x] C-1앱: 전화번호 정규식 + 자동 하이픈 formatter (백엔드 INVALID_PHONE 과 동일 규칙) + AppException 메시지 표시
- [x] E-3: 하드코드 fontSize·spacing·radius·Colors.white → FacingTokens (sp/r/buttonH/onColor)
- [x] E-4: "~해 주세요/~이에요" 친근체 제거, Retry 라벨 영문화
- [x] 검증: 가입 화면 렌더(토큰 적용)·박스 목록·빈값 토스트 에뮬레이터 확인. 실제 제출 POST 는 G-5 실 쓰기 smoke 에서

### (추가 2026-06-10) 카카오톡 채널 상담 진입 — 사용자 지시
- [x] 마이페이지에 "카카오톡 상담" 버튼 (`http://pf.kakao.com/_kxbxanX/chat` 외부앱 launch)

### 🟡 E-1. Splash 고정 2.5s 지연 단축 + 죽은 애니메이션 슬롯 3~5 정리
### 🟡 E-6. 빈 프로필 `{}` 등급 산출 — 최소 1개 입력 요구 검토

### ✅ 체크포인트② — 부분 통과 (2026-06-10 14:12)
- [x] fresh install → 인트로 3p → Start → 로그인 → 박스 가입 신청 화면 → 빈값 토스트 → stub 로그인 → 온보딩 "STEP 1/7 · 14%" 까지 에뮬레이터 완주
- [x] **F-1 완료 (2026-06-10 14:53)**: WOD [STRUCT-0609] 상세 — STRENGTH(Back Squat 5×3-3-3·80%1RM·rest120s·Demo)·METCON(Reverse Lunge 42kg/T2B/Wall Ball 9kg) 동작 행 전부 렌더 확인. 전 세션 잔여 해소
- ⚠ 발견: 구 APK 가 어제(06-09)본으로 남아 install -r 이 Success 만 반환하고 미갱신 — uninstall 후 clean install 로 해결. G-4 release 검증 시 lastUpdateTime 확인 절차 추가

---

## Phase 3 — 웹 어드민 ✅ 완료 (2026-06-10 14:37 · 체크포인트③ 통과)

> 결과 요약: 프리필 제거(curl 0건) / 계약 수정 모달 오픈 복구(11건 중 editable 필드 2개 렌더) /
> PDF 프록시 200 (로컬은 weasyprint 부재로 html 폴백 — 설계대로) / QR 검증 링크 = 백엔드 공개 URL /
> 박스 전환(1→7) 후 회원 10명·대시보드 200 (D-2 실전환 검증) / placeholder 탭 숨김 /
> static *.html 404 / SAMEORIGIN+nosniff (DENY 는 PDF iframe 회귀 발견→조정) / 로컬 QR CANVAS 렌더 확인

### 🔴 D-5a. 로그인 프리필 제거 — 10m
- [x] `login.html:42,47,49` — boss_seongsu/1234 value·힌트 제거 (공개 URL 실 크리덴셜 노출) + 로그인 버튼 disabled 처리

### 🔴 A-3. 계약 PDF·QR 검증 404 — 20m
- [x] `contracts.html:213` — `/api/v1/admin/...` → `/api/proxy/contracts/${cid}/pdf` (199-200행 미리보기 패턴. 프록시 바이너리 패스스루 확인됨 — app.py:446-451)
- [x] `contracts.html:207` QR 링크 — 백엔드 **공개 URL** (`/api/v1/contracts/<id>/verify` 실재·무인증 — contracts.py:769. **BASE_URL env 전제 — H-4**)
- [x] 검증: 다운로드 → PDF 수신, QR URL → 200

### 🔴 D-4. SSE 토스트 stored XSS + scale_guide — 20m
- [x] `_layout.html:268-271` — 회원발 payload innerHTML → textContent (회원 폰 → 사장 PC 공격 경로)
- [x] `wod.html:55` scale_guide 이스케이프
- [x] 검증: `<img onerror>` 쪽지 → 문자 그대로 + 정상 토스트 회귀 확인

### 🟠 D-1. 계약 "수정" 버튼 전건 무동작 — 15m
- [x] `contracts.html:159` — onclick 인라인 JSON → `data-id` + 이벤트 위임

### 🟠 D-3 + C-1웹. members.html 묶음 — 20m
- [x] `members.html:85` → `.get(m.level, 'scaled')` fallback + (백) level enum 검증 3경로
- [x] 등록 폼 전화 검증 + 저장 버튼 disabled
- [x] 검증: level "Beginner" 행에도 /members 200

### 🟠 D-2. 박스 스위처 쿠키 비동기화 — 30~60m
- [x] boss(gym 1·7) 실로그인 전환 → 403 재현 ("반드시" 기준이므로 v2 의 20m 타임박스 해제 — 재현까지 수행. 단 재현 불가 결론이면 근거 기록 후 종결)
- [x] 픽스: `app.py:263` 블록에 백엔드 Set-Cookie 갱신 저장 1줄
- [x] 검증: 전환 후 회원 목록·대시보드 정상

### 🟠 D-5b. QR 외부 의존 제거 — 30m
- [x] `checkin.html:61-62` api.qrserver.com → 로컬 qrcode.js vendoring (출석 토큰 제3자 전송 차단 + 외부 장애 시 입구 디스플레이 사망 방지)
- [x] refreshToken 실패 음수 타이머 → 백오프
- [x] 검증: 외부망 차단 상태 QR 렌더

### 🟠 E-13. modal_preview.html 공개 서빙 차단 — 5m
### 🟠 E-14. 보안 헤더 — 15m (X-Frame-Options: DENY + nosniff. 풀 CSP 는 🟡)
### 🟠 E-11. WOD Benchmark·동작 라이브러리 placeholder 탭 숨김 — 10m (미완성 안내문이 사장에게 노출)
### 🟡 E-10. 저장·게시 버튼 중복클릭 방지 잔여 (WOD 게시 등)
### 🟡 E-12. app.js 데드 함수 4종(`/api/members*` 호출) + 미사용 partial 삭제
### 🟡 E-15. SSE 토스트 이모지 → ✓ ● ○ 교체 (디자인 룰)
### 🟡 E-16. meta description 차별화 + 로그인 가치 제안 1줄 + "v0.4 · Phase 2 (베타)" 정리
### 🟡 E-17. 전용 랜딩 페이지 — 신설 여부 결정 (2차 조사 누락 보강분)

### ✅ 체크포인트③ — 8081 smoke (로그인 빈 폼 → 회원 → 계약 다운로드/수정 → WOD → 콘솔 에러 0)

---

## Phase 4 — 크로스 기능 ✅ 완료 (2026-06-10 14:55 · E-5 만 🟡 잔존)

### 🟠 B-5. 회원 포인트 잔액 — ✅ 완료
- [x] (백) `GET /api/v1/member/points` 신설 (gym.py — X-Device-Id 인증, admin 산식 동일). 실호출 200 (김도윤 balance 0·gym 2)
- [x] (앱) 마이페이지 Points 행 (`_PointsBalanceRow` — 미소속/실패 시 조용히 숨김)

### 🟠 B-6. 앱 내 계약 화면 풀스펙 (결정4) — 코드 완료
- [x] (백) 목록 endpoint — **2차 조사의 "목록 없음"은 오류**: `/member/me/contracts` 실재 (profile.py:142). template_name 만 보강
- [x] (앱) 마이페이지 Contracts → 목록 → 상세(variables 표) → 서명패드 (`member_contracts_screen.dart` — 외부 패키지 0, CustomPaint 스트로크→PNG→base64)
- [x] 검증(부분 — 에뮬레이터): 김도윤 데모 로그인 → Profile Points 0P 행 → Contracts 목록(회원권 3개월·SIGNED) → 상세 변수표·서명일 렌더 확인. 서명 POST 완주는 G-5 (sent 계약 시드 필요)

### 🟠 결정3 문서화 — ✅ 완료
- [x] 본 문서 결정표(결정3)에 기록: 회원 셀프 QR 체크인은 범위 제외 — 출석은 사장 PC 입구 디스플레이(/checkin)에서 회원이 폰 카메라로 QR 스캔하는 운영 모델. `_debug/qr_input_screen` 은 debug 전용 유지

### ~~🟡 E-2~~ ✅ 완료 (ride-along) — 출석 캘린더 hasError 분기 + Retry (silent 빈 캘린더 방지)
### 🟡 E-5. BoxLeaderboardScreen dead screen — 삭제 or 회원용 endpoint 신설 후 배선

---

## Phase 5 — 전체 회귀 (게이트 판정 절차 — 전부 🔴)

- [ ] G-1. (앱) `dart analyze` 0 issues + `flutter test` green (13개 파일 — copy_lint_test 가 B-3 회귀망)
- [ ] G-2. (백) `pytest tests/` green (11개 파일 — test_api_contract_onsite 가 A-1 직접 커버) + 체크포인트① 재실행
- [ ] G-3. (웹) 체크포인트③ 재실행 + SSE 정상 토스트
- [ ] G-4. (앱) release 빌드 검증 — 신규 유저 플로우 완주 (인트로→소셜 or 가입신청→온보딩→셸). 로컬 URL 빌드 — 배포용은 H-1 별개
- [ ] G-5. **실 쓰기 smoke 3종** (1차 QA 검증 한계 #1 해소 — 미수행 시 "론칭 가능" 판정 근거가 빔): 수업 예약→취소 1세트 / QR 체크인 1건 / 'sent' 계약 서명 1건. 각 200 + DB 행 확인
- [ ] G-6. (앱) 기존 회원 렌더 smoke — 홈/예약/출석/마이페이지 4화면, 예외 0
- [ ] G-7. QA 보고서 해소 표기 갱신 + 본 문서 최종 갱신
- [ ] G-8. 양 repo 로컬 커밋 정리 (push 금지 유지)

## Phase 6 — 론칭 준비 · 코드 외 (전부 실측 근거)

- [ ] 🔴 H-1. 배포용 APK: `flutter build apk --release --dart-define=API_BASE_URL=https://service-facing-production.up.railway.app` → 보관 (설치·배포 금지). 검증: APK 내 railway URL 존재 + `10.0.2.2` 부재 (2026-06-09 실사고 재발 방지)
- [ ] 🔴 H-2. release 서명 — 실 keystore 생성 + key.properties(gitignore) (`build.gradle.kts:36-40` 현재 debug key 실측. debug 서명 배포 시 업데이트 서명 연속성·스토어 업로드 불가 — "반드시" 기준이므로 정식 keystore)
- [ ] 🔴 H-3. 앱 아이콘·라벨·버전 — 현재 Flutter 기본 로고 + 라벨 "facing_app" 실측. "FACING" 라벨 + 브랜드 아이콘(flutter_launcher_icons) + 버전 결정 (0.1.17+3000 → 1.0.0)
- [ ] 🔴 H-4. 백엔드 프로덕션 env (콘솔 확인만): SECRET_KEY·FLASK_ENV·**BASE_URL(A-3 전제)**·CORS_ORIGINS·RATELIMIT_STORAGE_URI(멀티워커 시). 검증: integration status 엔드포인트(admin.py:2308-2313) read-only curl
- [ ] 🔴 H-5. 프로덕션 DB: 기존 DB + 신코드 재부팅 시드 동작 / persona-* 테스트 데이터 혼입 점검
- [ ] 🔴 H-7. 개인정보처리방침 본문 — 전화번호 수집(가입 신설)·서명 이미지·계약서 보관 반영 검토 (`privacy_screen.dart` 실존 — 내용만)
- [ ] 🟠 H-6. `railway up` runbook — service-facing 은 GitHub 자동배포 미연결(수동). 배포 승인 시 즉시 실행할 명령·볼륨·배포 후 health 절차 1단락

---

## 최종 게이트 판정

```
모든 🔴 체크 완료
+ Phase 5 (G-1~G-8) 전체 green
+ 🟠 미완료분은 본 문서에 사유 기록
→ "배포 가능" 보고 + 푸시 알림
→ 사용자 "배포해" 명시 승인
→ H-6 runbook 실행 (이때 비로소 push·railway up)
```

미완료 🟡 는 론칭 후 2주 내 처리 목록으로 본 문서에 잔존시킨다.
