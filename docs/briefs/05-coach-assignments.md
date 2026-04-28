# §5 Coach Assignments — 6-Pager

> **분류**: Product Brief · Internal  
> **버전**: v1.0  
> **작성일**: 2026-04-28  
> **작성자**: facing-app Product  
> **대상 독자**: VC · PM · Eng · 박스 코치

---

## 1. TL;DR

코치가 멤버에게 구조화된 운동 과제(Assignment)를 처방하고, 멤버는 수락·수행·결과 입력까지 앱 안에서 처리한다. 코치는 수행 결과를 보고 피드백을 남긴다. 카카오톡 메시지나 수기 노트로는 불가능했던 처방-수행-피드백 closed-loop를 FACING이 최초로 구현한다.

핵심 수치 목표: 처방 발송 후 48시간 내 수락률 85% 이상 / 수락 후 완료율 70% 이상 / 코치 피드백률 60% 이상.

---

## 2. Problem — 박스 코치의 처방 추적 한계

### 2-1. 현재 상태

CrossFit 박스 코치는 평균 15~40명의 멤버를 지도한다. 개인 맞춤 처방은 코칭의 핵심이지만, 현재 처방 도구는 다음 3가지 중 하나다.

| 도구 | 문제점 |
|---|---|
| 카카오톡 단체방 | 수행 여부 추적 불가. 처방 내용이 대화 속에 묻힘. |
| 수기 노트 · 화이트보드 | 사진 찍어 보내면 끝. 실제 수행 결과 회수 불가. |
| TrueCoach · TrainHeroic | 영어 전용 UI. 한국 박스 멤버십 미통합. 처방 단독 SaaS — 페이싱·리더보드 분리. |

### 2-2. 코치가 직면하는 실제 문제

- Back Squat 5×5를 처방했는데 김도윤이 했는지 안 했는지 다음 수업 전까지 모른다.
- Substitute(대체 동작)를 알려줬는데 멤버가 기억 못 해 부상 동작을 그냥 한다.
- RPE 기반 하중 처방을 했는데 멤버가 실제로 어떤 무게로 했는지 코치는 추론만 한다.
- 5주 누적 처방 플랜을 세웠는데 멤버 이탈률이 3주차에 급등한다. 이유를 모른다.
- Open 직전 처방 집중 기간에 "어깨 아파요" 거절이 증가하는데 어느 동작이 문제인지 파악 안 된다.

### 2-3. 멤버가 직면하는 문제

- 처방을 받았는데 언제까지 해야 하는지 기억이 불분명하다.
- 부상 시 대체 동작을 스스로 판단해야 한다.
- 코치가 왜 이 처방을 줬는지 의도를 모른 채 수행한다.
- 완료 후 코치에게 결과를 전달할 채널이 없다.

---

## 3. Tenets — 숙제의 원칙

FACING Coach Assignments 기능은 다음 4원칙을 모든 설계 결정의 기준으로 삼는다.

**T1. Schema 구조화 의무.**  
처방은 반드시 6 필드(동작 / 세트×횟수 / 하중 단위 / 마감일 / 대체 동작 / Rationale)를 포함해야 발송된다. 필드 누락 시 시스템이 저장을 거부한다. "나중에 채우겠다" 없음.

**T2. Rationale 의무.**  
코치는 "왜 이걸 하는가"를 텍스트로 남겨야 한다. 빈 Rationale로는 처방 저장 불가. 멤버가 의도를 이해한 채 수행하면 완료율이 높아진다는 CompTrain 원칙을 따른다.

**T3. Substitute 의무.**  
모든 처방에 부상·컨디션 대비 Substitute(대체 동작)가 명시되어야 한다. 처방 Schema에서 Substitute 없는 처방은 draft 상태로만 저장된다.

**T4. 거절 사유 명시.**  
멤버가 처방을 거절할 때 사유(부상 / 일정 / 강도 / 기타) 중 하나를 반드시 선택해야 한다. 코치는 이 데이터로 처방 재설계를 결정한다.

---

## 4. Approach — 처방 Loop 설계

### 4-1. 전체 흐름

```
[Coach] 처방 작성
    └─ Schema 6 필드 입력 → Validate → POST /api/v1/inbox/assignments
         └─ Push 알림 → [Member] 인박스 ASSIGNMENTS 탭 도착
              └─ 수락(Accept) → 수행 → 결과 입력
              │       └─ Coach 피드백
              └─ 거절(Decline) → 사유 선택 → Coach 확인 → 재처방 or 종료
```

### 4-2. Coach 처방 작성 화면 (ComposeAssignmentScreen)

코치는 Inbox → Compose → "Assignment" 타입을 선택한 뒤 아래 Schema를 입력한다.

