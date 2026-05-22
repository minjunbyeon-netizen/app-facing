# HANDOFF - 2026-05-22 21:50

## 완료

### 아키텍처 합의 (브리프 SSOT)
- [x] `docs/ARCHITECTURE_BRIEF.md` 작성 — facing 시스템 전체 SSOT (RBAC 3역할·SSE·DB 모델·통계·게이미피케이션 정책·인증·빌드 우선순위·결정사항 D1~D24)
- [x] 3 레포 `CLAUDE.md` 최상단에 "브리프 최우선" 명령 추가 (apps/facing-app · services/facing · web/facing-admin)
- [x] §0.5 인프라 카탈로그 (포트·DB·환경·시드·자주 헷갈리는 점 6건)
- [x] §12 study refs (subscription-fitness · pricing · ux-testing · payment · webhook · security)
- [x] §13 API 엔드포인트 카탈로그 (기존 14 + 신규 22)
- [x] §14 코치 관리 페이지 신설 — 가장 큰 빈약점 보강

### Phase 1 — 백엔드 신규 8 테이블 + 사장 인증
- [x] 모델 8개: `gym_manager`·`gym_member_profile`·`gym_membership`·`gym_locker`·`gym_attendance`·`gym_contract`·`gym_inquiry`·`audit_log`
- [x] `migrate_db()` 자동 import + create_all + `gym_members.status` enum 마이그레이션 (`+ left + removed`, sqlite_master 직접 편집)
- [x] `seed_gym_managers()` — `boss_seongsu / 1234` + `coach_park / 1234` 시드 (bcrypt cost 12)
- [x] `seed_admin_demo_data()` — 락커 34개 + 회원 5명 프로필+회원권 시드
- [x] `api/admin.py` — 사장 로그인·로그아웃·me·회원 CRUD·회원권 발급/연장·탈퇴·통계

### Phase 1.5 — 결제·체크인·푸시
- [x] `api/payments.py` — Toss Payments stub (TOSS_SECRET 미설정 시 즉시 결제 처리)
- [x] `api/checkin.py` — QR 1회용 토큰 (60초 만료) + 폰 스캔 endpoint + SSE 발행
- [x] `api/fcm.py` — FCM 토큰 등록 + `send_push()` 내부 함수 (stub)
- [x] APScheduler `backup.py` — 매일 03:00 KST `facing.db` 백업 + 30일 보존

### Phase 2 — PC 사장 화면 (`web/facing-admin` v0.3)
- [x] 사장 ID/PW 로그인 + 세션 쿠키 propagation
- [x] `/stats` — SSE 실시간 이벤트 표시
- [x] `/members` — 회원 CRUD + 회원권 연장 + 탈퇴
- [x] `/coaches` — 코치 명단 + 추가 + 페어링 코드 발급 + 퇴사
- [x] `/payroll` — 시급 정산 + 자동 산정 + CSV export
- [x] `/lockers` — 락커 grid 34개 + 클릭 배정/비우기
- [x] `/checkin` — QR 60초 갱신 + 실시간 출석 로그
- [x] `/contracts` — 전자계약서 작성 + 사장 서명 처리
- [x] `mock_*.json` 폐기 — 모두 백엔드 `facing.db` 호출

### Phase 3 — SSE 채널
- [x] `GET /api/v1/admin/events` — gym_id별 pub/sub
- [x] 이벤트: `member_join_request` · `member_approved` · `attendance_checked` · `payment_received`
- [x] 폰 가입 신청 → 사장 PC 즉시 알림

### Phase 4 — 폰 코치 페어링
- [x] `POST /api/v1/coach/pair` — 페어링 코드 → device_hash (1회용)
- [x] `coach_pair_screen.dart` + `qr_input_screen.dart` 신규 화면
- [x] 페르소나 스위처 진입 버튼 + debug APK 재빌드 + 에뮬레이터 재설치

### QA / 자동 검증
- [x] `sanity_check.py` — 13/13 OK
- [x] `usability_test.py` — Phase 5 시뮬 14/14 OK
- [x] `member_sync_check.py` — 회원 CRUD + 매핑 10/10 OK
- [x] `GET /api/v1/health` endpoint
- [x] 회의 리허설 캡처 9장

