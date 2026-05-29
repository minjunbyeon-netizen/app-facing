# HANDOFF - 2026-05-29 13:32

> ⚠️ 이번 세션 실제 작업 레포는 **C:\dev\web\facing-admin** (사장용 관리자 웹, Python Flask + Jinja + static/app.js).
> cwd 는 facing-app(Flutter)지만 코드 변경은 전부 facing-admin 에서 일어났어요.
> 둘 다 branch=`overnight/2026-05-25`. **배포 금지 — 로컬 커밋만, push 안 함.**
> 로컬 admin 웹: http://localhost:8081 (백엔드 services/facing, 로그인 boss_seongsu/1234, gym_id=2)

## 완료 (facing-admin, 전부 로컬 커밋 + playwright 검증)
- [x] 락커 datalist 자동완성 깨짐 — app.js 구버전 중복 함수(openLockerAssign 등)가 신버전 덮어씀 → app.js 락커 블록 제거 (3d8d1c7)
- [x] app.js 전역 함수 충돌 3건 (aaf6f8c): settings_plans/points `closeModal()` 크래시 → `closePlanModal`/`closePointModal` 분리 / members `applyFilter` → `applyMemberFilter` / app.js 전역 `.chip`·searchInput 핸들러 제거 (members 만료·일시정지·케어 필터 0건 버그)
- [x] 회원 추가 시 플랜 바꾸면 금액 자동 갱신 — autoFillEnd(prefix, fromPlanSelect) (fccbc64)
- [x] 회원 수정 모달에 회원권 가격칸 추가 + 발급 시 price:0 하드코딩 제거 (ab5fdaa)
- [x] 수업 묶음 3건 (8a1a08c): wod 리더보드 Elite/RXD/Scaled 서브탭 `.tab-chip` 충돌 → 상단 핸들러 `.filterbar` 한정 / calendar `month`+`data.items` → `from/to`+`data` 배열 / classes 추가 모달 공통 담당코치 select 추가(템플릿 경로 coach=null 하드코딩 해소)
- [x] 수업 상세 담당코치 ID→이름 표시 (_coachMap) (e5882ad)
- [x] 공지사항 — 프론트·백엔드 이미 완성 확인, 낡은 "endpoint 미구현" 주석만 제거
- [x] "기타→수업" 네비 rename — 이미 "수업" 섹션 존재(_layout.html:89), 변경 불요
- [x] /dead 데드코드 스캔 — admin+backend, **report-only (변경 안 함)**
- [x] 테스트 데이터 정리: 테스트 플랜(R2Test 등 4개) 삭제 · 테스트 공지 삭제 · 테스트 클래스 id=50 취소 · 리더보드 시드(세션1+점수9)·임시 스크립트 삭제

## 진행중
- 없음 (모든 변경 커밋 완료, 작업 트리 clean)

## 대기 (다음 세션 후보)
- [ ] safe-to-remove 데드코드 67건(거의 미사용 import) 정리 — 이번엔 report-only 선택. 적용하려면 repo별 새 브랜치+단일 커밋. ruff `--fix` 로 61건 auto. 중단지점: `services/facing` ruff F401/F841 결과 + facing-admin `scripts/seed_demo.py:12` sys import
- [ ] WOD '오늘 WOD' 게시 → 폰 회원 점수 입력 → 리더보드 반영 전체 흐름 점검 (미착수)
- [ ] 이메일 기능 실제 Mailgun 연결 (services/facing/api/notifications/email.py — 현재 send_email 호출부 0건 + Mailgun POST는 TODO 스텁. body_html "미사용"은 버그 아닌 미래용 스캐폴드)
- [ ] 배포: 준비되면 facing-admin `overnight/2026-05-25` push + Railway 배포 (사용자 "배포" 명시 후에만)

## 결정사항 / 주의
- "수업" 작업 타깃 = **admin 웹** (폰 앱 아님). 폰 앱엔 "기타" 탭·calendar 없음, 탭 5개 고정으로 확인
- `coach_user_id` = login_id 문자열 (coaches API `login_id` 와 일치, classes PATCH 지원)
- app.js 는 `_layout.html` 에서 `defer` 로드 → 인라인보다 항상 나중 실행 → `window.*` 덮어씀. 페이지-로컬 함수는 app.js 전역과 이름 겹치면 안 됨 (§0-B SSOT). 이번 충돌 버그들의 공통 원인
- classes GET 백엔드: `from/to`(ISO) 파라미터만, 응답 `data`=배열 (`month`/`data.items` 아님)
- 배포 금지 룰 (facing-app CLAUDE.md 최상위) — 로컬 commit OK, push/PaaS 배포는 "배포" 명시 전까지 금지

## 다음 세션 권장 첫 프롬프트
`/resume`
