# HANDOFF - 2026-05-25 14:49

> v1.16.2 큰 마일스톤 완료 세션. 어제 21:38 인계 이후 약 17시간 작업.

## 완료 (어제 21:38 ~ 오늘 14:49)

### 핵심 1 — facing-app 정체성 큰 전환
- [x] **포지셔닝 재정의** — "Games elite 페이싱 계산기" → "수업 관리 + 페이싱(+α)"
- [x] CLAUDE.md v1.16.2 (Primary value 변경, V1~V11 어투 유지, 금지어 헬스·다이어트·웰니스 유지)
- [x] ARCHITECTURE_BRIEF §11.5 (포지셔닝 전환) + §11.6 (스키마 확장) 등록

### 핵심 2 — 박스 프로필 + 코치 프로필 신규 스키마
- [x] `gym_profiles` 9 필드 ALTER (price_summary·payment_methods·receipt_info·parking_info·first_visit_guide·attire_guide·wifi_info·contact_kakao·free_notice)
- [x] `gym_coach_profiles` 신규 테이블 (coach_user_id·name·photo·career·certifications·specialty·competition_records·demo_video·sns·pt_bookable·off_days·display_order)
- [x] 백엔드 API: GET/PATCH gym profile 9 필드 + 코치 CRUD 5 endpoints + SSE `gym.profile.updated`/`coach.profile.updated`
- [x] Flutter UI: BoxProfileScreen + CoachDetailScreen (skeleton, read-only) + GymState `coaches` 필드 + repository 메서드

### 핵심 3 — 폰 MyPage 회원권·락커 카드 (v1.16.2 시그니처 작업)
- [x] 백엔드 `GET /api/v1/member/me/locker` 신규
- [x] Flutter `Membership`·`Locker` 모델 + repository (`listMyMemberships`·`listMyLockers`)
- [x] GymState `currentMembership`·`myLocker` getter + `loadMine()` 안에서 fetch
- [x] MyPage `_MembershipCard` (진행 막대 + 월별 타임라인 + TODAY 마커) + `_LockerCard` (락커 번호 + D-day)
- [x] SSE `locker.assigned`/`locker.released`/`gym.profile.updated`/`coach.profile.updated` 자동 reload trigger
- [x] e2e 실측: PC PATCH /lockers/A-07 release → 폰 SSE recv 1s → 카드 사라짐 (logcat + 캡쳐 검증)

### 핵심 4 — IdentityCard 3 줄 분리 + 역할 매핑
- [x] DemoAccount.personName 필드 분리 (옛 nameLabel 통문자열 폐기)
- [x] IdentityCard: 1줄 이름 / 2줄 박스명·역할 / 3줄 위치 / 4줄 DEMO 분리
- [x] `lib/core/role_labels.dart` 신규 — roleKoLabel(owner=코치, boss=사장, member+approved=회원, pending=가입대기 등 7 분기)
- [x] 옛 displayName 통문자열 자동 split 가드 (` · ` 첫 부분만)

### 핵심 5 — 배포 인프라
- [x] **GitHub push**: services/facing + web/facing-admin 양쪽 master
- [x] **Railway 배포**: service-facing + web-facing-admin 둘 다 production
- [x] **속도 SSE 워커 점유 fix** — `gunicorn -w 2 sync` → `-k gevent -w 1 --worker-connections 1000` → 32초 멈춤 → 0.1초
- [x] **메타 일괄 추가** — title·description·favicon SVG·OG 이미지(미니멀 1200×630) + ProxyFix (`og:image` https 강제)
- [x] Railway Volume 마운트 시도 → 권한 이슈로 detach (Dockerfile 원복)

### 핵심 6 — 시연 데이터
- [x] FACING SEONGSU(gym 2) 시드: 10 회원([DEMO] 김도윤·이수민·박지훈·최서윤·강민재·윤지원·한수아·송예준·정하은·임도현)
- [x] 회원권 9건 (1·3·6·12개월권 골고루, active·expiring·expired 분포)
- [x] 클래스 24개 (7일 × 평일4슬롯·주말2슬롯)
- [x] WOD 4개 게시 (FRAN·DT·EMOM·HELEN)
- [x] 박스 프로필 9 필드 가상 채우기 (가격·결제·주차·와이파이·카톡·휴무 공지 등)
- [x] 백엔드 신규 `DELETE /api/v1/admin/members/{mid}` hard-delete endpoint

### 핵심 7 — PC 어드민 사이드바 재배치
- [x] 코치 + 시급정산 1 항목으로 통합 (`코치 · 시급정산` → /coaches, /payroll 도 active)
- [x] 전자계약서 → 운영 섹션 이동
- [x] 클래스 예약 → 기타 섹션 이동
- [x] 락커 일괄 추가 modal (존 prefix + 범위 + zero-pad)

