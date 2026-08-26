# Hyphen — 시스템 아키텍처 브리프 (SSOT)

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
> **상세 로드맵**: `docs/_archive/PHASE4_ROADMAP.md`(2026-08-13 폐기 이동)

### 0.1.1. PHASE4 목표 — 듀얼 포지셔닝 확립

**"linko 는 운영, Hyphen 은 운영 + 선수."**

linko.my (한국 1위급, 350+ 박스) 의 운영 자동화 7 모듈을 흡수하면서, Hyphen 만의 선수 도구 4 모듈을 동시에 강화해 패스트팔로워 함정을 회피한다.

### 0.1.2. 11 모듈 요약

**흡수 7 모듈 (linko.my 추격)**:
1. §1.1 예약 시스템 (Class Reservation) — **P0** 1주
2. §1.2 카카오 알림톡 알림 자동화 — **P0** 3일 + NHN 사전심사 1주 (→ **2026-08-26 D60 폐기** — 알림은 앱 쪽지로 통일, `api/notifications/note.py`)
3. §1.3 전자계약 (e-Sign, PDF, audit hash) — **P0** 1주
4. §1.4 다지점 그룹 (gym_group + RLS) — P1 2주
5. §1.5 Toss 빌링키 자동결제 + 재시도 + grace period — **P0** 1주
6. §1.6 WOD 디자인 도구 + 월간 캘린더 + 복붙 — P1 1주
7. §1.7 AI 코칭 보조 (Claude API, HITL 의무) — P2 3일

**차별 강화 4 모듈 (Hyphen 만)**:
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

> **이 4줄이 Hyphen 전체(앱·PC 웹·백엔드)의 상위 규칙이다.** 아래 표·D 결정·각 repo
> CLAUDE.md 는 전부 이것의 각론이다. 충돌하면 **이 4줄이 이긴다.**

| # | 규칙 | 뒤따르는 금지 |
|---|---|---|
| **1** | **사장 = 매니저 = 코치 = 운영 권한.** 셋을 권한으로 가르지 않는다 | 코치라서 막는 분기 신설 금지 (nav·버튼·API 전부). 새 스태프 엔드포인트는 `@require_staff` 하나 |
| **2** | **회원은 폰(앱)에서만 쓴다** | 회원용 웹 화면·템플릿·로그인 페이지 신설 금지. 백엔드가 회원에게 주는 것은 **JSON API 뿐** |
| **3** | **사장·코치는 PC 에서도 쓴다** (PC 가 주, 폰이 보조) | "사장은 폰 안 씀"·"코치는 PC 안 씀" 같은 전제 금지. 스태프 기능은 양면 모두에서 도달 가능해야 한다 |
| **4** | **전 체육관은 한국이다 — 시간대는 KST 하나** (2026-08-26 사용자 "전부 한국이야, 확실히 못박아놔" = D56) | `gyms.timezone` 'Asia/Seoul' 외 값 · 다른 시간대 대비 작업(func.date 범위 전환·시간대 설정 화면) 금지. 폰·PC 는 표시만 기기 시간대 |

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

> **D41 (2026-08-24) — 예약 정책 2종: 종료 수업 차단 + 하루 예약 한도.**
>
> - **종료 수업 차단 (갭 픽스)**: 종전엔 어제 수업도 `status=open` 이면 예약이
>   통과됐다. `POST /member/classes/<id>/reservations` 와 회원 취소 DELETE 에
>   `CLASS_ENDED`(409) 게이트 — **컷오프 = 시작 + duration_minutes (종료 시각)**.
>   시작 시각이 아닌 이유: 코치 대리 예약 API 가 없어 지각 회원의 수업 중
>   자가 예약(→명단 등재)이 유일한 구제 경로다. 취소까지 막는 이유: 끝난 뒤
>   취소하면 노쇼 기록을 회피한다 — 출결 정정은 스태프 PATCH 만.
>   앱 거울: `ClassSessionDto.isEnded` (appClock) → 버튼 숨김 + '종료' 배지.
>   주간 보드(week_board `isOver`)는 시작 시각 기준으로 더 엄격 — 기존 유지.
> - **하루 예약 한도 (opt-in)**: 신규 표 `gym_class_settings.daily_reservation_limit`
>   (0=무제한 기본·1~10, gym_id PK — gym_point_settings 패턴).
>   설정 API `GET/PATCH /admin/gyms/<gid>/class-settings` (staff + audit,
>   `api/class_settings.py`) · 앱 코치 설정 '예약' 탭.
>   집행 = `api/classes.py _daily_limit_blocked` **한 곳** — 신규 confirmed ·
>   취소 후 재활성 · 대기 신청 세 진입로 전부 + 대기열 승격 재검사(초과 회원은
>   건너뛰고 다음 대기자 승격, 건너뛴 회원은 대기열 잔류).
>   기준일 = 수업 시작일(KST) · 카운트 = confirmed+attended. 초과 시
>   `DAILY_LIMIT_REACHED`(409). 리워드 엔진의 reserved_at 기준 "예약 행동일"
>   정규화와는 다른 축 (그쪽은 보상 1회 제한, 이쪽은 예약 자체 제한).
> - **같은 날 후속 (G29·G30 픽스)**: 재활성 분기를 정원 검사 안쪽으로 이동
>   (만석이면 waitlist 로) + 대기 중 재신청 `ALREADY_WAITLISTED`(409) 차단 +
>   대기 이탈 신설 `DELETE /member/classes/<id>/waitlist` (미승격 sentinel 행만
>   삭제 · SSE `member_waitlist_cancelled`) — 폰 `cancelClassFlow` 가 대기
>   상태면 전용 DELETE 로 분기 ('대기를 취소할까요?'). 종전엔 대기 '취소'
>   버튼이 예약 행 부재로 조용히 무동작이었다.
> - 회귀 게이트: 서버 `tests/test_reservation_policy.py`(11)·`tests/test_class_settings.py`(8),
>   골든 `state_07_class_ended`·`boss_08_settings_reservation`·`state_08_waitlist_cancel_dialog`.

> **D42 (2026-08-25 사용자 지시) — 로그인 창구는 하나. 역할 판정은 서버가 한다.**
>
> 종전엔 진입 화면에서 사람이 '아이디로 로그인(회원)' 과 '코치 로그인' 중 하나를
> 골라 들어갔다. 자기 역할을 사용자가 고르는 구조 자체를 폐기한다.
> - **신규 `POST /api/v1/auth/login {login_id, password}`** (`api/auth_login.py`) —
>   서버가 `gym_managers` → `member_credentials` 순으로 조회해 `kind: coach|member`
>   와 각자의 payload 를 함께 내려준다. 같은 아이디가 양쪽에 있으면 **비밀번호가
>   맞는 쪽**이 이긴다 (스태프 쪽 불일치여도 회원 표를 한 번 더 본다).
>   판정 몸통은 구 창구와 공유 — `admin.authenticate_manager()` ·
>   `member_auth.authenticate_member()` 로 뽑아 두 벌이 되지 않게 했다 (§0-B).
> - **구 창구 2개는 유지**: `/api/v1/admin/login`(관리자 웹) ·
>   `/api/v1/auth/member-login`(이미 배포된 APK). 앱 신버전은 통합 창구만 쓴다.
> - **rate limit 2겹**: IP 20회/5분(체육관 공용 공유기) + **계정 5회/5분**
>   (구 admin/login 수준 유지 — 창구가 넓어진 만큼 계정 축을 새로 조인다).
>   Flask-Limiter 기본 429 는 HTML 이라 앱이 파싱하다 죽어 `app.py` 에
>   JSON 429 핸들러(`RATE_LIMITED`)를 붙였다.
> - **아이디에 대소문자 규칙은 없다** (같은 날 사용자 추가 지시). 스태프는 원래
>   대소문자를 무시했는데 회원만 구분해서, 창구가 합쳐진 뒤 같은 화면인데 규칙이
>   둘로 보였다. 회원 조회 정본 = `models/member_credential.find_credential()`
>   한 곳 (자가가입 중복 검사도 같은 함수 — 'Member' 와 'member' 가 둘 다
>   만들어지지 않게). 세션·응답에는 사용자가 친 문자열이 아니라 **저장된 정본
>   아이디**를 담는다. 비밀번호는 그대로 대소문자를 구분한다.
> - **앱**: `login_screen.dart`(구 `member_login_screen.dart`) 한 화면 —
>   **브랜드 로고 없음**(사용자 지시 — 진입 화면 `signup_screen.dart` 도 같이
>   철수. 로고가 남는 자리는 스플래시·전면 로딩 둘뿐) · 역할 선택 UI 없음 · `kind` 로
>   `/boss/dashboard` ↔ `/shell` 분기. `BossLoginScreen`·`/boss/login` 삭제
>   (README §제거된 기능 대장 15). '아이디 기억하기' 저장 칸도 회원/코치 2칸 →
>   1칸 (구 값은 첫 로드 때 흡수).
> - 회귀 게이트: 서버 `tests/test_unified_login.py`(11) · 앱
>   `test/remembered_login_test.dart`(8) · 골든 `common_08_login`(로고 없는 통합
>   로그인)·`common_05_signup`(코치 줄 사라진 진입)·`state_09_login_remembered`.

