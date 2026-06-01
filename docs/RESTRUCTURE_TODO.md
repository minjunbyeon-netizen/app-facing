# 화면 재배치 To-Do — Home / Profile / Attend / Notice (2026-06-02)

> 사용자 요청 3건 기반. "한 개도 빠지지 말 것."
> 원칙: 그래프(radar·sparkline) 제거하고 **숫자는 유지**. 게이미피케이션은 Home으로, 점수는 Profile로, 공지는 Home 최상단 아코디언으로.

## 현재 구조 (출발점)
- **Home** (`home_screen.dart`): HeroCard(레이더 그래프 + Tier + Engine 점수 + 닉네임/레벨/칭호 + 카테고리 칩 + 트렌드 sparkline) · 약점 분석 inline · "CALCULATE WOD" 카테고리(Girls/Heroes/Games/Custom)
- **Profile** (`mypage_screen.dart`): Identity · AttendanceCompact(미니 캘린더+stats) · Membership · Locker · MyBox · Body · Settings · Actions
- **Attend** (`attendance_screen.dart`): LevelCard(캐릭터) · AchievementSection(업적 그리드) · Milestones(3종 진행바)
- **Notice** (`inbox_screen.dart`): GymInfoCard · 쪽지/숙제/공지 단일 피드(CoachDossierTile)

---

## Move A — Home 점수 컨텐츠 → Profile (그래프 제거·숫자 유지)
출처: `home_screen.dart` `_HeroCard` · `_WeaknessInsightInline`
- [ ] A1. Engine Score 큰 숫자(score100) → Profile
- [ ] A2. Tier 배지(TierBadge) → Profile
- [ ] A3. 레벨·칭호 pill(_IdentityRow) → Profile _IdentityCard에 통합 (닉네임 중복 정리)
- [ ] A4. 6 카테고리 점수 → Profile. **레이더 그래프(_RadarPainter) 삭제**, 숫자 칩만 유지
- [ ] A5. 트렌드 → **sparkline 그래프(_SparklinePainter) 삭제**, delta 숫자(▲+N)만 텍스트 유지
- [ ] A6. 약점 분석 카드(_WeaknessInsightInline) → Profile (숫자 기반이라 유지)
- [ ] A7. Home initState 데이터 로직(_engineFuture·_sessionCountFuture·_wornTitleCode) → Profile로 이전
- [ ] A8. 안 쓰게 된 _RadarPainter·_SparklinePainter·_RadarAxis 클래스 정리

## Move B — Attend 게이미피케이션 → Home
출처: `attendance_screen.dart`
- [ ] B1. LevelCard(캐릭터+레벨+XP+progress+격려 캡션) → Home
- [ ] B2. AchievementSection(업적 그리드) → Home
- [ ] B3. Milestones 3종(Attendance/Sessions/Achievements 진행바) → Home
- [ ] B4. 데이터 로직(history fetch·streak 계산·StreakFreeze·PrDetector·achievement check) → Home로 이전
- [ ] B5. **Attend 탭 운명 결정** (게이미피케이션 빠지면 비게 됨 — 결정 #2)

## Move C — Notice 중요내용 → Home 최상단 아코디언
출처: `inbox_screen.dart` `CoachDossierTile` · `announcements_state.dart`
- [ ] C1. 최신 공지/쪽지 N개(기본 3) 요약을 Home **최상단**(게이미피케이션보다 위)에 배치
- [ ] C2. 아코디언 — 기본 접힘, 최신 1개 헤드라인만 노출 → 탭하면 펼침
- [ ] C3. "더 보기" → Notice 탭(index 2) 이동(ShellNavBus.requestTab(2))
- [ ] C4. 미읽음 표시(accent stripe·dot) 유지
- [ ] C5. 데이터 소스 결정 — 공지(Announcements) only vs 쪽지+공지 합쳐 최신순 (결정 #3)

## Cross-cutting (정리·동기화)
- [ ] D1. Home AppBar/구성 재정의 (게이미피케이션 + 공지 중심)
- [ ] D2. Profile 섹션 순서 재배치 (Identity → Score → Body → Membership → …)
- [ ] D3. 중복 제거 (Profile AttendanceCompact ↔ Attend 캘린더, Level 계산 이중)
- [ ] D4. `docs/ARCHITECTURE_BRIEF.md` 충돌 점검 + 탭 책임 SSOT 갱신
- [ ] D5. 카피 SSOT(CLAUDE.md 카피 템플릿) — 새 섹션 라벨 영문 규칙 적용
- [ ] D6. main_shell.dart 탭 힌트 오버레이 _hints 텍스트 갱신
- [ ] D7. 상단 종(InboxBellAction) 역할 — Home 아코디언과 중복 점검
- [ ] D8. 에뮬 검증 (3 페르소나: 회원/코치/신규) + 캡처

---

## 설계 순서 (제안)
- **Phase 0** — ARCHITECTURE_BRIEF 충돌 점검 + 결정 게이트(#1·#2·#3) 확정
- **Phase 1** — Move A: Profile에 점수 섹션 신설(숫자만), Home에서 HeroCard 제거
- **Phase 2** — Move B: Home에 게이미피케이션 이식, Attend 탭 처리
- **Phase 3** — Move C: Home 최상단 Notice 아코디언
- **Phase 4** — Cross-cutting 정리(탭 힌트·카피·중복·brief)
- **Phase 5** — 에뮬 3 페르소나 검증 + 캡처

## 열린 결정 (Phase 0 게이트)
1. Home "CALCULATE WOD" 카테고리(Girls/Heroes/Games/Custom) 행선지 — (a) Profile (b) WOD 탭 흡수 (c) Home 유지
2. Attend 탭 — (a) 제거→4탭 (b) 전체 업적/기록 보관함으로 전환 (c) 유지하고 캘린더 복귀
3. Notice 아코디언 데이터 — (a) 공지만 (b) 쪽지+공지 최신순 통합
