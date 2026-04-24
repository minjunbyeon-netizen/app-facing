# UX Questions — Full Categorized Map (v1.16)

> **Scope**: 페르소나 10명 원문 질문 344+개를 **19 카테고리로 재분류 · 중복 제거 · 문장 다듬음**.
> **원본**: `/go` 4-agent 출력 (Haiku×3 질문 생성 + Sonnet 분류).
> **요약본**: `docs/UX_QUESTIONS_v1.16.md` (별도).
>
> **표기**: `[페르소나 코드]` = 원 출처. `→ 화면` = 질문 발생 지점. `★` = 2명 이상 중복 제기.

---

## A. 회원가입·온보딩 허들

**핵심 멘탈모델**: 가치 증명 전에 개인정보 요구하면 벽으로 인식 · 첫 1분 안에 "이 앱 뭐지?" 해결 필요.

1. ★ 가입 없이 데모·체험판 쓸 수 있나? → Splash `[P1·P3]`
2. 이 앱이 뭐 하는 건지 첫 화면에서 즉시 이해되는가? → Splash `[P1·P3]`
3. Splash에서 '시작하기' 말고 자동 진입 옵션 있나? → Splash `[P7]`
4. 왜 바로 측정 못 하고 회원가입부터? → Splash→Signup `[P1·P3]`
5. 네이버·카카오가 각각 뭐고, 다른 점은? → Signup `[P1]`
6. ★ 카카오/네이버 로그인 시 앱이 정확히 뭘 가져가나 (카톡방·연락처도?) → Signup `[P1·P2]`
7. 개인정보취급방침·이용약관 어디? → Signup `[P2·P3]`
8. 회원탈퇴·비밀번호 재설정·로그아웃 각각 어디? → Settings `[P2·P7]`
9. 계정 연동 (Google·Apple·Email) 예정은? → Signup `[P4·P5·P7]`
10. Intro 3장 스킵했는데 다시 보기? → Home `[P7]`
11. Onboarding 6단계를 꼭 다 해야 하나? → Onboarding `[P1]`
12. 온보딩 중간 앱 종료해도 데이터 남나? → Onboarding `[P1]`
13. Skip 후 나중에 입력 가능? 유턴 경로는? → Onboarding `[P1]`
14. ★ 1RM을 모르는 동작은 건너뛸 수 있나? (필수/선택 명확?) → Step 1 `[P1·P2·P4·P6·P8]`
15. 1RM 추정값 입력 시 계산 신뢰도 표시되나? → Step 1 `[P4]`
16. 몸무게·키는 왜 필요하고 영향은? → Step 1 `[P1]`
17. 체중 2kg 변하면 매번 재입력? 자동 감지? → Profile `[P4]`
18. 1주일 전의 1RM 하나만 알면 계산 가능한가? → Step 1 `[P2]`
19. 1년 전 데이터 입력·소급 반영 가능? → Onboarding `[P3]`
20. ★ BTWB·Wodify 3~5년 데이터 Import? → Onboarding `[P4·P6]`
21. 여러 박스 소속 시 온보딩 반복? → Box `[P4·P5]`
22. Onboarding에서 분석 목표(약점/경기/기록) 선택 → 맞춤 UI? → Step 1 `[P5·P6]`
23. 경기 출전 목표 설정 시 전용 기능 제시? → Step 1 `[P5]`
24. CGM·HRV 연동 옵션? → Onboarding `[P8]`
25. 언어 설정(영/한) 전환 위치? → Settings `[P8·P10]`

---

## B. 진척·발전 기록

**핵심 멘탈모델**: "측정 → 비교 → 개선" 루프 기대. 단발 계산기 인식이면 방치.

1. ★ 운동한 거·Split 계산한 결과 어디에 자동 기록되나? → Shell `[P1·P2]`
2. ★ 지난번 대비 얼마나 나아졌는지 한눈에? → Trends/Profile `[전원]`
3. 주간/월간 Engine 변화를 차트로? → Trends `[P2·P4·P5]`
4. 특정 동작(Snatch 등) 최근 N회 기록 비교? → History `[P4]`
5. PR 갱신 시 자동 1RM 수정 제안? → Profile `[P4]`
6. 지난 5년 Fran 타임 라인차트? → Trends `[P6]`
7. 6개월 vs 1년 전 6개월 기간 동시 비교? → Trends `[P6]`
8. 내 카테고리별(POWER/OLYMPIC/...) progress 각각? → Profile radar `[P2]`
9. 월별 총 Engine 점수 변동 한눈에? → Trends `[P4]`
10. 매주 Engine 자동 변하나? 수동 갱신? → Grade `[P2]`
11. Fran 3:45 → 3:42 개선 시 Split 자동 재계산? → Grade `[P4]`
12. 경기 시즌 12주 전부터 '시즌 준비 모드'? → Profile `[P5]`
13. 매주 '경기 준비도' 자동 점수? → Profile `[P5]`
14. 반복 기록한 같은 WOD 월별 시계열 개선? → History `[P6]`
15. 수동 리프팅 vs 맨몸 동작 별도 그룹 추이? → Trends `[P6]`
16. 5년 가장 많이 개선된 카테고리 자동 분석? → Trends `[P6]`
17. WOD 한 건 기록 타이밍 언제? (자동/수동?) → WOD `[P2·P3]`
18. 계산한 Split 자동 저장? → Result `[P2]`
19. 최근 5개만 남나 전부 남나? → History `[P3]`
20. Benchmark 입력 후 자동 매년 재계산? → Profile `[P9]`
21. 1년 전과 지금 1RM 비교 뷰? → Profile `[P9]`
22. 박스 가입 후 초기 3개월 성장도 그래프? → Trends `[P9]`

