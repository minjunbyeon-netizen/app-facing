# Coach Persona Feedback — v1.16 Sprint 12

**일자**: 2026-04-25 · 10명 코치 페르소나 가상 시뮬레이션
**시나리오**: 각 코치가 FACING 앱으로 자기 박스를 운영한다고 가정, 한 달 돌려본 후 피드백
**총**: 불만 100 · 제안 100

**참여 코치**:
- C1 대형박스오너(150명, 멀티코치) · C2 솔로코치(30명) · C3 프랜차이즈체인매니저(5지점) · C4 경쟁·Games준비코치(8명 정예)
- C5 마스터스코치(45+ 40명) · C6 프랜차이즈지점장(본사SOP) · C7 파트타임코치(저녁2h)
- C8 키즈/틴즈코치(8-15세) · C9 여성전용박스(80명) · C10 재활·PT코치

---

## Top 15 공통 요구 (4명 이상 언급)

| # | 카테고리 | 요구 | 우선 | 로컬 구현? |
|---|---|---|---|---|
| 1 | 멤버 관리 | 멤버별 last_activity · streak · 상태 배지 | **P0** | Yes |
| 2 | WOD 운영 | 어제 WOD 복사 · 템플릿 · 주간 반복 | **P0** | Yes |
| 3 | WOD 운영 | Scale Guide 텍스트 필드 (RX vs Scaled 무게·대체) | **P0** | Yes |
| 4 | 기록·성과 | 멤버별 지난 30일 WOD 히스토리 | **P0** | Yes (더미 seed) |
| 5 | 공지·알림 | 박스 전체 공지 (앱 내) | P1 | Yes (새 모델) |
| 6 | 스케줄 | 클래스 시간표 (아침/낮/저녁) | P1 | Yes (필드 추가) |
| 7 | 안전·부상 | 멤버 부상 메모 (코치 전용) | **P0** | Yes (로컬 only mock) |
| 8 | 데이터 | 박스 대시보드 (전체/활성/참가율) | **P0** | Yes |
| 9 | 권한 | 코치 복수 · 역할 권한 | P2 | 백엔드 확장 |
| 10 | 멀티 지점 | 체인 대시보드 | P2 | 복잡 |
| 11 | 결제 | 월 정기결제 · 미납 관리 | Phase 2 | 결제 PG 필요 |
| 12 | 미성년 | 보호자 동의 플로우 | Phase 2 | 법적 검토 |
| 13 | 배지 | 키즈 배지 · PR 축하 | P1 | 기존 시스템 확장 |
| 14 | 영상 | WOD 동작 영상 첨부 | P2 | 스토리지 필요 |
| 15 | 푸시 | FCM 알림 (새 WOD · PR) | Phase 2 | FCM 셋업 |

---

## 카테고리별 요약

### 멤버 관리 (C1-C4, C5, C9 중복 20+ 지적)
- 대량 승인 / 상태별 필터 / 검색
- 비활성 N일 경고 / 휴면 자동 전환
- 멤버 메모 (코치 전용) : 부상·생활변수·알레르기
- 코치 권한 분리 (WOD 작성 / 멤버 승인 / 전체 삭제)
- 멤버 레벨(Scaled/RX/RX+) 설정

### WOD 운영
- Scale Guide (RX 무게·Scaled 대체 동작)
- 어제 WOD 복사 / 주간 반복 템플릿
- 주기화 페이즈 태그 (Hypertrophy/Strength/Power/Conditioning)
- WOD 수정 시 기록 유지 vs 초기화 선택
- 타임슬롯 다중 WOD (아침/낮/저녁)

### 스케줄·시간표
- 클래스 시간표 (아침 6:30 / 낮 12:00 / 저녁 18:00)
- 월간 플래닝 드래그앤드롭
- 휴무일 일괄 설정
- 12주 사이클 시각화

### 기록·성과 추적
- 멤버 프로필 → 지난 3개월 WOD 히스토리
- 동작별 PR (1RM, Fran time)
- 박스 스코어보드 PDF/CSV 다운로드
- "이 달 가장 많이 한 동작"
- 팀 성과 비교 · 강점/약점 매트릭스

### 공지·커뮤니케이션
- 박스 전체 공지 (긴급/일반 우선순위)
- 그룹별/지점별 차등 발송
- "읽음" 통계
- WOD 피드백 댓글

### 안전·부상·의료 (C7, C10 C17~C20)
- 멤버 부상 이력 (수술·처방·금기 동작)
- 복귀 플랜 주차별 강도 자동
- 금기 동작 경고 (WOD 편성 시)
- 의료 기록 파일 첨부 (PDF)

### 미성년·여성·PT (C8, C9, C10)
- 보호자 동의 프로세스
- 여성 전용 박스 토글
- 생리·산전·산후 상태
- 키즈 배지 · 스티커 · 레벨업

### 데이터·KPI·리포팅
- 박스 대시보드 (전체 멤버/활성/참가율/이탈)
- 월간 리포트 PDF 자동 생성
- 지점별 비교 (체인)
- 멤버 유지율 (3m/6m/1y)

### 결제·수금 (Phase 2)
- 월 정기결제 자동화
- 미납 자동 추출 · 독촉
- 월간 수입 대시보드
- 환불 처리

### 체인·본사 (Phase 2)
- 지점별 시간표·수강료 독립
- 본사 → 지점 WOD 검수
- 신규 코치 온보딩 체크리스트

---

## Sprint 12 P0 즉시 실행 (현재 세션)

### 1. 더미 데이터 seed (백엔드)
- FACING 박스에 15명 멤버 가입 + 상태 다양화 (active 12 / paused 2 / rejected 1)
- 각 멤버 device_hash에 대해 지난 30일 WOD history 7~22개 랜덤 생성
- streak·참가율 체감 가능하게

### 2. GymWodPost.scale_guide 필드 (백엔드)
- migration: ALTER TABLE gym_wod_posts ADD COLUMN scale_guide VARCHAR(500)
- POST payload에 scale_guide (optional)
- GET 응답에 포함

### 3. 멤버 목록 확장 (백엔드)
- GET /api/v1/gyms/<id>/members 응답에:
  - last_wod_at (ISO) · total_sessions · streak_days
- dummy device_hash들 기반 집계

### 4. Coach Dashboard 확장 (프론트)
- 멤버 카드: 이름 prefix · 상태 · 마지막 활동 · streak
- 탭 시 bottom sheet: 최근 5개 WOD · mock 부상 메모

### 5. WOD 게시 확장 (프론트)
- Scale Guide 텍스트 에어리어 추가
- "Duplicate yesterday's WOD" 버튼

### 6. WodCard + WodSession에 Scale Guide 노출

---

## Sprint 13+ (P1, 로컬 구현 가능)

- 공지사항 (Announcements) 모델 + API + UI
- 클래스 시간표 (Gym.schedule JSON 필드)
- 멤버 부상 메모 (coach-only local notes, privacy 민감)
- PR 자동 축하 로직
- WOD phase 태그 (Hypertrophy/Strength/Power/Conditioning)
- 주기화 시각화 (타임라인)

## Phase 2 (외부 의존·법적 검토 필요)

- 결제 PG 연동 (Stripe/TossPayments)
- 보호자 동의 · 14세 미만 GDPR
- 의료 기록 첨부 (보안·보존 정책)
- 영상 첨부 (스토리지 비용)
- FCM 푸시 알림 인프라
- 체인 멀티 지점 (권한·본사 roles)
