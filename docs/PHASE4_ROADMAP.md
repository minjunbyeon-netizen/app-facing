# PHASE4 ROADMAP — facing 박스 SaaS 운영 자동화 + 선수 도구 강화

> **작성일**: 2026-05-23 (오버나이트 자율 작성)
> **베이스**: `docs/competitor/linko.md` (linko.my 350+ 박스, 한국 1위급) + `~/.claude/reference/study/gym-owner-feedback.md` (1041건) + `PHASE3_REVISION_v2.md`
> **목적**: linko.my 의 강한 운영 자동화 영역(예약·알림·전자계약·다지점·페이·WOD 디자인·AI) 흡수 + facing 만의 선수 도구(페이싱·티어·1RM) 강화 — **선수+박스 듀얼 포지셔닝**으로 패스트팔로워 함정 회피
> **선행**: PHASE3 P0 18 + P1 24 + P2 14 = 56 task 완료 후 진입 (Phase 3 종료 = 100박스 도달 시점)
> **ARCHITECTURE_BRIEF**: §11 변경 절차 — 본 로드맵 P0 task 의 schema·endpoint 변경은 브리프 §5 데이터 모델 / §13 API 카탈로그에 동기 PR 의무

---

## §0. 배경

### §0.1 왜 PHASE4 인가

PHASE3 v2 의 차별화 권장 1번 ("linko.my 운영 SaaS / facing 연산 엔진 수직 분리") 만으로는 **시장 진입 자체가 막힘**. 한국 박스 사장 1041건 의견 분석 결과 **결제·해지·알림·예약·다지점이 박스 SaaS 선택의 결정적 5요인** — 이 영역에서 linko 와 격차가 너무 크면 facing 의 선수 도구는 코치·박스 사장이 손도 안 댐.

따라서 PHASE4 는:
1. **흡수 7 모듈** — linko.my 의 운영 자동화 핵심 영역을 facing 에도 구현 (패스트팔로워)
2. **차별 강화 4 모듈** — facing 만의 선수 도구를 동시에 깊게 만들어 듀얼 포지셔닝 확립
3. **B2B2C 데이터 연동** — Recommendation 4 (facing-app Tier ↔ 박스 SaaS) 가 PHASE4 의 진짜 무기. linko 가 따라올 수 없는 영역

### §0.2 1041건 보고서 §13 권장 7건과의 매핑

| §13 권장 | PHASE4 모듈 | 우선순위 |
|---|---|---|
| 1. 한국 결제·세무 통합 (Toss·홈택스·부가세) | PHASE3 C-1 + PHASE4 §1.5 링코페이 대응 | PHASE3 완료, P0 보강 |
| 2. 코치 정산 자동화 (3.3%·4대보험) | PHASE3 N2-9 완료 | PHASE3 종료 |
| 3. Retention 자동화 hook (churn 66.4%) | **PHASE4 §1.2** 알림 자동화 + §1.1 예약 | **P0** |
| 4. facing-app Tier ↔ 박스 SaaS 연동 | **PHASE4 §2.4** 듀얼 포지셔닝 | **P0** (linko 가 못 따라올 영역) |
| 5. Vendor Lock-out 보장 | PHASE3 P1 CSV export 완료 | 유지 |
| 6. 한국 환불·해지 자동화 (소비자원 분쟁 92%) | PHASE3 D21 + PHASE4 §1.3 전자계약 | P0 보강 |
| 7. 1RM 기반 개인화 페이싱 (Sugar WOD/WodBuster 공백) | **PHASE4 §2.1·§2.4** | **P0** |

### §0.3 ARCHITECTURE_BRIEF §0 충돌 점검

- **§0 한 줄 요약 "역할은 회원·코치·사장 3개"** — PHASE4 §1.4 다지점은 사장 1인 다박스 (D18 다중 박스) 이미 지원, 충돌 X
- **§4 SSE 채널** — PHASE4 §1.2 카카오 알림톡은 외부 게이트웨이 (NHN·Aligo) 라 SSE 와 별개, 충돌 X
- **§5 신규 6 테이블** — PHASE4 는 schema 추가 (예약·전자계약 PDF·다지점 회원·페이먼트 토큰). §11 변경 절차 의무
- **§7 인증·보안** — PHASE4 §1.5 자체 결제 SDK 검토 시 PCI DSS scope 확장 위험. **링코페이형 자체 PG 는 P2 로 defer**, Toss 빌링키 강화로 대체

---

## §1. 흡수 영역 — 7 모듈 (linko.my 추격)

### §1.1 예약 시스템 (Class Reservation)

#### 현재 facing 상태
- ❌ 미구현. `PHASE3_REVISION_v2.md` N2-2 "PT 예약 — 마켓플레이스 연동 보류 + 취소 정책 3단계" 만 있고, **그룹 클래스 자리 예약은 schema·UI 둘 다 0%**
- ARCHITECTURE_BRIEF §5 신규 6 테이블에 `class_session` / `class_reservation` 부재
- 1041 보고서 §12 Rank 19 "클래스 예약·노쇼 관리" 인용수 10 — 시장 요구는 명확

#### linko.my 대비 격차
- linko: 관리자 웹 + 회원 앱에서 클래스 자리 사전 확인 + 예약 + 취소 + 노쇼 자동 관리. 박스 사장이 매니저 권한 코치에게 위임 가능
- facing: 0%. 코치는 출석 QR 받을 뿐 "오늘 누가 올지" 모름

#### PHASE4 구현 계획