---

## C. 비교·백분위·순위

**핵심 멘탈모델**: 절대 수치(Engine 82)보다 **상대 위치**("상위 몇 %")가 정체성.

1. ★ 내 Engine 점수가 전체 사용자 중 상위 몇 %? → Trends/Grade `[전원]`
2. ★ 우리 박스에서 나는 몇 등? → Profile/Box `[P1·P2·P4·P5]`
3. 전국 Scaled/RX/RX+/Elite 중 나는 몇 %? → Trends `[P1·P4·P5·P6]`
4. Fran 3:45가 전국 RX 기준 상위 몇 %? → Benchmark `[P4]`
5. 같은 박스 내 카테고리별 1등이 누구? → Box `[P2]`
6. 우리 박스 평균 Engine? → Box `[P2]`
7. 지역(서울/부산) 또는 전국 랭킹? → Trends `[P4]`
8. RX vs RX+ 별개 순위인가 통합? → Grade `[P4]`
9. 내 Engine 82가 높은지 낮은지 기준 명확? → Grade `[P4]`
10. 지역·나이·성별 세분 랭킹? → Trends `[P5]`
11. 전국 RX+ 여성 기준 내 Fran 3:20 상위 몇 %? → Benchmark `[P5]`
12. Open 결과와 앱 Engine 상관성? → Grade `[P5]`
13. 같은 박스 선후배(1년 전 나 vs 현재) 비교? → History `[P5]`
14. 전국 랭킹 Top 100 목록 열람? → Leaderboard `[P5]`
15. 같은 박스 다른 RX+ 남성 5명과 누적 Engine 월별 비교? → Box `[P6]`
16. 5년 전 나 vs 현재 나 Engine 비교? → History `[P6]`
17. RX+ 평균 Fran 3:15~3:25 범위라면 내 3:20 정확한 위치? → Benchmark `[P6]`
18. Elite 진입 위해 약한 카테고리 몇 점 올려야? (Gap Analysis) → Grade `[P6]`
19. 같은 5년 경력 RX+ 다른 사람들과 코호트 비교? → Trends `[P6]`
20. 작년 Games Top 10 평균 Engine vs 내 점수? → Trends `[P8]`
21. 같은 나이대(29세) 여성 Elite 사용자 통계? → Trends `[P8]`
22. Regionals 진출자들 Burst 평균? → Grade `[P8]`
23. 우리 박스 코치들 평균 Engine? → Box `[P8]`
24. Regionals 진입 Engine 최소 몇 점 (공시)? → Grade `[P7]`
25. 매달 이동평균(Momentum) 볼 수 있나? → Trends `[P7]`

---

## D. 게이미피케이션

**핵심 멘탈모델**: 외재적 보상 루프 기대. 배지만으로는 약하고 **레벨·혜택**까지 궁금.

1. ★ 배지가 뭐고 받으면 뭐가 좋아? → Trends `[P1·P3]`
2. 배지를 어떻게 받아? (조건 명확?) → Trends `[P1]`
3. ★ 레벨업은 없나? 있으면 뭐가 좋아? → Shell/Profile `[P1·P3]`
4. Hidden Legendary 배지는 뭐고 어떻게 해금? → Trends `[P1]`
5. 배지 15개 중 나는 몇 개 땄고 최대는? → Trends `[P4]`
6. 배지 해금 Push 알림 오나? → Settings `[P2·P4]`
7. 배지 완성 일시·스탬프? → Trends `[P2]`
8. 잠긴 배지 8개 해금까지 얼마나 필요? → Trends `[P2]`
9. Milestone 1개 완성 시 다음 자동 해제? → Attend `[P2]`
10. 매월 초기화되는 데이터? → Attend `[P2]`
11. 배지 나이·순서가 있나? (정식 레벨?) → Trends `[P3]`
12. 레벨 1~100 숫자 레벨링? → Profile `[P3]`
13. 마일스톤 달성 시 실제 혜택·상? → Attend `[P3]`
14. Streak 끊기면 복구 가능? (Freeze 아이템?) → Attend `[P3·P5]`
15. 월별 챌린지 있나? (예: 1개월 10회 WOD) → Events `[P4]`
16. 배지 SNS 공유 기능? → Q와 중복 `[P4·P8]`
17. '5년 기록' 같은 장수 배지? → Trends `[P6]`
18. 월별 챌린지가 '이번 달 약점 카테고리 집중'처럼 맞춤? → Events `[P6]`
19. 목표(예: 최고 Engine 갱신) 설정 시 진행도 시각화? → Profile `[P6]`
20. 부상에서 복귀 시 '복귀 기념' 배지? → Achievements `[P9]`
21. 꾸준히 하면 스트릭 배지? 무시? → Achievements `[P9]`
22. 암시적 성취(예: 3년 신가입) 배지? → Achievements `[P10]`
23. Games 진출 후 특별 배지? → Achievements `[P7]`
24. Leaderboard 1위 '이번 주 챔피언' 배지 자동? → Events `[P5]`

