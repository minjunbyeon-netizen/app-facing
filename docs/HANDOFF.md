# HANDOFF — 2026-04-30

## 컨텍스트

v1.22 개편 이후 패치 세션 3회차. 논문 인용 + CONTEXT/REFERENCES 섹션 구현 완료.

## 완료 (누적 — 이전 세션 포함)

- [x] **WOD 탭 Pacing 버튼 제거** — `lib/features/gym/box_wod_screen.dart`
- [x] **Notice 탭 코치 쪽지 작성 경로 명확화** — `lib/features/inbox/inbox_screen.dart`
- [x] **6카테고리 벤치마크 레퍼런스 시트** (남성) — `lib/core/benchmark_data.dart` + `lib/features/home/benchmark_sheet.dart`
- [x] **퀵 페르소나 스위처** — `lib/features/mypage/mypage_screen.dart` (kDebugMode 전용)
- [x] **seed_personas 실행** — `services/facing/data/seed_personas.py`
- [x] **벤치마크 여성 M/F 탭** — `lib/core/benchmark_data.dart` + `lib/features/home/benchmark_sheet.dart`
- [x] **벤치마크 CONTEXT + REFERENCES 섹션** — 6카테고리 논문 인용 추가 (`78a0494`)
  - `BenchmarkRef` 클래스 (title/authors/source/year)
  - `CategoryBenchmark`에 `context` + `refs` 필드 추가
  - 6카테고리 실제 논문 인용 (Pirolo 2014, Tibana 2019, Daniels VDOT, ACE BF%, Mangine 2014 등 18개 레퍼런스)
  - `_SectionBox` + `_RefItem` UI 위젯 — CONTEXT(본문) / REFERENCES(번호 목록) / SOURCE(기존 박스) 순
  - 에뮬레이터 실동작 확인 ✅

## 진행중
없음.

## 대기 (다음 세션 후보)

- [ ] **새 mascot 자산 추가** (사용자 제공 대기)
  - `assets/images/character/mascot_lv2.png` (Lv 11-20)
  - `assets/images/character/mascot_lv3.png` (Lv 21-30)
  - `assets/images/character/mascot_lv4.png` (Lv 31-40)
  - `assets/images/character/mascot_lv5.png` (Lv 41+)
- [ ] **갤럭시 실기 QA** — 에뮬레이터만 확인, 실기 M/F 토글 + REFERENCES 스크롤 검증 권장
- [ ] **Phase 4 — Barlow Condensed 영문 헤딩** (옵션)

## 주요 결정사항

- **벤치마크 데이터 SSOT** = `services/facing/engine/grading.py` F-constants. 앱 하드코딩 = 렌더링 전용
- **TextButton 사용 이유**: `DraggableScrollableSheet` 내부에서 `GestureDetector.onTap`이 수직 드래그 아레나에서 패배. TextButton은 Material 레이어에서 처리되어 정상 작동
- **퀵 스위처는 kDebugMode 전용** — release APK 완전 숨김
- **seed_personas 재실행 주의**: boxes_created=0(이미 존재), profiles는 덮어씀
- **REFERENCES 순서**: CONTEXT → REFERENCES → SOURCE (맨 아래가 짧은 출처 요약)

## 파일 경로

| 역할 | 경로 |
|---|---|
| 벤치마크 데이터 (M+F + refs) | `lib/core/benchmark_data.dart` |
| 벤치마크 시트 UI (M/F 토글 + 논문) | `lib/features/home/benchmark_sheet.dart` |
| 홈 화면 (칩 진입점) | `lib/features/home/home_screen.dart` |
| 백엔드 seed | `services/facing/data/seed_personas.py` |
| 프로필 (퀵 스위처) | `lib/features/mypage/mypage_screen.dart` |

## 최근 커밋

- `78a0494 feat(benchmark): 6카테고리 논문 인용 + CONTEXT/REFERENCES 섹션 추가`
- `4c76196 fix(benchmark): GestureDetector→TextButton으로 M/F 터치 타겟 수정`
- `768d78e feat(benchmark): 여성 벤치마크 M/F 탭 추가 + seed_personas 실행 완료`

## 다음 세션 권장 첫 프롬프트

```
/resume
```
