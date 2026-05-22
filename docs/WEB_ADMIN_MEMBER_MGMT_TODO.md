# facing — PC 사장 웹 · 회원관리 영역 작업 todo (study 기반)

> **작성일**: 2026-05-22
> **선행 문서**: `docs/ARCHITECTURE_BRIEF.md` · `docs/PHASE2_ROADMAP.md` · `~/.claude/reference/study/gym-management-saas.md`
> **대상**: `web/facing-admin` (PC 사장 웹) + `services/facing` (백엔드)
> **범위**: 사장이 회원 한 명을 등록·관리·결제·체크인·탈퇴까지 운영하는 전체 라이프사이클
>
> ⚠️ 모든 항목은 study `gym-management-saas.md` 의 §6 RBAC · §7 B2B2C 3-tier · §8 OWASP A01 · §11 GDPR(한국 PIPA 동등) · §13 모바일 보안 룰을 근거로 도출.

---

## 0. 한 줄 요약

> **로그인부터 회원 탈퇴까지, 사장이 만지는 모든 화면·API·DB 흐름을 OWASP A01 + RBAC + PIPA 기준으로 뼈대 다시 박는 작업. 56개 task · 9 영역 · 3 우선순위 tier.**

---

## 1. 우선순위 tier

| Tier | 의미 | 처리 시기 |
|---|---|---|
| **P0 — block** | 보안·격리·데이터 손실 위험. 5박스 onboarding 전 무조건 | Phase 2 M1~M3 |
| **P1 — major** | 사장 운영 부담 직접 영향. 박스 invite 전 권장 | Phase 2 M3~M5 |
| **P2 — minor** | 편의·미관·미래 확장 | Phase 2 M5 또는 Phase 3 |

---

## 2. 영역 A — 인증·세션·로그인 (P0)

### 2.1 study 근거

- §6.4 Google Zanzibar (consistency)·§7.3 JWT `org_scopes` 2-layer 강제
- §8.3 OWASP A01 — 3대 escalation 방어 (IDOR · vertical · horizontal)
- §13 RFC 6749·7515·8252 (OAuth·JWT·Native Apps)

### 2.2 task list (Phase 2 진행 — /test 보고서 patch 반영)

오버나이트 patch 2 라운드 (2026-05-23 오전):
- ✓ /test 페르소나 10명 × 10 피드백 = 100건 수집·5 카테고리 분석 (`docs/test/2026-05-23-0136/report.md`)
- ✓ C1 신뢰 붕괴 — `scripts/dev_boot.ps1` 좀비 포트 정리 (sub-agent 들이 보고한 자동 redirect 원인 추정)
- ✓ C2 읽기 전용 트랩 — 회원 행 클릭 + 수정 모달 + 코치 시급 인라인 편집 + 토스트
- ✓ C3 회원 추가 시 회원권 동시 발급 (newModal 확장) + CSV UTF-8 BOM
- ✓ C4 랜딩 1차 CTA + 빈 상태 친절 안내 (members·coaches·payroll) + 데이터 일관성 주석
- ✓ C5 락커 vacant opacity 제거 + 텍스트 라벨 + Scaled 배지 색 #5A5A5A → #9A9A9A (WCAG 보정)

- [x] **A-1 [P0]** **bcrypt cost 12 + password hashing 검증** (2026-05-22 완료)
  - 현재: `seed_gym_managers()`·`seed_superadmin()` 5곳 모두 `bcrypt.gensalt(rounds=12)` 일관 적용 확인
  - 로그인 검증 `bcrypt.checkpw()` — bcrypt 자체가 timing-safe ✓
  - `services/facing/audit_bcrypt.py` 추가 — `gym_managers` + `admin_users` 모든 hash 검증. cost <12 발견 시 exit 1
  - 실행 결과: 6/6 hash all cost 12 통과

- [x] **A-2 [P0]** **세션 쿠키 보안 플래그** (2026-05-23 일부 완료)
  - `services/facing/app.py` 에 `app.config.update()` 추가
  - `SESSION_COOKIE_SECURE=production만True` · `HTTPONLY=True` · `SAMESITE='Lax'` · TTL 8시간 + sliding (`SESSION_REFRESH_EACH_REQUEST=True`)
  - dev localhost HTTP 호환 (Secure=False), production env 자동 전환
  - 잔여: 로그아웃 시 server 측 세션 invalidate (Redis 또는 DB session table) — Redis 도입 시점 (M5) 에 추가

