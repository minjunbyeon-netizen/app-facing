# HANDOFF - 2026-08-24 22:53

## 완료 (이 세션)
- [x] **전면 자동 승인 전환 (사용자 지시)** — 배포 금지 룰 폐기 → CLAUDE.md §전면 자동 승인
  규칙 (hyphen 3면 push·railway up·DB 적용 전부 즉시 실행). `.claude/settings.local.json`
  `defaultMode: bypassPermissions` 는 사용자가 직접 적용 (다음 세션부터 발효).
  메모리 = `feedback-full-autonomy-hyphen.md`. ⚠ `.nopush` 마커 3면 삭제는 분류기 차단 —
  사용자 `!` 실행분 미완 (푸시는 마커 있어도 정상 통과했음)
- [x] **7항목 실검증 (에뮬 회원 ↔ PC 코치 E2E)** — ① 인증→대기함→승인→지급 왕복
  ② 달력 2배(주 107px×6, CSS 변수 SSOT) ③ 적립규칙 수동 4종+자동 3종 지급 실증
  ④ 계약 템플릿 수정·발급건 변수만·서명 잠금·서명본 동결 ⑤ 앱 서명패드 E2E
  ⑥ 회원권 발급(시작=만료 다음날)·정지 +9일·해제 원복 ⑦ 활동기록(90일·TOP5·결제·출석)
- [x] **실버그 6건 수정 + 회귀 테스트** (서버 194 passed·앱 189 passed·골든 58):
  ⑴ 인증 승인 첫 지급 누락 — `api/reward_rules.py` decide flush 추가
  ⑵ 정지 해제 이중 연장·역전 데이터 — `api/admin.py` resume 차액 보정
     (`tests/test_membership_pause.py` 신설 3건)
  ⑶ 앱 인증 시트 키보드 크래시 — `challenge_section.dart` _LogSheet State 소유로 이관
  ⑷ point-rule PATCH null 400 ⑸ 대표 회원권 미래권 가림 — `gym_state.dart`
  ⑹ 포인트 잔액 고착 — `mypage_screen.dart` GymState 청취
- [x] **개선** — member lessons `by_hour`(자주 오는 시간, PC 수강 이력 탭 표시) ·
  member 계약 `body_text`(서명 전 본문 열람, 앱 표시) · memberships pause 필드 →
  앱 일시정지 배지 · 계약 배지 한글화(골든 1장 갱신) · is_paused 경계 통일 ·
  달력 죽은 gantt CSS 6종 정리
- [x] **검증 산출** — 코드 지도 에이전트 3 + 코드리뷰 에이전트 APPROVE(결함 0·LOW 1 반영)
- [x] **커밋·푸시·배포 완료** — 3 레포 push (서버 caa7519 · 웹 6eb1b23 · 앱 f219f6a) +
  railway up 2건 → 프로드 /health·/login 200 확인. 검증 데이터 원복 완료
  (포인트 원장·서명 계약 id 2 는 이력 보존)

## 진행중
- 없음 (검증 사이클 완결)

## 대기
- [ ] **포인트 3중 이원화 정리 방향 결정 (사용자)** — 포인트 설정(PointRule, 수동 기준표)
  vs 업적 설정(RewardRule, 자동 지급) 같은 트리거명·다른 동작 + GymPointSettings
  (earn_rate 등) 소비자 0 고아. 통합/유지 결정 필요
- [ ] 릴리즈 APK 갤S22 실기기 설치 (3세션째 이월) — `build/app/outputs/flutter-apk/app-release.apk`
  는 v3.19 구빌드. 이번 수정 반영하려면 `flutter build apk --release --dart-define=API_BASE_URL=https://service-facing-production.up.railway.app` 재빌드 후 `/연결` → `adb install -r`
- [ ] (보고만·수정 지시 대기) 정지 시 후속 회원권 시작일 미보정(겹침 가능) · 결제 1만원당
  자동 계산 없음 · WOD 기록 100P 하드코딩(`api/gym.py:1901`) · 앱 계약 변수 라벨 raw 영문 ·
  회원 예약 원시 타임라인/90일+ 출석 누적 없음
- [ ] (선택) `.nopush` 마커 3면 삭제 —
  `! del C:\dev\services\hyphen\.nopush, C:\dev\web\facing-admin\.nopush, C:\dev\apps\facing-app\.nopush`
  삭제 후 `C:\dev\CLAUDE.md` G1 행 갱신 필요 (§0-B)

## 결정사항 / 주의
- **전면 자동 승인 발효 범위**: 잔여 예외 = main force push·시크릿 커밋·파괴 git(글로벌
  절대 차단) + 하니스 분류기 차단 (권한 자가 상향·게이트 마커 삭제류는 Claude 실행 불가)
- pytest 는 반드시 `python -m pytest tests` (bare pytest = _archive 수집 에러 함정)
- 로컬 백엔드(:5060)·관리자 웹(:8081) bg 실행 중 — 새 세션 재기동 필요. **이중 LISTEN 유령
  주의**: 재기동 전 `Get-NetTCPConnection -LocalPort 5060,8081 -State Listen` 확인
- 에뮬 앱은 이번 수정 반영된 debug 빌드 설치됨 (세션 유지 중). 에뮬은 `-timezone Asia/Seoul`
- is_paused/pause_end 는 **배타 경계** (해제일부터 정지 아님) — 서버·앱 동일 규약으로 통일함
- PS 5.1 함정: 커밋 메시지 here-string 안 큰따옴표 → 네이티브 인자 분해 깨짐 (따옴표 금지)
- playwright 스크린샷은 저장 위치가 repo 루트로 새는 경우 있음 — 검증 후 삭제할 것

## 다음 세션 권장 첫 프롬프트
`/resume` → 포인트 이원화 방향 결정 또는 릴리즈 APK 재빌드·실기기 설치