**Schema (3 테이블 추가)**:
```sql
CREATE TABLE class_session (
  id BIGSERIAL PRIMARY KEY,
  gym_id INT NOT NULL,
  coach_id INT,
  wod_id INT,                       -- 연결된 WOD (선택)
  scheduled_at TIMESTAMPTZ NOT NULL,
  duration_min INT DEFAULT 60,
  capacity INT DEFAULT 12,
  status VARCHAR(20) DEFAULT 'open', -- open/full/cancelled/done
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT class_gym_rls FOREIGN KEY (gym_id) REFERENCES gyms(id)
);

CREATE TABLE class_reservation (
  id BIGSERIAL PRIMARY KEY,
  class_session_id BIGINT REFERENCES class_session(id) ON DELETE CASCADE,
  member_id INT NOT NULL,
  gym_id INT NOT NULL,              -- RLS 필수
  status VARCHAR(20) DEFAULT 'reserved', -- reserved/cancelled/waitlist/attended/no_show
  reserved_at TIMESTAMPTZ DEFAULT NOW(),
  cancelled_at TIMESTAMPTZ,
  waitlist_position INT,
  UNIQUE(class_session_id, member_id)
);

CREATE TABLE class_waitlist_promotion (   -- 대기열 자동 승격 audit
  id BIGSERIAL PRIMARY KEY,
  reservation_id BIGINT,
  promoted_at TIMESTAMPTZ,
  notified_via VARCHAR(20)          -- kakao/sms/push
);
```

**Endpoint**:
- `POST /api/v1/admin/class-sessions` — 사장/매니저 클래스 발행 (배치 — "이번 주 월·수·금 18:00 12명")
- `GET /api/v1/admin/class-sessions?date=2026-05-30` — 명단 사전 확인 (linko Pulse 인터뷰 핵심 기능)
- `POST /api/v1/member/reservations` — 회원 폰에서 자리 예약 (멱등 — 동일 session+member UNIQUE)
- `DELETE /api/v1/member/reservations/<id>` — 취소 (cutoff: 2시간 전, 이후 = no_show 자동)
- `POST /api/v1/admin/reservations/<id>/no-show` — 노쇼 마킹 (3회 시 자동 sanction 옵션)
- SSE `class-reservation-changed` 이벤트 (코치 폰 실시간 명단 갱신)

**UI**:
- 사장 PC: `/admin/classes` — 월간 캘린더 + 클래스 발행 모달 + 명단 클릭 회원 사이드패널
- 코치 폰: "오늘 클래스" 탭 — 시간순 클래스 카드 + 예약 명단 (face thumbnail)
- 회원 폰: "예약" 탭 — 다음 7일 가용 클래스 + 1탭 예약 + 대기열 진입

**노쇼 정책 (D24 보강)**:
- 24시간 미취소 + 미출석 = no_show 자동 마킹
- 누적 3회 → 사장 PC 에 alert + 회원 등급에 따라 7일 예약 정지 옵션 (사장 설정)
- waitlist: 취소 발생 시 1순위 대기자에게 카카오 알림톡 자동 (15분 응답 후 다음 사람)

**우선순위**: **P0** (한국 박스 운영 필수 — 자리 부족 분쟁 직결)
**예상 공수**: **1주** (schema 3 + endpoint 5 + UI 사장PC/코치폰/회원폰 = 3*2일 + 1일 통합)

---

### §1.2 알림 자동화 (Notification Automation — 카카오 알림톡)

#### 현재 facing 상태
- ARCHITECTURE_BRIEF D22 "알림 게이트웨이 SMS = NHN Cloud Toast SMS · 이메일 = Mailgun · 푸시 = FCM" — 인프라는 정의됨
- D8 "만료 7·14일 전 자동 알림" — 시퀀스는 정의됐으나 실제 구현은 SMS 만 stub
- ❌ **카카오 알림톡 (비즈니스 채널 인증) 0%** — NHN Cloud Bizmessage 또는 Aligo 통합 부재
- 1041 보고서 §12 Rank 13 "카카오톡 알림 미통합 (한국)" 인용수 17 — 한국 박스 사장 필수 요구

#### linko.my 대비 격차
- linko: 회원권 만료 7·3·당일 카카오 알림톡 자동 + 신규 가입 환영 + 공지 게시판 알림 + 부분 인원 선택 발송 (회원권·성별 필터)
- facing: SMS stub 만 있고 실 발송 인프라 결합 미완

#### PHASE4 구현 계획

**선택**: NHN Cloud Bizmessage (이미 D22 의 NHN Cloud Toast SMS 와 동일 벤더 → 콘솔 통합)

**Schema 추가**:
```sql
CREATE TABLE notification_template (
  id SERIAL PRIMARY KEY,
  gym_id INT,                       -- NULL = 전역 템플릿
  kakao_template_code VARCHAR(50),  -- 카카오 비즈채널 사전 승인 코드
  channel VARCHAR(20) NOT NULL,     -- kakao_alimtalk/sms/email/push
  trigger_event VARCHAR(50),        -- membership_expiry_7d / payment_failed / class_waitlist_promoted ...
  body_template TEXT,               -- {{member_name}} 등 변수
  active BOOLEAN DEFAULT TRUE
);

CREATE TABLE notification_dispatch (
  id BIGSERIAL PRIMARY KEY,
  gym_id INT NOT NULL,
  member_id INT,
  template_id INT,
  channel VARCHAR(20),
  payload JSONB,
  status VARCHAR(20),               -- queued/sent/failed/delivered
  external_id VARCHAR(100),         -- 게이트웨이 응답 ID
  attempt_count INT DEFAULT 0,
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  error TEXT
);
```

**시퀀스 8건 (사전 승인 의무)**:
1. `membership_expiry_7d` — "{{member_name}}님 회원권 7일 후 만료. {{url}} 에서 연장"
2. `membership_expiry_3d`
3. `membership_expiry_today`
4. `payment_failed` — 카드 자동 재시도 후 실패 시
5. `class_waitlist_promoted` — 대기열 → 자리 확정 (15분 응답 cutoff)
6. `welcome_new_member` — 가입 승인 + first-week buddy 안내 (D11)
7. `pr_celebration` — facing-app Tier 상승 + 코치 멘션 (§13 Rec 3)
8. `no_show_warning` — 노쇼 2회 후 다음 1회 시 정지 안내