### 검증
- [x] 사이드바 14 항목 playwright 전수 검증 (105~225ms, 평균 124ms, 에러 0)
- [x] 액션 버튼 실 클릭: 락커 modal open · 코치 시급정산 링크 · 코치 추가 버튼
- [x] flutter analyze 0 issue (변경 파일 전부)

## 진행중

- [ ] **코치 프로필(gym_coach_profiles) 시드** — `coach_user_id`(gym_managers.id) 가 admin API 에 노출 안 됨. 별도 endpoint 신설 또는 DB 직접 INSERT 필요. 현재 NOTICE 카드는 GymProfile.coach_name·coach_bio fallback 으로 동작 (박지훈 · CrossFit L2 · 9년)
- [ ] **Railway Volume 권한 fix** — `entrypoint.sh` 로 root → chown → drop to appuser 패턴 필요. 현재는 Volume detached 상태 → 매 배포마다 DB wipe → 재시드 필요
- [ ] **HARDFIX 후 재테스트** — Volume 재마운트 후 영속 검증

## 대기 (다음 세션 후보)

- [ ] PHASE5 §1.3 사장 폰 회원 list+상세 6탭 (1주 plan)
- [ ] PHASE4 P0 잔여 — Toss 빌링키 자동결제·재시도·grace / 듀얼 포지셔닝 B2B2C
- [ ] 폰 사장 편집 UI 확장 (`gym_profile_edit_screen` 9 필드 + 신규 `coach_profile_edit_screen`)
- [ ] 회원 가입 흐름 e2e 시연 (폰 가입 신청 → PC 사장 승인 → 회원권 발급 → 폰 카드 갱신)
- [ ] 전자계약서 PC→폰 전자서명 흐름 e2e 시연 (PHASE4 §1.3 이미 모델 등록, UI 미완)
- [ ] 폰 APK 실기 Galaxy S22 설치 (어제 미완)

## 결정사항 / 주의

- 사용자 명시 **배포 진행** (이번 세션 처음으로 git push + Railway deploy 허용)
- Railway Hobby 플랜이라 cold-start sleep 없음 — 어제 본 32초 멈춤은 cold start 가 아니라 gunicorn sync 워커 + SSE 점유 문제
- 백엔드 service-facing Dockerfile: gunicorn -k gevent -w 1 (SQLite + workers=1 룰)
- 어드민 web-facing-admin Dockerfile: gunicorn -k gevent -w 1 --worker-connections 1000 (어제 v1.16.2 변경)
- **Volume 미마운트 상태** — 다음 배포 시 DB wipe. 재시드 스크립트: `cd web/facing-admin && PYTHONIOENCODING=utf-8 python scripts/seed_demo.py --prod`
- 시연 계정: boss_seongsu / 1234 (FACING SEONGSU, gym_id=2)
- 임시 admin5 / 1234 도 시연 시 만들었음 (Volume 시도 중 DB wipe 됐을 가능성)

## 이번 세션 commit (로컬 + push)

| repo | 주요 commit | push |
|---|---|---|
| services/facing | gym 9 필드 ALTER · 코치 테이블 · API · DELETE endpoint | ✓ |
| services/facing | Dockerfile 원복 (Volume 권한 이슈로) | ✓ |
| web/facing-admin | 코치·시급정산 통합 + 락커 일괄 추가 · gevent 전환 · OG 이미지 · ProxyFix · 시드 스크립트 | ✓ |
| apps/facing-app | GymProfile 9 필드 model · BoxProfileScreen · CoachDetailScreen · MembershipCard · LockerCard · IdentityCard 3줄 · role_labels · 박스소식 카드 보강 | (로컬만, push 안 함) |

## 외부 자료 / URL

- 프로덕션 어드민: https://web-facing-admin-production.up.railway.app
- 프로덕션 백엔드: https://service-facing-production.up.railway.app
- ARCHITECTURE_BRIEF: `docs/ARCHITECTURE_BRIEF.md` §11.5·11.6
- 박스 프로필 스키마: `docs/GYM_PROFILE_SCHEMA.md`
- 페르소나 백로그: `docs/PERSONA_BACKLOG.md`
- 시드 스크립트: `web/facing-admin/scripts/seed_demo.py`

## 다음 세션 권장 첫 프롬프트

`/resume`

그 후 (a) **Volume entrypoint 영속 fix** → DB wipe 끝내기, 또는 (b) **폰 emul 띄워서 NOTICE 박스 소식 카드 채워진 모습 캡쳐 + apps/facing-app push**, 또는 (c) **PHASE5 §1.3 사장 폰 모드** 본격 시작.
