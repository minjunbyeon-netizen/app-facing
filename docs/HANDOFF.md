# HANDOFF - 2026-04-25 16:28 (v1.16 · Sprint 10–17 완료 + 코칭/박스 소셜 + 더미 캡처)

## 완료 (이번 세션 누적)

### Sprint 10 — WOD Session
- WOD 세션 타이머 (For Time / AMRAP / EMOM)
- Wakelock + PopScope 종료 가드
- Scaled 토글 + Calc deeplink + Algorithm transparency
- 자동 캘린더 갱신 (`WodSessionBus.bump()`)

### Sprint 11 — UX 강화
- 페르소나 Q100/S100 피드백 반영
- Heatmap 캘린더 (intensity 0.45–1.0 alpha + check icon + ×N 배지)

### Sprint 12 — Coach Dashboard
- 15 더미 회원 (12 approved · 2 pending · 1 rejected)
- 161 WOD 히스토리 시드 (active / dormant / fresh 모드)
- Scale Guide + Duplicate WOD

### Sprint 13 — Growth
- Goals (weekly/monthly/PR/season)
- Tier Roadmap, Box Leaderboard, Favorite Athlete

### Sprint 14 — Gamification (전문가 패널)
- Level 1–50 하이브리드 커브 + 한국어 칭호 시스템
- Worn Title (단일 칭호 SharedPreferences 저장)

### Sprint 15 — Announcements & Messages
- 박스 공지 + 1:1 메시지
- WOD `rounds_data` JSON 컬럼

### Sprint 16 — Box Social
- 박스 내부 WOD 리더보드 + 댓글
- RX / Scaled / Beginner 3-version 토글

### Sprint 17 — Coaching Two-Way
- Coach Feedback (per-wod-per-member)
- Member Requests (subject / body / status: open · resolved · dismissed)

### 검증 & 캡처
- Phase 1 검증 (백엔드 health + 10 endpoints + DB state + flutter analyze)
- 더미 스크린샷 19장 (`dummy/01~19_*.png`) — 코치 + 멤버 화면 양쪽

## 진행중
- [ ] **게이미피케이션·칭호·업적 확장** (사용자 직전 요청 — 미착수)
  - 중단 지점: 요구사항 수신만 완료, 작업 시작 전 세션 종료
  - 다음 스텝:
    1. Panel B 20-title catalog 추가 (현재 15+5 시드, 시즌 한정·이스터에그·PR 기반 미적용)
    2. Streak Freeze / Rest Pass 아이템 시스템 (Panel C 권고)
    3. 시즌 한정 배지 (Spring Surge / Fall Grind / Year-End Warrior)
    4. PR 자동 감지 + 250 XP 보너스
    5. Level Decay (90일 비활동 → 5%/월)
    6. 칭호 잠금 해제 축하 모먼트 (confetti + Haptic.heavyImpact)

## 대기
- [ ] `dummy/18_session_running.png`, `19_save_record_sheet.png` 좌표 재조정 후 재촬영
- [ ] Phase 2 백로그:
  - FCM Push 알림
  - SNS 공유 카드
  - 영상 폼 분석
  - Whoop / Garmin OAuth
  - Cloud 백업
  - Friends / Follow 시스템

## 결정사항 / 주의

### 1. 배포 금지 규칙 (CLAUDE.md 최상위)
사용자 명시 "배포해" 전까지 어떤 형태의 배포도 금지. `git push`, Railway/Vercel/Fly, `gh pr`, store 업로드 모두 차단. 로컬 commit·로컬 빌드·에뮬레이터 설치만 허용.

### 2. FACING owner_hash 우회
SHA-256 + SECRET_KEY salt로 디바이스 ID 재해시되므로 owner_hash 직접 매칭 불가. 더미 데이터는 SQLAlchemy 세션으로 직접 시드.

### 3. Provider lifecycle
hot reload 시 main() 재실행 안 됨. Null Provider 에러 발생 시 `q` + `flutter run` 풀 재시작 필요.

### 4. 타이포 R5 (CLAUDE.md v1.14)
모든 fontSize는 `FacingTokens` 상수 참조. 인라인 `TextStyle(fontSize: N)` 커밋 거절.

### 5. Sprint 17 데이터 모델
- `GymCoachFeedback`: gym_id + wod_post_id + member_hash UNIQUE 제약 (per-wod-per-member upsert)
- `GymMemberRequest`: from_hash + status('open'|'resolved'|'dismissed') + coach_response nullable
- 둘 다 `models/gym_coach_feedback.py` 단일 파일

### 6. 자동 commit 정책
이번 세션 누적 commit (직전 HANDOFF 이후): `93d2b17`, `5fd1e37`, `229561e`, `de98085`, `fdb3c58` + 본 인계 commit 예정.

## 다음 세션 권장 첫 프롬프트
```
/resume HANDOFF 이어받아 — 게이미피케이션 칭호 업적 확장 작업 계속
```

## 관련 경로

| 역할 | 경로 |
|---|---|
| 게이미피케이션 코어 | `lib/core/level_system.dart` · `lib/core/worn_title_store.dart` |
| 업적/칭호 시드 | `services/facing/data/seed_achievements.py` |
| Coach Feedback | `lib/features/gym/wod_detail_screen.dart` · `models/gym_coach_feedback.py` |
| Member Requests | `lib/features/gym/member_requests_screen.dart` · `lib/models/coach_feedback.dart` |
| 박스 리더보드 | `lib/features/gym/wod_detail_screen.dart` (results + comments 통합) |
| Goals | `lib/core/goals_state.dart` · `lib/features/goals/goals_screen.dart` |
| 더미 시드 | `services/facing/data/seed_dummy_coaching.py` · `seed_facing_gym.py` |
| 캡처 19장 | `dummy/01~19_*.png` |

## 이전 HANDOFF
- `docs/archive/HANDOFF-2026-04-24.md` (v1.15 자산 연결)
- `docs/archive/HANDOFF-2026-04-24-v1152.md` (v1.15.2 페르소나 P0/P1/P2 반영)