---

## E. 기능 발견성

**핵심 멘탈모델**: 숨겨진 기능은 없는 기능 · 탐색 없이 바로 찾아야.

1. WOD 탭에서 뭘 할 수 있는 거야? → WOD `[P3]`
2. Calc 탭에 왜 4분류? 각각 언제 써야? → Calc `[P3·P4]`
3. Girls/Heroes/Games 공식 이름? 자동 업데이트? → Calc `[P2·P3·P7]`
4. Custom 분류에서 내 WOD를 만들려면? → Calc Custom `[P2]`
5. Radar 5축이 뭐 의미? → Profile `[P1·P2·P4]`
6. Radar 중심값이 내 Engine과 다르면? → Profile `[P2]`
7. Recent가 뭐지? 필터링 가능? → Profile `[P1·P4]`
8. Body 탭에서 무게·키 변화 추이 시간 흐름? → Body `[P4]`
9. Settings에 숨겨진 기능 또 있나? → Settings `[P4]`
10. Engine radar 최하위 축 클릭 시 drill-down 분석? → Profile radar `[P6]`
11. 내가 자주 하는 WOD TOP 10 자동? → History `[P6]`
12. Profile 탭 5년 누적 시간·총 중량 통계? → Profile `[P6]`
13. Snatch 같은 특정 동작 전용 상세 페이지? → History `[P6]`
14. Custom WOD 저장 시 유사 WOD 추천? → Calc `[P6]`
15. 특정 카테고리(무게)만 집중 보는 필터? → Trends `[P5]`
16. 피드에서 타임스탬프(언제 계산)? → History `[P5]`
17. 박스별 WOD 난이도 기준 추천? → WOD `[P5]`
18. Calc 4분류 각각 언제 써야? (Selection Guide) → Calc `[P4]`

---

## F. 브랜드·톤 혼란

**핵심 멘탈모델**: 영문 단독 = 전문 브랜드 (긍정) / 낯섦 (부정). Scaled·Masters에 부정 비중 높음.

1. FACING이 뭔 뜻? → Splash `[P1]`
2. Games가 뭐야? (올림픽처럼 4년마다?) → Calc `[P1·P3]`
3. Elite가 뭐? Engine이 뭐? → Grade/Profile `[P3]`
4. RX+가 RX보다 쉬운 건가? → Grade `[P3]`
5. Metcon이 왜 자꾸 나와? → Calc `[P3]`
6. 앱 목적이 '게임 출전 준비'인지 '일반 피트니스'인지 헷갈림 → 전반 `[P4]`
7. 'Engine' 정의·사용설명서·논문 있나? → Settings `[P4]`
8. 앱 곳곳 '건강/체중관리' 일반 피트니스 톤 섞여있지 않나? → 전반 `[P4]`
9. 명언 전부 영문인데 번역·한글 명언도? → Splash/Grade `[P4]`
10. 버튼 라벨 일관성 (확인/다음/OK 혼재?) → 전반 `[P4]`
11. 'Games 출전자' 목표인데 앱이 일반 피트니스 톤 → 전반 `[P5]`
12. 경기/운동/트레이닝 용어 혼재? → 전반 `[P5]`
13. 앱 설명에 'Games 출전자 전용' 핵심이 명확? → Signup `[P5]`
14. 튜토리얼·Help에서 경기 특화 기능 먼저? → Help `[P5]`
15. 'Elite 진입 도구'로 마케팅되는데 실제 기능 충분? → 전반 `[P6]`
16. 5년 경력자에게 Onboarding 또 거치게 하는 게 어색 → Onboarding `[P6]`
17. Split/Burst/Engine/Tier 용어 자연스럽나, 변수명처럼 느끼나? → 전반 `[P6]`

---

## G. 데이터 신뢰 (계산 근거)

**핵심 멘탈모델**: 블랙박스 알고리즘 불신. Elite·Games일수록 검증 욕구 강함.

