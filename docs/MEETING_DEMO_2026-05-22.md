# 회의 데모 플레이북 — facing-app 가짜 아이디 시연

> **작성일**: 2026-05-22
> **대상 회의**: 시연 회의 (날짜·참석자 미정)
> **목표**: 가짜 아이디(페르소나) 10명을 즉석에서 갈아끼우며 회원·코치 시점의 핵심 플로우 3개를 라이브로 보여주기

---

## 0. 핵심 결론 — "하드코딩 말고" 의 진짜 모양

요청 그대로 풀어드리면, **앱 화면에 하드코딩된 가짜 데이터가 아니라 백엔드 DB에 실제로 시드된 10명의 페르소나** 를 쓰는 방식이에요. 시연자가 폰의 디버그 메뉴(`MyPage → 페르소나 스위처`)에서 페르소나를 고르면 앱이 그 사람의 `device_id` 로 강제 전환되고, 백엔드의 모든 API(`/gyms/mine`, `/wods`, `/announcements`, `/messages`...)가 그 ID 기준으로 진짜 데이터를 내려주는 구조예요.

| 항목 | 위치 | 비고 |
|---|---|---|
| 페르소나 명단 SSOT | `services/facing/data/personas.json` | 박스 2개 + 페르소나 10명 |
| DB 시드 스크립트 | `services/facing/seed_personas.py` | personas.json 읽어서 DB 적재 |
| 보조 시드 | `seed_facing_gym.py` / `seed_dummy_coaching.py` / `seed_april_history.py` / `seed_movements.py` / `seed_wods.py` / `seed_achievements.py` | 박스·코칭 히스토리·동작 카탈로그·WOD 게시물·달성 배지 |
| 앱 측 스위처 | `lib/features/_debug/persona_switcher_screen.dart` | `kDebugMode` 가드. release 빌드 진입 불가 |
| 합성 grade 데이터 | `lib/features/_debug/persona_debug_data.dart` | 페르소나 → tier 매핑 + 체형/벤치마크 |

요청하셨던 "가짜 아이디" 는 결국 이 페르소나 시스템이 풀버전이에요. 별도로 새 시스템을 만들 필요 없이, **이미 박혀 있는 10명을 시나리오별로 어떻게 돌릴지** 만 정리하면 회의 데모는 바로 됩니다.

---

## 1. 페르소나 명단 (10명 + 박스 2개)

### 박스 2개

| 박스 ID | 이름 | 위치 | 오너 | 초대코드 | 전화 | 모토 |
|---|---|---|---|---|---|---|
| `box_seongsu` | **FACING SEONGSU** | Seoul · Seongsu | 박지훈 (coach_a) | `FSGSU1` | 02-6677-8800 | Earn it. |
| `box_gangnam` | **FACING GANGNAM** | Seoul · Gangnam | 이수민 (coach_b) | `FGNAM2` | 02-3445-9200 | Show up and do the work. |

### 페르소나 10명

| # | 페르소나 ID | 이름 | 역할 | 박스 | 상태 | Tier | WOD 이력 | 시연에서의 역할 |
|---|---|---|---|---|---|---|---|---|
| 1 | `admin_01` | 변민준 | admin | 무소속 | — | RX+ | 8건 | 본인 계정 · 박스 무소속 앱 사용자 데모 겸용 |
| 2 | `coach_a` | **박지훈** | coach_owner | SEONGSU | owner | Elite | 14건 | **코치 시점 데모 주인공 (A)** |
| 3 | `coach_b` | 이수민 | coach_owner | GANGNAM | owner | Elite | 12건 | 코치 시점 백업 (B) |
| 4 | `member_a1` | **김도윤** | member | SEONGSU | approved | RX | 11건 | **A체육관 정식 회원 데모 주인공** |
| 5 | `member_a2` | 정하은 | member | SEONGSU | approved | RX | 9건 | A체육관 회원 (피드/쪽지 수신자) |
| 6 | `member_a3` | 최서윤 | member | SEONGSU | **pending** | Scaled | 0건 | 가입 대기 상태 — 코치 승인 흐름 데모용 |
| 7 | `member_b1` | 강민재 | member | GANGNAM | approved | RX+ | 13건 | B체육관 회원 |
| 8 | `member_b2` | 윤지원 | member | GANGNAM | approved | RX | 7건 | B체육관 회원 |
| 9 | `member_b3` | 한수아 | member | GANGNAM | **rejected** | Scaled | 0건 | 가입 거절 상태 — 에러 화면 데모용 |
| 10 | `app_user_01` | **송예준** | app_user | **무소속** | — | RX | 6건 | **무소속 회원 데모 주인공 (B)** |

