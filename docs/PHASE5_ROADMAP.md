---
domain: facing
type: phase-roadmap
phase: 5
last_updated: 2026-05-23
status: planning
prerequisite: PHASE4 P0 완료 후 시작
---

# PHASE5 ROADMAP — 사장 폰판 보조 운영 (linko 격차 해소)

## §0. 배경

- linko 9 스크린샷 분석에서 발견 — 사장이 폰에서 모든 운영 가능 (회원 상세 6탭·회원 정보 수정·센터 dashboard·예약 명단·공지 등).
- facing 의 "PC-only" 가정이 외출·이동 중 사장의 큰 불편 + 즉시 응대 못함.
- 출처: `docs/linko-feature-gap.md §4.2` — facing PHASE3·4 와의 운영 격차 분석.
- PHASE5 는 사장 폰판 추가, 기존 PC 화면은 유지 (parallel — PC 사장 운영 흐름은 그대로).
- 브리프 §2 RBAC 갱신 완료 (§11.4 변경 등록).

---

## §1. 추가 모듈 (5개)

### §1.1 사장 폰 로그인·라우팅

- facing-app 진입 시 `user_type` 분기:
  - `device_hash` → 회원·코치 (기존 익명 플로우)
  - `login_id` → 사장·매니저 (PC 동일 ID/PW)
- 사장 ID/PW 폰 로그인 시 `boss_dashboard` 진입.
- 자동 로그인 (refresh_token) 보장 — 매번 로그인 X.
- 로그아웃 시 device_hash 익명 플로우로 복귀.

### §1.2 사장 dashboard (linko 사진 7 매칭)

- 박스 카드 (이름·전화·이미지)
- COACH/BOSS 배지 (한 사람 두 역할 가능)
- "회원 운영 관리" 큰 CTA → 회원 list
- **오늘의 수업 카드** (수업명·코치·예약자 수·시간 + "예약자 명단 확인" 버튼) — PHASE4 §1.1 예약 데이터 활용
- 공지 list (최근 5건). 새 공지 작성은 PC 만 (폰 작성 P1 검토)
- SSE 알림 뱃지 (미응대 신규 신청·결제 실패 등)

### §1.3 회원 list + 상세 6탭 (linko 사진 6 매칭)

- 회원 검색 (이름·전화) + 필터 (활성·만료·이탈위험)
- 회원 row 클릭 → 상세 6탭 (회원권·결제·출석·계약서·메모·Risk)
- PC 화면과 **동일 endpoint·동일 권한** — 단지 폰 UI 레이아웃
- 6탭 내부 상세 화면은 PC 와 fields 동일, 모바일 viewport 최적화 (탭 가로 스크롤 X — 세로 스택)

### §1.4 회원 정보 수정 (linko 사진 5 매칭)

- 회원 폼 (이름·생년월일·전화번호·성별·사진 업로드)
- 전화번호 변경 시 "확인" 버튼 → SMS OTP 인증 (linko 와 동일)
- "저장하기" 버튼 비활성/활성 토글 (변경 사항 있을 때만)
- 사진 업로드 — 갤러리·카메라 둘 다

### §1.5 사장 알림 받기 + 액션

- SSE 알림 (PHASE3 §4 admin_events 채널 확장):
  - 신규 회원 신청 (member_join_request)
  - 결제 실패 (billing_failed)
  - 이탈위험 high (member_risk_high) — PHASE4 §2.2 leaderboard 와 연동
  - 예약 만석/취소 (class_full / class_cancelled)
- 알림 클릭 → 해당 회원·결제·예약 상세로 **deep link**
- Tier 1 푸시 알림 (CLAUDE.md 룰 따름 — 외출 중 즉시 응대)

---

## §2. 영향 분석 (기존 시스템 변경)

### §2.1 인증·라우팅

- **facing-app**:
  - `lib/core/auth/` 신규 또는 확장 — `login_id` 분기 진입
  - 진입 라우터: `user_type` 검사 → `device_hash` flow 또는 `login_id` flow
  - JWT 또는 refresh_token 저장 (`shared_preferences` 안 됨 — `flutter_secure_storage` 권장)
