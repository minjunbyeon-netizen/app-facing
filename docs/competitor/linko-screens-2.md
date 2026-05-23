---
domain: facing
type: competitor-screen-analysis
target: linko.my (2 차 — 사장 PC + 마케팅 + 폰 20장)
last_updated: 2026-05-23
status: active
source: 카카오톡 공유 20장 (2026-05-23 17:25)
---

# linko.my 2 차 스크린샷 분석 (20장)

> 1차 (`linko-feature-gap.md`) 는 회원 폰 9장. 이번 2 차는 사장 PC 어드민 + linko 자체 마케팅 + 다른 폰 화면.
>
> 관련: `docs/competitor/linko.md` · `docs/competitor/linko-feature-gap.md`

## §1. 20장 인덱스

| # | 화면 | 사용자 |
|---|---|---|
| 1 | 회원 등록 폼 | 사장 PC |
| 2 | 주간 스케줄 캘린더 (7일×시간대) | 사장 PC |
| 3 | 락커 grid (계단·기타 그룹) | 사장 PC |
| 4 | WOD 보드 (전자칠판 모드) | 사장 PC |
| 5 | RECORD leaderboard (다크) | 사장·회원 폰 |
| 6 | 월간 WOD 캘린더 | 사장 PC |
| 7 | 공지 list | 사장 PC |
| 8 | 공지 작성 모달 (카톡 발송 가격) | 사장 PC |
| 9 | 설정 — 수업 카테고리 5탭 | 사장 PC |
| 10 | Manage Subscription (영문, $29 STARTER) | 사장 PC |
| 11 | linko 랜딩 헤드라인 | 마케팅 |
| 12 | 350+ 파트너 + 링코페이 | 마케팅 |
| 13 | 3 폼팩터 (PC·회원폰·관리자폰) | 마케팅 |
| 14 | 갈아타기 (마이그레이션) | 마케팅 |
| 15 | LINKO ZONE 로그인 | 사장 PC |
| 16 | LINKO ZONE 사장 홈 (sidebar 9 + 회원 정보 + 수업 일정) | 사장 PC |
| 17 | 유효 회원 리스트 (157명·D-day badge·정렬) | 사장 PC |
| 18 | 회원권 추가 모달 (할인·미수금·받은가격 분리) | 사장 PC |
| 19 | 갈아타기 (다시) | 마케팅 |
| 20 | 종합 | — |

## §2. facing 갭 6건 + 우선순위

| # | 갭 | facing 현재 | 우선순위 | 예상 공수 |
|---|---|---|---|---|
| §2.1 | 사장 홈 dashboard (오늘 예약·출석·신규 + 수업 일정 한 화면) | `/stats` 일부 + `/classes` 분산 — 통합 X | **P0** | 4일 |
| §2.2 | D-day badge + 컬럼 정렬 (회원 리스트) | members 정렬 X / D-day 미표시 | **P0** | 2일 |
| §2.3 | 회원권 추가 모달 (할인·미수금·받은가격 분리 + 결제수단 다중) | 단일 amount 만 | P1 | 2일 |
| §2.4 | 클래스 카테고리 분리 + 색 strip + 코치별 카운트 | classes.html 단일 캘린더, 카테고리 X | P1 | 3일 |
| §2.5 | 카카오톡 공지 발송 + 가격 미리보기 | 알림톡 8 템플릿 있지만 사장 PC 즉시 발송 UI X | P1 | 2일 |
| §2.6 | WOD 전자칠판 모드 (TV 송출용 fullscreen) | wod.html placeholder | P2 | 3일 |

## §3. 세부 분석

### §3.1 사장 홈 dashboard (가장 큰 갭)

**linko 화면 16**:
- 좌측 sidebar 9 메뉴 (홈·회원·수업·통계·락커·보드·노트·공지·설정)
- 메인 좌측: "오늘 예약한 회원 15명" + 프로필 사진 5개 가로 / "오늘 출석한 회원 15명" / "신규 등록 회원 10명"
- 메인 우측: "수업 일정 2026.05.23" — HYROX 10AM 카드 1개 + 박창현 +1 코치 표시

**facing 현재**: `/stats` 에 KPI 카드 있지만 "오늘 예약·출석·신규" 분리·프로필 사진 가로 list X. `/classes` 와 `/stats` 가 분리돼 있어서 한 화면에 안 보임.

**개선 plan**:
- `/stats` 또는 신규 `/dashboard` 페이지에 위 4 섹션 통합
- 오늘 예약·출석·신규 — 회원 프로필 photo 카드 가로 스크롤
- 수업 일정 카드 — 오늘 수업 list + 예약자 명단 진입 버튼
- D-day 임박 회원 알림 카드 (이탈 위험 통합)

### §3.2 D-day badge + 컬럼 정렬

**linko 화면 17**: 회원 리스트에 D-day·D-1·D-2·D-5 같은 badge (회원권 종료 임박도). 컬럼 헤더에 정렬 화살표.

**facing 갭**:
- `members.html` 에 `membership_end_date` 있지만 D-day 변환 표시 X
- 컬럼 정렬 (정렬 가능 thead) X

