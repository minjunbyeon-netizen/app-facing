# HANDOFF - 2026-08-14 15:01

> 주제: **이월 과제 4건 완주 + FACING 명칭 잔존 실사**. 오전 인계(12:11 자) 반영으로 시작 —
> 앱 push 승인 집행, RX 어휘 유지 확정 후 이월 4건을 전부 처리하고, "이제 FACING 안 쓴다"
> 지시로 잔존 전수 실사까지. 만진 repo: `apps/facing-app`(구명 폴더 — repo 는 app-hyphen,
> push 완료) · `web/facing-admin`(= hyphen-admin, 로컬 커밋만 — push 보류 지시).

## 완료

1. **오전 인계 반영** — 앱 repo push 승인 집행(5커밋 → origin/app-hyphen) ·
   **RX·SCALED/RXD/ELITE 어휘 유지 확정** (사용자 "운동 등급표기 정도니 내버려둬" —
   메모리 `project-rx-tier-vocab-keep` 기록, 재론 금지) · facing-admin push 는 "일단 무시".
2. **applyPersonaSnapshot → applyProfileSnapshot 개명** (7b817b6, §0-B grep 2건).
3. **button_lint_test 신설** (84f446c) — §7-D "버튼 = HkButton 1종" 게이트. 원시 버튼이
   이미 37파일에 있어 0건 게이트 불가 → **래칫**: baseline 밖 0건 + 이관 완료 파일 목록
   축소 강제 + 터치 48 미만·muted 전경 전면 0건. 신설 즉시 classes_screen 예약·취소 버튼
   높이 44 적발 → touchMin(48) 픽스 동봉.
4. **골든 날짜 드리프트 근본 해결** (ae1440b) — `package:clock` 존 주입(withClock)이
   **테스트 본문까지 전파 안 됨을 프로브로 실측** (package:test 가 본문을 선언 존 밖에서
   실행) → `lib/core/app_clock.dart` 전역 주입(appClock)으로 설계 변경. DateTime.now()
   45곳 전량 교체, flutter_test_config 가 Clock.fixed(**2026-08-12 수 10:30**) 고정,
   골든 8장 재생성, clock_lint_test 게이트 신설. **flutter test 146건 전건 통과.**
5. **hyphen-admin 가입 신청 표 "운동 경력 · 부상" 요약 1줄** (7d3e77b, 로컬만) —
   목록 API 가 8/13부터 싣던 sports_history·safety_note 를 표에 노출 (부상 강조색 +
   말줄임 + title 툴팁, 콜스팬 5→6). 코치가 상세 안 열고 승인 판단.
6. **FACING 잔존 전수 실사** — GitHub 4 repo 는 이미 전부 hyphen 개명 완료
   (app-hyphen·service-hyphen·web-hyphen-admin·web-hyphen), 앱·백엔드 노출 문구 클린
   (히스토리 주석 2줄뿐). `C:/dev/rename-hyphen-finalize.bat` 보강 — **facing-web 폴더
   누락 추가 + Claude 메모리 폴더 이관 [4/4] 단계 신설** (개명 시 경로 해시 변경으로
   세션 기억 끊기던 문제). 호칭 방침 메모리 저장 (`feedback-name-hyphen-not-facing`).

## 진행중

- 없음 (이월 목록 4건 전부 소진).

## 대기

- [ ] **물리 폴더 스왑** — 사용자가 모든 Claude 세션·서버(5060/8081/5062)·IDE 닫고
      `C:/dev/rename-hyphen-finalize.bat` 실행. 이 세션이 facing-app 점유 중이라 세션
      내 실행 불가. junction 으로 hyphen 경로 이미 유효해 급하지 않음.
- [ ] **Railway 무중단 개명 설계** — service-facing 프로젝트/도메인 3종. 도메인이 배포
      APK 3005·3006 에 구워져 있어 즉시 개명 불가 — 커스텀 도메인 → 앱 전환 빌드 →
      개명 순서 별건 설계 필요 (사용자 결정 대기).
- [ ] **hyphen-admin push** — ahead 1 (7d3e77b). 병행 세션이 그 repo 에서 작업·push 중이라
      조율 후. (사용자 "일단 무시" 상태 유지.)
- [ ] 원시 버튼 37파일 → HkButton 이관 (래칫 조이기 — 별건 큰 작업).
- [ ] 실기 갤S22 에 3006 설치 (`/연결` 후 adb install).

## 결정사항 / 주의

1. **시각 접근은 appClock 만** — `DateTime.now()`·존 주입 `clock.now()` 은
   clock_lint_test 가 차단. withClock 존 주입은 무효 (2026-08-14 프로브 실측).
2. **테스트 고정 시각 = 2026-08-12(수) 10:30** (`flutter_test_config.dart` kTestClock).
   날이 바뀌어도 골든 재생성 불요 — 날짜 드리프트 항목은 이월 목록에서 영구 소멸.
3. **골든 8장 중 boss_02_dashboard·common_05_signup 은 병행 세션의 auto-save 코드
   변경분(b7dc6eb — 브리프 §11.9 CoachShell·signup/boss_dashboard)이 함께 찍힘** —
   그쪽 세션이 골든 재생성하면 충돌 여지. 병행 세션 활동 중이니 커밋 전 git status 필수.
4. 앱 repo 커밋이 내 push 전에 origin 에 선반영되는 일 있었음 (병행 세션 or 훅 push) —
   push 시 "up-to-date" 나와도 이상 아님.
5. **호칭은 hyphen 계열만** ("(구 facing)" 병기 허용). 단 Naver OAuth URL scheme
   'facing' 은 개발자 콘솔 동기화 전 변경 금지.
6. hyphen-admin 가입 표 변경은 실브라우저 렌더 미검증 (정적 검토만) — 다음에 가입
   pending 회원 있는 상태로 한 번 열어볼 것.
7. 이 repo `dart format` 금지 유지.

## 관련 파일

| 경로 | 역할 |
|---|---|
| `lib/core/app_clock.dart` | 시각 접근 SSOT (appClock) — 신설 |
| `test/clock_lint_test.dart` · `test/button_lint_test.dart` | 신설 게이트 2종 (시각·버튼) |
| `test/flutter_test_config.dart` | kTestClock 고정 (2026-08-12 10:30) |
| `test/golden/goldens/` (8장 갱신) | 날짜 고정 반영 골든 |
| `web/facing-admin/templates/members_join.html` | 요약 1줄 (hyphen-admin, 로컬 커밋만) |
| `C:/dev/rename-hyphen-finalize.bat` | 폴더 스왑 (facing-web·메모리 이관 보강) |
| 메모리 `feedback-name-hyphen-not-facing` · `project-rx-tier-vocab-keep` | 호칭·어휘 방침 |

## 다음 세션 권장 첫 프롬프트

`/resume`
