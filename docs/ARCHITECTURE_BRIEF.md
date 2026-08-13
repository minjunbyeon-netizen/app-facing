# facing — 시스템 아키텍처 브리프 (SSOT)

> **작성일**: 2026-05-22
> **상태**: 합의 완료 — 이후 모든 작업의 중심 문서
> **적용 범위**: `apps/facing-app` (폰) + `web/facing-admin` (PC) + `services/facing` (백엔드)
>
> ⚠️ **이 문서가 우선이에요.** 코드 변경·새 기능 설계 시 이 브리프와 충돌하면 브리프를 따르고, 브리프를 바꿔야 한다면 사용자 명시 승인 후 문서 먼저 갱신해요.

---

## 0. 한 줄 요약

> **폰은 일상, PC는 운영. 백엔드는 단일 진실. 역할은 회원·코치·사장 3개. 실시간 동기화는 SSE.**

**시스템 카테고리**: CrossFit 박스 전용 **Vertical SaaS for Gym** (B2B2C · 멀티테넌시 + flat RBAC 3-tier + 실시간 SSE). 해외 동종: Wodify·PushPress·Mindbody. 아키텍처 패턴·법규·학술 근거 SSOT → `~/.claude/reference/study/gym-management-saas.md` (15 sub-topic · 94 source).

---

## 0.1. PHASE4 시작 (2026-05-23)

> **상태**: PHASE3 P0 18 + P1 24 + P2 14 = 56 task 완료 후 진입 예정. 본 섹션은 PHASE4 계획 선등록.
> **상세 로드맵**: `docs/PHASE4_ROADMAP.md`

### 0.1.1. PHASE4 목표 — 듀얼 포지셔닝 확립

**"linko 는 운영, facing 은 운영 + 선수."**

linko.my (한국 1위급, 350+ 박스) 의 운영 자동화 7 모듈을 흡수하면서, facing 만의 선수 도구 4 모듈을 동시에 강화해 패스트팔로워 함정을 회피한다.

### 0.1.2. 11 모듈 요약

**흡수 7 모듈 (linko.my 추격)**:
1. §1.1 예약 시스템 (Class Reservation) — **P0** 1주
2. §1.2 카카오 알림톡 알림 자동화 — **P0** 3일 + NHN 사전심사 1주
3. §1.3 전자계약 (e-Sign, PDF, audit hash) — **P0** 1주
4. §1.4 다지점 그룹 (gym_group + RLS) — P1 2주
5. §1.5 Toss 빌링키 자동결제 + 재시도 + grace period — **P0** 1주
6. §1.6 WOD 디자인 도구 + 월간 캘린더 + 복붙 — P1 1주
7. §1.7 AI 코칭 보조 (Claude API, HITL 의무) — P2 3일

**차별 강화 4 모듈 (facing 만)**:
8. §2.1 W-prime·CGM 페이싱 알고리즘 정밀화 — **P0** 2주
9. §2.2 5-Tier Engine 백분위 + 박스 leaderboard — P1 3일
10. §2.3 Games 선수 어휘·톤 PC 확장 — P2 2일
11. §2.4 듀얼 포지셔닝 B2B2C 데이터 브릿지 — **P0** 1주

**P0 총 공수**: ~6.4주 (parallel 시 ~5주) / **전체**: ~9~10주

### 0.1.3. B2B2C 데이터 브릿지 흐름

```
[폰 facing-app]               [PC facing-admin]
  회원 1RM·Engine·Tier   →    회원 등록 시 hydrate
        ↓                            ↓
    [services/facing 백엔드]
        ↓
   [linko 운영 자동화 흡수]
   예약·알림톡·전자계약·다지점
```

회원이 facing-app 으로 입력한 1RM·Engine·Tier → 박스 가입 시 코치에게 자동 공유 (PIPA §22 별도 동의). linko 가 따라올 수 없는 B2B2C 융합 영역.

---

## 0.5. 인프라 카탈로그 (헷갈림 차단 — INDEX)

### 0.5.1. 포트 · URL · 환경

| 컴포넌트 | 로컬 URL | Flask 환경 | 에뮬레이터 호출 URL | 실기/배포 호출 URL | 비고 |
|---|---|---|---|---|---|
| **백엔드** `services/facing` | `http://localhost:5060` | `debug=True` (Werkzeug dev) | `http://10.0.2.2:5060` | `http://<LAN-IP>:5060` 또는 Railway URL | 폰·PC 둘 다 호출. host=`0.0.0.0` 으로 LISTEN |
| **PC 사장 웹** `web/facing-admin` | `http://localhost:8081` | `debug=True` (Werkzeug dev) | (해당 없음) | (Phase 2 후반 Railway) | **5060/5061 은 Chrome `ERR_UNSAFE_PORT` 차단**. 8081 사용 필수 |
| **폰 앱** `apps/facing-app` | (해당 없음) | Flutter | `flutter run` 시 `--dart-define=API_BASE_URL=http://10.0.2.2:5060` | release APK 빌드 시 `--dart-define=API_BASE_URL=http://192.168.x.x:5060` 또는 배포 URL | base URL 미지정 default = `10.0.2.2:5060` (에뮬레이터 전용) |

### 0.5.2. 데이터베이스

| 컴포넌트 | 경로 | 형식 | git 추적 | 비고 |
|---|---|---|---|---|
| 백엔드 메인 DB | `services/facing/data/facing.db` | SQLite | **추적 X** (.gitignore) | 페르소나·박스·WOD·결과 등 모든 진실 |
| 백엔드 WAL | `facing.db-wal` / `facing.db-shm` | SQLite WAL | 추적 X | 자동 생성 |
| PC 사장 mockup | `web/facing-admin/data/mock_*.json` | JSON | 추적 O (회의 데모용) | Phase 1.5 에서 `facing.db` 의 신규 6 테이블로 마이그레이션 → 폐기 |
| 페르소나 SSOT | `services/facing/data/personas.json` | JSON | 추적 O | 시드 스크립트 입력 |

### 0.5.3. 환경변수

| 변수 | 위치 | 값 | 용도 |
|---|---|---|---|
| `SECRET_KEY` | `C:/dev/.env` (글로벌) 또는 `services/facing/.env` | 사용자 정의 (없으면 default `facing_default_salt`) | device_hash 솔트. 변경 시 페르소나 해시 모두 어긋남 |
| `PORT` | `services/facing/.env` | 5060 | 백엔드 포트 (글로벌 PORT 와 분리) |
| `APP_TEST_ADMIN_ID` / `APP_TEST_ADMIN_PASSWORD` | `C:/dev/.env` | 사용자 정의 | 슈퍼관리자 시드 (CLAUDE.md §3-A) |
| `ANTHROPIC_API_KEY` | 배포 PaaS 만 (Railway 콘솔) | Anthropic key | **로컬 .env 에 절대 X** (CLI 우회용) |
| `API_BASE_URL` | Flutter dart-define (빌드 시) | URL | facing-app 백엔드 호출 base |

### 0.5.4. 데모 계정 (의무 시드)

| ID | PW | 권한 | 시드 위치 |
|---|---|---|---|
| `admin` | `1234` | 슈퍼관리자 (모든 환경 시드) | 백엔드 부팅 시 자동 |
| `${APP_TEST_ADMIN_ID}` | `${APP_TEST_ADMIN_PASSWORD}` | 슈퍼관리자 (env 있을 때만, 프로덕션 skip) | env 기반 |
| `boss_seongsu` | `1234` | HYPHEN 사장 (PC 웹) | Phase 1 마이그레이션 |
| `coach_park` | `1234` | HYPHEN 코치 (폰 페어링 가능) | Phase 1 |

폰 페르소나 4명 (`persona-coach-park-2026` 등) 은 device_id 시드로 별도. 위 ID/PW 계정은 PC 사장 웹 로그인 전용.

### 0.5.5. 자주 헷갈리는 점

- ⚠️ **에뮬레이터 `10.0.2.2`** 는 Android 가상 호스트 PC 별칭. 실기는 LAN IP (예: `192.168.1.100`) 또는 배포 URL.
- ⚠️ **`localhost:5061` Chrome 에서 안 열림** — SIP-TLS 표준 포트라 차단. 사장 웹은 8081.
- ⚠️ **`SECRET_KEY` 변경하면 페르소나 해시 다 어긋남** — 시드 재실행 필요. 회의 직전엔 default salt 유지.
- ⚠️ **Windows bash + curl 한글 payload 깨짐** — 검증용으로 curl 쓸 때만. 폰·웹 폼은 정상 (UTF-8 자동).
- ⚠️ **debug APK 약 178MB / release APK 약 30MB** — 회의 시연은 페르소나 스위처 필요 → debug 필수.

---

## 1. 시스템 구성

```
                      ┌────────────────────────┐
                      │ Backend (Flask+SQLite) │
                      │  services/facing       │
                      │  단일 진실 (SSOT)      │
                      └───┬────────────────┬───┘
                          │ REST + SSE     │ REST + SSE
                          │                │
              ┌───────────▼──────┐   ┌─────▼──────────────┐
              │ 폰 앱 (Flutter)  │   │ PC 웹 (Flask)      │
              │ apps/facing-app  │   │ web/facing-admin   │
              │                  │   │                    │
              │ 회원 + 스태프    │   │ 스태프 전용        │
              │ (회원은 여기만)  │   │ (사장 = 코치)      │
              └──────────────────┘   └────────────────────┘
```

- **백엔드 1개** (`services/facing`, Flask + SQLite) — 단일 진실 (SSOT)
- **클라이언트 2개** (§2-0 대전제 2·3)
  - **폰** (`apps/facing-app`, Flutter): 회원의 **유일한** 창구 + 스태프 보조 운영
  - **PC 웹** (`web/facing-admin`, Flask + 바닐라 HTML/CSS/JS): 스태프(사장·코치·매니저) 주 창구
- **통신**: REST + SSE (Server-Sent Events)

> **회원용 웹 화면은 만들지 않는다 (강제·차단).** 회원이 PC 로 이 서비스를 쓸
> 일도, 그럴 가치도 없다. 회원의 창구는 폰 앱 하나뿐이고, 백엔드가 회원에게
> 내주는 것은 JSON API 뿐이다. 브라우저 화면은 코치·사장용 PC 웹 하나다.
> (2026-08-12 — 시험 삼아 만들었던 회원 모바일 웹 `/m` 은 삭제. 재도입 금지.)

폰과 PC 가 같은 DB·같은 API 를 다른 화면으로 본다는 게 핵심이에요. 클라이언트는 따로지만 데이터는 한 곳.

**PHASE4 B2B2C 확장 (§0.1.3 참조)**:

