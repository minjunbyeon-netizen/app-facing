# §3 WOD Broadcasting — 6-Pager

> 작성일: 2026-04-28
> 대상: VC · PM · Engineering · Coach Owner (박스 운영자)
> 프로젝트: FACING — CrossFit Games-Player 급 전용 WOD Pacing + 박스 통합 앱

---

## 1. TL;DR

Coach Owner 가 WOD 를 FACING 에 한 번 게시하면, 해당 박스의 승인된 멤버(Approved Member) 전원이 즉시 수신한다. 멤버는 박스 도착 전에 RX / Scaled / Beginner 3 버전 중 본인 버전을 확인하고, 한 탭으로 페이싱 전략을 계산한 뒤, WOD 완료 후 결과를 입력하면 박스 리더보드에 자동 반영된다. 카카오톡 단톡방이 전달하지 못하는 권한 제어 · 버전 분기 · 페이싱 연동 · 리더보드를 단일 앱이 담는다.

---

## 2. Problem — 기존 박스 의사소통의 한계

국내 박스의 WOD 공지는 대부분 카카오톡 단톡방 또는 박스 게시판(화이트보드·SNS)에 의존한다. 이 방식은 엘리트 athlete 운영에 5 가지 구조적 한계를 가진다.

### 2-1. 검색 불가

어제 Fran 기록을 찾으려면 단톡방을 위로 스크롤한다. 대회 전 3개월 WOD 패턴을 확인하는 것은 불가능에 가깝다. 기록 관리와 WOD 공지가 같은 채널에 섞인다.

### 2-2. 버전 분기 불가

RX / Scaled / Beginner 각각의 중량·동작 변형이 단일 메시지에 텍스트로 나열된다. 멤버는 본인 버전을 직접 파싱해야 하며 코치는 오해를 최소화하기 위해 여러 번 메시지를 보낸다. Scale Guide(변형 동작 안내)는 별도 SNS 게시물로 분리된다.

### 2-3. 페이싱 연동 없음

WOD 정보를 받아도 "어떻게 쪼갤 것인가"는 개인 경험에 의존한다. 백엔드가 산출하는 Split · Burst · 예상 완주 시간을 WOD 공지와 연결하는 채널이 없다.

### 2-4. 권한 제어 없음

단톡방에 코치, 현 멤버, 전 멤버, 게스트, 방문 athlete 가 섞인다. WOD 수신 자격(Approved Member) 과 전송 자격(Coach Owner) 이 구분되지 않는다.

### 2-5. 리더보드 없음

WOD 완료 후 결과 입력을 별도로 수집하지 않으면 박스 내 비교가 불가능하다. 코치가 수동으로 취합하거나 포기한다. 엘리트 athlete 의 경쟁 동기(competitive edge)가 활성화되지 않는다.

---

## 3. Tenets — WOD 공지의 원칙

### T1. 1회 입력 → 전체 공유

Coach Owner 가 한 번 등록하면 해당 박스의 모든 Approved Member 가 즉시 수신한다. 재전송 · 복붙 · 스크린샷 없음.

### T2. 3 버전 분기는 코치의 의무, 멤버의 선택

RX / Scaled / Beginner 각 버전을 코치가 구조화된 폼으로 입력한다. 멤버는 본인 버전만 본다. Scale Guide(변형 동작) 는 버전에 종속된다.

### T3. WOD 수신 즉시 페이싱 계산 가능

멤버가 WOD 상세를 연 직후, 탭 하나로 페이싱 전략(Split · Burst · 예상 시간) 을 산출한다. WOD 공지와 계산이 동일 맥락에서 이루어진다.

### T4. 권한은 박스 단위로 격리

Coach Owner 만 WOD 를 게시한다. Approved Member 만 수신한다. Pending · Rejected 상태는 차단된다. 박스 간 WOD 데이터는 공유되지 않는다.

### T5. 결과 입력 → 리더보드 자동 반영

WOD 세션 완료 시 총시간 · 라운드 · 방식(RX/Scaled/Beginner)을 입력하면 박스 리더보드에 자동 집계된다. 코치의 수동 취합 없음.

### T6. 과거 WOD 재사용