**Endpoint**:
- `POST /api/v1/admin/notifications/dispatch` — 즉시 발송 (성별·회원권 필터 + 미리보기)
- `GET /api/v1/admin/notifications?status=sent&date=...` — 발송 이력
- 백그라운드 APScheduler/Celery (PHASE3 N4-4 조건부 정의) — 매일 03:00 만료 임박 회원 스캔 + dispatch enqueue

**Failover**:
- 카카오 알림톡 발송 실패 → SMS 자동 fallback (소비자보호법 알림 의무)
- 발송 실패 3회 누적 = 사장 PC alert

**우선순위**: **P0** (한국 박스 사장 80%+가 별도 카카오톡 수동 발송 중)
**예상 공수**: **3일** (NHN 비즈채널 가입·템플릿 사전심사 = 외부 의존 1주 별도. 개발은 3일)

---

### §1.3 전자계약 (e-Sign Contract)

#### 현재 facing 상태
- ARCHITECTURE_BRIEF §2 Phase 2 "전자계약" 표기 존재. PHASE3 N3-3 "영문 계약서 + 한국법 준거법 명시 + 면책 문구"
- ❌ 실제 **PDF 생성 + 전자서명 캡처 + 법적 효력 보장 + 보관 (5년 D17)** 0%
- 한국 전자서명법 §2: 전자서명의 효력 = 본인 의사 확인 + 위변조 방지 + 시점 확인

#### linko.my 대비 격차
- linko: Professional 플랜 포함. 회원이 앱에서 손가락 서명 → PDF 자동 생성 → 양측 보관 → 분쟁 시 audit log 제출
- facing: 0%. PT 입회·환불·약관 동의 모두 종이/대면 의존

#### PHASE4 구현 계획

**Schema 추가**:
```sql
CREATE TABLE contract_template (
  id SERIAL PRIMARY KEY,
  gym_id INT,
  contract_type VARCHAR(50),        -- membership / pt_lesson / refund_agreement / personal_info
  html_template TEXT,               -- Jinja2 placeholder ({{member_name}} 등)
  required_signers VARCHAR(50)[],   -- ['member', 'gym']
  version INT,
  active BOOLEAN DEFAULT TRUE
);

CREATE TABLE contract_instance (
  id BIGSERIAL PRIMARY KEY,
  gym_id INT NOT NULL,
  member_id INT NOT NULL,
  template_id INT,
  pdf_url VARCHAR(500),             -- Cloudflare R2 또는 Railway Volume
  status VARCHAR(20),               -- draft / pending / signed / void
  signed_at TIMESTAMPTZ,
  member_signature_image BYTEA,     -- PNG 캡처 (low-res 100x40)
  gym_signature_image BYTEA,
  ip_address VARCHAR(45),
  user_agent TEXT,
  trusted_timestamp VARCHAR(200),   -- KISA RFC 3161 TSA 응답 (옵션 — 분쟁 대비)
  audit_hash CHAR(64)               -- SHA256(payload + signature + timestamp)
);
```

**PDF 생성**:
- `weasyprint` (Python, Pretendard 폰트 내장) — HTML → PDF
- 표지 + 본문 + 서명 이미지 + audit footer (해시·시각·IP)
- 저장: Cloudflare R2 (PHASE3 N4-5 Cloudflare CDN free tier 와 동일 인프라)

**Endpoint**:
- `POST /api/v1/admin/contracts` — 사장이 template+member 선택 → instance draft 생성
- `GET /api/v1/contracts/<id>/sign-link` — 회원에게 카카오 알림톡 발송용 1회용 token URL (10분 만료)
- `POST /api/v1/contracts/<id>/sign` — 회원 폰에서 손가락 서명 + PDF 생성 + audit hash 저장
- `GET /api/v1/contracts/<id>/pdf` — RBAC (사장 + 본인만 다운로드)

**법적 효력 보강**:
- 전자서명법 §3: "전자서명의 효력은 본인 의사 확인되면 종이와 동등" — IP + UA + timestamp 3종 audit 으로 충족
- KISA TSA (Trusted TimeStamping Authority) 는 분쟁 발생 시 추가 — 30박스 도달 후 도입 (§3 위험)
- 5년 보존 (D17 개인정보 5년 + 국세기본법 §85-3 부속서류 5년)

**우선순위**: **P0** (한국 박스 사장 PT·환불 분쟁 핵심 — 1041 §12 Rank 2 해지 92% 자동화 필수 인프라)
**예상 공수**: **1주** (schema 2 + PDF + endpoint 4 + 사장PC UI + 회원폰 서명 캡처)

---

### §1.4 다지점 (Multi-location / Multi-tenant within Single Owner)

#### 현재 facing 상태
- ARCHITECTURE_BRIEF D18 "사장 다중 박스: `gym_managers` PK 복합키 (gym_id, login_id). 로그인 시 박스 선택 토글 + 통합 대시보드" — 정의됨
- D19 "코치 다중 박스: 동일 패턴. 코치 폰 박스 선택 토글" — 정의됨
- ⚠ **실제 구현 진척 ~30%**. PHASE3 P1 "박스 스위처 stub" 완료, 통합 대시보드·다박스 WOD 공유·매출 합산은 미완

#### linko.my 대비 격차
- linko Enterprise: 파트너 체육관 다지점 연결 (공지·회원권·매출 공유) + 출석 패드 (회원이 어느 지점이든 체크인) + 지점별 수강상품 구분
- facing: D18·D19 정의는 있으나 SSE 채널·매출 합산·WOD 공유 미구현

#### PHASE4 구현 계획

**Schema 확장**:
```sql
ALTER TABLE gym_managers ADD COLUMN is_owner BOOLEAN DEFAULT FALSE;
-- is_owner=true 인 사장은 자기 소유 모든 박스 통합 dashboard 권한

CREATE TABLE gym_group (                -- 다박스 묶음 (선택)
  id SERIAL PRIMARY KEY,
  owner_login_id VARCHAR(50),
  name VARCHAR(100),                    -- "FACING SEONGSU + GANGNAM"
  created_at TIMESTAMPTZ
);

ALTER TABLE gyms ADD COLUMN group_id INT REFERENCES gym_group(id);

ALTER TABLE class_session ADD COLUMN is_shared_across_group BOOLEAN DEFAULT FALSE;
-- 사장이 그룹 전체에 같은 WOD 공유 가능
```