> 회의 진행 효율을 위해 굵게 표시한 4명(변민준 / 박지훈 / 김도윤 / 송예준) 만 시연하고, 나머지는 "회원 목록 안에 이런 분들도 있어요" 식으로 화면에 등장만 시키는 방식을 권장.

---

## 2. 시연 시나리오 매트릭스 (3개 시나리오 × 11개 검증 포인트)

| # | 시나리오 | 페르소나 | 화면 | 검증 포인트 | 기대 결과 | 실패 신호 |
|---|---|---|---|---|---|---|
| S1-1 | 소속 회원이 자기 박스 정보 카드를 본다 | 김도윤 (member_a1) | NOTICE 탭 상단 | 박스명 `FACING SEONGSU` 노출 | 카드 헤더에 박스명 | "내 박스" 로 표시되면 박스 hydrate 실패 |
| S1-2 | 위치 · 전화 · 코치약력 표시 | 김도윤 | NOTICE 탭 | 위치 = Seoul · Seongsu, 전화 = 02-6677-8800, 코치 = "박지훈 코치 · CrossFit L2 …" | 3 줄 모두 채워짐 | "정보 미등록" fallback 노출 시 `/gyms/mine.profile` 응답 누락 |
| S1-3 | 수업 시간표 표시 | 김도윤 | NOTICE 탭 | "평일 06:00 · 07:00 · 18:30…" 줄바꿈 포함 | `\n` 까지 그대로 렌더 | 한 줄로 뭉치면 캡션 줄바꿈 처리 누락 |
| S1-4 | 모토 표시 | 김도윤 | NOTICE 탭 | "Earn it." (italic quote 스타일) | quote 토큰으로 표시 | 일반 body 스타일이면 토큰 적용 안 됨 |
| S2-1 | 무소속 회원이 자체 WOD 프로그램을 본다 | 송예준 (app_user_01) | 홈 / WOD 빌더 | "Today's WOD" 시작 가능 | 등급별 자동 분할(Split)·폭발(Burst) 표시 | 박스 가입 권유 화면이 떠 막히면 무소속 분기 누락 |
| S2-2 | 무소속이 NOTICE 탭 진입했을 때 박스 카드 X | 송예준 | NOTICE 탭 | 박스 정보 카드 미노출 또는 "박스 없음" 안내 | 카드 영역 비거나 빈 상태 | 가짜 박스명 노출되면 hydrate 충돌 |
| S2-3 | 무소속도 6 카테고리 Engine 점수 확인 가능 | 송예준 | 마이페이지 / 결과 | tier=RX, overall ≈ 66% | 페르소나 합성 grade 적용 | 점수 0% 또는 미표시 시 `tierGrade()` 미동작 |
| S3-1 | 코치가 자기 박스 정보를 수정한다 | 박지훈 (coach_a) | 코치 대시보드 → 박스 정보 편집 | `phone` · `motto` · `class_schedule` 한 줄 변경 후 저장 | 200 OK · NOTICE 탭에서 바로 반영 | 403 FORBIDDEN 이면 `owner_hash` 매칭 실패 |
| S3-2 | 코치가 오늘의 WOD 를 등록한다 | 박지훈 | 코치 대시보드 → WOD 게시 | For Time / AMRAP / EMOM 중 1개 + content 입력 후 게시 | 200 OK · 회원 페르소나로 갈아끼면 NOTICE 또는 WOD 피드에서 즉시 노출 | INVALID_WOD_TYPE / INVALID_DATE 시 입력값 형식 오류 |
| S3-3 | 코치가 회원에게 1:1 쪽지를 보낸다 | 박지훈 → 김도윤 | 코치 대시보드 → 회원 목록 → 쪽지 | body 입력 후 송신 | 200 OK · 김도윤 페르소나로 갈아끼면 받은 쪽지 목록에 노출 | to_hash 누락 시 EMPTY_FIELD |
| S3-4 | 가입 대기 회원 승인 흐름 | 박지훈 → 최서윤 (member_a3) | 코치 대시보드 → 가입 요청 | "승인" 클릭 | 200 OK · status=approved 로 전환 · 최서윤 페르소나에서 박스 정보 카드 노출 | 403 시 owner 권한 누락 |

