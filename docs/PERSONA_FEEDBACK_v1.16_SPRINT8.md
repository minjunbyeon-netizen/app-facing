# Persona Feedback — v1.16 Sprint 8 검증 (2026-04-24)

> **Scope**: Sprint 7a + 7b + 8 총 15건 반영 후 페르소나 10명 체험 피드백.
> **Source**: `/go` 4-agent (Haiku×2 + Sonnet 종합) + 실측 백엔드 journey test.
> **Status**: Beta Preview 공개 전 최종 블로커 점검.

---

## 실측 검증 요약 (백엔드 curl journey)

### 5 데모 계정 실제 동작 결과
| 계정 | Tier 계산 | 박스 상태 | 배지 해금 |
|---|---|---|---|
| **Coach Kim** | rxd #4 (4.49) | A Box owner | 4개 (FIRST_ENGINE·REACH_RX·REACH_RX_PLUS·SCORE_80_OVERALL) |
| **Member Park** | intermediate #3 (2.95) | A Box approved member | 2개 |
| **Solo Athlete** | rxd #4 (3.55) | 박스 미가입 | 3개 |
| **Masters Lee** | intermediate #3 (2.93) · Masters 45+ | 박스 미가입 | 2개 |
| **Elite Dara** | advanced #5 (5.21) | 박스 미가입 | 5개 |

### 백엔드 플로우 검증
- Coach → Member 가입 승인 → WOD 게시·조회 **전부 성공**
- 비-멤버 접근 `FORBIDDEN 403` 차단 정상
- Tier 배지 role별 차등 해금 정상

---

## 메타 통찰 5개

1. **계산기 vs 성장 추적기 정체성 분열**: 10 페르소나 전원이 "내 기록 어디에 남나?" 질문. `TRENDS` 탭명이 Achievement 갤러리로만 운영 → 인지 불일치.
2. **단순화 반동**: v1.15.3 카테고리 breakdown 제거 · v1.16 Result 박스 제거 → RX+ 세그먼트 P0급 이탈. **단순화 원칙: 접기 가능(collapsible)이지 삭제 아님**
3. **Masters 사각지대 반복**: 자간·영문·한글 부제 문제가 v1.15→v1.16 2회 연속 같은 유형 피드백. 설계 단계에서 Masters persona 포함 안 됨 신호.
4. **Auth/데이터 영속성이 RX+ 이탈 주범**: P4/P5/P6 "클라우드 백업 없으면 안 쓴다" 명시. Split 정확도보다 데이터 유실 리스크를 먼저 봄.
5. **Box 기능은 중심 가치**: P2 Yoon "Today's WOD가 왜 안 보이냐" — WOD 탭 하위 2단계 아래 숨어있음. 박스 소속 사용자에겐 1순위 사용 목적.

---

## 공통 반복 Top 10

| 순위 | 요구 | 그룹 A (5 데모) | 그룹 B (5 원본) | 카테고리 |
|---|---|---|---|---|
| 1 | 내 기록 어디 자동 저장? | 4/5 | 3/5 | 영속성 |
| 2 | 상위 몇 % 숫자로? | 5/5 | 5/5 | 비교 |
| 3 | Trends 카테고리 breakdown 복원 | 3/5 | 1/5 | 정보 밀도 |
| 4 | 약관·개인정보 부재 → 신뢰 의심 | 5/5 | 2/5 | 법·신뢰 |
| 5 | Google/Apple/Email 로그인 없음 | 3/5 | 2/5 | OAuth |
| 6 | Tier 배지 해금 조건 불명확 | 4/5 | 2/5 | 발견성 |
| 7 | Achievement 한글 부제 | 2/5 | 2/5 | 접근성 |
| 8 | Result BURST 구간 구분 약화 | 3/5 | 1/5 | 표현 |
| 9 | Box WOD 최상단 노출 | 4/5 | 1/5 | IA |
| 10 | 필수/선택 명확화 + Skip 경로 | 5/5 | 1/5 | 온보딩 |

---

## 실제 작동 vs 페르소나 인식 불일치 (5건)

| 기능 | 실제 동작 | 페르소나 인식 | 원인 |
|---|---|---|---|
| **Tier 배지 해금** | Demo 5계정 role별 2~5개 정상 해금 | "어떻게 받는지 모르겠음" | 잠긴 배지 해금 조건 텍스트 부재 |
| **Trends = 배지 갤러리** | 15개 정상 표시 | "추세 보려 눌렀더니 배지가?" | 탭명 TRENDS ↔ Achievement 의미 불일치 |
| **Masters 45+ 배지** | `mastersLabel()` 정상 반환 | Masters가 설명 읽지 못하고 넘어감 | desc 영문 전용 |
| **Sign out 데이터 유지** | AuthState.signOut은 isSignedIn만 false | "데이터 날아가지 않나?" | 다이얼로그 안내 부족 |
| **Skip → 나중 수정 가능** | Profile 탭 언제든 수정 가능 | "나중에 어디서 재입력?" | Skip CTA 옆 경로 안내 없음 |

---

## P0 CRITICAL (5건 · Beta Preview 블로커)