**Endpoint**:
- `GET /api/v1/admin/group/dashboard` — 통합 매출·회원·코치 (사장이 그룹 owner 일 때만)
- `POST /api/v1/admin/gym-switcher` — 박스 토글 (세션 쿠키에 active_gym_id 갱신, assert_admin_gym 헬퍼 재사용)
- `POST /api/v1/admin/class-sessions/share-to-group` — 같은 WOD 그룹 전체 적용 (§1.1 예약 schema 연결)
- 회원 출석 패드: `POST /api/v1/admin/checkin/cross-gym` — 회원이 그룹 내 다른 지점 1회용 출석 (RLS 우회는 group_id 확인 후 허용)

**UI**:
- 사장 PC 헤더: 박스 dropdown (현재 active 표시) + "통합 보기" 토글
- 통합 대시보드: 박스별 매출·신규·이탈을 박스 컬러로 stacked bar
- 코치 폰: 박스 dropdown 비슷한 패턴 — 알림은 active 박스만, 통합 보기는 명시 선택

**Postgres RLS 정책 갱신**:
- PHASE3 N4-2 의 RLS 정책에 group_id 분기 추가
- `app.current_gym_id()` 외에 `app.current_group_id()` STABLE 헬퍼 신설
- 통합 dashboard 만 `current_group_id()` 사용, 그 외는 기존 `current_gym_id()` 유지 (안전 default)

**우선순위**: **P1** (Phase 3 초·중기는 단일 박스 사장 위주. 그룹 owner 는 30박스+ 시점 이후)
**예상 공수**: **2주** (schema 확장 + RLS 갱신 + 통합 dashboard + 박스 스위처 풀빌드 + 크로스짐 출석)

---

### §1.5 결제 강화 (Toss 빌링키 풀 + 자동 재시도 + Grace Period)

> linko 의 "링코페이 자체 결제 SDK" 는 facing 이 따라가지 **않는다**. PCI DSS scope 확장 + Toss·NICE 등 PG 사가 이미 충분히 안정적. 대신 빌링키 기반 자동결제 + 카드 재시도 + grace period 로 운영 부담을 0 으로 만든다.

#### 현재 facing 상태
- PHASE3 C-1·C-3·P0-8 완료: `gym_payment` 테이블 + Toss webhook HMAC + 환불·매출 dashboard
- ❌ Toss **빌링키 자동결제 정기실행** 0%. 회원 카드 자동 재시도 0%. 미납 grace period 0%.

#### linko.my 대비 격차
- linko: 링코페이로 카드 단말기 대체 + 구독형 회원권 자동결제 + 미납 자동 처리. 사장이 "결제 받기" 액션을 사실상 안 함
- facing: 사장이 매월 수동 결제 처리 중 (1041 §12 Rank 1 결제 오류·잘못된 청구 인용 58)

#### PHASE4 구현 계획

**Schema 추가**:
```sql
CREATE TABLE billing_key (
  id BIGSERIAL PRIMARY KEY,
  gym_id INT NOT NULL,
  member_id INT NOT NULL,
  toss_billing_key VARCHAR(200),    -- Toss 발급 빌링키 (암호화 권장)
  card_last4 VARCHAR(4),
  card_company VARCHAR(20),
  status VARCHAR(20) DEFAULT 'active', -- active/expired/revoked
  created_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ            -- 카드 만료
);

CREATE TABLE billing_schedule (
  id BIGSERIAL PRIMARY KEY,
  gym_id INT NOT NULL,
  member_id INT NOT NULL,
  billing_key_id BIGINT,
  next_charge_at TIMESTAMPTZ,
  amount INT,
  cycle VARCHAR(20),                -- monthly/quarterly/annual
  status VARCHAR(20),               -- active/paused/cancelled
  retry_count INT DEFAULT 0,
  grace_period_until TIMESTAMPTZ    -- 미납 시 grace period (3·7·30일)
);
```

**자동 재시도 정책**:
- 1차 실패: 24시간 후 재시도 + 회원 카카오 알림톡 "카드 결제 실패. {{retry_url}} 재시도"
- 2차 실패: 7일 후 재시도 + SMS fallback
- 3차 실패: grace period 30일 진입 → 30일 후 회원권 자동 정지 (D8 cancel flow 와 별개 — 미납은 자발적 해지 X)
- 체크인 차단은 grace 30일 끝나는 시점부터 (1041 §12 Rank 20 "결제 실패 → 체크인 차단 당혹" 회피)

**Endpoint**:
- `POST /api/v1/member/billing-keys` — Toss 빌링키 발급 (회원 폰 카드 등록 webview)
- `DELETE /api/v1/member/billing-keys/<id>` — 회원 직접 해지
- `POST /api/v1/admin/billing-schedules` — 정기결제 스케줄 등록 (회원권 가입 시 자동)
- `POST /api/v1/admin/billing-schedules/<id>/retry-now` — 사장이 즉시 재시도
- 백그라운드 APScheduler: 매일 03:00 next_charge_at 도래 schedule 스캔 + Toss billing-key API 호출

**우선순위**: **P0** (한국 박스 사장 수동 결제 부담 1순위)
**예상 공수**: **1주** (Toss 빌링키 API 통합 + schema 2 + 재시도 로직 + 회원 카드 등록 webview + 사장 PC 정기결제 dashboard)

---

### §1.6 WOD 디자인 도구 + 달력 + 복붙

#### 현재 facing 상태
- PHASE3 N1-1~N1-3 (스키마 6 테이블·movement_library 60·benchmark Korea/Custom) — schema 만 완료 가정
- ❌ **WOD 작성 UI (사장 PC 텍스트 에디터 + 동작 picker + RX/Scaled 분리 + 월간 캘린더 + 1주일 복붙)** 0%
- 1041 §12 Rank 11 "WOD 추적·청구 분리 (2개 앱)" — facing 통합 SSOT 강점

