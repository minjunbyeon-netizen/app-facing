# HANDOFF - 2026-09-07 10:30

> 이번 세션 작업은 전부 **`C:\dev\web\facing-admin`(코치 PC 웹)** 이다. 앱(`apps/facing-app`) 코드는
> 한 줄도 건드리지 않았다 — 앱 검사 342·골든 91은 직전 세션 상태 그대로다.

## 완료 — D126 토스트 (커밋 4개, 전부 push 됨)

- [x] **조립도 한 곳 + 정본 화면** (`ee2a68b`) — `showToast`·`showSyncToast` 가 `_layout.html`
  인라인에 갇혀 있어 갤러리가 **마크업 사본**을 그리고 있었다(D116 이 잡은 결함의 원인이 그대로
  남아 있었다). `static/toast.js` 로 빼고, 갤러리 사본 3개 삭제 → 레포 안 토스트 마크업 사본 **0**.
  그릇 `churnToastContainer` → `toastContainer` 개명(grep 5건), 없으면 toast.js 가 만든다.
  정본 화면 **`/design/toast`** 신설 — `design/toast_ssot.py` 가 실제 소스를 스캔해 만드는 **생성물**
  (손으로 고치지 말 것). 모양=실물 CSS 링크 · 표본=실물 함수가 만든 노드 복제 · 규격표=브라우저
  `getComputedStyle` 실측 · 문구 통계=전수 스캔.
- [x] **문구 한 벌 — 153곳** (`cce2704`) — 규칙 R1~R8 정본 = `design/SSOT.md §22.4`.
  합쇼체 20·해요체 30 → 0 · 마침표 55 → 0 · 실패 첫 줄에 서버 원문 51 → 0 ·
  "실패: " 만 남는 자리 33 → 0 · 둘째 줄 사용 1 → 118 · "다시 시도" 22갈래 → 3 ·
  서버 실패 아닌데 error 21 → 0 · SSE 내부 식별자(`member #37`) 18종 → 0.
  톤 분포 error 95·success 41·warn 14·기본 4 → **error 88 · success 45 · warn 20**.
- [x] **게이트 `design/lint.py §7.10`** — 첫 인자 `'…'+err`(R2) · `|| ''` 사유 비우기(R3) ·
  첫 줄 합쇼/해요/마침표(R1) · 옛 톤 이름 `danger`(R5). 현재 0건이고 **일부러 위반을 넣어
  넷이 모두 잡히는 것을 확인**한 뒤 되돌렸다.
- [x] **크기 3회** (`6a0d1e0` · `68e9e9d` · `ea388b0`, 통합 기록 = `SSOT.md §22.5`) —
  2026-08-29 '2배' 값에서 되돌아왔다. 본문 26→**19** · 둘째 줄 24→**16** · 시각 22→**16** ·
  아이콘 32→**삭제** · 패딩 20×28→**17×24** · 폭 480~680→**408~578** · 왼쪽 띠 6→**5** ·
  간격 `--sp-4`→**`--sp-3`**. 덤으로 `toast.js` 의 `innerHTML` 이 **0건**이 됐다.

## 진행중

- 없음. `web/facing-admin` 작업 트리 깨끗, origin/master 와 일치(`ea388b0`).

## 대기

- [ ] **토스트 본문 18px** — 지금 19px 는 `--fs-h1`(22)·`--fs-h2`(18) 사이라 토스트만 토큰 계단 밖이다.
  18 로 한 칸 내리면 전체가 토큰 안으로 들어온다(둘째 줄·시각 16 = `--fs-h3`). 사용자 판단 대기.
- [ ] **배지 3단** (앱 · 직전 인계장에서 이어짐) — `HkBadge` 한 곳에서 행동 배지 글자 `micro` 13 →
  `body` 15 w600 · 주 행동 **채움** / 보조 **외곽선** / 이유 **테두리 없는 글자**.
  골든 약 25장 재생성 예상, `test/touch_target_test.dart`·밀림 게이트 통과 필수.
- [ ] **점검 보고서 §4·§5 잔손질** (앱) — 홈 업적 아래 90dp 공백 · 쪽지함 빈 공지 카드 170dp ·
  로그인 약관 링크 굵기 · 내 정보 이름 중복 · 회색 상자 위 12sp muted 라벨 4.43:1.
  정본 = `docs/audit-visibility-2026-09-06.html`.
