# HANDOFF — 2026-04-29 08:20

## 완료 (2026-04-29 세션 — 별도 트랙)

### 30 시나리오 실전테스트
- [x] `docs/test-reports/2026-04-29-coach-member-30.md` — 36 체크포인트 표 / 5 카테고리 (A 출제 / B 노출 / C 전달 / D 응답 / E 양방향)
- [x] BLOCKER 2건 식별: E1 회원→코치 첫 메시지 시작 불가 / F1 Mode=SOLO 일관성
- [x] NOT-IMPL 1건: 캘린더 자동 연동 (Phase 4)

### 시각 통일 패스 (commit `af217cb`)
- [x] 18 files / 52 변경 — `micro.copyWith(ls:1.2, w700)` → `microLabel` 토큰 단일 출처
- [x] Engine Score fallback 추가 (`mypage_screen.dart` _EngineTrend) — records 비면 `grade['overall_score']` 사용

### Splash + Signup 검정 배경 정상화 (commit `040c14d`, `d6b3b9d`)
- [x] Android 12+ Theme.Black + windowSplashScreen* + 빈 icon drawable로 흰 배경/Flutter 로고 차단
- [x] `splash_screen.dart` HeroBackground 제거 → 단색 검정, duration 1.2s → 2.5s
- [x] `signup_screen.dart` HeroBackground 제거 → 단색 검정 (Splash 일관)

### Profile 인라인 모드 토글 (이번 응답 commit)
- [x] `lib/features/mypage/mypage_screen.dart` `_ModeRow` → 3 ChoiceChip 인라인 토글 (Solo/Member/Coach)
- [x] Mode 헤더 + chip 양쪽 중앙정렬 (Column crossAxis center + Row/Wrap center)

---

## 진행중

없음.

---

## 대기 (어제 04-28 마감 분 그대로 유지)

### 백엔드 services/facing/ 동기화 (별도 repo)
참조: `docs/BACKEND_SYNC_NOTES.md` 7 항목

- [ ] **P0** AchievementCatalog 50개 동기화 (`services/facing/models/achievement.py`)
- [ ] **P0** Inbox `/api/v1/gym/notes/{id}/complete` endpoint 검증
- [ ] **P0** RecipientStatus.actual_sets JSONB 컬럼 마이그레이션
- [ ] **P0 (Phase 3)** device_push_tokens + Alembic 마이그레이션 + FCM sender
- [ ] **P1** 거절 사유 영문 코드 enum 검증 (INJURY/CONDITION/TIME/SUBSTITUTE)
- [ ] **P1** Engine Score 표기 변환 가이드 docs
- [ ] **P2 (Phase 4)** Open/QF/Games/Regional/Murph self-report 검증 endpoint

### facing-app 잔여 트랙
- [ ] **BLOCKER E1** 회원→코치 첫 메시지 시작 진입점 (현재 코치만 시작 가능)
- [ ] **BLOCKER F1** Mode=SOLO 일관성 (Coach/Member 토글은 추가됐으나 Solo 잔여 분기 검증)
- [ ] 캘린더 자동 연동 (Phase 4 NOT-IMPL)
- [ ] adb UI 페르소나 자동 검증 — emulator BottomNav 좌표 calibration
- [ ] tmp/screen*.png + tmp/test/coach_*.png + go_*.png .gitignore 정리
- [ ] FCM Push 본 구현 (Firebase 프로젝트 설정 사용자 행동 필요)
- [ ] §3 Phase 2 Session Timer time cap 자동 중단

---

## 결정사항 / 주의

### 어제 (04-28) 결정 — 유지
- Engine Score 3 변수: `overall_score` 0~6 / UI 0~100 / `overall_number` 1~6
- 거절 사유 영문 코드 4종 (INJURY/CONDITION/TIME/SUBSTITUTE)
- Inbox endpoint 통합: `/api/v1/gym/{gymId}/notes/*` (kind='assignment')
- Mode 게이트: 클라이언트 `app_mode` ≠ 백엔드 `role` (escalation 차단)
- 한국 박스 600개 (§10 ↔ §1)

### 이번 세션 (04-29) 결정
- **Profile 토글**: 코치 ↔ 멤버 ↔ 솔로 모드 변경은 Profile → 3-ChoiceChip 인라인. AppModeStore.set + SnackBar 즉시 피드백.
- **Splash duration**: Flutter 첫 frame ~2s + 노출 1.5s+ → total 2.5s 고정.
- **Native splash 전략**: `windowSplashScreenAnimatedIcon` = 1×1 투명 vector 로 Android 12+ 자동 launcher 아이콘 노출 차단.
- **letterSpacing 단일 출처**: `microLabel` 토큰 (ls:1.2, w700, muted). 인라인 ls override 금지.

### 주의
- master 브랜치 force push 금지 (CLAUDE.md).
- emulator-5554 살아있는 상태로 세션 종료. 다음 세션 cleanup 권장.
- 큰 PNG screenshot read 빈도 절감 — build 검증 1회당 최대 1캡처, Read 안 함.

---

## 다음 세션 권장 첫 프롬프트

### facing-app 후속 (BLOCKER 우선)
```
/resume
```
→ E1 (회원→코치 첫 메시지 시작) 또는 F1 (Mode=SOLO 일관성) 둘 중 1건 선택.

### 백엔드 동기화로 이어갈 경우
```
cd C:/dev/services/facing
docs/BACKEND_SYNC_NOTES.md (apps/facing-app) P0 3건 진행
```
