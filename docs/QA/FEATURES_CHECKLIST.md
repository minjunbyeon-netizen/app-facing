# FEATURES CHECKLIST — facing-app v1.19+

**FEATURES**
**facing-app + services/facing 전 기능 수동 QA 체크리스트.**

> 페르소나 SSOT: `services/facing/data/personas.json` (10명)
> 기존 자동 회귀: `services/facing/tests/test_personas_e2e.py` (32 케이스)
> 백엔드 endpoint 53개 / 프론트엔드 features 22개 / Provider 17개 / Screen 15개 매핑.

---

## 페르소나 6 컬럼 (체크리스트 표 헤더)

| 약칭 | 페르소나 | 박스 | 상태 | device_id_seed |
|---|---|---|---|---|
| **AD** | admin (변민준) | — | 무소속 | `persona-admin-byun-2026` |
| **C-A** | coach_a (박지훈) | FACING SEONGSU | owner | `persona-coach-park-2026` |
| **C-B** | coach_b (이수민) | FACING GANGNAM | owner | `persona-coach-lee-2026` |
| **M-AP** | member_approved (김도윤·정하은·강민재·윤지원) | 자기 박스 | approved | `persona-member-*-2026` |
| **M-PD** | member_pending (최서윤) | FACING SEONGSU | pending | `persona-member-choi-seoyun-2026` |
| **M-RJ** | member_rejected (한수아) | FACING GANGNAM | rejected | `persona-member-han-suah-2026` |
| **APP** | app_user (송예준) | — | 무소속 | `persona-app-song-yejun-2026` |

---

## 셀 표기 규약

| 표기 | 의미 |
|---|---|
| `OK` | 정상 동작. 수동 확인 필요 |
| `OK†` | 자동 회귀 테스트 통과 (`test_personas_e2e.py`) |
| `OK(자박스)` | 자기 박스 한정. 타박스 차단 |
| `보기만` | 읽기 허용, 쓰기 차단 |
| `받기만` | 수신 가능, 발신 차단 |
| `차단` | 403 / 빈 응답 / UI 진입 불가 |
| `차단†` | 자동 회귀로 차단 검증됨 |
| `N/A` | 역할 특성상 해당 없음 |
| `미확정` | 정책 결정 필요 (별도 표 정리) |

---

## A. 박스 코칭 — 13 항목

**Box Coaching**
**코치/멤버 간 박스 단위 협업 기능.**

### A1. 쪽지 발송 — 코치→멤버
- [ ] **진입**: Coach Dashboard → Member 선택 → "Send Note"
- [ ] **API**: `POST /api/v1/gym/<gym_id>/notes`
- [ ] **권한 매트릭스**

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| N/A | OK(자박스) | OK(자박스) | 받기만 | 미확정 | 차단 | N/A |

- [ ] 코치 A 가 자박스 김도윤에게 발송 → 200
- [ ] 코치 A 가 타박스 강민재(Gangnam)에게 발송 → 403
- [ ] 멤버 김도윤 → POST 호출 → 403 (멤버는 ask 만 가능)

### A2. 쪽지 발송 — 멤버→코치 (Ask Coach)
- [ ] **진입**: Inbox → Note 상세 → "Ask Coach"
- [ ] **API**: `POST /api/v1/gym/notes/<note_id>/ask`
- [ ] **권한**

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| N/A | 받기만 | 받기만 | OK(자박스 코치) | 차단 | 차단 | N/A |

- [ ] 김도윤 → 박지훈에게 ask → 200
- [ ] 최서윤(pending) → ask → 403

### A3. 박스 공지 게시
- [ ] **진입**: Coach Dashboard → "Announcements" → "Compose"
- [ ] **API**: `POST /api/v1/gyms/<gym_id>/announcements`

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| N/A | OK(자박스) | OK(자박스) | 차단 | 차단 | 차단 | N/A |

