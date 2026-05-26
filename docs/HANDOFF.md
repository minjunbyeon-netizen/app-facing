# HANDOFF - 2026-05-26 11:32

## 완료 (이 세션, /resume 이어받기)

### TASK D 후속 — 수업 안내·이벤트·폰 회원 연동
- [x] 사이드바·페이지 "수업 템플릿" → "수업 안내" rename
- [x] `ClassTemplate.kind` 컬럼 추가 (regular/event)
- [x] "3수업 역도 세미나" event 템플릿 시드 (gym_id=2)
- [x] admin /class-templates 페이지: 종류(정규/이벤트) 배지·드롭다운·설명 placeholder 친절화
- [x] 회원 폰 GET `/api/v1/member/gyms/<gid>/class-templates` 추가
- [x] daily_plan API 응답에 template_name/kind/description inline join
- [x] 폰 `wod_today_screen.dart`: 카드에 종류 배지 + 이벤트면 강조
- [x] admin "오늘 WOD 배치" 표 race condition 버그 fix (await load() → await loadPlans())

### TASK D 후속 — WOD/Leaderboard
- [x] admin 전용 wod-posts GET endpoint 신규 (`/api/v1/admin/gyms/<gid>/wod-posts`)
- [x] /wod 페이지 "오늘 WOD" 탭에 fetch + 카드 UI (AMRAP·For Time 배지)
- [x] wod_session + wod_score 시드 (Fran, 회원 10명, rx_plus/rx/scaled 분배, 상위 3 PR)
- [x] admin 전용 leaderboard endpoint (`/api/v1/admin/gyms/<gid>/leaderboard?scale=`)
- [x] /wod Leaderboard 3 탭 (Elite/RXD/Scaled) 실 데이터 표 UI 완성

### 데이터 정합성 cleanup
- [x] 회원 (미입력) 3건 정리 → 오민주·서지훈·백소영 한국 이름·생년·전화 부여
- [x] 김철수 생년 보강
- [x] 코치 영문 더미 (Phase4 Coach, Kim Minsu) → 박지윤 코치·김민수 코치
- [x] 코치 시급 4명 부여 (한지민 35000·박지윤 30000·김민수 32000·박지훈 35000)
- [x] 계약서 10건 "테스트회원" → 정하은·서지훈·박서연·윤지원·오민주·강민재·임채원·이재훈·한도현 분배
- [x] 락커 12/34 점유 시드 (회원 random sample, 35.3% 점유율)
- [x] 오늘 출석 8명 시드 (6/7/8/9 + 18/19/20/21시 수업 시간대)

### 페이지 점검 (console 0 검증)
- [x] /dashboard /members /wod /coaches /calendar /contracts /classes /checkin /stats /lockers /class-templates

## 진행중
(없음 — 사용자가 /loop 종료 후 /handoff)

## 대기 (다음 세션 작업 후보)
- [ ] /wod Benchmark 탭 (Girls/Heroes/Open/Korea Custom 시드 + 모델 필요)
- [ ] /wod 동작 라이브러리 탭 (백엔드 endpoint 추가 후 활성)
- [ ] facing-admin `.err.log`/`.run.log`/`__pycache__/` .gitignore 추가
- [ ] 코치 시급 input field 인라인 편집 동작 검증 (PATCH 호출)
- [ ] 폰 실기 APK 빌드 + APK 설치 (집 도착 후) — wod_today_screen 신규 위젯 검증

## 결정사항 / 주의
- ClassTemplate.kind: `'regular'` (정규 수업) vs `'event'` (세미나·특별). UI 에선 정규/이벤트 배지로만 노출
- daily_plan API: template_name/template_kind/template_description inline join 으로 폰 호출 1회 완성
- admin endpoint 패턴: `_require_device` 인증 endpoint 는 별도 `/api/v1/admin/...` 경로로 boss session 통과 가능한 wrapper 추가
- wod_score scale_type CHECK 제약: `rx`/`scaled`/`rx_plus` 만 (elite 가 아니라 rx_plus)
- wod_score score_unit CHECK 제약: `time_sec`/`reps`/`rounds_plus_reps`/`load_kg` 만
- gym_lockers PK: (gym_id, locker_no) composite, locker_no 는 "A-01" 문자열 (정수 아님)
- 좀비 backend 사고 2회 발생 — 매 사이클 첫 줄 `BACK=$h.StatusCode ADMIN=$a.StatusCode` 박는 습관 정착 필요
- 한글 cell width 사용자 terminal 에서 narrow 로 계산되어 점선 박스 안 긴 한글이 중첩 표시됨 → 박스 안 본문 짧게 + 들여쓰기 줄이기 권장

## 다음 세션 권장 첫 프롬프트
`/resume`