1. ★★ 내 Engine 82가 어떻게 계산돼? (공식·수식) → Grade `[전원]`
2. Split 계산 논문 기반이면 어떤 논문? → Result `[P2·P4]`
3. Burst point가 정말 과학적? → Result `[P2]`
4. 계산 오류면 보정·피드백 채널? → Settings `[P2·P4]`
5. 다른 앱(Beyond/TrainHeroic) 계산과 다르면? → Settings `[P2]`
6. 1RM 추정값 입력 시 신뢰도 낮음 표시? → Step 1 `[P4]`
7. Fran RX vs Scaled 구분 기능? → Input `[P4]`
8. BTWB 3년 기록과 앱 데이터 동시 분석? → History `[P4]`
9. 내 데이터가 다른 사용자 비교 계산에 몰래 쓰이나? → Privacy `[P4]`
10. RX vs RX+ 점수 산정 방식 상세 설명 페이지? → Help `[P5]`
11. 내 WOD 기록 정확하게 계산되는지 검증 방법? → Settings `[P5]`
12. 경기 스코어보드와 자동 동기화? → Events `[P5]`
13. 몸무게·최대치 수정 시 이전 기록 소급 재계산? → Profile `[P5·P6]`
14. 5년 누적 데이터 오류 자동 감지·수정? → History `[P6]`
15. BTWB 수입 데이터와 앱 직접 입력 데이터 신뢰도 동일? → History `[P6]`
16. 알고리즘 업데이트 시 이전 기록 소급? → Algorithm `[P6]`
17. 데이터가 통계(백분위 계산)에 몰래 쓰이고 있지 않나? → Privacy `[P6]`

---

## H. 사회적 요소 (코치·팀 제외)

**핵심 멘탈모델**: CrossFit은 커뮤니티 스포츠. 개인 앱이어도 사회적 맥락 기대.

1. 나를 초대코드로 친구에게 공유? → Profile `[P2]`
2. 친구랑 같은 WOD 하면 비교? → WOD `[P2]`
3. 박스 코치 게시 WOD만 보나 모든 WOD? → WOD `[P2]`
4. 우리 박스 사람들이 내 정보 볼 수 있나? → Privacy `[P3]`
5. 박스 사람들이 내 배지 볼 수 있나? → Privacy `[P3]`
6. 이름으로 검색? → Box `[P3]`
7. 나보다 높은 등급 사람들 1RM 참고? → Benchmark `[P3]`
8. 같은 약점 가진 다른 RX+ 극복 사례 참고? → Peer `[P6]`
9. 박스 그룹 챌린지 ('이번 달 누가 최다 기록')? → Events `[P5]`
10. 박스 커뮤니티 피드에서 다른 사람 배지·PR? → Feed `[P5]`
11. 경기팀 모집 커뮤니티? → Box `[P5]`
12. 48세 여성들끼리만 보는 그룹? → Box `[P10]`
13. 코치한테 주간 리포트 자동 전송? → Coach `[P10]`
14. 여성 전용 Challenge? → Events `[P10]`
15. 배우자·친구와 WOD 함께 계산 후 비교? → Shared WOD `[P10]`

---

## I. 동기부여·지속

**핵심 멘탈모델**: 앱이 훈련 루틴 일부가 되어야 지속 · 매일 열 이유가 있어야.

1. 매일 열 이유가 뭐야? → Home `[전원]`
2. 목표 설정 기능? → Profile `[P6·P10]`
3. 푸시 알림·리마인더? → Settings `[P4·P9]`
4. Streak 끊어지면 복구 가능? → Attend `[P3]`
5. 일주일에 한 번만 계산해도 데이터 축적? → Home `[P9]`
6. 2주 쉬었을 때 복귀 장려 메시지? → Push `[P9]`
7. 꾸준히 하면 스트릭 배지? 아니면 무시? → Achievements `[P9]`
8. 연중 자주 놓치는 카테고리 자동 알림? → Settings `[P9]`
9. 올해 목표(Elite 진입) 달성 추적? → Goals `[P9]`
10. 바쁜 40대 직장 여성도 짧은 시간에 계산? → Quick Mode `[P10]`
11. 박스 안 가던 달은 데이터 어떻게? → Gaps `[P10]`
12. 가족 여행 중 오프라인 계산? → Offline `[P10]`
13. 인생 처음 Games 꿈꾸는데 현실적 로드맵? → Coaching `[P10]`

---

## J. 용어 혼란

**핵심 멘탈모델**: 전문 용어 = 진입 장벽. Scaled·Masters에 집중 발생.

1. ★★ 1RM이 뭐야? → Onboarding `[P1·P9]`
2. Back Squat·Floor Press 같은 동작명이 뭐? → Step 2 `[P1]`
3. Benchmark이 뭐야? → Step 2 `[P1]`
4. Unbroken이 뭐? 그냥 완료와 차이? → Input `[공통]`
5. AMRAP·For Time 중 뭘 선택? 각 의미? → Calc `[공통]`
6. Split/Burst/Engine/Tier 정의? → Result/Profile `[공통]`
7. Metcon이 뭐? → Radar `[P3]`
8. Games/Elite/RX+ 정의? → Grade `[P1·P3]`
9. Sign out이 뭐야? (한글 없음) → Profile `[P9·P10]`
10. ← Back이 뭔 뜻? 한글로? → Navigation `[P10]`
11. 배지 영문 이름(Complete Athlete 등) 한글 풀이? → Trends `[P9·P10]`

