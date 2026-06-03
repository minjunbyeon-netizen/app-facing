# HANDOFF - 2026-06-03 22:32

## 완료 (이번 세션 — D26 소셜 로그인 실 구현 · 전부 로컬 커밋만 · 푸시 X)

### 백엔드 (services/facing)
- [x] `models/social_account.py` 신규 (provider+uid UNIQUE, `social_accounts.id` = user_id).
      `gym_managers.user_id` · `gym_members.user_id` 링크 컬럼 + `base._migrate` ALTER.
- [x] `api/auth.py` 실 구현 — `/auth/social`·`/logout`·`/me`:
      httpx 토큰검증(google tokeninfo · naver userinfo), social_account upsert,
      device_hash 익명데이터 흡수, role 결정(boss>coach>member>solo), 세션 수립
      (uid/role/gym_id + admin_* bridge), in-memory rate limit, audit. 키 미설정 시 503 fail-fast.
- [x] `/auth/link-staff` — 전환기 staff claim: 기존 login_id+PW 본인확인 → `GymManager.user_id`
      연결 → 이후 소셜 로그인 자동 boss/coach 분기. `_apply_session` 공용 헬퍼.
- [x] 버그수정 2건: ① `gym_coach_profiles` FK 가 `gym_managers(id)`(미존재 컬럼) 참조 →
      gym_managers UPDATE 시 'foreign key mismatch'. CREATE 수정 + 기존 DB 재생성 마이그레이션.
      ② autoflush=False 라 link 직후 `_resolve_role` 가 user_id 못 봄 → `s.flush()` 추가.
- [x] requirements.txt `httpx` 추가 (gevent §2-A-4).

### 앱 (apps/facing-app)
- [x] `RealSocialAuthService` (google_sign_in id_token / naver_login_sdk access_token →
      POST /auth/social → role 매핑). `resolveSocialAuthService` 팩토리 + `USE_REAL_AUTH` 플래그.
      ⚠️ `flutter_naver_login`(현 Flutter 호환X, Registrar 제거 API) → `naver_login_sdk ^3.2.1` 교체.
- [x] 네이버 로그인 콜백 120초 타임아웃.
- [x] `StaffLinkScreen` (`/auth/link-staff`) + MyPage 액션 진입점("코치·사장 계정 연결").
- [x] `ApiClient` 에 CookieManager(CookieJar) — 소셜 세션 쿠키 보관 + `sessionCookie()` 노출.
- [x] 사장 연결 시 소셜 세션을 `BossAuthState` 로 넘겨 **재로그인 없이 /boss/dashboard 직행**.
- [x] CSRF 헤더명 `X-CSRFToken` → `X-CSRF-Token` (서버·CORS 표준 통일).

### 검증
- [x] 백엔드: 부팅·마이그레이션 통과, 라우트(401/400/401/503/200), 모킹 happy path
      (solo→link(boss_seongsu/1234)→즉시 boss(다중박스)→재로그인 boss), **소셜 세션으로 /admin/me 200**.
- [x] 앱: `flutter analyze` 0 이슈 + `flutter build apk --debug` 성공.
- [x] 문서: AUTH_SOCIAL_DESIGN.md, NATIVE_AUTH_SETUP.md, ARCHITECTURE_BRIEF §10 D26 · §13.2.

## 진행중
- (없음)

## 대기 / 다음 단계 (실 OAuth 키 확보 후)
- [ ] **Google OAuth 키 발급** (Cloud Console — Android + Web client id 2개 + SHA-1).
      네이버 키(`NAVER_CLIENT_ID/SECRET`)는 `C:/dev/.env` 에 이미 존재.
- [ ] 키를 `--dart-define` 주입(`USE_REAL_AUTH=true`·`GOOGLE_SERVER_CLIENT_ID`·`NAVER_CLIENT_ID/SECRET`)
      → 실기기 실 로그인 1건 → 배포 1건. 절차: `apps/facing-app/docs/NATIVE_AUTH_SETUP.md`.
- [ ] (선택) 앱 재시작 시 소셜 세션(쿠키 in-memory) 소실 → 재로그인 1회 필요. 영속화 검토.
- [ ] (선택) `@require_csrf` 를 실제 admin mutation endpoint 에 부착(현재 정의만, 미적용).

## 결정사항 / 주의
- 🚫 **배포금지 유지**. 이번 세션 전부 로컬 커밋만 (auto-save 훅도 로컬). push X.
- 백엔드 로컬 5060 기동 중. 토큰검증 둘 다 httpx, 키 없으면 503 fail-fast.
- 사장 social→admin 인가 = 기존 admin_* 세션 bridge 재사용 (별도 JWT 신설 X).
- role 자동결정: gym_managers/members.user_id 링크 조회 → 없으면 solo. manager 는 coach 셸로 라우팅(admin bridge 는 실제 role 유지).

## 다음 세션 권장 첫 프롬프트
`/resume`