---

## 3. 사전 준비 체크리스트 (회의 직전 5분)

회의 시작 5분 전, 이 순서대로 한 번씩 누르고 들어가시면 데모 중 막히는 일이 없어요.

### 3-A. 백엔드 살아 있는지 확인

```powershell
# 1. 좀비 프로세스 정리 (Windows SO_REUSEADDR 누적 방지 — global rule §B sledgehammer)
Get-Process python | Where-Object { $_.StartTime -gt (Get-Date).AddHours(-2) } | Stop-Process -Force

# 2. facing 백엔드 단독 기동
cd C:\dev\services\facing
python app.py
# → http://localhost:5060 LISTENING 1개만 떠야 정상

# 3. 진짜 기능 엔드포인트로 검증 (health 말고)
curl -sS http://localhost:5060/api/v1/gyms/search -w "%{http_code}\n"
# → 200 + FACING SEONGSU / GANGNAM JSON 떨어지면 OK
```

### 3-B. DB 시드 (이미 돌렸으면 건너뛰기)

페르소나 데이터가 깨끗하게 깔려 있는지 확신이 안 서면 이 순서로 한 번만 돌려요. **로컬 SQLite (`services/facing/data/facing.db`) 만 건드리고 git 추적 안 되니 안전**합니다.

```powershell
cd C:\dev\services\facing
python seed_movements.py        # 동작 카탈로그
python seed_personas.py         # 박스 2개 + 페르소나 10명 + gym_members
python seed_facing_gym.py       # FACING 공식 박스 (있으면 skip)
python seed_dummy_coaching.py   # 코치 피드백·요청 더미
python seed_april_history.py    # 4월 WOD 80건 + engine snapshots
python seed_wods.py             # 박스별 오늘의 WOD 게시물 6건
python seed_achievements.py     # 배지·달성 데이터
```

> SECRET_KEY 가 `.env` 에 등록돼 있으면 페르소나 해시가 달라집니다. 시연 직전엔 `.env` 의 `SECRET_KEY` 한 줄을 임시로 주석 처리하거나, 시드 후 그대로 두세요.

### 3-C. 앱 빌드 (디버그 빌드여야 페르소나 스위처 노출)

```powershell
cd C:\dev\apps\facing-app
flutter run -d <갤럭시-시리얼>   # 또는 emulator-5554
# release 빌드(APK) 면 페르소나 스위처가 안 보임 — debug 빌드 필수
```

### 3-D. 화면 도달 경로 외워두기

- **페르소나 스위처**: 앱 켜기 → 하단 탭 `Profile` (MyPage) → 디버그 메뉴 → "페르소나 스위처"
- **NOTICE 탭**: 하단 탭 `Notice` (index=2). 상단 박스 정보 카드가 데모 핵심.
- **코치 대시보드**: 박지훈/이수민 페르소나 적용 후 자동으로 코치 모드 진입
- **WOD 빌더 (자체)**: 송예준 페르소나 적용 후 홈 → "Start WOD"

---

## 4. 회의 진행 권장 흐름 (총 15~20분)

### Step 0 — 준비 멘트 (1분)

> "지금 화면은 페르소나 디버그 모드입니다. 실제 사용자는 이 화면을 못 보고요, 시연용으로 가짜 아이디 10명이 백엔드에 시드돼 있는 상태예요. 한 명씩 갈아끼면서 어떻게 다르게 보이는지 보여드릴게요."