### A4. 박스 공지 조회
- [ ] **진입**: AnnouncementsScreen
- [ ] **API**: `GET /api/v1/gyms/<gym_id>/announcements`

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| N/A | OK(자박스) | OK(자박스) | OK(자박스) | 차단 | 차단 | N/A |

### A5. 박스 WOD 게시 (코치)
- [ ] **진입**: BoxWodScreen → "Post WOD" / WodPostScreen
- [ ] **API**: `POST /api/v1/gyms/<gym_id>/wods`
- [ ] **검증 항목**:
  - [ ] WOD type (for_time / amrap / emom) 선택 가능
  - [ ] RX / Scaled / Beginner 3 버전 입력 가능
  - [ ] Scale Guide 텍스트 옵션
  - [ ] rounds_data JSON 다중 라운드 입력
  - [ ] time_cap_sec / rounds 양수 검증 (B-IN-9, 10 차수 5 fix)

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| N/A | OK(자박스) | OK(자박스) | 차단 | 차단 | 차단 | N/A |

### A6. 박스 WOD 조회 (멤버)
- [ ] **진입**: BoxWodScreen → 자박스 오늘 WOD
- [ ] **API**: `GET /api/v1/gyms/<gym_id>/wods`
- [ ] 박스 시드된 오늘자 WOD 표시 확인

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| N/A | OK(자박스) | OK(자박스) | OK†(자박스) | 차단† | 차단† | N/A |

### A7. 박스 WOD 삭제 (코치)
- [ ] **진입**: WodDetailScreen → IconButton(delete)
- [ ] **API**: `DELETE /api/v1/gyms/<gym_id>/wods/<wod_id>`

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| N/A | OK(자박스 작성자) | OK(자박스 작성자) | 차단 | 차단 | 차단 | N/A |

### A8. 그룹 만들기·관리 (코치)
- [ ] **진입**: GroupManagementScreen → "+ 버튼"
- [ ] **API**: `POST /api/v1/gym/<gym_id>/groups` / `POST /groups/<group_id>/members`
- [ ] **검증**:
  - [ ] Time HH:MM 검증 (B-IN-3 차수 5)
  - [ ] Capacity 양수 검증 (B-IN-4)
  - [ ] Color #RRGGBB 검증 (B-IN-6)
  - [ ] Member hash hex 8자+ 검증 (B-IN-5)

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| N/A | OK(자박스) | OK(자박스) | 차단 | 차단 | 차단 | N/A |

### A9. 박스 검색
- [ ] **진입**: GymSearchScreen
- [ ] **API**: `GET /api/v1/gyms/search?q=`
- [ ] FACING 공식 박스 최상단 정렬 확인

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK | OK | OK | OK | OK | OK | OK |

### A10. 박스 가입 신청 (Join)
- [ ] **진입**: GymSearchScreen → 박스 선택 → "Join"
- [ ] **API**: `POST /api/v1/gyms/<gym_id>/join`
- [ ] 차수 5 (B-ST-9): 이미 소속 박스 재가입 차단 확인

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK | N/A (이미 owner) | N/A (이미 owner) | N/A (이미 가입) | 미확정 | 미확정 | OK |

### A11. 박스 가입 코드 (Invite Code)
- [ ] **진입 (코치)**: Coach Dashboard → Invite Code 표시 / 재발급
- [ ] **API**: `GET /api/v1/gym/<gym_id>/invite-code` / `POST /regenerate`
- [ ] **진입 (멤버)**: Join by Code 입력
- [ ] **API**: `POST /api/v1/gym/join-by-code`

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| N/A | OK(자박스) | OK(자박스) | 코드 입력만 | 코드 입력만 | 코드 입력만 | OK |

### A12. 멤버 승인/거절 (코치)
- [ ] **진입**: Coach Dashboard → Pending Members → Approve / Reject
- [ ] **API**: `PATCH /api/v1/gyms/<gym_id>/members/<member_id>` body `action=approve|reject`
- [ ] 최서윤(pending) → 박지훈이 승인 / 거절 작동

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| N/A | OK(자박스) | OK(자박스) | 차단 | 차단 | 차단 | N/A |