- [ ] **A-3 [P0]** **CSRF 토큰**
  - Flask-WTF 또는 자체 구현. 모든 POST/PUT/DELETE 에 토큰 검증
  - `X-CSRF-Token` 헤더 + double-submit cookie 패턴
  - GET 은 idempotent 유지 (CSRF 영향 X)

- [ ] **A-4 [P0]** **로그인 rate limit + 잠금**
  - IP 당 5분 안 5회 실패 → 5분 lockout (study §8 escalation 방어 보조)
  - 같은 계정 30분 안 10회 실패 → 30분 lockout + 사장 SMS 알림
  - Redis 기반 sliding window counter

- [ ] **A-5 [P0]** **로그인 audit log**
  - `audit_log` 테이블에 (timestamp · user_id · gym_id · action='login' · ip · ua · success) 기록
  - 실패도 기록 (lockout 결정 근거)
  - 사장 본인 화면에서 최근 30일 로그인 로그 조회

- [x] **A-6 [P0]** **권한 미들웨어 헬퍼 추가** (2026-05-23 헬퍼 추가, 적용은 endpoint 마다)
  - `services/facing/api/admin.py` 에 `require_role(roles)` 데코레이터 + `assert_gym_match(resource_gym_id)` 헬퍼 추가
  - `require_role(["boss", "coach"])` 같이 다중 역할 지원
  - `assert_gym_match()` 는 IDOR 방어 — 자원 gym_id 가 세션 gym_id 와 다르면 abort(404)
  - 잔여: 모든 sensitive endpoint 에 적용 (B-8 IDOR 작업과 동시)

- [ ] **A-7 [P1]** **JWT 도입 (M4 멀티 박스 대비)**
  - 현재 세션 쿠키 → JWT 전환 (org_scopes 배열 클레임)
  - RS256 비대칭 (서버 private, 클라이언트 public cache)
  - access 15분 + refresh 7일 single-use rotation (study §13.2)

- [ ] **A-8 [P1]** **비밀번호 정책**
  - 최소 8자 + 영문·숫자·특수 중 2종 이상
  - 회원가입·변경 시 zxcvbn 점수 ≥3 강제
  - 정기 강제 변경 X (NIST 2017 가이드 — 정기 변경이 오히려 약한 패스워드 유발)

- [ ] **A-9 [P1]** **2FA (TOTP) — 옵션**
  - Google Authenticator·Authy 호환 TOTP
  - 사장 계정만 적용 (코치·회원은 v2)
  - 복구 코드 10개 (1회용)

- [ ] **A-10 [P2]** **SSO — Google·Kakao** (대형 박스 체인 진출 시)

---

## 3. 영역 B — 회원 schema·CRUD·검색 (P0~P1)

### 3.1 study 근거

- §3.4 RLS anti-pattern (복합 인덱스 `(gym_id, primary_key)` 의무)
- §11.5 한국 PIPA — 가명정보·민감정보 분리

### 3.2 task list

- [ ] **B-1 [P0]** **회원 schema 확장 — PIPA 분리**
  - `gym_member_profile` 에 다음 분리:
    - 식별정보 (이름·생년월일·전화·이메일) — 암호화 컬럼 (`pgcrypto` 또는 application-level AES-256)
    - 신체정보 (키·몸무게·운동 이력) — 일반 컬럼
    - 민감정보 (질병·복용약·부상이력) — 별도 table + 접근 audit
  - 가명정보 (분석용) — 별도 view 또는 ETL

- [ ] **B-2 [P0]** **동의서·서명 컬럼**
  - 가입 동의 (개인정보 수집·이용·제3자 제공·마케팅) 4 토글
  - 각 동의 항목 timestamp + IP 기록
  - 서명 이미지 (data URI 또는 S3 URL) + 캔버스 서명 UI

