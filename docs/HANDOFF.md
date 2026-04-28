# HANDOFF - 2026-04-28 09:30 (v1.20 · /go A→B→C 완료)

## 완료 (이번 세션 — /go 파이프라인)

### 트랙 A — QA v1.20 잔여 4건 (`f015e3e`)
- **B-LW-5** theme: GoogleFonts.bodoniModa 4건 fontFamilyFallback=Pretendard. 오프라인/캐시 미스 시 한글·UI 안전 보장.
- **B-LW-6** CLAUDE.md: micro 토큰 11sp → 13sp 정정 (v1.19 P0-8 노안 가독성 반영).
- **B-PF-6** attendance: limit 200 매직넘버 → `_kHistoryLimit` 상수 + 이유 주석.
- **B-PF-7** trends: `15 - visibleTotal` 하드코드 제거. snap.catalog.length 단독 분모.

### 트랙 B — Phase 2 정리 (`836f2dc`)
- **B-LW-13** demoUnlockedCodes 제거. AchievementState.isUnlockedInUi 단순화.
  Panel B 20-title (titles_catalog.dart + PanelBUnlocker)이 클라이언트 추론 담당.
  데모 3건(STREAK_10/GIRLS_5_COMPLETE/HEROES_3)은 백엔드 trigger 도착 전까지 잠금.
- **검증** (변경 없음, 사후 점검):
  - Haptic.achievementUnlock 연결: unlock_toast.dart:44 / attendance_screen.dart:797 / wod_session_screen.dart:393.
  - Panel B catalog 20-title 완비 (Common 6 / Rare 8 / Epic 4 / Legendary 2).
  - Level Decay UI wiring: history_screen.dart:142-194 ENGINE SCORE 카드 + STALE 라벨 + 캡션.

### 트랙 C — 회귀 테스트 안정화 (no source change)
- 단위 테스트 54건 전부 통과:
  - engine_decay 11 / level_system 8 / pr_detector 9 / season_badges 6 / streak_freeze 6 / titles_catalog 11 / widget 1 / 기타 2.
- flutter analyze: No issues found.
- integration_test/persona_smoke_test.dart: emulator 필요 (별도 실행). 컴파일 검증 통과.

### 차수 6에 흡수된 항목 (재처리 안 함)
B-LW-1/3/4/8/11/14/16/18/19, B-PF-1/3/4/9/10/12, B-EX-1/2/3/4/7, B-LG-1/2, B-ST-3/14.

## 진행중
- (없음)

## 대기

### Track A 잔여 (위험 또는 widespread, 별도 트랙 필요)
- **B-LW-15** mypage StatelessWidget context.mounted — false positive 가능성 (context.mounted IS valid in stateless). 추가 조사 필요.
- **B-LW-17** main.dart Provider .value dispose — 외부 소유 패턴이지만 app lifecycle = process lifetime 이라 사실상 문제 없음. 주석만 추가 후보.
- **B-LW-20** Text overflow widespread — long display_name 케이스. spot 점검 필요.
- **B-PF-2** hero_background gradient 재생성 — darkenStrength 동적 파라미터 때문에 단순 캐시 불가.
- **B-PF-5** wod_session _start/_resume — 코드 중복 의심, 실제 분기 다를 수 있음 검토 필요.
- **B-PF-8** attendance/trends streak 계산 중복 — `_currentStreakDays` 헬퍼 추출 후보.
- **B-PF-16** coach_dashboard pop+push — UX 패턴, 위험 낮으면 유지.
- **B-PF-17** wod_detail FutureBuilder ConnectionState 일관성.
- **B-PF-18** achievement state.error 미표시 — 사용자 노출 추가 후보.
- **B-ST-1/4/5/7/8/10/11/12/13** — 다수 차수 6 흡수 추정 또는 false positive (재검수 필요).

### Phase 2 백로그
- **Panel B 칭호 확장** (검토 결과 20개 충분, 추가 옵션):
  - PB_STREAK_30 (Common, 30일 연속 세션)
  - PB_HERO_3 (Rare, 헤로 WOD 3종 완료)
  → TitleUnlockSignals 필드 추가 + 추론 로직 필요.
- **잠금 해제 모먼트 강화**:
  - Confetti density / haptic timing 미세 조정 (현재 Epic/Legendary heavy 80ms delay).
  - Toast stack 시 첫 unlock 으로 burst → 나머지는 light only?
- **Streak Freeze UI**:
  - Attendance 화면에 freeze 사용/잔여 인디케이터 추가.
- **Level Decay 알림**:
  - Push notification 리마인더 (60일 / 90일 / 120일).
  - In-app 배너 (Tab Trends 진입 시 STALE 강조).

### Phase 3 (장기)
- FCM Push, SNS 공유 카드, 영상 폼 분석, Whoop/Garmin OAuth, Cloud 백업, Friends/Follow.

## 결정사항 / 주의

### 1. 배포 금지 (CLAUDE.md 최상위)
사용자 명시 "배포해" 전까지 git push / Railway / store 금지. 이번 세션 commit 전부 로컬 (`f015e3e`, `836f2dc` 미푸시). origin/master 대비 22 커밋 ahead.

### 2. demoUnlockedCodes 제거 영향
Achievement 트렌드 화면에서 `STREAK_10 / GIRLS_5_COMPLETE / HEROES_3` 3건이 잠금 상태로 표시됨 (이전: 데모 해금). 백엔드 trigger 추가 시 자동 해소.

### 3. micro 토큰 13sp 확정
이전 11sp 가이드는 v1.19 P0-8(M3 윤 페르소나)에서 노안 가독성 부족으로 13sp 상향 의결. CLAUDE.md 표 동기화.

### 4. fontFamilyFallback 동작
`GoogleFonts.bodoniModa(...).copyWith(fontFamilyFallback: ['Pretendard'])` 패턴. Bodoni Moda 런타임 fetch 실패 시 Pretendard 으로 글자 그리기 — italic 합성은 Flutter 엔진이 fauxItalic 적용.

## 다음 세션 권장 첫 프롬프트
```
/resume — Phase 2 백로그 (Panel B 칭호 확장 / 잠금 해제 모먼트 미세조정 / Streak Freeze UI) 또는 Track A 잔여 점검
```

## 관련 경로

| 역할 | 경로 |
|---|---|
| QA 보고서 (171건 마스터) | `docs/QA/QA-2026-04-27.md` |
| FEATURES 매트릭스 | `docs/QA/FEATURES_CHECKLIST.md` |
| 디자인 토큰 SSOT | `lib/core/theme.dart` (FacingTokens) |
| 게이미피케이션 코어 | `lib/core/level_system.dart`, `engine_decay.dart`, `streak_freeze.dart`, `season_badges.dart`, `titles_catalog.dart`, `pr_detector.dart` |
| Panel B 화면 | `lib/features/achievement/panel_b_screen.dart` |
| 단위 테스트 | `test/{engine_decay,level_system,pr_detector,season_badges,streak_freeze,titles_catalog}_test.dart` |
| 페르소나 회귀 | `integration_test/persona_smoke_test.dart` |

## 이전 HANDOFF
- `docs/archive/HANDOFF-2026-04-27.md` (v1.19 QA 차수 1~5)
- `docs/archive/HANDOFF-2026-04-25.md` (v1.16 Sprint 10–17)
- `docs/archive/HANDOFF-2026-04-24-v1152.md` (v1.15.2 페르소나)
- `docs/archive/HANDOFF-2026-04-24.md` (v1.15 자산 연결)