### 문서
- [x] `docs/ARCHITECTURE_BRIEF.md` — 시스템 SSOT
- [x] `docs/MEETING_BUILD_STATUS.md` — 회의 데모 흐름 + 빌드 현황
- [x] `docs/MEETING_DEMO_2026-05-22.md` — 페르소나 4명 시나리오

## 진행중
- 없음

## 대기 / 다음 분기

### 회의 후
- [ ] 회의 피드백 수렴
- [ ] Phase 5: 실 사용성 테스트 — 사장 5명·회원 5명 think-aloud
- [ ] 발견 이슈 hotfix

### 실 서비스 통합 (env 1줄씩)
- [ ] `TOSS_SECRET` → Toss live
- [ ] `FIREBASE_CREDENTIALS` → FCM live
- [ ] NHN Cloud Toast SMS + Mailgun 통합
- [ ] Railway / Vercel 배포 (사용자 명시 승인 후)

### 기능 추가 후보
- [ ] PC 사장 회원 추가 시 페어링 코드 발급 (회원도 device_hash 매핑)
- [ ] 폰 카메라 QR 스캐너 (mobile_scanner 패키지)
- [ ] 사장 다중 박스 (D18) UI
- [ ] 코치 다중 박스 (D19) UI
- [ ] `gym_inquiries` UI 구현

## 결정사항 / 주의

### 인프라
- 백엔드 `http://localhost:5060` (debug Werkzeug)
- PC 사장 `http://localhost:8081` (5060/5061 Chrome 차단)
- 폰 debug APK 178MB (페르소나 스위처 필수 → debug 빌드)
- DB `services/facing/data/facing.db` (SQLite WAL, git 미추적, 일일 03:00 KST 백업)

### 자주 막힌 패턴
- 백엔드 다중 인스턴스 충돌 → `taskkill //F //PID` 후 fresh start
- SQLite CHECK 변경 → sqlite_master 직접 편집 + 백엔드 재기동
- Windows bash + curl 한글 payload 깨짐 → 영문 검증
- `adb install INSUFFICIENT_STORAGE` → uninstall 후 재설치

### 회의 데모 흐름 (15분)
1. 폰 김도윤 NOTICE 박스 카드
2. 폰 송예준 무소속 자체 WOD
3. PC 박지훈 로그인 → stats
4. SSE: 폰 가입 신청 → PC 알림
5. PC: 회원 등록 + 회원권 (stub 결제 자동)
6. PC `/checkin` QR → 폰 체크인 → 실시간 출석
7. PC `/coaches` 새 코치 추가 → 페어링 → 폰 권한
8. PC `/payroll` 자동 산정 + CSV
9. PC `/lockers` `/contracts`

### 데모 계정
- PC 사장: `boss_seongsu / 1234`
- 폰: DEMO ACCOUNTS 4명 (박지훈/김도윤/송예준/최서윤)

## 파일 경로 (주요 신규)

| 역할 | 경로 |
|---|---|
| 시스템 SSOT | `apps/facing-app/docs/ARCHITECTURE_BRIEF.md` |
| 회의 빌드 현황 | `apps/facing-app/docs/MEETING_BUILD_STATUS.md` |
| 회의 플레이북 | `apps/facing-app/docs/MEETING_DEMO_2026-05-22.md` |
| 백엔드 admin | `services/facing/api/admin.py` |
| 백엔드 체크인/결제/FCM | `services/facing/api/{checkin,payments,fcm}.py` |
| 백엔드 백업 | `services/facing/backup.py` |
| 신규 모델 9개 | `services/facing/models/gym_*.py` + `audit_log.py` |
| QA 검증 | `services/facing/{sanity_check,usability_test,member_sync_check}.py` |
| PC 사장 웹 | `web/facing-admin/` (Flask + 8081) |
| 폰 페어링/QR | `apps/facing-app/lib/features/_debug/{coach_pair,qr_input}_screen.dart` |
| 폰 데모 계정 | `apps/facing-app/lib/features/auth/demo_accounts.dart` (4명, deviceIdSeed) |

## 다음 세션 권장 첫 프롬프트
`/resume`
