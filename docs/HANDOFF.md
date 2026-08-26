# HANDOFF - 2026-08-26 16:05

## 완료 (이 세션 — 13:21~16:05)
- [x] 인계장(13:15) 대기 1 **시간대 표준화 5단계 전부** (브리프 D55 · 갭대장 21차 · 이름사전 도메인 14):
  1단계 서버 `api/_time.py` 한 곳 — 응답 datetime `.isoformat()` 94줄 + 날짜 유도 8곳 → `iso()`/`kst_date()` (+09:00 고정), 클라이언트 입력 6경로 `parse_client_time`, `date.today()` 9곳 → `kst_today()`, KST 헬퍼 7종 통합(rename grep 0). 서버 커밋 3d53844.
  2단계 앱 — `DateTime.parse/tryParse` 26곳 → `parseServerTime(...).toLocal()`, from/to 전송 `toUtc()`(Z). 골든 58 무변화. 앱 커밋 e18947c.
  3단계 tests naive `datetime.now()` 17곳 → KST (b001b14). 4단계 `gyms.timezone` 컬럼 + `_migrate_gym_timezone_column` + `gym_tz/gym_today/gym_date/day_bounds_wall`, admin `_gym_today()` 23곳 (7937116).
  5단계 `railway up`(13:38 부팅) · 에뮬 **UTC 시계** 재주행(11:30 KST→'02:30 종료', 20:00 KST→'11:00 예약됨') · 보고서 4차 같은 URL 재발행
  (https://claude.ai/code/artifact/02ec5800-def2-4903-b286-34622bbae768 · 빌더 `C:\dev\project\hyphen-journey-2026-08-26\build_report_v4.py`, after3/).
- [x] **D56 사용자 지시 14:04 "전부 한국이야, 확실히 못박아놔"** — `tz_of` 항상 KST(+경고 로그) · `test_tz_of_is_always_kst_korea_only` · **3면 CLAUDE.md 대전제 4번** + 브리프 §2-0 행 4 · 갭대장 22차(func.date 13곳 = 갭 아님 종결) · 이름사전 행 · 메모리. 서버 d9f14ae · 앱 86ab320 · web 4257a03 · `railway up` 재배포(14:07 부팅).
- [x] 갤S22 릴리즈 APK(prod URL) 재빌드·설치 16:03 (무선 adb 192.168.1.101:5555, `/연결` 스크립트). 폰 잠금이라 화면 미확인.
- 회귀 최종: 서버 247 passed · 1 skipped · 앱 198 · 골든 58.

## 진행중
- [ ] 없음.

## 대기
- [ ] 갤S22 잠금 해제 후 수업 탭 육안 확인 (사용자 몫 — 이상 시 보고).
- [ ] S11 검증환경 — 보고만 유지.

## 보고만 (지시 없음)
- 1단계 커밋 메시지 "117줄" 은 실제 102줄(94+8) — 브리프·갭대장엔 정확 수치.
- 보고서 4차 PENDING 에 "TZ-잔여" 가 남아 있음 (D56 이전 발행) — 다음 재발행 때 제거.
- 프로드 응답 `+09:00` 은 부팅 로그·/health 로만 확인 (실계정 조회 안 함 — 실데이터 접촉 금지).

## 에뮬 재주행 절차 (검증된 순서 — 8/26 13:39 실측 보강)
1. `services/hyphen`: `PORT=5060 python app.py > _run.out 2> _run.err &` · pytest 는 **`python -m pytest tests/`**.
2. 앱: **앱 루트에서** `flutter build apk --debug` → `adb -s emulator-5554 uninstall com.netizen.hyphen.hyphen_app` → install. **재설치 첫 실행은 알림 권한 다이얼로그가 로그인보다 먼저** — Allow (540,1303) 를 먼저 탭한 뒤 진입 로그인 (540,765). 시계: `adb shell cmd alarm set-timezone UTC|Asia/Seoul`, 확인 `adb shell date`. 런치 `am start -n com.netizen.hyphen.hyphen_app/.MainActivity`.
3. 로컬 DB: gym 1 'HYPHEN'(timezone Asia/Seoul) · member/1234(회원권 8/19~11/17) · member2/1234(회원권 없음) · admin/1234 · 수업 55(8/26 20:00)·56(11:30)·8(8/28 06:00).
4. 좌표(1080×2400): 아이디칸 (540,648) · 비번칸 (540,852) · 로그인 버튼 (540,1198) · 코치 로그아웃 (995,130)/(778,1351) · 회원 내 정보 탭 (900,2250) · 회원 로그아웃 (928,656)/(846,1400).
5. bash 에서 `cd` 는 한 명령 안에서 유지됨 — 앱 명령 앞에 `cd /c/dev/apps/facing-app` 명시 (이 세션에서 3번 헛발).

## 결정사항 / 주의
- **D56 전 체육관 = 한국, KST 하나** — 다른 시간대 대비 작업(func.date 범위 전환·시간대 설정 화면) 제안 금지. 3면 대전제 4번.
- 시간대 규약: 서버 순간값은 `iso()`만, 앱 파서는 `parseServerTime(...).toLocal()`만, 날짜(YYYY-MM-DD)는 그대로.
- 프로드 접촉: /health · railway logs · `railway up` 만. gym 2 실데이터 오염 금지.
- 로컬 서버 종료됨. 에뮬레이터 켜 둠(디버그 APK, member 로그인, 시계 Asia/Seoul 복원). 갤S22 릴리즈 APK 설치됨(86ab320 + prod).

## 다음 세션 권장 첫 프롬프트
`/resume`
