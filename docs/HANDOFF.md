# HANDOFF — 2026-04-30

## 컨텍스트

v1.22 개편 이후 패치 세션 3회차 마무리. 논문 인용 UI + 슈퍼관리자 시드 완료.

## 완료 (누적 — 이전 세션 포함)

- [x] **WOD 탭 Pacing 버튼 제거** — `lib/features/gym/box_wod_screen.dart`
- [x] **Notice 탭 코치 쪽지 작성 경로 명확화** — `lib/features/inbox/inbox_screen.dart`
- [x] **6카테고리 벤치마크 레퍼런스 시트** (남성) — `lib/core/benchmark_data.dart` + `lib/features/home/benchmark_sheet.dart`
- [x] **퀵 페르소나 스위처** — `lib/features/mypage/mypage_screen.dart` (kDebugMode 전용)
- [x] **seed_personas 실행** — `services/facing/data/seed_personas.py`
- [x] **벤치마크 여성 M/F 탭** — `lib/core/benchmark_data.dart` + `lib/features/home/benchmark_sheet.dart`
- [x] **벤치마크 CONTEXT + REFERENCES 섹션** — 6카테고리 논문 인용 18개 (`78a0494`)
  - `BenchmarkRef` 클래스 (title/authors/source/year)
  - `CategoryBenchmark`에 `context` + `refs` 필드
  - `_SectionBox` + `_RefItem` UI — CONTEXT → REFERENCES → SOURCE 순
  - 에뮬레이터 실동작 확인 ✅
- [x] **슈퍼관리자 시드 계정** — `services/facing/` 백엔드 (`a50e3fa`)
  - `models/admin_user.py` 신규 (`AdminUser`: username/password_hash/role)
  - `models/base.py` `seed_superadmin()` + `admin_users` migrate
  - `app.py` 시작 시 `seed_superadmin()` 호출
  - `requirements.txt` bcrypt==4.2.1 추가
  - `.env` APP_TEST_ADMIN_ID=cheb2oy / APP_TEST_ADMIN_PASSWORD=Cheb!2oy#26
  - `.env.example` 키 이름만 (값 없음)
  - DB 확인: `$2b$12$...` bcrypt cost-12 해시 저장 ✅

## 진행중
없음.

## 대기 (다음 세션 후보)

- [ ] **Notice 상단 박스 정보 카드** — 박스 이름·위치·코치 프로필·수업시간·모토 표시 (가상 데이터)
  - `lib/features/inbox/inbox_screen.dart` 상단에 추가
  - 필요 시 `services/facing/` Gym 모델에서 데이터 가져오기
- [ ] **새 mascot 자산 추가** (사용자 제공 대기)
  - `assets/images/character/mascot_lv2~5.png`
- [ ] **갤럭시 실기 QA** — M/F 토글 + REFERENCES 스크롤 실기 검증 권장
- [ ] **Phase 4 — Barlow Condensed 영문 헤딩** (옵션)

## 주요 결정사항

- **벤치마크 데이터 SSOT** = `services/facing/engine/grading.py` F-constants
- **TextButton 사용 이유**: `DraggableScrollableSheet` 내부 GestureDetector 드래그 아레나 패배 → TextButton Material 레이어 우회
- **슈퍼관리자 조건부 시드**: `APP_TEST_ADMIN_ID` 없으면 스킵 — Railway 프로덕션 안전
- **REFERENCES 순서**: CONTEXT → REFERENCES → SOURCE

## 파일 경로

| 역할 | 경로 |
|---|---|
| 벤치마크 데이터 (M+F + refs) | `lib/core/benchmark_data.dart` |
| 벤치마크 시트 UI | `lib/features/home/benchmark_sheet.dart` |
| 슈퍼관리자 모델 | `services/facing/models/admin_user.py` |
| 슈퍼관리자 시드 | `services/facing/models/base.py → seed_superadmin()` |
| 백엔드 env | `services/facing/.env` |

## 최근 커밋

- `a50e3fa feat(admin): 슈퍼관리자 시드 계정 추가 (bcrypt 해싱, env 조건부)` — service-facing
- `78a0494 feat(benchmark): 6카테고리 논문 인용 + CONTEXT/REFERENCES 섹션 추가` — app-facing
- `c2f7460 chore(handoff): 세션 인계 직전 저장` — app-facing

## 다음 세션 권장 첫 프롬프트

```
/resume
```
