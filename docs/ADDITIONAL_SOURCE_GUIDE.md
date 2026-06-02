# additional/ 외부 정보 원천 통합 지침 (SSOT)

> 협업 개발자의 `rahap1` 레포(CrossFit Rehab Guide)를 **정보 원천**으로만 받아,
> **우리 코드로 재구현**해서 facing 앱의 **Notice 영역**에 채워 넣기 위한 작업 규칙.
> 2026-06-03 수립. 관련: `docs/ARCHITECTURE_BRIEF.md`(시스템 SSOT).

---

## 0. 한 줄 원칙

```
rahap1 = 정보(데이터·스펙) 원천일 뿐이다.
그쪽 코드는 실행·배포하지 않는다. 우리는 정보만 뽑아 우리 스택으로 다시 만든다.
```

협업 개발자는 `rahap1`을 계속 자기 방식(HTML + FastAPI)으로 만들어 나간다.
우리는 그 결과물을 **소비**하되, 구현이 아니라 **콘텐츠/로직**만 가져온다.

---

## 1. 역할 구분 (헷갈림 차단)

| 주체 | 정체 | 역할 | 우리가 하는 것 |
|---|---|---|---|
| **rahap1** (`github.com/Rimseorim/rahap1`) | 협업 개발자 레포 | 업스트림 정보 원천. 계속 갱신됨 | 받아오기만 (read-only) |
| **`additional/`** | rahap1의 박제된 사본(미러) | 우리 레포 안 참조 전용 스냅샷 | 덮어쓰기로 갱신·diff 비교 |
| **우리 코드** (`lib/`, `services/facing/`) | facing 본체 | 정보를 재구현해 Notice에 노출 | 직접 작성·유지 |

---

## 2. 단방향 데이터 흐름 (역류 금지)

```
rahap1 (협업자 push)
   │  ① 받아오기 (clone/덮어쓰기)
   ▼
additional/ (미러 — 손대지 않음)
   │  ② 정보 추출 + 우리 코드로 포팅
   ▼
lib/features/rehab/ + assets/data/rehab/ (우리 구현)
   │  ③ 노출
   ▼
폰 Notice 영역
```

- 흐름은 **위 → 아래 한 방향**. 우리가 `additional/`을 고쳐서 rahap1로 되돌리는 일은 없다.
- `additional/`은 언제든 통째로 덮어써도 되는 **소모성 미러**다.

---

## 3. 가져오는 것 / 안 가져오는 것 (경계)

| 받는다 (정보) | 안 받는다 (구현) |
|---|---|
| `data/rehab.json` — 의사결정트리 (동작→통증부위→질문→원인/병원 분기) | `index.html` — 그쪽 렌더링 (630KB) |
| `data/movements/*.json` — 동작별 통증부위·질문 데이터 | `backend/` — FastAPI(auth·records·models·database) |
| `docs/` — 기획서·DESIGN.md (카피·UX 로직·근거) | `scripts/` — 그쪽 빌드 스크립트 |
| 콘텐츠 텍스트·분기 규칙·6단계 재활 루트 | `Procfile`·`start.bat`·`requirements.txt` 등 실행물 |

> 핵심 자산은 `data/rehab.json`의 **스키마**다(`_schema: "1.0"`,
> `next`가 `q:id`=다음질문 / `cause:id`=원인확정 / `danger`=병원권유). 깨끗한 JSON이라 그대로 흡수 가능.

---

## 4. `additional/` 취급 규칙 (강제)

1. **손으로 수정 금지.** 다음 갱신 때 덮어써져 사라진다. 고칠 게 있으면 우리 코드 쪽에서.
2. **Flutter 빌드에 포함 안 됨.** `pubspec.yaml` assets에 `additional/`을 넣지 않는다. 참조 전용.
3. **그쪽 `.claude/`·`CLAUDE.md`는 우리 룰 아님.** facing-app 루트 CLAUDE.md만 적용. (`.gitignore`로 `.claude/` 제외 유지)
4. **그쪽 백엔드/HTML을 우리 배포에 올리지 않는다.**

---

## 5. 갱신 프로토콜 (협업자가 rahap1 갱신할 때마다)

협업 개발자가 `rahap1`에 새로 push하면:

1. **받아오기** — `additional/`을 최신 rahap1로 덮어쓴다 (아래 §5.1 명령).
2. **diff 확인** — `git diff`로 협업자가 **무엇을 바꿨는지**만 본다 (특히 `data/*.json`, `docs/`).
3. **포팅** — 바뀐 정보만 우리 코드/asset에 반영한다 (스키마 그대로면 JSON 교체, 로직 바뀌면 우리 Dart 수정).
4. **노출 갱신** — Notice에 보이는 내용 갱신 후 에뮬 검증.
5. **커밋** — `chore(additional): sync rahap1 @<짧은sha>` + 별도 `feat(rehab): ...` 포팅 커밋.

### 5.1. 받아오기 명령 (미러 덮어쓰기)
```bash
# 임시로 clone 후 .git 빼고 additional/ 위에 덮어쓰기
git clone --depth 1 https://github.com/Rimseorim/rahap1.git .tmp/rahap1-sync
rm -rf additional && mkdir additional
# (.git 제외하고 복사)
robocopy .tmp/rahap1-sync additional /E /XD .git   # Windows
rm -rf .tmp/rahap1-sync
```
> `additional/`은 우리 레포에 **vendored 스냅샷으로 추적**한다(gitignore 아님).
> 그래야 매 갱신마다 `git diff`로 협업자 변경분을 콕 집어 포팅할 수 있다.

---

## 6. 우리쪽 구현 위치 (포팅 대상)

| 우리 자산 | 위치 | 담는 것 |
|---|---|---|
| 재활 데이터 | `assets/data/rehab/` (예정) | rahap1 JSON을 우리 포맷으로 정제한 사본 |
| 재활 기능 | `lib/features/rehab/` (예정) | 의사결정트리 렌더링·분기·결과 UI (우리 디자인 토큰) |
| Notice 진입 | `lib/features/inbox/` 연계 (예정) | Notice에 "재활 가이드" 카드 → 탭하면 재활 플로우 |
| (필요 시) API | `services/facing/` | 우리 표준 Envelope로 서빙 (그쪽 FastAPI 아님) |

> 모든 UI·카피는 facing 규칙(다크 토큰·Voice&Tone·Pretendard)을 따른다. rahap1의 디자인을 그대로 베끼지 않는다.

---

## 7. 금지 (위반 시 이 지침 위반)

- ❌ `additional/`의 그쪽 코드(index.html·FastAPI)를 우리 앱/배포에서 실행·서빙
- ❌ `additional/` 안 파일을 손으로 수정 (다음 sync 때 소실)
- ❌ rahap1 디자인/HTML을 우리 화면에 그대로 복붙 (정보만, 구현은 우리 것)
- ❌ 우리 변경을 rahap1로 역푸시 (단방향 원칙)
