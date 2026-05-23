---
domain: facing
type: competitor-feature-gap
target: linko.my
last_updated: 2026-05-23
status: active
source: 카카오톡 공유 스크린샷 9장 (2026-05-23 17:13)
---

# linko.my 실제 앱 ↔ facing 기능 1:1 매칭

> 사용자가 카카오톡으로 공유한 linko.my 실제 모바일 앱 스크린샷 9장 분석.
> facing 의 폰 (Flutter) · PC 웹 (Flask) · 백엔드 (services/facing) 와 1:1 매칭해 갭 도출.
>
> 관련 문서:
> - `docs/competitor/linko.md` — linko 전체 분석 (가격·기능·차별점)
> - `docs/PHASE4_ROADMAP.md` — phase 4 plan
> - `docs/TECH_INVENTORY.md` — facing 현 기술 인벤토리

## §1. 분석한 스크린샷 9장

| # | 화면 | 사용자 | 핵심 기능 |
|---|---|---|---|
| 1 | 운동보기 (Barbell Hip Thrust) | 회원 | WOD 카드 — 무게·reps·세트·휴식·시작 버튼·트로피(랭킹) 진입 |
| 2 | 크로스핏 매그넘 박스 WOD 목록 | 회원 | 날짜별 WOD 카드 list (CrossFit.com·HYROX·Magnum Booty 병렬) + 잠금 + 직접 등록(+) |
| 3 | Linko 회원 홈 | 회원 | 박스 카드(크로스핏 매그넘)·나만의 운동·지난 기록 + 4탭 하단 nav (센터관리·프로그램·타임라인·이벤트) |
| 4 | 타임라인 (박스 마케팅 피드) | 회원·사장 | 박스 2주년 할인 이벤트 배너 — 이미지·헤드라인·기간·CTA + 핀고정 공지 |
| 5 | 회원 정보 수정 (사장 폰) | 사장 | 이름·생년월일·전화번호·성별·사진 수정 폼 + 인증 |
| 6 | 회원 정보 상세 (사장 폰, 4탭) | 사장 | 회원권·홀딩 연장·구매 물품·락커 + 회원권 history (시작/종료일) |
| 7 | 센터관리 (사장·코치 홈) | 사장·코치 | 박스 정보·COACH 배지·"회원 운영 관리" CTA·오늘의 수업(예약자 명단)·공지 |
| 8 | 빈 상태 (센터 미등록) | 신규 사장/회원 | "Closed" 도장·AI Gym Management Program 워터마크·센터 등록 CTA |
| 9 | 순위표 (1RM 동작별) | 회원 | 동작별 무게 ranking·통합/여성/남성 탭·내 순위 + 전체 순위 |

## §2. facing 현 상태 매칭

| # | linko 기능 | facing 현 위치 | 상태 | 갭 |
|---|---|---|---|---|
| 1 | WOD 카드 (무게·reps·sets·휴식·시작) | 폰 `wod_builder` + `wod_session` | 🟡 부분 | A/B 변형 토글, 우상단 트로피 진입, lb 단위 표기 |
| 2 | 박스 WOD 목록 (CrossFit/HYROX/Booty 날짜별) | 없음 (PC `/wod` 는 사장 발행용) | ❌ 없음 | 회원 폰에서 박스가 발행한 WOD 보는 화면 자체 X |
| 3 | 회원 홈 (박스 카드 + 나만의 운동 + 지난 기록) | 폰 `home` + `history` + `gym` | 🟡 부분 | 박스 카드 디자인 약함, entry 분산 — linko 처럼 단일 home 카드로 모아야 함 |
| 4 | 타임라인 (박스 공지·이벤트 피드) | 폰 `announcements` + `inbox` | 🟡 부분 | 이미지 배너·CTA 버튼·기간 표시·핀고정·풍부한 마케팅 도구 없음 |
| 5 | 회원 정보 수정 (사장 폰) | PC `/members/<id>` 만 | ❌ 폰 X | 사장 폰에서 회원 정보 수정 화면 X (브리프 §2 — 사장 PC 만 가정) |
| 6 | 회원 상세 4탭 (회원권·홀딩·구매물품·락커) | PC `/members/<id>` 6탭 (회원권·결제·출석·계약서·메모·Risk) | ❌ 폰 X / 🟡 PC | 폰에서 사장 회원 상세 X · 구매 물품 카테고리 X · 락커 분리 페이지 |
| 7 | 센터관리 (오늘 수업·예약자·공지) | PC `/stats` + `/classes` 분산 | ❌ 폰 X / 🟡 PC | 한 화면 dashboard X, 폰판 없음 |
| 8 | 빈 상태 (Closed 도장·센터 등록 안내) | 폰 `onboarding` 일부 | 🟡 부분 | "Closed" 같은 명시적 empty state·AI Gym 슬로건·센터 등록 1-tap CTA 없음 |
| 9 | 1RM 동작별 순위표 (통합·여성·남성 탭) | 폰 `leaderboard` | 🟡 부분 | WOD time 기반만 — 동작별 무게 ranking·성별 탭 분리 X |

