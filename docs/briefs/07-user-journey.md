# §7 User Journey — 첫 사용 30초 가치 도달 · 페르소나별 분기 · 5 메인 탭 · Retention 흐름

> **문서 버전**: v1.0 · 2026-04-28
> **대상 독자**: PM / Eng Lead / UX Designer
> **소속 섹션**: ABOUT.md §7 확장 (6-pager 형식)
> **단일 진원지**: 이 문서가 User Journey 흐름의 SSOT. ABOUT.md §7 요약은 이 문서를 참조.

---

## 1. TL;DR

FACING 의 사용자 흐름은 단 하나의 원칙으로 설계된다.

> **Splash → Tier 부여까지 30초. 그 이후 모든 것은 Tier 를 강화하기 위한 구조다.**

일반 피트니스 앱은 가입·결제·관심사 설문으로 5분을 태운다. FACING 은 체중·키·나이·성별 4개 필수 입력 후 1.8초 Engine 측정으로 Tier 를 즉시 부여한다. 1RM·UB·카디오는 옵셔널이다. 빈 칸은 알고리즘이 추론한다.

Tier 부여 = 페이싱 전략을 받을 자격 획득. 이것이 "30초 가치 도달"의 의미다.

---

## 2. Problem — 일반 피트니스 앱의 첫 사용 마찰

엘리트 athlete 가 일반 피트니스 앱에서 이탈하는 이유는 3가지다.

### 2-1. 첫 화면에서 광고·결제를 요청한다

- 무료 체험 7일 카운트다운 → FOMO 설계
- 결제 화면 없이 핵심 기능 진입 불가
- Games-Player 급은 이 순간 앱을 삭제한다

### 2-2. 온보딩이 길다

| 앱 카테고리 | 평균 온보딩 단계 | 가치 도달 시점 |
|---|---|---|
| 일반 피트니스 앱 | 7~12 단계 | 첫 운동 세션 완료 후 |
| CrossFit 기록 앱 | 4~6 단계 | 첫 WOD 등록 후 |
| FACING (목표) | 3 단계 (필수 입력·Engine·Tier) | Tier 부여 시점 = 30초 |

### 2-3. 엘리트 athlete 의 언어를 모른다

"오늘도 열심히!" 류 응원 카피, 칼로리 소모 중심 피드백, "건강" 목표 설정 — 모두 Games-Player 급이 인정하지 않는 프레임이다. HWPO · NOBULL 이 이 사용자층을 확보한 방식은 반대다. 숫자만, 기록만, 명령형만.

---

## 3. Tenets — 사용자 흐름 원칙

### T1. 30초 가치 도달

온보딩 완료(Tier 부여) 시점까지 30초. 이 숫자는 KPI 이자 설계 제약이다. 새 화면·새 입력 필드 추가 시 이 수치에 영향을 미치는지 먼저 검토한다.

### T2. 익명 device_id

이메일·소셜 로그인 없이도 Engine 측정과 페이싱 계산이 가능하다. UUID v4 를 최초 실행 시 SharedPreferences 에 저장하고 모든 API 요청에 `X-Device-Id` 헤더로 전송한다. 개인정보 수집 없이 사용자 데이터를 서버에 귀속시키는 구조.

Sign in 은 박스 가입·코치 기능·데이터 동기화가 필요한 시점에만 요청한다.

### T3. 옵셔널 입력

1RM · UB · 카디오 데이터가 없어도 Tier 를 받는다. 빈 칸은 체중·키·나이·성별 기반 자동 추론 알고리즘이 채운다. 추론값 기반 페이싱은 정확도가 낮을 수 있다는 사실을 결과 화면에서 명시한다.

### T4. Intro 1회만

`intro_seen` 플래그(SharedPreferences) 가 `true` 면 Splash 이후 곧바로 Sign in 으로 이동한다. Intro 3 페이지는 첫 설치 사용자 전용.

### T5. 페르소나별 분기

같은 앱 안에서 10개 페르소나가 서로 다른 화면과 권한을 경험한다. 분기는 백엔드 응답의 `role` + `gym_status` 두 필드로 결정된다. 프론트에서 role hardcode 금지.

---

## 4. Approach — 화면별 상세 흐름

### 4-1. Splash (1.5초)