### A13. 코치 피드백 노트 (Per-WOD-Per-Member)
- [ ] **진입**: WodDetailScreen → 멤버 행 → "Feedback"
- [ ] **API**: `POST /api/v1/gyms/<gym_id>/wods/<wod_id>/feedback`
- [ ] 4자 이상 검증 (B-IN-11 차수 5)

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| N/A | OK(자박스) | OK(자박스) | 보기만(자신것) | 차단 | 차단 | N/A |

### A14. 멤버 요청 (Member Request)
- [ ] **진입**: MemberRequestsScreen
- [ ] **API**: `POST /api/v1/gyms/<gym_id>/requests` (멤버) / `PATCH /requests/<rid>` (코치 응답)
- [ ] 멤버 → 자유 제목/본문 → 코치 open/resolved/dismissed 처리

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| N/A | OK(자박스 응답) | OK(자박스 응답) | OK(자박스 발신) | 차단 | 차단 | N/A |

### A15. 박스 메시지 (1:1 멤버 ↔ 코치)
- [ ] **진입**: MessagesScreen
- [ ] **API**: `POST /api/v1/gyms/<gym_id>/messages` / `GET /messages`
- [ ] 멤버는 코치에게만 송신 가능 (gym.py:589)
- [ ] 차수 5 (B-PF-15): hash substring 길이 안전 확인

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| N/A | OK(자박스 멤버) | OK(자박스 멤버) | OK(자박스 코치만) | 차단 | 차단 | N/A |

---

## B. 개인 기록 — 8 항목

**Personal Records**
**박스 무관 개인 트레이닝 기능.**

### B1. 등급 측정 (Engine Grade)
- [ ] **진입**: ProfileScreen → Benchmarks → "Measure Engine"
- [ ] **API**: `POST /api/v1/profile/grade`
- [ ] **검증**:
  - [ ] 6 카테고리 점수 표시 (POWER / OLYMPIC / GYMNASTICS / CARDIO / METCON / 종합)
  - [ ] overall_number 1~6 → Tier 라벨 (Scaled/RX/RX+/Elite/Games)
  - [ ] 카테고리별 nested score (`g[category][score]`) — 차수 5 B-LG-2 fix
- [ ] 페르소나 등급 일치 (변민준 RX+ / 박지훈·이수민 Elite / 김도윤·정하은 RX / 강민재 RX+ / 송예준 RX)

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK† | OK† | OK† | OK† | OK | OK | OK† |

### B2. WOD Builder (개인 WOD 생성)
- [ ] **진입**: WodBuilderScreen → 카테고리 → 동작 → 횟수/중량 → WOD type
- [ ] **API**: `GET /api/v1/movements/categories` / `GET /api/v1/movements`
- [ ] Calc 진입 → ResultScreen 분할 시퀀스 표시

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK | OK | OK | OK | OK | OK | OK |

### B3. Pacing Calculate (분할 계산)
- [ ] **진입**: WodBuilder → "Calculate"
- [ ] **API**: `POST /api/v1/pacing/calculate`
- [ ] **검증**:
  - [ ] split_pattern 분할 시퀀스 (예: `15-12-10-8-5`)
  - [ ] 폭발 시점 (is_explosion=true) 마킹
  - [ ] rationale 한글 근거 표시

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK | OK | OK | OK | OK | OK | OK |

### B4. WOD Session (타이머 + 기록)
- [ ] **진입**: ResultScreen → "Start WOD" → WodSessionScreen
- [ ] **검증**:
  - [ ] For Time / AMRAP / EMOM 타이머 동작
  - [ ] Wakelock + PopScope 종료 가드
  - [ ] Scaled 토글
  - [ ] 종료 시 Save Record sheet
- [ ] **API**: `POST /api/v1/history/wod`

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK | OK | OK | OK | OK | OK | OK |

