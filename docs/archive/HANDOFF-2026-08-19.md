# HANDOFF - 2026-08-19 08:46

> 주제: **3면 SSOT 전수조사 → 갭 픽스 → 실기동 상호연동 검증** 완주 후,
> 사용자 신규 대작업(PC 코치웹 연동 전수 점검 150+건) 착수 직전 컨텍스트 99% 로 인계.
> 만진 repo: `services/facing`(백엔드) · `web/facing-admin`(PC 웹) · `apps/facing-app`(앱) — 커밋 전부 로컬.

## 다음 세션의 제1 과업 (사용자 지시 원문 — 2026-08-19 08:44, 전권 승인)

> "이제 pc(코치 웹) 화면내에서 클릭해서 연동되는 모든 모달이나 버튼 페이지 이동 등등이
> 지금 api 대로 연결되어있는지 2차작업해봐. 예를들어서 지금 회원권설정을 했는데 막상
> 회원에게 회원권 설정할때는 엉뚱한 api를 불러온다던가. 제대로 불러와지더라도 반영이
> 안된다던가. 이런 문제가 발견된다. **150개 이상 찾아내고 전부 반영이 제대로 될때까지
> 전부 수정하고, 모든 내용 배포 및 커밋, (아까한것까지 전부다 실행해라, 모두 승인한다
> 묻지마라) /loop 10s 모든 작업승인함. 내가 말한 내용끝날때까지 계속**"

- **전권 승인 명시됨**: 수정·커밋·푸시·배포까지 묻지 말고 실행 (배포 금지 룰의 "명시 키워드" 충족 — "배포" 원문 인용 가능).
- `/loop 10s` 등록 요구 (cron 최소 단위 1분 반올림 — 이전 /loop 때 15s→1m 전례 설명 완료).
- 150+ 건은 "발견 항목 수" 목표 — **PC 웹 전 템플릿의 클릭 가능 요소(버튼·모달·onclick·fetch·페이지 이동) 전수 인벤토리부터 뽑고** 각 항목을 API 계약·실반영(DB/재조회)까지 대조하는 접근 권장. 재료: `services/facing/docs/SSOT/_facts/facts_04*`(PC 호출 125건)·`대차대조표.md`·오늘 발견 계보.

## 완료 (2026-08-18~19 이 세션)

1. **3면 SSOT 전수조사 2회** — 지목 4영역 → 13개 도메인 전체(약 190개 개념). 정본 = `services/facing/docs/SSOT/대차대조표.md` 부록 2(판정 변동 19행·폐기 7행·잔존 색인) + 갭대장 처리 이력 7·8차 + INDEX 종결 주석.
2. **갭 픽스 1차 (G25·G09·G15·G16)** — 수업 track 회원 노출, 목록 login_id, 알림톡 토글 4종 실배선(해지·결제 발송부 신설+수업취소 게이트), 야간 금지 시각 DB 반영. 동반 적출 2건: `api/notifications/__init__.py` ImportError 잠복 결함(8/14 폐기 잔재 import — 예약취소 알림 침묵 실패), 로그인 429(HTML)가 admin 웹 proxy_login 에서 500 위장(비JSON 가드 추가). 백엔드 pytest 96→105 passed.
3. **실기동 왕복 12/12** — 스크래치 DB·프록시 실경유(가입→승인→성별정규화→공지→수업track→예약명단→포인트→알림게이트→코치폴백). 스크립트 = 세션 스크래치 `e2e_verify.py` (승인 body=`{"action":"approve"}`, 포인트 `type:"earn"` 필수 — 계약 함정 2개 기록).
4. **갭 픽스 2차 (G24·G19·G20)** — 폰 수업 **등록·취소**(class_compose_sheet 신설, PATCH 수정은 미구현 잔존), 달성불가 업적 4종 숨김 전환(카탈로그 52→48), CF 시즌 윈도우 3종 정의. pytest 105 passed·flutter 147 전건.
5. **코치 셸 2탭 v3.3 (사용자 지시)** — 예약 현황(BossDashboard)·수업(회원과 동일 BoxWodScreen). 회원현황·쪽지 탭 제거(코드 보존), "회원 관리" 버튼을 승인 화면 push 로 실배선(구 스낵바 stub). 로그인 힌트 boss_seongsu→coach. 브리프 §11.9 v3.3 동기화.
6. **계정 3개 체제 정리 (사용자 지시)** — 두 로컬 DB(스크래치 + `services/facing/data/hyphen.db`) 모두 **coach/1234(코치)·member/1234(회원)·admin/1234(예외)** 만 남기고 계정·데이터 전량 삭제. member/1234 = HQ 승인 회원(이름 '멤버', device `member-phone-001`). 구명 잔재 `data/facing.db` 삭제. 정리 스크립트 = 스크래치 `clean_accounts.py`.
7. **에뮬↔PC 상호연동 실기 검증 (캡처 실증)** — 폰 코치 수업 등록→PC 캘린더 / PC 수업·공지→코치·회원 폰 보드 / member 예약→PC 명단 [멤버·confirmed]. 에뮬레이터 = Medium_Phone_API_36.1 (UTC 시간대 주의 — 등록 기본 시각이 KST 로 어긋남).

