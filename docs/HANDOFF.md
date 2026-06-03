# HANDOFF - 2026-06-03 14:24

## 완료 (전부 origin/master 에 push 됨)
- [x] 재활 감별 전체 플로우 구현 — 질문→자가테스트→원인+6단계 루트 / danger 분기.
      `lib/features/rehab/{rehab_models,rehab_flow_screen,rehab_screen,rehab_guide_card}.dart`
      데이터: `assets/data/rehab/*.json` (rahap1 흡수본). 에뮬 전 노드 검증 완료.
- [x] Notice→Attend 메시징 이동 — 공지·쪽지·대화목록·작성을 Attend 캘린더 밑으로.
      Notice 탭은 재활 가이드 카드만 남김 (사용자 결정 2026-06-03).
      `MessagingFeed`(임베드 위젯) = `lib/features/inbox/inbox_screen.dart`,
      `lib/features/attendance/attendance_screen.dart` 에 배치.
- [x] Attend·Notice 둘 다 중첩 Navigator — 탭 내부 화면(재활·채팅)서 하단 탭 유지.
      미읽음 dot·markSeen·벨/더보기 라우팅을 Notice(3)→Attend(2)로 이동.
      `lib/features/shell/main_shell.dart`, `lib/widgets/inbox_bell.dart`,
      `lib/features/home/home_screen.dart`. MainShell `resizeToAvoidBottomInset:false`.
- [x] /dead 데드코드 — `lib/core/athletes.dart`(미연결 86줄) 삭제, master 머지+push.
      `dart analyze` 0건. 정리 후 cleanup·overnight 브랜치 삭제 → 로컬·원격 master 만 남음.
- [x] 자동저장 훅 auto-push 차단 — `~/.claude/hooks/autopush-dev.sh` 에 `.nopush` 가드
      추가(커밋 유지, push 만 스킵). `C:/dev/apps/facing-app/.nopush` 마커 생성.
      다른 dev 레포는 auto-push 그대로.

## 진행중
- (없음 — 이번 세션 작업 단위 모두 종료)

## 대기 / 미검증
- [ ] Attend 메시징 **코치·사장 화면** 미검증 — 회원(김도윤)으로만 확인. 그룹·새쪽지
      버튼 + 회원별 대화목록 레이아웃 실제로 봐야 함.
- [ ] 채팅 **소프트 키보드** 픽셀 미검증 — 에뮬 하드웨어 키보드라 패널 안 뜸.
      실기 폰에서 타이핑 시 입력칸이 키보드 위로 깔끔히 올라오는지 확인 필요
      (구조상 `resizeToAvoidBottomInset:false` 로 처리, 비키보드 상태는 OK).
- [ ] report-only 데드 메서드 11개 — 대부분 repository/API 표면. 특히 **인바이트 코드
      기능**(`getInviteCode`/`regenerateInviteCode`/`joinByCode` in inbox_repository)이
      repository엔 있는데 UI 미연결. 살릴지(연결) / 둘지 결정 대기.
- [ ] Notice 탭이 재활 카드 하나만 있어 휑함 — 채울지 여부.

## 결정사항 / 주의
- 🚫 **배포금지** 유지 — 사용자가 "push/배포/출시" 명시 전엔 push 금지. 이제 `.nopush`
      로 자동저장 훅도 막힘. (이번 세션 push 는 사용자가 명시 승인해서 진행한 것)
- rahap1(`Rimseorim/rahap1`)은 **정보 원천**. `additional/`=단방향 흡수 사본(.git 없음).
      우리 push 는 origin(`minjunbyeon-netizen/app-facing`)으로만. 지침: `docs/ADDITIONAL_SOURCE_GUIDE.md`
- 재활 데이터 SSOT = `assets/data/rehab/`. rahap1 갱신 시 덮어쓰고 우리 코드로 재구현.
- 매 응답 PushNotification 발사 룰(프로젝트 Rule 1) 유지.

## 다음 세션 권장 첫 프롬프트
`/resume`
