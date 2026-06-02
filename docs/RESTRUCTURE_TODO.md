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
- [x] A1. Engine Score 큰 숫자(score100) → Profile
- [x] A2. Tier 배지(TierBadge) → Profile
- [x] A3. 레벨·칭호 pill(_IdentityRow) → Profile _IdentityCard에 통합 (닉네임 중복 정리)
- [x] A4. 6 카테고리 점수 → Profile. **레이더 그래프(_RadarPainter) 삭제**, 숫자 칩만 유지
- [x] A5. 트렌드 → **sparkline 그래프(_SparklinePainter) 삭제**, delta 숫자(▲+N)만 텍스트 유지
- [x] A6. 약점 분석 카드(_WeaknessInsightInline) → Profile (숫자 기반이라 유지)
- [x] A7. Home initState 데이터 로직(_engineFuture·_sessionCountFuture·_wornTitleCode) → Profile로 이전
- [x] A8. 안 쓰게 된 _RadarPainter·_SparklinePainter·_RadarAxis 클래스 정리

## Move B — Attend 게이미피케이션 → Home
출처: `attendance_screen.dart`
- [x] B1. LevelCard(캐릭터+레벨+XP+progress+격려 캡션) → Home
- [x] B2. AchievementSection(업적 그리드) → Home
- [x] B3. Milestones 3종(Attendance/Sessions/Achievements 진행바) → Home
- [x] B4. 데이터 로직(history fetch·streak 계산·StreakFreeze·PrDetector·achievement check) → Home로 이전
- [x] B5. **Attend 탭은 그대로 둠** (결정 #2 = 유지). 게이미피케이션 빠진 뒤 빈 화면 →
      "준비 중 / 곧 추가" placeholder만 남기고, 향후 다른 자료 들어올 자리로 보존.
      탭 라벨·아이콘·인덱스 변경 X. 5탭 유지.

## Move C — Notice 중요내용 → Home 최상단 아코디언
출처: `inbox_screen.dart` `CoachDossierTile` · `announcements_state.dart`
- [x] C1. 최신 공지/쪽지 N개(기본 3) 요약을 Home **최상단**(게이미피케이션보다 위)에 배치
- [x] C2. 아코디언 — 기본 접힘, 최신 1개 헤드라인만 노출 → 탭하면 펼침
- [x] C3. "더 보기" → Notice 탭(index 2) 이동(ShellNavBus.requestTab(2))
- [x] C4. 미읽음 표시(accent stripe·dot) 유지
- [x] C5. **데이터 = 쪽지(InboxState) + 공지(AnnouncementsState) 합쳐 최신순** (결정 #3 = b).
      두 소스 merge → createdAt desc 정렬 → 상위 N개. 미읽음 우선 가중은 추후 검토.

## Move E — WOD 카테고리 → WOD 탭 하단 (참조자료 아코디언)
출처: `home_screen.dart` "CALCULATE WOD" 섹션 → `gym/box_wod_screen.dart`
- [x] E1. Girls/Heroes/Games/Custom 카테고리 행 → **WOD 탭 최하단**으로 이동
- [x] E2. 형태 = **참조자료용 아코디언** (기본 접힘, "CALCULATE WOD · 프리셋" 헤더 탭하면 펼침)
- [x] E3. 진입 동작 유지 — 각 항목 탭 시 PresetsScreen/WodBuilderScreen 그대로 push
- [x] E4. Home에서는 이 섹션 완전 제거 (Home = 공지 + 게이미피케이션 전용)

## Move F — Notice 박스 기본정보 → WOD 탭 최상단 아코디언 (2026-06-02)
출처: `inbox_screen.dart` `GymInfoCard` → `gym/box_wod_screen.dart` `_GymInfoAccordion`
- [x] F1. GymInfoCard(박스명·위치·연락·코치·가격·수업시간·MOTTO) → WOD 탭 **최상단** 아코디언(`BOX INFO`)
- [x] F2. 형태 = 기본 접힘. subtitle 에 "박스명 · 위치" 1줄. 펼치면 전체 카드.
- [x] F3. Notice 에서 GymInfoCard 제거 — Notice 는 새 글(쪽지·공지) 전용 피드로 비움.
- [x] F4. GymInfoCard 에 `margin` 옵션 추가 — 아코디언 안 이중 여백 방지(margin=0).

## Move G — 회원↔코치 양방향 쪽지 (2026-06-02)
브리프 §160·§383 충족. 백엔드 member-report(회원→코치) 이미 존재 → 대화 합본 + 회원 발신 UI 추가.
- [x] G1. 백엔드 `GET /api/v1/gym/<id>/messages` — 받은 것(recipient) + 보낸 것(sender) 합쳐 시간순. direction(in/out).
- [x] G2. 앱 `ChatMessage` 모델 + `InboxRepository.listMessages`.
- [x] G3. 회원 NOTICE = 카톡식 대화뷰 — 상단 공지 핀(`_PinnedAnnouncement`) + 말풍선(`_ChatBubble`, mine=우측 accent) + 하단 입력바(`_ChatInputBar`, suffixIcon 전송).
- [x] G4. 회원 발신 = `memberReport`(wod_id 없이). 코치는 기존 인박스에서 수신.
- [x] G5. 코치 화면은 기존 단일 피드 유지(분기). `AnnouncementsState.items` getter 공개.
- [x] G6. 에뮬 검증 — 받은 쪽지 좌측 + 보낸 "test from member" 우측 정상. 입력바 무한너비 버그(Row→suffixIcon) 픽스.

## Cross-cutting (정리·동기화)
- [x] D1. Home AppBar/구성 재정의 (게이미피케이션 + 공지 중심)
- [x] D2. Profile 섹션 순서 재배치 (Identity → Score → Body → Membership → …)
- [x] D3. 중복 제거 (Profile AttendanceCompact → Attend 캘린더 이관, 캘린더 단일화)
- [x] D4. `docs/ARCHITECTURE_BRIEF.md` 충돌 점검 + D25 탭 책임 SSOT 기록
- [x] D5. 새 섹션 라벨 영문 규칙 적용 (NOTICE·ENGINE·MILESTONES·CALCULATE WOD)
- [x] D6. main_shell.dart 탭 힌트 오버레이 _hints 텍스트 갱신 + 버전 v3 bump + Inbox→Notice 표기 통일
- [x] D7. (되돌림 2026-06-02) 종(InboxBellAction)은 **쪽지·공지 메시징의 전 화면 공통 진입**이라
      Home 에도 복원. 모든 화면 우측상단에 종 유지가 사용자 설계. (중복이라 뺐던 D7 판단 무효화)
- [~] D8. 에뮬 검증 — 회원 페르소나(김도윤) 5탭 + 재부팅 클린 + 힌트 OK. 코치/신규 페르소나 미검증

## 진행 현황 (2026-06-02)
- Phase 1~5 완료 (각 단계 에뮬 검증 + 로컬 커밋). push·배포는 안 함 (프로젝트 배포 금지 룰).
- D7 완료(Home 상단 종 제거). 남은 자투리: D8 코치/신규 페르소나 검증 · 라이트/다크 테마(이번 작업 무관, 별건).

---

## 설계 순서 (확정)
- **Phase 0** — ARCHITECTURE_BRIEF 충돌 점검 (결정 게이트 완료)
- **Phase 1** — Move A: Profile에 점수 섹션 신설(숫자만), Home에서 HeroCard 제거
- **Phase 2** — Move E: WOD 카테고리 → WOD 탭 하단 아코디언 (Home 비우기 마무리)
- **Phase 3** — Move B: Home에 게이미피케이션 이식, Attend는 placeholder만 남김
- **Phase 4** — Move C: Home 최상단 Notice 아코디언(쪽지+공지 통합)
- **Phase 5** — Cross-cutting 정리(탭 힌트·카피·중복·brief)
- **Phase 6** — 에뮬 3 페르소나 검증 + 캡처

## 결정 (확정 2026-06-02)
1. WOD 카테고리 → **(b) WOD 탭으로**, 단 **하단에 참조자료용 아코디언** 형태 (= Move E)
2. Attend 탭 → **유지**. 게이미피케이션만 Home으로 빼고, 빈자리는 placeholder. 향후 자료 들어올 예정
3. Notice 아코디언 데이터 → **(b) 쪽지+공지 최신순 통합**

## 최종 화면 책임 (재배치 후)
- **Home** = 최상단 공지/쪽지 아코디언(접힘 1줄) + 게이미피케이션(Level 히어로·업적·Milestones)
- **WOD** = 최상단 BOX INFO 아코디언(박스·코치·가격·수업시간, 접힘) + 코치 오늘 WOD + 하단 프리셋 카테고리 아코디언(참조)
- **Notice** = 쪽지/숙제/공지 새 글 전용 피드. 박스 기본정보(GymInfoCard) 는 WOD BOX INFO 로 이관(2026-06-02). Home 은 요약본
- **Attend** = 출석 캘린더 복귀(Profile에서 이동) — 빈 탭 낭비 방지 (리뷰 다)
- **Profile** = Identity + 점수(숫자만, 그래프 X) + Body + Membership + Locker + MyBox + Settings + Actions

## 설계 리뷰 반영 (2026-06-02)
- (가) Profile 점수 = Identity 바로 밑. "Tier RX · Engine 45" 한 줄 + LV pill + 6 카테고리 숫자칩 + 약점.
       대형 "45 ENGINE/100" 히어로 숫자는 **빼고** 담백하게.
- (나) Home 순서 = 공지 아코디언(접힘) → 캐릭터 LevelCard(히어로) → 업적 → Milestones.
- (다) Attend = Profile의 출석 캘린더(_AttendanceCompact)를 Attend로 되돌려 채움.
       → Profile에서는 캘린더 제거, Attend가 출석 전담. (D3 중복 정리와 합쳐짐)
- 브리프 §10 D25로 폰 탭 책임표 기록 (승인 2026-06-02).