---

## K. 기기간 동기화·백업

**핵심 멘탈모델**: 분실 공포. 데이터 영속성은 당연한 기대.

1. ★ 폰 바꾸면 데이터 넘어가나? → Settings `[P2·P3·P9]`
2. 아이폰으로 바꾸면? → Settings `[P2]`
3. 휴대폰 분실 시 데이터? → Settings `[P3]`
4. 같은 계정으로 여러 기기 접속? → Settings `[P3]`
5. BTWB 3년 데이터 한 번에 Import? → Onboarding `[P4·P6]`
6. 내 데이터 CSV/JSON export? → Settings `[P3·P7]`
7. 서버 백업 자동? → Settings `[P8]`
8. 내 5년 데이터 export해서 다른 앱으로 이사? → Settings `[P6]`
9. 앱 업데이트 때 데이터 날아가나? → Settings `[P3]`
10. 기존 데이터 지워도 복구 가능? → Settings `[P3]`
11. 느린 인터넷(3G)에서도 잘 돌아가나? → Network `[P9]`
12. 오프라인 모드? 여행 중 사용? → Network `[P10]`

---

## L. 프라이버시

**핵심 멘탈모델**: 신체 데이터 = 민감 정보. 공개 범위 명확하지 않으면 입력 거부.

1. ★ 카카오/네이버 로그인 시 앱이 가져가는 정보 리스트? → Signup `[P1·P2]`
2. 내 체중·1RM이 공개되나? → Privacy `[P2]`
3. 어떤 데이터가 서버에 저장되나? → Privacy `[P3]`
4. 내 성적을 비공개로? → Settings `[P3]`
5. 이름 검색 비공개? → Settings `[P3]`
6. 탈퇴하면 데이터 지워지나? → Settings `[P2·P3]`
7. 서버 해킹 시 개인정보? → Settings `[P3]`
8. 내 데이터가 통계에 몰래 사용? (익명 처리?) → Privacy `[P4·P6]`
9. Masters 나이 증명 필요한가? → Profile `[P9]`
10. 생리 주기 정보 서버 저장? → Profile `[P10]`

---

## M. 경기·이벤트 특화

**핵심 멘탈모델**: 시즌 중 앱 활용 극대화 기대 · 비시즌과 다른 UX.

1. CrossFit Open 자동 반영 + 스코어 입력? → Events `[P5]`
2. Regional 진출 기준 Engine 점수 공시? → Grade `[P5·P7]`
3. 시즌별 분석(Open→Regional→Games) 별도 탭? → Events `[P5]`
4. 12주 트레이닝 플랜 자동 추천? → Plan `[P5]`
5. Games 2025 공식 6 WOD 미리보기? → Calc `[P7·P8]`
6. 2024 Games 5등 Split vs 내 Split 비교? → Games `[P7]`
7. Games Open 시작 시 자동 알림? → Settings `[P7]`
8. Games WOD 연간 자동 업데이트 백엔드 파이프라인? → Calc `[P7]`
9. 옛날 Games WOD (2021~2023) 보관? → Calc `[P7]`
10. Games 각 WOD별 '우리 박스 평균 점수' 통계? → Games `[P7]`
11. Games 팀 전 동료 Split 합산? → Team `[P8]`
12. Games 진출 전 최종 Engine 기준? → Grade `[P8]`
13. Tia Toomey 같은 우승자 Split 분석? → Games `[P8]`
14. Post-Game: 실제 성적 vs Predicted Split 비교? → Games `[P8]`
15. Games 혼합팀(Mixed Team) WOD 분석? → Team `[P8]`
16. Regionals 당일 Walk 타이밍 Split? → Event Plan `[P8]`
17. Games 우승 경로별 Split 비교(산소부족 vs 장거리)? → Games `[P8]`

---

## N. 분석·진단 도구

**핵심 멘탈모델**: 숫자 하나가 아닌 구조적 진단 기대 · 특히 Sangwoo 등 정체기 유저 핵심.