Coach Owner 는 이전 WOD 를 복제하고 수정하여 새 날짜에 게시할 수 있다. 비슷한 WOD 패턴을 반복 사용하는 박스 운영 현실을 반영한다.

### T7. 리더보드는 opt-in

박스 내 비교는 경쟁 동기 강화를 위한 수단이지 강제 노출이 아니다. 멤버는 본인 결과를 공개하지 않을 수 있다. 강제 리더보드는 블랙햇 패턴으로 분류하여 차단한다.

---

## 4. Approach — 코치 publish ↔ 멤버 receive 전체 흐름

### 4-1. 역할 정의

| 역할 | 식별 조건 | WOD Broadcasting 권한 |
|---|---|---|
| Coach Owner | `role == coach_owner` AND `box.owner_id == device_id` | 게시 · 복제 · 삭제 · 리더보드 관리 |
| Approved Member | `gym_status == approved` AND 동일 박스 | 수신 · 결과 입력 · 리더보드 조회 |
| Pending Member | `gym_status == pending` | 차단 — WOD 탭 잠금 |
| Rejected Member | `gym_status == rejected` | 차단 — 재가입 안내만 표시 |
| App User (no-gym) | 박스 미가입 | 차단 — 박스 가입 funnel 노출 |

### 4-2. Coach Owner — WOD 게시 흐름

```
Coach Owner

1. WOD 탭 진입 → "+" 버튼
2. 기본 정보 입력
   - WOD 이름 (예: Fran · Monday Metcon · Week 3 Day 2)
   - 날짜 · 시간대 (클래스별 분리 가능)
   - WOD 타입: For Time / AMRAP / EMOM / Chipper
3. 버전별 구성 입력 (최소 RX 1개 필수)
   - RX: 동작 · 횟수 · 중량 · 라운드
   - Scaled: 동작 변형 · 중량 변형 (예: Thruster → Goblet Squat, 43kg → 29kg)
   - Beginner: 경량화 + 동작 단순화
4. Scale Guide 입력 (옵션)
   - 변형 동작 설명 · 수행 기준 · 코치 의도
5. 라운드별 세부 (round-by-round) 입력 (옵션)
   - 21-15-9 같은 분산 구조를 라운드 단위로 명시
6. Publish → 박스 Approved Member 전체 즉시 전달
```

### 4-3. 어제 WOD 복제 + 수정

- WOD 목록에서 이전 WOD 를 선택 → "Duplicate" → 날짜만 변경하거나 동작 1~2개 수정 후 게시.
- 코치의 WOD 설계 시간을 단축한다. 주 5회 WOD 를 반복 운영하는 박스에 직접적 효용.

### 4-4. Approved Member — WOD 수신 흐름

```
Approved Member

1. WOD 탭 진입 → 오늘 날짜 WOD 자동 표시
2. 본인 버전 선택 (RX / Scaled / Beginner)
3. 상세 확인
   - 동작 목록 · 횟수 · 중량
   - Scale Guide (버전에 종속)
   - 라운드별 세부
   - 코치 의도 (Coach Note, 선택 노출)
4. "Pacing" 탭 → 페이싱 전략 즉시 산출
   - 현재 프로필(1RM · UB · 카디오 페이스) + WOD 구성 자동 매핑
   - Split 패턴 · Burst 시점 · 예상 완주 시간
5. 박스 도착 → WOD 세션 시작 (Session Timer)
6. 완료 → 결과 입력
   - 총시간 (For Time) 또는 완료 라운드 (AMRAP · EMOM)
   - 수행 버전 (RX / Scaled / Beginner)
   - 라운드별 세부 입력 (선택)
7. 리더보드 반영 (opt-in 멤버만 공개)
```

### 4-5. 댓글 · 코치 피드백

- WOD 상세 하단에 댓글 입력 가능 (Approved Member).
- Coach Owner 는 댓글에 피드백 태그를 달 수 있다.
- 실시간 지도 채널로 활용: "Pull-up 는 kipping 허용" · "Thruster 바 높이 확인할 것".
- 댓글은 해당 WOD 컨텍스트에 귀속된다. 단톡방처럼 다른 대화에 묻히지 않는다.

### 4-6. 박스 리더보드

