# HANDOFF - 2026-05-25 15:48

> 어제 21:38 → 오늘 14:49 의 v1.16.2 큰 마일스톤 끝낸 직후 이어진 1시간 세션.
> Volume entrypoint fix → 배포 → 시드 → prod APK 빌드 → emul 검증까지 깔끔하게 끝.

## 완료 (오늘 14:49 → 15:48, 약 1시간)

### 핵심 1 — Railway Volume 권한 영속 fix
- [x] **services/facing entrypoint.sh 신규** — root 시작 → mkdir -p /app/data → chown -R appuser → exec gosu appuser gunicorn
- [x] **Dockerfile 수정** — apt-get install gosu, `USER appuser` 제거(root 유지), `ENTRYPOINT ["/entrypoint.sh"]`, CMD 제거
- [x] **.gitattributes 신규** — `*.sh text eol=lf` (Windows 작업 시 CRLF 차단)
- [x] commit `2b08438` + GitHub push → Railway 자동 빌드 트리거
- [x] Railway Volume 사용자 직접 마운트 (Settings → Volumes → /app/data)
- [x] 새 빌드 health 200 4분 polling 검증

### 핵심 2 — Production DB 재시드
- [x] `cd web/facing-admin && PYTHONIOENCODING=utf-8 python scripts/seed_demo.py --prod` 실행
- [x] 10 회원 `[DEMO]` prefix (mid 62~71): 김도윤·이수민·박지훈·최서윤·강민재·윤지원·한수아·송예준·정하은·임도현
- [x] 9 회원권 (1·3·6·12개월권 분포)
- [x] 24 클래스 세션 (7일치)
- [x] boss_seongsu/1234 login 검증 OK (active_gym=2 FACING SEONGSU)
- [x] health: gyms=3, managers=3, SSE 42 subscribers

### 핵심 3 — Flutter APK prod 빌드 + emul 검증
- [x] `flutter build apk --release --dart-define=API_BASE_URL=https://service-facing-production.up.railway.app` (background, 77.8s)
- [x] APK 59.9MB 생성 → emul install
- [x] **NOTICE 박스 소식 카드 9 필드 다 살아있음 확인** — FACING SEONGSU·Seoul Seongsu·02-1234-5678·@facing.seongsu·COACH 박지훈(CrossFit L2·9년)·CLASS 평주말 시간표·PRICE 1·3·6·12개월권·PT·체험권·MOTTO "Earn it. Every day."
- [x] **WOD 게시 확인** — AMRAP 15 (Power Clean 135/95lb·Burpee Box Jump 24/20) + FRAN 21-15-9 (Thruster 95/65lb·Pull-up)
- [x] 박지훈 코치 view (FACING SEONGSU OWNER) WOD·Notice 양쪽 잘 떴음

## 진행중

(없음 — 이번 세션 모든 작업 마무리)

## 대기 (다음 세션 후보)

### 우선순위 높음
- [ ] **백엔드 admin override 시드 endpoint** (오늘 시작 안 함, 1시간+) — gym profile PATCH + WOD POST 가 device-hash 인증이라 admin JWT 로 호출 불가. seed_demo.py 가 박스 프로필 9 필드 + WOD 4개를 자동 시드 못함. 다음 Volume wipe 시 사용자가 또 PC 어드민 수동 채워야 함. 영속 인프라로 백엔드에 admin 전용 endpoint 추가 필요
  - 위치: `services/facing/api/gym.py` 끝에 `POST /api/v1/admin/gyms/<gym_id>/seed-profile`, `POST /api/v1/admin/gyms/<gym_id>/seed-wod` 추가
  - 인증: `session["admin_role"] in ("boss","owner")` + `session["admin_gym_id"] == gym_id`
  - seed_demo.py 에 `seed_box_profile()` + `seed_wods()` 함수 추가

- [ ] **코치 프로필 시드 (gym_coach_profiles)** — 어제부터 진행중. coach_user_id(gym_managers.id) 가 admin API 에 노출 안 됨. 신규 endpoint 또는 admin override 와 같이 처리

### 중간
- [ ] **services/facing untracked 3건 정리** — `.err.log`, `.run.log`(M), `data/contracts/contract_10_signed_20260523_212559.html`. `.gitignore` 에 `.err.log`, `.run.log`, `data/contracts/*.html` 추가 + `git rm --cached .run.log`
- [ ] **apps/facing-app ahead 1 commit (chore handoff 어제 임시)** — push 안 한 상태. 어제 70d9172 chore(handoff). 다음 세션에서 push 또는 squash 결정
- [ ] **데이터 정리** — 박지훈 계정이 Test 박스 OWNER + FACING SEONGSU 코치 두 군데 동시 소속이라 박스 default 가 Test 로 잡힘. demo card "박지훈 · FACING SEONGSU 코치" 탭해도 Test 로 들어감

