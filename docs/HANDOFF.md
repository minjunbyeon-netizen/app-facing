# HANDOFF - 2026-08-26 13:15

## 완료 (이 세션 — 12:27~13:15)
- [x] 인계장(12:25) 대기 1~4 전부: **S5 회원권 게이트 · S8 문구 117줄 · S10 코치 UX** → 서버 237 passed · 앱 197 · 골든 57 · `railway up`(12:44 부팅) · 갤S22 릴리즈 설치 · 에뮬 3차 주행 8장 · 보고서 같은 URL 재발행
  (https://claude.ai/code/artifact/02ec5800-def2-4903-b286-34622bbae768 · 빌더 `C:\dev\project\hyphen-journey-2026-08-26\build_report_v3.py`, after2/). 브리프 D53 · 갭대장 19차 · 이름사전 +2.
  S5 기준일 = **수업 시작일(KST)** ('오늘' 아님 — D53 에 이유). 앱 `Membership.coversDay`·`GymState.hasMembershipOn` → '회원권 필요' 배지.
- [x] 사용자 지시(12:59) **S6 가입 폼 BACK 확인 · S7 서버 시각 KST 고정 파싱(`core/time_format.dart parseServerTime`) · S9 = HYPHEN 전용 앱 결정(코드 미변경, 주석·D54·갭대장 20차)** → 앱 198 · 골든 58 · 갤S22 설치. 서버 변경 없음.
  커밋: 앱 2c338cd·489146c · 서버 c26b4ee·6a1835e · dev-root 3f698a0.

## 진행중
- [ ] 없음 — 아래 대기 1 착수 전 인계 (컨텍스트 88%).

## 대기 (사용자 결정 2026-08-26 13:12 "다른곳처럼 (표준대로) 우리도 저렇게 할까?" → 예, 표준 채택. 새 세션에서 집행)
1. [ ] **시간대 표준화 (저장·전송 = 오프셋 포함 순간 · 표시만 시간대 변환 · '하루' 규칙 = 체육관 시간대)** — 규모 실측: 서버 `.isoformat()` 179줄/16파일, `datetime.now(KST)` 107곳, models DateTime 컬럼 17개(전부 `timezone=True`), `String(10)` 날짜 컬럼 16개(YYYY-MM-DD — 그대로 둠, 날짜는 시간대 무관).
   순서 (각 단계마다 pytest tests/ + 앱 flutter test + 골든 회귀):
   - **1단계 서버 직렬화 한 곳** — `api/_time.py`(신설) `iso(dt)` = `_as_kst(dt).isoformat()` (naive → KST aware 붙여서, aware 는 KST 변환) 로 179줄 전부 치환. SQLite·Postgres 가 같은 문자열(`+09:00`)을 내려주게. `classes._as_kst` 는 이 모듈로 이동(§0-B rename grep).
   - **2단계 앱 파서 통일** — `parseServerTime` 을 공지·쪽지·기록·출석 등 남은 `DateTime.parse/tryParse` 전부에 적용 (1단계 뒤엔 오프셋이 항상 있어 무해). 골든 무변화 기대.
   - **3단계 테스트 시계** — `tests/*.py` 의 naive `datetime.now()` → `datetime.now(KST)`; `_today_class_or_skip` 자정 skip 제거 가능.
   - **4단계 체육관 시간대 자리** — `gyms.timezone` String(40) default 'Asia/Seoul' 컬럼 + `_migrate` ADD COLUMN, 서버 '하루' 계산(`_daily_limit_blocked`·`_membership_blocked`·`_kst_today`·출석 통계)이 `KST` 상수 대신 `gym.timezone` 을 읽게. PC 설정 화면은 보류(HYPHEN 1곳 — 값 고정). 브리프 D55 · 이름사전 행 · 갭대장 21차.
   - 5단계 배포 `railway up` + 프로드 /health + 에뮬 **UTC 시계**(`adb shell cmd alarm set-timezone UTC`)로 수업 탭 재주행 → 보고서 after3/ 재발행.
2. [ ] S11 검증환경 — 보고만 유지 (에뮬 절차 메모로 충분).

## 보고만 (지시 없음)
- 자기 반박 미해결: S6 확인은 텍스트칸 8개 기준(칩만 고르면 안 물음) · S7 에뮬 UTC 재현 검증 안 함 · 코치 로그아웃 device 리셋으로 `gym_manager_devices` 행 누적 · 쪽지 발신자 개별 코치명 불가(발신 스태프 컬럼 없음).

## 에뮬 재주행 절차 (검증된 순서 — 8/26 12:47 실측 보강)
1. `services/hyphen`: `PORT=5060 python app.py > _run.out 2> _run.err &` (좀비 `netstat -ano | grep :5060`). **pytest 는 반드시 `python -m pytest tests/`** (인자 없이 돌리면 수집 단계 캡처 오류 — 코드 결함 아님).
2. 앱: **반드시 앱 루트에서** `flutter build apk --debug` (cd 한 셸에서 nohup 하면 "No pubspec" 로 조용히 실패) → `adb -s emulator-5554 uninstall com.netizen.hyphen.hyphen_app` → install. **에뮬 저장공간 535MB 이하면 `INSTALL_FAILED_INSUFFICIENT_STORAGE`** → `pm trim-caches 4G` + `pm clear com.android.chrome` + `/sdcard/*.png` 삭제로 745MB 확보 후 성공. 시계 `adb shell cmd alarm set-timezone Asia/Seoul`. 런치는 `am start -n com.netizen.hyphen.hyphen_app/.MainActivity` (monkey 는 크롬이 앞에 있으면 안 뜸).
3. 로컬 DB: gym 1 'HYPHEN' · member/1234(id1, **회원권 8/19~11/17 있음**) · member2/1234(id2, device 'emu-member2-device', **회원권 없음** — S5 검증용) · member3·4 pending · admin/1234(boss 'Demo Admin') · 수업 55(8/26 20:00, member 확정)·56(11:30, 1·2 출석)·8(8/28 06:00 — 이 세션 curl 로 member 예약 id4 생성).
4. 좌표(1080×2400): 진입 로그인 (540,765) · 아이디칸 (540,648) · 비번칸 (540,852) · 로그인 버튼 (540,1198) · 코치 로그아웃 아이콘 (995,130) · 코치 다이얼로그 '로그아웃' (778,1351) · 회원 내 정보 탭 (900,2250) · 회원 로그아웃 버튼 (928,656) · 회원 다이얼로그 '로그아웃' (846,1400) · 알림 권한 Allow (540,1303).
5. 요청 확인 `_run.err` grep.

## 결정사항 / 주의
- 프로드 접촉: /health GET · `railway up` 만. 프로드 gym 2 실데이터 오염 금지 유지.
- 로컬 서버 종료됨(리스너 0). 에뮬레이터 켜 둠(디버그 APK 설치 상태, member 로그인 상태). 갤S22 릴리즈 APK(489146c, prod URL) 설치됨.
- 제1원칙(기능 추가 금지·갭은 보고) 유지 — 시간대 표준화는 사용자 결정으로 예외 승인.
- S9: 이 앱은 HYPHEN 체육관 1곳 전용 (사용자 13:00). 다른 체육관은 추후 선택 UI 를 숨긴 채 살리는 방향.

## 다음 세션 권장 첫 프롬프트
`/resume` → 대기 1 을 1단계부터 (지시 완료 — 추가 확인 불필요)
