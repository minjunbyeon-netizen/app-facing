# Overnight Brief — 2026-05-25

## 목표

`docs/PHASE5_PLAN.md` 의 Phase 0~6 전부 끝까지 자율 진행.
- Phase 0: v1.17 staff SSE 알림 실 시연 마무리 (이미 인프라 다 구축, install·로그인만 남음)
- Phase 1~6: 사장 운영 강화 (설정·회원·운영·자동화·수업·홈) 30+ 항목 완료

## 프로젝트 경로

- 메인: `C:\dev\apps\facing-app` (Flutter)
- 백엔드: `C:\dev\services\facing` (Flask)
- 둘 다 같이 건드림 (백엔드 API·DB 추가 + 프론트 화면 신설)

## 기술 스택 (자동 감지)

- Flutter 3.x (stable) + Dart, Provider, dio, shared_preferences, flutter_secure_storage, flutter_local_notifications, flutter_foreground_task
- 백엔드 Flask + SQLAlchemy + SQLite (facing.db), bcrypt, apscheduler
- 폰트 Pretendard Variable, 다크 단일 테마 FacingTokens v1.15
- 카피 Voice & Tone V1~V11 (영문 단독 라벨·한글 캡션 수직 스택)

## 성공 기준 (테스트 가능한 형태)

- [ ] **A. PHASE5_PLAN.md 의 모든 [ ] 체크박스 → [x] 완료** (Phase 0 + 1~6 합 30+ 항목)
- [ ] **B. `flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.100:5060` 성공** + `python app.py` 백엔드 부팅 시 health 200 응답
- [ ] **C. 사장 폰 로그인 → 신규 회원권 추가(자동 금액) → 자동 계약서 발급 → 만료 D-7 빨간 표시 → 알림바 수신** 핵심 흐름 5단계 로컬 검증 가능 (실 시연 없이 logcat·SQL·UI 캡쳐로 확인)

## 작업 목록

> Phase 단위로 묶음. 각 Phase 안 sub-task 는 PHASE5_PLAN.md 참조.
> 사용자 명시 의존성: Phase 1 (마스터 데이터) → Phase 2 (회원) → Phase 3 (운영) → Phase 4 (자동화) → Phase 5 (수업) → Phase 6 (홈) 순서.

1. **Phase 0 — 알림 시연 잔여**
   - 설명: APK 폰 install 완료 상태에서 사장 로그인 + 가짜 가입 신청 트리거로 staff SSE 알림 흐름 logcat 검증. 폰 실 조작 어려우면 logcat·백엔드 access log 로 흐름 검증만 시뮬.
   - 타입: sequential
   - 크기: small
   - depends_on: []

2. **Phase 1 — 설정 시스템 기반**
   - 설명: `services/facing/models/membership_plan.py` 신설(gym_id·duration_days·price·is_active 컬럼), `api/admin.py` 에 `/api/v1/admin/gyms/<gym_id>/plans` CRUD endpoint, `apps/facing-app/lib/features/boss/settings_screen.dart` UI. 포인트 설정 + 알림 설정도 같은 화면에 탭. 라우트 `/admin/settings`. Phase 1-1·1-2·1-3·1-4 항목 (PHASE5_PLAN.md).
   - 타입: sequential (다른 Phase 가 의존하는 마스터 데이터)
   - 크기: large
   - depends_on: [1]

3. **Phase 2 — 회원 화면 핵심 강화**
   - 설명: 사장 폰의 `boss_dashboard_screen.dart` 회원 리스트와 회원 상세 강화. D-7 빨간 강조·이전 회원권 이력·수강이력 탭 전환·포인트 잔액·메모 이름 옆 배치·기간 정지. 백엔드 API 응답 필드 확장 + Flutter UI 재배치. Phase 2-1~2-6.
   - 타입: sequential
   - 크기: large
   - depends_on: [2]

4. **Phase 3 — 운영자 도구**
   - 설명: 시급정산 4대보험 체크리스트 (`api/admin.py` payroll endpoint 확장 + UI 폼), 이탈위험+D-7 회원관리 별도 탭(churn_risk 활용), 락카 이름 자동완성(LIKE 또는 fuzzy) + 회원권 기간 자동 매칭 + 자동 연장 트리거. Phase 3-1~3-5.
   - 타입: sequential
   - 크기: large
   - depends_on: [3]