- [ ] **B-3 [P0]** **회원 사진**
  - 프로필 사진 upload (얼굴 인식 체크인 향후 대비)
  - 파일 검증 (image/jpeg·image/png only, magic byte 검증 — 확장자만 X)
  - S3 또는 로컬 `data/uploads/` (.gitignore)

- [ ] **B-4 [P0]** **회원 lifecycle 상태**
  - `gym_members.status` enum 확장: `pending` (가입 신청) · `active` · `paused` (동결) · `left` (탈퇴 30일 soft delete) · `removed` (영구 삭제)
  - 자동 전이 (cron): 회원권 만료 7일 후 paused → 60일 후 left → 30일 후 removed
  - 각 전이 시 SMS·메일 알림

- [ ] **B-5 [P1]** **회원 검색·필터·정렬**
  - 이름·전화·이메일 부분일치 (대소문자·공백 무시)
  - status 필터 (active / paused / left / pending)
  - 회원권 종류 필터
  - 가입일·최근 출석일·결제 금액 정렬
  - 결과 페이지네이션 (50건/page)

- [ ] **B-6 [P1]** **회원 대량 작업 (bulk)**
  - 체크박스 선택 → 일괄 회원권 연장·휴면·메시지 발송
  - CSV import (신규 박스 onboarding 시 기존 회원 마이그레이션)
  - CSV export (필터 결과)

- [ ] **B-7 [P1]** **회원 상세 페이지 강화**
  - 회원권 history (발급·연장·동결·환불)
  - 결제 history (회차·금액·방법)
  - 출석 history (월별 그래프 + 최근 30일 캘린더)
  - 코치 배정 history (PT 회원만)
  - 메모 (사장·코치 사적 메모, 회원에게 미노출)

- [ ] **B-8 [P0]** **IDOR 방어 — 모든 회원 endpoint**
  - `/members/<member_id>` 호출 시 `member.gym_id == current_gym_id` 검증
  - study §8.3 Failure 1 패턴 그대로
  - 404 응답 (403 대신 — 존재 여부 leakage 방지)

- [ ] **B-9 [P0]** **`(gym_id, member_id)` 복합 인덱스**
  - study §3.4 RLS anti-pattern 회피
  - 모든 tenant table 적용 (members·memberships·attendances·payments·lockers·contracts)

- [ ] **B-10 [P2]** **회원 그룹·태그**
  - 사용자 정의 태그 (예: "신규" · "VIP" · "PT 진행중")
  - 태그 기반 필터·일괄 메시지

---

## 4. 영역 C — 회원권·결제 (P0~P1)

### 4.1 study 근거

- §11 PIPA · §12 Citus 트리거 (1,000 박스 이후)
- 별도 reference 예정: `study/payment.md` (Toss·webhook 보안)

### 4.2 task list

- [ ] **C-1 [P0]** **회원권 종류 다양화**
  - 기간권 (1·3·6·12개월) + 자동결제 옵션
  - 횟수권 (10·30·50회) — 출석 1회 = 차감 1회
  - PT 권 (코치 배정 + 횟수)
  - 동결권 (질병·여행 시, 최대 30일·연 2회)
  - schema: `gym_memberships` 에 `type` enum + `unit_count_remaining` 컬럼

- [ ] **C-2 [P0]** **자동 만료·동결 처리**
  - APScheduler 또는 Celery beat — 매일 03:00 KST
  - 만료 7일 전 SMS 알림
  - 만료 당일 status → paused
  - 동결 기간 종료 자동 재개

- [ ] **C-3 [P0]** **회원권 연장·환불**
  - 부분 환불 (잔여 일수 비례)
  - 환불 사유 + audit log + 사장 서명
  - 회원에게 환불 영수증 메일

- [ ] **C-4 [P0]** **Toss Payments live 전환** (Phase 2 M2-1)
  - HMAC-SHA256 webhook 검증
  - idempotency key (replay 방어)
  - 결제 실패 retry policy

- [ ] **C-5 [P1]** **자동결제 (정기결제)**
  - Toss 정기결제 API (빌링키 발급)
  - 매월 지정일 자동 청구
  - 실패 시 3회 재시도 + 사장 SMS