- WOD 완료 + 결과 입력 → `/api/v1/gyms/{box_id}/wods/{wod_id}/results` POST.
- 리더보드 표시: 수행 버전별 분리 (RX · Scaled · Beginner 각 탭).
- 정렬 기준: For Time → 빠른 순 / AMRAP · EMOM → 많은 라운드 순.
- PR 감지: 같은 WOD 명칭의 이전 기록 대비 시간 단축 → 자동 PR 알림 + Haptic.
- 비공개 옵션: opt-out 멤버는 본인 결과를 리더보드에서 숨긴다 (기록 자체는 개인 History 에 유지).

---

## 5. Metrics — 측정 지표

### 5-1. 코치 활성도 (Supply)

| 지표 | 정의 | 목표 (MVP 3개월) |
|---|---|---|
| 박스당 주간 WOD 게시 수 | WOD publish count / box / week | 3.5+ (주 5일 기준 70%) |
| 복제 활용률 | duplicated WODs / total WODs | 30%+ |
| 버전 완성도 | RX + Scaled 동시 게시 비율 | 80%+ |
| Scale Guide 작성률 | WODs with guide / total WODs | 50%+ |

### 5-2. 멤버 수신율 (Demand)

| 지표 | 정의 | 목표 (MVP 3개월) |
|---|---|---|
| WOD 확인율 | WOD 상세 조회 멤버 / 박스 Approved 멤버 | 60%+ |
| 페이싱 연동율 | Pacing 탭 진입 / WOD 상세 조회 | 40%+ |
| 사전 확인률 | 박스 클래스 시작 전 WOD 조회 비율 | 50%+ |

### 5-3. 결과 & 리더보드 (Retention)

| 지표 | 정의 | 목표 (MVP 3개월) |
|---|---|---|
| WOD 결과 입력률 | 결과 입력 완료 / WOD 세션 시작 | 55%+ |
| 리더보드 opt-in율 | 공개 선택 멤버 / 전체 결과 입력 멤버 | 65%+ |
| PR 발생률 | 같은 WOD 2회 이상 기록 중 PR 비율 | 측정 기준 확립 후 추적 |

### 5-4. 박스 수준 retention

| 지표 | 정의 |
|---|---|
| 박스 DAU / MAU 비율 | 일간 WOD 탭 진입 멤버 / 월간 활성 멤버 |
| 코치 이탈률 | coach_owner 가 2주 이상 WOD 미게시 박스 비율 |
| 멤버 churm | Approved 상태에서 90일 이상 미접속 비율 |

---

## 6. Risks / Trade-offs

### 6-1. 박스 단위 의존성

WOD Broadcasting 기능 전체가 박스 가입 구조에 의존한다. 박스 미가입 사용자(App User) 는 WOD 탭을 사용할 수 없다.

완화 전략:
- App User 에게 WOD 탭 진입 시 박스 가입 funnel 을 노출한다 (검색 → 가입 신청).
- 박스 없이 WOD Calc(직접 입력 페이싱) 는 전 페르소나 사용 가능. WOD Broadcasting 없이도 핵심 가치 체험 가능.
- 개인 WOD 생성(코치 없이 본인이 WOD 를 직접 등록) 기능을 Phase 2 에서 검토.

### 6-2. Coach Owner 활성화 병목

WOD 공급이 Coach Owner 의 게시 행동에 종속된다. 코치가 FACING 을 사용하지 않으면 멤버도 WOD Broadcasting 을 경험하지 못한다.

완화 전략:
- 코치 온보딩 전용 시나리오 설계: 박스 생성 직후 첫 WOD 게시까지 3단계 가이드.
- 복제 기능으로 반복 게시 마찰 최소화.
- 코치 대시보드에 박스 내 멤버 확인률 표시 → 게시 행동에 즉각적인 정량적 피드백.
- MVP 는 직접 영업(D2C 코치 어빌리티) 집중. 박스 계약 시 코치 교육 포함.

### 6-3. 버전 분기 복잡도

RX / Scaled / Beginner 3버전 + Scale Guide 를 모두 입력하면 코치의 초기 작성 부담이 증가한다.