5. **Phase 4 — 자동화 흐름**
   - 설명: 회원 자동 가입(어플→로그인→박스선택→자동승인 옵션), 첫 회원권 결제 직후 ContractTemplate 자동 화면 전환, 회원권 추가 시 Phase 1 설정 기반 자동 금액 표시 드롭다운. Phase 4-1~4-3.
   - 타입: sequential
   - 크기: medium
   - depends_on: [4]

6. **Phase 5 — 수업·커뮤니티**
   - 설명: 메뉴 rename "기타"→"수업", 리더보드 Elite/RXD/Scaled 3 탭, 공지사항 CRUD + Phase 1 자동알림, 일정 달력, 클래스 수정 기능, 담당코치 변경 버그 수정. Phase 5-1~5-6.
   - 타입: sequential
   - 크기: large
   - depends_on: [5]

7. **Phase 6 — 홈 대시보드 + 청소**
   - 설명: 사장 폰 홈에 오늘 예약인원 + 이번 달 매출 위젯 (백엔드 agg query 신설), "오늘 처리할 일" 페이지 삭제. Phase 6-1~6-2.
   - 타입: sequential
   - 크기: small
   - depends_on: [6]

8. **마지막 — 회귀 검증 + 보고**
   - 설명: 모든 Phase 끝난 뒤 `flutter analyze` + `flutter build apk --release` + 백엔드 health 200 검증. Phase 별 commit 단위 정리. HANDOFF.md 갱신 + 미해결 항목 정리.
   - 타입: sequential
   - 크기: small
   - depends_on: [7]

## 금지사항

- main 브랜치 force push 금지
- **`git push` 원격 푸시 금지** (apps/facing-app · services/facing 둘 다, "배포해" 명시 전까지 commit 만)
- Railway·Vercel·Fly 등 PaaS 배포 명령 금지
- `gh pr create`·`gh pr merge` 금지
- 프로덕션 DB 마이그레이션 명령 금지 (마이그레이션 파일 작성은 OK)
- Google Play·App Store 업로드 금지
- 외부 메시지(Slack·메일·카톡 발송) 금지
- OpenAI·Gemini 등 비 Anthropic LLM 신규 도입 금지
- 시크릿 하드코딩 금지 (admin/1234 데모 시드는 룰상 예외)
- `~/.claude/CLAUDE.md`·`rules/**` 무단 수정 금지
- 디자인 미적 차단 (`rules/design-block.md` 의 16 항목 — 그라디언트·다중 box-shadow·hex 직접·이모지·Pretendard 외 폰트·pill·letter-spacing·spacing/radius 토큰)
- CrossFit 금지 용어 (운동·헬스·다이어트·웰니스 등) UI 출력 금지
- "오늘 처리할 일" 페이지는 삭제 (Phase 6 작업), 새 기능 추가 안 함
- 페이싱 계산 로직을 Flutter 앱에 구현 금지 (백엔드 `services/facing/engine/` 책임)

## 범위 밖 (이번 오버나이트 제외)

- 배포 작업 일체 (커밋만 — push 는 사용자 "배포해" 명시 후)
- 결제 외부 시스템 실호출 (Toss·카카오페이 sandbox 만)
- 카톡 알림톡 실발송 (NHN Toast 등)
- iOS 빌드 (Phase 5 한정 Android-only)
- v1.18 Foreground Service (PHASE5 다음 sprint)

## 메타

generated: 2026-05-25T23:03:00+09:00
estimated_tasks: 8 (Phase 0 + 6 Phase + 회귀 검증)
parallelizable_count: 0 (의존성 사슬 sequential)
estimated_minutes: 약 7~9 시간 (Phase 1·2·3·5 가 large, Phase 0·6·검증이 small/medium)

source_plan: `docs/PHASE5_PLAN.md`
handoff: `docs/HANDOFF.md`
architecture_brief: `docs/ARCHITECTURE_BRIEF.md`