#### linko.my 대비 격차
- linko: 텍스트 기반 WOD + RX/Scaled 병기 + 유튜브 동작 영상 링크 + 월별 캘린더 + 복사/붙여넣기 + 다지점 WOD 공유
- facing: schema 만 있고 사장 UI 0%. 폰은 본인 페이싱 결과만 표시

#### PHASE4 구현 계획

**Endpoint**:
- `POST /api/v1/admin/wod-sessions` — WOD 작성 (movement_library picker + 횟수·중량·시간 + RX/Scaled 두 가지 작성)
- `POST /api/v1/admin/wod-sessions/<id>/duplicate?to_date=...` — 1주일/1달 복사
- `POST /api/v1/admin/wod-sessions/<id>/share-to-group` — §1.4 다지점 그룹 전체 공유
- `GET /api/v1/admin/wod-sessions?month=2026-06` — 월간 캘린더 뷰

**UI (사장 PC)**:
- `/admin/wod-calendar` — 월간 캘린더 (FullCalendar.js 또는 자체) + 드래그앤드롭 복사
- 클릭 → 사이드패널 WOD 작성/편집 (movement picker + 횟수 + scoring_type 드롭다운 + RX/Scaled 두 탭)
- YouTube 링크 필드 (외부 video — N1-5 study 결론대로 자체 호스팅 X)

**facing 만의 보강** (§2.1 페이싱 알고리즘 연계):
- WOD 작성 후 "회원별 페이싱 미리보기" 버튼 → §2.1 알고리즘 호출 → 12명 회원 분할 시퀀스 1-클릭 코칭 카드 생성

**우선순위**: **P1** (Phase 3 N1 schema 완료 후 — UI 만 추가하면 됨)
**예상 공수**: **1주** (사장 PC 월간 캘린더 + 작성 모달 + 복사 + 회원 폰 표시는 기존 SSE 채널 재사용)

---

### §1.7 AI 코칭 Beta (조심스러운 도입)

> linko 의 "AI 체육관 운영 매니저 운영 효율 500% 향상" 클레임은 검증 불가. facing 은 **Beta 딱지 절대 안 붙임**. AI 는 facing 의 페이싱 알고리즘 정밀화 (§2.1) 에 종속된 보조 도구로만 도입.

#### 현재 facing 상태
- ❌ AI 0%. ARCHITECTURE_BRIEF §0-A LLM 분기 룰만 정의됨 (Claude 사용 강제)

#### linko.my 대비 격차
- linko: "AI 운동 프로그램 자동 생성" + "AI 체육관 운영 매니저" + "AI 보조 코칭" 3종, 모두 Beta. 실제 검증 미공개
- facing: 도입 안 함이 차별화. **"우리는 Beta AI 안 씁니다. 검증된 알고리즘만"** 으로 마케팅 가능

#### PHASE4 구현 계획 (제한적 도입)

**조건**: linko 의 AI 흡수가 **아니라**, facing 의 페이싱 알고리즘을 LLM 으로 **설명** 하는 보조 레이어만.

- `POST /api/v1/coach/wod-pacing-explain` — Claude API 호출 (배포 환경) 또는 Claude CLI (로컬). 회원 1RM·Engine·Tier + WOD 정의 → "왜 이 분할 시퀀스인가" 자연어 1~2단락 코칭 메모 생성
- 코치가 회원에게 보내기 전 검토 의무 (Human-in-the-loop, OWASP LLM Top10 LLM05)
- 회원 폰에는 코치 검토·승인된 메모만 표시
- **금지**: AI 가 직접 WOD 생성·페이싱 결정. 항상 알고리즘 = 진실, AI = 설명자

**비용**:
- prompt caching (system prompt 회원 데이터 모델 캐시) → 입력 토큰 90% 절감
- 박스당 월 ~30 WOD × 12 회원 × ~500 입력 tokens = ~180K tokens/박스/월
- 100박스 = 18M tokens/월 ≈ $13/월 (Claude Sonnet 4.5 입력 단가 기준, 캐싱 절감 후)

**우선순위**: **P2** (PHASE4 후기 — §2.1 페이싱 알고리즘 정밀화 완료 후)
**예상 공수**: **3일** (LLM 호출 wrapper + prompt 설계 + 코치 승인 UI)

---

## §2. 차별 강화 — 선수 도구 (facing 만)

### §2.1 W-prime·CGM 페이싱 알고리즘 정밀화

#### 현재 facing 상태
- `services/facing/docs/refer/` 10 카테고리 findings.md SSOT 존재 (백엔드)
- `services/facing/engine/` 모듈 존재 — Phase 1 기본 알고리즘 동작
- ❌ W-prime 모델 (Skiba 2012, Critical Power 기반 무산소 capacity 회복 동역학) 미적용
- ❌ CGM (Continuous Glucose Monitor) 통합은 v2 로드맵 (웨어러블 — linko 도 못 함)

#### linko.my 대비 격차
- linko: WOD 텍스트 + RX/Scaled + YouTube 링크. 페이싱 알고리즘·W-prime·1RM 기반 분할 0% (linko §7 약점 §7.3)
- facing: 이미 있는 영역. 깊이를 더 파면 **linko 가 절대 못 따라옴**

#### PHASE4 구현 계획

**알고리즘 보강**:
1. **W-prime balance 모델** (Skiba JAP 2012)
   - 회원 CP (Critical Power) 추정: Run 500m + 2km TT 입력 → 2-parameter 모델
   - W' (Anaerobic capacity) 추정: 30초 max effort (Wingate-style) 또는 Power 카테고리 데이터로
   - WOD 진행 중 시점별 W' 잔량 → 분할 시퀀스 자동 추천

2. **1RM 비례 페이싱**:
   - Thruster 95lb @ 1RM 135lb (70%) = unbroken 가능
   - 80%+ = burst 5-3-2 분할 권장
   - 90%+ = single-single
   - **§13 권장 7 "1RM 기반 개인화 페이싱"** 직접 구현

