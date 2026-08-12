# HANDOFF - 2026-08-12 20:56

> 주제: **앱 UI 가시성·버튼 편의 리디자인 (v2.2)** + 데모/디버그 UI 전면 삭제.
> 이번 세션은 **`apps/facing-app` 한 repo만** 만졌다 (백엔드·PC 웹 0건).
> **push·배포 0건.** 로컬 커밋 6개.
> 기준 자료: 경쟁 앱 링코(`com.linkcoach`) 화면 27장 분석 = `C:/dev/tools/linko-screens/`
> (INDEX → SCREENS → REVIEW → DATA 순으로 읽을 것. REVIEW.md 의 F1~F10 이 우리 결함 ID 의 근거).

## 완료

### 1. 토큰·테마 (전 화면 동시 적용) — `2f9465c`
- [x] **브랜드 빨강 #EE2B2B → #CC1F1F** — 흰 배경 4.01→5.32, 흰 글씨 4.19→5.55.
      전에는 **양방향 모두 WCAG AA 미달**이었다. `tierRx` 가 이미 같은 값이라 중복도 해소.
      경로: `appkit.config.json` 브랜드 스킨 수정 → `cd C:/dev/tools/appkit && python sync.py --app facing`
- [x] `placeholder` 토큰 신설 `#84848D` (조상 `#A1A1AA` 2.56:1 → 3.71:1)
- [x] `textButtonTheme` · `iconButtonTheme` 신설 — **터치 최소 48 을 앱 전역에서 강제**
- [x] `inputDecorationTheme` 신설 — 안내 문구 대비 + 포커스 테두리 브랜드색

### 2. FKit 확장
- [x] **`FkButton` 3단 신설** = 버튼의 유일 규격.
      primary 채움 52 / secondary 외곽선 52 / tertiary 글자 48. 화면당 primary 1개.
      옵션은 `expand` · `neutral`(중립 글자색) · `danger`(파괴적 동작) 셋뿐
- [x] **`FkListRow` 우측 화살표 자동** — `onTap` 있고 우측 값 없으면 부착 (앱 전역 적용)
- [x] `TermTip.showLabel` 신설 + 터치 영역 18~22 → 48

### 3. 화면 수정 (결함 ID = 이번 세션 부여, H1~H18)
- [x] **WOD 오늘 카드** — 연분홍 면 전체 채우기 → 흰 카드 + 좌측 4px 바 (링코 F1 구조).
      라벨 열 72→92(`A. METCON`·`VERSIONS` 두 줄 깨짐 해소). 액션 3개 → primary 1 + 글자 2
- [x] **홈 레벨 카드** — 캐릭터 flex 4/9(가로 44%) → 고정 88×88. 진행바 전체 폭·높이 6.
      XP 세 자리 쉼표. 캡션 색을 레벨대 색 → 본문색 고정
- [x] **마일스톤 진행바** — `alpha 0.55` 제거 (라이트 배경에서 반투명 = 비활성으로 읽힘)
- [x] **하단 탭** — 켜진 탭 아이콘·라벨을 브랜드색으로 (전엔 둘 다 검정)
- [x] H1 가입 코드 `000000`(검정 굵게) → `6자리 숫자`(placeholder) — 링코 F8
- [x] H2 사장 대시보드 수업 시각 ISO 원문 → `19:00 – 20:00 · 박준서` (`_hhmm()`)
- [x] H3 `데이터 초기화` → `FkButton.secondary(danger)` — 링코 S17
- [x] H4 빈 상태 규격 통일 (박스 미가입 12px 회색 → h3) — 링코 F7
- [x] H5 `ⓘ` 2개 라벨 없이 나란 → `ⓘ Tier` `ⓘ Engine` — 링코 F6
- [x] H6 통계 타일 2종 → 라벨 위/값 아래로 통일 · H7 `회원 관리` → FkButton.primary
- [x] H8 프로필 메뉴 화살표 · H9 `코치·사장 로그인` 흐린 회색 → 본문색 w600 + 구분선
- [x] H11·H14 앱바 제목과 화면 헤드라인 중복 2곳 제거 (R1)
- [x] H12 온보딩 1단계 영문 혼용 → 한글 (`체중`·`키`·`크로스핏 경력`), 입력칸 라벨 이중 표기 제거
- [x] H13 수업 카드 `Reserve`→`예약` · `Join Waitlist`→`대기 신청` · `60min`→`60분` · `WL 2`→`대기 2`
- [x] H16 인트로 1p 문구 중복 제거 + 헤드라인 마침표 제거 · H18 `로그아웃` → 외곽선 버튼
- [x] 사장 대시보드 카드 4종 모서리 r3 (이 화면만 각져 있었다)

### 4. 문서 — `98ecb2a`
- [x] **`docs/DESIGN-SSOT.md` v1.29 → v2.2, §7-D 신설** "버튼 1종 강제 · 가시성"
      — FkButton 표 + 금지 목록 + **가시성 규칙 10개** (링코 대조로 도출)
- [x] `CLAUDE.md` tier 5색 표를 코드 실측값으로 정정 + 구 v1.15 다크 컬러 표에 "현재 값 아님" 경고