- [ ] **C-6 [P1]** **결제 영수증·세금계산서**
  - 영수증 PDF 자동 발행 (회원 메일)
  - 사업자 세금계산서 (사장 요청 시) — `services/support` 패턴 참고

- [ ] **C-7 [P1]** **결제 reconciliation**
  - 월 1회 Toss 정산 내역 vs DB 결제 내역 비교
  - 불일치 발견 시 사장 알림

- [ ] **C-8 [P2]** **할인·쿠폰**
  - 코드 기반 할인
  - 친구 추천 할인
  - 시즌 이벤트 할인

---

## 5. 영역 D — 출석·체크인 (P0~P1)

### 5.1 task list

- [ ] **D-1 [P0]** **QR 체크인 — 1회용 토큰 60초 만료**
  - 현재 구현됨 (HANDOFF 확인)
  - 추가: replay 방어 — 토큰 사용 시 즉시 invalidate
  - QR 화면 5초마다 자동 갱신

- [ ] **D-2 [P0]** **체크인 시 회원권 검증**
  - 만료된 회원권은 입장 거부 + 사장 알림
  - 동결 중인 회원은 입장 거부 (단 사장 override 가능)
  - 횟수권은 차감 1회

- [ ] **D-3 [P1]** **체크인 방식 다양화 (옵션)**
  - PIN 입력 (회원 4자리 PIN)
  - NFC 카드 (별도 reader 필요)
  - 얼굴 인식 (B-3 사진 활용, v2)

- [ ] **D-4 [P1]** **출석 통계**
  - 일·주·월 출석률
  - 회원별 결석 7일+ 알림
  - 시간대별 혼잡도 히트맵

- [ ] **D-5 [P1]** **체크아웃·체류시간**
  - 입장·퇴장 모두 기록
  - 평균 체류시간 통계
  - 24시간 미체크아웃 자동 처리 (오류 보정)

---

## 6. 영역 E — 알림·SMS·메일·푸시 (P0~P1)

### 6.1 task list

- [ ] **E-1 [P0]** **알림 트리거 카탈로그**
  - 회원: 회원권 만료 7/3/1일 전·결제 완료·체크인 환영·동결 해제
  - 사장: 신규 가입 신청·결제 수신·만료 임박·코치 페어링 요청
  - 코치: 회원 PT 예약·캔슬·메시지

- [ ] **E-2 [P0]** **NHN Toast SMS 통합** (Phase 2 M2-3)
  - sender ID 등록
  - 발송 limit·비용 모니터
  - 발송 audit log

- [ ] **E-3 [P0]** **Mailgun 메일 통합** (M2-4)
  - SPF·DKIM·DMARC
  - HTML 템플릿 (영수증·만료 안내·환영)

- [ ] **E-4 [P0]** **FCM 푸시 통합** (M2-2)
  - 사장 PC 는 SSE 알림 (이미 구현)
  - 폰 회원·코치는 FCM

- [ ] **E-5 [P1]** **알림 설정 페이지**
  - 회원: 본인 받는 알림 ON/OFF (SMS·메일·푸시 채널별)
  - 사장: 본인 받는 알림 ON/OFF + 시간대 (예: 22:00~08:00 무음)

- [ ] **E-6 [P1]** **알림 발송 retry + dead-letter**
  - 발송 실패 3회 재시도
  - 모두 실패 시 `notification_failed` table 적재 + 사장 dashboard 표시

- [ ] **E-7 [P2]** **카카오 알림톡** (한국 시장 특화, SMS 대비 저렴 + 마케팅 가능)

---

## 7. 영역 F — 코치·PT 관리 (P1)

### 7.1 task list

- [ ] **F-1 [P1]** **코치 schema 확장**
  - 자격증 (CrossFit Level 1~4·기타) · 시급 · 전문 분야 · 사진
  - 시급 history (인상·인하)

- [ ] **F-2 [P1]** **코치 페어링 코드 발급 + 만료**
  - 현재 구현됨 (HANDOFF 확인)
  - 추가: 1회용 + 24시간 만료 강제 + audit log

- [ ] **F-3 [P1]** **PT 회원 ↔ 코치 매핑**
  - 회원당 main 코치 1명 + sub 코치 N명
  - PT 횟수권 회원만 적용