- `bg #0A0A0A` 위 `brandLogo` 토큰 72sp w800 ls-2.4 "FACING" 표시
- 하단 Quote 1개 랜덤 노출 (10개 풀, 저자 포함)
- 동시 처리: `intro_seen` 플래그 확인 · device_id 초기화 또는 불러오기 · 네트워크 상태 확인
- 이동: `intro_seen = false` → Intro 1 / `intro_seen = true` → Sign in

### 4-2. Intro (3 페이지, 1회만)

| 페이지 | 헤드라인 | 캡션(한글) | 핵심 전달 |
|---|---|---|---|
| Intro 1 | `Split defines rank.` | Tier 에 맞춰 Split 과 Burst 를 자동 계산. | 페이싱 가치 |
| Intro 2 | `6 metrics. Measure Engine.` | 6 카테고리 점수로 본인 수준을 정량화. | Engine 측정 |
| Intro 3 | `Start.` | — | CTA |

- 우측 하단 `Skip` (단어 1개, 마침표 없음): 곧바로 Sign in 이동. `intro_seen = true` 처리.
- Intro 3 에서 `Start` → Sign in 이동. `intro_seen = true` 처리.
- 뒤로가기 제스처: Intro 페이지 내 이전 이동. Splash 로 돌아가지 않는다.

### 4-3. Sign in

| 옵션 | 설명 | 내부 처리 |
|---|---|---|
| 네이버 로그인 | OAuth 2.1 + PKCE | 서버 세션 발급 → profile 연결 |
| 카카오 로그인 | OAuth 2.1 + PKCE | 동일 |
| 데모 (5 계정) | debug 모드 한정 표시 | PersonaSwitcher device_id 덮어쓰기 |

**5 데모 계정 목록** (debug only):

| 계정 | 매핑 페르소나 | role | gym_status |
|---|---|---|---|
| admin | 변민준 (admin_01) | admin | — |
| coach | 박지훈 (coach_a) | coach_owner | owner |
| member-approved | 김도윤 (member_a1) | member | approved |
| member-pending | 최서윤 (member_a3) | member | pending |
| app_user | 송예준 (app_user_01) | app_user | — |

Sign in 완료 → 백엔드 `/api/v1/profile/info` 로 기존 프로필 확인 → `gradeResult` 없음 → Onboarding Basic / 있음 → Main(5탭).

### 4-4. Onboarding — 3 스텝

**Step 1: Basic (필수)**

| 항목 | 유형 | 비고 |
|---|---|---|
| 체중 | 숫자 (kg / lb 토글) | 필수 |
| 키 | 숫자 (cm) | 필수 |
| 나이 | 숫자 | 필수 |
| 성별 | 선택 버튼 | 필수 |

헤드라인: `Enter 1RM.` / 캡션: "체중·키는 등급 산정 기준."
`Next` → Step 2

**Step 2: Benchmarks (옵셔널)**

| 카테고리 | 예시 항목 |
|---|---|
| Power | Back Squat 1RM / Deadlift 1RM |
| Olympic | Clean & Jerk 1RM / Snatch 1RM |
| Gymnastics | Pull-up Max UB / T2B Max UB |
| Cardio | Run 500m pace / Row 500m pace |
| Metcon | Fran time / Cindy rounds |

헤드라인: `Benchmarks.` / 캡션: "아는 것만 입력. 빈 칸은 자동 추론."
`Next` → Step 3 / `Skip` → Step 3 (빈 칸 그대로)

**Step 3: Engine 측정**

- POST `/api/v1/grade/calculate` 호출
- 로딩 오버레이: `Calculating.` + 캡션 "6 카테고리 Engine 측정." + Quote 1개
- 1.8초 후 응답 → GradeResult 파싱

### 4-5. Tier 부여 — "30초 가치 도달" 시점

GradeResult.overall_number (1~6) → 5 Tier 매핑:

| overall_number | Tier | 색상 토큰 |
|---|---|---|
| 1~2 | Scaled | `tierScaled #4A4A4A` |
| 3 | RX | `tierRx #EE2B2B` |
| 4 | RX+ | `tierRxPlus #929292` |
| 5 | Elite | `tierElite #C8C8C8` |
| 6 | Games | `tierGames #F5F5F5` |

결과 화면 헤드라인: `Your Tier.` / 캡션: "Tier 에 맞춰 Split 과 Burst 자동 조정. Profile 수정 가능."
AchievementState.check() 호출 → 신규 unlock 있으면 UnlockToast.showAll (Haptic heavy).
CTA: `Start WOD` → Main (5탭 Shell) 진입.

