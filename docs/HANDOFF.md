# HANDOFF - 2026-08-14 12:11

> 주제: **크로스핏 표기 전면 철수 v3.0 2단계 집행 + 실기동 검증**. 사용자 "1,2,3 다 해" 승인으로
> 게시글 이름 확정(추천안) → 앱+PC 웹 스윕 → 3006 빌드 → 에뮬 실기동 21장 촬영까지 완주.
> 만진 repo: `apps/facing-app`(로컬 커밋만 — 배포 금지 룰) · `web/facing-admin`(로컬 커밋, push 보류).
> 백엔드는 이번 세션에서 안 만짐 (af35b1b 는 병행 세션이 이미 push 완료 확인).

## 완료

1. **골든 1차 재생성** (117cb7e) — 3탭 라벨 v3.0 + 날짜 드리프트 11장, CLAUDE.md 장수 기록
   20→22 실측 정정 (§0-B).
2. **게시글 이름 확정** — WOD 게시물 = **"수업 내용"** / 시간표 면 = **"수업 시간"**
   (주간보드 한 날짜 안에 두 섹션 헤더로 분리, `week_board.dart`).
3. **크로스핏 표기 전면 스윕** (747506b) — 앱 45파일 노출 문구: 박스→**체육관**(조사 처리
   '박스가'→'체육관이', 인박스·아웃박스·체크박스 보호) · WOD→수업 내용 · 크로스핏/CrossFit 경력→
   **운동 경력** · "박스 가입 신청"→**"회원 가입 신청"**. 내부 심볼·API·DB·파일명 보존 (GLOSSARY §4).
   고유명사 보존: Fran·Girls/Hero/Games WOD·CrossFit Open/Games·명언 원문.
   같은 커밋에 GLOSSARY §2 v2(표 뒤집음)·DESIGN-SSOT §7·CLAUDE.md 카피 정본 동기 +
   **copy lint '크로스핏 표기 0건' 게이트 신설** + 금지어 '운동' 해제 + 골든 22장 2차 재생성.
   `flutter test` 140건 전건 통과.
4. **PC 웹 facing-admin 113곳 스윕** (82be5fa, 로컬만) — 템플릿 15종 + seed_demo.
   `member_detail.html` 은 병행 세션 미커밋 변경이 있어 제외 (잔존 = JS 주석 2곳뿐).
5. **백엔드 push 확인** — af35b1b 는 이미 origin/master 에 포함 (병행 세션 push). 추가 작업 없음.
6. **3006 빌드 + 에뮬 실기동 검증 21장** — prod URL 주입 빌드, 콜드부팅(-no-snapshot-load) +
   `adb shell cmd alarm set-timezone Asia/Seoul`. TEST3006 셀프 가입(id=4) → 코치 API 승인 →
   전 화면 순회 캡처(`build/shots-3006/`, zip 사용자 전달) → **하드 삭제 완료** (실회원 id 2·3 만
   잔존 실측). 새 카피 전부 실물 확인 (수업 내용/수업 시간 두 면 + 프로드 실데이터 AMRAP).
7. pubspec 3006 커밋 (062f7d6) · 8/14 인계장 archive 이동 + 최신 3개 유지 (b9945c2).

## 진행중

- 없음 (이번 세션 스코프는 완주).

## 대기

- [ ] **앱 repo push** — 배포 금지 룰상 사용자 "배포해/push" 명시 필요. 로컬 커밋 4개
      (b9945c2·117cb7e·747506b·062f7d6 + autopush auto-save 가능).
- [ ] **facing-admin push** — ahead 1 (82be5fa). 병행 세션이 그 repo 에서 작업 중이라 보류.
- [ ] **업적·레벨 어휘 잔존 결정** — 업적 카탈로그(첫 측정·RX 기준·스케일드 도달·ENGINE/TIER
      칩)와 레벨 표기 SCALED/RXD/ELITE 는 이번 스코프 밖 — 크로스핏 어휘 유지 중. 철수 여부 별건.
- [ ] **ARCHITECTURE_BRIEF·3면 대전제 "박스" 문구** — 내부 문서라 미변경. 브리프 §11 절차로 별건
      (3면 CLAUDE.md 대전제 3줄도 동시에).
- [ ] 실기 갤S22 에 3006 설치 (세션 시작 시 미연결 — `/연결` 후 `adb -s` install).
- [ ] 이월: 가입 관리 표 경력·부상 요약 1줄 · `package:clock` 47곳 · `applyPersonaSnapshot` 잔재 ·
      `button_lint_test` 신설.

## 결정사항 / 주의

1. **표기 정본 = `docs/GLOSSARY.md` §2 v2** — 체육관·수업 내용·수업 시간·운동 경력.
   자동 게이트 = `test/copy_lint_test.dart` '크로스핏 표기 0건' (문자열 리터럴 라인만 검사,
   예외 = quotes.dart·titles_catalog.dart, `(Girls|Hero|Games) WOD` 정규화 후 검사).
2. 에뮬 앱은 **로그아웃 상태로 종료** (TEST3006 삭제로 세션 고아 — 정상). 구 3005 는 실기에 잔존.
3. 코치 화면 실기동 캡처 불가 — 앱 코치 로그인 진입점 숨김 (`signup_screen.dart
   _kShowBossEntry=false`, v2.6 코드 보존). 회원 로그인 폼으로 coach 계정 로그인 안 됨 (실측).
4. 코치 API 재확인: `POST /api/v1/admin/login` body `{"login_id":"coach","password":"1234"}` →
   `csrf_token` / 회원 목록 = `GET /api/v1/admin/gyms/2/members` / 승인 = `PATCH
   /api/v1/admin/members/<id>/status` `{"action":"approve"}` / 삭제 = `DELETE
   /api/v1/admin/members/<id>`. 로그인 rate limit 5회/5분.
5. 에뮬 AVD 콜드부팅마다 타임존 GMT 리셋 — `set-timezone Asia/Seoul` 필수 (주간보드 주 표시).
6. 스윕 스크립트는 scratchpad (세션 소멸) — 잔존 재검증은
   `grep -rn "박스\|크로스핏\|CrossFit\|WOD" lib web` + copy lint 로 재현.
7. 이 repo `dart format` 금지 · PC 웹 sweep 커밋에 병행 세션 파일 미포함 원칙 유지.

## 관련 파일

| 경로 | 역할 |
|---|---|
| `docs/GLOSSARY.md` §2 v2 | 표기 정본 (체육관·수업 내용·수업 시간) — 이번에 뒤집음 |
| `docs/DESIGN-SSOT.md` §7 | 카피 규칙 — 크로스핏 철수 항목 추가, '운동' 해제 |
| `test/copy_lint_test.dart` | 신설 게이트 '크로스핏 표기 0건' |
| `lib/features/gym/week_board.dart` | 두 면 헤더 (수업 내용/수업 시간) 구조 지점 |
| `web/facing-admin/templates/**` | PC 웹 스윕 (82be5fa) — member_detail 만 미스윕 |
| `build/shots-3006/` + `build/shots-3006-live-20.zip` | 실기동 캡처 21장 (git 미추적) |
| `build/app/outputs/flutter-apk/app-release.apk` | 3006 (58.8MB, prod URL) |

## 다음 세션 권장 첫 프롬프트

`/resume` → ① push 승인 여부 확인 (앱 + facing-admin), ② 업적·레벨 어휘(RX 등) 철수 여부 결정.
