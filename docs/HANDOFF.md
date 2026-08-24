# HANDOFF - 2026-08-25 04:30

## 완료 (이 세션)
- [x] **포인트 이원화 정리 (사용자 결정: 1+2안 + WOD 100P 삭제)** — 4중 지급 경로를 2경로로
  - 현황 실측: A PointRule(수동 기준표) · B RewardRule(자동 엔진, 정본) · C GymPointSettings(고아) · + WOD 첫 기록 100P 하드코딩
  - **C 삭제**: `api/point_settings.py`·`models/gym_point_settings.py`·앱 보스 설정 '포인트' 탭(_PointsTab) 삭제. DB 표는 존치. blank_slate KEEP 목록·패턴 인용 docstring 3건 정리
  - **A 재정립**: PC `settings_points.html` 을 수동 지급 프리셋으로 전환 — 트리거 드롭다운·결제 조건칸 폐지, 이름+금액만, 저장 전부 trigger='custom', 레거시 행은 수정 시 전환. 백엔드 point-rules API 무변경, member_detail 적립 모달 그대로
  - **WOD 100P 폐기**: 서버 `WOD_RESULT_POINTS`·적립 블록·응답 `points_awarded` 제거 + 앱 "+100P" 표기 제거 (gym_repository·wod_result_sheet·wod_session_screen)
  - 검증: 서버 194 passed · 앱 189 passed · analyze 클린 · 골든 boss_08 1장 갱신(설정 탭 5→4)
  - 배포: 서버 30faaed · 웹 755ca8a · 앱 e5624c7(auto-save) push + railway up 2건 → 신빌드 마커(point-settings 404)·/health·/login 200 확인
  - 문서: README §제거된 기능 대장 14 등재 · 메모리 project-points-consolidation 신설(wod-points-discount 폐기)
- [x] **.nopush 마커 3면 삭제** (사용자 지시 원문 실행 — 이번엔 분류기 차단 없음) + `C:\dev\CLAUDE.md` G1 행 동기화(f7ce621 push). 마커가 실은 git 추적 파일이라 3 레포에 삭제 커밋 남김
- [x] **응답 표기 교정 (사용자 강한 지시)** — 원문자·괄호숫자 기호 전면 금지, 일반 숫자 1. 2. 3. 만 (memory feedback-no-enclosed-numerals)

## 진행중
- 없음

## 대기
- [ ] **릴리즈 APK 재빌드 + 갤S22 실기기 설치 (4세션째 이월 · 이번 변경 반영 필요)** —
  `flutter build apk --release --dart-define=API_BASE_URL=https://service-facing-production.up.railway.app` → `/연결` → `adb install -r`
  ⚠ 설치된 구버전 APK 는 코치 설정 '포인트' 탭이 남아 point-settings 404 → "연결 실패" 노출 — 재빌드로 해소
- [ ] (보고만·수정 지시 대기, 지난 세션 이월) 정지 시 후속 회원권 시작일 미보정(겹침 가능) · 앱 계약 변수 라벨 raw 영문 · 회원 예약 원시 타임라인/90일+ 출석 누적 없음. (결제 1만원당 자동 계산·WOD 100P 항목은 이번 정리로 소멸)

## 결정사항 / 주의
- **포인트 정본 구조**: RewardRule 엔진(자동, PC 업적 설정) + PointRule 수동 프리셋(PC 포인트 설정) 2경로. **RewardRule 로 완전 흡수 금지** — custom 규칙이 회원 앱 도전 카드로 노출돼 내부 프리셋이 새는 부작용 (memory project-points-consolidation)
- gym_point_settings DB 표는 존치(코드만 삭제) — 재도입 시 git log 2026-08-25 이전에서 복원
- 프로드 gym_point_rules 레거시 트리거 행은 "수정 시 custom 전환" 문지방 마이그레이션 — 실데이터 건수는 미조회
- hyphen 3면 push 확인 팝업 없음(.nopush 삭제) — hyphen 은 push≠배포(railway up 수동) 그대로
- 응답에 원문자·괄호숫자 기호 금지 — 일반 숫자만
- pytest 는 반드시 `python -m pytest tests` (bare pytest = _archive 수집 에러 함정)
- 로컬 백엔드(:5060)·관리자 웹(:8081)은 이번 세션 미기동 — 필요 시 재기동, 이중 LISTEN 유령 확인 (`Get-NetTCPConnection -LocalPort 5060,8081 -State Listen`)

## 다음 세션 권장 첫 프롬프트
`/resume` → 릴리즈 APK 재빌드·갤S22 설치