---

## 5. Main — 5 탭 구조

### 5-1. Calc 탭

**목적**: WOD 를 직접 입력하고 즉시 페이싱 전략을 받는다. 박스 미가입 사용자도 전면 사용 가능.

**흐름**:
1. WodBuilder — 동작 카테고리(Gymnastics / Barbell / Cardio / Bodyweight) → 동작 선택 → 횟수·중량·거리 입력
2. WodType 선택 — For Time / AMRAP / EMOM
3. POST `/api/v1/pacing/calculate` (profile_overrides 동봉)
4. ResultScreen — Split 패턴 + Burst 시점 + 예상 완주 시간 + 근거
5. 공유(share_plus) · 기록 저장(WodHistoryItem)

**페르소나 분기**: 없음. 전 페르소나 동일 경험.

### 5-2. WOD 탭

**목적**: 박스 코치가 등록한 오늘의 WOD 를 받고 세션을 기록한다.

**흐름 (approved 멤버)**:
1. BoxWodScreen — 오늘의 WOD 목록 (RX / Scaled / Beginner 3 버전)
2. WodDetail — Scale Guide · 코치 의도 · 댓글
3. WodSessionScreen (타이머) → 완료 기록 입력
4. PR 비교(PrDetector) · Season Badge unlock 체크 · 리더보드 반영

**페르소나 분기**:

| 역할 / 상태 | WOD 탭 접근 | 리더보드 | WOD 등록 |
|---|---|---|---|
| app_user (no-gym) | 박스 검색·가입 CTA만 | — | — |
| pending | 승인 대기 안내 표시 | — | — |
| rejected | 재신청 또는 다른 박스 CTA | — | — |
| approved | 전체 접근 | opt-in | — |
| coach_owner | 전체 접근 | 보기 전용 | 전체 권한 |
| admin | 전체 접근 | 보기 전용 | 전체 권한 |

### 5-3. Trends 탭

**목적**: Engine 추이 시각화 + 업적 갤러리 + Panel B 칭호 관리.

**섹션 구성**:

| 섹션 | 내용 | 주요 컴포넌트 |
|---|---|---|
| LEVEL 카드 | 현재 Lv(1~50) + XP 바 + 다음 Lv 까지 | LevelSystem |
| Engine Trend | 날짜별 overall_score 라인 차트 | EngineSnapshotRecord |
| Engine Decay | 마지막 세션 후 경과일 → decay 상태 표시 | EngineDecay |
| Achievement 갤러리 | FIFA-style 3×3 업적 그리드 | AchievementsScreen |
| Panel B | 20 종 칭호 (Common/Rare/Epic/Legendary) 진입점 | TitlesCatalog |

**칭호 unlock 임계 예시**:
- `IRON LUNG` — Engine 80+ 5회 연속 달성
- `UNBROKEN` — 같은 WOD 에서 전 동작 Unbroken 기록
- 임계는 결정론적. 랜덤 없음.

**페르소나 분기**: 전 페르소나 동일. 잠긴 칭호는 조건 표시.

### 5-4. Attend 탭

**목적**: 출석 캘린더 + Streak 관리 + Streak Freeze + 챌린지.

**섹션 구성**:

| 섹션 | 내용 |
|---|---|
| 월별 캘린더 | WOD 세션 완료일 도트 표시 |
| Streak 카운터 | 연속 출석 일수 |
| Streak Freeze | 주 1회 무료 Freeze 토큰. 사용자 자율 선택. 회복 결제 없음. |
| 챌린지 | 박스 단위 챌린지 (opt-in). 개인 챌린지 추후 추가. |

**Streak Freeze 규칙**:
- 1주 = 1 Freeze 토큰 자동 지급
- 사용: 오늘 세션 완료 없이 자정 넘어갈 때 수동 사용
- 결과: Streak 유지. 토큰 1 소모.
- 미사용 토큰 누적 불가 (1주 = 1 한도)

**페르소나 분기**: 전 페르소나 동일. Streak 은 device_id 귀속.

### 5-5. Profile 탭

**목적**: Tier 스냅샷 · 기록 · 인박스 · 박스 정보를 한 화면에서 관리.

**섹션 구성**:

| 섹션 | 내용 | 게이트 |
|---|---|---|
| TierSnapshot | 현재 Tier + 6 카테고리 레이더 | 전 페르소나 |
| WornTitle | 현재 착용 칭호 (1개) | 칭호 unlock 후 |
| InboxEntry | 코치 인박스 진입점 (미읽음 배지) | `isOwner \|\| isApproved` |
| TierRoadmap | 다음 Tier 까지 필요 지표 | 전 페르소나 |
| EngineTrend (미니) | 최근 5회 스냅샷 | 전 페르소나 |
| RoleModel | 같은 Tier 대표 athlete 인용 | 전 페르소나 |
| CategoryTiers | 6 카테고리 개별 Tier | 전 페르소나 |
| Achievements | 업적 요약 진입점 | 전 페르소나 |

**MyPage 설정** (Profile 내 진입):
- 단위 전환 (kg / lb)
- textScale 조정
- Reset data
- Sign Out

---

## 6. Metrics — 성공 지표

### 6-1. 첫 가치 도달 지표

| 지표 | 정의 | 목표 |
|---|---|---|
| Time to Tier | Splash 실행 → GradeResult 수신 경과 시간 | 30초 이하 |
| Onboarding Completion Rate | Step 1 진입 대비 Tier 화면 도달 비율 | 80% 이상 |
| Step 2 Skip Rate | Benchmarks 스킵 비율 | 모니터링만 (패널티 없음) |

### 6-2. Step별 이탈 퍼널

```
Splash 실행
  └─ Intro 진입           (목표 이탈 < 5%)
      └─ Sign in 완료     (목표 이탈 < 20%)
          └─ Step 1 완료  (목표 이탈 < 10%)
              └─ Engine 측정 완료  (목표 이탈 < 5%)
                  └─ Tier 부여 = 30초 가치 도달
```

### 6-3. Retention 지표

| 지표 | 정의 | 목표 |
|---|---|---|
| Day 1 Retention | 설치 당일 재사용 비율 | 60% 이상 |
| Day 7 Retention | 설치 후 7일 이내 재사용 비율 | 30% 이상 |
| Day 30 Retention | 설치 후 30일 이내 재사용 비율 | 15% 이상 |

### 6-4. 5 탭 사용률

| 탭 | 예상 주요 사용 빈도 |
|---|---|
| Calc | 세션 당일 1~2회 (WOD 전) |
| WOD | 박스 승인 멤버: 세션 당일 1회 |
| Trends | 주 1~2회 (기록 확인·칭호 점검) |
| Attend | 주 2~3회 (Streak 확인·Freeze 사용) |
| Profile | 월 1~2회 (Tier 업데이트·인박스 확인) |

탭 사용률 양극화(Calc 쏠림) 발생 시 나머지 탭 진입점을 Calc 결과 화면에 연결한다.

---

## 7. Risks / Trade-offs

### R1. 옵셔널 입력 = 추론 데이터 의존

1RM 빈 칸이 많을수록 Engine 점수 정확도가 낮아진다. 추론 알고리즘의 오차가 Tier 배정 오류로 이어질 경우 사용자 신뢰를 잃는다.

**완화**: 결과 화면에 "1RM 입력 시 정확도 향상" CTA 노출. 강제 아님. 추론값 기반 결과임을 micro 토큰으로 명시("추론값 기반").

### R2. 30초 제약과 데이터 품질 충돌

더 많은 입력 = 더 정확한 Tier. 그러나 입력 단계 추가 = 30초 초과. 이 둘은 영구적으로 긴장한다.

**현재 결정**: 필수 4 항목(체중·키·나이·성별) 만으로 Tier 부여 가능. 보완 입력은 온보딩 이후 Profile 에서 수시로 추가 가능.

### R3. Sign in 이전 데이터 유실 위험

Sign in 전 device_id 기반 데이터는 앱 재설치·기기 변경 시 유실된다.

**MVP 결정**: 유실 허용 (익명 구조의 트레이드오프). v2 에서 Sign in 후 server-side 백업 연결.

### R4. pending / rejected 사용자 이탈

박스 가입 신청 후 코치 승인 대기 중 이탈 가능성이 있다.

**완화**: pending 상태에서도 Calc 탭 전면 사용 가능. "승인 대기 중" 상태 메시지는 WOD 탭에만 표시. Attend · Trends · Profile 은 제한 없음.

### R5. 데모 계정 보안

debug 모드에서만 데모 계정 노출이어야 한다. release 빌드에 PersonaSwitcher 노출 시 role escalation 위험.

