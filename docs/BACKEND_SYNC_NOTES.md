# Backend Sync Notes — facing-app v1.1 ↔ services/facing/

> **작성**: 2026-04-28 /go 14
> **대상 repo**: `C:\dev\services\facing\` (별도 git repo)
> **상태**: facing-app v1.1 갱신 완료. 백엔드 동기화는 다음 트랙에서 진행.

facing-app 의 5 6-pager v1.1 갱신과 코드 변경에 따라 services/facing/ 측에서 함께 작업이 필요한 항목들을 한 곳에 모은다. 본 문서는 facing-app 세션 안에서 작성된 가이드이며, 실제 백엔드 변경은 별도 세션 (services/facing/ 디렉터리)에서 진행한다.

---

## 1. AchievementCatalog 50개 동기화 (P0)

### 현재 상태
- facing-app `lib/core/titles_catalog.dart`: 50 칭호 (Common 15 / Rare 20 / Epic 10 / Legendary 5).
- `test/titles_catalog_test.dart`: `expect(kPanelBTitles.length, 50)` + 분포 검증 회귀 통과.
- 백엔드: 직전 commit cfe0d38 "트랙 C — catalog 8 추가" 기준 미동기화 (≤ 28 추정).

### 작업
- `services/facing/models/achievement.py` 의 `ACHIEVEMENT_CATALOG` 상수 (또는 시드 데이터) 50 항목으로 확장.
- 백엔드 unlock 검증 endpoint (`POST /api/v1/achievement/check`) 응답이 50 코드 모두 인지하도록.
- 신규 22 코드 (PB_FIRST_WOD / PB_TEN_WODS / PB_PR_HUNTER / PB_DEADLIFT_DOUBLE / ... / PB_GAMES / PB_REGIONAL_CHAMP) 의 unlock condition 백엔드 SSOT 정합.

### 참고
- facing-app `TitleUnlockSignals` 43 필드 (§6 Achievement v1.1 §4-4 표 참조).
- 현재 12 종은 클라이언트 즉시 추론, 13 종은 백엔드 trigger 의존, 25 종은 self-report.

---

## 2. Inbox `/api/v1/gym/notes/{id}/complete` endpoint 검증 (P0)

### 현재 상태
- facing-app `lib/features/inbox/inbox_repository.dart`: `complete(noteId, {actual: List<ActualSet>})` 호출 → `POST /api/v1/gym/notes/{noteId}/complete` payload 발송.
- §5 Coach Assignments v1.1 §4-7 API 통합 표에 명시.

### 작업
- `services/facing/api/coach_note.py` 의 `/api/v1/gym/notes/{note_id}/complete` 라우트 존재 확인.
- payload 스키마: `{actual: [{set_index, actual_load, actual_reps, rpe, note}, ...]}`.
- response 스키마: `{ok, data: {status: "completed", actual_sets: [...]}}` (Envelope).
- `services/facing/models/coach_note.py` 의 `RecipientStatus.actual_sets` JSONB 컬럼 마이그레이션.

---

## 3. 거절 사유 코드값 정합 (`INJURY/CONDITION/TIME/SUBSTITUTE`) (P1)

### 현재 상태
- facing-app: §4 Coach Notes v1.1 + §5 Assignments v1.1 모두 영문 코드 4종 + free text.
- 백엔드: 현재 코드값 미확인. 한글 또는 다른 문자열일 가능성.

### 작업
- `services/facing/api/coach_note.py` `decline` 엔드포인트의 `reason` 필드 enum 검증.
- 4 코드 + free text 형식 허용.
- 마이그레이션: 기존 데이터에 `intensity` / `schedule` 등 다른 코드가 있으면 `TIME` 또는 `SUBSTITUTE` 로 매핑.

---

## 4. `device_push_tokens` 테이블 마이그레이션 (P0 — Phase 3 FCM)

### 현재 상태
- facing-app `docs/PHASE3_PUSH.md` 가이드 풀스펙 존재.
- 백엔드: 미구현.

### 작업
- 신규 테이블 `device_push_tokens(device_id, fcm_token, platform, created_at, updated_at)`.
- Alembic 마이그레이션 파일 신규 작성.
- `POST /api/v1/devices/push-token` endpoint 신설 (토큰 등록).
- `services/facing/services/fcm_sender.py` 신규 (코치 발송 시점에 멤버 device_push_token 조회 후 FCM 발송).

---

## 5. Open / QF / Games / Regional / Murph self-report 검증 endpoint (P2 — Phase 4)

### 현재 상태
- facing-app `TitleUnlockSignals` 의 `openRegistered` / `qfQualified` / `gamesQualified` / `regionalChampion` / `murphRxSec` 필드 — 현재 self-report 수용.
- 백엔드 검증 미구현.

### 작업
- `services/facing/api/achievement.py` 에 `POST /api/v1/achievement/open-register` / `qf-qualify` / `games-qualify` / `regional-champion` 4 endpoint 신설.
- CrossFit Open OAuth 또는 사용자 self-report + 코치 검증 두 경로 검토.
- `models/achievement.py` 의 verification 컬럼 (`verified_by`, `verified_at`) 추가.

---

## 6. Engine Score 표기 3 변수 분리 정합 (P1)

### 현재 상태
- facing-app §2 Pacing Intelligence v1.1: `overall_score` 0~6 (백엔드) / UI 0~100 / `overall_number` 1~6 (Tier).
- 백엔드 응답: 현재 `overall_score` (0~6) 만 반환. UI 0~100 변환은 클라이언트 책임.

### 작업
- 백엔드 응답 형식 그대로 유지 (변경 없음).
- 다만 docs (`services/facing/docs/refer/`) 에 표기 변환 가이드 추가:
  - `engine_score_ui = floor(overall_score / 6 × 100)`.
  - `overall_number = bucket(overall_score)` (1~6 정수).

---

## 7. ModeSelect 클라이언트 분기 ≠ 백엔드 권한 (P1 정보 공유)

### 변경 없음, 정보 동기화만
- facing-app v1.1: `app_mode` SharedPreferences 키 추가 (Coach/Member/Solo).
- 백엔드 `role` + `gym_status` 는 변경 없음.
- 클라이언트가 mode 임의 변경해도 백엔드 권한 escalation 없음 (예: Solo 사용자가 Coach 모드 → POST 게시 거절).

### 작업
- 변경 없음. 다만 백엔드 측 보안 회귀 테스트로 "role=app_user 가 게시 endpoint 호출 시 403" 케이스 명시 회귀.

---

## 우선순위 권장 순서

1. **§1 ~ §3 (P0)**: AchievementCatalog 50 / inbox complete / 거절 사유 — 클라이언트 v1.1 이미 발송 가정, 백엔드 미정합 시 런타임 에러.
2. **§4 (P0 — Phase 3)**: device_push_tokens — FCM 통합 의존성.
3. **§5 (P2 — Phase 4)**: self-report 검증 — Panel B 13 종 잠금 해소.
4. **§6 ~ §7 (P1)**: 정보 동기화 — 코드 변경 없음.

---

## 작업 시 주의

- DB 마이그레이션 + 코드 배포 동시 릴리즈 금지 (rules/common/deploy-safety.md).
- 마이그레이션 먼저 → 안정 확인 → 코드 배포.
- 모든 변경은 `services/facing/CLAUDE.md` 의 deploy 규칙 + Railway env vars 적용.

---

*facing-app 세션 안에서 작성된 가이드. 실제 백엔드 작업은 별도 세션 (cd C:/dev/services/facing) 에서 진행.*
