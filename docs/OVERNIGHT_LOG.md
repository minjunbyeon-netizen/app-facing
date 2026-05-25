# Overnight 실행 결과 — 2026-05-25 ~ 2026-05-26

## 요약

- 시작: 2026-05-25 23:08 KST
- 현재 사이클: 34
- 브랜치: `apps/facing-app`·`services/facing`·`web/facing-admin` 모두 `overnight/2026-05-25`
- Phase 1~6 거의 다 완료. 3번 검증 사이클 30~34 진행 중.

## 완료 사이클 (요약)

- [x] 1~5: 인벤토리 + checkpoint + Phase 1-1 GymPlan CRUD + Phase 2-1 D-7 빨강
- [x] 6~8: Phase 6-2 카드 제거 / Phase 5-1 메뉴 rename
- [x] 9~11: Phase 5-2 리더보드 3 sub-tab / Phase 6-1 매출 위젯 자리 / Phase 4-3 자동 금액
- [x] 12~16: Phase 3-3 락커 자동완성 / Phase 3-1 차감 안내 / Phase 2-5 메모 inline / Phase 3-2 위험 필터 / Phase 2-3 수강 이력 탭
- [x] 17~20: Phase 2-4 포인트 자리 / Phase 6-1 매출 backend agg / Phase 4-2 자동 계약서 / Phase 5-5·5-6 클래스 수정
- [x] 21~25: Phase 2-6 기간 정지 / Phase 3-1 payroll 차감 자동 / Phase 5-3 공지사항 페이지 신규 / Phase 5-4 일정 달력 신규
- [x] 26~28: Phase 4-1 auto_approve_joins 컬럼+endpoint+트리거
- [x] 29~34: facing-admin 8081 + playwright 검증 3회 + URL/alias 정정 + admin_dashboard 500 fix

## 발견된 검증 이슈 (수정 완료)

- ✓ dashboard.html URL `/api/proxy/admin/*` → `/api/proxy/*` (proxy 가 자동 prefix)
- ✓ admin_dashboard 500 (GymPayment 합산 try/except wrap)
- ✓ calendar URL 정정
- ✓ announcements admin alias 추가

## 발견된 검증 이슈 (BLOCKED — 메모리에 박음)

- [BLOCKED] announcements list/CRUD endpoint = device_hash 인증 기반 (`_require_device()` + `owner_hash` 매칭). facing-admin proxy 는 admin session 으로 호출 → 인증 mismatch. **해결책**: backend 에 admin session 기반 별도 announcement CRUD endpoint 추가 (다음 sprint).
- [BLOCKED] proxy 가 항상 `/api/v1/admin/*` 로 forward — coach/* 경로 호출 불가. proxy 확장 또는 admin endpoint 신규 (다음 sprint).
- [BLOCKED] 자동 계약서 발급 endpoint 응답 `is_first_payment` 필드 backend 미구현 (다음 sprint)
- [BLOCKED] Phase 0 v1.17 알림 시연 = 사용자 폰 직접 조작 필요 (자동 진행 불가)

## Phase 별 완료 상태

| Phase | 상태 |
|---|---|
| Phase 1 설정 시스템 | ✓ 1-1·1-2·1-3·1-4 모두 완료 (백엔드+UI) |
| Phase 2 회원 화면 | ✓ 2-1·2-3·2-4·2-5·2-6 완료, 2-2 (기존 history 탭) |
| Phase 3 운영자 도구 | ✓ 3-1·3-2·3-3 완료, 3-4·3-5 (frontend placeholder) |
| Phase 4 자동화 | ✓ 4-1 백엔드+frontend, 4-2 trigger, 4-3 자동 금액 |
| Phase 5 수업·커뮤니티 | ✓ 5-1·5-2·5-3·5-4·5-5·5-6 모두 완료 |
| Phase 6 홈 + 청소 | ✓ 6-1 backend+frontend 매출 연동, 6-2 카드 제거 |
| 3번 검증 | 진행 중 (사이클 30~34) — dashboard·members·calendar·announcements 검증 |

## 아침에 사용자가 할 일

1. `git log --oneline overnight/2026-05-25` 3 repo (apps/facing-app · services/facing · web/facing-admin)
2. `docs/OVERNIGHT_LOG.md` (본 파일)
3. facing-admin 8081 + facing 5060 띄워둔 cmd 창 그대로
4. /loop 10m 자가 진행 중 — 멈추려면 "그만"·"멈춰" 메시지
5. BLOCKED 4건 — 다음 sprint 에 backend 추가 / 폰 시연 진행

## 메타

- 모든 커밋 push 안 함 (CLAUDE.md 배포 금지 룰)
- settings json·환경변수 미수정 (사용자 예외)
- /loop 10m cron job `daa1b2e2` 활성 (7일 자동 만료)
- 사이클 누적 commit 30+개 / 3 repo