## §3. 종합 점수

- ✅ 동일 수준: **0 / 9 (0%)**
- 🟡 부분: **5 / 9 (56%)** — 1·3·4·8·9
- ❌ 없음: **4 / 9 (44%)** — 2·5·6·7 (4건 모두 폰판 사장 화면이거나 회원 폰 WOD 피드)

## §4. 핵심 갭 4개 (PHASE4 후속 후보)

### §4.1 회원 폰 박스 WOD 피드 (#2)
**왜 필요한가**: 회원이 박스에 가기 전 폰으로 오늘 WOD 미리 보는 게 CrossFit 박스 표준 UX. 코치가 PC 로 발행한 WOD 가 회원 폰 피드에 자동 노출.
**구현**: 폰 `lib/features/box_wod_feed/` 신규. 백엔드 `GET /api/v1/member/box-wods?date=...` (이미 wod 모델 있을 가능성). 잠금(미결제)·CrossFit.com 라이선스 표시 같이.

### §4.2 사장 폰판 운영 화면 (#5·#6·#7)
**왜 필요한가**: 사장이 외출·이동 중 폰으로 회원 정보 수정·신규 가입 승인·오늘 수업 확인 못함. PC 만 가정한 facing 설계가 linko 대비 큰 격차.
**구현**: 
- 폰 `lib/features/boss_dashboard/` — 센터관리 (오늘 수업·예약자·공지)
- 폰 `lib/features/boss_member_detail/` — 회원 상세 6탭 폰판
- 폰 `lib/features/boss_member_edit/` — 회원 정보 수정 폼
- 권한: 사장 로그인 시 `coach` 또는 `boss` 역할에서만 진입 가능 (브리프 §2 RBAC)
- 브리프 §2 "사장은 폰 안 씀" 가정 폐기 → "사장도 폰 보조 운영" 으로 갱신 필요

### §4.3 타임라인 마케팅 풍부함 (#4)
**왜 필요한가**: 박스가 회원에게 할인 이벤트·공지를 시각적으로 보여주는 채널. 단순 텍스트 공지 < 이미지 배너 + CTA + 기간.
**구현**: 폰 `announcements` 확장 + 이미지 업로드 (사장 PC 에서 작성, 회원 폰에 push). 기간 표시·CTA 버튼·핀고정.

### §4.4 무게 기반 1RM ranking (#9)
**왜 필요한가**: linko 가 단순 WOD time 외에 동작별 무게 ranking 으로 회원 동기 강화. facing leaderboard 는 time 기반만.
**구현**: 폰 `leaderboard` 에 "무게 1RM" 탭 추가 + 성별 분리 (통합·여성·남성 3 sub-탭) + 동작 선택 dropdown.

## §5. 우선순위 추천 (Impact × Effort)

| 갭 | Impact | Effort | 우선순위 |
|---|---|---|---|
| §4.1 회원 폰 박스 WOD 피드 | High | 3일 | **P0** |
| §4.2 사장 폰판 운영 화면 | High | 2주 | **P1** |
| §4.3 타임라인 마케팅 | Medium | 4일 | P2 |
| §4.4 1RM ranking | Medium | 3일 | P2 |

> **§4.1 이 가장 임팩트 큼**: linko 핵심 가치이자 facing 의 회원 onboarding 경험 격차. 회원이 박스 가기 전 폰에 WOD 떠 있는 게 너무 당연한데 facing 에서 빠짐.
>
> **§4.2 사장 폰판**: 브리프 §2 의 "사장은 PC 만" 설계 자체를 재검토해야 함. 사장 폰판 추가 시 권한·앱 진입 흐름 전반 변경.

## §6. 이미 잘하는 부분 (linko 와 동등 또는 우위)

- WOD 실행 화면 (#1) — wod_session 기능 거의 동등
- 회원 history 보기 (#3) — 폰 history feature 있음
- 박스 공지 (#4) — 기본 announcements 있음
- leaderboard 기본 (#9) — 폰 leaderboard feature 있음

## §7. linko 가 못 하는 facing 우위 (참고)

linko 9 스크린샷 어디에도 없는 facing 만의 영역:
- Engine 점수 (6 카테고리 백분위 1RM 평가)
- 5단계 Tier 시스템 (Scaled·RX·RX+·Elite·Games)
- 페이싱 알고리즘 (Split·Burst·W-prime — 추후 재시작)
- 한국 전자서명법 §3 준수 전자계약 + QR 위변조 검증
- 카카오 알림톡 8 템플릿 자동화 + SMS 폴백
- 이탈 위험 (churn risk) 점수 + SSE 사장 푸시

## §변경 이력
- 2026-05-23 17:24 — 신규 작성 (스크린샷 9장 분석 + 1:1 매칭)
