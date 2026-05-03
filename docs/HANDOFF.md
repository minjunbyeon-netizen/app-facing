# HANDOFF - 2026-05-03 20:31

## 완료
- [x] `tierGrade()` 스코어 스케일 수정: 0~1 → 1~6 (엔진 점수 0% 표시 버그 수정) — `864538d`
- [x] 페르소나 전수조사 + 더미 데이터 삽입
  - `gym_members` 8명 (approved/pending/rejected), `engine_snapshots` 80건, `gym_announcements` 6건
  - gym owner_hash: SEONGSU(gym_id=2)=박지훈, GANGNAM(gym_id=3)=이수민
- [x] `GymInfoCard` 공유 위젯 추출 → `lib/widgets/gym_info_card.dart` — `1b8a74c`
- [x] NOTICE 탭(`InboxScreen`) 최상단 체육관 정보 카드 추가 (위치·전화번호·코치약력·수업시간·모토)
- [x] 코치 더미 데이터 gym.id 키맵으로 교체 (박지훈=gym_id:2, 이수민=gym_id:3) — `d60d05a`

## 진행중
- 없음 (모든 작업 완료 상태)

## 대기
- [ ] `GymSummary` 모델에 `phone`, `coach`, `classSchedule`, `motto` 실제 필드 추가
  - 백엔드 `/api/v1/gyms/mine` 응답에 필드 추가 필요
  - `GymInfoCard._gymData` 하드코딩 const 맵 제거 → 실데이터로 교체
- [ ] `AnnouncementsScreen` 진입 경로 확인 (현재 메인 탭에서 직접 접근 불가한 것으로 보임)
- [ ] 갤럭시 실기 QA (이전 세션 대기 항목 승계)

## 결정사항 / 주의

### 핵심 아키텍처
- **NOTICE 탭** = `lib/features/inbox/inbox_screen.dart` (탭 index=2, label='Notice')
- **Announcements** = `lib/features/announcements/announcements_screen.dart` (별도 라우트, 탭 아님)
- **GymInfoCard** 공유 위젯: `lib/widgets/gym_info_card.dart` — 두 화면 모두 사용

### 백엔드 DB (로컬 전용, git 미추적)
- 경로: `services/facing/data/facing.db`
- 페르소나 해시: `SHA256(b'facing_default_salt' + seed.encode())`
- SECRET_KEY 미설정 시 기본 솔트 = `facing_default_salt`
- **실제 `.env`에 SECRET_KEY 설정 시** 해시 결과 달라짐 → 재시드 필요

### 엔진 점수 스케일
- 백엔드 응답: 1.0~6.0 범위
- 프론트 변환: `((s-1.0)/5.0*100).round().clamp(0,100)` (`lib/core/scoring.dart`)
- 페르소나 더미: Scaled≈10%, RX≈46%, RX+≈66%, Elite≈84%, Games≈96%

### 더미 데이터 현황
- `lib/widgets/gym_info_card.dart`: gym_id 2,3 하드코딩 (TODO 표시됨)
- `lib/features/_debug/persona_debug_data.dart`: 10명 체형·벤치마크

## 파일 경로 (이번 세션 수정)

| 역할 | 경로 |
|---|---|
| 체육관 정보 카드 (공유) | `lib/widgets/gym_info_card.dart` ← 신규 |
| NOTICE 탭 | `lib/features/inbox/inbox_screen.dart` |
| 공지 화면 | `lib/features/announcements/announcements_screen.dart` |
| 페르소나 더미 데이터 | `lib/features/_debug/persona_debug_data.dart` |
| 페르소나 스위처 | `lib/features/_debug/persona_switcher_screen.dart` |

## 다음 세션 권장 첫 프롬프트
`/resume`