### Step 1 — 시나리오 S1: A체육관 회원 (3~4분)

1. 페르소나 스위처 → **김도윤** 선택 → 적용
2. (자동으로 GymState 재로딩 다이얼로그 뜸) → 확인
3. `Notice` 탭 진입
4. **검증 포인트 강조해서 짚기**:
   - "박스 이름 보이시죠? FACING SEONGSU 입니다"
   - "위치 · 전화번호 · 코치 이름이랑 약력까지 다 박스 단위로 자동으로 깔려 있어요"
   - "수업 시간표는 코치가 적은 그대로 줄바꿈도 살아 있고요"
   - "마지막에 모토가 italic 으로 떠요 — 박스마다 다르게 설정 가능합니다"
5. (선택) 정하은(member_a2) 으로 한 번 더 갈아껴서 "**같은 박스 회원은 똑같은 카드가 보입니다**" 확인

### Step 2 — 시나리오 S2: 무소속 회원 (2~3분)

1. 페르소나 스위처 → **송예준** 선택 → 적용
2. `Notice` 탭 진입
3. **"박스 카드가 사라졌죠? 박스에 안 묶인 사람은 코치 공지를 받을 일이 없으니까요"**
4. 홈 탭 또는 "Start WOD" → 자체 WOD 프로그램 표시
5. 마이페이지 → Engine 점수 66% (RX) 확인
6. **포인트 멘트**: "박스에 안 들어가도 우리 서비스 자체 WOD 와 등급 시스템이 완전히 돌아갑니다. 박스는 옵션이에요."

### Step 3 — 시나리오 S3: 코치 (8~10분)

#### S3-1 박스 정보 수정 (2분)

1. 페르소나 스위처 → **박지훈** 선택 → 적용 (코치 모드 자동 진입)
2. 코치 대시보드 → 박스 정보 편집
3. `motto` 한 줄을 회의 자리에서 즉석으로 바꿔보기 (예: "오늘 회의 데모 중") → 저장
4. 페르소나 스위처 → 김도윤 → NOTICE 탭 → **방금 바꾼 모토가 그대로 노출되는 거 확인**
5. 다시 박지훈으로 돌아가서 원래 모토로 복구 ("Earn it.")

#### S3-2 오늘의 WOD 등록 (3분)

1. 박지훈 페르소나 유지
2. 코치 대시보드 → "오늘의 WOD 게시"
3. **For Time** 선택, post_date = 오늘, content 예시:
   ```
   "Fran"
   21-15-9
   Thruster 95/65 lb
   Pull-up
   ```
4. 게시 → 200 OK
5. 페르소나 스위처 → 김도윤 → WOD 피드 / NOTICE 에서 **방금 올린 WOD 즉시 노출 확인**
6. (선택) 김도윤이 결과 제출(time_sec 입력) → 박지훈으로 돌아와 리더보드에서 김도윤 기록 확인

#### S3-3 회원에게 쪽지 (2분)

1. 박지훈 페르소나
2. 코치 대시보드 → 회원 목록 → 김도윤
3. 쪽지 작성: "오늘 컨디션 어때요? Fran 페이스 분배 조심하세요"
4. 송신
5. 페르소나 스위처 → 김도윤 → 받은 쪽지 / 인박스에서 **방금 받은 쪽지 노출 확인**

#### S3-4 (선택) 가입 승인 (1~2분)

1. 박지훈 페르소나
2. 코치 대시보드 → 가입 요청 → **최서윤 (pending)**
3. "승인" 클릭
4. 페르소나 스위처 → 최서윤 → NOTICE 탭 → **방금까지 안 보이던 박스 정보 카드 노출 확인**

### Step 4 — 마무리 멘트 (1분)

> "정리하면 회원 시점 2개(소속/무소속), 코치 시점 1개(편집·게시·소통)로 우리 앱이 누구에게 어떤 가치를 주는지 한 번에 보여드린 거예요. 박스에 묶인 사람한테는 코치 공지·커뮤니티가, 안 묶인 사람한테는 자체 WOD 프로그램이 핵심이고, 코치한테는 박스 운영 도구가 핵심입니다."

