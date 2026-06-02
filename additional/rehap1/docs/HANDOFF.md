# HANDOFF - 2026-05-29 16:00

## 완료
- index.html BUNDLED 인코딩 깨짐 수정 — rehap2 기반으로 재빌드 (rehap1/index.html)
- GitHub remote URL 수정: health → rahap1 (오타: rehap1 → 실제 rahap1)
- FRONTEND_URL 수정: rimseorim.github.io/health → rahap1 (루트 backend/routers/auth.py)
- GitHub Pages 배포: 루트 index.html 추가, .nojekyll 추가
- rehap1/backend/ 중복 제거, start.bat 백엔드 경로 루트로 수정 (fb91790)
- 네이버 로그인 정상 작동 확인

## 진행중
- JSON 콘텐츠 개편 — squat.json 완료, lunge.json 이후 미작업
  - 중단 지점: lunge.json 미시작
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
- **백엔드 경로 확정**: Railway는 루트 `backend/`를 실행. 수정 시 `01.test/backend/`만 사용할 것. `rehap1/backend/`는 삭제됨.
- **start.bat**: `rehap1/start.bat` 실행 시 백엔드는 `C:\dev\exercisematerials\01.test`에서 실행됨
- **GitHub 레포**: `Rimseorim/rahap1` (오타 주의 — rehap 아니라 rahap)
- **GitHub Pages**: `https://rimseorim.github.io/rahap1/` (네이버 로그인용 프론트엔드)
- **Railway**: `https://web-production-28002.up.railway.app` (백엔드 API)
- **로컬 테스트**: localhost:8080에서 네이버 로그인 불가 — demo 계정 kim@rehab.com / 1234 사용
- **명칭 규칙**: name/tag/tests[].name/exercises[].name → 전문용어 유지. description/purpose/why → 평문만.
- **JSON 수정**: Python 스크립트로만 (PowerShell 인코딩 깨짐)
- **포인트 컬러**: --navy #2C2C2C, --accent #4A7FC1

## 다음 세션 권장 첫 프롬프트
`/resume` 후 "lunge.json description·purpose·why 평문화 시작해줘"
