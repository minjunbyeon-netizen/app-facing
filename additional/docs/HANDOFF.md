# HANDOFF - 2026-05-24 09:30

## 완료
- squat.json cause description 전문용어 제거·평문화 (1a3cc82)
- squat.json priority_note 전문용어 제거 (fd57dfc 포함)
- cause tag·name 전문용어 복원 (fd57dfc) — 평문으로 바꿨다가 사용자 지시로 원복
- test·exercise name 전문용어 복원 (d829100)

## 진행중
- JSON 콘텐츠 개편 — squat.json description/purpose/why 평문화 완료
  - 중단 지점: squat.json 완료. lunge.json 이후 미작업.
  - 다음 스텝: lunge.json의 causes[].description, tests[].purpose, exercises[].why 평문화

## 대기
- lunge·deadlift·pullup·kipping·press·row JSON description 평문화
- 고관절 콘텐츠 (런지·데드리프트·풀업·키핑·로우에 고관절 없음)
- PostgreSQL 전환 (현재 SQLite ephemeral)
- 네이버 앱 검수 신청
- 커뮤니티 기능
- 복합 원인 케이스
- 재평가 단계 체크박스 인터랙티브화 (현재 정적 텍스트)

## 결정사항 / 주의
- **명칭 규칙 확정**: name/tag/tests[].name/exercises[].name → 전문용어 유지. description/purpose/why → 전문용어 없이 평문만. 이후 모든 JSON 작업에 적용.
- API URL: `https://web-production-28002.up.railway.app`
- 네이버 콜백 URL: `https://web-production-28002.up.railway.app/auth/naver/callback`
- 로컬(localhost:8080)에서는 네이버 로그인 불가 — demo 계정으로 테스트 (kim@rehab.com / 1234)
- JSON 수정은 Python 스크립트로만 (PowerShell 인코딩 깨짐)
- 포인트 컬러: --navy #2C2C2C, --accent #4A7FC1
- 동작 ID: squat, lunge, deadlift, pullup, kipping, press-vertical, press-horizontal, row
- 통증 부위 ID: knee, lower-back, ankle, shoulder, wrist, elbow, hip, chest
- 재활 루트 3단계: 기초 재활(exercises) · 재평가(type:reassessment, checklist) · 운동 복귀(type:tips, tips[])

## 다음 세션 권장 첫 프롬프트
`/resume` 후 "lunge.json description·purpose·why 평문화 시작해줘"