## 진행중

- 없음 (신규 대작업은 착수 전 인계).

## 대기

- [ ] **제1 과업 실행** (위 지시 원문) — /loop 등록 + PC 웹 연동 전수 점검·수정.
- [ ] **미푸시 로컬 커밋 푸시 + 배포** (전권 승인됨): backend 4(04afc02·3583b33·65052c5·6cf0f02) · web 3(7d3e77b·f4f4621·89747aa) · app 다수(~962f7bd). `.nopush` push-gate 훅이 팝업 띄우면 사용자 최종 클릭 필요. 배포 = service-facing 프로젝트 `railway up` 수동 (백엔드·admin 웹 각각).
- [ ] 잔존 갭 후속: 폰 수업 수정 PATCH · 수업등록 템플릿 선행 비대칭(PC 필수 vs 폰 불요) · 시즌 윈도우 연도 무구분 · CF_QUARTERFINAL require_engine 미반영 · G22 is_pr 직렬화 · 계약서 응답 키 2벌 · 락커 no/locker_no.
- [ ] 명단 시트 스크롤 골든 1장(수업 취소 버튼 폴드 아래) · 코치 셸 2탭 골든.

## 결정사항 / 주의

1. **계정은 3개뿐** — coach/1234·member/1234·admin/1234. boss_seongsu 같은 옛 데모 이름 사용 금지. 시드가 부팅 시 APP_TEST_ADMIN_ID(슈퍼씨드)를 재생성할 수 있음(글로벌 의무 시드 — 재등장 시 사용자에게 보고).
2. **admin_login rate limit 5회/5분(429)** — 검증 스크립트에서 로그인 남발 금지. 429 는 HTML 이라 프록시 가드 필요했음(픽스됨).
3. **playwright 로 PC 모달 버튼 클릭이 헛도는 상성 문제** — 콘솔 에러 0·JS 직접 호출은 정상. 점검 자동화 시 `page.evaluate` 로 핸들러 직접 호출 우회가 빠름 (openSlotModal 등). submitT 류는 `{preventDefault(){}}` 가짜 이벤트 필요.
4. **검증 서버 재기동법**: 백엔드 `HYPHEN_DB=<경로> python -c "import app as m; m.app.run(host='0.0.0.0', port=5060, threaded=True)"` (로컬 .env 의 PORT override 우회용 런처), admin 웹 `HYPHEN_BACKEND_URL=http://127.0.0.1:5060` + 동일 런처 :8081. 이 세션의 백그라운드 서버들은 세션 종료와 함께 죽음.
5. 이 repo `dart format` 금지 · 골든 재생성은 변경 장만 · 시각은 appClock 만.
6. SSOT 문서 방침: 조사 본문은 스냅샷 유지, 갭대장 "처리 이력" 블록과 대차대조표 부록만 갱신.
7. 테스트 기준선: 백엔드 **105 passed 1 skipped** · 앱 **147 전건**.

## 관련 파일

| 경로 | 역할 |
|---|---|
| `services/facing/docs/SSOT/` (대차대조표 부록2·갭대장 7~8차·INDEX) | 전수조사·픽스 기록 정본 |
| `services/facing/api/{classes,admin,payments_admin,notifications/*}.py` | 1차 갭 픽스 |
| `services/facing/{seeds/seed_achievements.py, services/achievement_checker.py}` | G19·G20 |
| `apps/facing-app/lib/features/boss/class_compose_sheet.dart` | G24 수업 등록 시트 |
| `apps/facing-app/lib/features/shell/coach_shell.dart` | 2탭 v3.3 |
| `web/facing-admin/{app.py, templates/members*.html, notifications.html}` | 429 가드·login_id·토글 정리 |
| 스크래치패드 `e2e_verify.py`·`clean_accounts.py` | 왕복 검증·계정 정리 스크립트 |

## 다음 세션 권장 첫 프롬프트

`/resume` — 인계장 반영 후 제1 과업(원문 인용부)을 전권 승인 상태로 즉시 착수.
