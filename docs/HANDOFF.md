# HANDOFF - 2026-08-24 20:25

## 완료 (이 세션)
- [x] **관리자 웹 "예약 설정" 페이지 신설** — 하루 예약 한도 PC 편집 (편도-폰 해소).
  `web/facing-admin/templates/settings_reservations.html` + `/settings/reservations` 라우트 +
  사이드바 메뉴. 폰 코치 '예약' 탭과 같은 class-settings API 소비 (값 1곳). 실검증 완료
  (저장 왕복 + 에뮬 회원 앱 한도 집행 "하루 예약 한도(1회) 초과" 스낵바 실증 후 데이터 원복)
- [x] **케어 필요·만료 임박 사용자 재정의** — 케어 = 3일 연속 수업 예약 없음 ·
  만료 임박 = 결제 예정일(회원권 종료) 5일 이내. 판정 정본 = 서버 `api/admin.py`
  `CARE_NO_RESERVATION_DAYS(3)`/`EXPIRING_SOON_DAYS(5)` + members 응답
  `needs_care`/`last_class_date`/`is_expiring_soon` (PC 는 소비만).
  케어 페이지 2섹션 + members 칩 2종(risk→care rename, 만료 임박 신설) + 대시보드·통계
  라벨 5일 + dday 배지·행 강조 재배선. 신규 테스트 `tests/test_care_flags.py` 8건
- [x] **KST 보정** — admin.py `date.today()` 전량(24건, Date/_date alias 포함) `_kst_today()` 교체
  (Railway UTC 저녁 하루 밀림 해소)
- [x] **이원화 점검 (사용자 지시)** — 잔존 3건 수정: 대시보드 만료 카드 "7일 이내" 라벨 →
  "결제 예정일 5일 이내" · `dday-7`→`dday-far` rename · members `.dday-warning` 고아 삭제.
  인라인 style 0 · 독자 구성 0 확인
- [x] **락커 만료 임박 창 5일 통일 (사용자 지시)** — 구 14일 → EXPIRING_SOON_DAYS.
  창 4종(케어7·대시7·통계14·락커14) 전부 5일 하나로
- [x] **rename 3건 (§0-B grep 동기 완료)** — `expiring_in_14d`→`expiring_soon_count` ·
  members 칩 filter `risk`→`care` · `dday-7`→`dday-far`. 이름사전 등재 완료
- [x] **테스트·push** — 서버 190 passed 1 skipped (신규 8 포함) · 앱 189 전건(골든 58 불변).
  서버 push 완료(0ff5220) · 관리자 웹 push 완료(9f24d03). 앱 repo 는 코드 변경 0

## 진행중 (다음 세션 첫 작업)
- [ ] **railway up 2건 — 사용자 `!` 실행 대기** (배포 승인은 이미 받음, Claude 실행만 권한 차단)
  - `! cd C:\dev\services\hyphen; railway up --detach`
  - `! cd C:\dev\web\facing-admin; railway up --detach`
  - railway CLI 인증 살아 있음 (`railway whoami` = Byeon Ad) — **login 불필요**
  - 완료 후: 프로드 `/health` + 관리자 웹 대시보드 "만료 임박 5일" 확인

## 대기
- [ ] 릴리즈 APK 갤S22 실기기 설치 (2세션째 이월) — `build/app/outputs/flutter-apk/app-release.apk`
  (64.5MB, 프로드 URL, v3.19). 폰 무선 디버깅 IP:포트 필요 → `/연결` → `adb install -r`
- [ ] (선택) 실체육관(gym 2) 하루 예약 한도 실설정 — 배포 후 프로드 관리자 웹에서 가능
- [ ] (선택) 알림톡 "만료 7·3·당일" 발송 스케줄 — 만료 임박과 별개 개념으로 유지 결정 (통일 안 함)

## 결정사항 / 주의
- 케어 판정: confirmed·attended 만 집계 (취소·노쇼 제외), 미래 예약 있으면 케어 아님,
  대상 = 활성 회원만 (만료·일시정지·탈퇴·거절 제외). 신규 가입 직후 회원은 이력 없음 → 바로 케어 잡힘 (알려진 특성)
- 만료 임박 = 결제 예정일 개념은 회원권 `end_date` 로 매핑 (별도 결제일 컬럼 없음)
- pytest 는 반드시 `python -m pytest tests` — bare `pytest` 는 `_archive/engine-retired` 수집 에러 7건 (함정)
- 로컬 백엔드(:5060)·관리자 웹(:8081) bg 실행 중이었음 — 새 세션에선 재기동 필요.
  ⚠ 아침 세션 유령 백엔드가 5060 이중 LISTEN 하던 것 정리함 — 백엔드 코드 반영 안 될 때 netstat 확인
- 앱(facing-app) 이번 세션 코드 변경 0 — 로컬 커밋 1개(인계장 archive)만 있고 push 안 함 (배포 금지 룰)
- 에뮬 Medium_Phone_API_36.1 은 `-timezone Asia/Seoul` 로 기동할 것 (주간 보드 종료 판정)

## 다음 세션 권장 첫 프롬프트
`/resume` → railway up 2건 실행 확인 → 프로드 검증 → 폰 실기기 설치
