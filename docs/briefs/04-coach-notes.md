# §4 Coach Notes — 6-Pager
> facing-app · 2026-04-28 · 작성자: Product / 검토: Eng + Coach

---

## 1. TL;DR

박스 코치와 멤버 간 직접 통신 채널을 앱 안에 내장한다.

카카오톡 단톡방을 대체하는 것이 아니라, **박스 컨텍스트가 붙은 구조화 통신**을 새로 정의한다. 코치는 개인 / 그룹 / 전체 세 범위 중 하나를 선택해 Note 를 발송한다. 멤버는 4 탭 (ALL / NOTES / ASSIGNMENTS / OUTBOX) 인박스에서 수신하고, 읽음·수락·거절·Ask Coach 네 가지 액션을 취한다. 미읽음은 빨간 dot 으로 즉시 표시되며, Phase 3 에서 FCM Push 로 전환된다.

**권한 게이트는 엄격하다.** `isOwner || isApprovedMember` 만 인박스를 열 수 있다. Pending·Rejected·no-gym 사용자는 인박스 진입점 자체가 차단된다.

**핵심 수치 목표:** 발송 후 4시간 이내 읽음률 70%, Ask Coach 답장 전환율 20%.

---

## 2. Problem — 카카오톡 단톡방의 한계

박스 코치는 현재 카카오톡 단톡방으로 멤버에게 훈련 지시, 일정 변경, 개인 피드백을 전달한다. 이 방식이 가진 구조적 결함은 세 가지다.

**[1] 컨텍스트 증발**

단톡방은 WOD, 일정 공지, 개인 피드백, 잡담이 하나의 흐름에 섞인다. "지난주 Snatch 피드백 어디 갔지?"를 검색하는 시간은 코치와 멤버 양쪽이 낭비한다. 박스 컨텍스트 (박스명, 멤버 Tier, WOD 이력) 가 메시지에 붙지 않으므로 의미가 바로 증발한다.

**[2] 권한 없음**

단톡방은 코치와 멤버를 구분하지 않는다. Pending 상태 사용자, 이미 탈퇴한 멤버, 초대받지 않은 제3자가 피드백을 볼 수 있다. 개인 부상 정보, 1RM, 컨디션 노트 같은 민감 데이터가 무방비로 노출된다.

**[3] 자동 분류 없음**

"내일 오전반 출석 체크" 공지와 "김도윤 오른쪽 어깨 주의" 개인 메모가 같은 채널에 있다. 숙제(Assignment) 수락 여부, 읽음 확인, 질문 답장이 자동으로 추적되지 않는다. 코치는 "읽었어?" 를 매번 별도로 확인해야 한다.

**Coach Notes 가 해결하는 것:**

| 문제 | 해결 방식 |
|---|---|
| 컨텍스트 증발 | 박스 ID + 멤버 Tier + 발송 타임스탬프 자동 첨부 |
| 권한 없음 | `isOwner \|\| isApprovedMember` 게이트. 탈퇴·Pending 차단 |
| 자동 분류 없음 | 4 탭 (ALL / NOTES / ASSIGNMENTS / OUTBOX) 자동 라우팅 |
| 읽음 미추적 | markRead + 빨간 dot + Phase 3 FCM Push |
| 숙제 답장 | Ask Coach 전용 액션 타입 |

---

## 3. Tenets — 인박스 설계 원칙

**T1. 박스 게이트 우선.**
인박스는 박스 소속 코치와 승인 멤버 전용이다. 가입 심사 통과 이전에는 인박스 진입점을 렌더링하지 않는다. "승인 대기 중" 안내 화면만 노출.

**T2. 탭은 4개, 고정.**
ALL / NOTES / ASSIGNMENTS / OUTBOX (코치 전용). 탭 추가는 Phase 5 이전 금지. 분류 기준: Note = 일반 메시지, Assignment = 숙제 (accept/decline 필요), OUTBOX = 발신 확인.

**T3. Ask Coach 는 별도 액션 타입.**
멤버의 답장은 자유 텍스트 채팅이 아니다. "Ask Coach" 버튼 누르면 텍스트 입력창이 열리고, 해당 질문은 코치 인박스 OUTBOX 스레드에 질문 태그로 묶인다. 채팅 UX 는 Phase 6 이후 검토.

