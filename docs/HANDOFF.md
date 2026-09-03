# HANDOFF - 2026-09-03 14:36

> 주제: **스토어 심사 제출 준비** — 필요 항목 점검·어긋난 4건 수정 · 심사 계정 개명(testcoach1/testmember1/testmember2) ·
> 콘솔 입력 시트 + 제출 게이트 · 에뮬 실로그인 검증. 앱 237 passed / 서버 695 passed / 골든 89장 / `store_preflight` 24 PASS.
> 서버·관리자 웹 Railway 라이브. 컨텍스트 73% 로 handoff — **사용자 마지막 지시: "2번 → 1번 → 3번 재점검 후 보고"** (아래 진행중·대기 1~3).

## 완료
- [x] **심사 항목 점검 + 4건 수정** — ① iOS CI 러너 `macos-15`→`macos-26` (ASC 가 2026-04-28 부터 Xcode 26 빌드만 수용, CI 통과)
  ② `ios/Runner/PrivacyInfo.xcprivacy` 신설·pbxproj Resources 등록 ③ 공개 방침·삭제 안내·앱 privacy_screen 에서 사라진
  '착용 칭호' 항목 삭제(최종 갱신 2026-09-03, 웹 `a7f8fc8` 배포 라이브) ④ 스크린샷 21장(구글 7·애플 6.9"/6.5" 각 7)·AAB
  `1.0.0+3025`(49.9MB) 재생성. 앱 커밋 `50a9c2d`.
- [x] **골든 가짜 수업명 'WOD Class'→SWEAT · 'Morning WOD'→AWAKE** (fork 서브에이전트) — 20 PNG 재생성, 앱 `ea0c26d`.
- [x] **심사 계정 개명·재생성 (사용자 "이름 안 헷갈리게")** — 코치 `testcoach1`(테스트코치1, 부팅 시드 env `REVIEW_COACH_ID/NAME/PASSWORD`,
  옛 행 정리 `REVIEW_RETIRE_COACH_IDS=googletest2`) · 회원 `testmember1`(테스트회원1, id 12) · 회원 `testmember2`(테스트회원2, id 13,
  **계정 삭제 검증 전용**). 둘 다 0원 '심사용 회원권' ~2027-12-31. `REVIEW_LOGIN_IDS=testcoach1,testmember1,testmember2`.
  옛 googletest1(6)·googletest2·'차감문구 검증(테스트 계정)'(11) 삭제(사용자 승인). 서버 커밋 `feat(seed)…`·`bd3f3d3`.
- [x] **에뮬(프로드 APK) 실로그인** — testmember1: 수업 탭 프로그램 펼침·'예약' 버튼·내 정보 회원권 484일 / testcoach1: 예약 현황·쪽지 탭.
- [x] **콘솔 입력 시트 = `docs/STORE-SUBMIT-SHEET.md`(입력 정본)** + 아티팩트(복사 단추·완료 체크)
  https://claude.ai/code/artifact/5a41a8ff-bd08-4be1-b612-f35feeb62387 + **게이트 `python tool/store_preflight.py` 24 PASS**.
  PLAYSTORE/APPSTORE 는 시트를 가리킴. 데이터 보안·App Privacy 답안을 피트니스 정보·구매 내역까지 넓게 신고로 확정. 앱 `bce9e6d`·`2682285`.
- [x] 2026-09 요건 재조사 반영 — API 36·12명/14일·16KB(NDK 28)·건강 앱 선언·애플 연령 등급 신체계·EU DSA 판매자 아님·Xcode 26.
- [x] 메모리 `project-dual-store-release.md` 09-03 상태 추가.