```
[폰 facing-app]                    [PC facing-admin]
  회원 1RM·Engine·Tier     →       회원 등록 시 hydrate
  (device_hash 익명 → 동의 연결)         ↓
        ↓                     코치 클래스 12명 페이싱 카드
    [services/facing 백엔드 — 단일 진실]
        ↓
   [PHASE4 운영 자동화 흡수]
   예약·카카오 알림톡·전자계약·다지점·Toss 빌링키
```

---

## 2. RBAC — 역할은 셋뿐 (코치 · 회원 · 회원신청자)

### 2-0. 3면 공통 대전제 (강제·차단 · 2026-08-12 사용자 지시)

> **이 3줄이 facing 전체(앱·PC 웹·백엔드)의 상위 규칙이다.** 아래 표·D 결정·각 repo
> CLAUDE.md 는 전부 이것의 각론이다. 충돌하면 **이 3줄이 이긴다.**

| # | 규칙 | 뒤따르는 금지 |
|---|---|---|
| **1** | **사장 = 매니저 = 코치 = 운영 권한.** 셋을 권한으로 가르지 않는다 | 코치라서 막는 분기 신설 금지 (nav·버튼·API 전부). 새 스태프 엔드포인트는 `@require_staff` 하나 |
| **2** | **회원은 폰(앱)에서만 쓴다** | 회원용 웹 화면·템플릿·로그인 페이지 신설 금지. 백엔드가 회원에게 주는 것은 **JSON API 뿐** |
| **3** | **사장·코치는 PC 에서도 쓴다** (PC 가 주, 폰이 보조) | "사장은 폰 안 씀"·"코치는 PC 안 씀" 같은 전제 금지. 스태프 기능은 양면 모두에서 도달 가능해야 한다 |

**규칙 1 에 예외는 없다 (D37, 2026-08-12).** 회원 이름·연락처·생년월일 전부 스태프
평문이다. 구 PII 마스킹(D30)은 폐기 — 아래 D37 참조.

**규칙 2 의 배경** — 회원 모바일 웹 `/m` 은 2026-08-12 전부 삭제됐다. 재도입 금지.
회원 화면 검증은 앱(에뮬레이터·실기)으로 한다. "브라우저로 대신 확인" 경로를 다시 만들지 말 것.

**규칙 3 의 현재 배선** — PC = `web/facing-admin` (주) · 폰 = `apps/facing-app` 사장 화면 (보조).
둘 다 같은 백엔드·같은 세션 계정(ID/PW)을 쓴다.

**규칙 1 의 이름은 넷뿐 — 정본 = `services/facing/api/roles.py` (강제·차단).**

| 쓸 것 | 뜻 |
|---|---|
| `STAFF_ROLES` | 운영 권한 역할 목록 `("boss","manager","coach")`. **다른 파일에서 재정의 금지** |
| `@require_staff` | 스태프 엔드포인트의 **유일한** 게이트 데코레이터 |
| `is_staff(role)` | 함수 중간 분기용 판정 |
| `FORBIDDEN_STAFF_MSG` | 거절 문구 — "운영 권한이 필요합니다." 하나 |

한국어 용어도 **"운영 권한"** 하나로 쓴다 ("사장 권한"·"권한 부족" 금지).
역할 목록을 인자로 받는 게이트(`require_role([...])` 류)는 만들지 않는다 — 호출부마다
목록이 갈려 매니저가 코치보다 낮아지는 역전을 낳은 장본인이다.

**2026-08-12 통일 — 여섯 이름이 흩어져 있던 것을 위 넷으로 합쳤다 (옛 이름·별칭 전부 삭제).**

| 없어진 이름 | 있던 곳 | 문제였던 점 |
|---|---|---|
| `BOSS_LEVEL_ROLES` | `api/admin.py` | 같은 튜플이 두 파일에 |
| `_STAFF_ROLES` | `api/classes.py` | 〃 — 한쪽만 열려 사고 |
| `require_boss` | `api/admin.py` (71곳) | 이름이 "boss" 라 스태프 게이트인 줄 모름 |
| `require_role([...])` | `api/admin.py` (10곳) | 호출부마다 목록이 달라 매니저 역전 |
| `_require_boss` · `_require_boss_or_coach` | `api/contracts.py` | 파일 자체 게이트 — 공용 상수를 안 봄 |
| `_require_admin_role` | `api/classes.py` | 사용처 0, 권한 재분할의 씨앗 |

**회귀 방지** — `services/facing/tests/test_rules_prem.py` 9개가 이 3줄을 코드로 강제한다.
`boss` 는 통과시키면서 `coach`/`manager` 를 막는 게이트(튜플·단일비교 양쪽)를 정적 검사로
잡고, **역할 목록이 `roles.py` 밖에 또 정의되는 것**과 **거절 문구가 갈리는 것**까지 막는다.
백엔드 HTML 렌더 0개·삭제된 회원 웹 미부활·폐기 전제 주석 재등장도 함께 본다.
인가 게이트만 골라내려고 "403 을 뱉는가"로 판정한다 (신원 환산용 role 분기는 정상이라 제외).

**실호출 검증 (2026-08-12, 신규 임시 DB · boss_seongsu·coach_park·mgr_test)**
계약서 9종 + 가입코드 발급 1종 × 3역할 = **30콜 전부 게이트 통과 (403 0건)**.
쓰기 엔드포인트는 빈 본문·없는 id 로 호출해 400/404 를 받아 **데이터는 안 바꿨다**.
비로그인 7콜은 전부 401 — 게이트를 없앤 게 아니라 스태프에게만 연 것이 맞다.

> ⚠ **로컬 dev DB 스키마 드리프트** — `data/facing.db` 의
> `ck_gym_manager_role` 이 `('boss','coach')` 라 **매니저 계정을 아예 못 만든다**
> (운영·신규 DB 는 `('boss','manager','coach')` 로 정상). 매니저 역전 버그가 오래 살아남은
> 이유가 이것이다 — 로컬에서 재현이 불가능했다. 위 검증을 신규 임시 DB 로 돌린 이유.


### 2-0-1. 역할은 **딱 셋** (강제·차단 · 2026-08-12 사용자 지시 = D35)

> "코치(사장이자 매니저이자 모든 것) · 회원 · 회원신청자(뉴비) 딱 3개밖에 없다."
> 넷째 역할을 새로 만드는 제안·코드·문서는 **전부 반려**한다.

| 역할 | 클라이언트 | 권한 | 백엔드 값 (계약 — 그대로 둠) |
|---|---|---|---|
| **코치** | **PC 주 + 폰 보조** | 박스 운영 **전권**. 회원 DB CRUD·회원권·락커·전자계약·통계·WOD 게시·수업·가입 승인·쪽지. PII 전부 평문 (D37) | `gym_managers.role ∈ (boss, manager, coach)` — **셋 다 같은 코치** |
| **회원** | **폰 전용** | 자기 WOD·결과 저장·수업 예약·박스 공지·코치에게 쪽지·배지·tier | `gym_members.status = approved` |
| **회원신청자** | **폰 전용** | 가입 신청서 제출·심사 결과 확인까지. 박스 콘텐츠 열람 불가 | `gym_members.status = pending` |

- **super admin (서비스 운영자 = 사용자 본인) 은 아직 없다.** 필요해지면 그때 넷째로 추가한다
  — 지금 자리를 미리 파두지 않는다 (사용자 명시: "이건 나중에 하기로 한다").
- 사람이 읽는 말은 위 셋뿐이다. 사장·오너·매니저·짐매니저·관리자는 **제품에 없는 말**
  (표기 정본 = `docs/GLOSSARY.md`, 자동 게이트 = `test/copy_lint_test.dart`).
- **백엔드 enum 은 이번에 바꾸지 않는다** — `boss|manager|coach` 3값은 DB·API 계약이라
  3면 동시 수정이 필요하다 (§0-B). 지금 통일된 것은 **개념과 표기**이며, 게이트는 이미
  `STAFF_ROLES` 하나라 권한상 차이는 **이미 0** 이다. 값 정리는 별도 승인 작업.
- **거부됨(rejected)·탈퇴(left) 는 역할이 아니라 상태다.** 회원신청자의 심사 결과일 뿐,
  넷째 역할로 세지 않는다.

> **D29 (2026-08-12 사용자 결정) — 코치 = 사장.** 코치에게 수업 삭제를 포함한 운영 권한 전부 부여.
> 구 정의(회원 권한 + WOD 게시·회원 목록·쪽지·피드백·가입 승인)는 폐기.
>
> - 구현 지점 1곳: `services/facing/api/roles.py` `STAFF_ROLES`
>   — `@require_staff` 를 쓰는 모든 엔드포인트의 접근 주체를 이 상수가 정한다.
>   되돌리려면 이 한 줄을 `("boss",)` 로 좁히면 끝 (2026-08-12 이름 통일 후).
> - `web/facing-admin` 은 nav·버튼의 coach 분기를 전면 제거 (`_layout.html`·`members.html`).
> - PII 마스킹은 D30 에서 이름만 열었다가 **D37 에서 통째로 폐기**됐다 (아래).
> - **manager 포함** (2026-08-12 후속). 코치만 올리면 manager < coach 역전이 생겨
>   `STAFF_ROLES = ("boss", "manager", "coach")` 로 함께 정리했다.
> - 클래스 CRUD 의 인라인 role 체크도 같이 열었다 — 데코레이터가 아니라 함수 안
>   `if` 라 상수 변경만으로는 안 열렸다. 지금은 그 자리도 `is_staff()` 를 본다.
>
> **실기 검증 (2026-08-12, 로컬 5060 · coach_park/1234)**
> 락커·계약서·요금제·코치목록·회원목록·대시보드·알림설정·클래스목록 8종 전부 200,
> 수업 생성(201)→수정(200)→명단(200)→취소(200) 4단계 통과. 타 박스 클래스는 403 유지
> (테넌트 격리 정상). 당시 PII 는 코치에게 마스킹돼 있었다 — D37 에서 폐기.

> **D30 (2026-08-12) — 코치는 회원 '이름' 만 평문.** → **D37 로 대체됨 (폐기).**
> 마스킹을 항목 단위로 조금 열어 본 중간 단계였다. 반나절 만에 같은 문제가
> 연락처에서 다시 터져 마스킹 자체를 없앴다. 기록만 남긴다.