**T4. 미읽음은 즉시, 조용히.**
빨간 dot 은 앱 로드 직후 GET /api/v1/inbox 응답 기준으로 즉시 렌더링. FCM Push 는 Phase 3 완료 후 옵트인. "알림 설정 강요" 없음.

**T5. 발송 범위는 코치만.**
멤버는 Ask Coach 답장만 가능. 멤버 → 코치 직접 Note 발송, 멤버 → 멤버 DM 없음. 채널은 단방향 (코치 → 멤버) + 제한 역방향 (멤버 → 코치, Ask Coach 한정).

**T6. Optimistic Update, 롤백 보장.**
멤버의 읽음 표시·수락·거절은 UI 를 즉시 갱신하고 백그라운드에서 서버 동기화. 실패 시 snackbar 알림 + 원래 상태 복원. 서버 응답 대기 중 스피너 없음.

---

## 4. Approach — 발송부터 수신·액션까지

### 4-1. 코치: Compose → 발송

코치 (isOwner) 는 Profile → OUTBOX 탭 우상단 "+" 버튼으로 ComposeNoteScreen 진입.

**발송 옵션 3단계 선택:**

```
범위 선택 → 수신자 확인 → 내용 작성 → Send
```

| 범위 | 의미 | UI |
|---|---|---|
| Individual | 멤버 1명 지정 | 멤버 검색 (이름 + Tier 배지) |
| Group | 특정 그룹 (예: 7AM Class) | 그룹 드롭다운 |
| All | 박스 전체 멤버 | 경고 팝업 ("N명에게 발송") |

**Note 타입 선택:** NOTES (일반) / ASSIGNMENTS (숙제, §5 6-pager 참조).

**ASSIGNMENTS 선택 시 추가 필드:**
- 동작 (Movement picker)
- 세트 × 횟수
- 하중 단위: %1RM / RPE / kg / lb / sec/500m / tempo / feel
- 마감일
- 대체 동작 (선택)
- Rationale 메모 (선택, "왜 이걸 하는가")

**API 호출:**
```
POST /api/v1/inbox/notes
Body: { target: "individual|group|all", targetId?, type: "note|assignment", content, assignmentPayload? }
Response Envelope: { ok: true, data: { noteId, sentAt, recipientCount } }
```

오류 응답 시 토스트: `"Send failed. Retry."` (V7 전술적 실패 카피).

---

### 4-2. 멤버: 수신 + 4 탭 분류

멤버 (isApprovedMember) 는 Profile → InboxEntry 탭 진입.

**탭 구조:**

```
[ ALL ]  [ NOTES ]  [ ASSIGNMENTS ]  (+ [ OUTBOX ] — 코치 전용)
```

- **ALL**: 전체 수신 메시지 역순 (최신 상단). 미읽음 dot 포함.
- **NOTES**: type = "note" 필터. 박스 공지, 개인 피드백, 그룹 안내.
- **ASSIGNMENTS**: type = "assignment" 필터. 수락 대기 (PENDING) / 수락됨 (ACCEPTED) / 완료 (COMPLETED) / 거절 (DECLINED) 상태 배지.
- **OUTBOX** (코치 전용): 본인이 발송한 메시지 + 각 수신자별 읽음 여부 목록.

**데이터 로드:**
```
GET /api/v1/inbox
Response: { notes: [...], unreadCount: N }
```

앱 foreground 복귀 시 자동 reload. Pull-to-refresh 지원.

---

### 4-3. 멤버 액션 4종

각 Note Detail 화면 하단 액션 바:

| 액션 | 조건 | API |
|---|---|---|
| markRead | 미읽음 상태 | PATCH /api/v1/inbox/notes/{id}/read |
| Accept | ASSIGNMENTS + PENDING | PATCH /api/v1/inbox/notes/{id}/accept |
| Decline | ASSIGNMENTS + PENDING | PATCH /api/v1/inbox/notes/{id}/decline + 사유 선택 |
| Ask Coach | 모든 Note | POST /api/v1/inbox/notes/{id}/ask + 텍스트 |

**거절 사유 팔레트 (선택 + 직접 입력 선택):**
부상 / 일정 충돌 / 장비 미보유 / 기타

**Ask Coach 플로우:**
1. "Ask Coach" 버튼 탭 → 텍스트 입력창 (placeholder: "Question.")
2. Send → POST 완료 → 입력창 닫힘 + "Sent." 토스트
3. 코치 OUTBOX 스레드에 `[QUESTION]` 태그로 표시