- [ ] **검증 데이터 삭제 — 분류기 차단, 사용자 직접 실행 필요** — `railway ssh`·관리자 API 쓰기
  스크립트 둘 다 auto-mode 분류기가 막는다(우회 안 함). gym_id=2 안 9/5 AWAKE 12:30 · SWEAT 14:00 ·
  BUILD 14:30 + 9/5·9/7·9/10 글. 메모리 = `project-prod-data-access-blocked.md`.
- [ ] **폰(갤S22) 3031** — 무선 디버깅 꺼져 있음. 켜면
  `adb -s adb-R5CT503NB5M-r4Y2MU._adb-tls-connect._tcp install -r build/app/outputs/flutter-apk/app-release.apk`.
- [ ] **구글 플레이 AAB 업로드**(사용자 몫) — 3035 준비됨, 스토어 에셋 16장도 갱신 완료.
- [ ] **git worktree 5개 정리** · `migrate_db` 명시 커밋 · PC `dead_utilities` 16 ·
  타이머 흐름(`wod_session_screen.dart`) 옛 형식 제출 — 직전 인계장 그대로.

## 결정사항 / 주의

- **토스트 값 정본은 `static/style.css` 한 곳.** 문서·화면에 숫자를 옮겨 적지 않는다 —
  `/design/toast §2` 가 실물 노드를 재서 보여 주므로 CSS 를 고치면 표가 따라온다.
- **`/design/toast` 는 생성물이다.** 고칠 때는 `design/toast_ssot.py` 를 고치고
  `python design/toast_ssot.py` 로 다시 만든다. HTML 을 직접 손대면 다음 생성에서 지워진다.
- **아이콘은 다시 넣지 않는다.** 톤은 왼쪽 띠 하나가 말한다(아이콘과 띠가 같은 뜻을 두 번
  말하고 있었다 — 대전제 6-b). 색만으로 뜻을 전하는 자리가 됐으므로 **첫 줄 문구가 상태를 말한다**(R1).
- **새 `showToast` 호출은 R1~R8 을 따른다** — 첫 줄 명사형·마침표 없음, 사유는 3번째 인자,
  사유 없으면 3번째 인자를 뺀다, 재시도 안내는 '연결을 확인하고 다시 시도' · '새로고침 후 다시 시도' 둘뿐.
  어기면 `design/lint.py` 가 막는다.
- **`design/lint.py` 는 `design/*.html` 을 스캔하지 않는다** — 갤러리·토스트 화면은 게이트 밖이다.
  그래서 그 두 화면은 제품 CSS·제품 함수를 **링크해서** 쓴다(사본을 만들면 아무도 못 잡는다).
- 로컬 서버 2개가 이번 세션에서 떠 있다 — 백엔드 `services/facing` :5060 · 관리자 웹 :8081.
  `/design/toast` 를 보려면 8081 이 살아 있어야 한다. 정리하려면 해당 python 프로세스를 종료.
- 로컬 관리자 웹은 `localhost` → `127.0.0.1` 로 308 리다이렉트한다. `127.0.0.1:8081` 로 열 것.

## 관련 파일

- 정본: `web/facing-admin/static/toast.js`(조립) · `static/style.css .toast`(모양) ·
  `design/toast_ssot.py`(정본 화면 생성기) · `design/lint.py §7.10`(게이트)
- 문서: `web/facing-admin/design/SSOT.md §22`(22.1 조립 · 22.2 화면 · 22.3 문구 집행 ·
  22.4 규칙 R1~R8 · 22.5 크기) · `web/facing-admin/CLAUDE.md §토스트 알림`
- 화면: `http://127.0.0.1:8081/design/toast` · 갤러리 `http://127.0.0.1:8081/design`

## 검증 상태

| 대상 | 결과 |
|---|---|
| design/lint.py | 룰 위반 0건 · baseline 유지(인라인 style 5 · style 블록 2 · 사문 유틸 16) |
| 게이트 §7.10 | 위반 주입 시 4종 모두 검출 확인 후 되돌림 |
| 페이지 렌더 | 21개 전부 200 + 인라인 스크립트 `node --check` 통과 |
| Jinja | 템플릿 28개 파싱 OK |
| 실물 | 계약서·회원·락커 화면에서 success·warn·error·info·sync 5종 확인(아이콘 0) |
| git (facing-admin) | `ea388b0`, origin/master 와 일치, 트리 깨끗 |
| git (facing-app) | 이번 세션 코드 변경 없음 (인계장 이동만) |

## 다음 세션 권장 첫 프롬프트

`/resume` → "배지 3단 집행" (앱 `HkBadge` 15sp · 채움/외곽선/글자 3단, 골든 약 25장 재생성)
