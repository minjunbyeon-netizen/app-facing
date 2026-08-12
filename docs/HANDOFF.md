# HANDOFF - 2026-08-12 16:43

> 주제: facing 3면(앱·PC 웹·백엔드) 역할 규칙 정립 + 코치 동선 실사용 가능화.
> 이번 세션은 **로컬 커밋만** 했다. push·배포 0건.
> 3개 repo 를 동시에 만졌다: `apps/facing-app` · `web/facing-admin` · `services/facing`
> (+ `web/facing-web` 문서 1건).

## 완료

- [x] **D29 코치 = 사장** — 운영 권한 전부 개방. `api/admin.py BOSS_LEVEL_ROLES` ·
      `api/classes.py _STAFF_ROLES` 두 상수가 정본. 웹 nav·버튼의 coach 분기 전면 제거
- [x] **D30 코치 이름 평문** — `ROLE_SCOPES` 의 coach 3종에 `members_name_full` 추가.
      연락처·생년월일은 계속 마스킹 (PIPA §29 최소권한 유지). 실측: 코치 `김도윤`/`010-****-7782`
- [x] **D31 명단 출석 체크** — `PATCH /api/v1/admin/reservations/<id>/status`
      (confirmed·attended·no_show. cancelled 는 거부). 앱 시트 [출석][노쇼] 토글 +
      웹 상세 모달 버튼. gym_attendances 동기화(중복 방지·QR 행 불가침) 포함
- [x] **D31 대기 순번 정정** — 저장값(`promoted_position`) 대신 매 조회마다 재계산.
      `_current_waitlist_position()` · 적용 3곳(관리자 명단·회원 클래스·회원 예약)
- [x] **D32 고아 행 정리** — `services/facing/scripts/fix_orphans.py` 신설
      (기본 점검만, `--apply` 시 백업 후 삭제). 로컬 DB 14건 제거 → foreign_key_check 0건
- [x] **D33 3면 공통 대전제 3줄** — 브리프 §2-0 정본 + 4개 repo CLAUDE.md 에 동일 문구
      ① 사장=코치 ② 회원은 폰(앱)에서만 ③ 사장·코치는 PC 에서도
- [x] **규칙 위반 코드 4곳 수정** — contracts.py 게이트 2개 → `_require_staff` 통합 ·
      claim.py 가입코드 코치 개방 · admin.py `require_boss_or_manager`(죽은 코드) 삭제
- [x] **회귀 테스트 7개** — `services/facing/tests/test_rules_prem.py`. `pytest tests` 157 passed
- [x] **실호출 검증** — 계약서 9종+가입코드 1종 × (boss·coach·manager) = 30콜 403 0건,
      비로그인 7콜 401. 골든 16장·`flutter analyze` 0 issues·갤러리 22장

## 진행중

없음. 모든 착수 항목이 커밋까지 끝났다.

## 대기 (사용자 결정 필요 / 다음 후보)

- [ ] **로컬 dev DB 역할 제약 드리프트** — `data/facing.db` 의 `ck_gym_manager_role` 이
      `('boss','coach')` 라 **매니저 계정 생성 자체가 불가**. 운영·신규 DB 는
      `('boss','manager','coach')` 정상. 매니저 역전 버그가 오래 산 원인.
      고치려면 SQLite 특성상 테이블 재생성 필요 → 사용자 판단 대기
- [ ] **`api/gym.py:486,590` 기기 소유 게이트** — `gym.owner_hash != h` 로 코치 폰을 막는다.
      세션 role 축이 아니라 device_hash 축이라 규칙 1 적용 여부가 별도 판단 (미착수)
- [ ] **`classes.py` CSRF 미적용** — 파일 전체가 `require_csrf` 를 안 쓴다(수업 취소 포함).
      신규 출석 API 도 파일 관례에 맞춰 안 붙였다. 일괄 적용할지 결정 필요
