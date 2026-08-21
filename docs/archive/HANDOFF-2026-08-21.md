# HANDOFF - 2026-08-21 10:56

> 오버나이트(08-20 23:08 지시) + 오전 3라운드 + 버전 재시작(v1~v3) 세션 인계.
> 상세 작업 로그 = `docs/PLAN-overnight-0820.md` (라운드별 완료 로그 전부).

## 완료
- [x] 오버나이트 체크리스트 C1~C9 + 갭 스윕 9건 → **1v·2v** 태그·배포
- [x] 3라운드 사용자 10건 (R1~R10) 전부 — 락커 CSS·유료→활성 통일·쪽지 선발신·
      가입 사이드바 분리·30분 경계선·반복 스케줄(ClassScheduleRule+materialize)·
      공지 오염(auto_kind+홈 아코디언 소스 교체)·회원권 토글 방어·규칙 프리셋·
      인증 대기함 탭 → **3v**. 역순(R10→R1) playwright 검증 완료
- [x] 추가 지시 4건 — 수업 길이 개념(칩 duration 스팬+분 입력)·페이저 SSOT
      (.pager-btn — 일정달력은 죽은 .btn-ghost 참조였음)·업적 카테고리 통합·
      토글 스위치 전환 → **4v**
- [x] **버전 재시작 (사용자 지시): v1=4v 스냅샷(원본), v2, v3 — 세 repo 태그 정렬**
  - v2: 업적 category 서버 승격 (catalog.category, 시드 `_category()` 정본,
    RULE_* 는 규칙 카테고리) + 수업 칩 분 단위 비례 높이 (50분=83%)
  - v3: **관리자 localhost→127.0.0.1 308 리다이렉트** (Chrome ::1 선시도로
    요청당 ~310ms → 24-37ms, "페이지 2-4초" 실원인) + RULE_* category 백필
- [x] v3 Railway 배포 + 운영 헬스 200 (백엔드·관리자 둘 다)
- [x] 백엔드 pytest **163 passed 1 skipped** · flutter 전체 그린 · admin lint 0건
- [x] 앱 에뮬레이터 재빌드·설치 (구 com.netizen.facing 폐기 설치본 제거로 공간 확보)

## 진행중
- (없음 — 요청받은 작업 전부 종결)

## 대기
- [ ] 골든 재캡처 여부 판단: 앱 변경은 홈 공지 아코디언 소스 교체(R7)뿐 —
      기존 45장 그린이라 미갱신. 공지 fake 데이터를 넣어 아코디언 노출 골든을
      추가하려면 `test/golden/fakes.dart` + `screens_golden_test.dart`
- [ ] admin 인라인 스타일 부채 546건 (baseline 412 대비 누적 — lint 룰위반은 0)
- [ ] PLAN-overnight-0820.md C10(클릭-수정 갭 스윕) 체크박스만 미체크 —
      실질은 갭 스윕 9건으로 커버됨, 재스윕할지 판단만 남음

## 결정사항 / 주의
- **버전 태그 이원화**: 구 1v~4v(오버나이트) + 신 v1~v3(재시작, v1=4v 동일 커밋).
  사용자 롤백 기준은 **v1/v2/v3** (세 repo — services/facing·web/facing-admin·
  apps/facing-app 모두 같은 이름). `git checkout v{N}`
- **로컬 관리자 접속은 이제 http://127.0.0.1:8081** — localhost 는 308 리다이렉트됨
  (세션 쿠키가 호스트별이라 리다이렉트 직후 1회 재로그인 필요)
- 수업 30분 = "시작 시각 단위"이지 수업 길이가 아님 — 길이는 slotDuration 입력
  (템플릿 default_duration 자동). 그리드 셀·칩 전부 **명시 grid 좌표** — auto-placement
  혼용 금지 (섞으면 전체 밀림, classes.html 주석 참조)
- 업적 카테고리 정본 = `seeds/seed_achievements.py _category()` (§0-B).
  프론트 `catalogCategory(a)` 는 서버 category 우선, 코드 접두 휴리스틱은 폴백
- 반복 스케줄: materialize 는 조회 시 lazy, 오늘 이전 생성 금지·12주 상한·
  (rule_id,start_at) UNIQUE 멱등. PATCH/DELETE 는 예약·개별수정 슬롯 보존(kept_count)
- 리워드 승인 통지 = GymCoachNote `auto_kind="reward:action_log"` — 홈 '공지' 는
  AnnouncementsState(진짜 공지)만, 쪽지·알림은 종(MessagingScreen)
- services/facing `data/contracts/contract_1_draft_*.html` = 검증 중 생긴 런타임
  생성물 (untracked 유지 — 커밋 금지)
- 에뮬레이터 앱 재설치·삭제 주의: 디바이스 해시 기반 회원 행 — **hyphen 앱 데이터
  삭제 금지** (재설치 시 회원 세션 끊김)

## 다음 세션 권장 첫 프롬프트
`/resume`
