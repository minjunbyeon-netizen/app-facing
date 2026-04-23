# PERSONA_FEEDBACK — v1.15 (2026-04-24)

> 페르소나 10명 × 9개 화면 × UX/UI 피드백 + 실코드 교차검증 SSOT.
> 작성: /go 파이프라인 (Haiku×3 페르소나 시뮬레이션 + Sonnet 코드 감사).
> 다음 반영 완료 시 `docs/archive/PERSONA_FEEDBACK_v1.15.md`로 이동.

---

## 1. 페르소나 10명

### Scaled / RX 진입권 (P1~P3)
| ID | 프로필 | 디바이스 | 우려 요소 |
|---|---|---|---|
| **P1** | 남 27, CrossFit 2년, Scaled→RX. 78kg/179cm. IT 개발자. 영어 중급 | Galaxy S22 | 데이터 근거, 속도 |
| **P2** | 여 34, 입문 6개월, Scaled. 62kg/165cm. 콘텐츠 크리에이터. 영어 초급 | iPhone 14 | 영문 라벨 혼동, "나 Scaled 맞나?" 불안 |
| **P3** | 남 42, 홈짐 1년, 재진입 베테랑. 92kg/182cm. 자영업 | Pixel 7a | 시간 효율, 저장 신뢰 |

### RX / RX+ 중견 (P4~P6)
| ID | 프로필 | 디바이스 | 우려 요소 |
|---|---|---|---|
| **P4** | 남 31, 4년차 RX, Fran 2:47. BS 160/CJ 105/Snatch 80. Notion 기록광 | Pixel 8 Pro | "내 숫자 맞나?" 검증 욕구 |
| **P5** | 여 29, 3년차 RX+, Fran 3:22. BS 90/Snatch 55. 인스타그램 운영 | iPhone 15 Pro | 비주얼 세련됨, 브랜드 안목 |
| **P6** | 남 38, 전직 해병, RX+ 상위, Regionals 경험. Fran 2:58 | Galaxy Z Fold5 | 폴더블 레이아웃, 정보 밀도 |

### Elite / Games / Masters (P7~P10)
| ID | 프로필 | 디바이스 | 우려 요소 |
|---|---|---|---|
| **P7** | 남 26, Elite, Regionals, Fran 2:08, Snatch 105. Wodify/PushPress 사용중 | iPhone 15 Pro | 경쟁 앱 대비 우위 증명 |
| **P8** | 여 27, Elite 상위, Rogue 스폰. 타이포·그리드 예민 | Galaxy S24 Ultra | HWPO/NOBULL 기준 통과 |
| **P9** | 남 45, Masters 40+, RX+ 챔피언, Games Masters 경험. CompTrain 사용 | Pixel 9 Pro | 노안 시작, 11sp 불편 |
| **P10** | 여 52, Masters 50+, Elite Masters. 손 떨림, 큰 활자 선호 | iPhone 15 Plus | 48dp 터치, 명암 대비 |

---

## 2. 통합 이슈 리스트 (P0/P1/P2)

### P0 — 진행 불가 (1건)

| # | 이슈 | 파일:라인 | 페르소나 영향 |
|---|---|---|---|
| **P0-1** | Loading 다이얼로그 `canPop:false` + 취소 버튼 없음. 네트워크 지연/장애 시 사용자 탈출 불가. Dio `receiveTimeout: 10s`만 의존 | `lib/features/onboarding/onboarding_benchmarks.dart:295-309`, `_ComputeLoadingDialog` 471-472 | 전원 (P3, P6, P7 명시적 불안) |

### P1 — 혼동·마찰·접근성 (15건)