> **D37 (2026-08-12 사용자 결정) — 코치 PII 마스킹 전면 폐기. 규칙 1 에 예외 없음.**
> 코치는 한 명뿐이고 그 사람이 박스를 통째로 운영한다. 명단에서 "누가 예약했는지" 를 봐도 번호가 `010-****-0002`
> 면 결석 연락·대기 승격 안내를 못 한다. "권한은 같게, 개인정보만 최소권한" 이라는
> 축 분리는 이 박스의 운영 실제와 맞지 않았다.
>
> - 삭제: `api/admin.py` 의 `ROLE_SCOPES` · `_viewer_scope()` · `_mask_pii()` (별칭도 없음).
>   호출부는 회원 목록(`/admin/gyms/<id>/members`)과 명단(`/admin/classes/<id>/reservations`) 둘.
> - 응답에서 `viewer_scope` 필드도 사라졌다 (소비처 0곳 확인 후 제거).
> - 회원 개인정보 보호는 **테넌트 격리**(`assert_gym_match`) + **감사로그**(`AuditLog`)가 맡는다.
>   남의 박스 회원은 애초에 404 라 마스킹이 방어선이었던 적이 없다.
> - **재도입 금지** — `tests/test_rules_prem.py::test_no_pii_masking_for_staff` 가
>   심볼 부활과 "전화번호를 별표로 덮는 새 코드" 양쪽을 정적 검사로 잡는다.

> **D38 (2026-08-12 사용자 지시) — 코치 계정 관리 기능 전면 폐기.**
> "이건 그냥 코치 한 명이 회원관리 앱으로 쓰는 것" — 코치를 여러 명 두고 뽑고
> 내보내는 전제 자체가 이 제품에 없다.
>
> - 삭제(백엔드): GET/POST/PATCH/DELETE `/api/v1/admin/gyms/<id>/coaches[...]` ·
>   페어링 코드 재발급 · `POST /api/v1/coach/pair` · `_make_pairing_code` ·
>   `_pairing_expired` · `PAIRING_CODE_TTL_HOURS` · 세션·응답의 `employment_type`
> - 삭제(PC 웹): `/coaches` 라우트 + `templates/coaches.html` + 좌측 nav '코치' +
>   수업 생성·수정 모달의 '담당 코치' 선택과 코치 매핑 JS
> - 삭제(시드): 마스킹 검증용으로만 있던 '알바 코치' 계정 + 고용형태 값
> - **남긴 것**: 코치 **프로필**(`/api/v1/gyms/<id>/coaches`) — 회원 앱 박스 소개
>   카드에 쓰는 공개 정보라 계정 관리와 다른 기능이다
> - **휴면 컬럼**: `gym_managers.pairing_code` · `pairing_code_issued_at` ·
>   `employment_type` — 2026-08-13 사용자 승인으로 **DROP 완료** (아래 D40)
> - 재도입 금지 — `tests/test_rules_prem.py::test_no_staff_management` 가 감시

> **D40 (2026-08-13 사용자 승인) — 계약서 읽는 표 일원화 + 휴면 스키마 DROP.**
>
> - **계약서 정본은 `contract_instances` 하나.** 발급(POST)은 템플릿 기반
>   ContractInstance 를 쓰는데 회원 상세의 조회(GET)만 레거시 `gym_contracts` 를
>   읽고 있어, 계약서를 발급해도 그 탭이 **영원히 "계약서 없음"** 이었다.
>   `GET /api/v1/admin/members/<id>/contracts` 를 `api/contracts.py` 로 옮겨
>   ContractInstance 를 읽게 하고, `api/admin.py` 의 레거시 핸들러 3개
>   (회원별 목록 · 박스 전체 목록 · `POST .../contracts/<id>/sign`)는 삭제했다.
>   개인정보 export(`api/privacy.py`)도 같은 표를 본다.
> - **DROP (`models/base.py::_migrate_drop_dormant`, 부팅 시 idempotent)**:
>   표 `gym_contracts`(0행일 때만) · `member_claim_codes` /
>   컬럼 `gym_managers.pairing_code` · `pairing_code_issued_at` ·
>   `employment_type` · `user_id`, `gym_members.claim_code` ·
>   `claim_code_expires_at` · `user_id`.
>   `user_id` 는 소셜 계정 역참조인데 실제 연결은 `social_accounts.device_hash` ·
>   `staff_login_id` 가 하고 있어 모델에도 없던 죽은 컬럼이다.
> - 곁가지: `gym_managers` 를 모델 DDL 로 다시 만들면서 옛 role CHECK
>   (`boss`·`coach` 뿐이라 `manager` 를 못 넣던 것)가 모델 기준으로 맞춰졌다.

> **D31 (2026-08-12) — 명단에서 출석 체크 + 대기 순번 정정.**
>
> - **대기 순번**: `class_waitlist_promotions.promoted_position` 은 "줄 설 때" 번호라
>   앞사람이 승격·이탈해도 안 줄어든다 (실측: 대기 1명인데 화면엔 `대기 4`).
>   표시용 순번은 `api/classes.py _current_waitlist_position()` 으로 **매 조회마다 다시 센다**.
>   적용 3곳: 관리자 명단 · 회원 클래스 목록(`my_waitlist_position`) · 회원 예약 목록.
>   저장 컬럼은 이력용으로 보존하고 명단 응답에 `original_position` 으로 함께 내려준다.
> - **출석 체크**: `PATCH /api/v1/admin/reservations/<id>/status`
>   `{status: confirmed|attended|no_show}`. `cancelled` 는 의도적으로 거부 —
>   예약 취소는 회원 DELETE / 클래스 전체 취소 경로에만 있어야 이력이 남는다.
>   스태프(`is_staff()`) 전용 · 박스 일치 검사 · `AuditLog(class.reservation_status)` 기록.
> - **gym_attendances 동기화**: '출석' 시 그날 출석행이 없으면 `source='manual'` 1건 생성
>   (통계가 `distinct(member_id)` 라 QR 과 겹쳐도 중복 집계 없음). 되돌릴 때는
>   **같은 날 다른 수업에 출석 표시가 하나도 안 남았을 때만** manual 행을 지우고,
>   `source='qr'` 행은 실제 출입 기록이라 어떤 경우에도 건드리지 않는다.
> - UI: 앱 `class_roster_sheet.dart` 행 우측 [출석][노쇼] FkBadge 토글(같은 배지 재탭 = 확정
>   되돌리기) + 상단 '출석' 카운터, 시트를 바꾼 채 닫으면 대시보드 재조회.
>   웹 `classes.html` 상세 모달 명단에 같은 규칙의 버튼 2개.
>   대기자·고아(탈퇴 회원) 행에는 버튼을 붙이지 않는다.
> - 검증 (로컬, 계정 coach_park·boss_seongsu·admin): 상태 왕복 4단계 `synced`
>   created→None→removed 기대대로, 같은 회원 하루 2수업 분기에서 첫 수업만 되돌렸을 때
>   출석행 유지 확인, 잘못된 status 3종 400, 타 박스 스태프 403.

> **D32 (2026-08-12) — 고아 행 정리 + FK 강제 실증.**
> D29 에서 "예약 2명인데 명단 0명" 을 만든 고아 데이터의 뿌리를 정리했다.
>
> - **원인**: SQLite FK 는 연결마다 켜야 강제된다. `models/base.py` 의 connect 이벤트가
>   `PRAGMA foreign_keys=ON` 을 거는데, **그 리스너가 붙기 전에 지워진 회원**의 자식 행이
>   남은 것이다. 지금은 정상 — 임시 회원+예약+프로필을 만들어 회원만 지웠을 때
>   자식이 함께 사라지는 것을 실증했다 (`PRAGMA foreign_keys = 1` 확인).
>   raw `sqlite3.connect` 경로는 2곳뿐이고(스키마 편집·Postgres 내보내기) 행 삭제를 안 한다.
> - **도구**: `services/facing/scripts/fix_orphans.py` — `PRAGMA foreign_key_list` 로
>   FK 를 introspect 하므로 테이블이 늘어도 그대로 쓴다. 기본은 점검만, `--apply` 로 삭제.
>   삭제 전 `data/backup/` 에 DB 스냅샷(`sqlite3.backup` — WAL 안전). `ON DELETE CASCADE`
>   인 FK 의 고아만 지우고, 그 외는 의도일 수 있어 보고만 한다.
> - **로컬 DB 결과**: 14건 삭제 (class_reservations 12 · class_waitlist_promotions 1 ·
>   gym_member_profiles 1, 전부 `gym_members` 참조). 이후 `PRAGMA foreign_key_check` 0건.
> - **⚠ 운영 DB 는 아직 안 함** — Railway 볼륨은 사용자 승인 후
>   `python scripts/fix_orphans.py --db /app/data/facing.db` 로 먼저 점검할 것.
> - 명단 API 의 `orphan` 처리(outerjoin + '탈퇴 회원')는 **그대로 둔다** — 운영 DB 가
>   아직 안 정리됐고, 데이터가 깨끗해져도 방어로서 값이 싸다.

> **D33 (2026-08-12 사용자 지시) — 회원 폰 WOD 탭 = 그 주 월~일 아코디언.**
> "WOD 들어가면 아직도 보기가 너무 힘들다" 는 지적에서 나온 화면 구조 결정.
>
> - **전**: 오늘 / 예정 / 지난 3섹션이 세로로 이어지고, 그 아래에 수업 목록이 또
>   따로 쌓였다. 같은 날 정보가 두 곳에 나뉘어 "오늘 뭐 하고 몇 시에 가나" 를 보려면
>   두 군데를 봐야 했다.
> - **후**: 한 주가 7줄로 고정된다 (월~일 + 날짜, 오늘 표시). 요일·날짜를 누르면
>   그 자리에서 **그날 WOD + 그날 수업(줄마다 예약 버튼)** 이 함께 펼쳐진다.
>   한 번에 하나만 열리고, 주 이동은 헤더의 ◀ ▶.
> - 코드: `lib/features/gym/week_board.dart` (신설) · WOD 행은
>   `lib/features/gym/wod_row.dart` 로 분리해 보드와 공유 · 예약·취소 흐름은
>   `features/classes/classes_screen.dart` 의 `reserveClassFlow`/`cancelClassFlow`
>   한 벌 (§3 코드 SSOT).
> - 수업은 주 단위 1회 조회 (`GET /api/v1/member/classes?from=월&to=다음 월`) —
>   요일마다 부르면 7배 왕복. 백엔드 변경 0건.
> - D25 의 "WOD 탭 = 코치 오늘 WOD" 는 유지 — 오늘이 기본으로 열린 날일 뿐,
>   책임이 바뀐 것은 아니다.

