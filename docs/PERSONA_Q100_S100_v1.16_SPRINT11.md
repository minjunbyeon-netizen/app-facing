# Persona Q100 + S100 — v1.16 Sprint 11 (Post-Sprint-10 리뷰)

**일자**: 2026-04-25
**대상**: P1 코치김 · P2 회원박 · P3 솔로한 · P9 데이터광 · P10 소셜경쟁
**상태 기준**: Sprint 10 직후 (내장 타이머 · WOD 세션 · 캘린더 자동 반영 반영됨)
**총**: 질문 100 · 제안 100

---

## 카테고리별 Top 구현 항목 (Sprint 11 착수)

| 우선 | 카테고리 | 구현 | 출처 |
|---|---|---|---|
| **P0** | 기록/타이머 | Wakelock (화면 꺼짐 방지) | P3 Q9, S3 |
| **P0** | UI/반응성 | PopScope 세션 보호 + 확인 다이얼로그 | P2 Q44, Q50 / S44, S50 |
| **P0** | 카테고리/개인화 | Scaled 토글 + 기록 배지 | P2 Q8, Q18 / S12, S18 |
| **P0** | 페이싱·Calc 연결 | Pacing 버튼 → Calc 탭 실제 진입 | P2 Q34, P3 Q35 / S34 |
| **P0** | 신뢰/투명성 | Algorithm 설명 화면 (공식·논문 링크) | P9 Q9-Q15 / S7, S8 |
| P1 | 기록 수정 | History 기록 수정·삭제 | P3 Q6 / S8 |
| P1 | 데이터 내보내기 | CSV export (share_plus) | P9 Q16 / S13 |
| P1 | 차트 | Engine 90일 타임라인 상세 | P9 Q27 / S22 |
| P2 | 외부연동 | Whoop/Garmin OAuth (Phase 2) | P9 Q1-Q8 |
| P2 | 소셜 | 친구·랭킹·팀 (Phase 2, 백엔드 필요) | P10 Q33-Q43 |

---

## 기록/타이머 (15)
- Wakelock · Back 확인 · Scaled 토글 · 수정/삭제 · 음성 카운트다운 · 페이스 실시간 게이지 · 라운드+추가반복 UI 단순화 · 같은 WOD 여러 번 기록 · 타이머 완료 자동 bottom sheet · EMOM 진동 토글 · 오프라인 draft · 가로 모드 대응 · 무한 스크롤 · 긴 동작명 줄바꿈 · 작은 화면 폰트 축소

## 페이싱·Calc 연결 (10)
- Pacing 버튼 실제 딥링크 · Grade Split → WodBuilder pre-fill · 세션 상단 예상 Split 미니 가이드 · 완료 후 실제 vs 제안 차이 분석 · Burst 에너지 게이지 · 박스 평균 vs 개인 페이싱 · AI 다음 Split 제안 · Tier별 WOD 추천 · 페이싱 성공 패턴 추출 · 코치 진행 그래프

## 카테고리/개인화 (11)
- Scaled/RX 배지 · Unit 토글 전역 · 약점 카테고리 태깅 · 추정공식 공개 · Max 변경 이력 · 체중 변동 시 Recalc 배너 · 신규 멤버 1RM 임시값 · 비표준 동작 요청 메일 · 승인 전 관전 모드 · 휴가 pause · 재측정 주기 알림

## 신뢰/투명성 (7)
- Engine 계산식 공개 · Split 시뮬레이터 · Burst 에너지 곡선 투명성 · Tier 변화 로그 · 민감도 분석 · 벤치마크 데이터셋 출처 · Scaled 가중치 명시

## 데이터 내보내기 (5)
- CSV export · JSON dump · Google Sheets 연동 · 월별 대시보드 PNG · Auto-backup 클라우드

## 외부기기 (8, Phase 2)
- Whoop · Garmin · Apple HealthKit · Strava · 다중기기 우선순위 · sync 배너 · OAuth refresh · HRV 매핑

## 공개 API (5, Phase 2+)
- OpenAPI docs · OAuth 포탈 · Webhook · 익명 공개 데이터셋 · GraphQL 고려

## 친구·팔로우 (5, Phase 2)
- Follow · Feed · 프라이버시 · 박스 로컬 · DM

## 랭킹/리더보드 (6, Phase 2)
- 글로벌 · 체급·성별 · 박스 로컬 · 이벤트(Fran Challenge) · Head-to-Head · 챌린지 순위

## 공유·SNS (5, Phase 2)
- IG Story 자동생성 · Reaction · 비공개 링크 · Slack 봇 · 주간 하이라이트 Shorts

## 챌린지·팀·그룹 (4, Phase 2)
- 챌린지 생성 · 팀 점수 · 박스 내부 그룹 · 진행률 대시보드

## 코치/관리 (10, 로컬 가능분만)
- 주간 템플릿 복사 · 멤버 Tier 분포 · Scaled 의존도 · 휴무일 · 승인 전 관전 · 가이드 업로드 · AI 페이싱 피드백 · 월간 PDF · 스케일 전용 태그 · 휴가 pause

---

## Sprint 11 P0 5건 구체 구현

### 1. Wakelock
- `pubspec.yaml`: `wakelock_plus`
- `wod_session_screen.dart`: Start 시 enable · Pause/Reset/dispose 시 disable

### 2. PopScope 세션 보호
- 타이머 활성 상태에서 뒤로가기 → AlertDialog("진행 중인 세션. Reset 후 종료?")
- Complete 완료 후에는 자유롭게 뒤로

### 3. Scaled 토글
- Record sheet에 `Switch(ScaledChip)` 추가
- notes 앞에 `[SCALED]` 접두사 · 현재 이미 `wod_type`은 FRAN 기준이므로 `notes`에만 반영
- History 카드에 Scaled 배지 노출 (옵션, Sprint 11.1)

### 4. Algorithm 투명성
- `lib/features/mypage/algorithm_screen.dart` 신규
- `core/formula_references.dart` (이미 8개 참조)에서 구성 + Engine 산식 요약 + Tier 매핑표
- MyPage Actions에 "Algorithm" 엔트리 추가

### 5. Calc 딥링크
- `core/shell_nav_bus.dart` ValueNotifier — 어떤 탭 index로 이동할지 broadcast
- `main_shell.dart`: ShellNavBus.addListener → `_index = ...`
- `box_wod_screen.dart` Pacing 버튼: `ShellNavBus.switchTo(0)` (Calc)
- 현재는 빈 Calc 탭 이동만 — pre-fill은 Phase 2

---

## 제외 항목 (Phase 2 필수 · 백엔드·외부 API 필요)

- Whoop/Garmin/Apple Health/Strava 실연동 (OAuth + 공식 API 계약)
- 친구·팔로우·DM·Feed (user 모델 · 인증 확장 필요)
- 글로벌 랭킹·이벤트 챌린지 (aggregate DB · ETL)
- SNS 공유 실연동 (IG Graph API · TikTok Creator Kit)
- 공개 API/OpenAPI 포탈 (개발자 계정 · rate limit · docs 호스팅)