- [ ] **F-4 [P1]** **PT 예약 시스템**
  - 회원 → 폰에서 코치 시간표 보고 예약
  - 코치 → 폰에서 수락·거절·이동
  - 사장 → PC 에서 전체 예약 캘린더

- [ ] **F-5 [P1]** **코치 정산 (M4 연계)**
  - 현재 `/payroll` 자동 산정 (HANDOFF 확인)
  - 추가: PT 진행분 별도 정산 (PT 횟수 × 코치 PT 단가)
  - CSV export + 직접 송금 연동 (선택)

- [ ] **F-6 [P2]** **코치 평가**
  - 회원이 PT 후 5점 척도 평가
  - 사장 dashboard 에 코치별 평점

---

## 8. 영역 G — 보안·개인정보·법규 (P0)

### 8.1 study 근거 — §8 OWASP A01 + §11 PIPA

### 8.2 task list

- [ ] **G-1 [P0]** **개인정보 처리방침 페이지**
  - 한국 PIPA 의무 항목 다 포함
  - 변경 시 회원 재동의 강제

- [ ] **G-2 [P0]** **회원 본인 정보 열람·수정·삭제 권리**
  - 폰 회원 화면 + PC 사장 화면 양쪽에서
  - 삭제 요청 → 30일 soft delete → 60일 후 영구 삭제 (audit log 만 보존)

- [ ] **G-3 [P0]** **데이터 export (회원 본인)**
  - PIPA 제35조 — 회원이 본인 데이터 JSON·CSV 받을 권리
  - 폰 회원 화면 → 메일 발송

- [ ] **G-4 [P0]** **개인정보 접근 audit**
  - 사장·코치가 회원 상세 페이지 조회 → audit_log 기록
  - 회원이 본인 audit log 조회 가능 (누가 내 정보 봤는지)

- [ ] **G-5 [P0]** **암호화**
  - 식별정보 (B-1 분리) AES-256 application-level 암호화
  - 결제정보는 Toss 가 보관 (서버 X)
  - DB backup 도 암호화 (Railway 기본 옵션)

- [ ] **G-6 [P0]** **CORS·CSP·HSTS**
  - CORS: 사장 PC 웹 도메인만 허용
  - CSP: `default-src 'self'`; script-src whitelist
  - HSTS: max-age 1년 + includeSubDomains

- [ ] **G-7 [P0]** **OWASP A01 — IDOR 회귀 테스트**
  - 박스 A user 가 박스 B 회원 ID 직접 입력 → 404
  - 자동 테스트 (pytest)
  - CI 에서 매 commit 검증

- [ ] **G-8 [P1]** **CCTV·출입기록 별도 처리**
  - 박스에 CCTV 있다면 별도 동의 + 보관기간 30일
  - facing 시스템 안 X, 사장이 별도 운영 (PIPA 요구)

- [ ] **G-9 [P1]** **민감정보 마스킹**
  - 회원 목록 화면에서 전화번호·생년월일 일부 마스킹 (010-****-1234)
  - 클릭 시 audit log 기록 + 풀 노출

- [ ] **G-10 [P0]** **secret 관리**
  - 모든 secret Railway env 만 (코드·.env 절대 X — CLAUDE.md §2-A-1)
  - rotation 정책 (분기별 1회)

---

## 9. 영역 H — DB·아키텍처 (P0~P1)

### 9.1 study 근거 — §2~§5 멀티테넌시 + §14.1 facing 적용 권고

### 9.2 task list

- [ ] **H-1 [P0]** **SQLite → PostgreSQL 이행** (Phase 2 M3-1)
  - Alembic 도입
  - 데이터 마이그레이션 스크립트

- [ ] **H-2 [P0]** **모든 tenant table 에 `gym_id` 컬럼 + 복합 인덱스**

- [ ] **H-3 [P0]** **Postgres RLS — `ENABLE` + `FORCE`** (M3-3)

- [ ] **H-4 [P0]** **미들웨어 `SET LOCAL app.current_gym_id`** (M3-4)

- [ ] **H-5 [P0]** **pgTAP cross-gym 차단 테스트** (M3-5)

