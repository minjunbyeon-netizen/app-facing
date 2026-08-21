# HANDOFF - 2026-08-21 18:27

> 실데이터 반영 + 코치 쪽지·로그아웃 + 마스코트 SSOT 배선 + 스낵바 71건 이관 세션.
> 직전 인계장 = `docs/archive/HANDOFF-2026-08-21-1419.md`.

## 완료

### 1. 실물 포스터 3종 → 프로드 반영 (gym_id=2)
- [x] 회원권 6종 오픈 할인가 (1개월 무제한 200,000 · 주3회 160,000 · 3개월 무제한
      504,000 · 주3회 432,000 · 수강권 10회 176,000 · 20회 320,000). 구 3종 비활성
- [x] 수업 4종 (BUILD·SWEAT·AWAKE·TEAM HYPHEN) — 프로그램 가이드 설명·색 반영
- [x] 반복 규칙 6개 (월~금 06:30 AWAKE / 10:00 SWEAT / 18:30 BUILD / 19:30 SWEAT /
      20:30 BUILD + 토 10:00 TEAM HYPHEN) → 4주치 자동 생성
- [x] 메모리 저장: `~/.claude/projects/C--dev-apps-facing-app/memory/project-real-gym-data.md`

### 2. 백엔드 결함 3건 (services/facing — 전부 배포 SUCCESS)
- [x] **KST 나이브에 astimezone 이중 변환** → Railway(UTC)서 +9h 왜곡. 코치 대시보드
      오늘 수업(06:30→15:30)·출석 날짜/시각·예약 라벨 6곳. `_kst_wall()` 가드 (admin.py)
- [x] **PC 쪽지 폰 페어링 게이트 제거** — coach role 미페어링이면 쪽지 통째 차단됐고,
      페어링해도 회원 답장(owner_hash)과 편지함이 갈라짐 → 전 역할 gym.owner_hash 통일
- [x] **폰 쪽 편지함도 공용 해시로** — `_inbox_hash()` 로 발신·inbox·outbox·messages·
      threads·상세·읽음 8곳 치환 (coach_note.py) + 스레드 이름 GymMemberProfile 폴백

### 3. admin 웹 (web/facing-admin — 배포 SUCCESS)
- [x] 금액 입력 천 단위 콤마 전면 (결제 4칸·분할행·회원권 발급/연장/정정·회원
      추가/수정·계약) + 파싱 19곳 교체. 환불 prompt `parseInt('150,000')=150` 함정도 수정
- [x] 포인트 규칙 모달 — "조건 값(선택)" → 결제 트리거 전용 "얼마당 적립할까요?"
      + "→ 출석 1회당 100P 적립" 실시간 미리보기 + 표 열 '적립 기준'
- [x] 업적 설정 레이아웃 (P 단위 줄바꿈 밀림 nowrap · 픽토그램 정렬 · 규칙 0건 빈상태)
- [x] 쪽지 스레드 이름 역참조 (`_nameByHash`)

### 4. 앱 (apps/facing-app — v3.4·v3.5, push 완료 / 배포는 수동 APK)
- [x] **코치 셸 3탭** — 예약 현황·수업·**쪽지**(MessagingScreen 임베드). 종 진입도 유지
- [x] 코치 설정 AppBar 에 '로그아웃' 글자 버튼 (대시보드 아이콘과 동작 동일)
- [x] **마스코트 SSOT 신설** `lib/widgets/mascot.dart` — 표정 3종
      (happy·sad·neutral)만 두고 전 화면이 돌려 쓴다. 경로 문자열은 이 파일 밖 0건(검증)
- [x] 캐릭터 전용 폴더 `assets/character/` + README(파일명↔자리 표·투명PNG·32px 조건)
- [x] **스낵바 71건 전량 HkSnack 이관** — 실패 51 → error/fail(sad) · 완료 12 →
      show/info(happy) · 안내 6 → neutral. 남은 raw 는 업적 해금 커스텀 2건(의도적)
- [x] 죽은 에셋 삭제 (mascot.png · hero_splash.jpg · hero_grade.jpg — 참조 0건)
- [x] CLAUDE.md 디자인 원칙 "사진/일러스트 없음" → "사진 없음" + 캐릭터 예외 조항
      (사용자 승인 2026-08-21). 골든 8장 갱신 · analyze 0 · 170 tests pass

### 5. 기기·기타
- [x] 갤S22 릴리즈 APK 설치·기동 확인 (프로드 URL 주입). 중복 앱 3개 삭제 —
      구 HYPHEN(com.netizen.facing.facing_app) · 구 공수체크 TWA(app.workcheck.twa) ·
      공수체크 네이티브(com.gongsucheck.workcheck_app)
- [x] 스낵바 이관 대장 페이지 발행 (Artifact) —
      https://claude.ai/code/artifact/87a5e3db-8eb3-4ef3-a24f-bc0dc08a329b

## 진행중
- (없음)

## 대기
- [ ] **캐릭터 그림 3장 수령 대기** — 사용자가 `happy.png`/`sad.png`/`neutral.png` 를
      주면 Claude 가 2단계만 하면 켜진다:
      ① `pubspec.yaml` 의 `- assets/character/` 주석 해제
      ② `lib/widgets/mascot.dart` 의 `_assets` 맵 주석 해제
      **Claude 가 캐릭터를 생성·교체하지 않는다** (사용자 지시). 규칙 = `assets/character/README.md`
- [ ] 새 스낵바 모양 실기 확인 — APK 재빌드 후 폰 설치 (현재 폰에는 이관 전 빌드)
- [ ] 프로드 테스트 쪽지 3건 정리 (변민준 대화에 남음) — 사용자 요청 시

## 결정사항 / 주의

- **캐릭터는 성격 3종만** (2026-08-21 사용자 결정). 화면별 전용 그림 금지 —
  화면 수만큼 그림이 늘고 변경 파급을 못 잡는다. 레벨별 진화 5종 안(v3.5 초안)은 폐기
- **경로 문자열은 mascot.dart 밖에 절대 금지** (§0-B). 화면 코드에 파일명이 들어가는
  순간 이원화. 슬롯 위치는 그 파일 주석에 명시
- **appkit 에 마스코트 금지** — 거기는 workcheck·writeplz 공통 조상, 마스코트는 HYPHEN 전용
- 스낵바 창구는 **HkSnack 하나** (`lib/widgets/hkit.dart`). static show/error(동기) +
  `HkSnack.of(context)` 손잡이 info/fail(async gap 안전). 새 raw SnackBar 작성 금지
- 프로드 gym_id=2 는 **실영업 데이터** — 쓰기 테스트는 로컬(8081/5060)에서
- 갤S22 무선 디버깅은 자주 꺼진다. 실패 시 `adb kill-server` → `adb mdns services`
  → mDNS 시리얼(`adb-R5CT503NB5M-...`)로 직접 `-s` 지정
- 자동 변환 스크립트가 과매칭한 이력 있음 (main_shell·wod_session·wod_result_sheet) —
  대량 정규식 치환 후에는 반드시 `flutter analyze` + 전체 테스트로 확인
- 이 repo 는 **push ≠ 배포** (APK 수동). services/facing·web/facing-admin 은 `railway up` 수동

## 다음 세션 권장 첫 프롬프트
`/resume`