---

### 4-4. 알림 체계

**현재 (Phase 2):**
- 앱 로드 시 `unreadCount > 0` → 인박스 탭 아이콘 빨간 dot
- Note Detail 진입 시 자동 markRead (Optimistic Update)

**Phase 3 (FCM Push):**
- 코치 발송 시점에 수신자 device_push_token 으로 FCM 발송
- Payload: `{ type: "inbox_note", noteId, senderName, preview (40자 이하) }`
- 옵트인 전용. 앱 최초 실행 후 "Allow Notifications?" 팝업 1회만.
- 백엔드: `device_push_tokens` 테이블 + 발송 트리거 (docs/PHASE3_PUSH.md 참조)

**알림 카피 원칙:**
- "Coach sent you a note." (개인)
- "New message in FACING SEONGSU." (그룹/전체)
- "Assignment due in 2 days." (마감 임박, D-2 자동 리마인드 — Phase 3)

---

## 5. Metrics — 측정 기준

Coach Notes 의 성공 지표는 단순 발송 건수가 아니라 **코치 도구 의존도** 와 **멤버 반응률** 로 측정한다.

### 5-1. 코어 지표

| 지표 | 정의 | 목표값 |
|---|---|---|
| 발송 횟수 (Notes Sent) | 코치 per-week 발송 건수 | 박스당 주 5회+ |
| 읽음률 (Read Rate) | 발송 후 4시간 내 `markRead` 비율 | 70% |
| 응답률 (Ask Coach Rate) | Note 수신 중 Ask Coach 전환 비율 | 20% |
| Assignment 수락률 | ASSIGNMENTS 수신 중 Accept 비율 | 60% |
| 인박스 DAU/MAU | 승인 멤버 중 당일 인박스 진입 비율 | 40% (DAU/MAU 기준) |

### 5-2. 이상 신호 임계

| 신호 | 임계 | 대응 |
|---|---|---|
| 읽음률 < 30% (7일 연속) | 낮음 | FCM Push 조기 전환 검토 |
| Ask Coach 0건 (14일) | 낮음 | Note 카피·UX 재검토 |
| 발송 오류율 > 5% | 높음 | 백엔드 인박스 엔드포인트 디버깅 |
| Decline 율 > 50% (Assignment) | 높음 | 코치 사용 패턴 인터뷰 |

### 5-3. 측정 방법 (현재)

백엔드 `/api/v1/inbox` 응답에 `readAt`, `acceptedAt`, `declinedAt`, `askedAt` 타임스탬프 포함. 집계는 `services/facing/` 관리자 엔드포인트 (Phase 3).

---

## 6. Risks / Trade-offs

### 6-1. 코치 과부하 (가장 큰 위험)

**리스크**: Ask Coach 가 활성화되면 코치 1명이 박스 전체 멤버의 질문에 답해야 한다. 박스 규모가 30명 이상이면 코치 응답 부담이 채팅 앱 수준으로 증가한다.

**완화 방법:**
- Ask Coach 는 Note 에 묶인 스레드만. 독립 채팅 없음.
- 코치 OUTBOX 에서 미응답 질문만 필터링 가능.
- Phase 4: 코치 응답 템플릿 (자주 쓰는 답변 저장).
- Phase 5: 어시스턴트 코치 계정 (isAssistant 권한) — 답장 권한 분산.

**수용하는 Trade-off**: 채팅 경험(실시간, 읽고 있음 표시, 입력 중 표시)은 MVP 에서 제공하지 않는다. Ask Coach 는 비동기 Q&A 모델이다. 코치가 즉시 응답하지 않아도 앱이 "읽지 않음" 을 과도하게 강조하지 않는다.

### 6-2. 그룹·전체 발송 스팸

**리스크**: 코치가 잘못된 범위로 발송 (All 선택 → 전체 100명에게 개인 메모). 취소 기능 없음.

**완화 방법:**
- All 선택 시 확인 팝업: `"N명에게 발송. 취소 불가."` (V3 10단어 이하 원칙).
- 발송 후 30초 내 recall 기능 — Phase 3 (현재: 서버 DB 직접 delete 필요).

**수용하는 Trade-off**: MVP 에서는 발송 취소 없음. 코치 UX 교육이 완화 수단.

### 6-3. 인박스 게이트 vs UX 마찰

