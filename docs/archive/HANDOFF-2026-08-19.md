# HANDOFF - 2026-08-19 11:51

> 주제: ① 인계 제1 과업 **PC 코치웹 연동 전수점검 150+건** 완주 (점검→수정→검증→커밋·푸시·배포)
> ② **골든 23→41장 전 화면 확장** + 리더보드 유령 행 픽스. 세 repo 전부 커밋·푸시 완료, 배포 완료.

## 완료 (이 세션)

1. **PC 웹 연동 전수점검 (전권 승인 지시)** — 인벤토리 280건 검증·결함 83건 전건 수정.
   점검 8팀 + 수정 7팀 병렬, 백엔드는 직접 수정. 정본 = `../../services/facing/docs/SSOT/PC연동-전수점검.md`
   + 갭대장 처리 이력 9차. 대표: 정지가 미래 갱신 회원권에 오적용(HIGH)·계약 XSS·템플릿 0개
   수업 등록 차단·출석 시 정원 재개방·gym.id 누락 배지 침묵·출석/결제 SSE 발행 신설·계약
   직렬화 통일·CSRF 확대(폰 겸용 공지는 세션 조건부 `_admin_csrf_guard`).
2. **검증** — 백엔드 pytest 105 passed 1 skipped (CSRF 확대분 테스트 2파일에 자동 헤더 클라이언트
   추가) · 스크래치 DB 실기동 38/38 · admin 웹 17페이지 콘솔 에러 0.
3. **배포** — Railway `railway up` 2건 모두 SUCCESS 실증: admin 웹은 프로덕션 페이지에서 신버전
   마커 검출, 백엔드는 배포 SUCCESS + health 정상. (`HYPHEN_BACKEND_URL` 은 이미 공개 URL — QR 폴백 정상.)
4. **골든 23→41장** — `test/golden/screens2_golden_test.dart` 신설 (17케이스 18캡처): 회원 심화 13
   (수업 예약 2·수업 상세·코치 질문 시트·쪽지 피드·업적 전체/상세·프로필 수정·계약·목표·FAQ·
   약관·방침) + 아이디 로그인 + 코치 셸 2탭(인계 대기분) + 명단 시트 하단 수업 취소(인계 대기분) +
   날짜 선택 다이얼로그. fakes 에 memberClassesReserved()·memberContracts 추가.
5. **결정론 픽스 2건** — ① `class_compose_sheet.dart` showDatePicker 에 `currentDate: today`
   (Material 내부 시계로 골든이 매일 깨질 시한폭탄, "시각은 appClock 만") ② fakes prefix 충돌
   (`/gyms/1/wods` 가 하위 results·comments·feedback 삼킴 → 리더보드 "0th user:" 유령 행) —
   `/api/v1/gyms/1/wods/` 빈 목록 선등록으로 해소.
6. flutter test **164 전건** (구 147 + 신규 17) · 갤러리 41장 재생성(`build/goldens_gallery.html`) ·
   HANDOFF archive 4→3개 정리.

## 진행중

- 없음.

## 대기 (후속 후보)

- [ ] 잔존 갭: 폰 수업 수정 PATCH(G24 2차) · 리더보드 is_pr 실판정(PC 컬럼 영구 공란) ·
      시즌 윈도우 연도 무구분 · CF_QUARTERFINAL require_engine · 온보딩 완료 영속 서버화(현 localStorage).
- [ ] §0-B 잔재: Railway 구명 변수 `FACING_BACKEND_URL`(admin 웹 콘솔, HYPHEN_ 과 중복) 정리.
- [ ] 에뮬레이터 실기 확인 — 이번 픽스·화면들을 실기동으로 한 바퀴 (희망 시).

## 결정사항 / 주의

1. **테스트 기준선 갱신**: 백엔드 105 passed 1 skipped (반드시 `pytest tests` — 루트 pytest 는
   `_archive/engine-retired` 를 수집해 7 에러) · 앱 164 전건 · 골든 게이트 34케이스.
2. **CSRF 확대 여파**: admin 변이 라우트 테스트는 세션 `csrf_token` + `X-CSRF-Token` 헤더 필요
   (패턴 = test_api_contract_onsite 의 _CsrfClient). 폰 boss 클라이언트는 상시 주입이라 무영향,
   구버전 설치 앱은 재로그인 필요 가능.
3. **골든 2부**는 1부 헬퍼를 import (`screens_golden_test.dart show rxProfile...`) — 1부 헬퍼
   rename 시 2부 동기화 (§0-B). fakes 맵은 구체 경로 먼저 (prefix 매칭 함정 — 이번에 실제로 당함).
4. 계정 3개(coach/member/admin · 1234)·로그인 429 5회/5분·이 repo dart format 금지·시각은
   appClock 만 — 전부 유지.
5. 검증용 로컬 서버(백엔드 :5060 스크래치 DB·admin :8081)는 세션 종료와 함께 죽음.

## 관련 파일

| 경로 | 역할 |
|---|---|
| `../../services/facing/docs/SSOT/PC연동-전수점검.md` | 전수점검 정본 (인벤토리·결함·수정·잔존) |
| `../../services/facing/api/{admin,classes,contracts,gym,payments_admin,notification_settings,members_search}.py` | 백엔드 수정 |
| `../../web/facing-admin/{app.py, static/*, templates/*}` | PC 웹 수정 (24파일, 파티셜 1 삭제) |
| `test/golden/screens2_golden_test.dart` · `test/golden/fakes.dart` | 골든 2부 + 가짜 월드 확장 |
| `lib/features/boss/class_compose_sheet.dart` | showDatePicker currentDate 픽스 |
| `tool/golden_gallery.py` · `CLAUDE.md` | 갤러리 41장·골든 문단 동기화 |

## 다음 세션 권장 첫 프롬프트

`/resume` — 대기 항목은 전부 선택적 후속. 급한 진행중 작업 없음.
