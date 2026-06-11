# HANDOFF - 2026-06-11 15:45

## 완료 (이번 세션)
- [x] **론칭 게이트 통과** — `docs/LAUNCH-CHECKLIST.md` Phase 1~6 전부 ✅. Phase 5 회귀에서 CLASSES dead screen P0 발견·픽스(전역 버튼 minimumSize ∞ × Row), G-5 실 쓰기 smoke 3종(예약→취소·QR 체크인·sent 계약 서명패드 완주) 통과
- [x] **Phase 6 산출물** — 배포용 APK `dist/facing-1.0.0+3001-prod.apk`(railway URL·release 서명 검증), keystore `android/app/facing-release.keystore` + `android/key.properties`(gitignore), 라벨 "FACING"·버전 1.0.0+3001·브랜드 아이콘, 배포 runbook `services/facing/docs/RUNBOOK-DEPLOY.md`
- [x] **콘텐츠 TODO 전소** — `docs/LAUNCH-CONTENT-TODO.md` P0 5/5·P1 8/8·P2 11/11. 약관(앱 TermsScreen + 웹 /terms)·탈퇴 DELETE /member/me·FAQ 10문답·거절 재신청(rejected→pending)·페어링 72h TTL(컬럼 마이그레이션)·알림톡 발송 로그·동작 라이브러리 탭·copy_lint 부채 전소(테스트 110 green)
- [x] **facing-web 마케팅 랜딩 신설+배포** — `C:\dev\web\facing-web` (workcheck-web 구조·논리 복제). GitHub `web-facing` private + **Railway 배포 완료**: https://web-facing-production.up.railway.app (service-facing 프로젝트 내 web-facing 서비스, railway up 수동). 로컬 5062 (5061=Chrome 차단 SIP 포트)
- [x] **버튼 색 원칙** — 도입 문의 = 카카오 옐로(#FEE500/#191919) · 시작하기/CTA = 시그니처 레드(#EE2B2B) · "사장 로그인"→"로그인" 통일 (facing-web + facing-admin 랜딩·로그인)
- [x] **facing-admin 로그인 리디자인** — Narrate 레이아웃 동일(회색 바탕+흰 라운드 카드+← 홈으로+라벨 필드+보기 토글+풀폭 레드 CTA+노랑 도입문의 칩). 홈으로 링크 = 호스트 기반(로컬 5062 / prod web-facing)
- [x] **members 폰트 통일** (레벨·D-day·상태 13px·w700·ls0.3, 페이지 한정) / **lockers 일괄추가 픽스** (순차 N회 왕복 → bulk endpoint 1회, 3건 231ms)

## 진행중
- 없음 (모든 착수 작업 완결)

## 대기
- [ ] **[U] 네이버/구글 OAuth 키** — 발급 가이드는 직전 세션 응답에 정리됨 (네이버: Client ID/Secret, 구글: 웹 클라이언트 ID 1개. SHA-1 두 개는 이미 추출돼 가이드에 포함). 키 수령 시 `--dart-define` 4종 빌드 + 백엔드 GOOGLE_SERVER_CLIENT_ID 등록 + 실연동 검증
- [ ] **[U] NHN 알림톡 키 3종** — 가이드 `services/facing/notifications/NHN_BIZMESSAGE_SIGNUP_GUIDE.md`. 등록 전까지 prod 알림톡 = stub (화면 고지 완료)
- [ ] **백엔드+admin 프로덕션 배포** — 로컬 커밋 다수 미배포 (오늘 자 모든 백엔드/admin 변경). 승인 시 runbook §0 의 **BASE_URL 등록 필수** 후 `railway up`. 신코드 부팅 시 admin/1234 멱등 시드 + social_accounts·pairing TTL 컬럼 마이그레이션 자동
- [ ] **keystore 외부 백업** — `android/app/facing-release.keystore` + `key.properties` 분실 = 앱 업데이트 영구 불가
- [ ] facing-web OG/파비콘은 임시 생성본 — 교체 가능. footer 사업자 정보 = workcheck 동일(디알티) 재사용 — 다르면 수정

## 결정사항 / 주의
- **배포 금지 룰 변동**: facing-web repo push + Railway 배포는 사용자가 개별 승인("2번 시작"·"2")해 실행됨. **백엔드·admin·앱 은 여전히 push/배포 금지** (로컬 커밋만)
- facing-web 요금 섹션 = "무료 베타 + 공지 예정" 2카드 (가격 미정이라 지어내지 않음). 가격 확정 시 4카드 구조 복원 범위 = 섹션 1개
- 환경: 백엔드 5060 · admin 8081 · facing-web 5062 로컬 가동 / 에뮬레이터 debug 빌드(김도윤 로그인) / 본 DB 백업 `services/facing/data/backup/facing-2026-06-10-pre-phase5.db`
- pytest 기존 실패 2건(personas WOD 카운트 드리프트) + onsite 11 skip = 기존 부채, 이번 변경 무관
- Rule 1: 매 응답 PushNotification + 30분 idle 재발사

## 다음 세션 권장 첫 프롬프트
`/resume`