- [ ] **운영 DB 고아 정리** — 점검 결과 **0건이라 정리 불필요**. 재점검은
      `railway ssh "echo <b64> | base64 -d | python"` 패턴(읽기 전용 mode=ro)
- [ ] **`pytest` 루트 실행 크래시** — 인자 없이 `pytest` 만 치면 capture 오류로 죽는다.
      **이번 변경 이전부터 있던 문제**. `pytest tests` 로는 157 passed. 원인 미추적
- [ ] 계약서 실데이터로 코치 열람 내용까지 확인 (이번엔 임시 DB 라 계약서 0건)

## 결정사항 / 주의

1. **§2-0 3줄이 최상위 규칙.** 브리프의 다른 표·D 결정·각 repo CLAUDE.md 는 전부 각론.
   충돌 시 3줄이 이긴다. 규칙 1 의 **유일한 예외는 PII**(D30) — 축이 다르다.
2. **배포 금지 유지.** 사용자가 "배포해"라고 하기 전까지 push·railway up 금지
   (프로젝트 CLAUDE.md 최상위). 이번 세션 push 0건.
3. **`services/facing` 에 다른 Claude 세션이 동시 작업 중이었다.** auto-save 훅이 내
   변경을 자기 커밋에 여러 번 흡수했다(`1841275`·`7759d62`). 내용은 온전하나
   커밋 메시지가 auto-save 로 남았다. 다음 세션도 같은 상황일 수 있으니 커밋 전 `git log` 확인.
4. **`gym_coach_profiles` FK 결함은 그 세션이 고쳤다** (`1c18d1b`). 모델·DDL 수정 +
   기존 DB 복구 마이그레이션 포함 → **배포하면 운영이 자동으로 낫는다.**
   내가 운영 DB 조회로 찾은 것과 같은 건이다 (운영 테이블은 아직 깨진 상태).
5. **명단 API 의 `orphan`('탈퇴 회원') 처리는 그대로 둔다** — 운영 DB 미정리 + 값싼 방어.
6. **검증 시 로그인 5회/5분 제한**에 자주 걸린다. 계정당 1회 로그인 후 세션 재사용하거나
   백엔드를 재시작해 리미터를 리셋할 것.
7. 골든 `common_05_signup.png` 갱신은 내 변경과 무관 — `c974192`(auto-save)가 버튼을
   추가하고 골든을 안 돌려 커밋본이 낡아 있던 것을 바로잡은 것.

## 관련 파일

| 경로 | 역할 |
|---|---|
| `apps/facing-app/docs/ARCHITECTURE_BRIEF.md` | **최상위 SSOT.** §2-0 대전제 · D29~D33 |
| `services/facing/api/admin.py` | `BOSS_LEVEL_ROLES` · `ROLE_SCOPES` · `_mask_pii` |
| `services/facing/api/classes.py` | `_STAFF_ROLES` · 명단 API · 출석 PATCH · 대기 순번 |
| `services/facing/api/contracts.py` | `_require_staff` (옛 이름 2개는 별칭) |
| `services/facing/tests/test_rules_prem.py` | 3줄 규칙 회귀 테스트 7개 |
| `services/facing/scripts/fix_orphans.py` | 고아 행 점검·정리 (기본 점검만) |
| `apps/facing-app/lib/features/boss/class_roster_sheet.dart` | 명단 시트 + 출석 토글 |
| `apps/facing-app/lib/widgets/fkit.dart` | FKit — `FkListRow.trailingWidget` 추가 |
| `web/facing-admin/templates/classes.html` | 수업 상세 명단 + 출석 버튼 |

## 다음 세션 권장 첫 프롬프트

`/resume`

이어서 하려면 대기 항목 중 하나를 골라 지시:
1. 로컬 dev DB 역할 제약 고치기 (매니저를 로컬에서 못 만드는 문제)
2. `gym.py` 기기 소유 게이트 2곳 결정
3. `classes.py` 전체 CSRF 적용
