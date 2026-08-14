# HANDOFF - 2026-08-14 09:16

> 주제: **크로스핏 표기 철수 시작(탭 개편) + 백엔드 /history 복원 배포 + APK 3005 E2E**.
> 만진 repo: `apps/facing-app`(로컬 커밋만 — 배포 금지 룰) · `services/hyphen`(커밋 + `railway up` 배포, GitHub push 안 함).
> 대전제: **이 제품은 크로스핏장이 아니다** (2026-08-14 사용자 확인) — 크로스핏 어휘(WOD·박스·RX·크로스핏 경력) 철수 진행 중.

## 완료

1. **v2.9** — 첫 진입 탭 힌트 튜토리얼(`_TabHintOverlay`) 전면 삭제(사라진 Tier 안내하던 화면) +
   수업(구 WOD) 탭 앱바 새로고침이 수업 목록까지 갱신하도록 배선 통일(`refreshAll`).
   PC 수업 등록 → 폰 새로고침 버튼 미반영 버그 해소.
2. **v3.0 1단계** — 하단 3탭 표기 **홈 · 수업 · 내 정보** (구 홈·WOD·프로필) + 수업/내 정보
   화면 제목 일치. CLAUDE.md 셸 3탭 행 2곳·golden_gallery.py 동기 갱신 (§0-B).
