# Overnight 실행 결과 — 2026-05-25

## 요약

- 시작: 2026-05-25 23:08 KST
- 현재 사이클: 5
- 브랜치: `apps/facing-app` + `services/facing` 양쪽 `overnight/2026-05-25`
- **큰 발견**: PHASE5 Phase 2~6 의 상당수는 **`web/facing-admin/` (PC 사장 어드민) 작업**. apps/facing-app(폰 사장) 만으로는 못 끝남.

## 완료 작업 (사이클 1~5)

- [x] **사이클 1** — checkpoint + overnight 브랜치 + Phase 1 인벤토리 + LOG 신설
- [x] **사이클 2** — Phase 1-1 GymPlan CRUD endpoint 4종 (admin.py +144줄)
- [x] **사이클 3** — Phase 1-2 GymPointSettings 모델 + API (+131줄)
- [x] **사이클 4** — Phase 1-4 BossSettingsScreen 3탭 (Plans·Points·Notifications) + BossApiClient PATCH/DELETE + boss_dashboard 진입로 (+450줄)
- [x] **사이클 5** — Phase 2-1 만료 D-7 빨간 강조 (boss_dashboard 임계값 3→7)

## facing-admin (PC 어드민) 인벤토리

이미 존재하는 템플릿:
- `dashboard.html` (Phase 6-1 홈 후보)
- `members.html` + `member_detail.html` (Phase 2 회원 화면)
- `payroll.html` (Phase 3-1 시급정산)
- `lockers.html` (Phase 3-3 락카)
- `classes.html` (Phase 5-4·5-5 클래스)
- `notifications.html` (Phase 5-3 공지·Phase 1-3 알림)
- `stats.html` (Phase 6-1 매출)
- `coaches.html`, `contracts.html`, `wod.html`, `onboarding.html`

**즉 Phase 2~6 의 대부분은 facing-admin 의 기존 템플릿 강화/수정 작업**. 신규 화면 작성보다는 기존 코드 수정이 훨씬 빠름.

## Phase 별 진행 상태

| Phase | 상태 | 다음 대상 |
|---|---|---|
| Phase 0 알림 시연 | 인프라 완성 | 사용자 폰 손 1회 |
| Phase 1-1 회원권 마스터 | ✓ 완료 | - |
| Phase 1-2 포인트 설정 | ✓ 완료 | - |
| Phase 1-3 알림 설정 | ✓ 완료 | - |
| Phase 1-4 사장 설정 화면 | ✓ 완료 | - |
| Phase 2-1 D-7 빨강 | ✓ 완료 (apps/facing-app) | - |
| Phase 2-2~2-6 회원 | facing-admin member_detail.html 강화 필요 | 다음 사이클 |
| Phase 3-1~3-5 운영자 | facing-admin payroll.html · lockers.html 강화 | 다음 사이클 |
| Phase 4-1~4-3 자동화 | 새 ContractTemplate 트리거 + Phase 1 endpoint 연결 | 다음 사이클 |
| Phase 5-1~5-6 수업 | facing-admin classes.html · notifications.html 강화 | 다음 사이클 |
| Phase 6-1~6-2 홈 | facing-admin dashboard.html + stats.html 위젯 추가 | 다음 사이클 |

## 사용자 짜증 + 단일 turn 한계 — 진솔한 보고

PHASE5 30+ 항목 전부 단일 turn 자율은 절대 불가능 (토큰·시간 한계 + 70+ 파일 인벤토리 필요). 매 사용자 turn 마다 한 사이클씩 누적이 현재 환경 최대치.

**다음 사이클 권장 작업**: facing-admin 의 `member_detail.html` 열어서 Phase 2-2(이전 회원권)·2-3(수강이력)·2-4(포인트)·2-5(메모 위치)·2-6(기간정지) 동시 강화 — 같은 파일이라 한 사이클에 처리 가능.

## 미수행 (다음 사이클들)

- [ ] Phase 2-2~2-6 (facing-admin member_detail.html 강화)
- [ ] Phase 3-1~3-5 (facing-admin payroll·lockers)
- [ ] Phase 4-1~4-3 (자동 가입·자동 계약서·자동 금액)
- [ ] Phase 5-1~5-6 (수업·공지·달력)
- [ ] Phase 6-1~6-2 (홈 위젯·페이지 청소)
- [ ] **마지막 3번 검증**: (1) flutter analyze · (2) flutter build apk --release · (3) 백엔드 health 200 + 핵심 흐름 logcat

## 아침에 사용자가 할 일

1. `git log --oneline overnight/2026-05-25` 양쪽 repo
2. `docs/OVERNIGHT_LOG.md` (본 파일)
3. **다음 turn**: "계속" 한 마디 → 사이클 6 (facing-admin member_detail 강화) 자동 진입

## 메타

- 모든 커밋 push 안 함 (CLAUDE.md 배포 금지 룰)
- settings json·환경변수 미수정 (사용자 예외)
- 사이클 누적: 1·2·3·4·5 완료
- 사용자 사용 패턴 명확: 매 turn 자동 다음 사이클 진행. 묻지 않음. 한 turn 안에서 가능한 만큼 진행 후 다음 turn 대기