3. **Burst point 예측**:
   - 분할 시퀀스 + 회원 HR zone (가용 시) → 한계점 도달 round 예측
   - 코치에게 "8라운드 차에서 휴식 push 권장" 코칭 카드

**Endpoint**:
- `POST /api/v1/pacing/calculate` — 기존 endpoint 보강. W' 모델 입력 추가
- `GET /api/v1/member/<id>/cp-estimate` — CP·W' 추정값 + 신뢰도
- `POST /api/v1/coach/wod-pacing-batch` — WOD + 12 회원 일괄 페이싱 (§13 Rec 7 1-클릭)

**우선순위**: **P0** (facing 의 진짜 차별화 — linko 가 못 함)
**예상 공수**: **2주** (논문 검토 1주 — 백엔드 `docs/refer/` 갱신 + 알고리즘 구현 1주)

---

### §2.2 5-Tier 시스템 + 1RM Engine 백분위

#### 현재 facing 상태
- Tier 5단계 (Scaled/RX/RX+/Elite/Games) UI 완료
- 1RM Engine 6 카테고리 백분위 산출 완료
- ❌ 박스 단위 leaderboard (PHASE3 N1-6) 미완 + 다박스 비교 미정의

#### linko.my 대비 격차
- linko: 회원 기록 저장소만, 백분위·티어 0%

#### PHASE4 구현 계획

**박스 내 leaderboard** (PHASE3 N1-6 보강 + PHASE4 보강):
- RX leaderboard / Scaled leaderboard 분리 (PHASE3 v2 §2.3 합의)
- 5-Tier 분포 차트 (사장 PC dashboard) — 박스의 평균 티어 수준 시각화
- 동일 티어 회원 간 매칭 — buddy assign (D11) 알고리즘 보강

**Engine 백분위 전국 비교** (옵션, PHASE4 후기):
- 익명 집계 — 박스 평균 Engine 점수 ± 1σ 와 facing 전국 평균 비교
- 박스 마케팅 — "FACING SEONGSU 평균 Engine = 72 (전국 +12 상위)"

**Endpoint**:
- `GET /api/v1/admin/leaderboard?scale=rx&movement=fran` — 박스 내 동작별 ranking
- `GET /api/v1/admin/tier-distribution` — 박스 5-tier 분포
- `GET /api/v1/admin/engine-comparison?anonymized=true` — 전국 비교 (집계만)

**우선순위**: **P1** (PHASE3 N1-6 의 자연스러운 확장)
**예상 공수**: **3일**

---

### §2.3 Games 선수 어휘·톤 (HWPO·NOBULL)

#### 현재 facing 상태
- `apps/facing-app/CLAUDE.md` V1~V11 voice & tone rule 11건 SSOT 완비
- 폰 앱 — RX·Elite·Games 어휘 정착

#### linko.my 대비 격차
- linko: "체육관 운영 매니저" — 운영자 관점 단어, 선수 어휘 없음

#### PHASE4 구현 계획

**PC 사장 웹 톤 통일**:
- ARCHITECTURE_BRIEF D20 "PC 사장 = 전체 한글" 유지 (한국인 사장)
- 단, 회원 표시 카드 (회원 등급 표기·Engine 점수)에 facing 폰의 V1~V11 영문 톤 일관성 적용
- 사장 PC 도 회원 디테일 사이드패널은 "Your Tier" 형식

**카피 SSOT 통합**:
- 폰 V1~V11 → 사장 PC 회원 카드·통계 라벨에도 부분 적용
- 코치 폰은 폰 SSOT 그대로

**우선순위**: **P2** (이미 핵심은 동작 중, 다듬기)
**예상 공수**: **2일**

---

### §2.4 듀얼 포지셔닝 — 선수 + 박스 (facing-app Tier ↔ 박스 SaaS 연동)

> **§13 권장 4 — facing 의 진짜 무기. linko 가 절대 따라올 수 없는 영역.**

#### 현재 facing 상태
- facing-app 폰 (회원 개인 사용자용) 과 facing 박스 SaaS (사장·코치 PC + 코치 폰) 백엔드 동일
- ❌ **회원이 facing-app 으로 입력한 1RM·Engine·Tier 가 박스 등록 시 코치에게 자동 공유되는 흐름** 0%

#### linko.my 대비 격차
- linko: B2B만 (박스 운영자용). 개인 사용자 분석 앱 없음
- facing: B2B + B2C 동시 운영 — 회원이 facing-app 으로 시작 → 박스 가입 시 데이터 자동 hydrate → 코치 데이터 코칭

#### PHASE4 구현 계획

**B2B2C 데이터 브릿지**:
1. **회원이 facing-app 에서 입력한 1RM·Engine·Tier**:
   - device_hash 익명 → 박스 가입 시점에 회원 동의 받고 `gym_members.linked_device_hash` 연결
   - 코치 폰 회원 카드에 "Engine 72 (RX 진입 -3점) · Thruster 1RM 145lb · last PR 14일전" 표시

2. **WOD 페이싱 동의 흐름**:
   - 회원이 폰 앱에서 "박스 코치가 내 페이싱 데이터 사용 동의" 토글 (PIPA §22 별도 동의)
   - 동의 시 코치 페이싱 batch (§2.1) 에 포함, 미동의 시 기본 RX 값으로 추정

3. **코치 데이터 코칭** (CompTrain 스타일):
   - 코치 폰 "WOD 시작" 탭 → 오늘 클래스 12명 카드 → 각 회원 분할 시퀀스 자동 + 한계 round 예측
   - 코치가 카드 1탭 → 회원 폰에 페이싱 카드 push (SSE)

**Endpoint**:
- `POST /api/v1/member/link-facing-app` — device_hash 연결 + 동의
- `GET /api/v1/coach/class-pacing?class_session_id=...` — 클래스 회원 일괄 페이싱 카드
- `POST /api/v1/coach/push-pacing-card` — 회원 폰에 SSE push