| 필드 | 입력 형식 | 예시 |
|---|---|---|
| Movement | 드롭다운 (MovementPicker 재사용) | Back Squat |
| Sets × Reps | 숫자 입력 (세트 / 횟수) | 5 × 5 |
| Load Type | 단위 선택 (6종) | %1RM |
| Load Value | 단위별 입력 | 80 |
| Substitute | 동작 선택 + 조건 텍스트 | Front Squat (어깨 부상 시) |
| Tempo | 4자리 표기 (optional) | 3-1-1-0 |
| Rest | 초 단위 (optional) | 180s |
| Due Date | 날짜 피커 | 2026-05-02 |
| Rationale | 텍스트 (최소 10자) | Open 대비 leg drive 강화. 5주 누적 후 1RM 테스트. |
| Target | 개인 / 그룹 / 전체 | 개인: 김도윤 |

Load Type 6종: `%1RM` · `RPE` · `kg` · `lb` · `sec/500m` · `tempo` · `feel`.

Validate 실패 시 저장 차단 + 누락 필드 강조. 초안(draft) 상태로 임시 저장 가능.

### 4-3. 멤버 수신 화면 (AssignmentDetailScreen)

인박스 ASSIGNMENTS 탭에서 카드 형태로 표시.

```
ASSIGNMENT — Heavy Squat Day
  Back Squat  5 × 5 @ 80% 1RM
  Substitute: Front Squat  (어깨 부상 시)
  Tempo: 3-1-1-0  |  Rest: 180s

DUE: 2026-05-02
COACH: 박지훈

RATIONALE
Open 대비 leg drive 강화. 5주 누적 후 1RM 테스트.

  [ Accept ]          [ Decline ]
```

### 4-4. 멤버 수락 이후 — 결과 입력

수락 후 처방은 상태가 `accepted`로 변경되고, 멤버는 수행 후 아래 결과를 입력한다.

| 필드 | 설명 |
|---|---|
| actualLoad | 실제 사용한 하중 (처방과 동일 단위 표시) |
| actualReps | 실제 수행 횟수 (세트별) |
| RPE | 주관적 강도 1~10 |
| Note | 자유 텍스트 (선택) |
| Substitute Used | 대체 동작 사용 여부 토글 |

완료 입력 시 상태: `accepted` → `completed`. 코치에게 Push 알림 발송.

### 4-5. 거절 흐름

"Decline" 선택 시 사유 선택 필수.

| 사유 코드 | 표시 라벨 |
|---|---|
| `injury` | Injury |
| `schedule` | Schedule conflict |
| `intensity` | Too heavy / Too light |
| `other` | Other |

거절 후 코치는 인박스에서 확인, 재처방(re-assign) 또는 종료 선택.

### 4-6. 코치 피드백

코치는 `completed` 상태의 처방에 피드백 텍스트를 남긴다. 멤버에게 Push 알림.

```
FEEDBACK — 박지훈
실제 83kg으로 완료. RPE 8 기록. 다음 주 85kg 시도.
5주차 종료 시 1RM 테스트 예정.
```

### 4-7. API 설계 (신규 endpoint)

| Method | Path | 설명 |
|---|---|---|
| POST | /api/v1/inbox/assignments | 처방 생성 (coach_owner 만) |
| GET | /api/v1/inbox/assignments | 처방 목록 (role별 필터) |
| GET | /api/v1/inbox/assignments/{id} | 처방 상세 |
| PATCH | /api/v1/inbox/assignments/{id}/accept | 수락 |
| PATCH | /api/v1/inbox/assignments/{id}/complete | 완료 + 결과 입력 |
| PATCH | /api/v1/inbox/assignments/{id}/decline | 거절 + 사유 |
| PATCH | /api/v1/inbox/assignments/{id}/feedback | 코치 피드백 |

모든 응답은 Envelope `{ok, data, error?, code?}`.

### 4-8. 데이터 모델 (AssignmentRecord)

```dart
class AssignmentRecord {
  final String id;
  final String coachId;
  final String memberId;
  final String gymId;

  // 처방 Schema
  final String movement;       // "Back Squat"
  final int sets;
  final int reps;
  final String loadType;       // "%1RM" | "RPE" | "kg" | "lb" | "sec/500m" | "tempo" | "feel"
  final double loadValue;
  final String substitute;     // "Front Squat (어깨 부상 시)"
  final String? tempo;         // "3-1-1-0"
  final int? restSeconds;      // 180
  final DateTime dueDate;
  final String rationale;

  // 상태
  final AssignmentStatus status;  // draft | sent | accepted | completed | declined

  // 수행 결과 (멤버)
  final double? actualLoad;
  final List<int>? actualReps;   // 세트별 횟수
  final double? rpe;
  final String? memberNote;
  final bool substituteUsed;
  final DateTime? completedAt;

  // 거절
  final String? declineReason;   // "injury" | "schedule" | "intensity" | "other"

  // 코치 피드백
  final String? coachFeedback;
  final DateTime? feedbackAt;

  final DateTime createdAt;
}
```

