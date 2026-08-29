# HANDOFF - 2026-08-30 00:22

> 주제: **D88 운동 데이터 연동 1~3단계 집행 + 사용자 지시 E2E(코치 운동 짜기 → 회원 예약 → 완료 → 포인트·업적) 진행 중.**
> 컨텍스트 99% 워치독으로 중단 직전 저장. 3 repo 커밋·푸시 완료. **배포는 아직 안 함** (E2E 마무리 뒤 `railway up` 예정).
> 새 절대규칙: 대전제 6-b 이음새 (3면 CLAUDE.md·브리프 §2-0 반영, 메모리 `feedback-single-seam-single-compute`).

## 한 줄 요약
서버 555 passed(자정 경계 flake 1건은 00:30 뒤 재실행) · PC 린트 baseline · 앱 무변경(로컬 APK 로 에뮬 검증 중).
**남은 것 = E2E 마지막 3스텝(폰 '저장' → 포인트·업적 확인 → 배포·에뮬 프로드 복구·문서 마감).**

## E2E 현재 상태 (로컬 서버 5060 · 관리자 웹 8081 · 둘 다 켜져 있음)
- 로컬 DB gym 1 (RESV POLICY GYM), admin/1234, 회원 member/1234 (device `member-phone-001`, 기기 해시를 서버 salt 로 바로잡음, 회원권 start_date 를 08-01 로 고침).
- 코치: 템플릿 AWAKE(id 1) · 수업 7 (**00:21 시작**, program AMRAP 캡10 · Thruster 10회 40kg · Row 250m) · 규칙 1 "Thruster 첫 완료" (wod_log · movement_id 50 Thruster · lifetime 1회 · 30P · 업적 First Thruster RULE_1).
- 회원(에뮬 emulator-5554, 로컬 APK 10.0.2.2:5060 설치됨, 시간대 GMT 라 표시 시각은 -9h): 수업 7 예약 확정. **완료 시트가 열려 있고 라운드 3 입력됨.** 시작 전 저장은 403 "수업 시작 후에 완료할 수 있습니다." 확인(게이트 OK). 수업이 00:21 에 시작했으니 지금 저장 가능.
- 기준값(저장 전): member_points 합 0 · user_achievements = RULE_2 만 · gym_wod_results 0 · gym_attendances 0.

## 다음 스텝 (순서대로)
1. 에뮬 `adb -s emulator-5554 shell input tap 540 2233` (저장) → 스크린샷 → 기대: 저장 성공, 폭죽/스낵.
2. DB 확인: gym_wod_results 1건(class_session_id=7) · member_points +30 (reason "규칙 달성 — Thruster 첫 완료") · user_achievements RULE_1 · gym_attendances source=self · 알림 쪽지(업적 해금). 앱 내 정보 포인트 30P · 홈/업적 First Thruster · 쪽지함 '활동' 칸.
3. `pytest tests/` 재실행(00:30 이후 전량 통과 확인) → 배포: `cd services/hyphen && railway up --detach`, `cd web/facing-admin && railway up --detach` → 헬스 확인 → 프로드 부팅 로그에서 D88 마이그레이션 멱등 확인.
4. 에뮬레이터를 프로드 APK(3025) 로 되돌리기 (`flutter build apk --release --dart-define=API_BASE_URL=https://service-facing-production.up.railway.app` 또는 GitHub Releases 3025 apk 재설치) — **반드시** (어제 교정 사항).
5. 문서 마감: 브리프 D88-2·3 항목에 E2E 결과 줄 추가 · 메모리 `project-movement-data-flow` 를 "1~3단계 집행" 으로 갱신 · SSOT INDEX 상단에 D88 주석 · GLOSSARY 는 이미 반영.
6. 잔여(다음 세션): 앱 카드 제목/머리줄 중복 접기 · 앱 `wodTypeLabel`/`displayLine` 라벨을 서버 `wod_type_label`·`unit_label` 로(6-b) · 회원 완료 입력의 동작별 값(2단계 앱 부분 — 지금은 시트의 동작별 난도만) · 히스토리 동작 검색(3단계 후반).

## 결정·주의
- 동작 사전 정본 = `movement_library`(60) — 브리프의 "구 movements 23" 은 정정. 표시 이름 = 영문 하나(`display_name=name_en`).
- 종류·단위·분류 선택지 = 서버 `GET /admin/program-meta` 한 곳. PC JS 에 표 없음.
- `_sync_wod_post(program=None 명시 + 메모 없음)` 은 템플릿 게시물도 지운다 (구조를 본 창구가 비운 것).
- 규칙 삭제 후 재생성 UNIQUE 500 은 선재 결함 — `create_rule` 카탈로그 upsert 로 수정됨.
- 갤S22 실폰은 이번 세션 미사용. 에뮬 TZ 가 GMT 라 폰 화면 시각이 9시간 어긋나 보임(표시만).

## 다음 세션 권장 첫 프롬프트
`/resume` → 위 다음 스텝 1 부터 (에뮬 시트가 닫혔으면 수업 탭 → 일 30 AWAKE 펼침 → 완료 표시 → 라운드 3 → 저장).