1. ★ 내 약점 카테고리 어디? 자동 강조? → Radar `[P4·P5·P6·P7]`
2. 6개 지표 중 뭘 먼저 올려야? → Radar `[공통]`
3. '약점은 스태미나' 자동 진단 코멘트? → Insights `[P4]`
4. 주간 Performance 추이 자동 분석? → Trends `[P8]`
5. 약점 강화 루틴 추천? → Insights `[P8]`
6. Burst point 나타나는 패턴? → Result `[P8]`
7. 이번 주 vs 지난주 Engine 델타? → Trends `[P8]`
8. 카테고리 불균형도 점수화? → Radar `[P8]`
9. CGM/HRV 데이터와 Performance 상관관계? → Advanced `[P8]`
10. 매주 Tier 진입 가능성 자동 계산? → Progress `[P8]`
11. 매주 약점 분석 리포트 이메일? → Settings `[P7]`
12. Engine curve 재벌/상승세 AI 분석? → Trends `[P7]`
13. **약점이 뭔지만이 아니라 '왜' 약한지 이유 분석?** → Root Cause `[P6]`
14. 약점 극복 '이런 동작 집중' 처방 피드백? → Prescriptive `[P6]`
15. 3개월 약점 중심 WOD 후 개선 정도 수치화? → Tracking `[P6]`
16. 5년 데이터 계절별 패턴 감지 → 시즌 전략? → Seasonal `[P6]`
17. 약점 개선 기간 추정 → 'Elite 진입 가능 시점' 예측? → Predictive `[P6]`
18. 추이 보면 5년 더 해도 Elite 불가라는 솔직한 진단? → Honest `[P6]`
19. 부상·퇴행성 있을 때 보정·대체 동작? → Medical `[P9]`

---

## O. Masters 접근성 (글씨·색·청각·손떨림)

**핵심 멘탈모델**: 읽을 수 없으면 기능 자체가 무의미. 완전한 사각지대.

1. ★ 폰트 크기 14pt 이상 확대 가능? → Settings `[P9·P10]`
2. 다크 모드 외 라이트 모드? → Settings `[P9]`
3. 한글 설명 전면 추가? → 전반 `[P9·P10]`
4. '모름' 버튼 크기 더 크게? → Step 1/2 `[P9]`
5. VoiceOver/TalkBack 화면 읽기? → Accessibility `[P9]`
6. 손떨림 시 탭 판정 시간 증가? → Settings `[P9]`
7. 음성 입력? → Input `[P9]`
8. 화면 밝기 자동 조절 (눈 피로)? → Settings `[P9]`
9. Onboarding 5단계 너무 길지 않나? → Flow `[P9]`
10. 색약(적록색약) 대응? 색상만 구분 금지? → Design `[P10]`
11. 폰트 굵기 옵션? → Settings `[P10]`
12. 터치 반응 속도 조정? → Settings `[P10]`
13. 한 화면 정보 과다 시 스크롤? → Layout `[P10]`
14. 실수 탭 '되돌리기' 가능? → Undo `[P10]`
15. 한글 직접 입력(가나다) 필드? → Input `[P10]`

---

## P. 연령별 보정·기준

**핵심 멘탈모델**: 동일 기준 적용은 불공정. 연령 집단 내 상대 위치가 의미.

1. ★ 54/48세인데 Tier 기준이 30세와 같나? → Grade `[P9·P10]`
2. Masters 카테고리별 기준 점수? → Grade `[P9]`
3. 나이별 Engine 곡선? → Trends `[P9]`
4. Benchmark(1RM)를 나이별로 설정? → Step 2 `[P9·P10]`
5. Masters 인증(나이 증명) 필요? → Profile `[P9]`
6. 50대 이상 별도 커뮤니티? → Box `[P9]`
7. 부상 이력 보정? → Profile `[P9]`
8. 퇴행성 질환 있을 때 대체 동작? → WOD `[P9]`
9. 수술 재활 중 Volume 자동 조정? → WOD `[P9]`
10. 고혈압 약 복용 중 권장 Intensity? → Medical `[P9]`
11. 48세 Benchmark 기준 35세와 다른가? → Step 2 `[P10]`
12. 생리 주기 영향 고려? → Profile `[P10]`
13. 중년 여성 특화 운동 추천? → WOD `[P10]`
14. 근력 저하 '나이 탓'인지 '훈련 부족'인지 진단? → Insights `[P10]`
15. 폐경 이후 호르몬 변화 반영? → Profile `[P10]`
16. 같은 48세 여성 Masters와 비교? → Benchmark `[P10]`
17. 나이 들수록 Recovery 타임 증가? → WOD Rest `[P10]`
18. 고관절·무릎 경직 시 Mobility 추천? → WOD Mod `[P10]`
19. 야간 운동 vs 아침 운동 차이? → Trends `[P10]`
20. 골다공증 위험 시 고충격 제한? → Medical Alert `[P10]`

---

## Q. SNS·공유·연동

**핵심 멘탈모델**: 결과 = 증명 · 공유 가능할 때 사용 동기 상승.

1. 결과 카드 이미지 저장? → Result `[P8]`
2. 인스타에 바로 공유? → Result `[P8]`
3. Strava 연동? → Settings `[P8]`
4. Tier/Score 스크린샷 Instagram 태그? → Profile `[P8]`
5. 내 성적 가족에게 WhatsApp 공유? → Share `[P10]`
6. 배지 SNS 공유 기능? → Trends `[P4·P5·P8]`
7. CGM·HRV 데이터 연동 (Whoop/Oura)? → Settings `[P8]`
8. Apple Health·Google Fit 연동? → Settings `[공통]`
9. 대회 스코어 링크 공유? → Events `[P5]`
10. 공유 카드 디자인 Tier별 다름? → Share `[P8]`