---

## 5. Metrics — 측정 지표

성공 여부는 5개 지표로 판단한다.

| 지표 | 정의 | 목표 |
|---|---|---|
| 처방 발송 수 | 코치당 주간 발송 건수 | 3건 이상 / coach / week |
| 수락률 | 발송 후 48h 내 Accept / 총 발송 | 85% |
| 완료율 | Accept 후 DueDate 내 Complete / 총 Accept | 70% |
| 거절 사유 분포 | injury / schedule / intensity / other 비율 | injury > 30% → 처방 강도 재검토 신호 |
| 코치 피드백률 | completed 중 feedback 작성 비율 | 60% |

부차 지표:

- 처방 내 Substitute 사용률 (substituteUsed = true 비율)
- 처방 Schema 완성도 (Rationale 평균 글자 수)
- 재처방 발생률 (declined → re-assigned 비율)
- 처방 → PR 연계율 (처방 완료 후 같은 동작 PR 발생까지 평균 주 수)

---

## 6. Risks / Trade-offs

### R1. Schema 엄격성 vs. 사용성

**리스크**: 6 필드 필수 입력 + Rationale 최소 10자 + Substitute 의무 조건이 코치에게 마찰 요소가 된다. 특히 베테랑 코치일수록 "이걸 왜 앱에 입력해야 하나"라는 저항이 크다.

**대응**: 처방 템플릿 저장 기능. 코치가 자주 쓰는 처방(Back Squat 5×5 세트)을 저장해두면 다음 처방 시 1탭으로 불러온다. 반복 입력 비용 감소.

**Trade-off**: 템플릿이 지나치게 유연하면 Rationale 재작성 없이 재사용 — 템플릿 불러오기 시 Rationale 필드는 항상 초기화.

---

### R2. Push 의존성

**리스크**: 처방 수락·완료·피드백 loop는 Push 알림 없이는 응답 속도가 급감한다. FCM 미통합(현재 Phase 3 미완) 상태에서는 멤버가 앱을 직접 열어야만 처방 확인 가능.

**대응**: FCM 통합(docs/PHASE3_PUSH.md) 완료 전까지 Assignment 기능은 beta로 출시. 수락률 지표가 FCM 통합 전후로 분리 측정.

---

### R3. 처방 오남용

**리스크**: 코치가 1:1 처방 대신 "전체(all)" 타겟으로 일괄 발송 → 개인화 없는 처방이 남발 → 멤버가 Assignment 탭을 스팸으로 인식 → 수락률 급감.

**대응**: 전체 발송 처방은 Group 개념으로 분리. 개인 처방과 그룹 처방을 ASSIGNMENTS 탭에서 아이콘으로 구분. 코치 대시보드에서 전체 발송 처방 수락률을 분리 표시.

---

### R4. 처방 Schema vs. 페이싱 연동 갭

**리스크**: 현재 페이싱 엔진은 WOD Calc 기반. 처방 처방된 Strength 훈련(5×5, Tempo Squat)은 페이싱 엔진 범위 밖. 멤버가 처방을 받은 뒤 "이 처방 페이싱은?"을 기대할 수 있으나 지원 안 됨.

**대응**: MVP에서는 처방-페이싱 연동 없음 명시. Phase 3에서 Strength 세션 페이싱(세트 간 Rest 자동 산정) 검토.

---

### R5. 결과 입력 마찰

**리스크**: 멤버가 처방을 수행하고도 앱에서 결과 입력을 건너뛸 경우 완료율 수치 왜곡. "완료했는데 기록 안 했다"가 누적되면 코치 피드백 기회 소실.

**대응**: DueDate 경과 후 24h 이내에 "결과 입력 대기 중" 로컬 알림 1회 발송. Push 없는 환경에서는 앱 실행 시 배너 표시. 강제 입력 없음 — 멤버 자율 결정.

---

## 7. Roadmap

### Phase 1 — MVP (현재 목표)

단일 마감일 기반 처방. 1:1 개인 처방. 수락·완료·거절·코치 피드백 4가지 상태. FCM 미통합 상태에서 인박스 폴링 방식.

