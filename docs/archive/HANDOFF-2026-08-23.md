# HANDOFF - 2026-08-23 18:12

## 완료 (이 세션 — 전부 배포·검증 끝)
- [x] **수업 시스템 개편** (3 repo 배포 완료)
  - 수업 안내 = 수업의 정본: '매주 시간표' 열 + 시간 추가/삭제 (반복 규칙 편집 창구 일원화, 수업 관리의 반복 스케줄 모달 삭제)
  - 규칙 저장 시 "첫 수업 M/D(요일) HH:MM" 안내 + 캘린더 자동 이동 (first_session_at — autoflush=False 라 flush 후 조회)
  - **그날 내용 정본 = (날짜 × 수업 종류) 게시물** — 스웻은 스웻끼리, 빌드는 빌드끼리 (사용자 확정. 날짜 통합 아님 — 중간에 잘못 넓혔다 되돌림). `_sync_wod_post` (services/facing/api/classes.py) write-through: 생성/수정 upsert · 마지막 타임까지 취소 시 삭제
  - PC 상세·수정·등록 모달 전부 그날 게시물 표시/프리필 (`_dayContentFor`, templates/classes.html)
  - 템플릿 소개문이 세션 '그날 내용' 칸에 복사되던 것 차단 + 오염 정리 마이그레이션
- [x] **기록→PR→1RM 보드 연동** (조인트 3종, services/facing 1a9438c · 앱 e3758b1)
  - GymWodResult.movement 컬럼 + movement_signature (strength 게시물과 같은 그룹 형식)
  - _score: weight_kg 있으면 타입 불문 무게 기준 / 1RM 보드 strength 한정 필터 해제
  - 앱 결과 시트 '무게 기록 (선택)' 섹션 (동작 이름+무게+reps)
  - 종단 검증: 100kg 첫 기록 → 105kg is_pr=True "5kg 증가 — PR!" → 보드 자동 갱신 → 리워드 'pr' 트리거 기존 배선
- [x] 목표·착용 칭호 서버 저장 (member_goals + worn_title) · 칭호 카탈로그 정리 (해금 불가 32종 삭제, 한글화, 26종) · 칭호 프로필 노출
- [x] PC 정리: 페이지 헤더 통일 · 인라인 17→8 · 카카오 토큰 · 픽토그램 팔레트 생성물화 · 약관 동기화 · 배치 기능 삭제
- [x] 앱 정리: 설정 아코디언 삭제 · 예외 원문 노출 4건 · 영문 라벨 11건 · 방침 문구 정정

## 진행중 (다음 세션 이어서)
- [ ] **회원 기록 UX 4종 제안 — 사용자 응답 대기가 중단 지점** (마지막 턴 제안, 통과 전)
  1. 결과 시트 기록 종류 칩 [시간/라운드/무게]
  2. 서버 힌트: 게시물 저장 시 내용에서 score_hint 추출 (For Time→시간 등, 판정 사전 서버 한 곳)
  3. 동작 이름 칩 제안 (movement_library 대조)
  4. 시트 머리에 그날 내용 3줄
  - 관련: lib/features/gym/wod_result_sheet.dart · services/facing/api/gym.py(결과 저장 ~1895) · services/wod_compare.py

## 대기
- [ ] '당일 공개' 정책 결정 — 미래 수업 내용은 회원에게 잠김 (LockedWodBanner). 코치가 미리 적는 새 흐름과 충돌 여부 사용자 결정 대기
- [ ] 에뮬레이터 실물: 결과 시트 무게 기록 → PR 스낵바 (백엔드 배포됨, 앱 debug 재빌드 필요)
- [ ] 실 체육관(gym_id=2) 프로드 오염 금지 — 쓰기 테스트는 로컬/데모(gym 1)만

## 결정사항 / 주의
- 내용 단위 = **(날짜 × 수업 종류)**. "같은 날은 전부 같다" 아님 — 재론 금지
- 반복 규칙 편집 = 수업 안내 한 곳 (§0-B). 수업 관리 = 달력·그날 내용·휴강·단발
- classes.html 인라인 <script> 는 배포 전 `node -e "new Function(...)"` 문법 검사 (개행 리터럴 사고 2회)
- 에뮬레이터 저장공간 부족 → install -r 조용히 실패 → 옛 빌드로 오판 주의 (uninstall 후 install)
- 로컬 회원 테스트 계정: member/1234 (비번은 이 세션에서 로컬 DB 만 재설정)
- heredoc 파이썬에 `\n` 리터럴 금지 — chr(10) 또는 Edit 도구

## 다음 세션 권장 첫 프롬프트
`/resume` → 회원 기록 UX 4종 제안(위 진행중)에 대한 사용자 통과 여부 확인부터
