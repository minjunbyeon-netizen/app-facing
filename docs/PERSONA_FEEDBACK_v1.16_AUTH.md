# Persona Feedback — v1.16 Auth · Signup Flow (2026-04-24)

> **Scope**: SignupScreen + AuthState + Profile 로그아웃 기능.
> **Source**: `/go` 파이프라인 3-agent 페르소나 시뮬레이션.
> **상위 SSOT**: `docs/PERSONA_FEEDBACK_v1.16.md`

---

## 변경 요약

- `SignupScreen` (Naver 녹색 / Kakao 노랑 버튼 2개 · 데모)
- `AuthState` (SharedPreferences 기반 로컬 플래그)
- Splash 라우팅: 비로그인 → /signup, 로그인 + grade 없음 → onboarding
- Profile Actions: 로그인 상태 표시 + Sign out 버튼 (프로필 유지)

---

## 페르소나 10명 요지

### Tier A — Scaled/RX 진입 (P1~P3)
| 코드 | 핵심 반응 |
|---|---|
| **P1 Min** | 카카오 친숙 · 데모 캡션 무시 · 녹/노랑이 "저렴 이벤트 앱" 느낌 |
| **P2 Yoon** | 네이버 선호(보안) · 약관 부재 의심 · OAuth 자체는 OK |
| **P3 Daehyun** | 의심 많음 · "이 앱 누가 만든 거?" · 이메일 옵션 강력 요구 |

### Tier B — RX/RX+ 중견 (P4~P6)
| 코드 | 핵심 반응 |
|---|---|
| **P4 Jiho** (BTWB 사용) | **Google + Apple 필수** · 기기간 동기화 부재 = 이탈 요인. 경쟁 앱 대비 4/10 |
| **P5 Hana** (경기 지망) | **Google 필수**(글로벌). 로컬 전용 = "캐주얼 앱". 3/10 |
| **P6 Sangwoo** (5년차) | **이메일 + 비밀번호 필수** · "5년 데이터 잃기 싫음" · 클라우드 백업 없으면 거부. 2/10 |

### Tier C — Elite / Games / Masters (P7~P10)
| 코드 | 핵심 반응 |
|---|---|
| **P7 Minho** (Elite) | 2초 가입 OK. 데모 수용. 향후 클라우드 백업 원함 |
| **P8 Dara** (Games 지망) | 2초 OK. **Instagram/SNS 공유 기대** (Tier/Score 카드) |
| **P9 Chulsoo** (Masters 54, 시력 약) | `"Sign out"` 영문 부담 · **Kakao 노랑 명도 대비 부족 (WCAG AA 미달)** |
| **P10 Hyejin** (Masters 48) | 한글 선호 · 약관 부재 불안 · 카카오 선호 (톡 친숙) |

---

## 분류 · 우선순위

### P0 CRITICAL (즉시 반영 권장)

| # | 항목 | 출처 | 조치안 |
|---|---|---|---|
| P0-1 | **`Sign out` → `로그아웃` 한글화** | P9·P10 Masters | Profile Actions Sign out 버튼 + 다이얼로그 제목 한글 전환 |
| P0-2 | **OAuth 선택지 확장** (최소 Google + 이메일 fallback) | P4·P5·P6 전원 | Phase 2에서 Google + Apple SDK 연결. MVP에서는 **이메일 placeholder 버튼** 1개 추가 검토 |
| P0-3 | **약관·개인정보 링크** 명시 | P2·P3·P9·P10 | Signup 하단에 `이용약관 · 개인정보처리방침` 2줄 링크 (데모용 placeholder도 OK) |

### P1 HIGH

| # | 항목 | 출처 |
|---|---|---|
| P1-1 | Kakao 버튼 텍스트 색상 명도 대비 WCAG AA 확인 · 조정 | P9 |
| P1-2 | "데모" 캡션 → 하단 "Beta · Preview" 배지로 재프레이밍 | P1·P3 |
| P1-3 | 기기간 동기화 부재 명시 + Phase 2 로드맵 1줄 | P4·P5·P6 |
| P1-4 | 계정 마이그레이션 절차 문서화 (익명 device_id → provider 바인딩) | P6 |
| P1-5 | SNS 공유 카드 (Tier/Score) | P8 Dara |

### P2 MEDIUM