**리스크**: Pending 멤버가 코치 Note 를 받지 못해 박스 가입 동기 저하.

**완화 방법:**
- Pending 멤버 전용 안내 화면: `"Approval pending. Coach will contact you."` (단, 인박스 탭 차단 유지).
- 코치가 Pending 멤버에게도 직접 Note 발송 허용 여부 — Phase 3 검토 (현재: 차단).

**수용하는 Trade-off**: 권한 단순화가 UX 마찰보다 중요하다. 승인 전 채널 노출은 박스 정보 보안 문제.

### 6-4. FCM Push 지연

**리스크**: FCM 통합 전까지 멤버가 Note 를 수동 확인해야 한다. 읽음률 목표 70% 달성 어려울 수 있다.

**완화 방법:**
- 앱 foreground 복귀 시 자동 reload (현재 구현).
- "오늘 새 Note" 요약을 홈 화면 카드에 노출 — Phase 3.
- 읽음률 30% 미만 지속 시 FCM 조기 착수 트리거.

---

## 7. Roadmap

### 7-1. 현재 완료 (Phase 2)

| 기능 | 상태 |
|---|---|
| 인박스 4 탭 (ALL / NOTES / ASSIGNMENTS / OUTBOX) | 완료 |
| ComposeNoteScreen (개인 / 그룹 / 전체 발송) | 완료 |
| Note Detail + 액션 바 (markRead / Accept / Decline / Ask Coach) | 완료 |
| 권한 게이트 (isOwner \|\| isApprovedMember) | 완료 |
| 미읽음 빨간 dot | 완료 |
| Optimistic Update + 롤백 | 완료 |
| coach_note.dart / coach_group.dart DTO | 완료 |

### 7-2. Phase 3 (다음 스프린트)

| 기능 | 의존성 | 우선순위 |
|---|---|---|
| FCM Push 통합 | Firebase 프로젝트 + google-services.json | P0 |
| device_push_tokens 백엔드 테이블 | 백엔드 DB 마이그레이션 | P0 |
| D-2 마감 리마인드 (Assignment) | FCM 완료 후 | P1 |
| Note recall (발송 30초 내 취소) | 백엔드 API 추가 | P1 |
| InboxScreen 위젯 테스트 | 없음 | P2 |

### 7-3. Phase 4

| 기능 | 내용 |
|---|---|
| 코치 응답 템플릿 | 자주 쓰는 Ask Coach 답변 저장·재사용 |
| Note 카테고리 태그 | #technique / #nutrition / #schedule / #injury |
| 인박스 검색 | 날짜·키워드 필터 |
| 이미지 첨부 | Note 에 사진 1장 첨부 (S3 presigned URL) |

### 7-4. Phase 5 이후

| 기능 | 내용 |
|---|---|
| 어시스턴트 코치 계정 | isAssistant 권한, 답장 가능 |
| Pending 멤버 Note 수신 | 승인 전 단방향 코치 → Pending 채널 |
| 그룹 Note 스레드 | 그룹 수신자 전체가 볼 수 있는 공개 답장 |
| 실시간 채팅 (WebSocket) | Phase 6, 별도 아키텍처 결정 필요 |

---

## 8. FAQ

**Q1. 왜 카카오톡 대신 앱 내 인박스인가?**

카카오톡은 박스 컨텍스트, 멤버 권한, 메시지 자동 분류가 없다. FACING 인박스는 코치가 "7AM Class 전체에 Back Squat Assignment 발송" 한 번으로 해당 그룹만 지정 발송하고, 수락 여부를 자동 집계한다. 카카오톡 대체가 아닌 **운동 도구로서 통신** 이다.

**Q2. 멤버가 Note 를 받지 못하는 경우는?**

`isApprovedMember` 가 아니면 인박스 자체를 볼 수 없다. Pending 상태에서는 박스 승인 화면만 노출. Rejected 또는 no-gym 사용자는 인박스 진입점이 렌더링되지 않는다.

**Q3. 코치가 보낸 Note 를 삭제할 수 있나?**

Phase 3 까지는 삭제 불가. "All 발송" 확인 팝업이 유일한 방어선. Phase 3 에서 발송 30초 내 recall 기능 추가 예정.

**Q4. Ask Coach 답장은 어디에 표시되나?**