| # | 이슈 | 파일:라인 | 영향 |
|---|---|---|---|
| **P1-1** | HapticFeedback 0건. 주요 CTA·Pill 토글·PageView 전환·Grade 공개 촉각 피드백 전무 | 전체 grep 0건 | 전원 |
| **P1-2** | 버튼 press scale 애니메이션 0건 + `splashFactory: NoSplash`. 시각 피드백 전무 | `lib/core/theme.dart:336` + 전체 | P5, P7, P8 (세련됨 실패) |
| **P1-3** | `Semantics`/`MergeSemantics` 0건. 스크린리더 사용 불가 | 전체 grep 0건 | 접근성 규정 위반 |
| **P1-4** | '모름' TextButton `minimumSize: Size(0, 28)` + `shrinkWrap` → 탭 영역 28dp × 21필드 | `onboarding_benchmarks.dart:554-560` | P2, P10 (떨림 손가락) |
| **P1-5** | kg↔lb 토글 후 이미 입력된 값이 재변환되지 않음. 143(kg)이 lb 모드에서 그대로 143 표시 | `onboarding_benchmarks.dart:430-434` | P4, P7 (숫자 정확도) |
| **P1-6** | TextField `labelText` 누락 × 26필드. `hintText`만 존재 → 포커스 시 맥락 손실 | `onboarding_basic.dart:74-104`, `onboarding_benchmarks.dart:575-600` | 접근성 + P2 혼동 |
| **P1-7** | 버튼 카피 3언어 전환: '계산 중'(한) / 'Measure Engine'(영) / 'Next'(영) 동일 버튼 | `onboarding_benchmarks.dart:395-399` | P7 (HWPO 기준 실패) |
| **P1-8** | Hero 배경 위 텍스트 가독성 미보장. Intro 상단 SVG + Grade 전체 opacity 0.35 | `intro_screen.dart:153-157`, `onboarding_grade.dart:62-67` | P5, P9, P10 |
| **P1-9** | `result_screen.dart` FutureBuilder unmounted setState 위험 + pacing API timeout 없음 | `pacing_result/result_screen.dart:30-44, 97` | 크래시 위험 |
| **P1-10** | Tier 색상 Elite(#C8A84B 금) / Games(#E8E8E8 실버) 다크 배경 위 명도 구분 약함. 카드 border 색 판별 어려움 | `theme.dart` tier 토큰 | P8 (브랜드 안목) |
| **P1-11** | Grade 카테고리 카드 내 micro 11sp 수치 만연 | `onboarding_grade.dart:173-182` | P9, P10 (노안) |
| **P1-12** | Voice V9 위반: "Split 뽑아라"(home headline), "첫 1분 all-out은"(intro 캡션 후보) 영-한 혼용 | `home_screen.dart:69`, `intro_screen.dart:24` | P7, P8 (브랜드 일관성) |
| **P1-13** | Onboarding 진행 비주얼 바 없음. "Step 1/6" 텍스트뿐. 6단계 심리적 길이 압박 | `onboarding_basic.dart` AppBar | P2 (이탈 우려) |
| **P1-14** | Benchmarks 저장 피드백 없음. PageView 전환 시 toast/snackbar 부재 | `onboarding_benchmarks.dart` onPageChanged | P3, P4 (신뢰도) |
| **P1-15** | Skip TextButton 기본 minSize(88×36). 히어로 우상단 misfire | `intro_screen.dart:91-96` | P10 |

### P2 — 미적·일관성 (10건)

| # | 이슈 | 파일:라인 |
|---|---|---|
| P2-1 | Quote 저작자 필드 미구현 (명언만 표시, "— Rich Froning Jr." 누락) | `lib/core/quotes.dart`, `quote_card.dart` |
| P2-2 | 'Start.' 헤드라인(Intro 3) vs 'Start' 버튼 동일 화면 공존 → 중복 | `intro_screen.dart:37, 122` |
| P2-3 | '← Back' 화살표 문자 혼용. Icon 위젯으로 분리 | `onboarding_benchmarks.dart:384` |
| P2-4 | 하드코딩 `fontSize: 12` / `TextStyle(color: ...)` 단독 3건 | `intro_screen.dart:94`, `onboarding_benchmarks.dart:567-568`, `result_screen.dart:241` |
| P2-5 | Stickman 3단계 라벨 부재. Motivation/Discipline/Obsession 명시 | `intro_screen.dart` 각 스텝 |
| P2-6 | Grade 카테고리별 점수 강조 약함. 전체 점수 대비 세부 카드 수치 미니 | `onboarding_grade.dart:95-110, 152-160` |
| P2-7 | WOD Builder 동작 선택 시 RX standard(95/65) 가이드 없음 | `wod_builder/movement_picker.dart` |
| P2-8 | Loading 예상시간/취소 버튼 부재 (P0-1과 연결, 디자인 측면) | `_ComputeLoadingDialog` |
| P2-9 | GoogleFonts 런타임 fetch. 오프라인 첫 실행 시 Bodoni italic 폴백 불명확 | `theme.dart` brandSerif/h1Serif |
| P2-10 | Galaxy Z Fold5 세로 접힘(6.2") 레이아웃 미검증 | 전체 레이아웃 |

---

## 3. 페르소나별 결정적 반응 (Top 3)

### 이탈 위험 (P2 · P10)
- **P2 (영어 초급)**: Intro 2 "6 metrics. Measure Engine." — "뭐가 6개야?" / Benchmarks 필드명 3단계 영문("Strict Pull-up Max UB") / Step 진행바 없어 6단계 공포 → **이탈 확률 40%**
- **P10 (Masters 시니어)**: '모름' 버튼 28dp × 21개 / micro 11sp / Games 배지 실버가 "타버린 느낌" → **앱 유지 불가**

### 경쟁 앱 전환 위험 (P7)
- **P7 (Wodify/PushPress 사용자)**: 영-한 혼용 카피가 신뢰도 깎음. "Split 데이터 정확도가 5% 나으면 쓸 텐데, 카피 일관성부터 안 되면 쓰지 말 것" → **Copy/Voice + pacing 근거(논문 링크) 필수**

### 브랜드 손상 위험 (P8)
- **P8 (Rogue 스폰, 브랜드 예민)**: Bodoni italic 컨셉은 HWPO 기준 통과. 그러나 Tier 색상 구분 실패 + Quote 저작자 누락(CompTrain 기준) + Hero opacity 0.35로 의도 불명확 → **"컨셉은 Elite, 실행은 70%"**

---

## 4. 권장 수정 순서 (예상 공수)

### Sprint 1 — P0 즉시 (1시간)
1. **P0-1 Loading 취소 구조** — `_ComputeLoadingDialog`에 "Cancel" 버튼 추가 + `api.post` `.timeout(Duration(seconds: 8))` 래핑 + `canPop: true` 전환. 취소 시 mounted 체크 후 snackbar "Cancelled."

### Sprint 2 — P1 Top 5 (반일)
2. **P1-7 버튼 카피 통일** — 'Calculating.' 단일 상태 (영문 단독, 마침표) + 'Next' 고정
3. **P1-13 LinearProgressIndicator** — AppBar 하단 `value: _currentStep / 6`
4. **P1-14 Save toast** — PageView onPageChanged 시 Snackbar "Saved" 1s
5. **P1-5 kg↔lb 재변환** — `UnitState.toggle()` 시 current text × 2.20462 또는 /2.20462 적용
6. **P1-4 '모름' 탭 영역** — `minimumSize: Size(double.infinity, 48)` + shrinkWrap 제거

### Sprint 3 — P1 접근성·피드백 (1일)
7. **P1-1/P1-2 Haptic + press scale** — 공용 `_PressScale` 래퍼 + `HapticFeedback.lightImpact()` on CTA
8. **P1-3/P1-6 Semantics + labelText** — TextField 26개 labelText 일괄 추가 + TierBadge/Pill Semantics wrap
9. **P1-11 micro→caption** — Grade 카드 수치 11sp → 13sp 승격
10. **P1-12 Voice V9** — "Split 뽑아라" → "Pull your Split.", 후보 카피 V9 검증 재쉐이크

### Sprint 4 — P1 가독성 (반일)
11. **P1-8 Hero 대비** — Grade에 `HeroBackground(darkenStrength: 0.6)` 래핑(Stack + gradient 추가)
12. **P1-10 Tier 색 재조정** — Elite `#E8C86B`(더 따뜻한 금), Games `#FFFFFF` (순백, 명도 최고) 또는 accent red border로 RX 차별화 강화
13. **P1-9 result_screen timeout + mounted** — `.timeout(8s)` + `if (!mounted) return` 가드
14. **P1-15 Skip minSize** — `minimumSize: Size(48, 48)` + padding

### Sprint 5 — P2 일관성 (선택)
15. Quote author 필드, Stickman 3단계 라벨, Bodoni 폴백 검증 등

---

## 5. HWPO/NOBULL 기준 평가 (v1.15 현재)

| 기준 | 평가 | 근거 |
|---|---|---|
| HWPO "Earn it." 명령형 | ✓ 7/10 | 헤드라인 영문·명령형 유지. 'Split 뽑아라' 2건 감점 |
| NOBULL 모노톤 미니멀 | ✓ 9/10 | 9토큰 + 5 tier. 단색 배경. 장식 제로 |
| Mayhem 수치 우선 | △ 6/10 | Score/Tier 명확. 카테고리별 수치 약함(P2-6) |
| CompTrain 근거 제시 | ✗ 5/10 | 추론 근거·논문 링크 미노출. Quote 저작자 누락 |
| **종합** | **7.3/10** | P0/P1 15건 해결 시 8.8+ 도달 |

---

## 6. 결론

- **컨셉(VISUAL_CONCEPT v1.0)은 Elite 수준**. Bodoni italic + halftone + stickman + hero 흑백 조합은 HWPO/NOBULL 기준 상위.
- **실행은 70%**. P0 1건 + P1 15건이 전원 이탈·접근성·신뢰도를 동시에 흔든다.
- **Sprint 1~3 완료 시 페르소나 10명 전원 "사용 유지" 예측**. Sprint 4까지 가면 P7(경쟁앱 사용자) 전환 가능.
- **Masters(P9/P10) 만족도가 11sp → 13sp 단일 변경으로 크게 상승**. 비용 대비 효과 최상.

### 검증 체크리스트 (Sprint 1~3 후)
- [ ] P2 페르소나: 6단계 온보딩 완주 (이탈 없이)
- [ ] P4: Grade 화면에서 카테고리 breakdown + 추론 근거 이해 가능
- [ ] P7: 영문 카피 일관성 + Loading 취소 가능
- [ ] P9/P10: 13sp 이상 · 48dp 이상 실기기 테스트
- [ ] Wodify/PushPress 대비 속도 측정 (Splash → Grade 30초 내)
