# 구현 Plan — 매그넘 레퍼런스 기능 이식

> 선행: `ANALYSIS.md`(11화면) · `MEETING-MINUTES.md`(Opus 3인 회의). 본 문서는 미확인 4건 해소 후 작성한 실행 계획.
> 전제: 상태관리 `provider`+`ChangeNotifier`, 라우팅 named route 맵(`main.dart`). Riverpod/go_router 아님.

## A. 선결 미확인 해소 결과 (코드 확정)

| # | 항목 | 확정 | 영향 |
|---|---|---|---|
| 1 | 박스 WOD 조회 | `GET /api/v1/gyms/{id}/wods` 가 `rounds_data`(파싱된 배열) 반환. 회원 피드 `/member/box-wods` 는 요약만. `daily-plans` 는 별개 모델(`DailyClassPlan`, rounds_data 없음) | WOD 상세는 `/gyms/{id}/wods` 응답을 써야 함 |
| 2 | 동작별 영상 | WOD post 안엔 영상 필드 **없음**. `MovementLibrary.video_url`(마스터)만 존재. 동작명↔라이브러리 매칭 레이어 부재 | 영상은 매칭 레이어 신설 필요 → MVP 후순위 |
| 3 | 예약 오픈 윈도우 | `reserve_open_at` 컬럼 **없음**. `status='open'` 단일 게이트. 에러는 `_err()` envelope(`CLASS_NOT_OPEN` 등) | 오픈런 예약 원하면 컬럼+게이트 신규 |
| 4 | 코치명 | 클래스 응답에 코치명 **없음**, `coach_user_id`(=login_id 문자열)만. `/coaches` 는 `gym_managers.id`(정수) 키 → **식별자 불일치** | 코치명 표시는 백엔드 조인(GymManager 경유 id↔login_id) 선행 |
| 5 | 페이싱 엔진 | `POST /api/v1/pacing/calculate` 는 `load_value` 를 **입력**으로 받아 split/rest/pace 산출. "권장 kg" 출력 함수 **없음**. 단 1RM 조회 인프라(`_auto_overrides`·`_PROFILE_DIRECT_1RM`·`MaxRecord`)는 재사용 가능 | **1RM 환산은 신규 처방 레이어**(1RM × Tier 비율) 필요 |

### ⚠ 발견된 버그 (회의 중 추가 발견)
**현재 앱 출석 캘린더는 '가짜 출석'이다.** `attendance_screen.dart`의 `_AttendanceCalendar`가 `gym_attendances`(QR 체크인)가 아니라 `listWodHistory`(개인 페이싱 계산 기록)의 `createdAt`을 출석일로 칠하고 있음. 실제 체크인과 무관. → 그룹5 작업 시 진짜 출석 API로 교체 필요(별도 트래킹).

## B. MVP 스코프 (신규 화면 0 — 기존 화면 보강)

### B1. 수업 예약 보강 (그룹1)
- **B1-1 주간 셀렉터** `_WeekStrip` — `classes_screen.dart`에 가로 7일 탭 위젯 추가. 백엔드 `listClasses(from,to)` 날짜 파라미터 이미 지원 → **API 변경 0**. (프론트 S)
- **B1-2 코치명 노출** — 백엔드: 클래스 응답 직렬화에 `coach_name` 추가(GymManager로 `login_id`→`gym_managers.id`→`GymCoachProfile.name` 조인). 앱: `ClassSessionDto.coachName` 필드 + 카드 표시. (백 S, 프론트 S)
- **B1-3 (선택) 예약 오픈 윈도우** — `class_sessions ADD reserve_open_at DATETIME NULL` + 예약 직전 게이트(`RESERVE_NOT_OPEN` + 오픈시각 반환). 앱은 에러 메시지 표면화. MVP 필수 아님 → 사장이 오픈런 운영 원할 때만. (백 S)

### B2. WOD 상세 구조화 + 1RM 환산 (그룹3) — facing +α 핵심
- **B2-1 동작 레벨 구조화** — `GymWodPost.rounds_data` JSON 스키마 확장(스키마 변경 0, 직렬화/파싱만):
  `[{label, movements:[{movement_slug, name, sets, reps, load_value, load_unit, rest_sec}]}]`.
  POST 검증 + GET 응답 확장. 앱 `_AssignmentRow` 위젯(동작 1줄: 동작명·sets×reps·load·rest). (백 S, 프론트 S)
