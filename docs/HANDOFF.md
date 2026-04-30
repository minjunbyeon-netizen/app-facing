# HANDOFF — 2026-04-30 21:21

## 컨텍스트

v1.20 패치 세션. 전수조사(더미 데이터 맵핑) + 5기능 API 체크 + SECRET_KEY BLOCKER 수정.

## 완료 (누적 — 이전 세션 포함)

- [x] **WOD 탭 Pacing 버튼 제거** — `lib/features/gym/box_wod_screen.dart`
- [x] **6카테고리 벤치마크 레퍼런스 시트** (남/녀 탭 + CONTEXT/REFERENCES 섹션)
  - `lib/core/benchmark_data.dart` + `lib/features/home/benchmark_sheet.dart`
- [x] **슈퍼관리자 시드 계정** — `services/facing/` 백엔드 (`a50e3fa`)
- [x] **Notice 상단 박스 정보 카드** — `lib/features/announcements/announcements_screen.dart`
  - `_GymInfoCard` gym.id % 4 결정론 매핑 → 계정별 다른 코치/시간/모토 표시 (`3d7035a`)
- [x] **페르소나 전환 시 AuthState.displayName 즉시 반영** — `lib/features/_debug/persona_switcher_screen.dart` (`80a601d`)
  - `DeviceIdService.overrideForDebug` 후 `AuthState.signIn('demo', displayName: p.displayName)` 추가
- [x] **가상데이터 텍스트 4곳 정리** (`80a601d`)
  - `coach_dashboard_screen.dart` — CoachNote 3곳 "가상데이터" 제거
  - `box_leaderboard_screen.dart` — "가상 데이터. 더미 멤버 포함" → "익명 해시 기반 랭킹"
  - `goals_screen.dart` — "가상. 목표·진행률 ... Phase 2" → "목표·진행률은 이 기기에 저장됩니다."
- [x] **SECRET_KEY 불일치 BLOCKER 수정** — `services/facing/.env`
  - gym owner_hash가 `facing_default_salt`로 시딩되었으나 서버는 전역 key 사용 → FORBIDDEN
  - `.env`에 `SECRET_KEY=358a435d7e2a501944df4c73d0cbce1e7244bcfe` 명시 + `seed_personas.py` 재실행
- [x] **5기능 전체 API 검증 완료** (2026-04-30)
  - 체육관등록 POST/GET /api/v1/gyms ✅
  - 업적 GET /api/v1/achievements + POST /check ✅
  - 엔진수준(프로필) GET/POST /api/v1/profile/info + /grade ✅
  - 쪽지기능 inbox→outbox→mark_read 엔드투엔드 ✅

## 진행중
없음.

## 대기 (다음 세션 후보)

- [ ] **갤럭시 실기 QA** — M/F 토글 + REFERENCES 스크롤 실기 검증 권장
- [ ] **테스트 DB 정리** — gym 2/3에 더미 멤버(seed_dummy_coaching)와 persona 멤버 혼재
  - dummy 멤버(`60fb1e88...`, `7fc92162...` 등)는 default_salt 해시 → 앱에서 접근 불가
  - 정리 방법: gym_members WHERE status=approved AND device_hash NOT IN (persona hashes) DELETE
- [ ] **새 mascot 자산 추가** (사용자 제공 대기)
- [ ] **Phase 4 — Barlow Condensed 영문 헤딩** (옵션)

## 주요 결정사항 / 주의

- **SECRET_KEY**: `services/facing/.env`에 명시됨 (git 제외). 재시드·재배포 시 동일 키 사용 필수
- **hash_device_id** = `SHA256(SECRET_KEY + device_id)` — salt는 env에서 런타임에 읽음
- **더미 멤버 혼재**: gym 2/3에 `facing_default_salt`로 해시된 레거시 멤버 존재. 코치 outbox는 persona hash로 보내야 함
- **벤치마크 데이터 SSOT** = `services/facing/engine/grading.py` F-constants
- **슈퍼관리자 조건부 시드**: `APP_TEST_ADMIN_ID` 없으면 스킵 — Railway 프로덕션 안전

## 파일 경로

| 역할 | 경로 |
|---|---|
| 공지 화면 + GymInfoCard | `lib/features/announcements/announcements_screen.dart` |
| 페르소나 스위처 | `lib/features/_debug/persona_switcher_screen.dart` |
| 코치 대시보드 | `lib/features/gym/coach_dashboard_screen.dart` |
| 리더보드 | `lib/features/leaderboard/box_leaderboard_screen.dart` |
| 목표 화면 | `lib/features/goals/goals_screen.dart` |
| 쪽지 repository | `lib/features/inbox/inbox_repository.dart` |
| 쪽지 백엔드 | `services/facing/api/coach_note.py` |
| 백엔드 env (SECRET_KEY) | `services/facing/.env` ← git 제외 |
| 페르소나 시드 | `services/facing/data/seed_personas.py` |

## 최근 커밋 (app-facing)

- `80a601d fix: 페르소나 전환 시 AuthState.displayName 갱신 + 가상데이터 텍스트 정리`
- `3d7035a fix: GymInfoCard gym.id 기반 더미 데이터 맵핑 (계정별 분리)`
- `edba4d3 fix(announcements): GymInfoCard gym null 무관 항상 표시`

## 다음 세션 권장 첫 프롬프트

```
/resume
```