### 5. 데모·디버그 UI 전면 삭제 — `18b8b0f` (사용자 명시 지시)
- [x] 프로필 하단 DEBUG 블록 · `_QuickPersonaBar`(229줄) · `lib/features/_debug/` **폴더 통째**
- [x] `demo_accounts.dart` + 로그인 화면 데모 진입 UI · `_useDemo()` · `DeviceIdService.overrideForDebug()`
- [x] `integration_test/persona_smoke_test.dart`
- [x] 골든이 쓰던 `tierGrade('RX')`·체형 값만 `screens_golden_test.dart` 안 상수로 이관 (결과 이미지 동일)

### 검증
`flutter analyze` 0 issues · `flutter test` **134 passed** · 골든 16장 재생성 · 갤러리 22장

## 진행중

없음. 착수한 항목은 전부 커밋까지 끝났다.

## 대기 (사용자 결정 필요 / 다음 후보)

- [ ] **`ProfileState.applyPersonaSnapshot()` 이름 잔재** — 페르소나 기능이 사라졌는데 이름만 남았다.
      현재 호출자는 `test/golden/screens_golden_test.dart` 하나뿐. rename 시 §0-B 절차(전체 grep) 적용
- [ ] **버튼 규격 자동 게이트 없음** — 배지는 `test/badge_lint_test.dart` 가 지키는데
      §7-D 버튼 규칙 10개는 **사람 눈에만 의존**한다. `button_lint_test.dart` 신설 후보
      (검사 대상: 화면 로컬 `GestureDetector`+`Container` 버튼 · `minimumSize` 48 미만 ·
      `foregroundColor: FacingTokens.muted`)
- [ ] **`회원 관리` 버튼이 아직 "구현 예정" 스낵바** (`boss_dashboard_screen.dart:163`).
      하단 탭 `회원` 과 목적지도 같다. 모양만 맞춰 뒀고 **존치 여부는 제품 판단**
- [ ] **로그인 화면 `_kShowSocialLogin = false`** — 데모가 아니라 실 OAuth 키 대기 상태라
      이번 삭제 범위에서 제외했다. 정리할지 결정 필요
- [ ] **`state_01_wod_error` 골든에 에러가 안 찍힌다** — 파일명과 내용 불일치 의심. 미확인
- [ ] **에뮬레이터 실조작 검증 미실시** — 골든은 정지 화면이라 스피너·전환·터치를 못 잡는다.
      이번 세션 오진 2건(H15 성별 토글·H17 스플래시 점)이 전부 정지 화면 판단에서 나왔다
- [ ] 안 본 화면: 인트로 2·3p 등은 갤러리로만 훑었고 픽셀 단위로 뜯어보진 않았다

## 결정사항 / 주의

1. **이 repo 에서 `dart format` 을 돌리지 말 것.** 옛 SDK 기준으로 포맷돼 있어
   현재 포맷터를 돌리면 **118개 파일이 통째로 재포맷**된다 (이번 세션에서 사고 후 되돌림).
   편집은 Edit 도구로만.
2. **auto-save 훅이 작업을 남의 커밋에 흡수한다.** 이번 세션 중 다른 세션의 커밋
   `1a9de5d`("docs: …")·`582faf8` 에 내 lib 변경이 섞여 들어갔다. 커밋 전 `git log`·`git status` 확인.
3. **배포 금지 유지.** 사용자가 "배포해"라고 하기 전까지 push·railway up 금지 (프로젝트 CLAUDE.md 최상위).
4. **선택 상태는 검정(`color: fg`), 브랜드색은 동작 전용.** 선택형 FkBadge 8곳이 전부 이 규칙을
   따른다 — 성별 토글이 검정인 것은 결함이 아니라 체계다 (이번 세션 오진 H15).
5. **백엔드 데모 시드는 건드리지 않았다.** 글로벌 §3-A `admin/1234` 시드는 `services/facing` 의무이고,
   이번에 지운 것은 앱 화면의 디버그 UI 다.
6. UI 를 바꾸면 **골든 재생성 + 갤러리 갱신이 완료 조건** (DESIGN-SSOT §0).
   `flutter test --update-goldens test/golden` → `python tool/golden_gallery.py`

## 관련 파일

| 경로 | 역할 |
|---|---|
| `docs/DESIGN-SSOT.md` | **양식 정본.** §7-D = 이번 세션 버튼·가시성 규격 |
| `C:/dev/tools/linko-screens/REVIEW.md` | 링코 결함 F1~F10 — 우리 규칙의 근거 |
| `lib/widgets/fkit.dart` | FkButton(신설) · FkListRow 화살표 · FkBadge |
| `lib/core/theme.dart` | placeholder 토큰 · textButton/iconButton/inputDecoration 테마 |
| `appkit.config.json` | 브랜드 accent `#CC1F1F` (수정 후 `tools/appkit/sync.py --app facing`) |
| `lib/features/gym/box_wod_screen.dart` | WOD 오늘 카드 · `_kv` · 액션 위계 |
| `lib/features/home/home_screen.dart` | 레벨 카드 · 마일스톤 진행바 · `_comma()` |
| `lib/features/boss/boss_dashboard_screen.dart` | 카운터·수업·만료 카드 · `_hhmm()` |
| `test/golden/screens_golden_test.dart` | RX 캡처 입력 상수 (`_kRxGrade`·`_kRxBenchmarks`) |

## 다음 세션 권장 첫 프롬프트

`/resume`

이어서 하려면 대기 항목 중 하나를 골라 지시:
1. `button_lint_test.dart` 신설 — §7-D 규칙을 자동 게이트로
2. 에뮬레이터 실조작 검증 (골든이 못 잡는 것)
3. `applyPersonaSnapshot` 이름 정리 (§0-B 잔재)