- [ ] **H-6 [P1]** **백업·복구**
  - 현재 APScheduler 매일 03:00 KST `facing.db` 백업 (HANDOFF)
  - PostgreSQL 이행 후 → Railway 자동 백업 + 별도 S3 dump 30일 보존
  - 복구 drill — 분기 1회 테스트 복구

- [ ] **H-7 [P1]** **read replica 도입 검토** (Phase 2 M5 또는 Phase 3)
  - 통계·리포트 쿼리는 replica
  - write 은 primary

- [ ] **H-8 [P2]** **Citus 마이그레이션 trigger 모니터** (Phase 3)
  - 1TB 이상 OR 1000 박스 OR 1000 req/sec 도달 시 alert
  - study §12.2 임계값 그대로

---

## 10. 영역 I — Flask 백엔드 설정 (P0~P1)

### 10.1 task list

- [ ] **I-1 [P0]** **production WSGI server**
  - 현재 Werkzeug dev server (debug=True) — 데모용
  - production: gunicorn (sync worker, workers=2~4) — SQLite + workers>1 금지 룰 준수 (단일 SQLite → workers=1)
  - PostgreSQL 이행 후 (M3) workers 늘릴 수 있음

- [ ] **I-2 [P0]** **logging — 구조화**
  - JSON 포맷 (CloudWatch·Sentry 호환)
  - 레벨: DEBUG/INFO/WARNING/ERROR/CRITICAL
  - sensitive 데이터 자동 마스킹 (password·token·결제정보)

- [ ] **I-3 [P0]** **error tracking**
  - Sentry SDK 도입
  - PII scrub 활성화
  - release tag (deploy 단위)

- [ ] **I-4 [P0]** **health check endpoints**
  - `/api/v1/health` (이미 구현 — HANDOFF 확인)
  - 추가: `/api/v1/health/db` · `/api/v1/health/redis` · `/api/v1/health/external` (Toss·FCM)

- [ ] **I-5 [P0]** **graceful shutdown**
  - SIGTERM 받으면 in-flight 요청 완료 후 종료
  - Railway 배포 시 zero-downtime

- [ ] **I-6 [P0]** **request validation**
  - Pydantic 또는 marshmallow schema
  - 모든 POST·PUT body 검증
  - 잘못된 입력 = 400 + 명확한 에러 메시지

- [ ] **I-7 [P0]** **response envelope 통일**
  - 글로벌 `patterns.md` 의 `{ok, data, error, code}` 패턴 강제
  - 프론트엔드는 `res.ok` 분기

- [ ] **I-8 [P1]** **API versioning**
  - 현재 `/api/v1/...` 사용 중 (HANDOFF 확인)
  - v2 도입 시 v1 6개월 유지 후 폐기 정책

- [ ] **I-9 [P1]** **rate limit (전반)**
  - Flask-Limiter 도입
  - IP·user·endpoint 별 limit
  - 결제·로그인은 더 엄격하게

- [ ] **I-10 [P1]** **APScheduler → Celery 검토** (P3 단계)
  - 현재 APScheduler 인프로세스 (단일 워커만)
  - 워커 증설 시 Celery + Redis broker 로 이행

---

## 11. 영역 J — 통계·리포트·운영 dashboard (P1~P2)

### 11.1 task list

- [ ] **J-1 [P1]** **사장 dashboard — 핵심 지표**
  - 오늘/이번주/이번달 매출
  - active 회원 수 · 신규 가입 · 탈퇴
  - 출석률 · 평균 체류시간
  - 코치별 PT 진행 횟수

- [ ] **J-2 [P1]** **월간 리포트 자동 생성**
  - 매월 1일 03:00 KST 자동 생성
  - PDF + 메일 발송

- [ ] **J-3 [P1]** **회원 retention cohort**
  - 가입 월별 cohort table (3·6·12개월 잔존율)
  - subscription-fitness study cross-reference

- [ ] **J-4 [P2]** **AI insight**
  - 이탈 위험 회원 자동 검출 (출석 빈도 감소)
  - 사장에게 주간 alert

---

## 12. 우선순위 매트릭스 종합

### 12.1 P0 (5박스 onboarding 전 무조건)

