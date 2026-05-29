# HANDOFF - 2026-05-30 08:35

> ⚠️ 이번 세션 실제 작업 레포는 **C:\dev\services\facing** (백엔드 Flask) + **C:\dev\web\facing-admin** (사장용 관리자 웹).
> cwd 는 facing-app(Flutter)지만 코드 변경은 위 두 곳에서 일어났어요. 폰 앱(facing-app)은 이번에 코드 변경 없음(읽기만).
> 세 repo 모두 branch=`overnight/2026-05-25`. **배포 금지 — 로컬 커밋만, push·Railway 안 함.**
> 로컬: 백엔드 http://localhost:5060 (현재 실행중 PID 2112, 새 코드 로드됨) · admin 웹 http://localhost:8081 (로그인 boss_seongsu/1234, gym_id=2)

## 이번 세션 한 일 — WOD→점수→리더보드 흐름 점검 + 끊김 수정

### 발견한 핵심 버그 (끊김)
- admin Leaderboard 탭은 `wod_session`/`wod_score` 를 읽는데, **이 테이블에 점수를 쓰는 API 가 없음**(seed 전용). 폰 점수는 `gym_wod_results` 로 들어감 → 폰 제출 점수가 admin 리더보드에 절대 안 뜨던 구조적 끊김.
- scale enum 도 불일치: 폰 `rx/scaled/beginner` vs admin `rx_plus/rx/scaled`.
- ARCHITECTURE_BRIEF(line 243) 유지 테이블 = `gym_wod_posts·gym_wod_results` → 이게 정답, admin 쪽이 잘못된 쪽이었음.

### 완료 (전부 로컬 커밋 + playwright 라이브 검증)
- [x] 백엔드 `admin_leaderboard` 를 `gym_wod_posts`+`gym_wod_results` 기준으로 재배선 (services/facing `0692fb8`). scale enum 폰과 통일(rx/scaled/beginner). device_hash→GymMember→GymMemberProfile.name 조인, 없으면 `익명·{hash6}`. for_time=time asc, amrap/emom=rounds desc·extra desc 정렬.
- [x] admin 프론트 Leaderboard 탭 Elite/RXD/Scaled → **RX/Scaled/Beginner** 로 변경 (facing-admin `baf7d5a`)
- [x] 실제 흐름 실증: 백엔드 재시작 → 임시 회원으로 폰 endpoint(`POST /gyms/2/wods/{id}/results`) 점수 제출 → admin 리더보드에 즉시 1위 표시 확인 (테스트 데이터·캡처 png 모두 삭제)
- [x] **WOD별 리더보드** (약점 ⓑ): 백엔드 `wod_post_id` 파라미터 추가 (services/facing `ecdb940`) — 주면 그 WOD 고정, 없으면 그날 최신, 없는 id 는 session null graceful. admin 프론트에 WOD 선택 드롭다운 추가 (facing-admin `0ed7db6`) — 오늘 WOD 목록 채우고 기본 최신 선택. AMRAP↔FRAN 전환 라이브 검증 OK.

## 진행중
- 없음 (모든 변경 커밋 완료, 세 repo 작업 트리 clean)

## 대기 (다음 세션 후보)
- [ ] 약점 ⓐ — AMRAP 점수 표시가 `rounds` 만 (extra_reps 는 정렬엔 쓰나 화면 숫자엔 빠짐). `8+15` 형태로 고치려면 백엔드 score_value 표현 + 프론트 fmt 둘 다. 중단지점: admin.py `admin_leaderboard` 의 `score_unit="rounds"` 분기 + wod.html `fmt()`
- [ ] 약점 ⓒ — `churn_risk`(이탈위험)가 아직 `wod_score`(seed 전용) 읽음. `services/facing/services/cohort.py:103` `from models.wod_score import WodScore`. gym_wod_results 기준으로 돌려야 점수 출처 완전 통일. (회귀 아님 — 기존도 그랬음, 정합성 정리)
- [ ] 약점 ⓑ 확장 — 드롭다운이 "오늘" WOD 만 채움. 과거 날짜 WOD 리더보드 보려면 날짜 picker 필요(백엔드는 wod_post_id 만 주면 과거도 됨)
- [ ] 이전 세션 잔여: safe-to-remove 데드코드 67건(ruff `--fix` 61건 auto) · 이메일 Mailgun 실제 연결(email.py 스텁) · 배포(준비되면 세 repo push + Railway)

## 결정사항 / 주의
- WOD/리더보드 SSOT = **gym_wod_posts·gym_wod_results** (ARCHITECTURE_BRIEF 기준). wod_session/wod_score 는 이제 churn_risk·seed 만 읽음 — 점수의 정본 아님.
- 로컬 백엔드는 **Flask 리로더 꺼져 있음** → .py 고치면 반드시 5060 재시작해야 반영됨. 재시작 패턴: `Get-NetTCPConnection -LocalPort 5060` PID Stop-Process → `python app.py`(background) → LISTEN PID 1개 확인.
- 폰 device 인증 = `hash_device_id(X-Device-Id)` = `sha256(SECRET_KEY + device_id)` (models/profile.py:15). 테스트 시 임시 device_id 로 gym_members(approved) + profile 시드 후 실제 endpoint 호출.
- 8081 admin 웹은 PID 2개 LISTEN(좀비 의심) 상태였음 — 이번 작업엔 무영향, 손 안 댐.
- 배포 금지 룰 (facing-app CLAUDE.md 최상위) — 로컬 commit OK, push/PaaS 는 "배포" 명시 전까지 금지.

## 다음 세션 권장 첫 프롬프트
`/resume`
