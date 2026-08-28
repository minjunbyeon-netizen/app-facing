# HANDOFF - 2026-08-28 15:35

> 이 세션 주제: **앱 업적 화면 리디자인(E 안) 구현 + 코치 PC 웹 수정 요청 8건**.
> 3 repo(app-hyphen · service-hyphen · web-hyphen-admin) 전부 커밋·푸시 완료, 워킹트리 깨끗함.
> ⚠ app 저장소는 **공개(public)** — 자격증명·비밀번호 금지 (§2-A-1).

## 완료

### 1. 앱 업적 화면 리디자인 — v3.35 "E 안" (apps/facing-app)
- [x] 시안 데모 5종 HTML 작성·게시 → 사용자가 **E 안** 확정
      (`docs/design/achievements-redesign-2026-08-28.html` · 아티팩트 https://claude.ai/code/artifact/bb23c216-7ba6-46a8-b12d-d00b0db2f3e5)
      확정 결정: **도장만**(진열대 달성일 글자 삭제) · **행 68**(확인 방식 태그를 제목 옆) · **상태 전환 있음**(전체/미달성/달성)
- [x] `lib/features/achievement/achievements_screen.dart` 전면 교체 — 요약 카드(112) + HkSegment 3칸(40) +
      분류 라벨(40) + 행(64). 로딩은 같은 자리 스켈레톤.
- [x] `lib/features/achievement/trophy_room_screen.dart` 신설 — 검은 진열대(200) + 분류 진척(44) +
      같은 분류 3열 + "다른 분류" 3열. 같은 AchievementState 사용 → 화면 2는 로딩 없음.
- [x] `lib/features/achievement/achievement_group.dart` 신설 — 분류 규칙·라벨 SSOT (구 `_category` 승격)
- [x] HKit 확장: `HkSegment` 신설 · `HkListRow.titleBadge` · `HkSkeletonRow.height/leadingSize`
- [x] `core/time_format.dart mdShort` (7.12) · copy_lint 약관·방침 운영자 표기 예외
- [x] 골든 **62 → 64장** (`member_24_trophy_room` · `state_21_achievements_loading` 신규,
      `ach_01`·`ach_02`·`member_12` 재생성) + 갤러리 등재 + CLAUDE.md 집계 갱신
- [x] 회귀 게이트 신설 `test/golden/achievements_stability_test.dart` — 로딩·완료 앵커 y 동일(52·164·216·257)
- [x] 문구 조정 6건 반영: 확인 방식 **자동 / 기록 자동 / 코치 확인** · 3칸 **전체/미달성/달성** ·
      에러 라벨 삭제(HkErrorState) · 칸별 빈 문구 · 룸 진척 줄 수치만 · 숨김 조건 "조건 비공개 · 달성하면 공개"
- [x] 테스트 221 통과 · 스토어 스크린샷(Android/iOS) 재생성

### 2. 코치 PC 웹 수정 8건 (web/facing-admin + services/hyphen)
요청 원문 정본 = `web/facing-admin/docs/COACH-PC-FIXES-2026-08-28.md`
- [x] 1 회원권 해지 즉시 반영 — 원인은 **기간 만료 해지가 만료일까지 status=active** 라 화면이 그대로였던 것.
      `cancelled_at` 있는 active 를 "해지 예정" 으로 분리 + 성공 즉시 그 행 교체(`applyCancelledRow`) + 버튼 제거
- [x] 2 회원권↔결제이력 통일 — 결제이력 행에 회원권 이름·기간(`plan_name`·`plan_start_date`·`plan_end_date`),
      회원권 행에 `payment_ids` 없으면 "결제 기록 없음"
- [x] 3 회원 수정 폼 = 이용 중 회원권 **PATCH** (없을 때만 POST 발급) + 현재 회원권 값 미리 채움(`prefillCurrentMembership`)
- [x] 4 락커 자동 배정 — **오늘 ~ 회원권 종료일** + "남은 기간 N일" 안내 (구: 회원권 시작일=지난 날짜로 채움)
- [x] 5 수업관리 왼쪽 열 — 시간 눈금 → 그 시각 프로그램 표기(06:30 Awake), 열 폭 52→116
- [x] 6 예약 한도 회원권 종류별 — `gym_plan.daily_limit`/`weekly_limit` 신설(NULL=기본값, 0=무제한),
      게이트에서 종류 한도 > 체육관 기본값, 주 한도는 월~일 KST → `WEEKLY_LIMIT_REACHED`
- [x] 7 포인트 설정에 "자동 적립 항목" 표 + 켜기/끄기 (RewardRule `is_active` — 엔진이 이미 존중)
- [x] 8 홈 수업 일정에 예약 명단 (`reserved_names`·`waitlist`) — `06:30 Awake 예약 4/12` 아래 이름 나열
- [x] 검증: 백엔드 `pytest tests/` **300 통과**(신규 3건) · `python design/lint.py` baseline 유지 ·
      Jinja 템플릿 7종 컴파일 OK

## 진행중
- [ ] 없음. 3 repo 워킹트리 깨끗함.

## 대기 (사용자 결정 / 다음 세션)
- [ ] **배포 후 실화면 확인** — `services/hyphen` + `web/facing-admin` 각각 `railway up` 후 8건 직접 조작 검증
      (이번 세션은 템플릿 컴파일·lint·pytest 까지만. admin 실렌더는 서버 로그인 필요)
- [ ] **결제 기록 정책 결정** — 회원권 발급 시 결제 수단을 안 넣으면 결제 기록이 아예 안 생긴다.
      항상 만들지(미수금 = received 0 / unpaid price) 여부는 **돈 기록이라 임의로 정하지 않음**
- [ ] **앱 버전 3010 빌드** — 업적 화면이 바뀌어 스토어 AAB 3009·홈페이지 `achievements.webp` 는 구 화면
- [ ] 남은 앱 문구 후보 4·7·9·10·11·12 (진열대 분류 태그 중복 등 — 목록은 이 세션 대화에 있음)
- [ ] 코치 PC 웹 디자인 방향 — 바탕화면 `공수체크-PC화면-설계서.md` 기준 3안(골격 이식 / 규격만 정렬 / 데모 먼저) 미결정.
      즉시 고칠 값 1건: admin `--primary: #EE2B2B` 가 앱·홈페이지(#CC1F1F)와 다름
- [ ] 이전 잔여: 스토어 개발자 인증 메일 대기(§G 런시트) · 클로즈드 테스터 12명 · 갤S22 실기 검증

## 결정사항 / 주의
- **업적 4기둥 스코프 안** — 업적은 "수업 공개에 따른 게이미피케이션". API·백엔드 변경 없이 화면만 재구성.
- **레이아웃 안정성** — 업적 목록은 로딩·완료에서 앵커 y 가 같아야 한다(테스트가 막음). 스켈레톤과 실제 행의
  높이 상수(`kRowH` 64 · `_Summary.height` 112 · `HkSegment.height` 40 · `AchievementGroupLabel.height` 40)를 함께 고쳐야 함.
- **admin 작업 절차** — `design/SSOT.md`: 인라인 style 금지, 기존 클래스 우선, `python design/lint.py` baseline 유지.
- **회원권 종류 매칭은 이름 문자열** — `GymMembership.plan_name` ↔ `GymPlan.name` (카탈로그 정본 = gym_plan, G04).
- **DB 컬럼은 추가만** — 삭제 금지. 스키마 확장은 `models/base.py` 의 `_migrate_*` idempotent 패턴.
- 서버 pytest 는 반드시 `pytest tests/` 로 경로 명시.
- 이번 세션 병렬 서브에이전트 4개가 **사용량 한도(429)** 로 전부 죽어 순차로 진행함 — 다음 세션도 팬아웃은 신중히.

## 다음 세션 권장 첫 프롬프트
`/resume` → 배포(railway up) 후 코치 PC 8건 실화면 검증부터, 또는 앱 3010 빌드.