### 신규 기능 후보 (큰 작업)
- [ ] PHASE5 §1.3 사장 폰 회원 list+상세 6탭 (1주 plan)
- [ ] PHASE4 P0 잔여 — Toss 빌링키 자동결제·재시도·grace / 듀얼 포지셔닝 B2B2C
- [ ] 폰 사장 편집 UI 확장 (`gym_profile_edit_screen` 9 필드 + 신규 `coach_profile_edit_screen`)
- [ ] 회원 가입 흐름 e2e 시연 (폰 가입 신청 → PC 사장 승인 → 회원권 발급 → 폰 카드 갱신)
- [ ] 전자계약서 PC→폰 전자서명 흐름 e2e 시연
- [ ] 폰 APK 실기 Galaxy S22 설치 (집 도착 시 — memory `project-pending-phone-apk-install` 참조)

## 결정사항 / 주의

### Volume 영속성 (큰 깨달음)
- 어제 PC 어드민에서 채운 박스 프로필 9 필드 + WOD 4개가 Volume 마운트 후에도 영속됨
- 즉 Volume 안 데이터 보존 잘 됨 → 다음 wipe 위험은 Volume 자체 detach 시점에만 발생
- entrypoint.sh + gosu 패턴이 Postgres·Redis 공식 이미지가 쓰는 정식 패턴이라 보안 OK

### 배포 흐름 (검증된 시퀀스)
1. services/facing 코드 변경 → commit → `git push origin master`
2. Railway 자동 빌드 (DOCKERFILE 빌더, 보통 2~4분)
3. health 200 polling 으로 검증 — but health 가 commit SHA 안 보여주므로 Railway 대시보드 ACTIVE 확인이 더 확실
4. Volume 마운트 변경 시 Railway 자동 재배포 → entrypoint 가 chown 처리

### Flutter prod APK 빌드 패턴
- `flutter build apk --release --dart-define=API_BASE_URL=https://service-facing-production.up.railway.app`
- 빌드 시간 ~78s (캐시 있는 경우)
- 산출물: `build/app/outputs/flutter-apk/app-release.apk` (~60MB)
- `adb install -r` 으로 emul 또는 실기 install (`-r` = SharedPreferences 보존)

### 시드 스크립트 한계
- `seed_demo.py --prod` 는 admin JWT 로 회원·회원권·클래스만 INSERT
- 박스 프로필 9 필드 + WOD 4개는 device-hash 인증이라 PC 어드민 수동 또는 백엔드 admin override 필요

### 인증·세션
- prod URL 보는 새 APK 도 SharedPreferences 보존되어 박지훈 코치 세션 그대로 진입 — 새 로그인 안 해도 됨
- 박지훈 = Test 박스 OWNER + FACING SEONGSU 코치 동시 소속 (시드 데이터 inconsistency)

### 시연 계정
- boss_seongsu / 1234 (FACING SEONGSU, gym_id=2)
- admin / 1234 (글로벌 데모 — 모든 환경 자동 시드)
- DEMO 계정 카드: 박지훈(코치)·김도윤(회원)·송예준(개인)·최서윤(가입대기) — Athlete/Coach 모드 진입 시 박스 선택 화면 거침

## 이번 세션 commit (로컬 + push 상태)

| repo | 주요 commit | push |
|---|---|---|
| services/facing | `2b08438` fix(deploy): Railway Volume 권한 영속 fix (entrypoint.sh + gosu drop) | ✓ |
| web/facing-admin | (변경 없음) | - |
| apps/facing-app | 어제 `70d9172` chore(handoff) 1 commit ahead | (대기) |

## 외부 자료 / URL

- 프로덕션 백엔드: https://service-facing-production.up.railway.app
- 프로덕션 어드민: https://web-facing-admin-production.up.railway.app
- 시드 스크립트: `web/facing-admin/scripts/seed_demo.py`
- Volume entrypoint: `services/facing/entrypoint.sh` (신규)
- API client 환경변수: `apps/facing-app/lib/core/api_client.dart:11` (`API_BASE_URL` dart-define)

## 다음 세션 권장 첫 프롬프트

`/resume`

그 후 우선순위:
- (a) **백엔드 admin override 시드 endpoint 추가** — 박스 프로필 9 필드 + WOD 자동화 인프라 (다음 wipe 대비, 1시간+)
- (b) **코치 프로필 시드 (gym_coach_profiles)** — 어제부터 진행 중인 항목 마무리
- (c) **PHASE5 §1.3 사장 폰 회원 list+상세 6탭** 본격 시작 (1주 plan)
- (d) **untracked 정리 + apps/facing-app commit push** (가벼운 위생 작업)
