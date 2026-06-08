# HANDOFF - 2026-06-08 16:12

## 완료 (이번 세션 — 전자계약 버그 2건 배포 수정 + 발급 모달 개선 + 투자자 소개)

### 1. 계약서 발급 404 — web-facing-admin 브랜치 미머지 (배포 수정 완료)
- [x] 증상: 배포 웹 "+ 계약서 발급" 클릭 시 `/api/v1/admin/contract-templates` 404 → 모달 안 뜸.
- [x] 근본 원인: fix 커밋들이 `overnight/2026-05-25` 브랜치에만 있고 **master 미머지** → 배포본 옛 코드.
- [x] 조치: `web/facing-admin` master ← overnight FF 머지(22커밋) → push → `railway up --service web-facing-admin`.
- [x] 검증: 배포 웹 발급 `POST .../contracts` 201, 모달 정상(콘솔 0). 커밋 `9721b3d` 포함 배포 완료.

### 2. 발급 모달 회원권 자동 매핑 + 날짜 캘린더 (구현·배포 완료)
- [x] `web/facing-admin/templates/contracts.html` 변수 입력부(renderVarsFields) 재작성.
      plan_name=MembershipPlan select(`/api/proxy/gyms/<id>/membership-plans`), price=선택 시 자동,
      start_date/end_date=`<input type=date>` 캘린더(시작일+duration_days 종료일 자동), payment_method=select.
- [x] 백엔드 무변경. `_member_form_fields.html` PHASE5 §4-3 자동채움 패턴 이식. 커밋 `9721b3d`(같은 푸시).
- [x] 검증: 로컬 8081 — 3개월권 선택 → 400,000원·종료일 자동(시작+90일), 콘솔 0. railway up 배포 검증 완료.

### 3. 현장 본인 서명 "백엔드 연결 실패" — service-facing 브랜치 미머지 (안전 배포 완료)
- [x] 증상: 배포 웹 현장 본인 서명 제출 → "백엔드 연결 실패". onsite-sign 라우트 배포 백엔드 404, proxy-sign 401.
- [x] 근본 원인: onsite-sign(D27)도 백엔드 `overnight/2026-05-25` 에만, master 미머지.
- [x] 조치(안전 추출): 전체 57커밋 머지 대신 **onsite-sign 커밋만 cherry-pick**(`c6f6da6` → master `4b88bfb`).
      모델 변경 0·DB 스키마 영향 0(contracts.py + services/email_sender.py + test + .env.example).
- [x] 로컬 부팅 검증(health 200, onsite 401) → push → `railway up --service service-facing`.
- [x] 검증: 배포 백엔드 onsite-sign **404→401**, proxy-sign 401, health 200.

### 4. 투자자용 서비스 소개 HTML (작성 완료 · push 보류)
- [x] `apps/facing-app/docs/investor-overview.html` 신규. 전문용어 제거, 되는 것 12 / 준비 중 5 카드 + 하단 "왜 facing".
- [x] 우측 상단 PDF 다운로드 버튼(html2pdf.js CDN). Pretendard CDN. design-block 준수(그라디언트·이모지 X, 한글 자간 음수).
- [x] 검증: 임시 http 8099 + playwright 렌더 OK(html2pdf=function, 되는것 12/준비중 5). 커밋 `ea92599`(로컬, push 안 함).

## 진행중
- (없음 — 위 4건 모두 완료)

## 대기 / 주의 (다음 세션 반드시 확인)
- [ ] **service-facing 브랜치 상태**: 현재 `master` 체크아웃됨(onsite cherry-pick 위해). 로컬 백엔드 5060도 master 코드라
      **소셜로그인 등 overnight 기능 후퇴 상태**. overnight 복귀하려면 `git checkout overnight/2026-05-25`.
- [ ] **service-facing stash 1건**: "playwright 잔여물 임시"(`.playwright-mcp/*`, `facing-admin-dashboard.png`).
      overnight 복귀 시 `git stash pop` 또는 불필요하면 `git stash drop`. (애초에 repo에 들어가면 안 되는 잔여물 — .gitignore 검토)
- [ ] **service-facing 미배포 56커밋**: D26 소셜로그인(미완성·OAuth 키 없음)+DB모델변경(social_accounts 등)은 여전히 overnight 에만.
      master 미머지 = 프로덕션 미반영. onsite-sign 1건만 선별 배포된 상태.
- [ ] 투자자 HTML push 보류 중(배포금지). 외부 공유하려면 사용자 "배포" 승인 후.
- [ ] (이전 핸드오프 잔여) D26 소셜로그인 실기기 실 OAuth 키 발급·테스트 — 절차 `apps/facing-app/docs/NATIVE_AUTH_SETUP.md`.

## 결정사항 / 주의
- 배포 승인 범위(사용자 명시): 계약서 fix·발급모달·onsite-sign 만 배포. 투자자 HTML 은 push 보류.
- web-facing-admin = master 에 overnight 22커밋 전부 머지됨(프론트 only, DB 무관 → 안전).
- service-facing = onsite 1커밋만 cherry-pick(DB 스키마 영향 0). 나머지는 신중히(소셜로그인·DB변경 포함).
- railway: service-facing·web-facing-admin 둘 다 같은 `service-facing` Railway 프로젝트, **자동배포 안 걸림 → railway up 수동**.
- 로컬 서버: 5060(service-facing, master 코드)·8081(web-facing-admin). 8099 임시 http 는 종료됨.
- 데모 로그인: `boss_seongsu / 1234` (= `admin / 1234` 동일 박스 사장). 로컬 8081·배포 웹 동일.

## 다음 세션 권장 첫 프롬프트
`/resume` — 이어서 (1) service-facing 브랜치 정리(master 유지 vs overnight 복귀+stash) 결정 (2) 투자자 HTML 다듬기/배포 (3) 배포 웹 현장·대리 서명 end-to-end 1건 검증
