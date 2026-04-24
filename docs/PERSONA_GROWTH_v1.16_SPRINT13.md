# Growth-Oriented Persona Feedback — v1.16 Sprint 13

**일자**: 2026-04-25 · 10명 성장 욕심 페르소나
**시나리오**: 앱으로 본인 성장·승급·경쟁 목표 추적
**총**: 불만 100 · 제안 100

**참여**:
- P1 대회준비자(Regionals 도전) · P2 PR 중독자(Fran sub-2) · P3 Tier 승급 집착 · P4 데이터 성장자
- P5 박스 내 경쟁자 · P6 후발 따라잡기 · P7 체성분 성장자
- P8 테크닉 마스터리 · P9 롤모델 팔로우 · P10 크로스핏 인플루언서

---

## Top 12 공통 요구

| # | 카테고리 | 요구 | 우선 | 로컬? |
|---|---|---|---|---|
| 1 | PR 추적 | 동작별 최고기록·트렌드 | **P0** | Yes |
| 2 | Tier 로드맵 | 다음 Tier까지 필요 점수·약점 | **P0** | Yes |
| 3 | 목표 설정 | 일/주/월/분기 목표·진행률 | **P0** | Yes |
| 4 | 박스 리더보드 | 같은 박스 순위 · 활동 비교 | **P0** | Yes |
| 5 | 약점 분석 | 자동 감지 + 집중 프로그램 | P1 | Yes (로컬) |
| 6 | 롤모델 팔로우 | 엘리트 선수 WOD 라이브러리 | **P0** | Yes (mock) |
| 7 | 비디오 분석 | 폼 녹화·슬로우모션·비교 | P2 | 복잡 (SKIP) |
| 8 | SNS 콘텐츠 | 자동 카드·Reels 템플릿 | P2 | 복잡 (SKIP) |
| 9 | 외부연동 | Whoop/Garmin/HRV | Phase 2 | No |
| 10 | 체성분 | 체중·근육량 추적 | P1 | Yes (로컬) |
| 11 | 주기화 | Block 표시·Taper 가이드 | P1 | Yes (텍스트) |
| 12 | Cloud backup | 기기 변경 대비 | Phase 2 | 백엔드 인증 필요 |

---

## 카테고리별 요약

### PR 추적 & 동작별 기록 (P2 집중, 15+)
- 동작별 최고기록 탭 · PR 달성 배지 · 월 평균 그래프 · 박스 평균 대비 차이

### Tier 승급 로드맵 (P3, P6)
- "현재 RX 55 → RX+ +10 필요" · 약점 카테고리 +X점 시 전체 +Y점 시뮬
- 추정 도달 시점 (월별 성장률 기반)
- 승급 축하 후 다음 목표 제시

### 목표 관리 (P1, P2, P3, P4)
- 일/주/월/분기 목표 동시 관리
- PR 카운트다운 ("Fran sub-2까지 X일")
- 달성률 월간 리포트
- 시즌 목표 (Regionals 진출)

### 경쟁·비교 (P5, P6)
- 박스 리더보드 (체급·성별 필터)
- 같은 Tier 상위 3명 성장 곡선 겹치기
- 프라이빗 리더보드 (친구 3-4명)
- 전국·글로벌 랭킹 (공식 CrossFit 연동)

### 약점 분석 (P3, P6)
- 6 Radar 중 하위 2개 자동 강조
- "이 카테고리 +10 → 전체 +2" 시뮬
- 주간 집중 모드

### 주기화 (P1)
- Block 표시(Prep/Accum/Intensity/Peak/Deload)
- Volume Load 추적
- Taper 가이드 자동 (대회 2주 전)
- 시즌 캘린더

### 체성분 (P7)
- 체중·체지방·근육량 수동 입력
- 성능 vs 체성분 상관도
- 근육 증가기 긍정 피드백

### 롤모델·엘리트 (P9)
- 선수 5-30명 WOD 라이브러리 (Mat Fraser, Rich Froning, Tia Toomey 등)
- 선수별 철학·인터뷰
- 내 기록 vs 엘리트 비교
- 즐겨찾기 → 주간 추천

### 테크닉·비디오 (P8) — Phase 2
- In-app 녹화 · 슬로우모션 · 각도 가이드
- AI 폼 분석 확장 (Squat→전 동작)
- Before/After 비교
- 원격 코치 피드백 마켓플레이스

### SNS 콘텐츠 (P10) — Phase 2
- 원탭 공유 (IG/TikTok/Threads)
- Reels 템플릿 · 해시태그 자동
- Before/After 슬라이더
- Duo 콜라보
- 월간 하이라이트 컴필레이션

---

## Sprint 13 P0 즉시 실행 (현재 세션)

### 1. GoalsState + Goals Screen
- `core/goals_state.dart`: ChangeNotifier + SharedPreferences (`weekly_target_sessions`, `pr_goal_fran_sec` 등)
- `features/goals/goals_screen.dart`: 주간 세션 타겟 slider · Fran PR 목표 · 달성률 바
- Profile → "Goals" 진입점

### 2. Profile Tier 로드맵 카드
- 현재 Engine score 기반 → 다음 Tier 임계점 (매핑은 score 기준: 1→<=1.99, 2→<=2.99 … )
- "RX 55/100 → RX+ 65 필요 (+10)"
- 가장 약한 카테고리 1개 + "+5점 시 전체 +Y" 추정

### 3. Box Leaderboard 화면
- `features/leaderboard/box_leaderboard_screen.dart`
- 기존 /members API 재사용 → total_sessions 정렬 Top 10
- 내 현재 rank 하이라이트
- WOD 탭 AppBar에 trophy 아이콘 진입점

### 4. Favorite Athlete 롤모델
- `core/athletes.dart` 상수 5명 (Mat Fraser, Rich Froning, Tia Toomey, Ben Bergeron, Camille LB)
- SharedPreferences 저장
- Profile에 MY ROLE MODEL 섹션: 선수 이름 · 한 줄 철학 · 대표 WOD 텍스트

---

## Sprint 14+ 후보 (P1, 로컬 구현 가능)

- 체성분 로그 (BodyComp: weight/fat%/muscle_kg 수동 입력)
- 주기화 Block 태그 (WOD post에 phase 드롭다운)
- 약점 자동 감지 강화 (Profile → WeakInsight 확장)
- PR 동작별 테이블 (Profile → Benchmarks 상세)
- 월간 성장 리포트 PDF (local render)

## Phase 2 (외부 의존)

- Whoop/Garmin/Apple Health OAuth
- CrossFit Open 연동
- 비디오 녹화 · AI 폼 분석
- SNS 자동 공유 카드 (IG Graph API)
- 원격 코치 마켓플레이스 (결제 PG)
- Cloud backup (인증)
- 팔로워·커뮤니티 (소셜 그래프)
