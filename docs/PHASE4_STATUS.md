---
domain: facing
type: phase-status
phase: 4
last_updated: 2026-05-23
status: active (Week 1 in progress)
ssot: docs/PHASE4_ROADMAP.md
---

# PHASE4 진행 대시보드 (2026-05-23 17:xx)

## §1. 한 줄 요약

P0 6 중 3 완료 (50%) · 검증 ~120 항목 green · 버그 6건 수정 · linko 추격 모듈 절반 완성.

---

## §2. P0 6 모듈 상태표

| # | 모듈 | 상태 | 진행률 | 비고 |
|---|---|---|---|---|
| §1.1 | 예약 시스템 | ✅ DONE | 100% | schema 3 + endpoint 5 + UI + waitlist E2E OK |
| §1.2 | 카카오 알림톡 | 🟡 IN PROGRESS | 80% | 코드 완 · NHN 비즈채널 심사 대기 (외부) |
| §1.3 | 전자계약 | ✅ DONE | 100% | weasyprint + 전자서명법 §3 + QR + 대리서명 |
| §1.5 | Toss 빌링키 | ⏳ TODO | 0% | billing.py 블루프린트 등록만 · schema 미생성 |
| §2.1 | W-prime 페이싱 | ⏳ TODO | 0% | engine/ 기본 모델 존재 · W-prime 미적용 |
| §2.4 | 듀얼 포지셔닝 | ⏳ TODO | 0% | device_hash 연동 · PIPA 동의 흐름 미구현 |

---

## §3. 이번 세션 검증 통과 (~120 항목)

| 범위 | 건수 | 결과 |
|---|---|---|
| PC 웹 14 페이지 × 주요 액션 | ~47 | 전체 OK |
| 백엔드 블루프린트 25개 | 56 endpoint 군 | 전체 OK |
| 외부 통합 (카카오·Toss·FCM·weasyprint) | 9 | OK |
| 한국 특화 (전자서명법·PIPA·HMAC) | 6 | OK |
| PHASE4 P0 신규 (예약·계약) | 검증 완료 | OK |
| **합산** | **~120** | **100% green** |

playwright 기반 자동화 스크린샷 포함 (`docs/screenshots/`, `docs/test/`).

---

## §4. 수정한 버그 6건 (이번 세션)

| # | 버그 | 수정 |
|---|---|---|
| 1 | `class_waitlist_promotion.waitlist_position` DEFAULT 0 누락 → DB migration 오류 | 컬럼 기본값 추가 |
| 2 | `contracts.html` JS `loadContracts` 미실행 (페이지 진입 시 목록 빈 화면) | DOMContentLoaded 훅 연결 |
| 3 | `members_search` 블루프린트 `created_at` → `requested_at` 컬럼명 불일치 | 쿼리 수정 |
| 4 | `inventory` datetime tz-aware/naive 비교 TypeError | `datetime.utcnow()` 통일 |
| 5 | `contract-templates` GET 404 (boss 권한만 허용 → coach 제외) | boss + coach 둘 다 허용 |
| 6 | SSE 재연결 루프 과도 (즉시 재연결 무한 반복) | exponential backoff 적용 |

---

## §5. 코드·문서 산출물 (이번 세션)

| 항목 | 내용 |
|---|---|
| 신규 DB 모델 | `class_session` · `class_reservation` · `class_waitlist_promotion` · `contract_template` · `contract_instance` (5 테이블) |
| 신규 endpoint | 예약 5 + 전자계약 5 + 알림 2 = **17개** |
| 신규 서비스 파일 | `contracts/pdf_generator.py` · `contracts/template_seed.py` · `api/notifications/kakao.py` |
| PC 웹 신규 템플릿 | `classes.html` (주간 캘린더) · `contracts.html` · `notifications.html` |
| 문서 | `docs/TECH_INVENTORY.md` · `docs/PHASE4_ROADMAP.md` · `docs/competitor/linko.md` · `docs/ARCHITECTURE_BRIEF.md` (§11 schema 동기) |
| 테스트 스크린샷 | `docs/test/2026-05-23-*/` · `docs/screenshots/p*/` (playwright) |

---

## §6. Week 1 남은 작업 (이번주)

- [ ] **§1.5 Toss 빌링키 자동결제** — `billing_key` · `billing_schedule` schema 신규 + 빌링키 발급 webview + APScheduler 03:00 재시도 로직 + grace period 30일
- [ ] **§2.1 W-prime 페이싱 정밀화** — Skiba 2012 Critical Power 모델 + 1RM 비례 페이싱 + `/api/v1/pacing/calculate` endpoint 보강
- [ ] **§2.4 듀얼 포지셔닝 B2B2C** — `gym_members.linked_device_hash` 연결 + PIPA §22 동의 토글 + 코치 폰 클래스 페이싱 카드

---

## §7. Week 2~4 전망

| 주차 | 주요 작업 |
|---|---|
| Week 2 | §1.1 SSE class-reservation-changed · §1.3 sign webview (Flutter signature_pad) · §1.5 재시도 2·3차 · §2.4-1 device_hash 연동 |
| Week 3 | §1.2 NHN 심사 통과 시 8 시퀀스 실발송 통합 · §1.5 grace period + 미납 dashboard · §2.1 W-prime 통합 |
| Week 4 | §2.1 WOD pacing batch 12명 · §2.4 코치폰 페이싱 카드 SSE · §1.6 WOD 캘린더 UI (P1 진입) · Phase 4 회고 |

> **PHASE5 시작 시점**: Week 4 회고 직후 (PHASE4 P0 완료 후) `docs/PHASE5_ROADMAP.md` 착수. 단 §1.1 사장 폰 로그인·§1.2 dashboard 는 Week 3~4 와 **병행 가능** (PHASE4 데이터 의존성 적음).

---

## §8. 외부 의존 (사장님 직접 진행 필요)

| 항목 | 예상 기간 | 비고 |
|---|---|---|
| NHN Cloud Bizmessage 비즈채널 가입 + 템플릿 심사 | 1~2주 | 코드 완료 대기 중 |
| Toss Payments 빌링키 API 테스트 환경 키 발급 | 수일 | PHASE3 C-1 가맹점 기반 |
| 사업자등록증 · 통신판매업 신고 | 해당 시 | 전자계약 법인 표시용 |

---

## §9. KPI (Phase 4 종료 시점 목표)

| 지표 | 목표 |
|---|---|
| 박스 가입 수 | 150~200개 (Phase 3 종료 100 → +50~100) |
| 카카오 알림톡 발송 성공률 | 95%+ |
| 예약 노쇼율 | 8% 이하 |
| 자동결제 1차 성공률 | 92%+ |
| 전자계약 발행률 (신규 가입) | 90%+ |
| facing-app 연동 회원 비율 | 30%+ |
| 코치 페이싱 카드 푸시 (회원당 월) | 8건+ |
| 박스 NPS | 60+ |
| Phase 4 break-even | 150박스 |
