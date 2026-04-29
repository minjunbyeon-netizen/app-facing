# HANDOFF — 2026-04-29 22:06

## 컨텍스트

v1.22 디자인 전면 개편 + 게이미피케이션 확장. HWPO+Strava 하이브리드 테마 → 5탭 재구조 → 업적 96종 + 레벨별 캐릭터.

## 완료
- [x] **테마 v1.22 (HWPO+Strava 하이브리드)** — `lib/core/theme.dart`
  - accent CF Red(#EE2B2B) → HWPO 탠(#B97A4A). tierRx만 CF Red 잔류
  - 이중 폰트: HWPO 임팩트(display 72sp w900) + Strava 본문(h1 32sp w600)
  - 신규 토큰: accentSoft, displayCompact, pr / 버튼 r4 pill / sectionLabel 12sp
- [x] **WOD 탭 재설계** — `lib/features/gym/box_wod_screen.dart`
  - PAST/TODAY/UPCOMING 3섹션, 일자 헤더 중복 제거
  - row 미니멀 (border 제거, 얇은 divider, 라벨:값 패턴)
  - TODAY accentSoft bg 강조, 미래 일자 Mark Done 잠금(🔒 + "Not yet")
  - 아코디언 토글 버그 수정 (펼침→detail 분기 제거 → 항상 toggle)
- [x] **Home Hero 카드 (안 C 합체)** — `lib/features/home/home_screen.dart`
  - Tier+Engine+Radar 통합. 중앙 ENGINE 점수(72sp HWPO display + 탠)
  - Radar `clearCenter` 옵션. 마스크 124px circle.
  - 약점 분석은 별도 `_WeaknessInsightInline` 으로 분리
- [x] **공통 Bell 헤더** — `lib/widgets/inbox_bell.dart` (신규)
  - 모든 탭 AppBar 좌측 고정 — 탭 시 Notice 탭 점프 + 미읽음 dot
  - Inbox 4탭 → NOTICE 단일 피드 (날짜 desc), 하단 nav 라벨도 Notice
  - WOD AppBar 정리: Messages/Announce/Leaderboard 제거 (Inbox 통합)
- [x] **Profile 정체성 재정의** — `lib/features/mypage/mypage_screen.dart` (1626 → 776줄)
  - 신규 _IdentityCard (닉네임+첫글자 아바타+Edit Profile 버튼)
  - 신규 EditProfileScreen — `lib/features/mypage/edit_profile_screen.dart`
  - 신규 _AttendanceCompact (미니 캘린더 + 1줄 통계 STREAK/TOTAL/THIS MONTH)
  - 삭제: TierRoadmap, EngineTrend, CategoryTiers, RecentRecords, RoleModelCard, WornTitleLine
- [x] **Attend 게이미피케이션 전용** — `lib/features/attendance/attendance_screen.dart`
  - 큰 캘린더+stats 제거 → Profile 이주
  - PanelB AppBar 잔재 제거. CHALLENGES 섹션 폐기 (mock+중복)
  - LEVEL 카드 좌·우 50:50 (캐릭터 좌측 풀 height + 우측 row 컨텐츠)
  - 신규 mascot 자산 `assets/images/character/mascot.png` (HYPHEN 캐릭터)
  - pubspec에 `assets/images/character/` 등록
- [x] **업적 96종 + XP 시스템** — backend `data/seed_achievements.py` (48 → 96)
  - 등급별 XP: Common 20 / Rare 50 / Epic 120 / Legendary 300
  - LevelSystem.compute() 에 achievementXp 파라미터 추가
  - 레벨별 캐릭터 mascot_lv{2,3,4,5}.png 매핑 (자산 미존재 시 mascot.png 폴백)
  - 7단계 격려 캡션 ("좋은 출발" → "베테랑" → "경지에 올랐다")

## 진행중
없음. 모든 v1.22 패치 커밋 완료.

## 대기 (다음 세션 후보)
- [ ] **새 mascot 자산 추가** (사용자 제공 대기)
  - `assets/images/character/mascot_lv2.png` (Lv 11-20)
  - `assets/images/character/mascot_lv3.png` (Lv 21-30)
  - `assets/images/character/mascot_lv4.png` (Lv 31-40)
  - `assets/images/character/mascot_lv5.png` (Lv 41+)
  - 자산 드롭만 하면 매핑 자동 (코드 수정 불필요)
- [ ] **백엔드 시드 실제 적용** — services/facing 측
  - `python -c "from data.seed_achievements import seed; from models.base import SessionLocal; s=SessionLocal(); print(seed(s))"`
  - 또는 시드 endpoint 노출
- [ ] **Phase 4 — Barlow Condensed 영문 헤딩** (옵션)
- [ ] **Home Leaderboard 진입 버튼** (사용자 요청 시)
- [ ] **Profile 사진 업로드 기능** (현재 첫 글자만)

## 주요 결정사항
- **HWPO 탠 액센트 (#B97A4A) 채택** — CF Red는 tierRx 배지에만 잔류. 의미 분리(브랜드 vs CrossFit 정체성)
- **이중 폰트 모드** — 화면당 HWPO 임팩트 ≤ 1~2회. 영혼 숫자 7곳만(Engine score, Tier 배지, LEVEL 숫자, brandLogo, PR 등)
- **WOD 탭 토글 버그**: 펼친 상태에서 row tap → detail 분기 때문이었음. `onTap: _toggle` 단순화. Detail은 명시 "Detail →" TextButton만
- **Inbox 4탭 통합 → NOTICE**: ALL/NOTES/ASSIGNMENTS/OUTBOX 폐지. 단일 피드 날짜 desc
- **레벨별 캐릭터 진화**: 5단계 (1-10/11-20/21-30/31-40/41+). 자산 미존재 시 errorBuilder 폴백
- **업적 XP 합산**: AchievementState.snapshot.unlocked × LevelSystem.rarityXp[c.rarity]

## 주의사항
- **CLAUDE.md §0 배포 금지 강제**. 사용자 명시 "배포해" 전까지 git push / Railway / Play Store 모두 차단
- **mascot 자산 변경 시 hot reload(r) 미적용**. 반드시 `q` → `flutter run` 재실행
- **pubspec 변경**도 동일. `flutter pub get` 자동 실행 안 됨
- **services/facing 와 apps/facing-app은 독립 git repo**. 각각 따로 커밋됨
- v1.22 rev6까지 진행. 최근 커밋:
  - apps: `f9138f7 feat(level): achievements x2 + rarity XP + level-bracket mascot`
  - services: `d6ed1a2 feat(seed): +48 achievements (total 96)`

## 다음 세션 권장 첫 프롬프트

```
/resume
```

또는:
```
mascot_lv2~5 캐릭터 이미지 만들었어. assets/images/character/ 에 드롭했고
앱에서 레벨별로 잘 바뀌는지 확인해줘
```