- **백엔드**:
  - 기존 admin login endpoint (`/api/v1/admin/login`) 가 폰에서도 호출 가능하게
  - 또는 새 endpoint 분리 (`/api/v1/admin/login-mobile`) — `X-Device-Id` 헤더 받아 audit log 강화

### §2.2 권한 분기

- 폰에서 `boss`/`manager` 로그인 → boss role 권한 그대로 부여 (PC 와 동일 RBAC).
- 매니저 권한 enum 신규 — 백엔드 `gym_managers.role` 컬럼에 `'manager'` 값 추가.
- `coach` 도 PHASE5 에서 폰 보조 운영 일부 확장 검토 (코치별 본인 담당 회원 관리) — P2 로 분리.

### §2.3 UI 토큰 일관성

- PC 와 폰 같은 색·타이포 (FacingTokens) 유지.
- 단, 폰 사장 화면은 회원·코치 폰 화면과 **다른 헤더 배경** (예: `surface` 대신 `bg+border` 강조) — 역할 시각 구분.
- 사장 dashboard 는 모바일 viewport (375~430dp) 최적화. PC 740dp 와 다른 grid.

### §2.4 데이터 모델

- 신규 테이블 0 (기존 PHASE3/4 테이블 재사용).
- ALTER 1건:
  - `gym_managers.last_mobile_login_at` (TIMESTAMP, nullable) — 사장 폰 로그인 추적용 audit.

---

## §3. 우선순위·공수

| 모듈 | Impact | Effort | 순위 |
|---|---|---|---|
| §1.1 사장 폰 로그인·라우팅 | High | 2일 | **P0** |
| §1.2 사장 dashboard | High | 4일 | **P0** |
| §1.3 회원 list+상세 6탭 | High | 1주 | **P0** |
| §1.4 회원 정보 수정 (SMS OTP 포함) | Medium | 2일 | P1 |
| §1.5 사장 알림+deep link | Medium | 3일 | P1 |

**P0 합계**: ~9일 / **전체**: ~2~3주

---

## §4. 측정 KPI (Phase 5 종료 시)

- 사장 폰 일 사용 빈도 (DAU/WAU) — 목표: WAU 80%+
- 외출 중 회원 응대 처리 건수 — 목표: 주 3회+
- 회원 가입 신청 응답 시간 (PC vs 폰) — 목표: 폰 응답 < 10분
- 사장 만족도 NPS — Phase 5 종료 시 인터뷰

---

## §5. 의존성

- **PHASE4 P0** (예약·전자계약·알림톡·Toss 빌링키) 완료 후 시작 권장.
- 단, **일부 모듈 병행 가능**:
  - §1.1 사장 폰 로그인 — PHASE4 와 무관, 선행 가능
  - §1.2 사장 dashboard — 데이터만 보여주므로 PHASE4 와 병행 가능
  - §1.3 회원 list+6탭 — PHASE3 데이터 그대로 사용
- §1.5 알림 deep link 는 PHASE4 §1.1 예약·§1.5 빌링 endpoint 의존 — PHASE4 완료 후만 가능.

---

## §6. 브리프 변경 등록

`docs/ARCHITECTURE_BRIEF.md §11.4` 에 PHASE5 §2 RBAC 갱신 항목 등록 완료 (2026-05-23).

PHASE5 착수 시 §10 결정사항 표에 D-번호 부여:
- D-PHASE5-1: 사장 폰 보조 운영 도입 (linko 격차 해소)
- D-PHASE5-2: 매니저 역할 신규 (사장 위임 운영권)
- D-PHASE5-3: `user_type` 진입 분기 (device_hash vs login_id)

---

## §7. 회피 사항 (linko 답습 X)

- linko 사진 5 의 "저장하기" 비활성/활성 토글 → 채택 (UX 좋음)
- linko 사진 6 의 6탭 횡 스크롤 → **회피** (facing 폰은 세로 스택 또는 탭 압축 3+3)
- linko 의 사진 업로드 → 채택, 단 facing tier 시스템과 연동 (회원 프로필 사진은 게이미피케이션 X 가정 유지)
- linko 와 동일한 "사장 폰에서 모든 것 가능" 가정은 채택하되, facing 의 PC 우위 (대시보드·통계·계약·정산) 는 유지 — 폰은 **보조** 강조.