> **D34 (2026-08-12 사용자 지시) — 회원 프로필에서 ENGINE 섹션 내림.**
> "engine 은 우리가 쓸 데 없다" 는 지시. 3기둥(게이미피케이션·WOD 보드·프로필)
> 집중(v1.27)의 연장선이다.
>
> - **화면에서만 제외, 코드는 보존** (CLAUDE.md "숨김 = 코드 보존"). Tier 배지 ·
>   Engine 점수 · LV · 칭호 · 6 카테고리 칩 · 추세 delta · 약점 카드 일습은
>   `lib/features/mypage/score_section.dart` 로 옮겨 두었다 (`ScoreSection`).
>   되살리려면 `MyPageScreen` children 에 `ScoreSection()` 한 줄이면 된다.
> - 같은 데이터를 쓰는 **온보딩 `/onboarding/grade` · 벤치마크 시트는 그대로 산다** —
>   Engine 측정 자체를 없앤 결정이 아니다. 프로필에서 되비추던 자리만 없앴다.
> - 백엔드 계약 변경 0건 (`overall_number`·`overall_score`·카테고리 응답 그대로).
> - 함께 처리: WOD 행의 '완료 표시'를 FkBadge 로 내려 수업 줄의 예약·대기 배지와
>   같은 크기로 통일 ("지금도 좀 커서 거북하다"). 터치 48 은 FkBadge 가 내부에서
>   확보하므로 DESIGN-SSOT §3 터치 기준은 유지된다.

> **D35 (2026-08-12 사용자 지시) — 역할은 코치·회원·회원신청자 셋뿐.** 전문 = §2-0-1.
> 표기 정본 = `docs/GLOSSARY.md` (사장·오너·매니저·관리자는 제품에 없는 말, copy lint 게이트).
> super admin(서비스 운영자)은 나중에. 앱 문구 22곳 정리 + `role_labels.dart` 매핑 4종 → 코치.

> **D36 (2026-08-12 사용자 지시) — 회원 레벨은 경력 3단으로 통일.**
> "PC 에서 회원 레벨을 맞추는 것도 경력에 따라 나눈다."
>
> | 크로스핏 경력 | 레벨 |
> |---|---|
> | 1년 미만 | **SCALED** |
> | 1~3년 | **RXD** |
> | 3년 이상 | **ELITE** |
>
> - **구 방식 폐기**: "레벨은 앱 사용 기반 자동 산정"(2026-06-08 결정, `members.html` 주석)은
>   더 이상 기준이 아니다. Engine 점수와도 무관하다 (D34 로 프로필에서 ENGINE 을 내린 것과 같은 줄기).
> - 사다리는 **셋뿐** — `RX+`·`Games` 는 회원 레벨에 쓰지 않는다. WOD 결과 1건의
>   `scale_level` 도 같은 셋(`scaled`/`rx`/`elite`).
> - **아직 구현 안 됨 (미착수 — 이 결정은 규칙만 확정)**. 필요한 것:
>   1. 회원에게 **크로스핏 시작일**(경력 기산점) 필드가 없다 — `gym_member_profiles` 컬럼 추가 + 마이그레이션
>   2. `level` 산정 = 시작일→오늘 경과로 서버가 계산 (수기 입력 금지 — 두 기준이 갈리면 원점)
>   3. PC 회원 폼(`web/facing-admin/templates/members.html`)의 레벨 읽기전용 안내 문구 교체 +
>      시작일 입력칸 추가
>   → DB 스키마 적용은 사용자 확인 대상 (§4). 착수 전 이 3줄을 먼저 갱신할 것.

