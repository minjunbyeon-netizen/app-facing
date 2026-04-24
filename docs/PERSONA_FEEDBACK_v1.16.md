# Persona Feedback — v1.16 (2026-04-24)

> **Scope**: v1.15.3 이후 누적 변경분 10건 대상.
> **Source**: `/go` 파이프라인 (Haiku×3 페르소나 시뮬레이션).
> **Status**: 반영은 별도 승인. 본 문서는 SSOT.

---

## v1.15.3 이후 누적 변경 (이번 피드백 대상)

1. Shell 5탭 영문 라벨 (`Calc · WOD · Trends · Attend · Profile`)
2. Calc 탭 4분류 row형 (Girls · Heroes · **Games 신규** · Custom)
3. Games 카테고리 6 WOD 추가 (Amanda .45 · Jackie Pro · 2421 · Sprint Snatch · DL+HSPU · Echo+Snatch)
4. Preset Detail 중간 화면 (HOW TO + `계산하기` CTA)
5. Result 화면 박스 제거 (좌측 1px line만)
6. Achievement 9배지 MVP + Hidden Legendary 3개
7. Trends 컴팩트화 (NEXT + MOMENTUM)
8. Profile 정리 (Tier 한 줄 · Category Tiers · RECENT RECORDS · MY BOX · Achievements)
9. Box 기능 (코치 WOD 게시 + 멤버 승인) — 로컬만
10. 카테고리 Tier 매핑 버그 수정 (`_category_dict`에 `number` 필드 추가)

---

## 페르소나 10명 요지

### Tier A: Scaled~RX 진입 (P1~P3)
| 코드 | 핵심 반응 |
|---|---|
| **P1 Min** (Scaled 1년차) | 2단계 Detail 부담. Achievement collapsed 동기 약함. Games Amanda .45(135lb)는 "딴 세상"으로 인식. Calc row 단조. |
| **P2 Yoon** (RX 진입) | 원클릭 기대. Detail 불필요. Achievement 펼쳐야 진행률 보이는 것 문제. WOD 탭에 Today's WOD 상단 노출 필요. |
| **P3 Daehyun** (전환기) | Detail은 유용. Achievement는 "보조". "RX Standard까지 N점 부족" 진행도 요구. Box는 지역/지도 필터 필수. |

### Tier B: RX·RX+ 중견 (P4~P6)
| 코드 | 핵심 반응 |
|---|---|
| **P4 Jiho** (RX 3년차) | **Trends 카테고리 breakdown 제거 불만**. 약점 식별 불가. Result 박스 제거 후 BURST 빠른 인식 약함. Detail 반복 사용 시 지연. |
| **P5 Hana** (RX→RX+) | Games 카테고리 최고. 그러나 "역사" 프레임 → "진입 경로/벤치마크" 재프레임 필요. Achievement는 Legendary를 "Regionals 진입 가능 신호" 같은 현실 맥락으로. |
| **P6 Sangwoo** (RX+ 정체기) | **Trends 컴팩트는 최악**. 카테고리 breakdown 복원 P0. Games는 낮은 관심 (동기 아님). Detail 긍정 (WHY 설명). |

### Tier C: Elite/Games/Masters (P7~P10)
| 코드 | 핵심 반응 |
|---|---|
| **P7 Minho** (Elite) | Games 긍정. Hidden Legendary 자극 OK. **매년 Games WOD 자동 업데이트 파이프라인** 요구. Box는 이미 자기 코치 있어 무관심. |
| **P8 Dara** (Games 지망) | **가장 긍정적 페르소나**. Games + Achievement + Box 전부 호응. Result 박스 제거 후 정보 밀도 감소만 아쉬움 — 폰트 키우기로 보완. |
| **P9 Chulsoo** (Masters 54, 시력 약) | 자간 복원 OK. Calc row 약함 (divider 두께 · 배경색 필요). Achievement 한글 부제 필수. Detail은 "검증 후 실행" 안심 경로로 긍정. |
| **P10 Hyejin** (Masters 48) | 배지 한글 의역 필수 ("Complete Athlete" → "전 종목 마스터"). 나머지는 P9와 동일. |

---

## 분류 · 우선순위

### P0 CRITICAL (즉시 반영 — 사용자 이탈 리스크)

| # | 항목 | 출처 | 방향 |
|---|---|---|---|
| P0-1 | **Trends 카테고리 breakdown 복원** | P4·P5·P6 전원 | 카테고리 5개 mini sparkline 부활 or Profile CATEGORY TIERS 즉시 링크 추가 (Trends 하단 "See breakdown → Profile" 핫버튼) |
| P0-2 | **Result 박스 제거 후 BURST 구분 강화** | P4·P5·P8 | 1px line 유지 + 분할 숫자 폰트 한 단계 키우기 (h1 44sp → h1 48sp) or 여백·accent 병행 |
| P0-3 | **Achievement 한글 부제 추가** | P9·P10 Masters | 카탈로그 description을 영문 부제 + 한글 1줄 조합 (예: "Complete Athlete · 전 종목 80점 돌파") |

