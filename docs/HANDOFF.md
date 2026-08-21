# HANDOFF - 2026-08-21 11:17

> 골든 전수 업데이트 세션 인계. 직전 인계장은 `docs/archive/HANDOFF-2026-08-21.md` (오버나이트+v1~v3).

## 완료
- [x] 홈 공지 아코디언 골든 2장 추가 (`member_02b_home_notice` 접힘 · `member_02c_home_notice_open` 펼침)
      — R7(홈 공지 소스 AnnouncementsState 교체) 시각 게이트. 총 **45 → 47장**
- [x] `test/golden/fakes.dart` 에 `memberAnnouncements()` 신설 (핀 1 + 일반 2, appClock 고정 상대일).
      **기본 memberWorld 는 공지 0건 유지** — 기존 45장 픽셀 불변 재생성으로 확인
- [x] `test/golden/screens_golden_test.dart` 'member: home notice accordion' 씬 추가 (world 주입 방식)
- [x] `tool/golden_gallery.py` SECTIONS 2건 등재 + `CLAUDE.md` 골든 수 45→47 동기화 (§0-B)
- [x] 회귀 게이트 `flutter test test/golden` 39 테스트 전부 그린
- [x] **playwright 로 갤러리 47장 전수 육안 검수 — 결함 0건** (사용자 지시 "1개1개 모두")
- [x] 로컬 커밋 2건: 인계장 archive 정리(a9d8e30) + 골든 추가(6fd0f0a). **push 안 함 (배포 금지 룰)**

## 진행중
- (없음)

## 대기
- [ ] **사용자 마지막 요청 "페이지 열어봐" 미수행** (컨텍스트 경고로 중단) — 갤러리 열기:
      `cd build && python -m http.server 8123 --bind 127.0.0.1` 후 playwright 로
      `http://127.0.0.1:8123/goldens_gallery.html` (file:// 는 차단됨)
- [ ] 검수 중 관찰 3건 — 수정 여부 사용자 결정 대기 (제1원칙: 보고만 한 상태):
      ① 코치 화면 헤더 "OWNER" 빨간 라벨 (3면 대전제 '역할은 코치 하나' 와 충돌 소지)
      ② 갤러리 설명문 member_16 "목표 — 빈 상태" ↔ 실제 캡처엔 값 있음 (설명문만 낡음)
      ③ 수업 등록 날짜 선택 다이얼로그 Material 기본 영문 (Select date·Cancel·OK)
- [ ] (이월) admin 인라인 스타일 부채 546건 / C10 클릭-수정 갭 재스윕 판단

## 결정사항 / 주의
- 공지 fake 는 `memberAnnouncements()` 를 해당 씬에서만 주입 — 기본 세계에 넣으면
  기존 골든 다수(종 배지·탭 배지)가 흔들림. 이 원칙 유지할 것
- 골든 시계 = `test/flutter_test_config.dart` `kTestClock` (2026-08-12 10:30 고정) —
  공지 날짜 라벨 08.08/08.11/08.10 은 여기서 파생 (드리프트 없음)
- member_03·member_04 는 육안상 비슷하나 해시 다름 (중복 아님 — 스크롤 오프셋 차)
- 로컬 관리자 접속 = http://127.0.0.1:8081 (localhost 는 308 리다이렉트, 직전 인계장 참조)
- 버전 롤백 기준은 v1/v2/v3 태그 (세 repo 공통, 직전 인계장 참조)

## 다음 세션 권장 첫 프롬프트
`/resume`