---

## 5. 화면별 검증 포인트 — 시연 중 막혔을 때 대응

| 증상 | 원인 후보 | 대응 |
|---|---|---|
| NOTICE 탭에서 박스명이 "내 박스" 로만 뜸 | `/gyms/mine` 응답 hydrate 실패 (백엔드 OFF 또는 시드 누락) | 백엔드 재기동 + `seed_personas.py` 재실행 |
| 박스 정보 카드 필드가 전부 "정보 미등록" | 박스 시드는 됐는데 `gym_profiles` 행이 없음 | `seed_personas.py` 가 `profile` 블록까지 INSERT 했는지 로그 확인 |
| 페르소나 갈아껴도 화면 안 바뀜 | DemoSwitcher↔GymState 동기화 누락 (v1.20 fix 이후엔 거의 없음) | 다이얼로그에서 "확인" 누른 뒤 화면을 한 번 pop & re-push (탭 한 번 다른 데 갔다 오기) |
| 코치 페르소나인데 403 FORBIDDEN | `owner_hash` 가 SECRET_KEY 변경으로 어긋남 | `.env` 의 `SECRET_KEY` 주석 처리 후 `seed_personas.py` 재실행 |
| WOD 게시 시 INVALID_DATE | post_date 형식이 `YYYY-MM-DD` 가 아님 | 직접 타이핑 말고 화면의 날짜 피커 사용 |
| 점수가 0% 로만 표시 | `tierGrade()` 스케일 버그 (v1.18 이전) | 최신 master 인지 확인 (`864538d` 이후) |
| 갤럭시에서 빌드는 됐는데 페르소나 스위처가 안 보임 | release 빌드로 깔림 | `flutter run` (debug) 로 다시 깔거나 `--debug` 명시 |

---

## 6. 회의 후 정리

- **시드 데이터 그대로 두기**: 로컬 DB(`services/facing/data/facing.db`)는 git 무시 대상이라 다음 시연 때 또 쓸 수 있어요. 굳이 wipe 안 해도 됨.
- **만약 박지훈이 회의 자리에서 바꾼 박스 모토를 안 되돌렸다면**: 마지막에 한 번 더 박지훈으로 들어가서 원래 모토로 복구. 다음 시연자가 헷갈리지 않게.
- **회의 인사이트 회수**: 이 문서 하단에 "## 7. 회의 피드백" 섹션 추가해서 회의에서 나온 지적/요청을 그 자리에서 받아치면 좋아요. 끝나고 따로 정리 안 해도 됨.

---

## 7. 회의 피드백 (회의 중·후 채워넣기)

- (회의 중 받은 의견 1)
- (요청 사항 1)
- (다음 데모 때 추가할 시나리오 1)

---

## 부록 A. 페르소나 device_id 해시 산식

`hash_device_id(seed) = SHA256("facing_default_salt" + seed)` 의 hex digest 앞 N자리.
`.env` 에 `SECRET_KEY=...` 가 설정돼 있으면 솔트가 그 값으로 바뀌어 해시 결과가 달라집니다. 시연 직전에 SECRET_KEY 가 default 인지 한 번만 확인해주세요.

## 부록 B. 가짜 아이디를 더 늘리고 싶다면

회의 직후 "회원 30명짜리도 보고 싶다" 같은 요청이 나오면, 추가 작업 후보는 다음 셋 중 하나예요.

1. **personas.json 에 수동 추가** — 가장 안전. SSOT 유지.
2. **`seed_fake_members.py` 신설 (faker 라이브러리)** — 백엔드에 `faker` 추가 후 `--count 30` 같은 옵션으로 자동 생성. 박스 가입까지 자동.
3. **앱에 "가짜 회원 +1" 버튼** — 페르소나 스위처 옆에 추가. 데모 중 즉석으로 늘릴 수 있지만 코드 변경 동반.

요청 나오면 1번부터 권장 (10명 → 30명 정도까지는 1번이 가장 깔끔).
