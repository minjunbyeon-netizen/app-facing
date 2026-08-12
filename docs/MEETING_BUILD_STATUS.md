# FACING 회의 빌드 현황 — 2026-05-22

> **상태**: Phase 1·1.5·2·3·4 풀빌드 완료 · sanity check 13/13 통과
> **시연 가능**: 폰 ↔ PC 사장 ↔ 백엔드 전체 흐름

---

## 한 줄 요약

> **회의에서 폰·PC 동시에 띄워서 가입 신청 → SSE 알림 → 회원 등록 → 결제 → QR 출석 → 통계 갱신까지 5분 안에 시연 가능.**

---

## 빌드 완료 항목 (Brief §9 Phase 1~4)

| Phase | 작업 | 상태 |
|---|---|---|
| 1 | 백엔드 신규 8 테이블 + 사장 로그인 + SSE | ✅ |
| 1.5 | Toss Payments stub + QR 출석 + FCM stub | ✅ |
| 2 | PC 사장 화면 (회원·락커·계약·통계·코치·시급·백업) | ✅ |
| 3 | 폰 가입 흐름 SSE 발사 (사장 PC 즉시 알림) | ✅ |
| 4 | 폰 코치 페어링 (사장 발급 코드 → device_hash) | ✅ |
| 5 | 사용성 테스트 (사장 5명·회원 5명) | 회의 후 |

---

## 시스템 헬스 (2026-05-22 21:14 검증)

```
[OK] health 200       gyms=4
[OK] 박스 검색         200
[OK] 페르소나 mine     200
[OK] 사장 로그인       200  (박지훈 사장)
[OK] 회원 리스트       200  (8명)
[OK] 통계              200  (매출 540,000원)
[OK] 코치 명단         200  (3명)
[OK] 락커              200  (34개)
[OK] 시급 정산         200  (총 4,200,000원)
[OK] QR 발급           200
[OK] 폰 QR 스캔 출석    200  (member=김도윤)
[OK] 백업 실행         200  (facing-20260522.db)
[OK] 통계 재확인       200  (오늘 출석 2명)

총 13건 · 통과 13 · 실패 0
```

회의 직전 `python services/facing/sanity_check.py` 한 번 돌려서 13/13 통과 확인.

---

## 회의 데모 흐름 (15분 권장)

### 0. 사전 (회의 시작 5분 전)
1. `cd C:/dev/services/facing && python app.py` (백엔드 5060)
2. `cd C:/dev/web/facing-admin && python app.py` (사장 PC 8081)
3. 에뮬레이터 띄우고 facing-app 설치 후 실행
4. `python sanity_check.py` 13/13 OK 확인

### 1. 폰 회원 시점 (3분)
1. 페르소나 스위처에서 **김도윤** 선택
2. NOTICE 탭 → HYPHEN 박스 정보 카드 (위치·전화·코치·수업·모토)
3. WOD 탭 → 오늘의 WOD + PAST WOD
4. 마이페이지 → Engine 66 점수

### 2. 폰 무소속 시점 (1분)
1. 페르소나 → **송예준** 선택
2. NOTICE 탭 박스 카드 없음 (무소속)
3. 자체 WOD + Engine 점수

### 3. PC 사장 시점 — 핵심 (8분)
1. `http://localhost:8081/login` → `boss_seongsu / 1234` 로그인
2. **`/stats`** — 운영 통계 (오늘 출석·이번 달 신규·매출·락커 점유율·여성 비중·SSE 실시간 로그)
3. **`/members`** — 회원 8명 + 추가/편집/탈퇴/회원권 연장
4. **`/lockers`** — 락커 34개 grid, 클릭 배정/비우기
5. **`/coaches`** — 코치 명단, "+ 코치 추가" → 페어링 코드 즉시 발급
6. **`/payroll`** — 코치 시간 입력 자동 계산 + 자동 산정 + CSV 다운로드
7. **`/checkin`** — QR 코드 (60초 갱신) + 폰 스캔 시 우측에 실시간 출석 표시
8. **`/contracts`** — 전자계약서 작성 + 서명 처리

### 4. 폰 ↔ PC 실시간 연동 데모 (3분)
1. 폰: 페르소나 스위처 → "QR 체크인" 진입 → PC `/checkin` 의 토큰 입력 → 출석
2. PC: `/stats` 의 SSE 로그에 즉시 "✓ 김도윤" 표시 + 오늘 출석 카운트 +1
3. 폰: "코치 페어링" → PC 에서 발급한 코드 입력 → 코치 권한 등록

---

## 데모용 계정

| 위치 | ID/seed | PW | 권한 |
|---|---|---|---|
| PC 사장 | `boss_seongsu` | `1234` | HYPHEN 사장 |
| 폰 (페르소나) | `persona-coach-park-2026` | — | 박지훈 코치 |
| 폰 (페르소나) | `persona-member-kim-doyun-2026` | — | 김도윤 회원 |
| 폰 (페르소나) | `persona-app-song-yejun-2026` | — | 송예준 무소속 |
| 폰 (페르소나) | `persona-member-choi-seoyun-2026` | — | 최서윤 가입대기 |

폰 데모 계정 4명은 facing-app 로그인 화면의 "DEMO ACCOUNTS" 에 노출돼서 누르면 자동 진입.

---

## 회의 직후 다음 단계

- **Phase 5**: 사용성 테스트 — 사장 5명·회원 5명 think-aloud 30분 (Brief D14)
- **실 Toss 통합**: `TOSS_SECRET` 환경변수 추가 시 자동 live 모드
- **실 FCM 통합**: `FIREBASE_CREDENTIALS` 추가 시 자동 live 모드
- **실 SMS (D22)**: NHN Cloud Toast SMS / Mailgun 통합
- **법규 검토**: 전자계약서·개인정보 보존·환불 약관 (D17·D21)

---

## 인프라

- 백엔드: `services/facing` (Flask + SQLite, 포트 5060)
- PC 사장: `web/facing-admin` (Flask + 바닐라 HTML/CSS/JS, 포트 8081)
- 폰: `apps/facing-app` (Flutter, debug APK 178MB · API_BASE_URL=10.0.2.2:5060)
- DB: `services/facing/data/facing.db` (SQLite WAL) · 일일 03:00 KST 자동 백업 30일 보존