영역 A: A-1~A-6 · 영역 B: B-1~B-4, B-8~B-9 · 영역 C: C-1~C-4 · 영역 D: D-1~D-2 · 영역 E: E-1~E-4 · 영역 G: G-1~G-7, G-10 · 영역 H: H-1~H-5 · 영역 I: I-1~I-7

**총 P0 항목 약 36개**. Phase 2 M1~M3 안에 처리 목표.

### 12.2 P1 (박스 invite 전 권장)

영역 A: A-7~A-9 · 영역 B: B-5~B-7 · 영역 C: C-5~C-7 · 영역 D: D-3~D-5 · 영역 E: E-5~E-6 · 영역 F: F-1~F-5 · 영역 G: G-8~G-9 · 영역 H: H-6~H-7 · 영역 I: I-8~I-10 · 영역 J: J-1~J-3

**총 P1 항목 약 28개**. Phase 2 M3~M5 안에 처리 권장.

### 12.3 P2 (편의·미관·미래)

A-10 · B-10 · C-8 · E-7 · F-6 · H-8 · J-4

**총 P2 항목 약 7개**. Phase 2 M5 또는 Phase 3.

---

## 13. 의존 그래프 (P0 핵심 순서)

```
H-1 (PostgreSQL 이행)
   ↓
H-2 (gym_id 컬럼)  ←  B-1 (회원 schema 분리)
   ↓
H-3 (RLS enable/force)
   ↓
H-4 (미들웨어 SET LOCAL)
   ↓
A-6 (require_role 미들웨어)  ←  A-1~A-5 (로그인 강화)
   ↓
B-8 (IDOR 방어)  ·  G-7 (회귀 테스트)
   ↓
C-1 (회원권 종류)  ·  D-1 (QR 체크인)  ·  E-1 (알림 카탈로그)
   ↓
C-4 (Toss live)  ·  E-2~E-4 (외부 통합)
   ↓
G-1~G-5 (PIPA 컴플라이언스)
   ↓
I-1~I-7 (production 준비)
   ↓
[5박스 onboarding 가능]
```

---

## 14. 산출물 매핑

| 영역 | 백엔드 파일 | 프론트 파일 | DB 변경 |
|---|---|---|---|
| A 인증 | `services/facing/api/auth.py` · `api/middleware/auth.py` | `web/facing-admin/login.html` · `static/js/auth.js` | `audit_log`·`sessions` |
| B 회원 | `api/admin.py`·`api/members.py` | `templates/members.html` | `gym_member_profile`·`gym_consent`·`gym_signature` |
| C 결제 | `api/payments.py`·`api/webhooks/toss.py` | `templates/memberships.html` | `gym_membership`·`payment`·`refund` |
| D 출석 | `api/checkin.py` | `templates/checkin.html` | `gym_attendance` |
| E 알림 | `api/notifications/*.py` (fcm·sms·email adapter) | `templates/notifications.html` | `notification_log` |
| F 코치 | `api/coaches.py`·`api/pt.py` | `templates/coaches.html`·`pt.html` | `gym_coach`·`pt_session` |
| G 보안 | `api/middleware/security.py`·`api/privacy.py` | `templates/privacy.html` | `audit_log` (전 영역) |
| H DB | `migrations/`·`models/*.py` | (없음) | 모든 table |
| I Flask | `app.py`·`config.py`·`logging_config.py` | (없음) | (없음) |
| J 통계 | `api/stats.py`·`api/reports.py` | `templates/stats.html`·`reports.html` | view·materialized view |

---

## §변경 이력

- **2026-05-22**: 신규 작성. study `gym-management-saas.md` 기반 9 영역 · 56 task · 3 우선순위 tier. Phase 2 M1~M5 로드맵과 매핑.

---

## 15. 다음 액션 (이 todo 활용법)

1. **사용자 검토** — 우선순위 동의·삭제·추가
2. **세션별 task 1~3개씩 진행** — `/resume` 시 이 파일 참조
3. **완료 task 는 `- [x]` 로 체크 + commit**
4. **사용자가 새 요구 추가하면 같은 영역에 task ID 부여 (A-11·B-11 형식) + 우선순위 tier 부여**
5. **5박스 onboarding 직전 P0 36개 다 완료 검증**