- **B2-2 1RM 환산 처방 레이어** — **신규**. `one_rep_max × Tier별 처방비율`로 "네 1RM 기준 X kg" 산출.
  - 백엔드 신규 `POST /api/v1/member/wod/{post_id}/prescribe` (또는 WOD 응답에 인라인): device 프로필 1RM(`_auto_overrides` 재사용) × 동작별 처방비율 → `{movement, prescribed_kg, tier}`.
  - 처방비율 테이블 정의 필요(ADR) — 예: 동작별 %1RM 기본값.
  - 앱: `_AssignmentRow`에 "Your load: 42kg (RX)" 보조 라인. (백 M, 프론트 S)
- **B2-3 (후순위) 동작 영상** — 동작명↔`MovementLibrary` 매칭 레이어 + `url_launcher` 외부재생. MVP 제외, B2 phase2.

### MVP 카피 (V1~V11)
- 예약 완료 모달 → `Reserved.` / 취소 → `Cancel reservation?`
- 오픈 차단 → `Booking opens 05.30 00:00` + 한글 캡션 "오픈 전입니다"(V10 수직스택)
- WOD 동작 라벨 → `Sets` `Reps` `Rest 60s` `Load` / 시작 → `Start WOD`
- 환산 라인 → `Your load: 42kg · RX`

## C. v-next 스코프 — 회원권 홀딩 (그룹2)
회원 셀프 홀딩 API·한도 모델 **전무**. 신규 구축 묶음.
- **C-1 용어 SSOT(§0-B)** — 코드 `pause` ↔ UI `hold/홀딩` 통일(권장 내부 `hold`). 선행.
- **C-2 한도 모델** — `membership_plans ADD hold_max_days INT`, `hold_max_count INT`.
- **C-3 홀딩 이력 테이블** — `gym_membership_holds`(membership_id·start·end·reason·status[requested/active/completed/rejected]·requested_by·created_at). 기존 단일 `pause_*`는 "현재 활성" 캐시로 유지하거나 이력으로 일원화(admin.py:1148 동시 수정 의무).
- **C-4 회원 API** — `GET /member/membership`(D-day·한도·홀딩 잔여), `POST /member/membership/{id}/hold`(한도 검증, 박스정책상 승인형이면 requested + 사장 SSE).
- **C-5 앱** — `HoldMembershipScreen`(다크 date range picker — 기본 picker 라이트라 커스텀, `_AttendanceCalendar` 그리드 재활용 검토) + `_MembershipCard`에 한도·잔여 표시.
- 작업량 **M** (5그룹 중 최대).

## D. 폐기 (그룹4 공지 좋아요·댓글)
브랜드 충돌(V4·NOBULL)로 폐기. 양방향 소통은 inbox·member_requests로 충분.
단, WOD 댓글 UI는 공용 `CommentThread` 위젯으로 추출해 SSOT화(그룹3 댓글과 묶어 처리).

## E. ADR 결정 필요
1. **WOD 동작 구조화: JSON 확장 vs 정규화 테이블** → MVP는 JSON 확장(무위험) 권장.
2. **1RM 처방비율 출처** → 동작별 기본 %1RM 테이블을 어디 둘지(상수 vs DB). + Tier(Scaled~Games)별 보정 정책.
3. **예약 오픈 윈도우 도입 여부** → 박스 운영 정책. 옵션 컬럼으로 둘지.
4. **동작 영상 매칭 레이어** → 동작명 정규화(slug) 방식.

## F. 권장 작업 순서
1. ADR 1·2 확정(WOD JSON 스키마 + 처방비율) — B2 선행.
2. **B2(WOD 구조화+환산)** 먼저 — 차별점 핵심, 신규 화면 0.
3. **B1(예약 보강)** 병렬 가능 — 독립.
4. 출석 캘린더 '가짜 출석' 버그 수정(그룹5 연계).
5. v-next: 홀딩(C) — 용어 SSOT부터.