| # | 항목 | 이탈 위험 페르소나 | 화면 |
|---|---|---|---|
| **P0-1** | Trends 탭명 vs 콘텐츠 불일치 — 카테고리 breakdown 브릿지 OR 탭명 EARN/BADGES 변경 | P4·P6·Yoon | TrendsScreen + Shell label |
| **P0-2** | 이용약관·개인정보 링크 전무 — 법적 문제 | P2·P3·P9·P10 | SignupScreen 하단 |
| **P0-3** | Result BURST 구분 약함 — 1px line만으로 불명확 | P4·P5·P8 | result_screen.dart |
| **P0-4** | Achievement 잠긴 배지 **해금 조건 미표시** | 전 세그먼트 | TrendsScreen achievement_card |
| **P0-5** | Sign out 영문 + 데이터 유지 안내 없음 | P9·P10·Sangwoo | MyPageScreen |

---

## P1 HIGH (8건)

1. Achievement 카탈로그 **한글 부제** 필드 추가 (P9·P10)
2. Onboarding 필수/선택 명확화 + Skip 경로 안내 (전원)
3. **WOD 탭 최상단** Today's Box WOD 섹션 (P2·P4)
4. Signup **Beta Preview** 배지 + 정식 출시 로드맵 (P1·P3·P6)
5. **Kakao 버튼 WCAG AA** 대비비 검증 (#FEE500+#191600) (P9)
6. **Calc row 시각 강조** (divider 1px + surface 옵션) (P9·P10)
7. Games 카테고리 "역사" → "진입 경로" 프레임 (P5·P7)
8. Tier progression bar ("RX+까지 N점") (P3·P6)

---

## Sprint 9a 권장 범위 (Beta Preview 블로커 해소 · 1~2h)

| # | 작업 | 파일 | 시간 |
|---|---|---|---|
| 9a-1 | `Sign out` → `로그아웃` + "기기 데이터 유지" 안내 | `mypage_screen.dart` | 10분 |
| 9a-2 | 이용약관·개인정보 placeholder 링크 (signup 하단) | ✓ 이미 v1.16 반영 | 확인만 |
| 9a-3 | Achievement 잠긴 배지에 **해금 조건 표시** (catalog trigger_hint) | `achievement_card.dart` + catalog | 30분 |
| 9a-4 | Result BURST 구분 강화 (left-line 2→3px + 분할 숫자 h1→48sp) | `result_screen.dart` | 20분 |
| 9a-5 | Trends AppBar `TRENDS` → `EARN` + 상단 "Engine Progress →" Profile 링크 브릿지 | `trends_screen.dart` | 20분 |

---

## Sprint 9b (P1 5건 · 1주)

1. Achievement 한글 부제 렌더링
2. Onboarding 필수/선택 라벨
3. WOD 탭 Today's Box WOD 상단
4. Signup Beta Preview 배지 카피
5. Kakao 버튼 대비비 조정

---

## Sprint 10+ (Phase 2)

| 항목 | 설명 |
|---|---|
| Google/Apple/Email OAuth | P4/P5/P6 이탈 방지 핵심 |
| 계정 마이그레이션 | device_id → provider 바인딩 |
| 서버 백분위 집계 | Top N% 실제 데이터 |
| Games WOD 자동 업데이트 | 공식 공개 후 7일 내 갱신 |
| Box 지도 검색 | 지역 필터 + 지도 뷰 |
| PR 배지 | 카테고리별 신기록 trigger |
| CGM/HRV 연동 | P8 Dara 요구 |
| SNS 공유 | 결과 카드 이미지 |

---

## 10 페르소나별 최우선 (P0/P1/P2)

### Group A (5 Demo 계정)
| 계정 | 최우선 | 우선순위 |
|---|---|---|
| Coach Kim | Top N% 배지 (자부심 동기) | P1 |
| Member Park | Tier progression bar (다음 목표) | P1 |
| Solo Athlete | Custom WOD 저장·히스토리 | P2 |
| Masters Lee | 연령별 Tier 정규화 | P1 |
| Elite Dara | Hidden Legendary 진행도 게이지 | P0 |

### Group B (5 원본 페르소나)
| 페르소나 | 최우선 | 우선순위 |
|---|---|---|
| P2 Yoon | 약관·개인정보 정식 텍스트 | P1 |
| P3 Daehyun | 용어 tooltip 구현 (TermTip 완전화) | P1 |
| P6 Sangwoo | **Radar 5축 시각화** + 심층 진단 | P0 |
| P8 Dara_original | **Share 기능** (Instagram) | P1 |
| P9 Chulsoo | **폰트 확대 + VoiceOver** | P0 |

---

## CPO 최종 판단

> **Beta Preview 공개 가능? 조건부 Yes** — Sprint 9a 5건 완료 후 한정 공개 가능. 법적 약관 없는 상태 공개는 리스크.
>
> **가장 큰 강점**: Split/Burst 페이싱 결과 화면 + Tier 시스템 + Games WOD 카테고리의 조합은 시중 어떤 CrossFit 앱에도 없다. Elite 페르소나 반응이 가장 긍정적 — 정확한 타깃 포지셔닝 신호.
>
> **가장 큰 위험**: 로컬 전용 + Naver/Kakao 2개 OAuth 조합이 RX+ 중견 사용자(BTWB/Wodify 이탈자)에게 "데이터 못 믿는 앱"으로 찍히는 것. 핵심 타깃 P4~P8이 정식 Beta 전에 이탈하면 초기 리텐션 데이터 오염.

---

## 관련 문서
- 직전: `docs/UX_QUESTIONS_v1.16_FULL.md` · `docs/PERSONA_FEEDBACK_v1.16.md`
- CF Games: `docs/CF_GAMES_WODS_2021_2025.md`
- 게이미피케이션: `docs/GAMIFICATION_v1.16_PROPOSAL.md`
