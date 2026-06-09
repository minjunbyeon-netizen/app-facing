# Opus 병렬회의 회의록 — 매그넘 레퍼런스 5기능 facing 이식

> 일시: 2026-06-09 / 패널: 백엔드·아키텍처(Opus) · Flutter/모바일(Opus) · 제품/브랜드(Opus) 3인 병렬
> 대상: `docs/benchmark/magnum/ANALYSIS.md` 의 도출 기능 5그룹
> 원자료: `docs/benchmark/magnum/00~10.jpg` (크로스핏 매그넘 앱 11화면)

## 0. 최대 합의 — "5개 중 신규는 사실상 2개뿐"

세 패널이 코드를 전수 확인한 뒤 **독립적으로 같은 결론**에 도달했다.

| 그룹 | facing 현황 | 판정 |
|---|---|---|
| 1. 수업 예약 | `classes_screen.dart` + 백엔드 `class_reservation`/waitlist/SSE/알림톡 **70~90% 완성** | **보강만** |
| 2. 회원권 + 홀딩 | 회원권 카드·D-day 완성 / 홀딩은 admin-only 컬럼만 존재, **회원 셀프신청 신규** | **부분 신규** |
| 3. WOD 상세 | 댓글·토글 풍부 / **동작별 sets·reps·rest 정형 + 영상 + 1RM 환산** 갭 | **부분 신규 (핵심 +α)** |
| 4. 공지 좋아요·댓글 | 전무 | **신규 — 단, 제품팀 "버려라"** |
| 5. WOD/출석 캘린더 | `_AttendanceCalendar` STREAK 기반 완성, 매그넘보다 우위 | **점검만** |

순 신규 작업 = 그룹 2(홀딩)·3(구조화 WOD) 두 개. 그룹 4는 브랜드 충돌로 보류 권고.

## 1. 패널별 핵심 발언

### 백엔드/아키텍처
- 예약: 코어 완성. **누락 2건 = 예약 오픈 윈도우 규칙(`reserve_open_at`)** + 취소신청 분기. 작업량 **S**.
- 회원권+홀딩: `gym_membership.pause_*` 컬럼은 admin 전용·단일홀딩만. "21일·3회 한도" + 셀프신청 위해 **`gym_membership_holds` 이력 테이블 + plan 한도 컬럼 신설** 필요. **§0-B 용어충돌**: 코드 `pause` ↔ UI `hold/홀딩` SSOT 통일 선행. 작업량 **M (무게중심)**.
- WOD 상세: `GymWodPost.rounds_data` JSON 을 동작 레벨로 확장하면 **스키마 변경 0**. 정규화 테이블은 MVP 과설계. → JSON 확장 권장(ADR 1건).
- 공지 좋아요/댓글: 순수 신규 2테이블, 격리됨, **무위험 S**.
- 캘린더: 신규 DB 0. 3소스(출석·WOD·history) 날짜축 병합 `GET /member/calendar` 1개. KST 날짜경계만 주의.
- 전체 추정 **M** (그룹2 중심). 미확인: 홀딩 한도 필드 위치, `GET /gyms/{id}/wods` 응답 스키마.

### Flutter/모바일 (중요 정정 포함)
- **상태관리는 Riverpod 아님 → `provider`+`ChangeNotifier`**. 라우팅은 go_router 아닌 **named route 맵(`main.dart`)**. 신규 상태는 기존 패턴 따를 것.
- 예약: `classes_screen` 완성. 신규는 **`_WeekStrip`(가로 요일 셀렉터) 1개**. 백엔드 날짜 파라미터 이미 지원.
- 홀딩: **이 5그룹 중 유일한 진짜 신규 화면** `HoldMembershipScreen` + 다크 date range picker(기본 picker 라이트테마라 커스텀 필요). 최대 리스크 = 백엔드 홀딩 API 부재 가능성.
- WOD 상세: `AssignmentItem` 에 sets·reps·load·restSec **데이터 이미 있음**. `_AssignmentRow` 위젯 + `videoUrl` 1필드. in-app 영상은 패키지 미도입(현재 `url_launcher` 외부재생만).
- 공지 댓글: WOD 댓글 UI 재사용 → **공용 `CommentThread` 위젯 추출**(SSOT). 좋아요 ♥는 `Icon` 사용이라 V4 위반 아님.
- 캘린더: 월 prev/next 네비 + 날짜별 WOD 리스트만 보강. **S**.

### 제품/브랜드 (결론 주도)
- 그룹 3 = **facing +α 와 가장 정합하는 핵심**. 매그넘은 "무게·세트 표시"까지, facing 은 거기에 **회원 1RM·Engine·Tier 환산**("네 1RM 기준 42kg, Tier RX 권장")을 얹어 Wodify/매그넘이 못하는 차별화.
- 그룹 4 좋아요·댓글 = **버려라**. ♥·댓글은 소셜 메커니즘, V4·NOBULL 톤과 정면충돌. 공지는 정보전달이지 인게이지먼트 아님. 양방향은 이미 inbox·member_requests 로 충분.
- 그룹 2 홀딩 = 한국 박스 churn 방지 필수지만 사장승인·잔여일 재계산 얽힘 → **v-next**.
- UI 0% 복제, 흐름만. 밝은톤·민트·pill·이모지 전부 버리고 다크+영문(V1~V11)으로 번역.

## 2. 함정 (copy 금지)

1. **그룹 3 를 "무게·세트 표"로만 베끼면** 페이싱 엔진이 안 붙어 열등한 Wodify 클론. → WOD 상세에 **1RM 환산을 1차 스코프 필수 포함**.
2. 그룹 4 좋아요·댓글 따라하면 브랜드 희석.
3. 예약을 매그넘 UI(민트·pill·모달)까지 베끼면 다크 정체성 붕괴 — 흐름만.
4. **스코프 크리프**: "5개 다 신규"로 착각하면 PHASE4 재팽창. 순 신규는 2개.

## 3. 합의된 추천 1차 스코프 (MVP)

> **신규 화면을 만들지 않는다.**
> ① `classes_screen` 보강 — 예약 오픈 윈도우 + 코치명 + `_WeekStrip`
> ② `wod_detail_screen` 보강 — 동작별 무게·Reps·Sets·rest·영상 구조화 + **회원 1RM 환산(facing +α)**
> → 홀딩(그룹2)은 v-next, 공지 좋아요·댓글(그룹4)은 보류/폐기.

## 4. 착수 전 선결 (미확인 해소)

- `GET /gyms/{id}/wods` 및 `daily-plans` 응답 스키마 본문 확인 (그룹3 착수 전)
- WOD 동작 영상 URL 백엔드 필드 유무 + in-app 영상 재생 패키지 도입 여부 결정 (ADR)
- WOD 상세 ↔ 페이싱 엔진(`services/facing/engine/`) 환산 API 계약 정의
- (v-next) 홀딩 API 부재 확정 시 백엔드 `gym_membership_holds` 설계 + `pause`/`hold` 용어 SSOT 통일