**마케팅 메시지**:
- "facing 박스의 모든 회원은 자기 폰에서 자기 데이터를 봐요. 코치는 모든 회원 페이싱을 1탭으로 봐요. linko 는 못 해요."

**우선순위**: **P0** (facing 의 진짜 비교 불가 영역)
**예상 공수**: **1주** (device_hash 연동 + 동의 흐름 + 코치 UI + 페이싱 카드 SSE)

---

## §3. 우선순위 매트릭스 (Impact x Effort)

| 모듈 | Impact | Effort | 우선순위 | 비고 |
|---|---|---|---|---|
| §1.1 예약 시스템 | High | 1주 | **P0** | 한국 박스 운영 필수 |
| §1.2 카카오 알림톡 | High | 3일 + NHN 가입 1주 | **P0** | retention 결정적 |
| §1.3 전자계약 | High | 1주 | **P0** | 해지 분쟁 92% 자동화 |
| §1.5 Toss 빌링키 자동결제 | High | 1주 | **P0** | 결제 부담 0 |
| §2.1 W-prime 페이싱 알고리즘 | High | 2주 | **P0** | linko 격차 |
| §2.4 듀얼 포지셔닝 B2B2C | High | 1주 | **P0** | linko 가 못 함 |
| §1.4 다지점 그룹 | Mid | 2주 | P1 | 30박스+ 시점 |
| §1.6 WOD 디자인 도구 | Mid | 1주 | P1 | UI 만 추가 |
| §2.2 Tier·Engine 백분위 leaderboard | Mid | 3일 | P1 | N1-6 확장 |
| §1.7 AI 코칭 보조 | Low | 3일 | P2 | §2.1 완료 후 |
| §2.3 카피·톤 통일 | Low | 2일 | P2 | 다듬기 |

**P0 모듈 6개 총 공수**: 1+0.4+1+1+2+1 = **6.4주** (parallel 가능 = ~5주 실효)
**P1 모듈 3개**: 2+1+0.4 = 3.4주
**P2 모듈 2개**: 0.4+0.3 = 0.7주
**PHASE4 전체**: ~9~10주 (sequential) / ~7~8주 (parallel)

---

## §4. PHASE4 WEEK BY WEEK (4 주 P0 집중)

### Week 1 (P0 시작 — 외부 의존 먼저)

- [ ] **§1.2-prep** NHN Cloud Bizmessage 비즈채널 가입 + 8 템플릿 사전심사 제출 (외부 1주 대기)
- [ ] **§1.5-prep** Toss 빌링키 통합 — Toss 가맹점 신청 검토 + 빌링키 API 테스트 환경 키 발급
- [ ] **§1.3** 전자계약 schema 2 테이블 + weasyprint 도입 + contract_template 1건 (membership) 작성
- [ ] **§1.1** 예약 schema 3 테이블 + endpoint 5 backend 절반 (POST·GET 명단·POST 예약)

### Week 2 (P0 백엔드 마무리)

- [ ] **§1.1** 예약 endpoint 나머지 (취소·noshow·waitlist 자동 승격) + SSE class-reservation-changed 채널
- [ ] **§1.3** 전자계약 sign endpoint + audit hash + 회원 서명 webview (Flutter signature_pad)
- [ ] **§1.5** 빌링키 발급 webview + billing_schedule 스케줄러 (APScheduler 03:00) + 1차 재시도 로직
- [ ] **§2.4-1** facing-app device_hash ↔ gym_members 연결 + PIPA §22 별도 동의 토글

### Week 3 (P0 UI + 알고리즘)

- [ ] **§1.1 UI** 사장 PC `/admin/classes` 월간 캘린더 + 발행 모달 + 코치/회원 폰 예약 UI
- [ ] **§1.2** NHN 비즈채널 승인 도착 시점 — 8 시퀀스 통합 + SMS fallback + dispatch dashboard
- [ ] **§1.5** 자동 재시도 2차·3차 + grace period + 미납 dashboard
- [ ] **§2.1** W-prime 모델 구현 — `services/facing/docs/refer/` 갱신 + engine 코드 보강

### Week 4 (P0 마무리 + P1 시작 + 차별화)

- [ ] **§2.1** W-prime 통합 + WOD pacing batch endpoint (12명 일괄)
- [ ] **§2.4** 코치 폰 클래스 페이싱 카드 UI + push-pacing-card SSE
- [ ] **§1.6** WOD 디자인 도구 UI — 월간 캘린더 + 작성 모달 (P1 진입)
- [ ] **§2.2** 박스 leaderboard + 5-tier 분포 차트 (PHASE3 N1-6 자연 확장)
- [ ] **Phase 4 회고** + 100박스 측정 (예약 노쇼율·결제 자동화율·코치 사용률)

### Week 5~6 (P1)

- [ ] **§1.4** 다지점 그룹 (gym_group + RLS 갱신 + 통합 dashboard + 크로스짐 출석) — 2주
- [ ] **§1.6** WOD 디자인 마무리 (다지점 공유 + 회원별 페이싱 미리보기)

### Week 7~8 (P2 + 안정화)

- [ ] **§1.7** AI 코칭 보조 (Claude API + prompt caching + 코치 승인 UI)
- [ ] **§2.3** 카피·톤 통일 (PC 사장 회원 카드 V1~V11 부분 적용)
- [ ] PHASE4 통합 테스트 + 5박스 파일럿 RITE 라운드 (Nielsen 5-user)

---

## §5. 측정 지표 (Phase 4 종료 시점)

