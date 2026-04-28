# HANDOFF — 2026-04-28 16:38

## 완료

### 6-pager v1.1 갱신 (10건 — facing-app 측 SSOT 정합 종료)
- [x] §1 Market Opportunity v1.1 — 한국 박스 250 → 600 / Solo→Member funnel
- [x] §2 Pacing Intelligence v1.1 — Engine Score 3 변수 분리 (0~6 / 0~100 / 1~6) / Solo 미영향
- [x] §3 WOD Broadcasting v1.1 — mode 컬럼 + timeCapSec / GymWodComment / GymWodResult.scaleLevel
- [x] §4 Coach Notes v1.1 — 5 액션 (markRead/Accept/Complete/Decline/AskCoach) + Mode 게이트 + 거절 사유 영문 코드
- [x] §5 Coach Assignments v1.1 — Notes endpoint 통합 / 3 클래스 모델 (CoachNote+AssignmentItem+ActualSet+RecipientStatus)
- [x] §6 Achievement v1.1 — Panel B 20 → 50 / 분포 15/20/10/5 / TitleUnlockSignals 43 필드
- [x] §7 User Journey v1.1 — ModeSelect 분기 (Coach/Member/Solo)
- [x] §8 Gym Membership v1.1 — Solo→Member 전환율 dial / R6 추가
- [x] §9 Differentiation v1.1 헤더만 (본문 v1.0 유효)
- [x] §10 Thesis v1.1 — Solo→Member dial / 시장 진입 위험 R 행 추가

### 코드 트랙
- [x] ShareCountStore 신설 (`lib/core/share_count_store.dart`)
- [x] Panel B shareCount signal 통합 (`lib/features/achievement/panel_b_screen.dart`)
- [x] result_screen Share 직후 ShareCountStore.increment() (`lib/features/pacing_result/result_screen.dart`)
- [x] InboxScreen 게이트 위젯 테스트 (`test/inbox_screen_test.dart` — 코치 4탭 / 멤버 3탭, 2/2 pass)
- [x] WodSessionScreen smoke 위젯 테스트 (`test/wod_session_screen_test.dart` — For Time / AMRAP 12, 2/2 pass)
- [x] Backend sync notes 가이드 (`docs/BACKEND_SYNC_NOTES.md` — 7 항목)
- [x] CoachBadge + 9 화면 AppBar 통합 (이전 세션 누적)
- [x] 3 모드 시스템 (`lib/core/app_mode.dart` + ModeSelectScreen + CreateGymScreen)
- [x] Panel B 50-title 카탈로그 + TitleUnlockSignals 43 필드

### 회귀 / 배포
- [x] flutter analyze 0 issues
- [x] flutter test 114 pass (기존 110 + 신규 4)
- [x] persona_matrix_test 31 pass
- [x] git push origin master 완료 — `19a0215..2c4dd5d` (64 commits + merge)

### 이번 세션 누적 commit (origin/master 동기화 후 0 ahead)
- 6cd12c9 §5 / edcd63d §2 / 9aa5810 §10 / a575091 §1 / 2e5375d §9
- 371a73e B1 inbox test / d079327 B2 ShareCountStore / 9edc535 B3 share increment
- 2922420 B1' wod_session smoke / cbb58b8 backend sync notes
- 2c4dd5d Merge origin/master + push 완료

---

## 진행중

없음 (모든 작업 완료).

---

## 대기

### 백엔드 services/facing/ 동기화 (별도 repo)
참조: `docs/BACKEND_SYNC_NOTES.md` 7 항목

- [ ] **P0** AchievementCatalog 50개 동기화 (`services/facing/models/achievement.py` ACHIEVEMENT_CATALOG)
- [ ] **P0** Inbox `/api/v1/gym/notes/{id}/complete` endpoint 검증 (`services/facing/api/coach_note.py`)
- [ ] **P0** RecipientStatus.actual_sets JSONB 컬럼 마이그레이션
- [ ] **P0 (Phase 3)** device_push_tokens 테이블 + Alembic 마이그레이션 + FCM sender 서비스
- [ ] **P1** 거절 사유 영문 코드 enum 검증 (INJURY/CONDITION/TIME/SUBSTITUTE)
- [ ] **P1** Engine Score 표기 변환 가이드 docs (`services/facing/docs/refer/`)
- [ ] **P2 (Phase 4)** Open / QF / Games / Regional / Murph self-report 검증 endpoint

### facing-app 잔여 트랙
- [ ] adb UI 페르소나별 자동 검증 — emulator BottomNav 좌표 calibration 필요 (Y ≈ 2216 보정)
- [ ] tmp/screen*.png 디버그 캡처 .gitignore 정리 + `git rm --cached` (별도 commit)
- [ ] §6 §7-1 단위 테스트 pass count (현재 11) 정확도 grep 후 문서 갱신
- [ ] FCM Push 통합 본 구현 (Firebase 프로젝트 설정 사용자 행동 필요 — `docs/PHASE3_PUSH.md` 가이드 풀스펙 존재)
- [ ] §3 Phase 2 Session Timer time cap 자동 중단

---

## 결정사항 / 주의

### 정합 결정 (이번 세션)
- **Engine Score 3 변수**: `overall_score` 0~6 (백엔드 원본) / **UI 표시 0~100** (`floor(overall_score / 6 × 100)`) / `overall_number` 1~6 (Tier 매핑)
- **거절 사유**: `INJURY/CONDITION/TIME/SUBSTITUTE` 영문 코드 4종 + free text (§4 Coach Notes / §5 Assignments 통합)
- **Inbox 인박스 endpoint**: `/api/v1/inbox/assignments/*` 별도 X → `/api/v1/gym/{gymId}/notes/*` (kind='assignment') 통합
- **Mode 게이트**: 클라이언트 `app_mode` (UI 분기) ≠ 백엔드 `role` (권한). escalation 차단 — Solo가 Coach 모드 → 백엔드 게시 API 거절
- **Solo→Member 전환율 (월 ≥ 10%)**: 양면 시장 lock-in 첫 dial. 미달 시 박스 검색 진입점 UX·박스 공급 점검
- **한국 박스 600개** (§10 ↔ §1 정합. 250 → 600 갱신)

### 주의
- master 브랜치 force push 절대 금지 (CLAUDE.md). 이번 세션 non-fast-forward 발생 시 merge로 처리 (rebase + force push 아님).
- emulator-5554 살아있는 상태로 세션 종료 (com.netizen.facing.facing_app 프로세스). 다음 세션 cleanup 권장.
- §2 v1.1 Engine Score 3 변수 분리 후 백엔드 docs (`services/facing/docs/refer/`) 측 변환 공식 문서 동기화 필요.
- 일반 push만 진행, force push 미사용. CLAUDE.md 배포 금지 규칙 위반 없음.

---

## 다음 세션 권장 첫 프롬프트

### 백엔드 동기화로 이어갈 경우 (권장)
```
cd C:/dev/services/facing
docs/BACKEND_SYNC_NOTES.md (apps/facing-app) P0 3건 진행: AchievementCatalog 50개 + Inbox /complete + RecipientStatus.actual_sets 마이그레이션
```

### facing-app 후속 작업
```
/resume
```
→ 본 HANDOFF.md 읽고 대기 작업 중 1건 선택 (adb 좌표 calibration / tmp/ gitignore 정리 / FCM 본 구현).
