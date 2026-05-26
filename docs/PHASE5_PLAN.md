# PHASE5 운영 강화 — Phase 1~6 분해

> 2026-05-25 22:57 사용자 6 카테고리 요구사항을 의존성 순서로 6 Phase 분해.
> 원문 SSOT: 같은 날 채팅 사용자 메시지 (홈/통계/회원/운영/수업/설정).
> ARCHITECTURE_BRIEF.md 와 충돌 발견 시 본 문서가 아닌 BRIEF 갱신 우선 (글로벌 룰).

## 분해 원칙

- Phase 1 (기반 마스터 데이터) → Phase 2 (회원 화면 핵심) → Phase 3 (운영자 도구) → Phase 4 (자동화 흐름) → Phase 5 (수업·커뮤니티) → Phase 6 (홈 대시보드 + 청소).
- 앞 Phase 안 끝나면 뒤 Phase 가 의미 없도록 짰음 (예: 회원권 설정 마스터 없이는 자동 금액 매핑 불가).
- Sprint 예상치는 1 인 풀타임 기준 — 검증·디자인 폴리시·실시연 포함.

---

## Phase 0 — 직전 보류분 (15분, Phase 1 끼워서 처리)

- [ ] 0-1. APK LAN IP 박힌 빌드 폰 설치 후 `boss_seongsu` 로그인 → 가짜 가입 신청 → 알림바 캡쳐 — v1.17 staff SSE 실 시연 마무리

## Phase 1 — 설정 시스템 기반 (Sprint 1, 1주)

> 모든 phase 가 이 마스터 데이터에 의존. 먼저 안 만들면 뒤 다 깨짐.

- [x] 1-1. 회원권 마스터 설정 (gym_plan 모델 + settings_plans.html · CRUD endpoint · soft-delete)
- [x] 1-2. 포인트 설정 (gym_points_setting JSON + 사이클 58 Points 탭 inline 편집)
- [x] 1-3. 알림 설정 (announcements 자동알림 toggle + Phase 5-3 공지 CRUD 연동)
- [x] 1-4. 사장 설정 화면 (`/admin/settings` + 좌측 사이드바 진입로 + 4 탭 Plans·Points·Notify·Auto-Join)

## Phase 2 — 회원 화면 핵심 강화 (Sprint 2, 1주)

- [x] 2-1. 만료 D-7 빨간색 강조 (members.html 임계값 통일 commit f2bcea6)
- [x] 2-2. 회원 상세 회원권 이력 리스트 (memberships 탭 — 활성·만료·정지 row 분리)
- [x] 2-3. 결제이력 → 수강이력 탭 전환 (commit 8458bbf · top 5 자주 들은 수업)
- [x] 2-4. 회원 카드 포인트 잔액 표시 (commit d1b032b)
- [x] 2-5. 메모 inline 배지 이름 옆 (commit b2b3152 · hover tooltip)
- [x] 2-6. 기간 정지 파트 (commit 033d5f5 · pause endpoint + UI prompt)

## Phase 3 — 운영자 도구 (Sprint 3, 1.5주)

- [x] 3-1. 시급정산 4대보험 차감 정책 (commit 41d75ff + F2-F3 정밀 차감 두루누리·산재)
- [x] 3-2. 위험·D-7 필터 chip (commit be67819 · 이탈위험 50+ 또는 만료 임박 모아보기)
- [x] 3-3. 락카 회원 이름 자동완성 (commit da7cff0 · datalist 부분 검색)
- [x] 3-4. 락카 회원권 기간 자동 매칭 (lockers.html assign 시 active membership start·end 복제)
- [x] 3-5. 회원권 추가 시 락카 자동 연장 (서비스 레이어 훅 — membership extend → locker end_date 동기화)

## Phase 4 — 자동화 흐름 (Sprint 4, 1.5주)

- [x] 4-1. 회원 어플 다운 → 로그인 → 박스 선택 → 자동 가입 (commit ae2d46e — self_signup_screen.dart + GET /member/gyms-list + auto-approve gym setting)
- [x] 4-2. 첫 회원권 결제 직후 자동 계약서 발급 화면 전환 (payments_admin.py is_first_payment 응답 + member_detail.html confirm → /contracts?member_id 이동)
- [x] 4-3. 회원권 추가 시 Phase 1-1 설정 기반 자동 금액 표시 (commit 6bcb5c8 — member_detail.html msPlanSelect onChange · GYM_ID plans fetch · price·end_date 자동 채움 · plan 미설정 박스 fallback)

## Phase 5 — 수업·커뮤니티 (Sprint 5, 1주)

- [x] 5-1. 사이드바 '기타' → '수업' rename (commit 2794671)
- [x] 5-2. Leaderboard Elite/RXD/Scaled 3 탭 (commit 7354537 + TASK D 후속 a13fc50 실 데이터)
- [x] 5-3. 공지사항 CRUD (commit 8d2bdb2 + URL 정정 161208a)
- [x] 5-4. 일정 달력 화면 (commit 925225f · month fetch · 클래스·공지 표시)
- [x] 5-5. 클래스 detail 수정 버튼 (commit 2442b79)
- [x] 5-6. 클래스 추가 담당 코치 select 버그 수정 (commit cc01614)

## Phase 6 — 홈 대시보드 + 청소 (Sprint 6, 3~5일)

- [x] 6-1. 오늘 예약·이번 달 매출 위젯 (commit 4b27011 자리 + 8617501 JS 연동 + 백엔드 agg)
- [x] 6-2. '오늘 처리할 일' 카드 제거 (commit fb873a9)

---

## 진행 룰

- 각 Phase 시작 시: 사용자에게 plan 한 번 더 확인 + DB 변경 영향 보고
- 각 항목 완료 시: 체크박스 갱신 + commit (글로벌 §3 autopush 단, 배포 금지 룰)
- 모든 Phase 끝나면: docs/PHASE5_PLAN.md 를 docs/archive/PHASE5_PLAN-{YYYY-MM-DD}.md 로 이동

## 외부 자료 / 참조

- 백엔드 admin endpoint: `services/facing/api/admin.py`
- 프론트엔드 사장 화면: `apps/facing-app/lib/features/boss/`
- web admin: `web/facing-admin/` (있으면)
- 디자인 토큰: `apps/facing-app/lib/core/theme.dart` (FacingTokens v1.15)
- 카피 SSOT: `apps/facing-app/CLAUDE.md` §Voice & Tone V1~V11
