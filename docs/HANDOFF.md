# HANDOFF — 2026-04-30

## 컨텍스트

v1.22 전면 개편(HWPO+Strava 하이브리드, 5탭, 업적 96종, 레벨 캐릭터) 이후 추가 패치.
홈 벤치마크 레퍼런스 시트 + 퀵 페르소나 스위처 구현 완료.

## 완료 (이번 세션)

- [x] **WOD 탭 Pacing 버튼 제거** — `lib/features/gym/box_wod_screen.dart`
  - 버튼 제거 + `shell_nav_bus.dart` 미사용 import 제거
  - RenderFlex overflow 경고 해결

- [x] **Notice 탭 코치 쪽지 작성 경로 명확화** — `lib/features/inbox/inbox_screen.dart`
  - 코치 AppBar `IconButton(Icons.edit_outlined)` 추가 (FAB 백업 진입점)
  - 빈 상태 hint: "오른쪽 상단 ✏ 또는 + New 버튼으로 쪽지·숙제 발송."
  - compose 후 `context.read<InboxState>().refresh()` 호출

- [x] **6카테고리 벤치마크 레퍼런스 시트** — 신규 2파일 + home_screen.dart 수정
  - `lib/core/benchmark_data.dart` — Games/Elite/RX+/RX/Scaled 5티어 × 6카테고리 레퍼런스 데이터
  - `lib/features/home/benchmark_sheet.dart` — `showBenchmarkSheet(ctx, key)` DraggableScrollableSheet
  - `lib/features/home/home_screen.dart` — 레이더 차트 아래 6개 LayoutBuilder+Wrap 칩 추가 (tap → sheet)

- [x] **퀵 페르소나 스위처** — `lib/features/mypage/mypage_screen.dart`
  - kDebugMode guard. Profile > DEBUG 섹션 내 가로 스크롤 5개 아바타 칩
  - COACH A(박지훈/성수), COACH B(이수민/강남), USER A(김도윤/성수), USER B(정하은/성수), USER C(강민재/강남)
  - 탭 → `DeviceIdService.overrideForDebug` + `AppModeStore.set` + `GymState.loadMine()` + SnackBar

## 진행중
없음.

## 대기 (다음 세션 후보)

- [ ] **백엔드 페르소나 시드 실행** — services/facing 에서 필요
  - `python -m data.seed_personas` (코치 페르소나에 gym 소속 설정)
  - 미실행 시: Notice FAB 코치에게 안 보임 (isOwner=false, getMine=null)
  - **빠른 베타 테스트 전 선행 필수**

- [ ] **새 mascot 자산 추가** (사용자 제공 대기)
  - `assets/images/character/mascot_lv2.png` (Lv 11-20)
  - `assets/images/character/mascot_lv3.png` (Lv 21-30)
  - `assets/images/character/mascot_lv4.png` (Lv 31-40)
  - `assets/images/character/mascot_lv5.png` (Lv 41+)

- [ ] **벤치마크 시트 여성 데이터** — 현재 남성(BW80kg) 전용. 여성 탭 추가 옵션
- [ ] **Phase 4 — Barlow Condensed 영문 헤딩** (옵션)

## 주요 결정사항

- **벤치마크 데이터 SSOT** = `services/facing/engine/grading.py`. 앱은 hardcoded 문자열로 표시 (API 통신 불필요 — 정적 레퍼런스)
- **퀵 스위처는 kDebugMode 전용** — release APK에서 완전 숨김
- **ValueKey('inbox-${gs.isOwner}')** — InboxScreen StatefulWidget 재생성으로 코치/멤버 전환 레이스 컨디션 해결 (main_shell.dart, 이전 세션에서 완료)
- **Notice FAB 미표시 근본 원인** = 백엔드 seed_personas.py 미실행 → getMine null → isOwner false

## 파일 경로

| 역할 | 경로 |
|---|---|
| 벤치마크 데이터 | `lib/core/benchmark_data.dart` |
| 벤치마크 시트 UI | `lib/features/home/benchmark_sheet.dart` |
| 홈 화면 (칩 추가) | `lib/features/home/home_screen.dart` |
| WOD 탭 (Pacing 제거) | `lib/features/gym/box_wod_screen.dart` |
| 인박스 (코치 작성 버튼) | `lib/features/inbox/inbox_screen.dart` |
| 프로필 (퀵 스위처) | `lib/features/mypage/mypage_screen.dart` |

## 최근 커밋

- `02bb12a feat(home/profile): 6카테고리 벤치마크 레퍼런스 시트 + 퀵 페르소나 스위처`
- `1ecdb98 fix(wod/inbox): Pacing 버튼 제거 + Notice 코치 쪽지 작성 경로 명확화`

## 다음 세션 권장 첫 프롬프트

```
/resume
```

또는:
```
services/facing에서 python -m data.seed_personas 실행했어. 퀵 페르소나 스위처로 코치A 전환 후 Notice에 FAB 뜨는지 확인해줘.
```
