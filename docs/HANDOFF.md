# HANDOFF - 2026-06-03 20:27

## 완료 (이번 세션 — D26 소셜 로그인 통일)

### apps/facing-app (로컬 커밋만 · .nopush · 푸시 X)
- [x] **회원·코치·사장 전원 소셜 로그인 통일 골격** (네이버·구글). 가짜 버튼 단계.
      - `lib/features/auth/social_auth_service.dart` 신규 — `SocialAuthService`(인터페이스)
        + `StubSocialAuthService`(가짜, role=solo). `SocialRole{boss,coach,member,solo}`·
        `SocialAuthResult`. 실 OAuth는 `RealSocialAuthService` 1개 교체로 활성.
      - `signup_screen.dart`: Kakao→Google 교체(네이버+구글). `_signIn`이 SocialAuthService
        호출→role로 자동분기(`_routeByRole`). 데모계정도 role 자동분기. Box Owner Login
        버튼 제거→하단 "사장 로그인 (전환기)" 작은 링크로 격하.
      - `core/theme.dart`: `googleSurface`·`googleBlue` 토큰 추가.
- [x] **수동 역할선택 화면 흐름 제거 + 파일 삭제**
      - `splash_screen.dart`·`onboarding_grade.dart` → shell 직행 (mode-select 분기 제거).
      - `mode_select_screen.dart`·`role_entry_screen.dart` 삭제. main.dart import·라우트
        (`/onboarding/mode`·`/role-entry`) 정리. `app_mode.dart` 주석 갱신.
- [x] **브리프(SSOT) 갱신** `docs/ARCHITECTURE_BRIEF.md`
      - D26 추가(전원 소셜 통일). D2·D3·§7 인증표에 "D26 대체" 표시.
      - §13.2에 `/auth/social`·`/auth/logout`·`/auth/me` 등록. §11.7에 신규 스키마
        (`social_account` 테이블·`user_id` ALTER)·env 등록.
- [x] 에뮬 검증: 로그인 화면 네이버·구글 정상 / 네이버 탭→역할화면 없이 온보딩 직행 /
      flutter analyze 0 이슈.

### services/facing (로컬 커밋만 · .nopush · 푸시 X)
- [x] **소셜 로그인 설계 문서** `docs/AUTH_SOCIAL_DESIGN.md` — 엔드포인트·요청응답·토큰
      서버검증(google id_token / naver userinfo)·role 결정 알고리즘·social_account 모델·
      device_hash link·세션(admin 패턴 재사용)·보안(OAuth2.1+PKCE)·env·stub→real 교체·체크리스트.
- [x] **스텁 라우트** `api/auth.py` — `/auth/social`·`/auth/logout`·`/auth/me` 501
      NOT_IMPLEMENTED. `api/__init__.py` 블루프린트 등록. 검증: health 200 · 3라우트 501 ·
      5060 LISTEN PID 1.

## 진행중
- (없음)

## 대기 / 다음 단계 (실 OAuth — 키 확보 후)
- [ ] **Google OAuth 키 발급** (Google Cloud Console). 네이버 키(`NAVER_CLIENT_ID/SECRET`)는
      `C:/dev/.env`에 이미 존재. → `GOOGLE_CLIENT_ID/SECRET`만 추가 필요.
- [ ] 백엔드 실 구현: `models/social_account.py` + base._migrate() 테이블·ALTER /
      `api/auth.py` 3 라우트 채우기 / google-auth·httpx 의존 추가 / role 결정·세션·audit·rate limit.
      → `services/facing/docs/AUTH_SOCIAL_DESIGN.md §9` 체크리스트.
- [ ] 앱 실 구현: `RealSocialAuthService` + `google_sign_in`·`flutter_naver_login` pubspec.
      화면·라우팅은 인터페이스 의존이라 변경 0줄.

## 결정사항 / 주의
- 🚫 **배포금지(facing-app)** 유지. 3개 레포 `.nopush`로 auto-push 차단 — 이번 세션 전부 로컬 커밋만.
- D26 = 회원·코치·사장 전원 소셜. device_hash는 데이터 연결키로 격하. 사장 ID/PW(Box Owner
  Login)는 전환기 fallback(하단 링크)으로만 유지 → 실 OAuth 시 제거 예정.
- role 자동결정: 서버가 gym_managers(boss/coach)·gym_members 연결 조회 → 없으면 solo.
- 세션은 기존 admin(Flask session+CSRF+bcrypt) 패턴 재사용 — 별도 JWT 신설 X.
- ⚠️ 실 구현 시 모듈 레벨에서 `jsonify`/`session` 호출 금지 (app context 에러 — 이번에 한 번 겪음).
- 백엔드 현재 로컬 기동중 (5060, task byjimtme5). 에뮬 facing-app 설치됨(네이버 stub 로그인 상태).

## 다음 세션 권장 첫 프롬프트
`/resume`
