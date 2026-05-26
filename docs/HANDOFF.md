# HANDOFF - 2026-05-26 16:39

> 이전 인계장 (14:32) 이후 14:32 ~ 16:39 약 2 시간 작업. 회원 리스트·통계·알림 페이지 + FCM 풀 e2e.

## 완료 (이번 세션)

### 회원 리스트 (`web/facing-admin/templates/members.html`)
- [x] 탈퇴 silent fail 잡기 — toast 없으면 alert fallback, risk 필터에서 left/rejected 제외, fade-out + URL filter 유지 reload
- [x] 정렬 화살표 9 컬럼 ⇅ 항상 표시 + D-day 초기 ↑ asc 안정화
- [x] 성별·생년 정렬 키 분리
- [x] 레벨·D-day chip → plain text + 색만 (member·dashboard 양쪽)
- [x] 탈퇴 회원 D-day cell '—' + 정렬 시 9999 로 가라앉힘
- [x] 탈퇴된 회원에 '삭제' 액션 + `hardDelete` JS
- [x] **상태 6분류** — 대기·활성·일시정지(주황)·만료·탈퇴·거절. backend `is_paused` 응답 필드 추가
- [x] '비고' 헤더 + '수정/삭제' 통일 (smartDelete: approved/pending → leave+hard 자동)
- [x] '일시정지' 필터 chip, '활성' 분기에서 만료·일시정지 제외

### 사이드바 (`web/facing-admin/static/style.css`)
- [x] `.nav a` 간격 반으로 축소 (padding 6→3, min-height 32→22, line-height 1.5→1.3)
- [x] `.nav .group` 간격 2배 (padding 7→14)

### 통계 페이지 (`web/facing-admin/templates/stats.html` + `services/facing/api/admin.py`)
- [x] SSE 실시간 이벤트 패널 + status badge 삭제
- [x] 차트 5개 신규 — 매출 6개월 막대, 출석 7일 막대, 회원/락카/연령/성별 도넛 4개
- [x] backend `admin_stats` 에 `revenue_series`·`attendance_series`·`age_buckets` 추가
- [x] KPI 4 card → 1 카드 6 셀 strip 통합
- [x] 막대 차트 세로 2배 (110→220) + max값 천장 닿게 정규화 + 현재 시점 accent
- [x] 도넛 4개 2×2 격자 (100→130 SVG, 중심 숫자 22px)
- [x] `?from=&to=` 날짜 범위 캘린더 (default 이번 달 1일~오늘) + showPicker() input 어디 클릭해도 열림
- [x] `_layout.html` 전역에 `input[type=date|month]` clicker handler — 6 페이지 동시 적용

### 알림 설정 + FCM 풀 e2e
- [x] `notifications.html` 에 `announcement` 토글 추가
- [x] 가상 FCM 시드/정리 카드 (노란 dashed) — POST/DELETE `/api/v1/admin/gyms/<gid>/test-fcm/seed` + GET status
- [x] `services/facing/api/fcm.py` 에 `_test_seeded` set 분리 (실 토큰 보존)
- [x] **Flutter `lib/core/fcm_register.dart` 신규** — app launch 시 placeholder FCM 토큰 자동 register
- [x] `lib/main.dart` 에 `unawaited(FcmRegister.registerIfNeeded(api))` 호출, 24h idempotency
- [x] e2e 검증 — 에뮬 앱 → POST `/api/v1/devices/fcm-token` → DB 박지훈(에뮬앱) mid=76 row insert → 공지 ann=16 sent=2/11 (placeholder token 들 stub 로그 출현)

## 진행중

(없음 — 사용자 명시 `/handoff` 트리거)

## 대기 (다음 세션 후보)

- [ ] **firebase_messaging 패키지 진짜 통합** — pubspec.yaml + `android/app/google-services.json` 배치, `FcmRegister._obtainToken()` 한 줄을 `FirebaseMessaging.instance.getToken()` 으로 교체. 그러면 stub → live 자동 전환
- [ ] backend `FIREBASE_CREDENTIALS` 환경변수에 Firebase Admin 서비스 계정 JSON 경로 등록 (Railway 콘솔)
- [ ] 검증용 테스트 회원 정리 — `gym_members` mid=75 (에뮬테스트, hash c04cb20b/005ee8e2), mid=76 (박지훈에뮬앱, hash 64f3b345) DB row 삭제 + `_fcm_tokens` clear
- [ ] 공지 발행 직후 emul 화면에 진짜 푸시 알림 도착 — Firebase 통합 후만 가능
- [ ] Phase 0-1 APK 실기 install (이전 세션부터 대기 — 메모리 `project-pending-phone-apk-install`)

## 결정사항 / 주의

- **배포 금지** 룰 유지 — git push·Railway·gh PR 일체 X. commit 만 누적
- **검증 시드 회원 잔존 (gym 2)**:
  - mid=47 E2E Test Member (status=approved · 옛날 시드)
  - mid=75 에뮬 테스트 (status=approved · device_id="emulator-self-signup-test-2026-05-26" · hash 005ee8e2...)
  - mid=76 박지훈(에뮬앱) (status=approved · device_id="persona-coach-park-2026" · hash 64f3b345...)
- **공지 ann 16건 누적**: 검증 사이클에서 만든 `Push wiring test`/`re-verify`/`Seed test push`/`[UI 검증]`/`[EMUL E2E]` v1·v2·v3·`폰에 도착하나요` 등. 운영 데이터 아님 — 다음 cleanup 사이클에 삭제 가능
- **SECRET_KEY salt 주의**: `models.profile.hash_device_id` 가 `.env` 의 SECRET_KEY 사용. 직접 DB 조작 스크립트는 반드시 dotenv 로드 먼저 — 안 그러면 default salt 로 잘못된 hash 들어감 (오늘 1회 hash mismatch 사고)
- **Flask debug reload 불안정**: 백엔드 코드 변경 후 자동 reload 가 가끔 fail. 검증 시 새 응답 필드 안 보이면 `Get-NetTCPConnection -LocalPort 5060` PID kill → `python app.py` 수동 재시작
- **8081 admin web 좀비 PID 잔재**: Windows TCP table 잔재라 무시 OK. 실제 listener 1개로 정상 동작
- **3 레포 모두 `overnight/2026-05-25` 브랜치** — 다음 세션 master 머지 또는 같은 브랜치 이어가기 결정 필요
- **검증 통과 카운트** — pytest 8 (locker 4 + announcement 4) · flutter analyze 0 · admin 6+ 페이지 console 0

## 다음 세션 권장 첫 프롬프트

`/resume`