완화 전략:
- RX 만 필수, 나머지는 선택. 미작성 버전은 "버전 미제공" 표시 후 코치에게 알림.
- 동작별 기본 Scale Guide 템플릿 제공 (예: Pull-up → Ring Row 기본 설명 자동 채움).
- 복제 + 수정 패턴으로 반복 박스는 첫 주 이후 작성 시간 단축.

### 6-4. 리더보드 경쟁 과열

엘리트 박스에서 리더보드가 부정적 비교 압력으로 작용할 수 있다.

완화 전략:
- 기본값 비공개 (opt-in). 공개는 멤버 자발적 선택.
- 리더보드는 박스 단위 격리. 전체 앱 랭킹 없음.
- 수행 버전별(RX · Scaled · Beginner) 분리 표시 — 비교 맥락을 동일 버전 내로 한정.

### 6-5. Pending / Rejected 멤버 경험

가입 신청 후 승인 대기 중인 멤버는 WOD 를 볼 수 없다. 이탈 유인이 될 수 있다.

완화 전략:
- Pending 상태에서 WOD 탭 진입 시 "승인 대기 중 — 코치 승인 후 WOD 수신 시작" 명확 안내.
- 대기 중에도 WOD Calc(직접 입력 페이싱) 와 Engine 측정은 전부 사용 가능. 가치를 먼저 체험.
- 코치에게 Pending 멤버 승인 알림 (In-app · 향후 FCM).

---

## 7. Roadmap

### Phase 1 — 현재 (완료)

| 기능 | 상태 |
|---|---|
| WOD 게시 (Coach Owner) | 완료 |
| RX / Scaled / Beginner 3 버전 구조 | 완료 |
| WOD 상세 멤버 수신 | 완료 |
| WOD 세션 타이머 | 완료 |
| 결과 입력 + 리더보드 POST | 완료 |
| PR 감지 + 알림 | 완료 |
| 어제 WOD 복제 + 수정 | 완료 |
| 라운드별 세부 (round-by-round) 입력 | 완료 |
| 댓글 구조 (기반) | 완료 |
| Pending / Rejected 권한 차단 | 완료 |

### Phase 2 — 다음 (백엔드 의존)

| 기능 | 우선순위 | 비고 |
|---|---|---|
| Scale Guide 템플릿 라이브러리 | HIGH | 코치 작성 부담 감소 |
| 코치 피드백 태그 (댓글 레이어) | HIGH | 실시간 지도 완성 |
| 영상 첨부 (Scale Guide 데모 클립) | MEDIUM | 스토리지 비용 고려 |
| 개인 WOD 생성 (no-gym 사용자) | MEDIUM | App User 가치 확대 |
| WOD 예약 게시 (시간 지정 publish) | MEDIUM | 코치 새벽 예약 설정 |
| 멤버 버전 변경 후 재계산 | MEDIUM | 세션 중 버전 수정 |
| 코치 대시보드 — 확인률 표시 | HIGH | 게시 행동 피드백 루프 |

### Phase 3 — 자동화 (중장기)

| 기능 | 방향 |
|---|---|
| WOD → 페이싱 자동 연동 (탭 없이) | WOD 상세에서 바로 Split 미리보기 |
| 자동 페이싱 추천 (코치용) | 박스 평균 Tier 기준 권장 Split 제안 |
| 히스토리 기반 볼륨 경고 | 주간 누적 부하 초과 시 코치에게 알림 |
| WOD 패턴 분석 | 박스 WOD 주기·편중 분석 리포트 |
| Whoop / Garmin 데이터 연동 | 회복 상태 반영 페이싱 보정 |
| FCM Push — WOD 게시 알림 | 코치 게시 즉시 멤버 푸시 수신 |

---

## 8. FAQ

**Q1. 코치가 박스를 만들지 않으면 멤버는 WOD Broadcasting 을 쓸 수 없나?**

그렇다. WOD Broadcasting 은 박스 단위 구조 위에서만 동작한다. 박스 미가입 사용자는 WOD Calc(직접 입력 페이싱) 와 Engine 측정으로 핵심 가치를 먼저 체험하고, 박스 가입 funnel 을 통해 진입한다. 코치 없이 혼자 WOD 를 등록하는 개인 WOD 기능은 Phase 2 백로그에 있다.

