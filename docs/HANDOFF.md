# HANDOFF - 2026-08-12 22:45

> 주제: **WOD 탭을 주간 아코디언으로 재구성(v2.4) + 버튼·프로필·홈 전면 컴팩트화(v2.5)**.
> 이번 세션은 `apps/facing-app` 한 repo만 만졌다 (백엔드·PC 웹 코드 변경 0건).
> **push·배포 0건.** 로컬 커밋만. 에뮬레이터(emulator-5554)·폰(192.168.1.100:5555)에
> 디버그 APK 설치까지 완료.
> 사용자 지시의 큰 줄기: "WOD 들어가면 보기가 너무 힘들다" → 주간 아코디언,
> 그리고 "칸을 쓸데없이 크게 쓴다, 50% 수준으로" → 전 화면 컴팩트화.

## 완료

### 1. WOD 탭 = 그 주 월~일 아코디언 — `e48731a` (v2.4)
- [x] `lib/features/gym/week_board.dart` **신설**. 한 주가 7줄로 고정되고, 요일·날짜를
      누르면 그 자리에서 **그날 WOD + 그날 수업(줄마다 예약 버튼)** 이 펼쳐진다.
      한 번에 한 날만 열리고(다시 누르면 접힘), 헤더 ◀ ▶ 로 주 이동.
- [x] 구 3섹션(오늘·예정·지난) + 하단 ClassesSection 임베드 **폐기**.
      `_DateAccordion`·`_groupByDate`·`_WodEntry` 삭제.
- [x] `lib/features/gym/wod_row.dart` **분리** — `WodRow`·`LockedWodBanner`·코치 메시지
      시트를 box_wod_screen 에서 꺼내 보드와 공유 (같은 행 위젯 두 벌 방지).
- [x] 예약·취소 흐름을 `reserveClassFlow`/`cancelClassFlow` **한 벌**로 통일
      (`features/classes/classes_screen.dart` top-level). 수업 화면·주간 보드가 같이 쓴다.
- [x] 수업은 **주 단위 1회 조회** (`GET /api/v1/member/classes?from=월&to=다음 월`).
      백엔드 변경 0건 — `from` 이 과거여도 그대로 받는다(코드 확인, 실호출 미검증).
- [x] 하루에 WOD 가 둘 이상이면 **첫 개만 펼침** (둘 다 펼치니 수업이 화면 밖으로 밀렸다).
- [x] 예약 직후 재조회 때 **주간 요약이 통째로 빈칸으로 깜빡이던 것** 제거 —
      FutureBuilder 를 걷고 이전 결과를 들고 있다가 갈아끼운다.
- [x] WOD 로드 실패가 "게시된 WOD 없음"으로 읽히던 것 → 경고 배너 + 다시 시도
      (`_LoadErrorBanner`).
- [x] 브리프에 **D33** 기록.

### 2. 버튼·프로필·홈 컴팩트화 — `600b23a` (v2.5)
- [x] **버튼 한 규격 36** — `FacingTokens.buttonHCompact` 신설(appkit 마스터 52 는 불변).
      세로 패딩 16→4, 모서리 r4→r3. FkButton 3종(채움·외곽선·글자) 높이 통일.
- [x] WOD 수업 줄의 예약·대기·취소·마감·종료를 **전부 FkBadge 한 규격**으로
      (예약됨과 같은 크기). 완료 표시는 전폭 채움 → 글자 폭 컴팩트.
- [x] 프로필: 아바타 56→40, 이름 h2→h3, 전폭 '프로필 수정' 버튼 → 이름 줄 연필 아이콘.
      섹션 구분선 여백 24→4. FkAccordion `dense`+`minTileHeight 44` (헤더 72→44).
- [x] 프로필 **박스 기록에서 Tier·전화·생년월일·성별·선호 시간 삭제** — 앱이 쓰지 않는
      되비추기 값. 코치가 남긴 주의 사항·메모만 남기고 둘 다 없으면 카드 자체 숨김.
      로그인 수단(NAVER) 표기도 삭제. 설정·메뉴 아코디언 부제 삭제 → 한 줄 버튼.
- [x] 홈: 업적 빈 상태 아이콘+2줄 → 한 줄. `FkListRow` 여백 12→8 (업적·마일스톤·
      프로필 메뉴 공통). 바깥 여백·섹션 간격 16/24→12.
- [x] 검증: `flutter analyze` 0 · `flutter test` **134 통과** · 골든 **22장 갱신** ·
      갤러리 22장 · 에뮬레이터에서 WOD·프로필·홈 3탭 실물 확인 · 예약 버튼 실호출 성공.

## 진행중

없음. (아래 '대기' 1번이 사용자가 방금 지시한 다음 작업이다.)

## 대기 (다음 세션 첫 작업 — 사용자 지시 2026-08-12 22:43)

- [ ] **① ENGINE 섹션 삭제.** "engine 은 우리가 쓸 데 없다."
      대상 = `lib/features/mypage/mypage_screen.dart` 의 `_ScoreSection`
      (ENGINE 라벨 · Tier/Engine 점수/LV/칭호 줄 · 6 카테고리 칩 · 트렌드 delta ·
      `_WeaknessInline` 약점 카드) + `MyPageScreen` children 의 `_ScoreSection()` 과
      그 앞뒤 `_SectionDivider()`.
      ⚠ **"숨김 = 코드 보존" 원칙**(CLAUDE.md)대로 진입점만 끊을지, 파일째 지울지
      먼저 판단할 것. 권장 = 화면에서 제외 + 클래스 보존(온보딩 `/onboarding/grade`·
      벤치마크 시트가 같은 데이터를 쓴다). 삭제 시 딸려가는 것:
      `_ScoreSectionState`·`_WeaknessInline`·`benchmark_sheet` 진입·`_rarityColor`.
      골든 `member_03_shell_profile` 재생성 필요.