### B5. 캘린더 / 출석 히트맵
- [ ] **진입**: AttendanceScreen
- [ ] **검증**:
  - [ ] 월별 히트맵 intensity 0.45–1.0 alpha
  - [ ] 2+ 세션 체크 아이콘
  - [ ] ×N 배지 (3+ 세션)
  - [ ] 일요일 시작 (차수 5 B-LW-12 통일)
  - [ ] 월별 챌린지 표시

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK | OK | OK | OK | OK (0건) | OK (0건) | OK |

### B6. WOD History 조회
- [ ] **진입**: HistoryScreen
- [ ] **API**: `GET /api/v1/history/wod?limit=200`
- [ ] **검증**:
  - [ ] 페르소나 wod_history_count 일치 (admin=8 / coach_a=14 / coach_b=12 / member 7~13 / pending=0 / rejected=0 / app_user=6)
  - [ ] 차수 5 B-LW-9: 그래픽 기호 → 화살표만
  - [ ] HistoryDetailScreen 진입 가능

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK†(8) | OK†(14) | OK†(12) | OK†(7~13) | OK†(0) | OK†(0) | OK†(6) |

### B7. Engine History 스냅샷
- [ ] **API**: `POST /api/v1/history/engine` / `GET /api/v1/history/engine`
- [ ] 등급 측정 결과 자동 저장 → MyPage 그래프
- [ ] TrendsScreen → 카테고리 trend line

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK | OK | OK | OK | OK (1건만) | OK (1건만) | OK |

### B8. Goals (주간/월간/PR/Season)
- [ ] **진입**: GoalsScreen
- [ ] **검증**:
  - [ ] 주간 세션 카운트 (일요일 시작 — B-LW-12)
  - [ ] 월간 세션 카운트
  - [ ] PR 자동 감지 (Sprint 18, 250 XP 보너스)
  - [ ] Season 표시 (Open / Quarterfinals / Semifinals / Games / Offseason)

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK | OK | OK | OK | OK | OK | OK |

---

## C. 시스템 — 9 항목

**System & Identity**
**인증·게이미피케이션·통합 기능.**

### C1. 회원가입 (Splash → Signup)
- [ ] **진입**: SplashScreen → SignupScreen
- [ ] **검증**:
  - [ ] 데모 Naver / Kakao 버튼 (실제 OAuth 미연결)
  - [ ] 약관·개인정보 모달 (차수 5 R5 fontSize 토큰화)
  - [ ] DeviceIdService 최초 UUID 생성

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK† | OK† | OK† | OK† | OK† | OK† | OK† |

### C2. Onboarding (Profile 초기 입력)
- [ ] **진입**: 회원가입 후 OnboardingBasic → Benchmarks → Grade
- [ ] **API**: `POST /api/v1/profile/info` / `POST /api/v1/profile/grade`
- [ ] **검증**:
  - [ ] 체중·신장·나이 범위 검증 (B-IN-7, 8 차수 4)
  - [ ] Benchmarks Skip 가능
  - [ ] kg/lb 토글
  - [ ] Calculating 오버레이 + Quote 표시

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK | OK | OK | OK | OK | OK | OK |

### C3. Profile 수정 + Display Name
- [ ] **진입**: ProfileScreen
- [ ] **API**: `POST /api/v1/profile/info`
- [ ] **검증**:
  - [ ] Display name 수정 (Sprint 19 페르소나 P0-2)
  - [ ] Avatar color
  - [ ] Injury notes
  - [ ] Profile state hasGrade SSOT 일치 (`overall_number` — 차수 5 B-PF-12)
- [ ] 페르소나 display_name 일치 검증 (자동 회귀)

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK† | OK† | OK† | OK† | OK† | OK† | OK† |