**Q2. Scaled 버전을 코치가 입력하지 않으면 어떻게 표시되나?**

WOD 상세에서 해당 버전을 선택하면 "버전 미제공" 안내가 표시된다. 멤버는 RX 구성을 참고하거나 코치에게 댓글로 문의한다. 버전 완성도는 코치 대시보드 지표(Phase 2)에 노출되어 작성을 유도한다.

**Q3. 멤버가 세션을 완료하지 않고 앱을 종료하면 결과는 어떻게 되나?**

Session Timer 중간 종료 시 WOD History 에 "미완료" 상태로 저장된다. 리더보드에는 반영되지 않는다. 이후 앱 재진입 시 해당 세션을 이어서 기록하거나 결과를 수동 입력할 수 있다.

**Q4. 박스 리더보드에서 본인 순위를 숨기면 본인 기록도 사라지나?**

아니다. 리더보드 비공개(opt-out)는 타인에게 보이지 않는 것이지, 본인의 개인 History 에서 삭제되지 않는다. 개인 WOD 기록 · PR 추적 · Engine 추이는 opt-out 상태에서도 정상 동작한다.

**Q5. 댓글은 해당 WOD 에만 귀속되나? 코치-멤버 간 다른 채널이 있나?**

댓글은 특정 WOD 에 귀속된다. WOD 와 무관한 코치-멤버 직접 통신은 §4 인박스(Note / Assignment) 를 사용한다. WOD 댓글과 인박스는 분리된 채널이다.

**Q6. 여러 클래스 시간대 (7AM · 10AM · 6PM) 를 분리해서 WOD 를 게시할 수 있나?**

현재(Phase 1) WOD 는 날짜 단위 게시다. 같은 날짜에 클래스 시간대별 WOD 를 분리하려면 복제 기능을 활용하여 이름만 다르게 게시한다 (예: Monday 7AM · Monday 6PM). 시간대별 WOD 세분화는 Phase 2 에서 검토한다.

**Q7. 동일한 WOD (Fran · Grace 등 벤치마크 WOD) 가 여러 날짜에 등장하면 PR 추적이 되나?**

된다. PR Detector 는 WOD 명칭 기준으로 이전 기록과 비교한다. "Fran" 을 3개월 뒤 다시 게시하고 멤버가 완료하면 이전 최고 기록 대비 시간 단축 여부를 자동 감지하고 PR 알림을 표시한다.

**Q8. 코치가 게시한 WOD 를 수정·삭제할 수 있나?**

Coach Owner 는 본인이 게시한 WOD 를 수정하거나 삭제할 수 있다. 단, 이미 결과가 입력된 WOD 를 삭제하면 해당 결과도 함께 삭제된다는 경고를 표시한다. 멤버 기록 보호를 위해 결과가 있는 WOD 는 아카이브(비공개) 처리를 권장한다.

**Q9. For Time WOD 에서 시간 초과(time cap) 를 설정할 수 있나?**

Phase 1 에서는 time cap 을 코치가 WOD 이름이나 Scale Guide 에 텍스트로 기록하는 방식이다. Session Timer 의 time cap 알림 · 자동 중단 기능은 Phase 2 에서 구현한다.

**Q10. 앱 없이 (오프라인 상태) WOD 를 확인할 수 있나?**

최근 조회한 WOD 는 로컬 캐시에 유지된다. 오프라인 상태에서도 마지막 조회 WOD 를 확인할 수 있다. 결과 입력과 리더보드 동기화는 네트워크 복구 후 자동으로 수행된다. 오프라인 상태에서는 상단에 "OFFLINE · Sync on reconnect" 배너가 표시된다.

---

## 관련 문서

| 문서 | 경로 |
|---|---|
| 프로젝트 개요 | `docs/ABOUT.md §3` |
| 기능 매트릭스 (B그룹 WOD 세션) | `docs/PROJECT_CHARTER.md §5` |
| WOD 세션 데이터 흐름 | `docs/PROJECT_CHARTER.md §9-4` |
| 박스 멤버십 권한 표 | `CLAUDE.md §8` |
| 게이미피케이션 (PR / 리더보드) | `docs/PROJECT_CHARTER.md §7` |
