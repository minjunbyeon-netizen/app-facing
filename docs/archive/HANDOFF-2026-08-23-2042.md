# HANDOFF - 2026-08-23 20:42

## 완료 (이 세션 — 전부 로컬 커밋만, push 안 함)
- [x] **'당일 공개' 잠금 폐지 (v3.15)** — 사용자 결정 "당일공개 폐지"
  - 서버 `future_locked` 2곳 삭제 (services/facing api/gym.py — locked = 회원권 만료만)
  - 앱 `LockedWodBanner` 미래 분기·'당일 공개.' 문구 삭제 (week_board.dart · wod_row.dart)
  - README §제거된 기능 대장 13 등재. 3면 grep 잔존 0건 (PC facing-admin 포함)
- [x] **기록 UX 1·2·3 (v3.15~16)** — 회원 기록 UX 4종 제안 중 1·2·3 승인분
  - UX 1: 결과 시트 기록 종류 칩 [시간/라운드/무게] (wod_result_sheet.dart `_RecordKind`)
  - UX 2: 서버 `score_hint` → 칩 기본값 자동 (판정 사전 = services/wod_compare.py 한 곳, 앱 판정 0)
  - UX 3: `movement_suggestions` → 동작 이름 후보 칩 (구조화 load 동작 + movement_library load_kg 축 매칭)
  - 서버 자기서술 판정 `result_kind_of` — 비교·표시 모두 "기록이 담은 값" 기준.
    종류 다른 이전 기록은 비교 제외 (int·tuple min/max TypeError 잠재결함도 함께 차단)
  - `my_result.movement` 동봉 → 재수정 프리필 (GymMyResult·GymWodPost 모델 확장)
- [x] **검증** — 앱 테스트 186건·골든 3장 갱신·서버 스텁 27케이스 전부 통과.
  에뮬 실물 왕복: 미래수업(8/24) 공개 확인 · 무게 칩+Back Squat/105/3 프리필 · 110 저장 →
  스낵바 "지난 기록보다 10kg 증가 — PR!" · DB weight_kg=110/is_pr=1 확인 · FRAN 시트
  시간 칩 자동 + THRUSTER 후보 칩 탭 → 이름 채움
- [x] SSOT 반영 — `services/facing/docs/SSOT/대차대조표.md` 부록 3 (8/23 변동분 행 단위 색인)

## 진행중 (다음 세션 첫 작업 — 사용자 "1" 승인됨)
- [ ] **결과 저장 직후 주간 보드 기록 배지 미갱신 수정** — 저장 후 배지가 옛 값(105KG×3)
  잔존, 새로고침 시 정상. 컨텍스트 99% 로 착수 직전 중단.
  - 중단 지점: `lib/features/gym/wod_row.dart` `_openResultSheet` —
    `showModalBottomSheet<bool>` 반환값(true=저장됨)을 안 받고 버림. await 후 true 면
    GymState 수업 목록 재조회 배선 (week_board 카드 배지·wod_row 배지 둘 다 GymState 원천)
  - 수정 후 골든 영향 없음 예상 (동작 변경만) — `flutter test` 로 확인

## 대기
- [ ] push/배포 — 전부 로컬 커밋 상태. 사용자 "배포해" 지시 시에만
  (앱 0e183ab·812b64c·7695b04 / 서버 c39bc3f·8d6d6d8·92a755c. services/facing 은 railway up 수동)
- [ ] UX 4 (시트 머리 그날 내용 3줄) — 시트가 이미 내용 4줄 표시 중이라 사실상 충족. 미논의 종결

## 결정사항 / 주의
- '당일 공개' 재도입 금지 — 폐지는 사용자 결정 (2026-08-23). 잠금 사유는 회원권 만료 하나
- PR 비교는 같은 종류 기록끼리만 — 종류 바꿔 재기록하면 "첫 기록" 취급될 수 있음 (의도된 동작)
- 덮어쓰기 재저장의 비교 대상은 그 이전 기록 (105→110 인데 "10kg 증가"가 정답 — 직전 별개 기록 100 기준)
- 에뮬 저장공간: `install -r` INSUFFICIENT_STORAGE 재현 — uninstall 후 install (기기 데이터 초기화 → member/1234 재로그인)
- ESC(keyevent 111)는 Flutter 바텀시트를 닫아버림 — 키보드 닫기는 keyevent 4(BACK)
- 로컬 백엔드(python app.py, :5060) 백그라운드 실행 중이었음 — 새 세션에선 재기동 필요할 수 있음
- 에뮬 앱: 재설치본 member/1234 로그인 상태. 실 체육관(gym_id=2) 프로드 오염 금지 — 쓰기는 로컬 demo(gym 1)만

## 다음 세션 권장 첫 프롬프트
`/resume` → 보드 기록 배지 즉시 갱신 수정(진행중 항목)부터 바로 착수