> **D43 (2026-08-25 사용자 지시) — 폰 코치는 보는 쪽. 수업 내용은 PC 에서 쓴다.**
>
> "코치로 로그인 하면 예약 현황만 제대로 보이고, 수업 내용 게시하는 건 굳이 폰에
> 넣지 말자 — 그런 상세 내역은 PC 에서 하게 하자." 대전제 3(코치는 PC 가 주,
> 폰이 보조)의 화면 단위 집행이다.
> - 앱에서 삭제: `WodPostScreen`(수업 내용 작성 폼) · 수업 탭 '수업 내용 게시'
>   FAB · WodRow 삭제 아이콘. 게시가 PC 몫이 되면 삭제도 PC 몫이다 — 폰에서
>   지울 수는 있는데 다시 쓸 수는 없는 상태가 더 나쁘다. 죽은 배선
>   (`gym_state`·`gym_repository` 의 postWod·deleteWod)까지 같이 내렸다.
> - **백엔드는 그대로**: `POST/DELETE /api/v1/gyms/<id>/wods` 는 PC 웹이 쓴다.
>   폰만 창구를 닫은 것이지 기능을 없앤 것이 아니다.
> - 폰 코치에 남는 쓰기 동선은 **예약 현황 탭** 쪽뿐이다 — 수업 등록·수정·취소
>   (G24 시트) · 출석/노쇼 체크(D31) · 가입 승인. 이건 '예약 현황' 의 일부라
>   이번 스코프에 넣지 않았다 (더 내릴지는 사용자 결정 대기).
> - 회귀 게이트: 골든 `coach_02_shell_board`(FAB·삭제 아이콘 없는 수업 탭) ·
>   `test/button_lint_test.dart` baseline 래칫 1줄 축소.

> **D44 (2026-08-25 사용자 지시) — 폰 코치는 '오늘 돌리는 것'만.**
>
> D43 직후 사용자가 "코치가 폰에서 되는 것" 전수 목록을 받아 직접 추렸다.
> 남긴 것 = 오늘 예약·출석 수치 · 오늘 수업 목록 · 예약자 명단 · 출석/노쇼 체크 ·
> 가입 신청 승인/거절 · 쪽지 · 알림 on/off · 가입 자동 승인 · 하루 예약 한도 ·
> 수업 내용 읽기. 내린 것 = 위 README §제거된 기능 대장 17 (수업 등록·수정·취소 ·
> 회원 명단/통계/상세 · 코치 노트 · 회원 요청 · 만료 임박 · 체육관 프로필 수정 ·
> 요금제 탭).
> - **대기자 승격은 자동이 정본** (사용자 지시 "7은 자동으로 해라"). 서버가 이미
>   그렇게 동작한다 — `api/classes.py cancel_reservation` 이 취소 즉시
>   `waitlisted_at` 순으로 다음 대기자를 confirmed 로 올리고 `member_promoted_from_waitlist`
>   SSE 를 쏜다 (하루 예약 한도 초과자는 건너뛰고 대기열에 남긴다). 폰에 수동
>   승격 버튼은 원래 없었다 — 명단의 '승격' 은 상태 배지다.
>   ~~⚠ 갭: PC 에서 정원을 늘렸을 때는 승격이 돌지 않는다~~ → **2026-08-25 해소**
>   (서버 `_promote_waitlist()` 한 곳 — 취소·정원 증가 두 진입로 공유, 갭대장 16차).
> - 화면 개명: `CoachDashboardScreen` → `MemberApprovalsScreen` — 가입 승인만
>   남아 이름이 실물과 어긋났다 (§0-B). 진입 버튼 '회원 관리' → '가입 신청'.
> - 코치 설정 4탭 → 3탭 (알림 · 자동 가입 · 예약).
> - 회귀 게이트: 골든 55장 (5장 삭제: boss_04·05·06·07·09) ·
>   `boss_02_dashboard`·`boss_03_class_roster`·`coach_01` 재생성 ·
>   button_lint baseline 2줄 축소 + 1줄 개명.

> **D45 (2026-08-25 사용자 지시) — 폰 코치 설정 화면 폐지 + 자동 가입 승인 기능 폐기.**
>
> D44 목록을 한 번 더 추린 결과. 폰 코치 설정 3탭이 전부 사라진다.
> - 알림 on/off · 하루 예약 한도 → **PC** (관리자 웹에 이미 화면이 있다:
>   `notifications.html` · `settings_reservations.html`).
> - **자동 가입 승인은 기능 자체를 없앤다** — "내가 항상 승인해서 하는걸로".
>   가입 신청은 예외 없이 코치가 직접 승인한다. 앱 탭 + 백엔드 엔드포인트
>   (`/api/v1/admin/gyms/<id>/auto-approve`) + `api/gym.py` 의 분기까지 전부 삭제.
>   `GymProfile.auto_approve_joins` 는 읽는 코드 0 인 휴면 컬럼으로만 남긴다
>   (gym_point_settings 와 같은 처리). 되살리지 말 것.
>   ※ 공식 HYPHEN HQ 체육관 즉시 승인(`OFFICIAL_GYM_NAME` 분기)은 데모 계정용
>   별개 장치라 유지한다 — 코치가 설정으로 켜고 끄는 물건이 아니다.
> - 폰 코치 AppBar 에 남는 것은 로그아웃 하나. 폰에서 코치가 할 수 있는 일은
>   이제 **7가지**다: 오늘 예약·출석 수치 · 오늘 수업 목록 · 예약자 명단 ·
>   출석/노쇼 체크 · 가입 신청 승인/거절 · 쪽지 · 수업 내용 읽기.
> - 회귀 게이트: 골든 54장(boss_08 삭제) · button_lint baseline 1줄 축소 ·
>   서버 211건.

> **D46 (2026-08-25 사용자 지시) — 코치 셸 상단바는 하나.**
>
> "폰에서 예약(현황)일 때 상단화면과 수업일 때 상단화면이 또 다르잖아. 이런 거
> 하지 말고 통일하라고 1개로." 탭마다 화면이 자기 AppBar 를 들고 오면서
> 예약 현황(체육관명+역할+로그아웃) · 수업(제목+COACH 배지+종+새로고침+회원) ·
> 쪽지(제목만) 세 개가 제각각이었다.
> - **상단바 소유권을 셸로 올린다.** `CoachShell` 이 Scaffold+AppBar 를 갖고,
>   세 페이지는 `embedded: true` 로 자기 AppBar 를 그리지 않는다
>   (`BossDashboardScreen`·`BoxWodScreen`·`MessagingScreen` 공통 플래그 —
>   variant 신설이 아니라 state 한 칸, §3).
> - 단일 바 = **체육관명 + '코치' + 로그아웃**. 어느 탭인지는 하단 탭바가
>   알려주므로 제목은 신원 하나로 고정한다. 로그아웃 처리도 셸로 옮겼다.
> - 뺀 것: 종·새로고침·COACH 배지·회원 아이콘. 종은 쪽지 탭이 그 목적지라
>   중복이고, 새로고침은 예약 현황·수업 둘 다 당겨서 새로고침이 있다.
>   회원 아이콘은 예약 현황 탭 '가입 신청' 버튼과 중복.
> - **회원 셸(MainShell)은 건드리지 않았다** — 탭별 제목(홈·수업·내 정보)이
>   이미 같은 골격이고 이번 지시는 코치 화면을 가리킨다. `embedded` 기본값
>   false 라 회원 쪽 렌더는 1픽셀도 안 바뀐다 (골든으로 확인).
> - 회귀 게이트: 골든 `coach_01`·`coach_02`·`coach_03` 재생성 (세 장 상단바 동일).