| # | 항목 |
|---|---|
| P2-1 | Sign out 확인 다이얼로그에 "로컬 저장 유지" 다이어그램 1줄 |
| P2-2 | 이메일+비밀번호 정식 옵션 (Phase 2) |
| P2-3 | 클라우드 백업 (Google Drive · Firebase) |

---

## 핵심 인사이트 (3줄)

1. **OAuth 2개로 부족**: Naver/Kakao만으론 RX+ 이상 중견 사용자 기준 미달. Google·Apple·Email 중 1개는 P0. 국내 선수·한국 박스 대상이면 Naver/Kakao 유지 OK, 글로벌 지망(Hana) 포함하려면 Google 필수.

2. **"데모" 표기의 역설**: P1 Min은 읽지도 않고, P2 Yoon은 신뢰 ↑, P3 Daehyun은 의심 ↑, P6 Sangwoo는 이탈 요인. 단일 캡션으로는 양극 반응. **"Beta · Preview" 배지 + 정식 출시 로드맵 링크**가 더 효율적.

3. **한국 박스 포지셔닝 vs 글로벌 지망**: Naver/Kakao 2개는 **한국 박스 중심 포지셔닝**엔 정확. 하지만 Games 지망 선수(Hana/Dara)는 Google 통일 필수 → 두 페르소나 타깃 분리 시점 필요.

---

## 충돌 결정

### D1. `Sign out` 한글 vs 영문
- **상황**: CLAUDE.md V8 `단어 1개 라벨 = 영문 단독 + 마침표 없음`. 하지만 P9/P10 Masters 접근성 요구.
- **권장**: 한글 `로그아웃` 전환. 이유: Sign out은 국내 앱 표준이 한글. V8 원칙의 "영문 단독"은 브랜드 표현(PROFILE/TRENDS 같은 시스템 라벨)에 적용, 일반 행동 동사는 한글 병기 검토 여지. Masters 포용 우선.

### D2. OAuth 확장 우선순위
- **상황**: Google vs Apple vs Email 중 하나 선택해야 함 (MVP 확장 범위)
- **권장**: **Google 먼저** — P5 Hana(경기 지망, 글로벌) 타깃 + Android 앱 기본 연동 용이성. Apple은 iOS 릴리즈 시점에 동시. 이메일은 Phase 2.

### D3. 데모 표기 유지 여부
- **상황**: P1 무시 / P2 도움 / P3 의심 / P7 수용
- **권장**: **유지 + 표현 개선**. `(데모 — 버튼 탭 즉시 가입 처리)` → `Beta Preview · 출시 시 실제 OAuth 연결`. 신뢰 구축.

---

## 경쟁 앱 대비 평가 (RX+ 기준)

| 앱 | OAuth | 동기화 | 백업 | Facing 대비 |
|---|---|---|---|---|
| BTWB | Apple·Google·Email | 웹+모바일 | JSON export | Facing 4/10 |
| Wodify | Email 중심 | 웹+박스 | 서버 저장 | Facing 3/10 |
| HWPO | Apple ID 단독 | iCloud | Apple 시스템 | Facing 비슷 |
| TrainHeroic | 다수 provider | 완전 동기화 | 서버 | Facing 3/10 |

**결론**: 로컬 전용 + 데모 상태로는 BTWB·Wodify에서 **이탈 유인 부족**. 최소 Google 추가 + 계정 마이그레이션 설계 완료 후 정식 출시 권장.

---

## 권장 반영 순서

### Sprint 6a (이번 사이클 반영 가능)
- P0-1: `Sign out` → `로그아웃` (5분)
- P0-3: 이용약관·개인정보 placeholder 링크 (10분)
- P1-2: `(데모 — ...)` → `Beta Preview · 정식 출시 시 OAuth 연결` 카피 교체

### Sprint 6b (다음 사이클)
- P0-2: Google Sign In SDK 연결 (Android 우선)
- P1-1: Kakao 버튼 WCAG AA 검증

### Sprint 7+
- Apple Sign In (iOS 릴리즈 시)
- 이메일 가입 옵션
- 계정 마이그레이션 절차
- 클라우드 백업

---

## 관련 문서
- 상위 SSOT: `docs/PERSONA_FEEDBACK_v1.16.md`
- 이전: `docs/PERSONA_FEEDBACK_v1.15.3.md`
- 브랜드 SSOT: `CLAUDE.md`
