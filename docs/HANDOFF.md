# HANDOFF - 2026-08-24 14:47

## 완료 (이 세션)
- [x] **회원 예약 규칙 조사** — 하루 횟수 제한 없음(수업 단위 정원만) 확인 후 사용자 지시로 기능화
- [x] **예약 정책 2종 구현 (브리프 D41)** — 서버+앱+골든+SSOT 문서 동기화
  - 종료 수업 차단: 예약·회원 취소 `CLASS_ENDED` 409, 컷오프 = 시작+duration (지각 예약 허용 설계)
  - 하루 예약 한도: `gym_class_settings.daily_reservation_limit` (0=무제한 기본, 1~10)
    + GET/PATCH `/api/v1/admin/gyms/<gid>/class-settings` + 앱 코치 설정 '예약' 탭(5번째, 스크롤 탭바)
  - 집행 = `api/classes.py _daily_limit_blocked` 한 곳 (신규·재활성·대기 신청 + 승격 재검사 skip)
- [x] **G29·G30 수정 (갭대장 14차 종결)** — 재활성 정원 우회 봉쇄(만석 시 waitlist 로) +
  중복 대기 `ALREADY_WAITLISTED` + 대기 이탈 `DELETE /member/classes/<id>/waitlist` +
  앱 cancelClassFlow 대기 분기('대기를 취소할까요?') — 무동작이던 대기 취소 버튼 소생
- [x] **[별건 회귀 수정] 빈 DB 첫 부팅 migrate_db 전멸** — `models/base.py _migrate_class_tables`
  BEGIN 앞 `conn.commit()` (8/23 선행 마이그레이션 미커밋 UPDATE 와 driver BEGIN 충돌.
  기존 DB 무영향, 서버 pytest 전체가 이걸로 죽어 있었음)
- [x] **테스트** — 서버 182 passed 1 skipped · 앱 189 전건 · 골든 58장 (state_07 종료 카드 ·
  boss_08 설정 예약 탭 · state_08 대기 취소 다이얼로그 신규)
- [x] **에뮬 실기 왕복** — 종료 수업 예약 → "이미 종료된 수업입니다." / 한도 2 에서 3건째 →
  "하루 예약 한도(2회)를 초과했습니다." 스낵바 실증. 검증 데이터 정리 완료(수업 4개 삭제·한도 0 복원)
- [x] **배포 (사용자 "전부다해" 승인)** — 서버 push(5be0eef)+`railway up` 성공, 앱 push(e752545).
  프로드 `/health` ok + 신규 class-settings 라우트 401 응답으로 신 코드 확인
- [x] **릴리즈 APK 재빌드** — `build/app/outputs/flutter-apk/app-release.apk` (64.5MB, 프로드 URL 주입, v3.19 포함)

## 진행중 (다음 세션 첫 작업)
- [ ] **릴리즈 APK 실기기(갤S22) 설치** — 지난 세션부터 이월. 중단 지점 = 폰 무선 디버깅 연결 불가
  - 사용자에게 IP:포트 요청 (설정 > 개발자 옵션 > 무선 디버깅) → `/연결 <IP:포트>` →
    `adb -s <addr> install -r build/app/outputs/flutter-apk/app-release.apk`
  - INSUFFICIENT_STORAGE 시 uninstall 후 install (applicationId `com.netizen.hyphen.hyphen_app`, 재로그인 필요)

## 대기
- [ ] (선택) 코치가 실체육관(gym 2)에 하루 한도 실설정 — 기본 0(무제한)이라 켜기 전까지 프로드 동작 변화 없음
- [ ] (선택) 대기열 승격 skip 회원 알림 — 침묵 대기 UX (D41 자기반박 잔존)
- [ ] (선택) PC 관리자 웹(facing-admin)에 예약 정책 설정 화면 — 현재 폰 코치 설정만 (편도-폰)

## 결정사항 / 주의
- 종료 컷오프 = 종료 시각 (주간 보드 isOver 는 시작 시각 기준으로 더 엄격 — 의도적 이원, 이름사전 등재)
- 하루 한도 카운트 = confirmed+attended, 수업 시작일(KST) 기준. 대기 등록은 카운트 제외 (승격 재검사가 봉쇄)
- 에뮬 상태: Medium_Phone_API_36.1 을 `-timezone Asia/Seoul` 로 재기동함 (기본 GMT — KST 아니면
  주간 보드 종료 판정이 어긋남). v3.19 디버그 빌드 설치·member 로그인 상태
- 로컬 백엔드(:5060) 백그라운드 실행 중이었음 (bash task) — 새 세션에선 재기동 필요
- 실체육관(gym 2) 프로드 오염 금지 — 이 세션 쓰기는 전부 로컬 demo(gym 1), 정리 완료
- 서버 원격명 service-hyphen 으로 개명 확인됨 (구 service-facing URL 은 그대로)

## 다음 세션 권장 첫 프롬프트
`/resume` → 폰 무선 디버깅 IP:포트 확보 후 릴리즈 APK 실기기 설치부터