- [ ] **② 완료 표시 버튼을 '예약됨' 수준으로 더 축소.** "지금도 좀 커서 거북하다."
      현재 = `FkButton.primary('완료 표시', icon: Icons.check, expand: false)` 높이 36
      (`lib/features/gym/wod_row.dart` 액션 행). 예약됨 = `FkBadge` 높이 약 24.
      권장 = 수업 줄과 같이 **FkBadge(onTap)** 로 내리거나 `buttonHCompact` 를 28~30 으로.
      전자면 WOD 행 액션 3개(완료 표시·메시지·자세히)를 배지 줄로 통일하는 편이 깔끔하다.

## 대기 (이전부터 남은 것)

- [ ] 코치 PC 화면(`web/facing-admin`)을 브라우저로 열어 예약자 명단 실사 — 이번에도 못 함
- [ ] 벤치마크·등급 화면(`/onboarding/benchmarks`·`/onboarding/grade`) 존치 여부 결정
      (①과 함께 결정하면 좋다 — 둘 다 Engine 계열)
- [ ] `_kShowSocialLogin=false` (실 OAuth 키 대기)
- [ ] `applyPersonaSnapshot()` 이름 잔재
- [ ] `button_lint_test.dart` 신설 (§7-D 버튼 규칙 자동 게이트)

## 결정사항 / 주의

1. **완전 원형 pill 은 넣지 않았다.** 사용자가 "pill 버튼 모드"를 요청했으나 글로벌
   `rules/design-block.md` §2-B 차단 항목이라 r3(12) 사각으로 뒀다. 높이 36 에서 r4 를
   주면 사실상 원형이 된다. 예외를 원하면 사용자 승인이 필요하다.
2. **버튼 높이 36 은 DESIGN-SSOT 의 터치 48 기준보다 작다.** 사용자 지시 우선으로 내렸다.
   ②를 하면 더 작아지므로 터치 영역(FkBadge 는 내부에서 48 확보)을 반드시 확인할 것.
3. **`FacingTokens.buttonHCompact` 는 facing 전용이다.** appkit 마스터(52)를 고치면
   workcheck·writeplz 까지 따라 내려간다 — 건드리지 말 것.
4. **이 repo 에서 `dart format` 금지** (옛 SDK 포맷 — 118개 파일 재포맷).
5. **auto-save 훅이 작업 중간에 커밋을 만든다.** 이번에도 `8ecc0db`·`abbb85b` 로
   중간 상태가 커밋됐다. 코드는 HEAD 에 정상.
6. **백엔드는 `use_reloader=False`** — 고치면 프로세스를 죽였다 다시 띄울 것.
7. **배포 금지 유지.** 사용자가 "배포해"라고 하기 전까지 push·railway up 금지.
8. UI 를 바꾸면 **골든 재생성 + 갤러리 갱신이 완료 조건**
   (`flutter test --update-goldens test/golden` → `python tool/golden_gallery.py`).
9. **adb `input tap` 이 간헐적으로 하단 탭바로 튄다.** 새 Bash 호출의 첫 탭이 엉뚱한
   곳에 꽂히는 일이 두 번 있었다 — 무해한 첫 탭을 한 번 넣고 실제 탭을 보내면 됐다.
10. 검증 중 **목요일 07시 수업에 테스트 예약 1건**이 실제로 들어갔다 (회원 `member`).
    필요 없으면 앱에서 취소.

## 관련 파일

| 경로 | 역할 |
|---|---|
| `lib/features/gym/week_board.dart` | 주간 아코디언 (신설) — 요일 줄·수업 줄·예약 배지 |
| `lib/features/gym/wod_row.dart` | WOD 행 (분리) — **②의 '완료 표시' 버튼이 여기** |
| `lib/features/gym/box_wod_screen.dart` | WOD 탭 셸 + 박스정보·공지 아코디언 + 에러 배너 |
| `lib/features/classes/classes_screen.dart` | `reserveClassFlow`/`cancelClassFlow` 정본 |
| `lib/features/mypage/mypage_screen.dart` | 프로필 — **①의 `_ScoreSection` 이 여기** |
| `lib/features/home/home_screen.dart` | 홈 — 마일스톤 `_ProgressStat` |
| `lib/features/achievement/achievement_section.dart` | 업적 섹션·빈 상태 한 줄 |
| `lib/widgets/fkit.dart` | 버튼·배지·행·아코디언 규격 SSOT (높이 36·dense) |
| `lib/core/theme.dart` | `buttonHCompact` 및 전역 버튼 테마 |
| `docs/ARCHITECTURE_BRIEF.md` | D33 (WOD 탭 = 주간 아코디언) 기록 |

## 로컬 실행 메모

```
백엔드   cd C:/dev/services/facing && python app.py          # 0.0.0.0:5060, 수정 시 재시작 필수
빌드     flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.103:5060
설치     adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
콜드스타트 adb -s emulator-5554 shell am force-stop com.netizen.facing.facing_app
          adb -s emulator-5554 shell am start -n com.netizen.facing.facing_app/.MainActivity
캡처     adb -s emulator-5554 exec-out screencap -p > out.png
```
테스트 계정: 회원 `member` / `1234` (gym 2 = HYPHEN, approved)

## 다음 세션 권장 첫 프롬프트

`/resume` → 대기 ①②를 한 커밋으로 처리하고 골든 갱신까지.