### C4. Achievement / 칭호 (FIFA-style)
- [ ] **진입**: AchievementsScreen
- [ ] **API**: `GET /api/v1/achievements` / `POST /achievements/check`
- [ ] **검증**:
  - [ ] Lv 1~50 하이브리드 커브
  - [ ] Worn Title (단일 칭호 SharedPreferences)
  - [ ] Confetti + Haptic 잠금 해제 모먼트
  - [ ] catalog 로딩 실패 → 사용자 메시지 (차수 4 B-PF-18)

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK | OK (Elite 칭호) | OK (Elite 칭호) | OK (등급별) | 미확정 | 미확정 | OK |

### C5. Inbox 통합 조회
- [ ] **진입**: InboxScreen (코치 탭 vs 멤버 탭 토글)
- [ ] **API**: `GET /api/v1/gym/<gym_id>/inbox` / `GET /outbox`
- [ ] **검증**:
  - [ ] 카톡식 미읽음 dot
  - [ ] Note 종류 (assignment / announcement / personal) 필터
  - [ ] 차수 5 B-LW-2: 그룹 이름 표시 (현재 ID — 후속 작업)

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK (박스 알림 없음) | OK (자박스 알림) | OK (자박스 알림) | OK (자박스 알림) | OK (차단된 알림) | OK (차단된 알림) | OK (박스 알림 없음) |

### C6. Note 상세 / 액션 (read·accept·complete·decline·ask)
- [ ] **진입**: NoteDetailScreen
- [ ] **API**: `POST /api/v1/gym/notes/<note_id>/read` 등 5개
- [ ] **검증**:
  - [ ] WHY 섹션 (rationale) 본문 위 고정 노출
  - [ ] Complete 모달 set별 actual_load/reps/rpe 입력
  - [ ] Decline 사유 4개 chip + 자유 입력
  - [ ] 빈 reason 차단 (차수 3 B-IN-12)
  - [ ] actualLoad kg/lb 단위 표시 (차수 5 B-VC-7)

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| N/A | 본인 작성 노트만 | 본인 작성 노트만 | 수신자 본인만 | 차단 | 차단 | N/A |

### C7. Box Social — 결과 + 댓글
- [ ] **진입**: WodDetailScreen → Results / Comments 탭
- [ ] **API**:
  - [ ] `POST /api/v1/gyms/<gym_id>/wods/<wod_id>/results` (RX / Scaled / Beginner 3-version 토글)
  - [ ] `GET /results` (박스 리더보드)
  - [ ] `POST /comments` / `GET /comments` / `DELETE /comments/<cid>`
- [ ] 차수 5 B-VC-4: 댓글 hint 슬랭 제거 확인

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| N/A | OK(자박스) | OK(자박스) | OK(자박스) | 차단 | 차단 | N/A |

### C8. 박스 리더보드
- [ ] **진입**: BoxLeaderboardScreen
- [ ] **API**: WOD 결과 + 멤버별 시간 정렬 (gym.py results)
- [ ] 박스 시드 더미 멤버 + Tier 배지 표시

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| N/A | OK(자박스) | OK(자박스) | OK(자박스) | 차단 | 차단 | N/A |

### C9. Trends + Heatmap (월별 활동)
- [ ] **진입**: TrendsScreen
- [ ] **검증**:
  - [ ] streak 계산 일관성 (attendance 와 통일)
  - [ ] FutureBuilder ConnectionState 분기 (차수 2 B-FB-3)
  - [ ] hidden 배지 동적 (차수 4 B-PF-7)

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK | OK | OK | OK | OK (0건) | OK (0건) | OK |

---

## D. 인프라 / 메타 — 4 항목

**Infrastructure**
**시스템 단위 동작.**

### D1. /health
- [ ] **API**: `GET /health` → 200
- [ ] **자동**: `test_health` 통과 †

### D2. Offline Banner
- [ ] **진입**: 네트워크 끊김 시 상단 배너
- [ ] 차수 5 B-VC-1: `OFFLINE` 헤딩 + `연결 시 동기화.` 캡션 stack
- [ ] ConnectivityState init 로깅 (B-LW-16 미적용 — 후속)