- Schema: 동작 / 세트×횟수 / 하중(6 단위) / DueDate / Substitute / Rationale
- 타겟: 개인 (1:1)
- 상태: draft → sent → accepted → completed / declined
- Push: FCM 없음. 앱 실행 시 폴링

### Phase 2 — 윈도우 기반 마감 + 그룹 처방

단일 날짜 DueDate → Start Date + End Date 윈도우. 멤버가 윈도우 내 아무 날이나 수행 가능.
그룹 처방: 시간대·실력 그룹 단위 처방. 개인 처방과 ASSIGNMENTS 탭 내 분리 표시.
FCM 통합 완료 → Push 기반 수락·완료 알림.

- Schema 추가: startDate / endDate / targetType(individual/group/all)
- 처방 템플릿 저장·불러오기
- 재처방(re-assign): declined 건에 코치가 수정 처방 발송

### Phase 3 — 자동 PR 추적 + 처방 플래너

처방 완료 후 같은 동작에서 PR 발생 시 처방-PR 연계 자동 기록. 코치는 "처방 X건 후 PR 달성" 통계를 멤버 카드에서 확인.

다중 처방 플래너: 코치가 4~8주 처방 시퀀스를 미리 설계. 매주 자동 발송. Open prep 사이클 전용.

- PR 연계: PrDetector + AssignmentRecord 조인
- 플래너: 주간 처방 시퀀스 + 자동 발송 스케줄
- 분석: 코치 대시보드 — 멤버별 처방 완료율 + PR 달성률 추이

---

## 8. FAQ

**Q1. 코치가 아닌 멤버도 처방을 만들 수 있나?**  
없다. 처방 생성은 `coach_owner` role 전용. 멤버는 수락·완료·거절·질문(Ask Coach)만 가능하다.

**Q2. 처방과 WOD 공지는 어떻게 다른가?**  
WOD 공지는 박스 전체 멤버 대상 당일 WOD. 처방은 개인(또는 그룹) 지정 + 마감일 + 결과 입력 loop가 있는 구조. 인박스 탭도 분리(NOTES vs ASSIGNMENTS).

**Q3. 처방 내 하중 단위 %1RM은 어떻게 계산되나?**  
백엔드가 해당 멤버의 저장된 1RM 값에 처방 퍼센트를 곱해 실제 하중(kg)을 자동 환산해 표시한다. 멤버 프로필에 해당 동작 1RM이 없으면 "1RM 없음 — 먼저 입력" 안내.

**Q4. 같은 처방을 여러 멤버에게 동시에 보낼 수 있나?**  
Phase 1에서는 1:1 개인 발송만 지원. Phase 2에서 그룹·전체 발송 추가.

**Q5. 멤버가 처방을 무시하면(읽지 않으면)?**  
DueDate가 지나면 처방 상태는 `expired`로 자동 변경. 코치는 만료 처방 목록을 대시보드에서 확인. 강제 조치 없음.

**Q6. Substitute 없이 처방을 발송할 수 없다면 부상 위험이 없는 동작도 대체 동작을 넣어야 하나?**  
MVP에서는 Substitute 필드를 "없음(None)" 선택도 허용한다. 코치가 명시적으로 "없음"을 선택하면 통과. 빈 채 건너뛰는 것만 차단.

**Q7. TrainHeroic / TrueCoach 대비 FACING의 차별화 포인트는?**  

| 항목 | TrainHeroic / TrueCoach | FACING |
|---|---|---|
| 언어 | 영어 전용 | 한국어 기본 + 영문 전문 용어 |
| 박스 멤버십 통합 | 별도 SaaS | WOD 공지 + 리더보드 + 처방 한 앱 |
| 페이싱 연동 | 없음 | 동일 앱 내 WOD Calc + Engine Score |
| 티어 시스템 | 없음 | Scaled → Games 5 티어 연동 |
| 게이미피케이션 | 없음 | 칭호 / Level / Season Badge |
| 가격 | $19~49/coach/month | TBD (박스 멤버십 번들) |

**Q8. 처방 기록은 얼마나 보관되나?**  
멤버의 처방 이력은 History 탭에 영속 저장. 코치가 박스를 나가도 멤버의 완료 기록은 유지.

**Q9. 코치가 피드백 없이 다음 처방을 발송할 수 있나?**  
가능하다. 피드백은 의무가 아니다. 단, 코치 대시보드에서 "미피드백 처방 수"를 경고 색으로 표시해 코치 스스로 누락을 인지하도록 한다.

**Q10. 처방 수행 중 부상이 생기면?**  
멤버는 완료 대신 거절(Decline, 사유: Injury)로 상태를 바꿀 수 있다. 이미 Accept 후에도 거절로 전환 가능. 코치에게 즉시 Push 알림 + 인박스 알림 발송.