**완화**: `kDebugMode` 플래그 조건부 렌더. CI 에서 release 빌드 smoke test 의무.

---

## 8. Roadmap — 단계별 User Journey 강화

| 단계 | 주요 항목 |
|---|---|
| 현재 (Phase 3) | `intro_seen` 플래그 · Skip · 5 데모 계정 · device_id 익명 세션 · Engine→Tier→UnlockToast |
| Phase 4 (백엔드 無) | 온보딩 완료율 로컬 로깅 · "추론값 기반" micro 라벨 · pending 가이드 카드 |
| Phase 5 (백엔드 有) | FCM Push (WOD·노트·PR) · `/api/v1/season/current` 실서버 · device_id→user_id 마이그레이션 |
| Phase 6 (v2+) | 친구 초대(referral) · 클라우드 백업 · iOS 빌드 + TestFlight |

---

## 9. FAQ

| 질문 | 답 |
|---|---|
| 왜 이메일 가입이 없나? | 이메일 UI = 추가 마찰. 30초 제약 위협. 데모 계정은 debug 한정, production 흐름에 미노출. |
| Intro 를 왜 3 페이지로 고정했나? | Split defines rank. → 6 metrics. → Start. = "왜 이 앱인가"의 최소 구조. 2페이지: Engine 개념 불완전. 4페이지+: Skip 율 급등. |
| Step 2 Benchmarks 를 필수로 만들면 안 되나? | T3 원칙(옵셔널 입력) 위반. 1RM 을 모른다고 Tier 배정을 막는 것은 진입 장벽. 추론 알고리즘이 이 사용자를 위해 존재한다. |
| pending 상태 사용자는 어떻게 잡나? | Calc 탭은 박스 가입 여부 무관 전면 개방. "대기 중에도 WOD 페이싱 계산 가능"을 pending 화면에서 명시. |
| rejected 사용자는 영구 차단인가? | 아니다. rejected = 해당 박스 거절. 다른 박스 재신청 또는 app_user 로 Calc 전용 사용 가능. |
| 10 페르소나 분기를 어떻게 유지하나? | 백엔드 `role` + `gym_status` 두 필드만으로 분기. 새 페르소나도 이 두 필드 내에서 처리. `persona_matrix_test.dart` (31 tests) 회귀 보장. |
| 30초 제약을 어떻게 측정하나? | MVP: 로컬 타임스탬프 (Splash → GradeResult). Phase 4: 서버사이드 이벤트 로그 실측. 초과 시 Step 1 UX 또는 API 응답 시간 우선 조사. |
| Engine 측정 실패 시 흐름은? | "Calc failed. Retry." 토스트 + Retry. 3회 실패 → 로컬 추론 Tier 임시 배정 + "연결 시 업데이트" 안내. 오프라인 Tier 는 서버 미저장. |
| Streak Freeze 를 왜 무료로 주나? | 유료 복구(Duolingo 모델) = 화이트햇 위반. Freeze = Rest Pass. "쉬는 것도 훈련이다"가 이 사용자층에게 정확한 언어다. |
| 5 탭 구조는 확정인가? | Phase 3 기준 고정. 탭 추가 = Shell 네비게이션 구조 변경 → Major 결정. 신규 기능은 기존 탭 내 섹션 추가로 수용. |

---

## Appendix — 페르소나 × 탭 접근 매트릭스

| 역할 / 상태 | Calc | WOD | Trends | Attend | Profile | Inbox |
|---|---|---|---|---|---|---|
| admin | 전체 | 전체 + 등록 | 전체 | 전체 | 전체 | 전체 |
| coach_owner | 전체 | 전체 + 등록 | 전체 | 전체 | 전체 | 4탭 |
| approved | 전체 | 전체 | 전체 | 전체 | 전체 | 3탭 |
| pending | 전체 | 대기 안내 | 전체 | 전체 | 전체 | 차단 |
| rejected | 전체 | 재신청 CTA | 전체 | 전체 | 전체 | 차단 |
| app_user | 전체 | 가입 CTA | 전체 | 전체 | 전체 | 차단 |

Inbox 3탭 = ALL / NOTES / ASSIGNMENTS. 4탭 = +OUTBOX (coach only).

---

*본 문서는 ABOUT.md §7 의 6-pager 확장판이다. ABOUT.md §7 은 이 문서의 요약 포인터로만 유지한다.*
