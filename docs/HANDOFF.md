# HANDOFF - 2026-08-19 13:13

> 주제: G24 2차(폰 수업 수정) + 인계 잔존 갭 2건 + §0-B Railway 잔재 + 에뮬레이터 실기 실증.
> 사용자가 "잔존 갭 마지막 2건" 착수를 "1" 로 지시한 직후 컨텍스트 93% 로 인계.

## 완료 (이 세션)

1. **G24 2차 — 폰 수업 수정 PATCH (G24 종결)**
   - 백엔드: 명단 응답(admin_list_class_reservations)에 duration_minutes·track 동봉
     (폰 프리필용) + 회귀 6건 신설 `tests/test_gap_g24_class_edit.py`.
   - 앱: `class_compose_sheet.dart` edit 모드(showClassEditSheet — 프리필·PATCH
     4필드·start_at 은 읽기 전용 + "취소 후 재등록" 안내) + 명단 시트 '수업 수정'
     버튼·저장 후 재조회(ObjectKey 재생성). 골든 boss_07 신규·boss_05 재생성(42장).
2. **리더보드 is_pr 실판정** — admin_leaderboard 하드코딩 False 제거. For Time 한정,
   이전 날짜 같은 wod_type·같은 scale 본인 최고 대비 strict 단축 = PR (첫 기록 제외,
   폰 PrDetector 정책 미러). PC wod.html PR 태그 실동작. 회귀 3건
   `tests/test_leaderboard_is_pr.py`.
3. **온보딩 완료 영속 서버화** — 소셜 로그인 후 로컬 hasGrade 없으면
   `GET /api/v1/member/me/profile` 의 name+level 로 판정
   (`ProfileState.onboardingDoneFrom` + `signup_screen._routeByRole` async 화).
   재설치·기기 변경 시 재온보딩 제거, 실패 시 로컬 판정 폴백. 단위 4건
   `test/onboarding_done_test.dart`.
4. **§0-B Railway 잔재** — web-facing-admin 콘솔 `FACING_BACKEND_URL` 삭제
   (HYPHEN_BACKEND_URL 과 동일값 중복, 배포본 08-19 02:05 는 신명만 읽음 확인 후
   집행. 재배포 트리거 없음·프로덕션 /login 200. CLI `railway variable delete` 사용
   — C:/dev/.env 의 RAILWAY_API_TOKEN 은 무효, railway login 세션이 정본).
5. **에뮬레이터 실기 실증** — 코치 폰 수정(90분·정원8·트랙RX) 저장 → 명단 0/8 →
   대시보드 04:00–05:30·0/8명 → 회원 수업 탭 0/8. 실백엔드(:5060) 왕복.
   adb 좌표 탭 방식 (한글 input text 불가 → 숫자·영문 필드로 실증).

## 진행중

- 없음 (다음 과업 착수 직전 인계).

## 대기

- [ ] **잔존 갭 마지막 2건** — 사용자가 "1" 로 착수 지시. 새 세션 제1 과업:
      ① 시즌 윈도우 연도 무구분 (achievement_checker `_SEASON_WINDOWS` — 월일만
      비교, 연도 구분 없음) ② CF_QUARTERFINAL require_engine (시드의 요구 조건
      트리거 미구현 계열). 정본 = `../../services/facing/docs/SSOT/갭대장.md`
      (처리 이력 11차까지 반영됨).
- [ ] PC 웹 PR 태그 실기 확인 (For Time 기록 2건 넣어 재현) — 백엔드 테스트로만 검증됨.
- [ ] 로컬 `hyphen.db` 테스트 수업 1건: 04:00–05:30·정원 8·트랙 RX 로 남음
      (이 세션 실기로 수정됨). 정리 = 코치 로그인 → 명단 시트 → 수업 취소.
- [ ] 로컬 커밋 push — "배포해" 명시 시에만. 미푸시 커밋: 앱 4건
      (bfba8cf·f476c77·8de7a1a + 이 handoff), 백엔드 2건 (fcae6a5·a26c4c9).

## 결정사항 / 주의

1. **이 repo push 금지** (배포 금지 규칙 v1.16.1) — 이 세션도 로컬 커밋만.
2. is_pr 판정은 "같은 wod_type" 기준 — 게시물 제목 컬럼이 없어 벤치마크 구분 불가
   (Fran↔Murph 가 같은 for_time 으로 비교됨). 현 스키마의 최선으로 합의.
3. 온보딩 서버 판정은 **소셜 로그인 경로만** 배선 (아이디 로그인은 별도 경로).
4. 수업 수정 PATCH 는 start_at 미지원 (PC 동일) — 시간 변경 = 취소 후 재등록.
   수정 후 SSE 미발행 (PC 도 동일) — 열려 있는 회원 화면은 재조회 시 반영.
5. 기준선 갱신: 백엔드 **114 passed 1 skipped** (`pytest tests`) · 앱 **169 전건** ·
   골든 게이트 36케이스(**42장**). 계정 coach/member/admin·1234 · dart format 금지 ·
   시각은 appClock 만.
6. 실기 자동화 함정 (재확인): 로그인 폼 "coach"/"····" 는 placeholder — 탭 후
   실입력 필요. 검증용 프로세스(백엔드 :5060·에뮬레이터)는 세션 종료와 함께 죽음.

## 관련 파일

| 경로 | 역할 |
|---|---|
| `lib/features/boss/class_compose_sheet.dart` | 등록+수정 2모드 시트 (G24 2차) |
| `lib/features/boss/class_roster_sheet.dart` | '수업 수정' 진입 + 재조회 배선 |
| `lib/features/profile/profile_state.dart` | onboardingDoneFrom 판정 헬퍼 |
| `lib/features/auth/signup_screen.dart` | 로그인 후 서버 판정 라우팅 |
| `../../services/facing/api/classes.py` | 명단 응답 duration·track 동봉 |
| `../../services/facing/api/admin.py` | 리더보드 is_pr 실판정 |
| `../../services/facing/docs/SSOT/갭대장.md` | 처리 이력 10·11차 — 다음 과업 정본 |

## 다음 세션 권장 첫 프롬프트

`/resume` — 제1 과업: 잔존 갭 마지막 2건 (시즌 윈도우 연도 무구분 · CF_QUARTERFINAL
require_engine). 갭대장 확인 후 백엔드 → 테스트 순.