> **D38 (화면 쪽 각론) — 코치 '관리' 면 폐기. 결정 전문 = 위 D38 (§2 뒤).**
> "코치 관리 이딴 거 없다. 내가 곧 코치이자 사장이니까. 직원 고용은 나중 일."
>
> ⚠ 이 블록은 2026-08-12 밤에 **D37 번호로 적혔다가 D38 로 정정**됐다. 같은 날 두
> 세션이 각자 번호를 매겨 D37 이 두 번 쓰였다 — PII 폐기가 D37, 코치 관리 폐기가 D38 이다.
> (커밋 `8cb9a53` 의 메시지에 남은 "D37" 은 이 D38 을 가리킨다.)
>
> - **폐기 대상 = 코치를 *등록·고용·관리* 하는 면**. PC 온보딩 STEP 2 의 '코치 등록 +
>   페어링 코드' 카드와 `/coaches` 링크 3곳(구 페이지는 같은 날 이미 삭제) · 랜딩·통계의
>   "코치 관리/코치 설정" 문구 · 앱 프로필의 '직원 계정 연결' 행.
>   STEP 2 이름도 "코치 · 운영 설정" → **"수업 · 회원권"**.
> - **남긴 것 (관리가 아님)**: 박스 소개의 코치 소개 카드(회원이 코치가 누군지 보는 곳) ·
>   회원↔코치 쪽지 · 수업 담당 표기. 회원 관리(`CoachDashboardScreen`)는 이름만 coach 일 뿐
>   **회원**을 다루는 화면이라 그대로 둔다. `/auth/link-staff` 도 남는다 (소셜 계정에
>   본인 코치 계정을 잇는 1회용 화면이라 '관리' 가 아니다).
> - ⚠ **백엔드 코드는 보존이 아니라 삭제됐다** — 같은 날 후속 지시("그런 비슷한 것도
>   전부 없애라")로 코치 계정 CRUD·페어링·고용형태를 실제로 지웠다. 위 D38 본문 참조.
>   한때 이 자리에 "숨김 = 코드 보존" 이라고 적혀 있었으나 사실과 다르다.
> - 이 결정으로 D35 의 "역할 셋"이 화면에서도 참이 된다 — 관리할 넷째 주체가 없다.

> **D39 (2026-08-13 사용자 지시) — 가짜 데이터는 코드에서도 지운다.**
> "리스트 하드코딩된 거 전부 지워라. 테스트로 뒀던 것들 싹 지워."
>
> - **백엔드**: 가짜 회원·페르소나·더미 쪽지를 만들던 시드를 파일째 삭제.
>   부팅 시드 = 카탈로그 + 박스 + 로그인 계정(admin·슈퍼씨드)뿐. 고정 테스트
>   계정(coach/member/new)·기본 락커·요금제 시드도 없앴다.
>   청소 도구 = `services/facing/scripts/blank_slate.py` (미리보기 기본, --apply 시 백업).
>   로컬·운영 둘 다 적용 완료 (운영은 `railway ssh`).
> - **앱**: 가짜 CrossFit 시즌 일정(`core/season.dart`)과 그 위에 얹혀 있던
>   시즌 배지(`core/season_badges.dart`)를 삭제. 화면에 `* Mock schedule` 이라고
>   적힌 배너가 실제로 사용자에게 보이고 있었고, 실제 대회 일정과 무관한
>   날짜로 배지를 주고 있었다. 제거 지점 4곳 — 계산 진입 배너 · 업적 패널 ·
>   결과 화면 · 세션 화면.
> - **남긴 것**: `weak_insight.dart`(점수 기반 규칙 코멘트)는 D34 로 이미 화면에서
>   내려간 `score_section.dart` 만 참조한다 — 사용자에게 안 보여서 그대로 뒀다.
> - 재도입 금지. 데모가 필요하면 **시드가 아니라 그때 손으로** 넣는다.

- **사장은 운영자**, PHASE5 부터는 **외출·이동 중 폰 보조 운영 가능** (linko 격차 해소 — `docs/PHASE5_ROADMAP.md` 참조). PC 가 주, 폰이 보조. **폰 사장 로그인 = PC 동일 ID/PW** 사용. 회원·코치는 device_hash 익명 유지.
- 한 사람이 두 역할 가질 수 있어요 (예: 박지훈 = 사장 + 코치). DB 상으로는 `gym_managers` 에 두 행 (또는 role 컬럼 set 형).
- **PHASE5 추가 가정**: facing-app 진입 시 `user_type` 분기 — `device_hash` (회원·코치 익명) vs `login_id` (사장·매니저 ID/PW). 같은 앱 바이너리, 다른 진입 플로우.

---

## 3. 신규 가입 흐름 (가장 중요한 데모 흐름)

```
[현장]                      [폰 회원]                 [PC 사장]
────────                    ──────────                ──────────
체육관 방문
      │
      ▼
QR 또는 카운터 안내    →    1. 박스 찾기 화면
                            2. HYPHEN 선택
                            3. 가입 신청 (pending)
                                 │
                                 │ POST /join
                                 ▼
                                                      ─── SSE ───▶ 4. 알림 토스트
                                                                    "신규 신청 1건"
                                                                      │
                                                                      ▼
                                                                    5. 회원 카드 클릭
                                                                    6. 이름·생년·전화·
                                                                       회원권·락커 입력
                                                                    7. "승인 + 등록"
                                                                      │
                                                                      │ POST /admin/members
                                                 ◀─── SSE/Push ───   ▼
                        8. "등록 완료" 알림   ◀
                           NOTICE 탭에 박스
                           정보 카드 자동 노출
```

회의 데모 핵심 흐름. **폰에서 시작한 신청이 SSE 로 PC 사장 화면에 실시간 푸시**.

---

## 4. SSE 채널

```python
GET /api/v1/admin/events  → Server-Sent Events stream (사장 PC 구독)
GET /api/v1/member/events → 회원 폰 구독 (또는 30초 poll fallback)

이벤트 종류 (대표 — 전체 목록의 정본은 코드):
- member_join_request   : 폰 → 사장 (신규 신청)
- member.created        : 사장 PC → 구독자 (회원 등록)
- membership.issued     : 사장 PC → 구독자 (회원권 발급)
- wod.posted            : 코치 → 회원 (오늘 WOD 게시)
- wod_result.posted     : 폰 → 코치 (회원 결과 제출)
- note.new              : 폰·PC → 구독자 (1:1 쪽지 — payload preview·sender_name)
```

> **이벤트명 SSOT = 코드 두 곳** (2026-08-06 §0-B 정정): 발행 = `api/*.py` 의
> `sse_publish(gym_id, "<이름>", …)` 호출부(현재 35종) / 수신 = `facing-admin`
> `templates/_layout.html` 의 `_eventToastMap` 키. **두 목록의 키는 반드시 일치**해야 한다 —
> 어긋나면 토스트가 조용히 죽는다 (D28 에서 `message.received` 사문 발견). 명명 규약은
> 점 표기(`도메인.동작`)가 기본이며, 초기 도입분 일부(`member_join_request`·
> `attendance_checked`·`contract_issued` 등)는 밑줄 표기로 남아 있다.
>
> **2026-08-06 대조 결과**: 수신만 있고 발행 없는 사문 = 0건. 발행하지만 PC 토스트가 없는
> 10종(`coach.profile.updated`·`gym.profile.updated`·`locker.added`·`wod.deleted`·
> `membership.paused|resumed|updated`·`daily_plan.created|updated|deleted`)은 **전부
> PC 에서 시작한 동작**이라 자기 행동 되울림이 되므로 의도적 무음. 폰에서 시작하는 이벤트는
> 전부 토스트가 있어야 하며, 이 대조에서 `member.self_signup`(앱 자가가입) 누락을 발견해 추가했다.

- **모바일은 SSE 끊김 잦음** → 폰은 SSE 시도 + 실패 시 30초 poll fallback
- **PC 브라우저는 EventSource 안정적** → SSE 만

---

## 5. 데이터 모델 — 신규 테이블 6개

| 테이블 | 누가 쓰나 | 핵심 컬럼 |
|---|---|---|
| `gym_managers` | 운영자(코치) 계정 — 다중 박스 OK | gym_id, login_id, password_hash, role (boss/manager/coach — 셋 다 같은 '코치'), name, phone, device_hash, hired_at, left_at |
| `gym_member_profiles` | 사장 회원 DB | gym_id, member_id (FK), name, gender, birth_date, phone, level, preferred_time_slot, preferred_coach_gender, safety_note, note |
| `gym_memberships` | 회원권 관리 | member_id, plan_name, start_date, end_date, price, status (active/expired/refunded), refund_amount, refunded_at |
| `gym_lockers` | 락커 관리 | gym_id, locker_no, member_id, start_date, end_date |
| `contract_instances` | 전자계약 (정본 — 구 `gym_contracts` 는 D40 에서 DROP) | template_id, gym_id, member_id, status, variables, pdf_path, signed_pdf_path, signed_at, signature_* |
| `gym_attendances` | 통계용 | member_id, gym_id, checked_at, source (qr/manual) |
| `gym_inquiries` | 회원→사장 직접 문의 (환불·계약·분쟁) | gym_id, member_id, subject, body, status, responded_at |
| `audit_logs` | 개인정보 접근·변경 감사 | actor_login_id, action, target_member_id, payload_hash, created_at, ip |

기존 `gym_members` (device_hash 기반) 와 1:1 외래키. 폰은 device_hash 그대로 쓰고, PC 는 member_id 기반 + 사장 로그인.

**기존 `gym_members` 에 컬럼 추가**: `status` (`pending`/`approved`/`rejected`/`left`/`removed`), `left_at`, `left_reason` — **M14 자발적 탈퇴 처리** 위해 필요.

**`gym_managers` 다중 박스 (M7·M8)**: 한 login_id 가 박스 2곳 운영 시 두 행 INSERT (gym_id 다르게). PK = (gym_id, login_id) 복합키. 사장 로그인 시 박스 선택 토글 (또는 통합 대시보드).

기존 테이블 (유지): gyms · gym_members · gym_wod_posts · gym_wod_results · gym_messages · gym_announcements · gym_coach_feedback · gym_member_requests · gym_profile (박스 정보).

---

## 6. 사장 통계 — 게이미피케이션 빼고 운영 숫자만

```
┌─ 오늘 ────────────────────┐  ┌─ 이번 달 ──────────────────┐
│ 출석 회원   38명          │  │ 신규 가입       12명       │
│ WOD 게시    2건           │  │ 만료 회원       8명        │
│ 가입 신청   3건 (대기)    │  │ 만료 임박       5명        │
└───────────────────────────┘  │ 매출 추정    8,400,000원   │
                               └────────────────────────────┘
┌─ Retention ───────────────┐  ┌─ 락커 점유율 ──────────────┐
│ 3개월 retention   78%     │  │ A존  10/12 (83%)           │
│ 6개월 retention   62%     │  │ B존  16/22 (72%)           │
│ 1년  retention    44%     │  │ 만료 임박     2개          │
└───────────────────────────┘  └────────────────────────────┘
```

- **게이미피케이션(배지·streak·tier)** 은 회원 폰에는 그대로 유지 (회원 유지 동기), 사장 화면은 **숫자만**
- 사장 = 결정 빠르게 내릴 수 있는 운영 지표 중심

### 6.1 측정 알고리즘 (M13 — 통계 정의 명시)

| 지표 | 정의 | SQL 의사코드 |
|---|---|---|
| 오늘 출석 | 오늘(KST) `gym_attendances.checked_at` UNIQUE(member_id) 수 | `COUNT(DISTINCT member_id) WHERE DATE(checked_at)=today` |
| 이번 달 신규 가입 | 이번 달 안에 `gym_memberships.start_date` ≥ first_day_of_month | `COUNT WHERE start_date BETWEEN month_start AND month_end` |
| 만료 임박 | `end_date` 가 오늘로부터 14일 이내 + status=active | `WHERE end_date BETWEEN today AND today+14d` |
| 매출 추정 (이번 달) | 이번 달 시작된 회원권 price 합 + 갱신 매출 | `SUM(price) WHERE start_date IN month` |
| 3개월 retention | M-3 코호트(3개월 전 가입자) 중 지금까지 1회 이상 출석한 비율 | `cohort 가입자 N / 그 중 M+0~M+3 동안 attendance 1+ 인원` |
| 6개월 retention | M-6 코호트 | 동일 패턴 |
| 1년 retention | M-12 코호트 | 동일 패턴 |
| 락커 점유율 | `gym_lockers` 중 `member_id IS NOT NULL` 비율 | `COUNT(occupied) / COUNT(total)` |
| 여성 비중 (M10) | gym_member_profiles WHERE gender='여' 비율 | gender 분포 |
| 여성 시간대 분포 (M10) | preferred_time_slot 별 GROUP BY | bar chart |

retention 정의 = "코호트(가입 월) 의 N개월 후 시점에 attendance ≥ 1 인 비율". 출석 기록 없으면 "left" 로 간주 (자발적 탈퇴와 별개).

---

## 7. 인증·보안

| 플랫폼 | 인증 방식 | 비고 |
|---|---|---|
| 폰 (회원·코치) | device_hash (X-Device-Id 헤더) | ⚠️ **D26으로 대체 예정** — 소셜 로그인 통일. device_hash 는 데이터 연결키로 격하 |
| PC (사장) | ID/PW + 세션 쿠키 (httpOnly Secure) | ⚠️ **D26으로 대체 예정** — 사장도 소셜 로그인. ID/PW 는 전환기 fallback |
| 시드 계정 | `boss_seongsu / 1234` (데모) + `APP_TEST_ADMIN_*` env (슈퍼) | CLAUDE.md §3-A 의무 시드 |
| 출석 체크인 | 1회용 QR (60초 만료) | 박스 입구 디스플레이가 토큰 갱신, 폰이 스캔 → POST `/attendances` |
| 결제 (Toss Payments) | webhook HMAC-SHA256 서명 검증 + timing-safe compare + idempotency key | reference/payment.md + reference/webhook.md 준수 |

- 회원 개인정보(이름·생년·전화·서명)는 들어가는 순간 **개인정보보호법 적용**. 암호화·접근로그·감사 필수.
- 사장 mutation 액션(승인/연장/락커 배정)은 **GET 절대 금지** (CSRF). POST/PATCH/DELETE + CSRF 토큰.
- 결제 webhook idempotency: 같은 Toss orderId 두 번 들어와도 1회만 처리.

### 7.1 개인정보 보존·삭제 (M5 — 개인정보보호법 §29 준수)

| 데이터 | 보존 기간 | 삭제 시점 | 근거 |
|---|---|---|---|
| 회원 이름·전화·생년 | 회원 탈퇴 후 5년 (세무·소비자 분쟁 대비) | 5년 경과 자동 cron 으로 NULL 처리 (member_id 만 유지) | 국세기본법 §85-3 (5년 보존) |
| 전자계약서·서명 이미지 | 계약 종료 후 5년 | 동일 | 전자문서법 §5 |
| WOD 결과·페이싱 기록 | 영구 (운동 기록은 회원 자산) | 회원이 명시 요청 시 즉시 익명화 | GDPR §17 (삭제 권리), 개인정보보호법 §36 |
| 출석 기록 | 회원 탈퇴 후 1년 | 1년 경과 자동 익명화 (회원 단위 식별 제거, 통계 카운트만 유지) | 통계 가치 vs 최소 보존 원칙 |
| audit_logs | 영구 (위변조 방지) | 절대 삭제 X | 정보통신망법 §29 (감사로그) |

**회원이 "삭제 요청" 시**: 사장 PC 화면에서 "개인정보 삭제" 버튼 → 30일 유예 → 자동 NULL 처리. audit_logs 에는 "deletion_requested_at" 만 남김.

---

## 8. 게이미피케이션 정책

- **회원 폰** — 배지·tier·streak·season 유지. 회원 유지율 핵심 가치.
- **사장 PC** — 게이미피케이션 노출 X. 사장은 운영 숫자만.
- **코치 폰** — 회원 게이미피케이션 진행도 조회 가능 (코칭 도구), 단 사장처럼 retention 통계는 X.

---

## 9. 빌드 우선순위

| Phase | 작업 | 무게 |
|---|---|---|
| **1. 백엔드 기반** | 신규 6 테이블 마이그레이션 + 사장 로그인 + SSE 채널 | 2일 |
| **1.5. 결제·체크인·푸시** | Toss Payments 통합 + QR 출석 체크인 + FCM 푸시 (D13·D14) | 1.5일 |
| **2. PC 사장 화면 풀** | 회원 DB CRUD + 회원권 3-tier (D9) + 락커 + 통계 대시보드 (여성 비중 D10 포함) + 전자계약 + SSE 알림 + churn win-back UI (D8) | 3일 |
| **3. 폰 가입 흐름 연동** | 박스 찾기 → 신청 → SSE 푸시 알림 수신 → 박스 정보 hydrate + first-week buddy 자동 메시지 (D11) | 1.5일 |
| **4. 폰 코치 모드 보강** | 사장 등록 회원과 device_hash 매핑 + 회원 목록 동기화 + buddy assign UI | 1일 |
| **5. 사용성 테스트** | 사장 5명·회원 5명 think-aloud 30분 (D14, Nielsen) → 발견 이슈 hotfix | 1일 |

총 약 10일 풀빌드. mockup (`web/facing-admin` v0.2) 은 이미 1번 일부 + 2번 부분 완료 상태.

---

## 10. 결정 사항 / 합의

| # | 결정 | 근거 |
|---|---|---|
| D1 | 백엔드 1개 (services/facing) — 분리 X | SSOT 단일성, 작업·인증 일관성 |
| D2 | ~~폰은 device_hash 익명 유지~~ → **D26으로 대체** (소셜 로그인 통일) | 회원 가입장벽 ↓, 기존 코드 호환 |
| D3 | ~~사장은 ID/PW 로그인~~ → **D26으로 대체** (사장도 소셜) | 개인정보 다루므로 신원 식별 필수 |
| D4 | SSE 사용 (WebSocket X) | 단방향 푸시면 충분, Flask Werkzeug 호환 |
| D5 | 사장 화면 게이미피케이션 X | 운영자 결정 속도 중심, 숫자만 |
| D6 | 폰·PC 모두 같은 박스(gym_id) 기반 | RBAC 가 gym 단위로 분리 |
| D7 | 신규 가입 = 폰 시작, PC 완성 | 사용자가 명시한 핵심 흐름 |
| D8 | **Churn 방지**: 만료 7·14일 전 자동 알림 (push+SMS) + 연장 시 10% 할인. cancel flow 에 "save offer" (1개월 무료) 1회 | subscription-fitness §4 (retention 벤치) + pricing §10.4 (cancel flow) |
| D9 | **회원권 3-tier + decoy**: charm 99k / 279k / 990k (12개월) + decoy 12개월+PT 1,490k (anchor). Annual 가입 시 churn 50% ↓ | pricing §1·§6·§9 + §10.2 (annual vs monthly churn) |
| D10 | **여성 회원 특수 필드**: `preferred_time_slot` (여성 전용/심야), `preferred_coach_gender`, `safety_note`. 사장 통계에 여성 비중·시간대 분포 추가 | subscription-fitness §5 (여성 20-39 WTP) |
| D11 | **신규 first-week buddy assign**: 사장이 가입 승인 시 코치에게 buddy 매칭 지시. 폰에서 buddy 첫 메시지 자동 트리거. 1주 retention 측정 | subscription-fitness §6 (group dynamics retention 1.5~2x) |
| D12 | **페르소나 = JTBD 라벨**: 박지훈="회원 관리 시간 줄이기" / 김도윤="내 PR 자동 추적" / 송예준="박스 안 다녀도 자체 WOD" / 최서윤="처음이라 뭐부터 할지 모름" | ux-testing §2 (JTBD & behavioral segmentation) |
| D13 | **출석 체크인 = QR 1회용 (60초 만료)** / **결제 = Toss Payments + webhook 서명 검증** | 사용자 명시 + subscription-fitness §2 (multi-gym 결제) |
| D14 | **FCM 푸시 통합** (Phase 2 후반) + **사용성 테스트 사장 5명·회원 5명 think-aloud** (Nielsen 5-user 84% 발견율) | ux-testing §3.3 (Nielsen 5-user rule) |
| D15 | **API 엔드포인트 카탈로그를 §13 에 통일 명세** — REST 동사·경로·인증·응답 형식 SSOT | 통독 M1 |
| D16 | **회원 탈퇴 처리**: `gym_members.status='left'` + `left_at` + `left_reason` 추가. 자발적 탈퇴와 만료 분리 | 통독 M14 |
| D17 | **개인정보 보존 5년 + 자동 익명화 cron**: §7.1 보존 표 준수 | 개인정보보호법 §29·§36 · 국세기본법 §85-3 |
| D18 | **사장 다중 박스**: `gym_managers` PK 복합키 (gym_id, login_id). 로그인 시 박스 선택 토글 + 통합 대시보드 (총매출/총회원) | 통독 M7 |
| D19 | **코치 다중 박스**: 동일 패턴. 코치 폰에 박스 선택 토글 + 박스별 알림 분리 | 통독 M8 |
| D20 | **다국어 정책**: 폰 = 영문 헤드라인 + 한글 캡션 (V8~V10 SSOT 유지) / **PC 사장 = 전체 한글** (운영자 한국인) / 코치 폰 = 폰과 동일 | facing-app CLAUDE.md V8~V11 |
| D21 | **환불·해지 자동 계산** (M3): 잔여기간 × 1일 단가 − 위약금 10%. 환불 상태 = gym_memberships.status='refunded'. 환불 처리 화면 사장 PC §14 | 소비자보호법 · 체육시설업 표준약관 |
| D22 | **알림 게이트웨이**: SMS = **NHN Cloud Toast SMS** (D8 만료 알림) · 이메일 = **Mailgun** (계약서 PDF 발송) · 푸시 = FCM (D14) | 한국 시장 가용성 + Mailgun 무료 tier |
| D23 | **DB 백업**: SQLite `facing.db` 일일 새벽 03:00 → `data/backup/facing-YYYYMMDD.db` (30일 보존) + 주간 외부 백업 (Railway Volume snapshot) | 회원 50명 시점부터 적용 |
| D24 | **사장의 코치 관리 페이지** 신설 (§14) — 가장 큰 빈약점 보강. 코치 추가/제거·시급·스케줄·페어링 코드 발급 | 통독 M15 |
| D25 | **폰 탭별 화면 책임 재배치** (2026-06-02): **Home** = 공지/쪽지 아코디언(최상단·접힘) + 게이미피케이션(Level·업적·Milestones) / **WOD** = 코치 오늘 WOD + 하단 프리셋 카테고리 아코디언(참조) / **Notice** = 쪽지·숙제·공지 전체 피드(Home은 요약본) / **Attend** = 출석 캘린더 전담(Profile에서 이동) / **Profile** = Identity + 점수(숫자만, radar·sparkline 그래프 제거) + Body·Membership·Locker·MyBox·Settings·Actions. 페이싱 엔진 Home→Profile 강등은 §11.5 positioning(엔진=부가 기능, 홈 노출 위계↓) 과 정합. 5탭 구조·라벨·인덱스 유지 | 사용자 결정 2026-06-02 + §11.5 |
| D26 | **인증 통일 (2026-06-03)**: 회원·코치·사장 **전원 소셜 로그인(네이버·구글)**. ① device_hash = 익명 식별 → **데이터 연결키**로 격하 (계정에 link). ② 사장 ID/PW(D3·§7) = 소셜로 대체, 전환기엔 fallback 병행. ③ 로그인 응답에 `role` 포함 → 앱이 자동 분기 (수동 mode_select·role_entry 화면 폐기). ④ **백엔드·앱 실 구현 완료 (2026-06-03), 실 OAuth 키 대기**: 백엔드 3 라우트(`/auth/social`·`logout`·`me`)·`social_accounts` 테이블·`gym_managers/members.user_id` 링크·httpx 토큰검증(google tokeninfo·naver userinfo)·role 결정·세션·rate limit 구현+모킹검증 완료. 앱 `RealSocialAuthService`+`resolveSocialAuthService` 팩토리(`USE_REAL_AUTH` 플래그)+pubspec(google_sign_in·naver_login_sdk, **디버그 APK 빌드 통과**) 완료. 기본은 여전히 `StubSocialAuthService`. 키는 전부 `--dart-define` 주입(안드로이드 manifest 수정 0). **남은 것 = GOOGLE_CLIENT_ID/SECRET 발급 → `--dart-define=USE_REAL_AUTH=true` (절차: `apps/facing-app/docs/NATIVE_AUTH_SETUP.md`)**. OAuth 2.1 Authorization Code + PKCE(security.md). 상세: `services/facing/docs/AUTH_SOCIAL_DESIGN.md` | 사용자 결정 2026-06-03 (D2·D3·§7 대체) |
| D27 | **기본 전자계약 흐름 단순화 (2026-06-05)**: ㉠회원폰·㉡현장·㉢이메일 3경로를 **"현장 1기기 서명 + 메일 발송"** 하나로 통일. 코치·사장 폰(또는 PC) 한 대를 회원에게 건네 **회원 본인이 직접 서명**(코치 대필 금지 — 전자서명법 §3) → 완성 PDF 를 **회원 이메일로 발송**. 회원 이메일 = D26 소셜 로그인(네이버·구글) 계정 이메일 자동 사용(미로그인 시 등록폼 1칸). 발송 채널 = Mailgun(D22). 회원 앱 설치 불요. 구현 시 staff-기기 서명 경로(proxy-sign 변형, "현장 본인 서명" vs "대리" 구분) + 메일 발송 1건 추가. 상세: `services/facing/docs/ONBOARDING_FLOW.md §2·§4` | 사용자 결정 2026-06-05 (㉠㉡㉢ 단순화) |
| D28 | **쪽지 = 폰 + PC 양쪽 (2026-08-06)**: 회원이 보낸 1:1 쪽지를 코치·사장이 **PC 어드민에서도 읽고 회신**한다. 기존엔 폰 전용(device_hash 인증)이라 "중요한 일은 PC 에서 처리"가 불가능했다. 데이터·직렬화는 그대로 `gym_coach_notes`(+recipients) 1벌 — 조회 로직을 `api/coach_note.build_threads()`·`build_messages()` 로 추출해 폰(device 인증)·PC(세션 인증)가 **같은 코드**를 쓴다. PC 신원 환산: boss·manager = `gyms.owner_hash`, coach = 페어링된 `gym_managers.device_hash`(미페어링이면 안내문과 함께 빈 목록). 신규 엔드포인트 3개 = §13.2. 함께 수정: SSE 이벤트명 — PC 는 `message.received` 를 듣고 있었으나 백엔드는 그 이름을 **한 번도 발행한 적이 없어** 쪽지 토스트가 죽어 있었다 → `note.new` 로 교체 + payload 에 `preview`·`sender_name` 동봉 | 사용자 결정 2026-08-06 (§2 RBAC 코치 클라이언트 갱신 동반) |

---

## 13. API 엔드포인트 카탈로그 (M1)

> ⚠️ **부분폐기 (2026-08-13 전수조사)**: 이 §13 은 실코드와 대조되지 않은 낡은 카탈로그다.
> 실구현 정본 = `services/facing/docs/SSOT/` (라우트 212개 전량 `_facts/facts_01_url_map.txt` + 4면 `대차대조표.md`).
> 아래 표는 역사 기록으로만 보존한다 — 새 작업의 근거로 쓰지 말 것.

### 13.1 기존 (현재 동작 — facing-app 폰 호출)

| 동사 | 경로 | 인증 | 비고 |
|---|---|---|---|
| GET | `/api/v1/gyms/search?q=` | device_hash | 박스 검색 |
| GET | `/api/v1/gyms/mine` | device_hash | 내 박스 (owner_hash + profile) |
| POST | `/api/v1/gyms` | device_hash | 박스 생성 (owner) |
| POST | `/api/v1/gyms/{id}/join` | device_hash | 가입 신청 |
| DELETE | `/api/v1/gyms/{id}/leave` | device_hash | 탈퇴 |
| PATCH | `/api/v1/gyms/{id}/profile` | device_hash (owner) | 박스 정보 수정 |
| GET/POST/DELETE | `/api/v1/gyms/{id}/wods` | device_hash | 오늘의 WOD |
| GET/POST/PATCH | `/api/v1/gyms/{id}/members` | device_hash (owner) | 회원 목록·승인 |
| GET/POST/DELETE | `/api/v1/gyms/{id}/announcements` | device_hash | 공지 |
| GET | `/api/v1/gym/{id}/messages` · `/threads` | device_hash | 1:1 쪽지 타임라인·스레드 목록 (발송은 `/gym/{id}/notes`·`/member-report`). **경로가 `gym` 단수** — 다른 행의 `gyms` 복수와 다름 (2026-08-06 실경로 대조 정정) |
| GET/POST | `/api/v1/gyms/{id}/wods/{wid}/results` | device_hash | 결과·리더보드 |
| GET/POST/DELETE | `/api/v1/gyms/{id}/wods/{wid}/comments` | device_hash | WOD 댓글 |
| GET/POST/DELETE | `/api/v1/gyms/{id}/wods/{wid}/feedback` | device_hash (owner) | 코치 1:1 피드백 |
| GET/POST/PATCH | `/api/v1/gyms/{id}/requests` | device_hash | 회원 사전 건의 |

### 13.2 신규 (Phase 1·2 — 사장 PC + 폰 가입 흐름 보강)

| 동사 | 경로 | 인증 | 용도 |
|---|---|---|---|
| POST | `/api/v1/auth/social` | provider token (body) | **D26 소셜 로그인** — 네이버·구글 검증→계정 upsert→role 반환. 설계: `services/facing/docs/AUTH_SOCIAL_DESIGN.md` |
| POST | `/api/v1/auth/logout` | 세션 | D26 로그아웃 |
| GET | `/api/v1/auth/me` | 세션 | D26 본인 정보 + role + 소속 박스 |
| POST | `/api/v1/auth/link-staff` | 세션 + login_id/PW | D26 전환기 — 기존 코치/사장 계정을 소셜계정에 link → role 자동 boss/coach (설계 §4.1) |
| POST | `/api/v1/admin/login` | ID/PW → 세션 쿠키 | 사장 로그인 (D26 전환기 fallback) |
| POST | `/api/v1/admin/logout` | 세션 | 로그아웃 |
| GET | `/api/v1/admin/me` | 세션 | 본인 정보 + 박스 목록 (다중 박스) |
| GET | `/api/v1/admin/gyms/{id}/members` | 세션 (boss) | 회원 DB 풀 리스트 |
| POST | `/api/v1/admin/gyms/{id}/members` | 세션 (boss) | 회원 추가 (이름·전화·생년 입력) |
| PATCH | `/api/v1/admin/members/{mid}` | 세션 (boss) | 회원 정보 편집 |
| DELETE | `/api/v1/admin/members/{mid}` | 세션 (boss) | 회원 삭제 (status='removed') |
| POST | `/api/v1/admin/members/{mid}/leave` | 세션 (boss) | 자발적 탈퇴 처리 (D16) |
| POST | `/api/v1/admin/members/{mid}/memberships` | 세션 (boss) | 회원권 발급 |
| PATCH | `/api/v1/admin/memberships/{mid}/extend` | 세션 (boss) | 회원권 연장 (D8 win-back) |
| POST | `/api/v1/admin/memberships/{mid}/refund` | 세션 (boss) | 환불 처리 (D21) |
| GET/POST/PATCH | `/api/v1/admin/gyms/{id}/lockers` | 세션 (boss) | 락커 관리 |
| GET/POST | `/api/v1/admin/members/{mid}/contracts` | 세션 (boss) | 전자계약 |
| GET | `/api/v1/admin/gyms/{id}/stats` | 세션 (boss) | §6 통계 한 묶음 |
| GET/POST/PATCH/DELETE | `/api/v1/admin/gyms/{id}/coaches` | 세션 (boss) | **코치 관리 §14 (D24)** |
| POST | `/api/v1/admin/gyms/{id}/coaches/{cid}/pairing-code` | 세션 (boss) | 코치 폰 페어링 코드 발급 |
| GET | `/api/v1/admin/gyms/{id}/message-threads` | 세션 (boss·manager·coach) | **D28 회원 쪽지** — 상대별 1:1 스레드 요약(안읽음 포함) |
| GET | `/api/v1/admin/gyms/{id}/messages?peer=&read=1` | 세션 (boss·manager·coach) | D28 — 특정 회원과의 타임라인. `read=1` 이면 열람 시 읽음 처리 |
| POST | `/api/v1/admin/gyms/{id}/messages` | 세션 + CSRF | D28 — PC 에서 회원에게 1:1 회신 (500자) |
| POST | `/api/v1/admin/members/{mid}/inquiries/{iid}/respond` | 세션 (boss) | 회원 문의 답변 |
| GET | `/api/v1/admin/events` | 세션 (boss) | **SSE stream §4** |
| POST | `/api/v1/attendances` | device_hash + QR 토큰 | 출석 체크인 (D13) |
| POST | `/api/v1/payments/webhook` | HMAC-SHA256 서명 | Toss webhook (D13) |
| GET | `/api/v1/member/events` | device_hash | 회원 폰 SSE stream |
| POST | `/api/v1/member/inquiries` | device_hash | 회원→사장 직접 문의 |
| POST | `/api/v1/admin/members/{mid}/claim-code` | 세션 (boss) | **이음새 1** — 폰 없이 선등록한 회원에 가입 코드 발급(6자리·7일). 상세: `services/facing/docs/ONBOARDING_FLOW.md §4` |
| POST | `/api/v1/member/claim` | device_hash + code | **이음새 1** — 회원이 앱에서 코드 입력→임시 레코드에 폰 device_hash 흡수(중복 self-signup 병합) |

**응답 형식** 통일: `{ok: true, data: {...}}` / `{ok: false, error: "한글", code: "MACHINE_CODE"}` (기존 envelope 유지).

---

## 14. 코치 관리 페이지 (M15·D24 — 가장 큰 빈약점 보강)

### 14.1 사장 PC 화면 (`/admin/coaches`)

```
┌─ 코치 명단 ──────────────────────────────────────────────────┐
│ 이름      전화          입사일      시급       상태   액션  │
│ 박지훈    010-...       2024-03-01  35,000원   재직   편집 │
│ 김민수    010-...       2025-08-15  28,000원   재직   편집 │
│ 이수연    010-...       2024-11-10  30,000원   퇴사   복원 │
└─────────────────────────────────────────────────────────────┘
[+ 코치 추가]  [급여 정산 export]
```

### 14.2 코치 추가 흐름

1. 사장이 "+ 코치 추가" 클릭 → 폼 (이름·전화·시급·시작일)
2. 백엔드 `POST /api/v1/admin/gyms/{id}/coaches` → `gym_managers` INSERT (role='coach')
3. 자동으로 **페어링 코드 6자리 발급** + SMS 발송
4. 코치가 폰 facing-app 켜고 "코치 페어링 코드 입력" → device_hash ↔ login_id 연결
5. 코치 폰이 코치 모드 활성화 (기존 owner 와 동일 권한)

### 14.3 코치 제거 / 퇴사

- "퇴사 처리" 클릭 → `gym_managers.left_at = now()` (행 삭제 X, 이력 보존)
- 해당 코치의 폰 device_hash 는 그 박스에서 권한 박탈
- 회원에게 보낸 쪽지·피드백은 history 로 유지 (작성자 표기는 "(퇴사) 이수연")

### 14.4 시급·스케줄 (Phase 5+)

- 시급 입력만 v1. 자동 정산은 Phase 5+ (회계 시스템 연동 후보)
- 스케줄 (수업 시간표) 은 D2 (이번 빌드 X)

### 14.5 다중 박스 코치 (M8·D19)

- 같은 코치가 박스 2곳 등록 시 `gym_managers` 에 두 행 (gym_id 다르게)
- 코치 폰에 박스 선택 토글 (상단 메뉴)
- 시급·페이먼트는 박스별 독립

---

## 11. 변경 절차

이 브리프와 충돌하는 코드 변경이 필요할 때:
1. Claude 가 충돌 감지 → 사용자에게 보고 ("이 브리프와 어긋나는데 어느 쪽 우선?")
2. 사용자 명시 승인 → 브리프 먼저 갱신 → 코드 변경
3. 변경 이력은 §10 결정 사항 표에 D8, D9... 로 추가

브리프 우선 원칙. 코드만 갱신하고 브리프 방치 금지 (글로벌 §0-B SSOT 룰).

### 11.1. PHASE4 신규 테이블 (12개) — 사전 합의 등록

> 등록일: 2026-05-23. 상세 DDL: `docs/PHASE4_ROADMAP.md` 각 §1.x·§2.x.
> Migration 방법: `services/facing/models/base.py` `_migrate()` 함수에 `CREATE TABLE IF NOT EXISTS` 패턴 추가 (기존 Phase 1 방식 동일).

| # | 테이블 명 | PHASE4 Week | 모듈 | 브리프 §5 다이어그램 갱신 필요 |
|---|---|---|---|---|
| 1 | `class_session` | Week 1 | §1.1 예약 | 예 |
| 2 | `class_reservation` | Week 1 | §1.1 예약 | 예 |
| 3 | `class_waitlist_promotion` | Week 1 | §1.1 예약 대기열 audit | 예 |
| 4 | `notification_template` | Week 3 | §1.2 카카오 알림톡 | 예 |
| 5 | `notification_dispatch` | Week 3 | §1.2 발송 이력 | 예 |
| 6 | `contract_template` | Week 1 | §1.3 전자계약 템플릿 | 예 |
| 7 | `contract_instance` | Week 1 | §1.3 서명 인스턴스 | 예 |
| 8 | `gym_group` | Week 5 | §1.4 다지점 그룹 | 예 |
| 9 | `billing_key` | Week 2 | §1.5 Toss 빌링키 | 예 |
| 10 | `billing_schedule` | Week 2 | §1.5 자동결제 스케줄 | 예 |
| 11 | `ai_coaching_session` | Week 7 | §1.7 AI 코칭 보조 | 아니오 (Phase 2 연기) |
| 12 | `wod_calendar_plan` | Week 4 | §1.6 WOD 월간 캘린더 | 예 |

> `billing_key` 는 PHASE3 C-1 에서 일부 구현됐을 수 있음. 코드 착수 시 `services/facing/models/` 확인 후 중복 방지.

### 11.2. PHASE4 ALTER 컬럼 (3건) — 사전 합의 등록

> Migration 방법: `_migrate()` 내 `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` (SQLite 호환 — `IF NOT EXISTS` 는 SQLite 3.37+ 지원, 미만이면 try/except OperationalError 패턴).

| # | 테이블.컬럼 | 타입 | PHASE4 Week | 모듈 | 용도 |
|---|---|---|---|---|---|
| A1 | `gym_member_profiles.preferred_class_time_slot` | VARCHAR(50) | Week 1 | §1.1 예약 | 예약 선호 시간대 (기존 D10 `preferred_time_slot` 과 별도 — 클래스 예약용) |
| A2 | `gyms.group_id` | INT FK → `gym_group.id` | Week 5 | §1.4 다지점 | 다지점 그룹 FK |
| A3 | `gym_memberships.auto_renew_enabled` | BOOLEAN DEFAULT FALSE | Week 2 | §1.5 자동결제 | 자동갱신 토글 |

> A1 주의: 기존 `gym_member_profiles.preferred_time_slot` (D10 여성 전용/심야) 과 **다른 컬럼**. 클래스 예약 전용으로 분리. 이름 충돌 방지를 위해 `preferred_class_time_slot` 사용.

### 11.3. PHASE4 신규 API 엔드포인트 (§13 카탈로그 갱신 예고)

> PHASE4 구현 착수 시 §13.2 에 신규 endpoint 추가 의무. 아래는 예고 목록 (상세: `docs/PHASE4_ROADMAP.md` 각 §).

| 모듈 | 신규 엔드포인트 수 | 비고 |
|---|---|---|
| §1.1 예약 | 6 | POST·GET·DELETE·noshow·SSE 이벤트 |
| §1.2 알림톡 | 2 | dispatch·이력 |
| §1.3 전자계약 | 4 | draft·sign-link·sign·pdf |
| §1.4 다지점 | 4 | group dashboard·gym-switcher·share·cross-gym 출석 |
| §1.5 빌링키 | 5 | key 발급·삭제·schedule·retry·APScheduler |
| §1.6 WOD 캘린더 | 4 | 작성·복사·공유·조회 |
| §1.7 AI 코칭 | 1 | wod-pacing-explain |
| §2.1 페이싱 보강 | 3 | calculate 보강·cp-estimate·pacing-batch |
| §2.2 leaderboard | 3 | leaderboard·tier-distribution·engine-comparison |
| §2.4 듀얼 포지셔닝 | 3 | link-facing-app·class-pacing·push-pacing-card |
| **합계** | **35** | |

### 11.5. facing-app 포지셔닝 전환 (2026-05-24)

> 등록일: 2026-05-24. 사용자 결정: 신규 방문자 페르소나 시뮬레이션 100건 그루밍 결과, facing-app 의 primary value 를 "Games-elite 전용 페이싱 계산기" → **"수업 관리 + 페이싱 (+α)"** 로 전환.
> 상세: `docs/PERSONA_BACKLOG.md` 와 `apps/facing-app/CLAUDE.md` v1.16.2.

| 항목 | Before | After | 영향 범위 |
|---|---|---|---|
| facing-app primary value | "Split defines rank · Games elite" | "수업을 간편하게 — 박스 운영 + 페이싱(+α)" | 모든 화면 카피·온보딩·홈 |
| 타깃 유저층 | Games tier 출전자급 한정 | RX-aspiring ~ Games 까지 폭넓게 | 마케팅·기능 우선순위 |
| 페이싱 엔진 위상 | 메인 기능 | 부가/차별 기능 (Wodify 미보유 hook) | 홈 화면 노출 위계 |
| 톤·V1~V11 어투 | 유지 | 유지 (단, "elite 전용" 문구 제거) | 카피 톤 |
| 금지 용어 (헬스·다이어트·웰니스) | 유지 | 유지 | 카피 |

> §10 결정사항 표에는 D-번호 부여 후 추가 예정.

### 11.6. 박스 프로필 + 코치 프로필 스키마 확장 (2026-05-24)

> 등록일: 2026-05-24. 페르소나 결과 분류 — 박스 운영 정보 18 필드를 `gym_profiles` + 신규 `gym_coach_profiles` 두 테이블로 흡수.
> 상세 DDL: `docs/GYM_PROFILE_SCHEMA.md`.

| 변경 | 대상 | 신규 필드 / 모델 | 비고 |
|---|---|---|---|
| ALTER | `gym_profiles` | +9 필드 (price_summary, payment_methods, receipt_info, parking_info, first_visit_guide, attire_guide, wifi_info, contact_kakao, free_notice) | 기존 7 필드 (phone·coach_*·motto·logo·class_schedule·instagram) 와 합쳐 16 필드 |
| 신규 테이블 | `gym_coach_profiles` | coach_user_id, gym_id, name, photo_url, career, certifications, specialty, competition_records, demo_video_url, sns_url, pt_bookable, off_days_json, hired_at | 코치 multi 지원. `gym_managers.role='coach'` 와 1:1 연결 |
| 신규 endpoint | §13 카탈로그 | 6 (GET/PATCH gym profile / GET coach list / GET coach detail / PATCH coach profile / GET coach off-days) | RBAC: 사장 = 전부, 코치 = 본인 only, 회원 = 읽기만 |

> 계약서(`contract_template` / `contract_instance`) 는 **PHASE4 §1.3 으로 이미 등록됨** (위 §11.1). 추가 작업 없음. 박스 프로필 페이지에서 "환불·해지·등록비·보험" 4 항목은 계약서 템플릿 필드로 흡수.

---

### 11.7. D26 소셜 로그인 신규 스키마·엔드포인트 (2026-06-03)

> 등록일: 2026-06-03. 사용자 결정(D26): 회원·코치·사장 전원 소셜 로그인 통일.
> 상태: **설계만 등록 (미구현)**. 앱은 현재 `StubSocialAuthService`. 상세 설계: `services/facing/docs/AUTH_SOCIAL_DESIGN.md`.

| 변경 | 대상 | 신규 필드 / 모델 | 비고 |
|---|---|---|---|
| 신규 테이블 | `social_account` | provider, provider_uid (UNIQUE 복합), email, display_name, created_at, last_login_at | 소셜 계정 ↔ user 매핑 |
| ALTER | `gym_members` · `gym_managers` | +`user_id` (FK, nullable) | device_hash·login_id → user_id 점진 통합 |
| 신규 endpoint | §13.2 카탈로그 | 3 (`/auth/social` · `/auth/logout` · `/auth/me`) | 세션 메커니즘은 admin 동일 재사용 |
| 신규 env | `C:/dev/.env` + Railway | `GOOGLE_CLIENT_ID`/`SECRET` (NAVER_* 는 기존 재사용) | LLM 키(§0-A)와 무관 |

> 마이그레이션은 `models/base.py` `_migrate()` 패턴. 구현 착수 = 네이버·구글 OAuth 키 확보 시점.

---

### 11.4. PHASE5 §2 RBAC 변경 등록 (2026-05-23)

> 등록일: 2026-05-23. 상세 plan: `docs/PHASE5_ROADMAP.md`.
> 사장 폰 보조 운영 가정 추가 — linko 격차 해소 (linko 9 스크린샷 분석에서 격차 발견).

| 변경 항목 | Before | After | 영향 범위 |
|---|---|---|---|
| 사장 클라이언트 | PC 전용 | PC 주 + 폰 보조 (PHASE5) | facing-app 인증·라우팅·UI |
| 매니저 역할 | 미정의 | RBAC 표 추가 — 사장 위임 운영권 | 백엔드 RBAC enum + 미들웨어 |
| 폰 진입 분기 | device_hash 단일 | user_type=`device_hash` (회원·코치) vs `login_id` (사장·매니저) | facing-app 부팅 라우터 |
| 사장 폰 로그인 | 없음 | PC 와 동일 ID/PW | 백엔드 admin login endpoint 확장 |

> §10 결정사항 표에는 PHASE5 착수 시점에 D-번호 부여 후 추가.

### 11.8. D28 쪽지 PC 확장 등록 (2026-08-06)

> 등록일: 2026-08-06. 사용자 지시 — "코치(사장) 중요한 일은 PC 에서 처리".
> 실기 검증 완료: 회원 폰 발송 → PC 토스트·타임라인 즉시 반영, PC 회신 → 회원 폰 대화 반영.

| 변경 항목 | Before | After | 영향 범위 |
|---|---|---|---|
| 코치 클라이언트 (§2) | 폰 | 폰 주 + PC 보조 | 브리프 §2 RBAC 표 |
| 쪽지 조회 로직 | `coach_note` 엔드포인트 안에 인라인 | `build_threads()`·`build_messages()` 공용 함수 (SSOT) | `api/coach_note.py` |
| PC 쪽지 API | 없음 (폰 device_hash 전용) | admin 3 엔드포인트 (§13.2) | `api/admin.py`·`web/facing-admin` |
| SSE 쪽지 이벤트 | PC 가 `message.received` 수신 대기 (백엔드 미발행 = 사문) | `note.new` + `preview`·`sender_name` payload | `api/coach_note.py`·`templates/_layout.html` |

- **스키마 변경 없음** — 기존 `gym_coach_notes` · `gym_coach_note_recipients` 그대로 사용.
- 미해결: 폰 미페어링 코치는 PC 에서 쪽지 열람 불가 (안내문 노출). 페어링 없이도 되게 하려면
  `gym_managers` 에 staff 전용 식별 해시를 부여하는 별도 결정이 필요하다.

---

## 12. 참조 study (브리프 보강 근거)

| study 파일 | 적용된 결정사항 | 핵심 인용 |
|---|---|---|
| `reference/study/subscription-fitness.md` | D8 · D9 · D10 · D11 · D13 | §4 retention 벤치 / §5 여성 WTP / §6 group dynamics / §2 multi-gym pricing |
| `reference/study/pricing.md` | D8 · D9 · D21 | §1 charm / §6 tier / §9 bundle / §10 churn (annual vs monthly) / §10.4 cancel flow |
| `reference/study/ux-testing.md` | D12 · D14 | §2 JTBD / §3.3 Nielsen 5-user / §4 10 heuristics / §5 Baymard friction |
| `reference/study/ui-design-fundamentals.md` | (Phase 2 UI 설계 시 참조) | 5 디자인 프리셋 · 21 파라미터 default-deny 룰 |
| `reference/study/fitness.md` (sub-files: cardio·olympic-lifting·power·gymnastics·hyrox) | 기존 engine·grade 산정 로직 | 페이싱 계산·tier 정의의 학술 근거 |
| `reference/payment.md` | D13 · D22 | Toss Payments + webhook 검증 + idempotency |
| `reference/webhook.md` | D13 · D22 | HMAC-SHA256 + timing-safe compare + replay 방어 |
| `reference/security.md` + `reference/authorization.md` | D17 · §7.1 · D3 | 개인정보보호법 §29·§36 · bcrypt · RBAC · 감사로그 |

신규 보강 시 study 인용 우선 — 임의 결정 금지.
