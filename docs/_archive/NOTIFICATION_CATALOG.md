# facing — 알림 카탈로그 (E-1)

> **작성일**: 2026-05-23 (오버나이트)
> **목적**: 회원·사장·코치 트리거 매트릭스 SSOT. 채널별 본문 템플릿. 발송 우선순위.
> **연계**: `services/facing/services/expiry_scheduler.py` (C-2 자동 만료) · `api/webhooks/toss.py` (결제 webhook) · `api/fcm.py` (FCM stub) · 향후 `api/notifications/{sms,email,push}.py`

---

## 0. 한 줄

> **회원·사장·코치 3 시점 × 15 trigger × 4 채널 (SMS·메일·푸시·SSE) = 약 60 알림 매트릭스. 우선순위 P0 (block 위험)·P1 (운영 efficiency)·P2 (마케팅).**

---

## 1. 회원 대상 알림 (10 trigger)

| # | trigger | 채널 | 시점 | 본문 템플릿 |
|---|---|---|---|---|
| M1 | 가입 환영 | SMS + 메일 | 회원 status `pending → approved` 즉시 | `[FACING SEONGSU] {name}님 가입 환영합니다. 회원권 시작일 {start_date}` |
| M2 | 회원권 발급 | SMS | 회원권 생성 시 즉시 | `[FACING] {plan_name} ({months}개월) 발급 완료. 만료일 {end_date}` |
| M3 | 만료 7일 전 | SMS + 푸시 | 매일 03:30 cron | `[FACING] 회원권 7일 후 만료. 갱신은 박스 사장에게.` |
| M4 | 만료 3일 전 | SMS + 푸시 | 매일 03:30 cron | `[FACING] 회원권 만료 임박 (3일). 갱신 신청 부탁드려요.` |
| M5 | 만료 1일 전 | SMS + 푸시 | 매일 03:30 cron | `[FACING] 내일 회원권 만료. 갱신·연장 안 하면 자동 동결됩니다.` |
| M6 | 만료 당일 (동결) | SMS + 푸시 | 매일 03:30 cron | `[FACING] 회원권이 만료되어 체크인이 임시 비활성됐어요. 갱신 시 즉시 활성화` |
| M7 | 결제 완료 | SMS + 메일 (영수증 첨부) | Toss webhook DONE 또는 사장 수동 입력 | `[FACING] 결제 완료 ₩{amount:,}. 영수증 첨부 (메일 확인)` |
| M8 | 환불 완료 | SMS + 메일 | refund endpoint 호출 시 | `[FACING] 환불 ₩{refund_amount:,} 처리 완료. 영업일 3~5일 후 카드 반영` |
| M9 | 결석 7일 알림 | 푸시 | 매주 월요일 03:30 cron | `[FACING] 1주일 안 오셨어요. 운동 다시 시작해보세요!` (subscription-fitness §4.3 -33% cancellation 효과) |
| M10 | 출석 milestone | 푸시 | 30·90·365회 도달 즉시 | `[FACING] 출석 {n}회 달성! 🎯 (badge 자동 발급)` (SDT identified regulation) |

## 2. 사장 대상 알림 (8 trigger)

| # | trigger | 채널 | 시점 | 본문 템플릿 |
|---|---|---|---|---|
| B1 | 신규 가입 신청 | 푸시 + SSE | 회원 가입 신청 즉시 | `[FACING 사장] 신규 가입 신청 1건. PC dashboard 에서 승인` |
| B2 | 결제 수신 | 푸시 + SSE | Toss webhook DONE | `[FACING 사장] 결제 ₩{amount:,} from {member_name}. 회원권 자동 활성` |
| B3 | 환불 요청 | 푸시 + 메일 | 회원이 환불 요청 시 (UI 추가 예정) | `[FACING 사장] 환불 요청 — {member_name} ₩{amount:,}. 검토 필요` |
| B4 | 만료 임박 통계 | 메일 (요약) | 매주 월요일 09:00 | `[FACING 주간] 7일 안 만료 회원 N명. 갱신 권유 권고` |
| B5 | 출석 0인 알림 | 푸시 | 영업일 12:00 까지 출석 0 시 | `[FACING 사장] 오늘 점심까지 출석 0건. 회원에게 알림 보낼까요?` |
| B6 | 코치 페어링 완료 | 푸시 + SSE | 폰 페어링 성공 즉시 | `[FACING 사장] 코치 {coach_name} 폰 페어링 완료` |
| B7 | 코치 3개월 경과 | 푸시 + 메일 | hired_at +90일 cron | `[FACING 사장] 코치 {name} 입사 3개월. 일반근로자 전환 검토 필요 (labor-office §2.1)` |
| B8 | 박스 NPS 측정 | 메일 | 가입 후 30일 + 분기 1회 | `[FACING] 박스 운영 만족도 1~10 점수 부탁드려요 (Typeform 링크)` |