---

## R. 코치·팀 연동 (신규)

**핵심 멘탈모델**: 개인 데이터 → 코치 피드백 루프가 훈련 개선의 실제 경로.

1. 코치한테 내 Engine 리포트 보낼 수 있나? → Box `[P5·P7]`
2. 코치 대시보드(팀원 여러 명 관리 뷰)? → Box `[P5]`
3. 박스 내 팀 대시보드? → Box `[P5·P8]`
4. 코치 승인 대기 상태 확인? → Box `[P5]`
5. 코치 WOD 게시 시 멤버 알림? → Push `[P5]`
6. 코치가 개인 프로그램 맞춤 작성? → Coach `[P5]`
7. 코치와 주간 리포트 자동 공유? → Coach `[P10]`
8. 코치 피드백 코멘트 달 수 있나? → Feed `[P5]`

---

## S. WOD 빌더 UX (신규)

**핵심 멘탈모델**: 매번 처음부터 입력하는 마찰 쌓이면 포기.

1. ★ 동작 리스트 너무 길어 검색? → Builder `[공통]`
2. ★ kg ↔ lb 토글 어디? 세션 기억? → Builder `[공통]`
3. 자주 쓰는 WOD 저장·즐겨찾기? → Builder `[P4·P8]`
4. Custom WOD 저장 후 복붙? → Builder `[P7·P8]`
5. 같은 동작 2번 쓸 수 있나? (Thrusters 2번) → Builder `[P7]`
6. 부상 시 대체 동작 제안? → Builder `[P7]`
7. 팀 WOD(2인/3인) 지원? → Builder `[P7·P8]`
8. Benchmark 저장 후 WOD에서 재사용? → Builder `[P7]`
9. WOD 조정 즉시 Split 재계산? → Builder `[P8]`
10. 쌍둥이 WOD(Ascending/Descending) 비교? → Builder `[P8]`
11. 내 WOD 히스토리 검색·필터? → History `[P8]`
12. Custom WOD 저장 시 유사 WOD 추천? → Builder `[P6]`

---

## 카테고리별 수치 요약

| # | 카테고리 | 원문 중복 제거 후 질문 수 | 우선순위 (이탈 기준) |
|---|---|---|---|
| A | 회원가입·온보딩 허들 | 25 | **P0** |
| B | 진척·발전 기록 | 22 | **P1** |
| C | 비교·백분위·순위 | 25 | **P1** |
| D | 게이미피케이션 | 24 | P2 |
| E | 기능 발견성 | 18 | P1 |
| F | 브랜드·톤 혼란 | 17 | P1 |
| G | 데이터 신뢰 | 17 | **P0** (Elite) / P2 (Scaled) |
| H | 사회적 요소 | 15 | P2 |
| I | 동기부여·지속 | 13 | P1 |
| J | 용어 혼란 | 11 | **P0** |
| K | 기기간 동기화 | 12 | P1 |
| L | 프라이버시 | 10 | P1 |
| M | 경기·이벤트 | 17 | P1 (Elite/Games) |
| N | 분석·진단 | 19 | **P1** |
| O | Masters 접근성 | 15 | **P0** (Masters) |
| P | 연령별 보정 | 20 | **P0** (Masters) |
| Q | SNS·공유 | 10 | P2 |
| R | 코치·팀 (신규) | 8 | P2 |
| S | WOD 빌더 UX (신규) | 12 | **P0** |
| — | **합계** | **310개 (중복 제거 후)** | — |

원문 344+ → 중복 제거·통합 → **310 유니크 질문**으로 정리.

---

## 가장 자주 반복된 질문 Top 15 (빈도 순)

| 순위 | 질문 | 카테고리 | 출처 |
|---|---|---|---|
| 1 | 내 점수 계산 근거·공식·논문? | G | 전원 |
| 2 | 1RM/Benchmark 모르는 항목 건너뛰기? | A·J | P1·P2·P4·P6·P8 |
| 3 | 지난번 대비 얼마나 늘었나? | B | 전원 |
| 4 | 박스·전국에서 나는 상위 몇 %? | C | P1·P2·P4·P5·P6 |
| 5 | 폰 바꾸면 데이터 유지? | K | P2·P3·P9 |
| 6 | BTWB/Wodify Import? | A·K | P4·P6 |
| 7 | 영문 용어(1RM·AMRAP·Unbroken) 뜻? | J | P1·P9·P10 |
| 8 | Sign out·Back 영문 한글로? | J·O | P9·P10 |
| 9 | 레벨업 있나? 배지 혜택? | D | P1·P3 |
| 10 | Masters 연령 기준 30세와 다른가? | P | P9·P10 |
| 11 | 내 약점 카테고리 자동 진단? | N | P4·P5·P6·P7 |
| 12 | 카카오/네이버 로그인 시 가져가는 정보? | A·L | P1·P2 |
| 13 | 프라이버시 정책·탈퇴? | A·L | P2·P3 |
| 14 | 결과 카드 SNS 공유? | Q | P4·P5·P8 |
| 15 | Games WOD 연간 자동 업데이트? | M | P7·P8 |