## 진행중
- [ ] **1번 — 코치 쪽지함 orphan 쪽지 4개 정리**: 환영/안내 쪽지를 API 로 보낼 때 `target_id` 에 회원 번호를 넣어 코치 쪽지함에
  "8·9·12·13" 이름의 스레드 4개가 생김 (`gym_coach_notes` id 49~52 + `gym_coach_note_recipients`). 쪽지 상대 = **회원 device_hash**
  (`sha256(SECRET_KEY + device_id)`, 회원 번호 아님). **중단 지점 = 프로드 DB 직접 수정(`railway ssh`)이 하니스 분류기에 차단**됨 —
  우회 금지(CLAUDE.md 잔여 예외). 사용자가 `services/hyphen` 에서 `railway ssh` 로 들어가 아래를 붙여넣거나, Claude 재실행 시 허용 팝업 승인.
  ```
  python3 - <<'EOF'
  import os,sqlite3
  c=sqlite3.connect(os.environ['HYPHEN_DB'])
  m={str(i):h for i,h in c.execute('select id,device_hash from gym_members where id in (8,9,12,13)')}
  for n,t in c.execute('select id,target_id from gym_coach_notes where id in (49,50,51,52)').fetchall():
      h=m.get(t)
      if h:
          c.execute('update gym_coach_notes set target_id=? where id=?',(h,n))
          c.execute('update gym_coach_note_recipients set recipient_hash=? where note_id=?',(h,n))
      else:
          c.execute('delete from gym_coach_note_recipients where note_id=?',(n,))
          c.execute('delete from gym_coach_notes where id=?',(n,))
  c.commit(); print('done')
  EOF
  ```
  정리 뒤 에뮬 코치 쪽지 탭 재캡처로 확인 (현재 에뮬은 testcoach1 로그인 상태, `-timezone Asia/Seoul`).

## 대기
- [ ] **2번 — 공지 3건이 화면에 안 뜸**: `GET /api/v1/coach/gyms/2/announcements` 는 3건인데 코치 쪽지 탭 공지 카드는 '등록된 공지 없음'.
  기간 만료(ends_at)·visible_to 필터 추정 — 미확인. 회원 홈 전광판도 같은 출처. 필요하면 코치로 새 공지 1건 게시(POST 같은 경로,
  json `title/body/priority/category/visible_to`, CSRF 헤더 `X-CSRF-Token` = 로그인 응답 `csrf_token`).
- [ ] **3번 — 콘솔 입력 준비 재점검·보고**: `python tool/store_preflight.py` 재실행 + 시트 §5 "제출 직전 10분" 대조 후 보고.
- [ ] 개발자 계정(구글·애플) 승인 상태는 사용자만 앎 — GitHub Secrets(`gh secret list`) 0건. 승인되면 APPSTORE.md §G · PLAYSTORE.md §G 런시트.
- [ ] 이전 세션 잔여: 프로드 E2E 잔여 수업 327/328(삭제 API 없음, 지난 수업이라 무해) · 서브에이전트 의심점 4건(movements=[]·load_kg=0·
  검색 날짜 created_at·상한 1000) · 시각 경과 자동 갱신 · APScheduler 미설치(프로드 스케줄러 꺼짐).

## 결정사항 / 주의
- **비밀번호는 Railway `service-facing` 변수만** — `REVIEW_COACH_PASSWORD` · `REVIEW_MEMBER_PASSWORD` · `REVIEW_MEMBER2_PASSWORD`
  (`railway variables --json` 은 `PYTHONIOENCODING=utf-8` 로 읽을 것 — 한글 값 때문에 cp949 디코드가 죽음). 공개 저장소라 문서·코드에 안 적음.
  scratchpad `review_accounts.json` 은 세션 한정.
- 심사 회원 기기 ID = `review-testmember1-device` / `review-testmember2-device` (해시 = SECRET_KEY 결합). 코치 API 쓰기는 `X-CSRF-Token` 필수.
- 시트가 입력 정본, PLAYSTORE/APPSTORE 는 근거·이력. 아티팩트는 시트 사본 — 값 바꾸면 시트 먼저.
- 데이터 보안: 코치 열람 = 같은 서비스 안 → 제3자 공유 아님 / 운동 기록 = 피트니스 정보 / 회원권 = 구매 내역 (넓게 신고).
- 서버·웹 배포 = `railway up` 수동, 변수만 바꿀 땐 `railway variables --skip-deploys` 후 `railway redeploy -y`.
- 가짜 데이터 골든은 fakes.dart 수업명 SWEAT/AWAKE/BUILD — 'WOD' 재도입 금지(`store_preflight` 가 잡음).

## 관련 파일
앱 `docs/STORE-SUBMIT-SHEET.md` · `docs/PLAYSTORE.md` · `docs/APPSTORE.md` · `tool/store_preflight.py` · `tool/gen_store_shots*.py` ·
`.github/workflows/ios.yml` · `ios/Runner/PrivacyInfo.xcprivacy` · `lib/features/mypage/privacy_screen.dart` · `test/golden/fakes.dart` /
서버 `models/base.py`(seed_gym_managers) · `api/auth_login.py`(REVIEW_LOGIN_IDS) · `api/coach_note.py`(threads·notes) · `.env.example` /
웹 `web/facing-admin/templates/legal_privacy.html` · `legal_delete_account.html`

## 다음 세션 권장 첫 프롬프트
`/resume`