### P1 HIGH (다음 Sprint 권장)

| # | 항목 | 출처 |
|---|---|---|
| P1-1 | **Calc row 시각 강조** (divider 0.5→1px · surface 배경색 옵션) | P9·P10 |
| P1-2 | **Games 카테고리 프레임 재설계** — "역사" → "진입 경로/벤치마크" 카피 | P5 Hana |
| P1-3 | **2단계 Detail 선택적 토글** — "HOW TO 보기" + 빠른 재계산 경로 | P2·P4 |
| P1-4 | **Achievement collapsed 첫 진입 시 미리보기** (해금 1~2개 항상 노출) | P1 Min |
| P1-5 | **WOD 탭 상단에 Today's WOD 섹션** (가입자) / **Find Box CTA** (미가입자) 명시화 — Box와 Calc 통합감 | P2 Yoon |
| P1-6 | **Games WOD 연간 자동 업데이트 파이프라인** — 공식 공개 후 7일 내 seed JSON 갱신 | P7 Minho |
| P1-7 | **"다음 Tier까지 N점 부족" 진행도** (Tier progression bar) | P3 Daehyun |

### P2 MEDIUM (여유 시)

| # | 항목 |
|---|---|
| P2-1 | Box 검색 시 지도·지역 필터 (강남/강북 등) |
| P2-2 | Preset 즐겨찾기 (반복 사용자 빠른 재계산) |
| P2-3 | Games WOD 상세에 "진입 조건" 명시 (어느 Tier면 RX 도전 가능) |

---

## 충돌 결정

### D1. Trends 컴팩트 vs 정보 밀도
- **상황**: P4/P5/P6은 카테고리 breakdown 복원 요구, P9/P10은 단순화 선호
- **권장**: **Trends 내 카테고리 breakdown 복원**하되 **기본 collapsed** (Masters 부담 완화). 탭하면 펼쳐 5개 mini sparkline 노출. Profile CATEGORY TIERS와 링크 유지.

### D2. Result 박스 제거 유지 vs 복원
- **상황**: P4/P5는 "구분력 약함"이나, 사용자가 직접 "그리드 촌스럽다"고 지적했던 맥락 있음
- **권장**: **박스 제거 유지**. 대신 분할 숫자 크기 상향(h1 44→48sp) + BURST 세그먼트 accent line 2px→3px 강화.

### D3. 2단계 Detail 필수 vs 선택적
- **상황**: P1/P3/P9/P10 긍정 (안심·학습), P2/P4 부정 (반복 지연)
- **권장**: **첫 회 필수 유지**, 재사용 시 **"바로 계산" 스위치** Profile 설정에 추가. 사용자 선택권.

---

## 반영 시 Sprint 구성안

### Sprint 5a (이번 사이클 연장 가능)
- P0-1: Trends 카테고리 breakdown 복원 (collapsed 기본)
- P0-2: Split 숫자 폰트 상향 + BURST accent 강화
- P0-3: Achievement 한글 부제 (9배지 카탈로그 seed 업데이트)

### Sprint 5b (다음 세션)
- P1-1: Calc row divider 강화
- P1-5: WOD 탭 상단 Today's WOD · Find Box 통합
- P1-4: Achievement collapsed 미리보기

### Sprint 6+
- P1-2: Games 카테고리 재프레임
- P1-3: Detail 선택적 토글
- P1-7: Tier progression bar
- P2-1: Box 지도 검색

---

## 가장 큰 통찰

1. **Trends 단순화 과도**: "깔끔함" 요구에 따라 카테고리 breakdown 잘랐으나 RX+ 정체기(Sangwoo)의 **핵심 사용 목적** 파괴. 향후 단순화는 "접기 가능" 전제로만.

2. **Games 카테고리 프레임 미스매치**: Hana/Dara 같은 지망자에겐 "진입 경로", Minho 같은 Elite에겐 "참고 벤치마크", Sangwoo/Min 같은 하위엔 "딴 세상". 단일 프레임 불가 → 카드별로 맥락 제공 필요.

3. **Masters 접근성이 체계적으로 저평가됨**: 자간 복원은 올바른 방향이었으나 Calc row / Achievement 영문은 여전히 벽. 한글 의역 + divider 강조로 포용.

4. **Box 기능의 진짜 가치는 "박스와 앱의 통합감"**: 현재 Box는 "옵셔널 기능" 인식. WOD 탭 상단 노출로 중심 가치로 승격 필요.

---

## 관련 문서
- 이전: `docs/PERSONA_FEEDBACK_v1.15.3.md`
- CF Games 리서치: `docs/CF_GAMES_WODS_2021_2025.md`
- 게이미피케이션 설계: `docs/GAMIFICATION_v1.16_PROPOSAL.md`
- 브랜드 SSOT: `CLAUDE.md`