## 3. 코치 대상 알림 (5 trigger)

| # | trigger | 채널 | 시점 | 본문 템플릿 |
|---|---|---|---|---|
| C1 | 페어링 코드 발급 | SMS (사장 채널) → 코치 폰에 입력 | 사장이 코치 등록 시 | `[FACING] {coach_name} 페어링 코드: {code} (24h 유효)` |
| C2 | PT 예약 (회원→코치) | 푸시 | 회원이 예약 시 즉시 | `[FACING] {member_name} 님이 {time} PT 예약. 수락/거절` |
| C3 | PT 취소 (회원→코치) | 푸시 | 회원이 취소 시 즉시 | `[FACING] {member_name} PT 취소 ({time}). 24h 전이면 전액 환불` |
| C4 | 시급 정산 완료 | 푸시 + 메일 (명세서) | 사장이 mark-paid 시 | `[FACING] {month} 시급 정산 완료 ₩{net_pay:,} (세금 ₩{tax:,})` |
| C5 | 회원 결석 알림 (담당 코치) | 푸시 | 담당 회원 7일 결석 시 | `[FACING 코치] {member_name} 7일 결석. 연락 권고 (-33% churn 효과)` |

---

## 4. 채널별 우선순위

| 채널 | 우선 trigger | 비용 | live 통합 시점 |
|---|---|---|---|
| SMS (NHN Toast) | M3·M4·M5·M6·M7·M8·B7·C1 | ₩10~20/건 (한국 통신사) | P1 (E-2) |
| 메일 (Mailgun) | M1·M7·M8·B4·B8·C4 영수증·명세서 | 거의 0 | P1 (E-3) |
| 푸시 (FCM) | B1·B2·B5·C2·C3·C5·M9·M10 | 0 | P1 (E-4) |
| SSE (in-process) | B1·B2·B6 (PC 사장 dashboard 실시간) | 0 | 이미 구현 |
| 카카오 알림톡 | 향후 M·B 일부 (마케팅 가능) | ₩7~15/건 | P2 (Phase 3 후반) |

---

## 5. 발송 우선순위 (P0·P1·P2)

| 우선순위 | trigger | 이유 |
|---|---|---|
| **P0 (block 위험)** | M3·M4·M5·M6·M7·B1·B2·C4 | 회원 이탈·법적 의무 (영수증)·운영 차단 |
| **P1 (운영 efficiency)** | M1·M2·M8·M9·B3·B4·B5·B6·C1·C2·C3·C5 | 운영 자동화·재가입 유도 |
| **P2 (마케팅·미래)** | M10·B7·B8 | 게이미피케이션·NPS·코치 전환 알림 |

---

## 6. 안전 장치

- **rate limit**: 같은 회원 같은 trigger 1일 1회만 (audit_log 기반 idempotent)
- **무음 모드**: 회원 본인 설정 — `/api/v1/privacy/consent` marketing=false 시 M10 차단
- **국가 코드**: 한국 SMS 만 (NHN), 외국 회원은 메일 fallback
- **opt-out**: 모든 SMS·메일 본문에 "수신거부 [URL]" 의무 (정보통신망법 §50)
- **시간대**: 야간 22:00~08:00 발송 금지 (회원 푸시만 보류, 사장은 24/7)
- **dead letter**: 발송 3회 실패 시 audit_log 에 `notification_failed` 적재 + 사장 dashboard 표시

---

## 7. 구현 상태 (체크리스트)

- [x] **C-2** 만료 자동 검출 cron (`services/expiry_scheduler.py`) — 매일 03:30 KST. audit_log idempotent
- [ ] **E-2** NHN Toast SMS 통합 — 발송 실제 API 호출 (M3~M6·B7·C1 등)
- [ ] **E-3** Mailgun 메일 — HTML 템플릿 + 영수증 PDF 첨부
- [ ] **E-4** FCM 푸시 live — 폰 회원·코치 (현재 fcm.py stub 만)
- [ ] M9 결석 7일 cron (별도 job 추가)
- [ ] M10 출석 milestone (체크인 endpoint 에 검출 로직)
- [ ] B5 점심 12시 출석 0 cron
- [ ] B7 코치 3개월 경과 cron (이미 `needs_transition` flag 있음 — alert 만 추가)
- [ ] 회원·사장 옵트인·국가 코드·무음 모드 설정 페이지

---

## §변경 이력

- **2026-05-23**: 신규 작성. 23 trigger × 4 채널 매트릭스. C-2 자동 만료 cron 구현·연계.
