# HANDOFF - 2026-06-01 23:00

## 완료
- recovery_test 컴포넌트 분리 (직접테스트 test()와 완전 독립) (6825581)
- 4단계 고정 스텝바 추가: 기초재활→회복테스트→재평가→운동복귀 (route/recovery_test/complete 공통)
- rehabProgressBar() 헬퍼 함수로 스텝바 통합, done 단계 클릭 시 해당 화면 복귀
- recovery_complete 화면 신설: 회복테스트 pass → "2단계 완료!" → 3단계 재평가 시작
- 재활 루트 퍼센트 4단계 기준 재계산 (updateProgress)
- selectTestResult retestMode: pass→recovery_complete, fail→route(stageIndex=0)
- 1단계 완료 화면: 텍스트("최소 3일 이상…") + 버튼 3개(지금 바로 테스트하기/내일 다시 오기/이 단계 운동 다시 보기)
- recovery_complete 레이아웃 순서 수정 (f5cbb4e)

## 진행중
- 없음

## 대기
- 카카오·구글 OAuth 백엔드 연동 (현재 "준비 중" 토스트)
- 추이 탭 종목 관리 기능 (삭제·병합 등)
- 기록 탭 수정 기능 (현재 삭제만 가능)
- press-vertical.json elbow coming_soon 원복 여부 확인
- 실제 운동 영상 URL 데이터 입력
- recovery_test 없는 pain site(squat/shoulder, squat/hip 등) 처리 — 현재 토스트만 표시

## 결정사항 / 주의
- 배포 구조: rehap2(로컬 작업) → Copy-Item → rehap1/index.html + 루트 index.html → git add 두 파일 → push
- 4단계 고정 매핑: stageIndex 0→1단계, recovery_test→2단계, stageIndex 1→3단계, stageIndex 2→4단계
- stageToStep = { 0:0, 1:2, 2:3 } (0-based, updateProgress용)
- rehabProgressBar()는 cause/route/complete/recovery_test 화면에서 호출, recovery_complete는 하드코딩 바 사용
- recovery_test 하드코딩 바: 1 기초재활(button/done), 2 회복테스트(div/active), 3·4(div)
- retestMode 플래그: goRetest()에서 true 설정, selectTestResult에서 소비 후 false
- "기초 재활" stage name 하드코딩으로 needsRetest 분기 — 다른 이름 쓰면 미작동
- 앱 이름: LogFit (로그핏), 주 색상: 차콜 #2C2C2C + 흰색 + 파란색 #4A7FC1

## 다음 세션 권장 첫 프롬프트
`/resume`