**개선 plan**:
- API 응답에 `d_day` 계산 필드 (예: 종료까지 N일 남음)
- members.html row 에 D-day badge (D-1·D-5·D-day 색 그라데이션 — `--warning` 사용)
- thead 컬럼에 정렬 화살표 + JS 클라이언트 정렬 (이름·생년·시작·종료·D-day)

### §3.3 회원권 추가 모달

**linko 화면 18**:
- 기존 회원권 표시 (회원권명·기간·결제 금액·미수금·남은 일수·수강 횟수)
- 추가 등록 폼 — 카테고리·회원권 종류·시작·종료·**최대 수강 횟수**·결제일·**회원권 가격·받은 가격·할인 금액·미수금 금액**·결제수단 (현금·카드·계좌이체)·결제수단 추가 다중

**facing 갭**: 결제 모달이 단일 amount + method 만. 할인·미수금·받은가격 분리 X.

**개선 plan**:
- `gym_payment` 모델에 `discount_amount`·`unpaid_amount`·`received_amount` 컬럼 추가 (이미 일부 있을 수 있음)
- 회원권 추가 모달에 위 입력 분리 + 결제수단 다중 (현금 일부 + 카드 일부) 지원

### §3.4 클래스 카테고리 분리

**linko 화면 9·2**: 설정에서 CrossFit·Magnum Power 60·HYROX·Magnum compete·HYROX race prep·HYROX Engine·HYROX Build 7+ 카테고리 정의. 각 카테고리에 색 strip + 담당 코치 매핑. 캘린더에서 카테고리별 색으로 표시.

**facing 갭**: classes 모델은 단일 title 만. category 컬럼 X.

**개선 plan**:
- 신규 `gym_class_category` 모델 (gym_id·name·color·default_coach_id)
- `class_session` 에 `category_id` FK 추가
- 설정 페이지 (`/settings/categories`) 에서 카테고리 CRUD
- classes.html 캘린더 cell 에 카테고리 색 strip

### §3.5 카카오톡 공지 발송 + 가격 미리보기

**linko 화면 8**: 공지 작성 시 하단 "유효 회원 0명에게 카카오톡 메시지 발송시 0원" 표시. 발송 비용 미리 안내.

**facing 갭**: 알림톡 8 템플릿 자동 발송 있지만 사장이 PC 에서 즉석 공지 + 카톡 발송 + 비용 계산 UI X.

**개선 plan**:
- 공지 작성 모달에 "카카오톡 발송" toggle + 대상 (유효 회원·만료 회원·코치·전체) select
- 백엔드 `POST /api/v1/admin/announcements/<id>/broadcast` — NHN 알림톡 단가 × 대상 수 계산 후 발송
- 단가 표시 (예: 알림톡 9원 × 138명 = 1,242원)

### §3.6 WOD 전자칠판 모드

**linko 화면 4**: WOD 본문 큰 글씨 + 우상단 "칠판 모드" 버튼 → TV·모니터에 fullscreen 송출. 박스 입구·벽 디스플레이용.

**facing 갭**: wod.html 게시 placeholder 만.

**개선 plan**:
- `/wod/<id>/board?fullscreen=1` 신규 라우트 — 칠판 모드 (Helvetica 80px·검정 배경·흰 글씨)
- TV 브라우저로 진입 → 큰 글씨로 운동 list 표시

## §4. 마케팅 분석 (linko 자체)

- **랜딩**: "가치 있는 일을 더 가치 있게" — 추상적 슬로건
- **350+ 파트너 체육관**: 시장 검증 강조 (facing 마케팅 시 비슷한 socil proof 필요)
- **3 폼팩터**: 사장 PC + 회원 폰 + 사장 폰 — facing 의 PHASE5 (사장 폰판) 동일 방향
- **링코페이**: 자체 결제 SDK — facing 은 Toss 빌링키 (P0)
- **갈아타기 (마이그레이션)**: AI 데이터 이전 — linko 의 가장 강한 진입 장벽 제거 도구. facing 이 후발주자라면 같은 도구 필요.
- **$29 STARTER**: 글로벌 가격 (월) — linko 가 한국 외 시장 진출 가능성 시사. facing 은 영문 글로벌 plan 도 검토 필요.

## §5. 가장 임팩트 큰 우선순위 (Top 3)

1. **§2.1 사장 홈 dashboard** — 한 화면에 오늘 예약·출석·신규 + 수업 — 사장 운영 시간 절약 효과 최대
2. **§2.2 D-day badge + 컬럼 정렬** — 회원 만료 관리 직관성 (재등록 유도)
3. **§2.3 회원권 추가 모달 (할인·미수금·받은가격)** — 한국 현장 회원권 판매 시 자주 발생 (할인 행사·미수금 외상)

## §6. 다음 study 후보
- linko 의 "AI 어시스턴트" Beta — 사장 폰 메인에 "Kim, Shall we do our best today?" 같은 AI 보조 멘트 노출. 운영 매니저 AI 미구현 영역.
- linko 의 통계 dashboard — 매출·신규 회원·이탈 trend 차트 (이번 20장에 직접 안 보임)

## §변경 이력
- 2026-05-23 18:50 — 신규 작성 (20장 분석 + 갭 6건 우선순위)