| KPI | 목표 | 측정 방법 |
|---|---|---|
| 박스 가입 N | 150~200개 (Phase 3 종료 100 → +50~100) | gyms 테이블 active count |
| 카카오 알림톡 발송 성공률 | 95%+ | notification_dispatch.status='delivered' / total |
| 예약 노쇼율 | 8% 이하 | reservation.status='no_show' / 총 예약 |
| 자동결제 성공률 (1차) | 92%+ | billing_schedule.retry_count=0 비율 |
| 전자계약 발행률 | 신규 가입 90%+ 종이→전자 전환 | contract_instance status='signed' / 신규 회원 |
| 듀얼 포지셔닝 — facing-app 연동 회원 | 30%+ | gym_members.linked_device_hash NOT NULL |
| 코치 페이싱 카드 푸시 수 | 회원당 월 8건+ | push-pacing-card 호출 수 |
| 박스 NPS | 60+ (Phase 3 종료 50 → +10) | 분기 + 30일 자동 트리거 |
| Phase 4 break-even | 150박스 (PHASE3 v2 §10 60박스 break-even 기반 추정) | 월 매출 - 인프라 - 인건비 |

---

## §6. 위험·의존성

### §6.1 외부 의존성 (시간 통제 불가)

| 의존 | 영향 | 회피 전략 |
|---|---|---|
| NHN Cloud 비즈채널 사전심사 | 7~14일 대기 | Week 1 제일 먼저 신청 + Aligo 백업 채널 가입 |
| Toss 가맹점 등록 검토 | 5~10일 | 이미 PHASE3 C-1 완료 가정. 빌링키 추가는 기존 가맹점 ID 사용 |
| 전자서명 법적 효력 (TSA) | 30박스 도달 후 분쟁 발생 시 | KISA RFC 3161 TSA 도입 미루기 — audit hash·IP·UA 3종으로 1차 충분 |
| 카카오 비즈채널 사전 승인 템플릿 거절 | 1~2주 재작업 | 보수적 문구 작성 — 광고성 단어 회피 |

### §6.2 기술 위험

| 위험 | 영향 | 완화 |
|---|---|---|
| Postgres RLS + 다지점 그룹 누수 | 박스 A 사장이 박스 B 데이터 조회 | gym_group RLS 정책 추가 시 별도 staging 환경에서 7일 회귀 테스트 + ARCHITECTURE_BRIEF §11 변경 절차 |
| Toss 빌링키 자동결제 중복 청구 | 회원 분노 + 환불 폭증 | advisory lock (PHASE3 v2 §5.4) + idempotency key 의무 + webhook reconciliation |
| 예약 waitlist race condition | 동시에 2명 자리 차지 | PostgreSQL `SELECT FOR UPDATE` + `class_reservation` UNIQUE 제약 |
| AI 코칭 LLM 환각 (페이싱 잘못 추천) | 회원 부상·신뢰 손실 | HITL 의무 + AI 메모는 항상 "코치 검토 필요" 워터마크 + 알고리즘 = 진실, AI = 설명자 |

### §6.3 법적·운영 위험

| 위험 | 완화 |
|---|---|
| 전자서명법 §3 본인 의사 확인 분쟁 | IP+UA+timestamp 3종 audit + 가입 시점 별도 동의 토글 + 30박스 시점 변호사 자문 (PHASE3 N3-3 와 합산) |
| 개인정보보호법 §22 PIPA 별도 동의 (페이싱 데이터 코치 공유) | §2.4 명시 동의 토글 + 미동의 시 기본 RX 값 처리 — 토글 해제는 언제든 가능 |
| 카카오 알림톡 광고성 메시지 분쟁 | 정보성 (만료 안내·예약 확정) 와 광고성 (마케팅 쿠폰) 분리 + 광고성은 별도 동의 (PHASE3 v2 §3.5) |
| 다지점 그룹 owner 권한 남용 (회원 데이터 광역 접근) | audit log 강화 + RLS 정책에 group 권한 분리 + owner 위임 시 별도 동의 |

### §6.4 PHASE3 의존성

- PHASE3 P0 18 task **반드시 완료 후** PHASE4 진입
- 특히 N1 (CrossFit 도메인 6 테이블) · H-1 (PostgreSQL+RLS) · N5-1 (Sentry) 완료 의무
- 예외: PHASE3 P1 의 N3 (i18n EN) 는 PHASE4 와 병행 가능 (글로벌 진출 트리거 다름)

---

## §7. 듀얼 포지셔닝 — 마케팅 메시지 (PHASE4 종료 시점)

| 청중 | 메시지 |
|---|---|
| 박스 사장 (linko 와 비교) | "예약·결제·계약·알림 다 자동화. 더해서 회원 페이싱 데이터까지 1탭. linko 는 운영, facing 은 운영+선수." |
| 박스 코치 | "오늘 클래스 12명 페이싱 1탭. CompTrain 처럼 데이터 코칭." |
| 일반 회원 | "facing 폰 앱 = 내 데이터. 박스 등록 시 코치가 같은 데이터로 코칭. 분리되지 않음." |
| 엘리트 선수 | "RX·Elite·Games 5-tier. W-prime + 1RM 기반 페이싱. Sugar WOD 가 아니에요." |

---

## §8. 변경 이력

- **2026-05-23 (오버나이트 자율 작성)**: PHASE4 ROADMAP v1 작성. linko.my 분석 7 영역 흡수 모듈 + facing 차별화 4 모듈 = 11 모듈. P0 6 / P1 3 / P2 2. 4~8주 sequential / 7주 parallel. 외부 의존 (NHN·Toss·카카오) Week 1 선행 의무. ARCHITECTURE_BRIEF §11 변경 절차 따라 schema 변경 시 SSOT 동기 PR 의무 명시.

---

## §9. 다음 단계

1. 본 로드맵을 ARCHITECTURE_BRIEF §11 변경 절차에 등록 — schema 변경 (§1.1 예약 3 / §1.2 알림 2 / §1.3 계약 2 / §1.4 다지점 1 + 2 alter / §1.5 빌링 2 = 12 신규 + 3 alter) 사전 합의 필요
2. PHASE4_TODO.md 작성 — 본 로드맵의 11 모듈을 task 단위로 쪼개기 (예상 ~80 task)
3. NHN Cloud Bizmessage 사전심사 제출 — PHASE4 Week 1 첫 task. 외부 의존 시간 회수
4. Toss 빌링키 통합 검토 — PHASE3 C-1 완료 후 PG 사 추가 협의 단계 진입
