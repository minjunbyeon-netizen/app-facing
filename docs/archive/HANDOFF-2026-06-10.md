# HANDOFF - 2026-06-10 09:00

## 완료
- [x] **#3 WOD 동작별 구조화** — 백엔드 + 앱 코드 구현·로컬 커밋 완료 (양쪽 repo)
  - 백엔드 `api/gym.py`: `_safe_movements()` 헬퍼 + `post_wod` 라운드 직렬화에 `movements[]` 추가, `GET /gyms/{id}/wods` 가 `rounds_data`(movements 포함) 반환 확인
  - 앱 `models/gym.dart`: `WodMovementItem` 클래스 + `WodRoundItem.movements`/`hasMovements`
  - 앱 `wod_detail_screen.dart`: `_buildMovementRounds()` + `_MovementRow` (sets×reps·load·rest + Demo 영상 링크), `_openVideo()` (url_launcher)
  - `dart analyze`: No issues. 커밋 ff45fbf
- [x] **출석 캘린더 가짜데이터 버그 수정** — 개인 페이싱 기록 → 실제 QR 출석(`/api/v1/member/attendances`)로 교체. 커밋 2e25b84
- [x] **레퍼런스 11화면 분석 + Opus 병렬회의 + Plan** — `docs/benchmark/magnum/{ANALYSIS,MEETING-MINUTES,PLAN}.md`
- [x] **API 응답 검증** — WOD 126(gym 2) `/api/v1/gyms/2/wods` 응답에 movements 정상 포함 확인 (회원 김도윤 device→member id 22, gym 2, approved)

## 진행중
- [ ] **#3 상세 화면 동작 행 렌더 시각 확인** — 마지막 한 스텝만 남음
  - 환경: 백엔드 5060 가동, 에뮬레이터 emulator-5554, demo 회원 `persona-member-kim-doyun-2026`(member 모드)로 로그인 상태
  - 검증 대상 WOD: id=126 "[STRUCT-0609]" (gym 2, TODAY 06.09)
    - round0 Strength: Back Squat 5×3-3-3 80%1RM rest120 (+video)
    - round1 Metcon AMRAP12: Reverse Lunge 2×10~12 42kg / Toes-to-Bar 2×8 / Wall Ball 15 9kg
  - 진행 지점: WOD 리스트 → 도움말 오버레이 닫음 → STRUCT-0609 카드 "Detail →" 탭 직후 스크린샷 단계에서 도구 internal error 로 중단
  - 다음 스텝: `adb -s emulator-5554 exec-out screencap` → 0.5배 다운스케일(System.Drawing) → Read 로 `_MovementRow` 렌더 육안 확인. 탭 안 먹으면 `uiautomator dump` 로 Detail 버튼 bounds 재확인 (스케일 좌표: Detail→ 약 full 870,1682)
  - ⚠ Bash 로 adb shell + `/sdcard` 경로 쓸 때 `export MSYS_NO_PATHCONV=1` 필수

## 대기
- [ ] **B2-2 1RM 환산** — 동작별/티어별 처방 비율(%1RM) 출처가 engine·science docs 에 없음. 도메인 결정 필요 (ADR)
- [ ] **예약 roundtrip 검증** — OPEN class 세션 시드 후 회원 예약 흐름 확인 (현재 51세션 중 최근분 cancelled — 데이터 공백)
- [ ] **동작 영상 매칭 레이어** (B2 phase2) — 동작 slug → 데모 영상 자동 매핑. 현재는 코치가 video_url 수동 입력
- [ ] **CLAUDE.md 디자인 토큰 동기화** — 문서는 구 dark 토큰, 코드는 v2.0 light(`dark`=`light` alias). 사용자 승인 후 문서 갱신 (코드 변경 X)

## 결정사항 / 주의
- **배포 금지 (최상위)** — 사용자가 "배포해/push/출시/릴리즈" 명시 전까지 git push·Railway·스토어 일체 금지. 로컬 commit 만 허용. 이번 세션 모든 커밋 push 안 함
- 상태관리 = provider + ChangeNotifier (Riverpod 아님), 라우팅 = main.dart named routes (go_router 아님) — 기존 패턴 따를 것
- 테마 = v2.0 light 가 의도된 정본. dark 토큰 문서는 drift, 코드 건드리지 말 것
- 코치 WOD 작성은 owner device auth 필요 → 검증용 WOD 는 로컬 DB 직접 insert(owner_hash author)로 시드함
- WOD 상세는 `GET /api/v1/gyms/{id}/wods`(rounds_data 포함)에서 로드, `/member/box-wods`(요약)는 아님
- Rule 1: 매 응답 종료 시 PushNotification 발사 + 30분 idle 재발사

## 다음 세션 권장 첫 프롬프트
`/resume`