3. **백엔드 `/api/v1/history/*` 복원 + railway up 배포** — 8/13 엔진 폐기(2c4b740)가 폰 홈
   게이미피케이션·이력 화면이 소비하는 경로를 지워 배포된 앱 홈이 404("경로를 찾을 수
   없습니다")로 죽어 있었다. history.py 는 engine 의존 0 이라 파일 복원+블루프린트 재등록만
   (`services/hyphen` af35b1b). 프로드 200 + 에뮬 홈 렌더 실검증. pacing·movements·presets 폐기는 유지.
4. **APK 3005 로컬 빌드**(prod URL 주입) → **에뮬레이터 + 실기(무선 adb 192.168.1.100:5555) 설치**.
   패키지 개명(hyphen_app) 첫 빌드 — 실기에 구 3004(facing_app)와 **병존**(구 앱 삭제는 사용자 몫).
   릴리스 업로드는 안 함 (배포 승인 필요).
5. **E2E 실검증** — 에뮬 3005 에서 가입 신청 7항목(자동 하이픈·SCALED 자동표시) → PC 코치 승인
   API → 즉시 입장. **새 탭 라벨 ✓ 튜토리얼 미노출 ✓ 홈 레벨·업적 정상 ✓**. 신청 값(생년월일·성별·
   연락처·레벨)의 코치 목록 도착 확인 후 테스트 회원(TEST3005, id=4) 하드 삭제 완료.
6. 에뮬 진단 부산물 — "로그인 안 된다"는 일시 네트워크 플레이크(현재 정상), 진짜 고장은 위 3번.
   에뮬 타임존 GMT → Asia/Seoul 교정.
7. 8/13 인계장 archive 이동(`docs/archive/HANDOFF-2026-08-13.md`).

## 진행중

- [ ] **골든/스크린샷 20장 재촬영** — 사용자 마지막 지시 "골든 전부 다시, 에뮬 콜드스타트하고
      스크린샷 한 20장" — **컨텍스트 경고로 착수 못 함**. 해석 2갈래라 1줄 확인 권장:
      (a) 에뮬 실기동 화면 20장 캡처 (b) `flutter test --update-goldens test/golden` 재생성.
      (a)면: 콜드부팅(`%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe -avd Medium_Phone_API_36.1
      -no-snapshot-load`) → 부팅 후 **`adb shell cmd alarm set-timezone Asia/Seoul` 필수**(리셋됨) →
      3005(`com.netizen.hyphen.hyphen_app`) 순회 캡처. ⚠ 에뮬 새 앱 세션은 테스트 회원 삭제로
      고아 — 재로그인 필요한데 회원 비번은 사용자만 앎. 구 앱(facing_app 3004)엔 cheb2oyy 세션 생존.

## 대기

- [ ] **게시글(구 WOD 게시물) 이름 결정** — '수업' 직행은 시간표 수업과 동명 충돌이라 보류.
      제안: ① "수업 내용"/"수업 시간" 두 면(⭐추천) ② "코치 노트" ③ 직접 지정.
- [ ] 결정 후 **크로스핏 표기 전면 스윕** — 앱(WOD 145곳·박스 156곳)+PC 웹(97곳) 노출 문구,
      "박스 가입 신청"→"회원 가입 신청"·"크로스핏 경력"→"운동 경력"(승인됨), GLOSSARY §2 ·
      DESIGN-SSOT §7(금지어 '운동' 해제) · CLAUDE.md 카피 · copy lint 를 **같은 커밋**으로.
      내부 코드·API·DB 이름은 유지 (GLOSSARY §4 원칙).
- [ ] **골든 일괄 재생성** — 날짜 드리프트 7장 + 탭 라벨 변경분. 표기 스윕 커밋에서 한 번에.
- [ ] 백엔드 GitHub push (af35b1b 로컬만 — push 게이트 통과 필요) · 앱 repo push (배포 승인 시).
- [ ] 이월: 가입 관리 표 경력·부상 요약 1줄 · `package:clock` 47곳(골든 날짜 근본 해결) ·
      `applyPersonaSnapshot` 잔재 · `button_lint_test` 신설.

## 결정사항 / 주의

1. **크로스핏장이 아니다** — 표기 철수는 "노출 문구만, 내부 이름 보존" 노선. 탭은 확정 집행됨.
2. SSOT 대차대조(`services/hyphen/docs/SSOT/`)는 **완성 스냅샷** — 참고해 고쳐도 됨
   ("갭 수정은 별건 승인 후 집행" 명시). 이번 /history 복원이 그 첫 사례.
3. 코치 승인 API: `POST /api/v1/admin/login` body `{"login_id":"coach","password":"1234"}`
   (username 아님) → 응답 `csrf_token` → `PATCH /api/v1/admin/members/<id>/status`
   body `{"action":"approve"}` + `X-CSRF-Token`. 로그인 rate limit **5회/5분**.
4. 에뮬 AVD(Medium_Phone_API_36.1)는 **콜드부팅마다 타임존 GMT 리셋** — 주간보드가 엉뚱한
   주를 보이면 이것부터. `adb shell cmd alarm set-timezone Asia/Seoul`.
5. 실기 폰 무선 adb `192.168.1.100:5555` 연결돼 있음 — adb 명령은 `-s` 지정 필수.
6. 이 repo `dart format` 금지 · autopush 훅이 중간 auto-save 커밋 생성(3005 pubspec bump 포함).

## 관련 파일

| 경로 | 역할 |
|---|---|
| `lib/features/shell/main_shell.dart` | 3탭 라벨(홈·수업·내 정보) · 튜토리얼 삭제 지점 |
| `lib/features/gym/box_wod_screen.dart` | 수업 탭 — `refreshAll` 배선 · 앱바 제목 '수업' |
| `lib/features/gym/week_board.dart` | 주간보드 (WOD 게시물+수업 시간표 동거 — 이름 충돌 현장) |
| `lib/features/mypage/mypage_screen.dart` | '내 정보' 제목 |
| `services/hyphen/api/history.py` + `api/__init__.py` | 복원된 /history (af35b1b, 배포됨) |
| `docs/GLOSSARY.md` §2 | WOD·박스 정본 표기 — 스윕 때 뒤집을 곳 |
| `docs/DESIGN-SSOT.md` §7 | 영문 고정어·금지어 목록 — 스윕 때 갱신 |
| `test/golden/screens_golden_test.dart` | tapTab '내 정보' 반영됨 · 골든 재생성 대기 |
| `build/app/outputs/flutter-apk/app-release.apk` | 3005 (58.8MB, prod URL, 사이드로드용) |

## 다음 세션 권장 첫 프롬프트

`/resume` → ① 20장 촬영의 의미(실기동 캡처 vs --update-goldens) 1줄 확인 후 실행,
② 게시글 이름 받아 표기 전면 스윕.