---

## 디벨롭된 우수 질문 Top 10 (원문 기반 확장)

원문이 인상적이었던 것들을 디벨롭한 "가장 좋은 질문" Top 10 — 앱 설계 시 **나침반** 역할.

1. **"내 약점이 뭔지만이 아니라 '왜' 약한지 이유 분석해 주나?"** — 원문(P6) · **근본 차별점**. 진단 도구에서 처방 도구로 진화 필요.
2. **"5년 더 해도 Elite 못 든다는 솔직한 진단도 가능한가?"** — 원문(P6) · 앱의 신뢰성 극한 테스트.
3. **"전국 RX+ 여성 내 Fran 3:20 상위 5% 수준인지?"** — 원문(P5) · 백분위 + 성별·연령 세분 필요.
4. **"Tia Toomey 같은 Games 우승자 Split vs 내 Split 비교?"** — 원문(P8) · Games 벤치마크 레퍼런스화.
5. **"Games WOD 연간 자동 업데이트 파이프라인은?"** — 원문(P7) · Sprint 7 이후 필수.
6. **"경기 시즌 12주 전부터 '시즌 준비 모드' 자동 활성화?"** — 원문(P5) · 맥락 인식 UX.
7. **"1RM 추정값 입력 시 '신뢰도 낮음' 표시되나?"** — 원문(P4) · 데이터 품질 투명성.
8. **"5년 데이터 계절별 패턴 감지 → 시즌 전략 추천?"** — 원문(P6) · 장기 사용자 가치.
9. **"부상 이력 입력 시 Tier 기준 자동 보정?"** — 원문(P9) · Masters·재활 포용.
10. **"알고리즘 업데이트 시 이전 기록 소급 재계산되나, 버전별 분리?"** — 원문(P6) · 장기 사용자 신뢰.

---

## P0 핵심 5건 (이탈 즉시 차단 · 카테고리 합집합)

| # | 항목 | 카테고리 | 이탈 위험 페르소나 |
|---|---|---|---|
| P0-1 | **용어 툴팁 시스템** (1RM·AMRAP·Unbroken·Metcon·RX+ 등 12 용어) | J | P1·P9·P10 Scaled·Masters |
| P0-2 | **계산 근거 Rationale 노출** (수식 + 지표 기여도 % + 논문 링크) | G | P2·P4·P6·P8 |
| P0-3 | **Masters 연령 필드 + Tier 기준 보정** (35+/45+/55+ 자동 분류) | O·P | P9·P10 전원 |
| P0-4 | **WOD 빌더 검색 + kg/lb 세션 기억** | S | 전원 |
| P0-5 | **Signup 약관·개인정보·이메일 옵션** | A·L | P2·P3·P9·P10 |

---

## 메타 통찰 (4개)

1. **P0 항목 5개 중 3개가 "첫 10분" 안에 발생** (A·J·S): Scaled·Masters 페르소나의 첫 세션 이탈률이 앱 성패 좌우. Sprint 7a는 **Onboarding + Builder 집중**이 맞음.

2. **Elite/Games vs Masters 요구가 극단 대립**: Elite는 "정보 밀도·자동화·SNS 연동" (P8 Dara), Masters는 "한글·폰트 확대·연령 보정" (P9·P10). 한 앱에 담으려면 **세그먼트 스위치** 필요 (Onboarding에서 목표 선택 → UI 차별화).

3. **Sangwoo(P6) 같은 '정체기' 페르소나의 질문이 가장 깊음**: "약점 왜?", "5년 더 해도 Elite 못 들면?", "알고리즘 버전 변경 시 소급?" — 장기 사용자 가치를 정의. 이 3개만 제대로 답해도 **경쟁 앱 대비 차별화 완성**.

4. **코치·팀(R) 카테고리는 B2B 레버리지**: P5 Hana, P7 Minho가 "코치 대시보드" 반복 언급. 개인 앱 → 박스 단체 도입 전환점. Sprint 8+ 우선순위 재검토 필요.

---

## 관련 문서
- 요약본: `docs/UX_QUESTIONS_v1.16.md`
- 페르소나 피드백: `docs/PERSONA_FEEDBACK_v1.16.md` · `docs/PERSONA_FEEDBACK_v1.16_AUTH.md`
- 게이미피케이션: `docs/GAMIFICATION_v1.16_PROPOSAL.md`
- Games 리서치: `docs/CF_GAMES_WODS_2021_2025.md`
- 브랜드 SSOT: `CLAUDE.md`