### D3. Inventory (Streak Freeze 등 아이템)
- [ ] **진입**: MyPage → Inventory
- [ ] **API**: `GET /api/v1/inventory` / `POST /inventory/use`
- [ ] Phase 2 권고 — 미구현 영역 다수

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK (보유 시) | OK | OK | OK | OK | OK | OK |

### D4. Presets (공식 WOD 라이브러리)
- [ ] **진입**: PresetsScreen
- [ ] **API**: `GET /api/v1/wods/presets`
- [ ] Fran / Murph / Cindy 등 공식 WOD 목록 + 상세
- [ ] 차수 3 B-ER-1: snap.error 직접 노출 차단

| AD | C-A | C-B | M-AP | M-PD | M-RJ | APP |
|---|---|---|---|---|---|---|
| OK | OK | OK | OK | OK | OK | OK |

---

## 미확정 정책 — 결정 필요

| ID | 항목 | 결정 사항 |
|---|---|---|
| P1 | A1 pending 쪽지 수신 | 승인 전 코치 안내 메시지 수신 허용? 현재 백엔드 inbox 401 추정 |
| P2 | A10 pending 재신청 | 동일 박스 중복 신청 차단/허용 |
| P3 | A10 rejected 재신청 | 거절 후 재신청 허용 (기간 제한?) or 영구 차단 |
| P4 | C4 pending/rejected Achievement | 박스 가입 무관 개인 칭호 발행 기준 |
| P5 | A11 invite_code 멤버 직접 사용 | join-by-code 가 박스 우회 가입인지 |
| P6 | C5 cross-box inbox | 다른 박스에서 발송된 노트가 inbox 에 노출되나 |

---

## 자동 회귀 vs 수동 QA 분리

### 자동 회귀 (32 케이스 이미 통과 †)
- B1, B6, C1, C2, C3 핵심 endpoint
- A6 박스 WOD 조회 권한 경계
- D1 health
- 페르소나 6 컬럼 × profile/info 200 + display_name 일치

### 수동 QA 전용 (UI 동작 확인 필수)
- A1~A5, A7, A8, A11~A15 박스 코칭 UI 플로우
- B2, B3, B4 WOD 빌더·세션 타이머
- B5, B8 캘린더 / Goals 화면
- C4 Achievement 잠금 해제 모먼트 (Confetti + Haptic)
- C5~C9 Inbox / Note / Social / Leaderboard / Trends UI
- D2~D4 Offline / Inventory / Presets

---

## 실행 가이드

### 1. 자동 회귀 (10초)
```bash
cd C:/dev/services/facing
python -m pytest tests/test_personas_e2e.py -v
```
32/32 통과 확인. 실패 시 본 체크리스트 † 셀 재검증.

### 2. 수동 QA — 페르소나 device_id 로 진입
백엔드 시드 후 Flutter 앱에서 device_id 직접 주입 필요 (Phase 2 작업).
```bash
cd C:/dev/services/facing
python -m data.seed_personas
python app.py    # localhost:5060
```

### 3. 박스 owner 진입 시뮬레이션
- 박지훈 시뮬: `X-Device-Id: persona-coach-park-2026` 헤더로 호출
- 김도윤 시뮬: `X-Device-Id: persona-member-kim-doyun-2026`
- 최서윤 시뮬 (pending): `X-Device-Id: persona-member-choi-seoyun-2026`

---

## 카운트 요약

| 카테고리 | 항목 수 | 자동 † | 수동 |
|---|---|---|---|
| A 박스 코칭 | 15 | 1 | 14 |
| B 개인 기록 | 8 | 4 | 4 |
| C 시스템 | 9 | 3 | 6 |
| D 인프라 | 4 | 1 | 3 |
| **합계** | **36** | **9** | **27** |

> 자동 회귀 9 + 수동 QA 27 = 36 기능 항목.
> 페르소나 7 컬럼 × 36 행 = 252 권한 셀. 미확정 6건은 P1~P6 별도 표로 추적.