코치 OUTBOX 의 해당 Note 스레드에 `[QUESTION]` 태그로 표시된다. 멤버 측에서는 Note Detail 하단 Ask Coach 섹션에 질문 전송 확인 상태가 표시된다. 코치 답변은 별도 Note 로 발송 또는 Phase 4 스레드 기능 후 인라인 표시.

**Q5. 그룹은 코치가 직접 만드나?**

코치 (isOwner) 가 Groups 관리 화면에서 그룹 이름 + 멤버 지정. 예: "7AM Class", "Barbell Club", "Open Prep Group". 멤버는 그룹 설정 권한 없음.

**Q6. 미읽음 dot 이 사라지는 시점은?**

Note Detail 진입 시 즉시 markRead API 호출 + Optimistic Update 로 dot 제거. 서버 실패 시 dot 복원.

**Q7. ASSIGNMENTS 와 일반 NOTES 의 차이는?**

NOTES 는 읽음으로 처리가 끝난다. ASSIGNMENTS 는 Accept / Decline 액션이 필요하고, 수락 후 완료 기록 (actualLoad / actualReps / RPE) 을 입력해야 COMPLETED 상태로 전환된다. §5 6-pager 에서 상세 다룬다.

**Q8. 코치가 Note 를 잘못된 멤버에게 보낸 경우 대응은?**

Phase 3 까지는 코치가 해당 멤버에게 OUTBOX 에서 확인 후 후속 Note 로 정정 발송. 자동 취소는 미지원. 개인 정보 포함 Note 발송 실수는 박스 오너 교육 사항.

**Q9. 인박스 데이터 보존 기간은?**

MVP 에서는 무기한. Phase 4 에서 90일 아카이브 정책 검토 (멤버 탈퇴 시 즉시 삭제 원칙과 동일하게 처리).

**Q10. FCM Push 와 빨간 dot 중 어느 쪽이 더 중요한가?**

읽음률 지표 기준으로 FCM Push 가 더 강하다. 그러나 앱 내 dot 은 즉각 구현 가능하고 옵트인 마찰이 없다. Phase 2 에서 dot 을 먼저 확보하고, Phase 3 에서 FCM 로 읽음률 격차를 메운다.

---

## 부록 A — 권한 매트릭스

| 사용자 역할 | 인박스 탭 | Compose | Ask Coach | 인박스 진입점 |
|---|---|---|---|---|
| isOwner (coach) | ALL / NOTES / ASSIGNMENTS / OUTBOX | 가능 | 해당 없음 | 노출 |
| isApprovedMember | ALL / NOTES / ASSIGNMENTS | 불가 | 가능 | 노출 |
| Pending | 없음 | 불가 | 불가 | 차단 |
| Rejected | 없음 | 불가 | 불가 | 차단 |
| no-gym (app_user) | 없음 | 불가 | 불가 | 차단 |

---

## 부록 B — 데이터 모델 요약

```
CoachNote {
  id: String
  boxId: String
  senderId: String           // coach device_id
  target: "individual|group|all"
  targetId: String?          // memberId 또는 groupId (target = individual|group 시)
  type: "note|assignment"
  content: String
  assignmentPayload: AssignmentPayload?
  sentAt: DateTime (ISO8601 UTC)
  recipientCount: int
}

InboxEntry (멤버 뷰) {
  noteId: String
  type: "note|assignment"
  senderName: String
  preview: String            // content 앞 40자
  sentAt: DateTime
  readAt: DateTime?
  status: "unread|read|accepted|declined|completed"  // assignment 만 accepted/declined/completed
  askCoachSent: bool
}
```

---

## 부록 C — API 엔드포인트 목록

| Method | Path | 역할 | 권한 |
|---|---|---|---|
| GET | /api/v1/inbox | 인박스 전체 조회 | approved + owner |
| POST | /api/v1/inbox/notes | Note 발송 | owner 만 |
| PATCH | /api/v1/inbox/notes/{id}/read | 읽음 표시 | approved + owner |
| PATCH | /api/v1/inbox/notes/{id}/accept | 수락 (Assignment) | approved 만 |
| PATCH | /api/v1/inbox/notes/{id}/decline | 거절 (Assignment) | approved 만 |
| POST | /api/v1/inbox/notes/{id}/ask | Ask Coach 질문 | approved 만 |
| GET | /api/v1/inbox/outbox | 발신함 (코치) | owner 만 |
