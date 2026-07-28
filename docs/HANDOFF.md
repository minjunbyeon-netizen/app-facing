# HANDOFF - 2026-07-28 22:28

## 완료 (전부 검증 포함)
- [x] **v1.29 디자인 SSOT** — `docs/DESIGN-SSOT.md` 신설 (타이포·굵기 4단·간격·모서리·FKit 규격·카피 규칙). CLAUDE.md 디자인/카피 섹션이 이 문서로 위임.
- [x] **전면 한글화** — lib/ 전체 약 250개 라벨 (도메인 용어 WOD·RX·1RM·Engine·POWER 등 카테고리·벤치마크명은 영문 유지). appkit strings 한글 스킨(`appkit.config.json` → sync). 구 Voice V1~V11 폐기.
- [x] **로그인·로딩 통일** — BrandLogo 기본 폭 220 전 진입화면, FkLoadingScreen/FkSocialButton FKit 추가, 사장 로그인·직원 연결 화면 통일.
- [x] **네이버 로그인 준비** — RealSocialAuthService 기배선 확인, `env.json.example` 템플릿 (.gitignore 에 env.json). 키 등록만 남음 (`docs/NATIVE_AUTH_SETUP.md`).
- [x] **폰 클린 재설치 검증** — 갤S22 (192.168.1.100:39711, mDNS 로 재발견 가능). 잔재 6건 수정.
- [x] **앱↔백엔드 교차검증** — 계약 85경로 미스매치 0, RBAC 403 4종, admin/1234·boss_seongsu/1234 분리.
- [x] **claim 플로우 (이음새 1) 구현+배포+E2E** — backend `services/facing/api/claim.py` + `models/member_claim.py` + tests/test_claim.py (7 green) + 앱 `/signup/claim` 화면 + PC 어드민 회원상세 "앱 연결 코드" 버튼. **프로덕션 E2E 성공** (코드 발급→폰 입력→연결→재발급 시 ALREADY_LINKED). 상세: `services/facing/docs/ONBOARDING_FLOW.md §4`.
- [x] **PC WOD→회원 노출 + 쪽지 왕복** — PC 어드민 WOD 게시 → 폰 노출 ✓, 회원→코치 메시지 ✓, 코치→회원 답장 폰 수신 ✓. 테스트 데이터 삭제 완료.
- [x] 배포: service-facing + web-facing-admin (railway up). **web-facing-admin 에 SECRET_KEY env 필수** — 미설정으로 1회 실패 후 주입·성공.

## 진행중
- (없음 — 모든 착수 작업 완료 상태에서 인계)

## 대기 (다음 세션 후보)
- [ ] PC 어드민 "회원 메시지" 페이지 — 회원이 보낸 쪽지를 코치가 PC 에서 읽고 답장 (현재 API 만 있음: GET `/api/v1/gym/{id}/messages`·`/threads`, 코치 폰만 UI 보유). ⭐ 첫 도입 업체 필수 후보
- [ ] WOD 게시 시 회원 폰 푸시 알림 (현재 새로고침/재진입 필요. SSE 는 발행 중 — FCM 연결 후보)
- [ ] 네이버 실 로그인 — 사용자가 Naver Developers 앱 등록 후 `env.json` 채우면 켜짐
- [ ] 잔여 영문 소소 2건 — 프로필 "Support (KakaoTalk)" 라벨, 로그아웃 다이얼로그 내 "Privacy Policy → Delete Account" 문구
- [ ] 백엔드 test_personas_e2e 2건 실패 — 로컬 dev DB 드리프트 (coach_b 13≠12, member_b1 15≠13). claim 무관 확인됨. personas.json 카운트 갱신 또는 리시드로 해소

## 결정사항 / 주의
- **배포 승인 이력**: 사용자가 "추천안대로" 채택하며 배포 승인 → service-facing·web-facing-admin railway up 실행됨. **facing-app(앱) 레포는 push 안 함** — 로컬 커밋만 (배포 금지 룰 유지, "배포해" 키워드 대기).
- **회원 행 이원화 함정**: PC 등록 회원과 실기기 회원은 별개 gym_members 행. 쪽지 target 은 실기기 행 device_hash. 해소책 = claim 코드. 메모리 `project-crosscheck-rbac-2rows.md` 참조.
- **backend 재배포 시 시드 재실행** — 오늘자 WOD 2건(AMRAP·FRAN)이 자동 생성됨 (seed_personas).
- **폰 자동화**: 화면 꺼짐(15197바이트 블랙 캡처) 시 WAKEUP+dismiss-keyguard. 한글 adb input 불가 — 영문만.
- 골든 19장 + 갤러리(`python tool/golden_gallery.py`) + 테스트 127 green 상태로 인계.

## 다음 세션 권장 첫 프롬프트
`/resume` — 이후 "PC 어드민 회원 메시지 페이지 만들어" (대기 1순위)
