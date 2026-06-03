# HANDOFF - 2026-06-03 15:53

## 완료 (apps/facing-app — origin/master push 됨)
- [x] 재활 감별 전체 플로우 — 질문→테스트→원인+6단계 루트 / danger 분기.
      `lib/features/rehab/*`, 데이터 `assets/data/rehab/*.json`(rahap1 흡수본). 에뮬 검증.
- [x] Notice→Attend 메시징 이동 — 공지·쪽지·대화를 Attend 캘린더 밑(`MessagingFeed`)으로.
      Notice 탭은 재활 가이드만 유지. dot·markSeen·벨 라우팅 Notice(3)→Attend(2).
      `lib/features/{inbox/inbox_screen,attendance/attendance_screen,shell/main_shell}.dart` 등.
- [x] /dead — `lib/core/athletes.dart` 삭제. cleanup·overnight 브랜치 정리.
- [x] 자동저장 훅 `~/.claude/hooks/autopush-dev.sh` 에 `.nopush` 가드(커밋 유지·push만 차단)
      추가 + facing-app/service-facing/web-facing-admin 루트에 `.nopush` 생성.

## 완료 (web/facing-admin + services/facing — origin/master 머지·배포까지)
- [x] PC 부적합 전수조사 — 폰 전용 요소는 care.html `tel:` "전화" 버튼뿐. 나머지(QR·카톡·
      전화번호 라벨)는 PC 정상. mobile 어투·뷰포트도 깨끗.
- [x] care.html "전화" tel: 버튼 6개 제거 + 전화번호 17px 크게 노출.
- [x] **이탈예측점수(churn risk 100점) 기능 완전 제거** (사용자 "백엔드까지" 결정):
      - 백엔드: `services/facing/services/churn_risk.py`·`churn_risk_scheduler.py` 삭제,
        admin.py(배치·필드·단건 API)·billing.py(결제실패 hook)·expiry_scheduler.py(cron) 제거.
      - 프론트: care 이탈위험 섹션 / members 배지·필터 / member_detail 이탈위험 탭·loadRisk /
        _layout 실시간 churn 토스트 / onboarding 카드 제거. "결제 동의 갱신" 버튼은 결제탭으로 이동.
      - **cohort.py compute_churn_risk(마케팅 대시보드용, 별개)는 유지.**
- [x] 두 레포 master fast-forward 머지 + push.
- [x] **railway 배포 둘 다 완료 + 프로덕션 실물 검증**:
      백엔드 churn-risk 엔드포인트 404 / health 200. 관리자 웹 케어 페이지서 이탈위험·전화버튼
      사라진 것 boss_seongsu 로그인해 직접 확인.

## 진행중
- (없음)

## 대기 / 미검증
- [ ] Attend 메시징 **코치·사장 화면** 미검증 — 회원(김도윤)으로만 봄.
- [ ] 채팅 **소프트 키보드** 픽셀 미검증 — 에뮬 하드키보드라 안 뜸. 실기 확인 필요.
      (구조상 main_shell `resizeToAvoidBottomInset:false` 로 처리, 비키보드 상태는 OK)
- [ ] facing-app report-only 데드 메서드 11개(repository/API 표면). 특히 **인바이트 코드 기능**
      (`getInviteCode`/`regenerateInviteCode`/`joinByCode`)이 repo엔 있는데 UI 미연결.
- [ ] Notice 탭이 재활 카드 하나라 휑함 — 채울지 여부.
- [ ] facing-admin/service-facing 모두 `overnight/2026-05-25` 브랜치에서 작업 후 master 머지함.
      (현재 두 레포 작업 브랜치는 overnight/2026-05-25, master=동일 상태)

## 결정사항 / 주의
- 🚫 **배포금지(facing-app)** 유지. 단, 이번 세션 push·배포는 모두 사용자 명시 승인으로 진행.
      `.nopush` 로 자동저장 훅 auto-push 차단됨 (3개 레포).
- rahap1=정보 원천, `additional/`=단방향 흡수 사본. 우리 push는 각자 origin으로만.
- 재활 데이터 SSOT=`assets/data/rehab/`. 외부 자료 SSOT=`services/facing/docs/refer/`.
- service-facing 배포=`railway up` 수동 (GitHub auto-deploy 없음). railway 프로젝트=service-facing,
  서비스 2개(service-facing=API / web-facing-admin=관리자 웹).
- 매 응답 PushNotification 발사(프로젝트 Rule 1) 유지.

## 다음 세션 권장 첫 프롬프트
`/resume`