> **D47 (2026-08-25 사용자 지시) — 앱 UI 골격 SSOT: 인라인·이원화 전부 HKit/테마 한 곳으로.**
>
> "PC 에서 SSOT 로 하나로 묶어서 하듯이 앱에서도 인라인으로 되어 있거나 이원화되어
> 있거나 찾아서 전부 통일." 전수 조사 결과 5종이 흩어져 있었다 — 상단바 31곳 ·
> 다이얼로그 11곳 · 바텀시트 13곳 · 원시 버튼 71곳(22파일) · 입력칸 스타일 4벌.
> - **정본 신설 (`lib/widgets/hkit.dart`)**: `HkAppBar`(push 화면) / `HkAppBar.identity`
>   (셸: 체육관명 + 역할) · `HkDialog.confirm/info/custom` · `HkSheet.show` ·
>   `HkInlineError`. 모양은 `theme.dart` 가 갖는다 — `dialogTheme`·`bottomSheetTheme`
>   신설, `inputDecorationTheme` 에 에러 테두리·errorStyle 보강 (이게 없어서 로그인·
>   가입 화면이 각자 `_inputDeco` 를 들고 있었다).
> - **회원 셸도 상단바 하나** (D46 코치 셸에 이어): 체육관명 + '회원' + 종.
>   홈·수업·내 정보 세 탭이 `embedded: true` 로 들어와 자기 AppBar 를 안 그린다.
>   홈의 새로고침 아이콘은 당겨서 새로고침(RefreshIndicator)으로 이관.
> - **원시 버튼 0건**: ElevatedButton/OutlinedButton/TextButton 직접 사용 71곳 전부
>   `HkButton.primary/secondary/tertiary` 로. `button_lint_test.dart` baseline 이
>   22파일 → **빈 집합** (래칫 종료). 영문 라벨 잔재(Start/Resume/Save/Send/Ask
>   Coach/Share)는 이 김에 한글로.
> - **바텀시트 모서리 r5 로 통일** (DESIGN-SSOT §모서리 — 종전엔 r3/r4 혼재) ·
>   다이얼로그 r4 · 위험 동작(탈퇴·초기화·계정 삭제·세션 종료) 확정 버튼은
>   `danger: true` 채움으로 통일.
> - **새 게이트 `test/ssot_lint_test.dart`**: lib/features/** 에서 `AppBar(`·
>   `AlertDialog(`·`showModalBottomSheet`·`InputDecoration _x(`·`OutlineInputBorder(`·
>   인라인 에러 박스 6패턴 0건 강제 — 다시 인라인이 생기면 CI 에서 죽는다.
> - 남겨 둔 것 (보고): `hyphen_pictogram.dart` 의 hex 32개는 업적 픽토그램 6색 팔레트
>   ×N — 토큰으로 올리면 테마가 부풀어 art asset 으로 취급. `avatar.dart` hex 6개
>   (이니셜 배경 해시 팔레트)·`grain_overlay.dart` 1개 동일.

> **D48 (2026-08-25 사용자 지시) — 구조 이원화 6건 통일: 같은 정보를 두 화면이 다르게 그리지 않는다.**
>
> D47 뒤 "앱 UI 따로 있는 부분 전수조사" → 12건 중 **구조가 갈라진 6건**을 먼저.
> - **하단 탭바 2벌 → `HkTabBar`** (hkit): 회원 셸·코치 셸이 테마·구분선·SafeArea 까지
>   복사해 들고 있었다. 셸은 destinations 만 준다. `ssot_lint_test` 에 `NavigationBar(` 금지 추가.
> - **승인 대기 화면 2벌 → `MembershipStatusView`** (gym/membership_status_view.dart):
>   셸 입구 게이트(`_PendingGate`)와 수업 탭 안 미가입/대기/거절 3종이 같은 상태를 두
>   문구·두 골격으로. none/pending/rejected 한 위젯 — 게이트는 `onRecheck`·`onSignOut` 만 더 준다.
> - **회원 수업 예약 UI 2벌 → 주간보드 하나**: `/classes` 별도 화면(카드형) 삭제
>   (README §제거된 기능 대장 19). 예약·취소 흐름은 `classes/class_flows.dart`.
> - **코치 수업 카드 2벌 → `ClassLine`** (classes/class_line.dart): 예약 현황 탭 카드와
>   주간보드 줄이 같은 수업을 다른 모양으로. 골격 하나 + 우측 슬롯만 시점별 —
>   `ClassLine.coach`(인원 + 명단 진입) / `ClassLine.member`(예약·대기·취소 배지).
>   **코치가 수업 탭에서도 인원+명단을 본다** — 회원용 예약 배지가 코치에게 보이던
>   문제가 같이 닫혔다 (WeekBoard `isOwner`).
> - **공지 행 2벌 → `AnnouncementRow`** (announcements/announcement_row.dart): 홈·수업 탭
>   아코디언이 본문 줄 수만 다른 복사본. `bodyMaxLines` 인자.
> - **에러 뷰 4벌 → HKit**: 코치 대시보드 `_ErrorView`·계약 `_ErrorRetry` → `HkErrorState`,
>   수업 탭 `_LoadErrorBanner`·주간보드 수업 에러 줄 → `HkInlineError(onRetry:)`.
>   `HkErrorState` 안의 원시 OutlinedButton 도 HkButton 으로.
> - 곁가지: `core/time_format.dart` 신설 (hhmm·hhmmIso·ymd·mdDot) — 이번에 손댄
>   파일의 날짜 헬퍼만 이관, 나머지 7개 파일은 "작은 것" 단계에서.
> - 회귀 게이트: 골든 54장 재생성 (member_07·08·state_07·08 은 주간보드로 재촬영) ·
>   앱 194건 · ssot_lint 7패턴.

> **D49 (2026-08-25 사용자 지시) — 부품 인라인 6건 통일: 정본이 있는데 안 쓰던 곳을 전부 갈아끼움.**
>
> D48 뒤 "작은 것 6건" — 판단은 없고 양만 많은 갈아끼우기.
> - **섹션 라벨 77곳 → `HkSectionLabel`** (`Text('X', style: sectionLabel)` 직접 지정 26파일).
>   `.copyWith` 변형 3곳만 남김 (색·굵기를 바꾸는 자리).
> - **스피너 13곳 → `HkLoading`** — 크기 18/20/22·색 muted/primary/accent 가 섞여 있었다.
>   22×22 stroke 2 muted 한 규격.
> - **빈 상태 8곳 → `HkEmptyState`** (업적·계약·가입 신청·수업 기록·기록 상세·그룹 ×2·노트).
>   폼 안 부연 문구 4곳(주간보드 "등록된 수업 없음"·내 정보 "체육관 없음"·노트 작성 "동작 없음")은
>   화면 상태가 아니라 줄 안 메모라 그대로.
> - **통계 타일 → `HkStatTile`**: 코치 예약 현황 `_CounterCard` (h1 숫자·자체 카드) →
>   명단 시트·홈 마일스톤과 같은 타일. `_ProgressStat`(홈)은 이미 HkListRow 위의 진행바,
>   `_StatsHeader`(업적)는 히어로 숫자 — 타일이 아니라 그대로.
> - **날짜·시각 함수 7파일 → `core/time_format.dart`** (`ymd`·`hhmm`·`hhmmIso`·`mdDot`·`mdHm`·`mmss`).
>   `history_detail._formatDate`(ISO→`yyyy.MM.dd HH:mm`) 1개만 잔존 — 다음 표기 추가 때 흡수.
> - **카드 크롬 → `HkCard`**: 정식 크롬(surface + border + r3) 38곳 중 Container 인자가
>   margin/padding/child 뿐인 2곳만 자동 치환. 나머지 36곳은 `clipBehavior`·`width`·
>   `alignment`·색 테두리 등이 붙어 있어 HkCard 시그니처 밖 — **보고만** (HkCard 에
>   `clipBehavior`/`borderColor` 를 열어 주는 결정이 먼저).
> - 게이트 추가 (`ssot_lint_test`): `CircularProgressIndicator(` · `style: sectionLabel[,)]` ·
>   `String _fmt/_hhmm/_ymd/_dateShort…(` 3패턴 → 총 10패턴.
> - 회귀: 골든 54장 재생성 · 앱 194건.

> **D50 (2026-08-25 사용자 지시 "1,2,3번 다") — 카드 마저 · 코치 다중 기기 · 코치 수업 탭 읽기 전용.**
>
> - **카드 27곳 → `HkCard`**: 정본에 `radius`(r2 카드)·`borderColor`(예약됨=초록 같은
>   상태 테두리)·`borderWidth`·`clipBehavior`·`width` 네 칸을 열어 D49 에서 시그니처 밖이던
>   것을 흡수. 남은 10곳은 카드가 아니다 — 왼쪽 색띠(업적·칭호), 원형(코치 사진),
>   말풍선(채팅), 요일 타일(주간보드), 내 기록 강조(배경 색 조건), 결과 시트 헤더.
> - **코치 다중 기기 페어링 (서버)**: `GymManager.device_hash` 1개가 마지막 로그인 기기로
>   덮어써져 에뮬레이터 로그인 뒤 갤S22 수업 탭이 '미가입'으로 떨어졌다 (실기 발견).
>   신규 표 `gym_manager_devices(gym_id, login_id, device_hash, paired_at, last_seen_at)`
>   — 로그인마다 upsert. 판정·SSE 구독·기기 폴백은 `roles.staff_rows_for_device()`
>   **한 곳**(표 ∪ 구 컬럼). 구 컬럼은 '마지막 로그인 기기' 로 계속 갱신 — PC 쪽지함
>   신원(`_staff_device_hash`) 등 구 경로 호환. 회귀: `tests/test_manager_devices.py`(4).
> - **코치 수업 탭 읽기 전용**: 회원용 '완료 표시'(내 기록) 배지를 코치에게 숨김
>   ('메시지' 는 이미 숨김). 코치가 이 탭에서 하는 건 읽기 + 인원·명단뿐 (D43·D44 정합).

> **D51 (2026-08-25 사용자 결정 "니 말대로 1" + 쪽지 단순화 지시) — 코치 앱 2탭 · 정본은 부품이지 화면이 아니다.**
>
> 질문 "코치가 앱으로 로그인했을 때 수업 화면이 회원과 같을 필요가 있나" → 없다.
> 회원 주간보드를 코치에게 얹고 `isOwner` 분기를 하나씩 깎던 것은 한 위젯 안의 이원화였다.
> - **코치 셸 = 2탭**: 예약 현황(오늘 수치 · 가입 신청 · **주간** 수업/예약) · 쪽지.
>   '수업' 탭 폐지 (README 대장 20). 주간 수업/예약 = `boss/coach_week_classes.dart` —
>   부품은 회원 쪽과 같은 규격(주간 헤더·ClassLine.coach·명단 시트·HkCard), 화면 조립은
>   코치용. 데이터는 코치 세션 API(`GET /admin/gyms/<id>/classes?from&to`,
>   `BossApiClient.getList` 신설) — 회원 API 기기 폴백에 기대지 않는다.
> - **회원 화면에서 코치 분기 전부 제거**: week_board `isOwner`·명단 진입, box_wod 코치
>   배지·가입 신청 아이콘, wod_row 완료 표시/메시지 가드, wod_detail 배지·요청 가드,
>   mypage 가입 신청 버튼·'코치' 라벨. 회원 셸은 순수 회원 화면 (isOwner 잔존 = 쪽지·
>   wod_session 의 권한 가드 2곳뿐 — 화면 분기 아님).
> - **쪽지 단순화 (사용자 지시)**: '그룹' 버튼·그룹 관리 화면·그룹 모델·리포지토리 그룹
>   메서드 삭제. '새 쪽지' = 내 회원 목록 → 받을 사람 탭 → 그 회원과의 대화 화면
>   (`ChatThreadScreen`)에서 아래 입력칸에 쓰고 전송 (`inbox/new_note_screen.dart`).
>   대상 3종·종류 2종·제목·근거·기한·동작 표를 전부 걷었다 (대장 21). **API 는 그대로** —
>   `POST /gym/<id>/notes` individual/note 라 PC 쪽지함(`admin._staff_device_hash` 공용
>   owner 해시 규칙)이 종전처럼 받는다. 그룹·숙제 서버 API 는 PC 용으로 존치.
> - 회귀: 골든 `coach_01`(주간) 재생성 · `coach_02` 삭제 · `coach_04_new_note_members` 신규 ·
>   `coach_03` 재생성(그룹 버튼 없음).

> **D60 (2026-08-26 사용자 지시 — PC 웹 개편 6건 + "카카오 알림톡 필요 없음, 앱 쪽지로. 야간 발송 금지 없애고 보내는 시간은 오후 3시로 통일. 각 알림마다 뭐가 발송되는지 보여라") — 알림 = 앱 쪽지 하나 · PC 사이드바/공지·일정/케어/수업/알림 설정 개편.**
>
> - **알림 채널 = 회원 앱 쪽지 하나** (카카오 알림톡·NHN 폐기 — `_archive/dead-2026-08-26/`). 정본 =
>   `services/hyphen/api/notifications/note.py`: `NOTE_TEMPLATES`(expiry·payment·reservation·cancel — 키 =
>   설정 토글 키) · `send_member_note()` (발신 = `admin._staff_device_hash` owner 해시 → 회원 `device_hash`,
>   `GymCoachNote kind='note'` + Recipient + SSE `note.new` + AuditLog `note.auto`) · `describe_templates()` ·
>   `SEND_HOUR = 15`. 발송 4지점(해지·수업 취소·결제 입력·만료)이 전부 이 함수 하나.
> - **발송 시각**: 만료 안내(D-7·D-3·D-0)는 매일 **15:00 KST** 잡 하나(`daily_expiry_notify_15`, AuditLog 로
>   같은 날 멱등). 결제·수업 취소·해지는 **사건 즉시** — "뭐든지 오후 3시" 를 수업 취소 통보에까지 적용하면
>   다음날 3시에 알리게 되어 무의미하므로 일일 배치에만 적용 (Claude 판단, 사용자 재결정 가능).
>   야간 발송 금지(quiet_start/quiet_end) 개념 삭제 — 설정 키·검증·UI 전부 제거.
> - **설정 API** `notification-settings` GET/PATCH 응답에 `send_hour`·`templates[{key,label,when,title,body}]`
>   동봉 — PC 알림 설정 화면이 항목마다 **실제 발송 문구**를 보여 준다 (사용자 "뭐가 발송되는지 알아야 토글을
>   켠다"). `alimtalk-logs` → `notification-logs` (note.auto 최근 7일).
> - **PC 웹 (web/facing-admin)**: 사이드바 = '일정 달력'+'공지사항' → **'공지 · 일정'** 한 화면
>   (`/announcements` = 월 달력 막대 + 공지 표 + 모달, 막대 클릭 = 같은 화면 수정 모달, `/calendar` 는 302) ·
>   '처음 시작하기' 링크 삭제(라우트 존치) · 푸터 = 로그아웃만(문의하기 카카오톡·평일 10–18시·v1.0 베타 삭제) ·
>   케어 필요 = 카드 그리드 → **표 2개**(케어 필요·만료 임박, 긴급 행 좌측 rail) · 수업 안내 매주 시간표 =
>   규칙당 **요일 스트립 7칸 + 시각** 한 줄, '+ 시간'·× 삭제, 편집은 '수정' 모달 안 "매주 시간표" 섹션
>   (요일 칩·시각·행 추가/삭제, 저장 시 규칙 diff → POST/PATCH/DELETE) · 수업 관리 시간 축 = 수업 있는 시간
>   **앞 1시간 ~ 끝나는 시각**만, 2시간 이상 빈 구간은 접힌 행("12:00 ~ 16:00 비어 있음 · 펼치기"), 수업 없는
>   주는 06~20.
> - 앱(폰) 변경 0 — 자동 쪽지는 기존 쪽지함에 코치 발신으로 도착. 골든 변경 없음.
> - 검증: 백엔드 pytest 270 passed · PC 6화면 playwright 실클릭(코치 로그인) · design lint 인라인 8→7.

> **D59 (2026-08-26 사용자 선택 "옵션 1" — 인계장 대기 1번) — 폰 코치 셸 세션 만료 시 로그인 화면 자동 이동.**
>
> - 증상: 코치 셸(예약 현황·쪽지)에서 서버 세션이 만료되면 `require_staff` 의 401 UNAUTHORIZED
>   가 `HkErrorState('로그인이 필요합니다.' / 다시 시도)` 로만 떠서 갇혔다 — 우상단 로그아웃
>   아이콘을 눌러야만 나갈 수 있었다.
> - 처리 (폰 3곳, 백엔드·PC 변경 0):
>   1. `BossApiClient._checkSession` — 인증 요청 응답이 `401 + code UNAUTHORIZED` 면
>      `BossAuthState.expire()` (저장 로그인 삭제 + notify). `_unwrap`·`getList` 공통 — 어느
>      코치 API 든 한 곳. 로그인 창구(`_loginTo`, INVALID_LOGIN)는 이 길을 타지 않는다.
>   2. `CoachShell` — `BossAuthState` 리스너: 로그인이 풀리면 다음 프레임에 로그아웃과 같은
>      뒷정리(`DeviceIdService.reset` · `GymState.resetLocal`, S1) 뒤 `/signup` 위에 `/login`
>      을 얹는다. 로그아웃 버튼 경로는 `_leaving` 빗장으로 이중 이동 방지. `main.dart` 의
>      기존 리스너가 스태프 SSE 를 멈춘다.
>   3. `LoginScreen` — 라우트 인자 `{argNotice: noticeSessionExpired}` 를 에러 줄
>      (`HkInlineError`) 자리에 한 번 띄운다: "로그인이 만료되었습니다. 다시 로그인해 주세요."
>      다음 로그인 시도에서 사라진다.
> - 골든: `state_16_coach_session_expired` (states 2부 — 대시보드 401 → 로그인 화면 + 사유).
>   하네스 `routes` 주입구 신설 (화면이 스스로 라우트를 넘어가는 상태 캡처용) ·
>   `FakeBossApi.unauthorizedPaths` · `FakeBossAuth.loggedIn` 가변.
> - 안 한 것: 회원 API(X-Device-Id)에는 세션이 없어 해당 없음. 코치 쪽지 탭·가입 신청은
>   기기 페어링(gym_manager_devices)이라 세션 만료와 무관 — 대시보드·주간 수업·명단이 대상.

> **D58 (2026-08-26 사용자 지시 "해지·일시정지·만료되면 그 권으로 예약된 건 사라지게" + "예약은 매일 전날 오전 11시부터 — 보기는 언제든지, 월요일 수업은 일요일 11시부터 일괄") — 회원권 무효 시 예약 소멸 + 예약 오픈 시각.**
>
> - **예약 소멸 (`classes.revoke_uncovered_reservations`)**: 회원의 **앞으로의** confirmed 예약·미승격 대기 각각을
>   예약 게이트와 같은 `pick_membership`(자기 행 점유 제외)로 다시 판정 — 그날을 덮는 유효권이 없으면 취소
>   (`late_cancel=False`, 횟수 점유 해제) + 빈자리 대기열 승격 + SSE `member_reservation_cancelled`. 호출처 =
>   즉시 해지(`admin_cancel_membership` — **환불은 소멸 뒤 잔여로**: 체육관이 지운 예약 몫은 돌려준다) ·
>   정지(`admin_pause_membership_v2`) · 수정(`admin_edit_membership` — 기간 단축·횟수 축소) · 자연 만료는
>   `sweep_uncovered_reservations` (expiry_scheduler 매시 :05 + 부팅 직후, 멱등). 기간 만료 시 해지는 만료일까지
>   유효하므로 즉시 소멸 없음(만료 뒤 스윕). 응답 `revoked: [{reservation_id, class_session_id, title, start_at}]`,
>   PC 토스트 "예약 N건 자동 취소".
> - **예약 오픈 시각 (`gym_class_settings.booking_open_hour`)**: 수업 **전날** 이 시 정각에 그날 수업 예약·대기 신청이
>   일괄로 열린다 (`classes.booking_open_at` = 수업일−1 의 hour:00, 체육관 시간대). 전이면 409 `BOOKING_NOT_OPEN`
>   "예약은 8/27 11:00 부터 가능합니다." — 신규·재활성·대기 신청 세 진입로, 승격은 예외(이미 열린 수업의 빈자리).
>   NULL/행 없음 = 제한 없음(테스트·신규 체육관). 마이그레이션 `_migrate_booking_open_hour` 가 기존 체육관 행을
>   11 로 채우고 행 없는 체육관엔 행을 만든다. PC 예약 설정 "예약 오픈 시각" 셀렉트(제한 없음 / 전날 00~23시,
>   새 행 기본 11). 목록 응답 `booking_open_at` 동봉 → 폰 `ClassSessionDto.isBookingNotOpen` → 주간보드 배지
>   **'오픈 전'**(탭하면 서버 문구 스낵바 — 정책 문구는 서버 하나). 보기는 종전대로 언제나.
> - 회귀: 서버 `tests/test_booking_window_revoke.py` 7건 (오픈 전 차단·대기 신청 차단·목록 open_at·NULL 해제·
>   즉시 해지 소멸+환불 3/3·정지 창 안만 소멸·기간 단축 소멸+승격·스윕 멱등) + 기존 환불 테스트 기대값 갱신 —
>   265 passed 1 skipped. `test_reservation_policy._set_limit` 은 오픈 시각 None 고정(시각 비의존). 앱 199+1 ·
>   골든 60 (`state_15_class_booking_not_open` 신규).
>   - 보고만: **자동 노쇼는 추후** (사용자 결정 20:28 "지금 구현하기는 어렵다") — 시스템이 출석을 아는 경로는 코치 명단 체크뿐(QR 폐지)이라
>     노쇼 면제 규칙은 코치가 찍을 때만 성립. 재개 안 = 명단을 한 명이라도 찍은 수업만 종료 1시간 뒤 나머지를 노쇼로 굳힘.
>   - **정지 중 열람 = 허용 (2026-08-26 21:29 사용자 결정 "정지하면 열람가능, 만료회원은 만료불가 형식")**: 일시정지 회원은
>     수업 내용(게시물)을 그대로 보고 **예약만** 막힌다(D58 소멸). 만료·해지 회원만 자물쇠("회원권 만료. 갱신 후 열람.").
>     정본 = `gym.py` WOD 목록 locked 판정 `status=active AND end_date>=오늘` — 정지는 status 가 active 로 남아 자동 통과.
>     정지 전용 잠금 분기 신설 금지. 코치 PC 실주행(COACH 계정 정지→폰 예약 소멸→해제) 캡처 = `project/hyphen-journey-2026-08-26/pause/`.

> **D57 (2026-08-26 사용자 지시 "횟수권도 있으면 좋겠는데 … 3회 9,900 이벤트 할 계획" + 차감 규칙 "1회 노쇼·20분 전 취소 노패널티, 2회 노쇼부터 차감, 20분 이후 취소도 1회는 노패널티 2회부터 차감") — 횟수권(세션권) 신설.**
>
> 회원권은 기간제 하나뿐이었다 (`gym_membership_plans`/`gym_plan` 에 `session_based` 유형만 휴면). 3면 같이 집행.
> - **자료**: `gym_memberships.session_total` (NULL = 기간제) · `class_reservations.membership_id`(어느
>   횟수권에서 나온 예약인지) · `late_cancel`(취소 시각이 시작 20분 전을 지났는가) ·
>   `session_charged`(지금 1회를 점유하는가). 요금제는 기존 `gym_plan.session_count` 를 PC 어댑터
>   (`/admin/gyms/<id>/membership-plans` GET/POST/PATCH) 가 드디어 노출·저장 — 횟수가 있으면
>   `plan_type='session_based'`, `duration_days` 는 **사용 기한**. 마이그레이션 `_migrate_session_pass_columns`
>   (`_migrate_class_tables` 의 표 재생성 **뒤**에 — 앞에 두면 새 컬럼이 같이 지워진다).
> - **규칙 (정본 `api/_membership.py`)**: 유효 = S5 와 동일(수업일 기준 active 기간·정지 창 밖).
>   기간제가 유효하면 횟수 안 깎음. 횟수권만 있으면 잔여 ≥ 1 인 권(만료 임박 순)에 붙이고
>   예약 확정 순간 1회 점유 → 잔여 0 이면 **예약·대기 신청 모두** 409 `SESSIONS_EXHAUSTED`
>   "회원권 횟수를 모두 사용했습니다." (유효권 자체가 없으면 종전 `MEMBERSHIP_REQUIRED`).
>   점유는 `recompute_session_charges` 가 **회원권 단위로 시간순 재계산** — 예약중·출석 = 점유 ·
>   제때 취소(시작 20분 전까지, `LATE_CANCEL_MINUTES=20`) = 해제 · 노쇼 = 회원권별 첫 1회 무료,
>   2회째부터 점유 · 늦은 취소 = 노쇼와 **별도 카운터**로 첫 1회 무료, 2회째부터 점유 ·
>   체육관 사정 취소(`admin_cancel_class`) = 해제·늦은 취소 아님. 코치가 출결을 되돌리면 다시
>   세므로 카운터 드리프트 없음 (예: 첫 노쇼를 출석으로 고치면 둘째 노쇼가 무료가 된다).
>   대기열 승격(`_promote_waitlist`)도 잔여를 재검사해 0 이면 건너뛴다.
> - **응답**: `/member/me/memberships`·PC 이력 GET 에 `session_total·session_used·session_remaining·
>   no_show_count·late_cancel_count·free_no_show_left·free_late_cancel_left` 동봉 (기간제는 null/0).
>   회원 취소 DELETE 응답에 `late_cancel·session_charged·message` — 문구("… 1회 차감" / "… 이번은
>   차감 없음")는 서버가 정본, 폰은 그대로 스낵바.
> - **PC**: 회원권 설정 표·모달에 '횟수 (회) — 비우면 기간제' 칸(+ 차감 규칙 한 줄 안내) ·
>   발급 모달은 종류를 고르면 횟수 자동 · 이력 표 종류 아래 "1/3회 사용 · 잔여 2회 · 노쇼 면제 1회 ·
>   늦은 취소 면제 1회" · 수정 모달 횟수 칸 · 회원 리스트 회원권 칸 "잔여 2회 / 3회".
> - **폰**: `Membership.isSessionPass/sessionProgress` + `coversDay` 가 잔여 0 이면 false → 주간보드
>   '회원권 필요' 배지 재사용(신규 배지 없음). 내 정보 요약 "2회 남음 · 27일 후 만료", 카드 막대 =
>   사용 횟수 비율("1회 사용 / 2회 남음") + "노쇼 면제 1회 · 늦은 취소 면제 1회 남음". 취소 다이얼로그는
>   시작 20분 전을 지났으면 "횟수권은 1회 차감될 수 있습니다" 한 줄(`kLateCancelMinutes` = 서버 상수 거울).
>   예약·취소 성공 뒤 `GymState.refreshMemberships()` 로 잔여를 다시 받는다 — 에뮬 실주행에서
>   내 정보가 앱 재시작 전까지 옛 잔여(3회)를 보이던 것을 잡음 (기간제는 영향 없음).
> - 회귀: 서버 `tests/test_session_pass.py` 10건(점유·소진·제때/늦은 취소·노쇼 무료 1회·자가 치유·
>   기간제 우선·대기 신청 차단·승격 skip·수업 취소 해제·폰/PC 응답·발급/수정) — 257 passed 1 skipped.
>   앱 199 · 골든 59 (`state_14_mypage_session_pass` 신규, 기존 58 무변화).
> - **PC·코치 계정 실주행 (18:08~18:22, 사용자 "코치거 줬다가 회원권 삭제·수정·권한·기능수정 체크")**:
>   COACH(role coach) 로 로그인해 횟수 수정(3→5→4→5→6)·즉시 해지·재발급·요금제 수정/삭제(비활성)/복구
>   전부 통과 — `require_staff` 가 boss/manager/coach 동일 (대전제 1). 발견·수정 3건:
>   (a) 즉시 해지 환불이 횟수권에도 **일수** 비례(₩9,773)로 계산 → 잔여 횟수 비례(3/5 → ₩5,940)로
>   서버 `admin_cancel_membership` + PC 미리보기 수정, 테스트 +1 (258 passed).
>   (b) PC 에서 횟수를 고쳐도 폰이 재시작 전까지 옛 잔여 — 서버가 쏘던 `membership.updated/paused/resumed`
>   를 `GymState._reloadTriggers` 에 추가 (해지·발급은 이미 듣고 있었음). (c) 해지된 회원권이 내 정보에
>   "3회 남음" 으로 남아 보임 → 활성권이 없으면 "해지됨/만료됨" + 카드 한 줄. '회원권 삭제' 는 없고
>   해지(기간 만료/즉시)만 있음 — 의도된 설계(이력 보존).
> - 보고만: PC 발급 모달에서 종류를 고른 뒤 시작일을 바꾸면 종료일이 재계산되지 않음 (D57 이전부터).
>   에뮬 `INSTALL_FAILED_INSUFFICIENT_STORAGE` — `adb install -r` 이 조용히 옛 APK 를 남긴 것이 "첫 빌드
>   누락" 의 정체 (`dumpsys package … lastUpdateTime` 으로 확인). 재설치 전 `adb uninstall` 로 공간 확보.

> **D56 (2026-08-26 사용자 지시 "전부 한국이야 걱정하지마. 이거 확실히 못박아놔") — 전 체육관 = 한국, 시간대 KST 하나로 확정. 3면 대전제 4번.**
>
> - D55 4단계의 `gyms.timezone` 은 'Asia/Seoul' **한 값만** 가진다. 서버 `api/_time.py tz_of` 는
>   이름이 무엇이든 항상 KST 를 돌려주고(다른 값은 경고 로그), 테스트
>   `test_tz_of_is_always_kst_korea_only` 가 못박는다. 컬럼은 이미 프로드에 나간 마이그레이션이라
>   그대로 두되 값은 고정 — 설정 화면 없음.
> - D55 에서 "남은 경계" 로 적었던 `func.date()` 13곳(저장 벽시계 KST 축)은 **갭이 아니다** —
>   한국 전용이라 그 축이 곧 정답. 범위 전환·다른 시간대 대비 작업은 금지 (갭대장 22차 종결).
> - 폰·PC 의 표시 변환(`toLocal()`)은 그대로 — 해외에서 앱을 열어도 같은 순간을 기기 시간대로
>   그리는 것은 '표시' 규칙이지 체육관 시간대가 아니다.

> **D55 (2026-08-26 사용자 결정 "다른곳처럼 (표준대로) 우리도 저렇게 할까?" → 예) — 시간대 표준 채택: 저장·전송 = 오프셋 포함 순간 · 표시만 시간대 변환 · '하루' = 체육관 시간대.**
>
> - **1단계 서버 직렬화 한 곳** — `api/_time.py` 신설. 응답 순간값 datetime `.isoformat()` 94줄
>   (+ DB datetime→날짜 유도 8곳 `kst_date`)을 `iso()` 로 — naive(SQLite)=KST 벽시계로 읽어 `+09:00`
>   을 붙이고, aware(Postgres)는 KST 로 변환. SQLite·Postgres 가 같은 문자열을 내린다. 날짜
>   컬럼(String(10)) 62줄은 시간대 무관이라 그대로. 클라이언트 ISO 입력 6경로(수업 생성 · 목록
>   from/to 2벌 · 공지 start/end 2벌)는 `parse_client_time` 한 곳(Z·오프셋·없음 전부 KST).
>   `date.today()` 9곳 → `kst_today()`(Railway UTC 컨테이너의 한국 저녁 하루 밀림). 파일마다 있던
>   `KST`·`_now`·`_kst_today`·`_kst_wall`·`_as_kst`·`_to_kst_naive`·`_parse_to_kst_naive` 를 이 모듈
>   하나로 (§0-B rename — 이름사전 도메인 14). 스트릭 계산의 `now_utc`(실은 KST) 이름·축 정정.
> - **2단계 앱 파서 통일** — 서버 순간값 `DateTime.parse/tryParse` 26곳(업적·공지·쪽지·피드백·
>   체육관·기록·채팅)을 `parseServerTime(...).toLocal()` 로. 표시 직전 `.toLocal()` 이라 KST 폰은
>   픽셀 동일(골든 58 무변화), UTC 기기도 같은 순간을 그린다. 전송은 수업 목록 `from/to` 를
>   `toUtc().toIso8601String()`(Z) 으로 — 오프셋 포함. 날짜 전용(회원권·락커 기간·로컬 저장값) 17곳은
>   대상 아님.
> - **3단계 테스트 시계** — `tests/*.py` naive `datetime.now()` 17곳 → `datetime.now(KST)` (UTC CI 에서
>   서버 `now_kst` 와 어긋나지 않게). `_today_class_or_skip` 자정 skip 은 시간대와 무관(2시간 뒤가
>   내일이 되는 문제)이라 유지.
> - **4단계 체육관 시간대 자리** — `gyms.timezone` String(40) default 'Asia/Seoul' + idempotent
>   ADD COLUMN. `_time.py` `tz_of·date_in·day_bounds_wall·gym_tz·gym_today·gym_date`(캐시 없음
>   §2-A-5). 하루 예약 한도는 `func.date` 대신 체육관 하루 `[lo, hi)` 범위, 회원권 게이트는
>   `gym_date`, PC 관리자 '오늘' 23곳은 `_gym_today()`(세션 체육관). PC 설정 화면은 보류(HYPHEN
>   1곳 — 값 고정). **남은 경계**: `func.date(...)` 13곳(admin 9 · classes 3 · gym 1 — 출석 통계·
>   오늘 수업 집계)은 저장 벽시계(KST) 축 — 체육관이 KST 라 지금은 동일, 다른 시간대 체육관이
>   생기면 `day_bounds_wall` 범위로 전환 (갭대장 21차).
> - 회귀: 서버 247 passed(+10 `tests/test_time_std.py`) · 앱 198 · 골든 58 무변화.

> **D54 (2026-08-26 사용자 지시 "s6 하고, s7 시각이 지나면 안보이게, s9 는 당연한 것") — 가입 폼 BACK 확인 · 서버 시각 KST 고정 · HYPHEN 전용 앱 확정.**
>
> - **S6** — 가입 신청 폼(`self_signup_screen.dart`)을 `PopScope(canPop:false)` 로 감싸 입력이
>   하나라도 있으면 '작성을 그만둘까요? / 입력한 내용이 사라집니다.' (계속 작성 · 나가기) —
>   비어 있으면 그대로 나간다. 제출 중엔 BACK 무시. 골든 `state_13_signup_back_dialog`.
> - **S7 근본 원인은 시간대 파싱** — 서버(SQLite)는 KST 벽시계를 오프셋 없이 내려주는데
>   `DateTime.parse` 가 기기 시간대로 읽어, 기기 시계가 UTC 면 20:00 KST 수업이 9시간 뒤로
>   밀려 시작이 지난 뒤에도 '예약' 이 살아 있었다(에뮬 1차 S7 = 에뮬 UTC 시계 때문).
>   `core/time_format.dart parseServerTime` — 오프셋 없으면 +09:00 고정, 있으면(Postgres
>   프로드 aware) 그대로. `ClassSessionDto`·`MyReservationItem`·명단 시트 `_notStarted`·
>   `hhmmIso` 가 이걸 쓴다. KST 폰에서는 종전과 픽셀 동일(골든 무변화), 시간대가 다른 기기
>   에서도 '시작 지남'→'종료' 배지·'예약' 숨김이 서버(KST)와 같은 순간에 일어난다.
> - **S9 는 결함이 아니라 결정** — 이 앱은 **HYPHEN 체육관 1곳 전용**. 가입 신청 대상이
>   'HYPHEN' 으로 고정된 것은 의도. 다른 체육관을 받게 되면 그때 선택 UI 를 (숨긴 채) 살리는
>   식으로 확장 — 지금은 손대지 않는다. `_kBrandGymName` 주석에 같은 결정 기록.
> - 회귀: 앱 198건 · 골든 58장.

> **D53 (2026-08-26 사용자 결정 "회원권 없으면 예약·대기 당연히 안 된다. 2번은 하고") — 회원권 게이트 (S5) + 문구·코치 UX (S8·S10).**
>
> D52 에서 보고만 했던 S5·S8·S10 을 사용자 결정으로 집행. S6·S7·S9·S11 은 계속 보고만.
> - **S5 회원권 게이트 (차단, 무료 제공 없음)** — 서버 `classes._membership_blocked`
>   한 곳: `_daily_limit_blocked` 와 같은 자리에서 신규 confirmed · 취소 후 재활성 ·
>   대기 신청 세 진입로 + `_promote_waitlist` 승격 재검사가 전부 지난다.
>   유효 = `gym_memberships.status='active'` · `start_date ≤ 수업일 ≤ end_date` ·
>   수업일이 정지 창(`pause_start ≤ 날 < pause_end`, admin.py `is_paused` 와 같은 배타
>   경계) 밖. 아니면 `MEMBERSHIP_REQUIRED`(409) "유효한 회원권이 없어 예약할 수
>   없습니다." **기준일 = 수업 시작일(KST)** ('오늘' 이 아님 — 하루 한도와 같은 축.
>   미리 결제한 다음 달 권으로 다음 달 수업은 잡히고, 이번 달 권으로 만료 뒤 수업은
>   막힌다). 회원권을 한 장도 안 준 승인 회원(에뮬 member 계정)이 예약·대기·승격을
>   전부 통과하던 갭.
>   폰: `Membership.coversDay` + `GymState.hasMembershipOn(day)` 가 같은 규칙의
>   표시용 거울 — 주간보드 `ClassLine.member` 가 그날 유효권이 없으면 예약·대기 대신
>   **'회원권 필요'** 배지(탭하면 서버 409 문구를 스낵바로 — 정책 문구는 서버 하나).
>   목록을 아직 못 받은 상태(`_membershipsLoaded=false`)는 '없음' 으로 그리지 않는다.
> - **S8 서버 노출 문구 금지어** — `api/*.py` 문자열 리터럴 117줄 '박스'→'체육관'
>   (인계장의 8곳은 표본이었고 실제는 11개 파일 — `_err(...)`·`"error":`·엑셀 컬럼
>   '박스명'). 주석·docstring·내부 식별자(인박스 등)는 그대로. 회귀 테스트는 응답
>   문구를 단언하지 않아 무영향.
> - **S10 코치 UX 2건** — (a) 코치 셸 로그아웃이 확인 없이 기기 페어링을 풀던 것 →
>   `HkDialog.confirm`(회원 `_confirmSignOut` 과 같은 골격, 문구 '이 기기와 코치 연결이
>   끊깁니다'). (b) 명단 시트 머리의 코치가 login_id('admin') 로 뜨던 것 → 서버
>   `admin_list_class_reservations` 가 `coach_name`(gym_managers.name, login_id 매칭)
>   동봉, 폰 `ClassRoster.coachDisplay` = 이름 → 아이디 폴백.
> - 회귀 게이트: 서버 `tests/test_reservation_policy.py` +8 (회원권 없음·오늘 만료·
>   미래 시작·비active·정지일·대기 신청·재활성·승격 skip) — 237 passed 1 skipped.
>   기존 예약 테스트 회원은 헬퍼가 ±60일 active 권을 기본 발급. 골든
>   `state_11_class_membership_required` · `state_12_coach_logout_dialog` 신규,
>   `boss_03`·`state_10` 재생성(코치 이름). 57장.
> - 이름사전 +2 행 (MEMBERSHIP_REQUIRED · coach_name) · 갭대장 19차.

> **D52 (2026-08-26 사용자 지시 "1 하고 다시보고") — 에뮬 실주행 갭 4건 수정 (S1~S4).**
>
> 8/26 로컬 서버 + 에뮬레이터 회원·코치 1바퀴 실주행(캡처 37장)에서 나온 갭 중
> 사용자가 고른 4건. 정책 결정이 필요한 S5~S10 은 보고만 (README 인계 archive).
> - **S1 치명 — 로그아웃 뒤 같은 폰 가입 신청이 기존 승인 회원에 붙음.**
>   앱: `DeviceIdService.reset()` 신설 — 회원 `AuthState.signOut()`·코치
>   `CoachShell._logout` 이 이 기기의 device_id 를 새 UUID 로 되돌린다 (로그인은
>   서버가 내려주는 값을 `adopt` 하므로 기록은 그대로 이어짐). 로그아웃 3경로
>   (내 정보·승인 대기 셸·계정 삭제)와 코치 로그아웃이 `GymState.resetLocal()` 로
>   옛 소속 캐시도 비운다.
>   서버: `POST /member/gyms/<gid>/self-signup` 의 같은 기기 중복 분기가 **다른
>   아이디**의 자격증명이 이미 이 기기에 묶여 있으면
>   `DEVICE_BOUND_TO_OTHER_ACCOUNT`(409) — 종전엔 기존 회원 행에 새 아이디·
>   비밀번호를 덮어써 승인·회원권이 남에게 넘어갔다. 같은 아이디 재신청·
>   자격증명 없는 기기 전용 회원은 그대로 통과.
> - **S2 — 회원 주간 목록 `reserved_count` 가 confirmed 만 셈** →
>   `confirmed+attended` (정원 판정·대기 승격과 같은 기준). 코치가 출석을 찍을수록
>   회원 화면 예약 숫자가 줄던 결함.
> - **S3 — 수업 시작 전 출석 체크 통과** → `PATCH /admin/reservations/<id>/status`
>   가 attended·no_show 를 시작 시각 전엔 `CLASS_NOT_STARTED`(409). confirmed
>   (되돌리기)는 언제든. 폰 명단 시트는 같은 기준(`appClock`)으로 배지를 잠그고
>   '출석 체크는 수업 시작 후' 한 줄. (종료 컷오프 CLASS_ENDED 와 짝 — 예약은
>   종료까지, 출석은 시작부터.)
> - **S4 — 쪽지 발신자 'facing'**: 코치 쪽지는 체육관 공용 owner_hash 로 나가는데
>   그 해시엔 프로필이 없어 해시 조각이 이름으로 떴다. `coach_note._profile_display`
>   폴백 = 체육관 대표 스태프(boss 우선·재직) 이름 → 없으면 체육관 이름.
>   해시 값에 무관하므로 프로드 gym 2 owner_hash 를 손대지 않는다.
> - 회귀 게이트: 서버 `tests/test_reservation_policy.py` +3 ·
>   `tests/test_member_detail_linkage.py` +1 · `tests/test_coach_note_sender_display.py`(4 신규)
>   — 228 passed 1 skipped. 골든 `boss_03_class_roster`(시작 지난 수업으로 fake 이동) ·
>   `state_10_roster_before_start` 신규.

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

- **사장은 운영자**, PHASE5 부터는 **외출·이동 중 폰 보조 운영 가능** (linko 격차 해소 — `docs/_archive/PHASE5_ROADMAP.md`(2026-08-13 폐기 이동) 참조). PC 가 주, 폰이 보조. **폰 사장 로그인 = PC 동일 ID/PW** 사용. 회원·코치는 device_hash 익명 유지.
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
| `gym_memberships` | 회원권 관리 | member_id, plan_name, start_date, end_date, price, status (active/expired/refunded), refund_amount, refunded_at, **session_total** (D57 횟수권 — NULL=기간제; 사용 횟수는 `class_reservations.session_charged` 집계) |
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
| POST | `/api/v1/auth/login` | ID/PW (+X-Device-Id) | **D42 통합 로그인 — 창구는 하나.** 서버가 `kind: coach\|member` 판정 후 각자 payload 반환. 앱(폰)의 유일한 로그인 경로 |
| POST | `/api/v1/admin/login` | ID/PW → 세션 쿠키 | 코치 로그인 — **관리자 웹 전용** (D42 이후 앱은 `/auth/login` 사용) |
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

> 등록일: 2026-05-23. 상세 DDL: `docs/_archive/PHASE4_ROADMAP.md`(2026-08-13 폐기 이동) 각 §1.x·§2.x.
> Migration 방법: `services/facing/models/base.py` `_migrate()` 함수에 `CREATE TABLE IF NOT EXISTS` 패턴 추가 (기존 Phase 1 방식 동일).

| # | 테이블 명 | PHASE4 Week | 모듈 | 브리프 §5 다이어그램 갱신 필요 |
|---|---|---|---|---|
| 1 | `class_session` | Week 1 | §1.1 예약 | 예 |
| 2 | `class_reservation` | Week 1 | §1.1 예약 | 예 |
| 3 | `class_waitlist_promotion` | Week 1 | §1.1 예약 대기열 audit | 예 |
| 4 | `notification_template` | Week 3 | §1.2 카카오 알림톡 (D60 폐기 — 템플릿은 `note.py NOTE_TEMPLATES` 코드 상수, 표 없음) | 예 |
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

> PHASE4 구현 착수 시 §13.2 에 신규 endpoint 추가 의무. 아래는 예고 목록 (상세: `docs/_archive/PHASE4_ROADMAP.md`(2026-08-13 폐기 이동) 각 §).

| 모듈 | 신규 엔드포인트 수 | 비고 |
|---|---|---|
| §1.1 예약 | 6 | POST·GET·DELETE·noshow·SSE 이벤트 |
| §1.2 알림톡 (D60 → 앱 쪽지) | 2 | dispatch·이력 |
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

> 등록일: 2026-05-23. 상세 plan: `docs/_archive/PHASE5_ROADMAP.md`(2026-08-13 폐기 이동).
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

### 11.9. 코치 앱 = 간단 3탭 셸 등록 (2026-08-14 사용자 설계 · 같은 날 v2 확정)

- **결정 (v2, 2026-08-14 12:52 사용자 확정)**: 코치는 PC(디테일 운영)와 앱(간단)
  둘 다 쓴다 (§2-0 대전제 ③ 재확인). 앱 쪽 코치 경험은 **CoachShell 3탭** 하나로 고정:
  ① 회원 현황 — 승인 대기·로스터·활동 통계 (기존 CoachDashboardScreen 재사용)
  ② 예약 조회 — 오늘 예약·출석·수업 명단 (기존 BossDashboardScreen 임베드)
  ③ 쪽지 — 핀 공지 + 회원 쪽지 스레드 (기존 MessagingScreen 재사용)
- **v1(예약·수업·내 정보)에서 바뀐 것**: 수업 탭(BoxWodScreen) 삭제 — 수업 안내는
  PC·회원 앱 몫. 내 정보 탭(MyPageScreen) 삭제 — 로그아웃은 예약 조회 AppBar 에
  이미 있다.
- **v2.3(2026-08-12) "코치 진입 숨김" 부분 폐기**: 진입 버튼(`_kShowBossEntry`) 원복.
  "코치 주 창구 = PC" 는 유지 — 앱은 보조·간단 창구다.
- **정리**: 대시보드의 가짜 하단탭(onTap 빈 함수 4개) 삭제 — 실탭은 CoachShell 소유.
- **백엔드 — 코치 기기 폴백 (services/facing, 2026-08-14)**: 회원 현황·쪽지 탭은
  회원 API(X-Device-Id)를 쓰는데, 로그인만 한 코치 기기는 owner_hash 도
  GymMember 도 아니라 "체육관 미가입" 이 났다. admin_login 이 페어링하는
  `GymManager.device_hash`(재직 중)를 스태프 기기 증표로 인정 —
  `api/roles.py is_staff_device()` 하나로 판정하고 `/gyms/mine`·회원 목록/승인·
  WOD 목록·공지(G13 기기판)·coach_note 게이트(`_is_coach_device`, 구 `_is_owner`
  개명)가 이를 쓴다. 회귀 = `tests/test_coach_device_fallback.py`.
- **미해결**: 쪽지 신원은 PC 규약(admin.py `_staff_device_hash`)과 동일하게
  coach 는 본인 페어링 해시다 — 회원이 시작하는 스레드는 owner_hash 로만 가므로
  boss 아닌 코치 기기에는 회원 발신 스레드가 안 보인다 (PC 와 같은 한계).
- **스키마 변경 없음.**
- **v3.3 (2026-08-18 사용자 지시)**: 코치 폰 = **2탭**으로 축소 — "코치는 대부분
  PC. 폰 코치는 진짜 기본만". ① 예약 현황 — BossDashboardScreen 임베드 (오늘
  예약·출석·수업 명단·수업 등록(G24) 포함, 구 예약 조회 탭 그대로) ② 수업 —
  회원 셸과 **동일한 BoxWodScreen 재사용** (variant 신설 없음, 코치 데이터
  접근은 위 코치 기기 폴백이 처리 — 프론트 role 분기 없음). 회원 현황·쪽지
  탭 제거 (숨김 = 코드 보존 — 화면 파일·배선 잔존, 셸에서만 제외). 가입 승인은
  예약 현황 탭 '회원 관리' 버튼 → CoachDashboardScreen push 로 잇고 (구
  '구현 예정' 스낵바 → 실배선), 쪽지는 수업 탭 종(InboxBellAction) →
  MessagingScreen push 로 유지. 백엔드·스키마 변경 없음.

### 11.10. 체육관별 업적(게임) 설정 — PC 코치 설정 → 회원 폰 연동 (2026-08-20 사용자 지시)

- **결정**: 코치가 PC 설정에서 업적(게임 요소)을 체육관 단위로 조절하면 회원
  휴대폰에 그대로 반영된다. 앱은 서버 응답을 그리기만 하므로 **앱 코드 변경 0**.
- **신규 테이블**: `gym_achievement_settings` (gym_id PK·FK, is_active,
  disabled_codes_json, updated_at) — `gym_point_settings` 패턴 (행 없음 = 전부 활성).
- **신규 endpoint 2 (§13 카탈로그 대상)**: GET·PATCH
  `/api/v1/admin/gyms/<gid>/achievement-settings` (`@require_staff` + 감사로그).
- **회원 연동 의미론**: 마스터 off = `/api/v1/achievements` 카탈로그·해금 빈 응답
  + `/check` 신규 해금 중단. 개별 비활성 code = `is_hidden` 과 동일 — 미해금만
  숨고 **기해금 기록은 계속 보인다**. 판독 단일 지점 =
  `services/achievement_checker.py gym_achievement_policy()`.
- **PC**: `/settings/achievements` (settings_points 패턴 — 마스터 토글 + 업적별 토글).
- 회귀 = `tests/test_achievement_settings.py` (7건).

**v2 (같은 날 2차 — 사용자 지시 "engine 이 없는데 왜 있냐 + 픽토그램·희귀도·포인트·비고")**
- **카탈로그 대수술**: Engine 스냅샷·Tier·신체(1RM·체중)·프리셋 기반 등 원천 소멸
  트리거의 업적 ~70종 삭제 — 시드 22종(수업 기록·PR 기반)만 잔존. 목록 정본 =
  `models/base.py DEAD_ACHIEVEMENT_TRIGGERS` (시드 프루닝 + 마이그레이션 동일 목록).
  G19 '숨김' 정책을 '삭제' 로 승격. 해금 기록은 보존 (카탈로그 없으면 화면 미노출).
- **카탈로그 코치 편집 3필드**: `achievements_catalog` +icon(픽토그램 슬러그)·
  +points(달성 시 자동 적립, member_points earn/created_by='achievement')·
  +repeat_kind(1회/반복 — 표기용, 반복 재적립 엔진은 후속). 희귀도(rarity)도 PC
  드롭다운 편집 — 시드는 코치 편집 필드를 덮어쓰지 않는다.
- **신규 endpoint**: PATCH `/api/v1/admin/achievements/<code>` (rarity·icon·points·
  repeat_kind — 카탈로그는 전역 1벌, 1샵 운영 전제).
- **앱**: 업적 카탈로그·희귀도·포인트는 서버 응답 그대로 — 필터 탭에서 빈 그룹
  (Tier·Engine·히든) 삭제만 반영. 회귀 = 백엔드 131 · 앱 167 · 골든 42장.

### 11.11. 리워드 규칙 엔진 — GTM 식 행동/조건/보상 빌더 (2026-08-20 사용자 승인·구현)

- **설계 정본 = `docs/PLAN-reward-rules.md`** (승인 확정: 주=ISO 월요일 · 미소급 ·
  custom 인증 기본 코치 승인 · 카테고리 3분류 ①자동/②기록 로그/③코치 인증).
- **신규 표 3**: `gym_reward_rules`(규칙) · `gym_reward_grants`(지급, UNIQUE
  rule×member×window_key = 반복 재적립 중복 차단) · `gym_action_logs`(custom 인증
  원장, UNIQUE 1일 1회). `achievements_catalog` +gym_id (커스텀 업적 `RULE_{id}`).
- **엔진**: `services/reward_engine.py` 단일 판독 — 훅 3곳(출석 동기화 ·
  `save_wod_history` · custom 승인) + `/achievements/check` 보조 스윕.
  달성 시 member_points earn(created_by='reward_rule') + 업적 해금.
- **API**: admin reward-rules CRUD·grants·action-logs 승인/대리 + member
  `reward-rules/<id>/log`·`me/reward-progress` (§13 카탈로그 대상).
- **PC**: `/settings/achievements` 에 카테고리 3섹션 + 문장형 빌더 + 인증 대기함.
- **앱**: 해금 축하 = 토스트(기본 픽토그램)+컨페티 캐논 2초, 스냅샷 diff 로 서버
  훅 해금도 감지. 완료 기록 시트 v3.3 — 수업 내용 인계·동작별 SCALED/RXD
  (코치 무게 자동)·ELITE 제거.
- **P3 도전 카드 구현 (2026-08-20 밤)**: 홈 마일스톤 아래 도전 섹션 —
  규칙 문장+진행바+달성 ✓+승인 대기 건수, custom 은 [인증하기] 시트(1일 1회,
  409 안내). 자동 인정 즉시 지급 시 업적 diff 로 축하 연동. 규칙 없으면 숨김.
- **P4 트리거 4종 구현 (2026-08-20 저녁 — 설계 = `docs/PLAN-record-structures.md` Part B)**:
  reservation(예약한 날 기준, 취소 제외) · payment(paid, refund 제외) ·
  membership_extend(2번째 발급부터, 누적 조건만) · birthday(당일~+7일 유예,
  연 키 매년 반복, 조건 슬롯 서버 강제). 전부 카테고리 1. 기존 DB 의
  trigger CHECK 는 `_migrate_reward_trigger_enum`(writable_schema)으로 확장.
  훅 +5곳: 예약 확정 3경로·결제 입력·회원권 발급(연장+연동 결제), 생일은
  출석 훅 동승 + 스윕. 앱 변화 없음 (문장·진행률 = 서버 생성).

### 11.12. 수업 유형별 기록 구조 + 발전 측정 (2026-08-20 사용자 승인·Q1+Q2 구현)

- **설계 정본 = `docs/PLAN-record-structures.md` Part A** (확정: EMOM 성공 라운드
  1칸 · Strength 최고 무게+reps 1줄 · AMRAP 라운드 우선, 동라운드면 reps).
- 점수 = 유형별 단위: for_time 시간↓ / amrap 라운드+reps↑ / emom 성공 라운드↑ /
  **strength 무게↑** (`gym_wod_results` +weight_kg·weight_reps·is_pr·signature).
- **비교·PR = 서버 단일 판독** (`services/wod_compare.py`): 시그니처(동작·횟수
  시퀀스 해시, strength 는 동작 단위, 자유 서술 첫 줄 폴백)로 같은 수업 자동
  매칭 → 저장 응답 `comparison`(직전 델타 한국어 메시지 + 역대 최고 PR,
  For Time 0.5% 임계). 첫 기록 = PR 아님. 수업 기록 PR 은 리워드 'pr' 트리거
  원천에 합류 (§11.11).
- 앱: 완료 기록 시트 4분기 + 저장 스낵바 비교 메시지 표시 (계산 0). 코치 등록
  시트 STRENGTH 추가 (백엔드 ALLOWED_WOD_TYPES 정합 — 구 드리프트 정정).
- **실기 결함 6건 수정 (2026-08-20 밤 탐색 테스트)**: ①strength 상세 타이머
  숨김(For Time 스톱워치 오작동·시간 기록 오염 차단) ②인증 승인/거절 →
  회원 쪽지 통지(coach_note) ③히스토리 0초 기록 '-' 표시 ④wods 목록에
  `my_result` 동봉 → 카드 '기록 {값}' 배지·시트 프리필·덮어쓰기 안내
  ⑤요청/댓글 빈 전송 안내(시트는 인라인 — 스낵바는 모달 뒤에 가려짐 실측)
  ⑥`reward_rule.changed` SSE → 도전 카드 자동 갱신. 전부 에뮬레이터 재검증.
- **Q3 구현 (같은 날 저녁)**: `wods/<id>/my-history`(같은 시그니처 내 기록,
  라벨 서버 완성) · `strength-board`(리프트별 역대 최고) → 수업 상세 "내 이전
  기록" 섹션 + 내 정보 메뉴 "최고 기록"(1RM 보드 화면). v3.4 이전 기록은
  signature NULL 이라 이력 미포함 (신규 축적). 기존 표시용 판정기 2종
  (admin_leaderboard For Time is_pr · 앱 PrDetector)은 온존 — 통합 후속 (PLAN A-5).

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
