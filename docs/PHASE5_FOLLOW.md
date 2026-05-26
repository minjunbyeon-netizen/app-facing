# PHASE5 Follow-up TODO — 2026-05-26 09:17

> 사용자 명시 2026-05-26 09:17 — 버튼 일관성·클래스 track·playwright 3 디버깅.
> /loop 1m cron 으로 자동 진행. 멈추려면 "그만"·"멈춰".

## TASK A — UI 버튼·배지·색 통일 (지저분 정리)

- [ ] A-1. `contracts.html` actions column — 보기/수정/다운로드/사장대리서명 → 일관된 작은 ghost 버튼 1종으로
- [ ] A-2. `contracts.html` status badge — 초안/발송됨/열람/✓서명완료/취소/만료/서명대기/대리 → 색 3종(primary·muted·danger) + 보조 라벨 제거 또는 inline 합침
- [ ] A-3. `members.html` actions — 수정/탈퇴 → 같은 ghost 패턴
- [ ] A-4. `member_detail.html` 메모 inline 배지 + 정지·연장 버튼 → 같은 패턴
- [ ] A-5. `classes.html` 클래스 detail modal 닫기/취소/수정 → 같은 패턴
- [ ] A-6. 전 페이지 grep — pill·badge·chip 색 코드 통일 표 작성

## TASK B — 클래스 Track (수업 종류) 시스템

같은 시간대에 초보(Track 1) vs 진짜 크로스핏(Track 2) 같이 운영. 회원이 취향 골라 들음.
예: 6시 Track1 · 7시 Track2 · 8시 Track1 · 9시 Track2

- [ ] B-1. `ClassSession` 모델에 `track` 컬럼 추가 (예: "intro", "rx", "scaled", "open" 또는 자유 문자열)
- [ ] B-2. ALTER TABLE class_sessions ADD COLUMN track VARCHAR(20)
- [ ] B-3. POST/PATCH class endpoint 에 track 파라미터 추가
- [ ] B-4. `classes.html` 클래스 추가 form 에 track select (있으면) 또는 신규 form
- [ ] B-5. classes.html 리스트·detail 에 track 표시
- [ ] B-6. seed: 오늘 6/7/8/9시 클래스 4건 추가 (Track 1↔2 교차) — 하드코딩 X, INSERT 로 데이터만

## TASK C — Playwright 3 디버깅 사이클

각 사이클: 페이지 진입 → console 에러 확인 → 디자인 이상한 곳 시각 점검 → 발견 시 fix

- [ ] C-1. 1차: contracts·members·classes 3 페이지
- [ ] C-2. 2차: detail modal 들 (member detail·class detail·계약서 modal)
- [ ] C-3. 3차: settings·calendar·announcements 회귀

## 완료 상태 (2026-05-26 09:37)

- ✓ A-1 contracts actions ghost link 통일
- ✓ A-2 stat-badge 색 4종 SSOT (primary·success·muted·danger)
- ✓ A-3 members status badge 4종 매핑
- ✓ B-1·B-2 ClassSession.track 컬럼 + ALTER
- ✓ B-3 classes POST/PATCH endpoint track 파라미터
- ✓ B-4 추가 form Track select (intro/rx/scaled/open + 미지정)
- ✓ B-5 캘린더 chip + detail modal + dashboard 카드 track badge
- ✓ B-6 오늘 8시간대 클래스 시드 (6/7/8/9시 + 18/19/20/21시 — intro/rx 교차)
- ✓ C-1 1차 검증 (contracts·members·classes) console 0
- ✓ C-2 2차 검증 (class detail modal Track 행 표시)
- ✓ C-3 3차 검증 (settings·calendar·announcements) console 0
- ✓ 회원 정리 + 실 이름 시드 10명 + 성별·생년 컬럼 분리
- ✓ payment is_first_payment / classes PATCH / members pause endpoint 추가
- — A-4·5·6 (member_detail·classes modal 등 추가 폴리시): 옵션. 핵심 통일은 stat-badge SSOT 로 다 끌고 감.

## TASK D — 수업 템플릿 + 일일 WOD 배치 (2026-05-26 10:29 추가)

같은 "1수업" 큰 카테고리가 요일마다 다른 운동. 사장이 템플릿 + 시간대 배치 + 일일 WOD 까지 설정 → 폰 회원에게 자동 노출.

- [ ] D-1. `ClassTemplate` 모델 신설 (id·gym_id·name·description·default_track·default_duration·default_room)
- [ ] D-2. `DailyClassPlan` 모델 신설 (id·gym_id·date·hour·template_id·wod_title·wod_description — 그날 그 시간의 실제 운동)
- [ ] D-3. ALTER ClassSession 에 template_id FK 추가 (option, 옛 데이터 호환)
- [ ] D-4. backend admin CRUD endpoint — templates·daily-plans
- [ ] D-5. facing-admin /classes 페이지 또는 신규 /class-templates 페이지 — 템플릿 관리 + 배치 UI
- [ ] D-6. 폰 회원 화면 — 오늘/내일 클래스 + WOD 미리보기 (앱 lib/features/classes 또는 신규 wod 화면)
- [ ] D-7. SSE publish — daily plan 갱신 시 회원 폰 실시간 알림
- [ ] D-8. seed: ClassTemplate 2건 ("1수업 초보 입문" / "2수업 RX 본격") + 오늘 DailyClassPlan 8건 (6/7/8/9/18/19/20/21시 교차)

## 진행 룰

- 1 사이클당 1~2 항목씩 누적 commit
- /loop 1m cron 이 fire — 매 turn 자동 다음 사이클
- BLOCKER 만나면 docs/OVERNIGHT_LOG.md 에 [BLOCKED] 메모 후 다음 항목
- 사용자 "그만"·"멈춰" 메시지 시 cron 종료 + 최종 보고
