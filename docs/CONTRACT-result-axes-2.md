# 기록 축 계약 2 — 축을 서버가 내려주고, 강도가 다르면 비교하지 않는다 (D122 · 2026-09-06)

> D121 계약(`CONTRACT-result-axes.md`)의 **후속**이다. 그 문서가 "파트 종류가 칸을 정한다" 를
> 세웠고, 이 문서는 2026-09-05 사용자 질문("스트렝스는 무게·횟수만이면 되나 · 포타임은 시간만
> 중요한가 · 같은 포타임을 무겁게 한 사람과 가볍게 한 사람을 어떻게 구분하나 · AMRAP 은
> 정해진 수보다 더 했으면")에서 나온 조사 결과를 집행한다.
>
> 런타임 정본은 여전히 **서버 `services/result_axes.py` 한 곳**이다. 이 문서는 서버·앱·PC 가
> 같이 보는 계약이고, 규칙을 앱이나 PC 에 복제하지 않는다 (대전제 6-b).

---

## 0. 조사가 내린 결론 세 줄

1. **축은 맞았다.** strength = 세트별 `[무게][횟수]`, for_time = 시간, amrap = 라운드+부분 렙 —
   전부 업계 표준과 같다. 고칠 것은 축이 아니라 **배선·라벨·비교 열쇠**다.
2. **FOR TIME 은 시간만 중요한 게 아니다.** 다만 답은 *환산*이 아니라 *묶음*이다 — 크로스핏
   공식도 무게로 시간을 보정하지 않고 Rx'd/Scaled 를 갈라 그 안에서만 줄 세운다. 우리는
   회원 리더보드가 없어 문제가 더 작다: **내 과거와 겨룰 때 같은 강도끼리만 겨루면 된다.**
3. **자동 RX/Scaled 판정은 하지 않는다.** 무게 칸이 코치 값으로 프리필돼 있어 "저장만 누른
   사람" 이 전부 RX 로 찍힌다. 기계가 만드는 같은 거짓말이다.

---

## 1. 서버가 파생한다 — 근력 무게 (배선 복구)

**문제**: v3.45 이후 앱이 `weight_kg` 를 안 보내는데 서버는 그 값을 **무조건 덮어썼다.**
그래서 `gym_wod_results.weight_kg` 가 영구 NULL 이고, 그 칸을 읽는 화면 넷이 죽어 있다 —
히스토리 헤드라인(`-`) · strength PR · 1RM 보드(영구 공란) · 동작 단위 묶기.
회원이 적어 낸 무게는 `gym_wod_result_movements.load_kg` 에 **멀쩡히 있다** (한 사실이 두 표에
있고 화면이 빈 쪽을 읽는 상태 — 대전제 6 위반).

**규칙** (정본 = `result_axes.rollup_strength_best`):

- 세트 축(strength) 파트 중 **첫 파트**만 본다 (한 결과 행에 한 축).
- 그 파트의 `load_kg` 가 있는 줄에서 **최대 무게**, 동률이면 **최대 reps**.
- 그 줄의 동작 이름을 `movement` 로 → `movement_signature` 가 잡혀 날짜가 달라도 같은
  리프트로 묶인다 (2026-08-23 조인트 1 경로 재사용).
- 앱이 낱개 키(`weight_kg` 등)를 **명시로 보내면 그쪽이 이긴다** (`rollup_legacy_score` 와 같은 우선순위).
- **`existing.weight_kg = weight_kg` 무조건 대입을 없앤다** — 키가 없고 파생도 없으면
  **종전 값 유지** (`notes` 와 같은 계약). 옛 기록 파괴 차단.

---

## 2. 강도가 다르면 비교하지 않는다 (라벨 없이)

**규칙** (정본 = `result_axes.load_fingerprint` · `load_text`):

```python
def load_fingerprint(movements) -> str:
    """이 기록의 무게 지문 — 비교 그룹의 둘째 열쇠.
    무게가 적힌 줄만, (part_index, set_index, 정규화 동작명) 순으로 'name@kg' 이어붙임.
    무게가 하나도 없으면 '' (맨몸 수업 — 종전대로 시간만 비교).
    수치는 f'{v:g}' — 20 과 20.0 은 같고 42.5 와 43 은 다르다."""
```

`compare_and_flag` 의 **후보 필터**에 두 열쇠를 더한다:

| 열쇠 | 뜻 |
|---|---|
| `signature` (기존) | 같은 처방 |
| **`load_fingerprint`** | 내가 실제로 든 무게 |
| **`capped`** | 캡 기록 ↔ 완주 기록은 다른 단위다 |

후보가 0건이고 같은 `signature` 에 **다른 무게 기록이 있으면**:
```jsonc
{"kind":"time","is_pr":false,"message":"20kg 로는 첫 기록","prev":null,"best":null}
```
그 밖에는 종전대로 `null` — **거짓 없이 침묵한다.**

**저장하지 않는다.** 지문은 내 기록에서만 파생되므로 게시물이 바뀌어도 안 변한다 →
컬럼을 만들면 정본이 둘이 된다. 비교 시점에 계산한다. **DB 컬럼 0 증가.**

---

## 3. 축을 서버가 내려준다 (앱의 사본 제거)

**문제**: 앱이 `_scoredTypes = {'for_time','amrap'}` · `_noRepsTypes = {…,'emom'}` 리터럴로
축 표를 **복제**하고 있다. 새 종류·축 변경마다 **앱 재배포·스토어 심사**가 필요하다.

`api_rounds` 의 파트마다 다음을 싣는다 (전부 `result_axes` 함수를 부르기만 한다):

```jsonc
{
  "index": 2,
  "wod_type": "for_time",
  "score_keys": ["time_sec", "capped", "extra_reps"],   // NEW — 이 파트가 갖는 점수 칸, 그리는 순서
  "score_labels": {                                      // NEW — 라벨도 서버 (앱에 한글을 심지 않는다)
    "time_sec": "완주 시간", "capped": "캡 종료", "extra_reps": "남긴 렙스"
  },
  "score_target": null,                                  // NEW — 숫자 힌트 (emom=duration_min, amrap=round_reps)
  "show_movement_reps": false,                           // NEW — has_movement_reps()
  "set_based": false                                     // NEW — is_set_based()
}
```

### 축 표 (정본 `result_axes.AXES` — 이 표가 유일하다)

| `wod_type` | `score_keys` | `score_labels` | `score_target` | 동작 줄 |
|---|---|---|---|---|
| `for_time` | `time_sec` · `capped` · `extra_reps` | 완주 시간 · 캡 종료 · 남긴 렙스 | — | 무게 쓰는 동작만 `[무게]` |
| `amrap` | `rounds` · `extra_reps` | 라운드 · `+ 회` | `round_reps` | 무게 쓰는 동작만 `[무게]` |
| **`emom`** | **`rounds`** | **완료한 분** | **`duration_min`** | 무게 쓰는 동작만 `[무게]` |
| `strength` | (없음) | — | — | **세트별** `[무게][횟수]` |
| `custom` | (없음) | — | — | `[한 횟수]` + 무게 쓰는 동작만 |

**앱은 `score_keys` 를 보고 그린다.** `_scoredTypes`·`_noRepsTypes` 리터럴은 삭제한다.

---

## 4. EMOM 에 점수를 준다

**문제**: 지금 EMOM 파트는 적을 게 하나도 없으면 **파트 자체가 화면에서 사라진다**.
회원 눈에 "D 파트는 왜 없지?" 로 보인다 — 화면이 없는 척한다.

- 축 = `ROUNDS` 하나(`rounds`), 라벨 **`완료한 분`**, 힌트 `10분 중`(=`duration_min`).
- **체크박스는 쓰지 않는다** — 체크 안 된 칸이 "실패" 로 읽히는데 실제로는 "안 적음" 일 수
  있다. 계약 §4 의 "0 을 지어내지 않는다" 와 부딪힌다. 숫자 한 칸은 그 문제가 없다.
- `extra_reps` 는 주지 않는다 (EMOM 에 '추가 회' 는 뜻이 없다).
- 새 컬럼 없음 — `gym_wod_result_parts.rounds` 재사용.
- **서버 안 두 표의 어긋남도 이걸로 사라진다**: `wod_compare` 는 이미 emom 을 rounds 축으로
  비교하도록 쓰여 있는데 `AXES` 가 그 값을 못 만들게 막고 있었다.

---

## 5. AMRAP — 라벨과 검증

| 자리 | 지금 | 바꾼 뒤 |
|---|---|---|
| 오른 칸 라벨 | `추가 회` | **`+ 회`** |
| 오른 칸 힌트 | `0` | `round_reps` 있으면 **`25 미만`**, 없으면 `0` |
| 안내 줄 | 없음 | 점수 칸 아래 **항상 있는 고정 높이 한 줄**: `마지막 라운드에서 한 횟수를 적습니다` |
| 동작 줄 | 무게 없으면 줄이 사라짐 | 서버 `lines` 를 **읽기 전용**으로 세운다 (입력 칸 아님) |

`추가 회` 는 한국어로 "정해진 것에 더해서" 로 읽힌다 — 실제 뜻은 정반대(마지막 라운드를
다 못 채우고 한 만큼)다. **사용자 질문 자체가 그 오독의 증거였다.**

### `round_reps` (한 라운드 렙스 합)

정본 = `result_axes.round_reps(part) -> int | None`. **`None` 이 되는 조건**(하나라도 참):
동작 0개 · `unit != "reps"` 인 동작이 있음 · `reps` 가 단일 정수(`^\d+$`)가 아닌 동작이 있음 ·
`reps` 가 빈 동작이 있음.

- 응답 파트에 `round_reps`, `my_result.parts[]` 에 **저장 시점 스냅샷** `round_reps` + 파생 `total_reps`.
- 저장: `gym_wod_result_parts.round_reps INTEGER NULL` 하나 추가. `total_reps` 는 컬럼을 만들지
  않는다(파생 — 같은 사실을 두 번 세지 않는다).
- **검증 (400)**: `round_reps` 가 있고 `extra_reps >= round_reps` →
  `한 라운드를 다 채웠으면 라운드 수에 넣어 적으세요.`
- 표시: 상세에서만 `AMRAP 8R+12 · 총 212회`. 목록 둘째 줄은 종전 그대로.

### 코치 편집기 (PC)

**AMRAP 선택 시 `라운드` 칸을 비활성**한다. AMRAP 은 시간이 끝날 때까지 도는 것이라 정해진
라운드가 없다 — 칸을 열어 둔 것이 "정해진 수" 라는 개념을 만들었다.
(프로드 실측: amrap 파트 4건 중 1건에 이미 라운드 값이 들어가 있다.)
`_part_head_bits` 도 `amrap` 이면 `N라운드` 를 찍지 않는다. 판정은 `result_axes` 한 곳.

---

## 6. STRENGTH — 세트별 횟수 프리필

`api_rounds` 의 동작마다:

```jsonc
{ "name": "Back Squat", "reps": "5-5-5-5-5", "set_count": 5,
  "set_reps": ["5","5","5","5","5"] }   // NEW
```

- 정본 = `result_axes.set_reps()`. **`set_count()` 는 `len(set_reps())`** — 두 함수가 각자
  쪼개면 세트 줄 수와 프리필 개수가 갈린다.
- 조각은 `strip()`. 세트 축이 아닌 종류는 `[]`. `MAX_SETS`(20) 로 자른다.
- **앱은 쪼개지 않는다.** 지금 세트 5줄이 전부 힌트로 `5-5-5-5-5` 를 보여주는 것도 고친다
  (그 줄의 목표만 힌트로).
- 무게 프리필은 종전 그대로(코치 값 하나가 전 세트에) — 세트별 무게 처방 수단은 만들지 않는다.

---

## 7. 히스토리 — 파트 점수가 보이게

**문제**: 서버는 `history_item.parts[]` 를 내려주는데 **앱이 파싱조차 안 한다.** 회원이 적어 낸
파트 점수는 목록 둘째 줄의 잘린 한 줄 말고는 다시 볼 방법이 없다.

| 자리 | 바꾼 뒤 |
|---|---|
| 목록 둘째 줄 | `maxLines: 2` (지금 1) |
| 목록 헤드라인 | 다중 파트에서 온 값이면 숫자 아래 작은 라벨 (`9:42` / `C 파트`) — 서버 `headline_part_label` |
| **상세** | `parts[]` 를 파트별 한 줄로 세운다 — 서버가 그린 `line` 그대로 (`A 파트 · STRENGTH — 70kg×5`) |
| 상세 배지 | 난도 배지는 **이미 삭제됨**(2026-09-05). `capped` 면 **`캡`** 배지 |

응답 확장:
```jsonc
"capped": true,                       // NEW — 파트에서 파생 (결과 행 컬럼 아님)
"headline_part_label": "C 파트",       // NEW — 다중 파트일 때만, 아니면 null
"parts": [ {"index":0, "wod_type":"strength", "line":"70kg×5"}, … ]  // line 은 result_part_line 노출
```

`result_movements_summary` 는 **처방과 다를 때만** 꼬리를 붙인다:
`Thruster 21-15-9회 · 20kg (처방 43kg)`. 판정도 `result_axes.load_text` 한 곳.
세트 축 파트는 동작 이름을 반복하지 않고 접는다: `Back Squat 60kg×5 · 65kg×5 · 70kg×3`.

---

## 8. 종류는 5개로 동결

`WOD_TYPES` = `for_time · amrap · emom · strength · custom`. **늘리지 않는다.**

근거: 조사한 형식 8종 중 6종이 이미 표현되고(Chipper·RFT·Ladder·Max Effort·Time Trial·Hero),
Death by 는 §4 로 해결된다. 남는 공백은 Tabata(8라운드 중 **최저** 렙) 하나이고 현장 빈도 근거가
없다. 그리고 상용 앱 6곳(TrainHeroic·BTWB·SugarWOD·Wodify 등) **어디도 형식 이름을 값으로 두지
않는다** — 전부 점수 축 목록이다.

새 종류를 늘리는 조건(명문): *코치가 실제로 자주 올리는데, 회원이 적을 값의 축이 기존
셋(시간·라운드·세트무게) 밖일 때만.* 늘릴 때는 §3 표에 근거를 적는다.

---

## 9. 게이트 (전부 같은 커밋)

**서버**
- 축 표 중복 정의 감지 확장 — `score_keys`·`score_labels`·`set_reps`·`round_reps`·
  `load_fingerprint` 를 정본 밖에서 다시 적으면 실패.
- **`AXES` 와 `wod_compare._score` 가 emom 에 대해 같은 축을 말하는지 대조** (지금 어긋난 것).
- `WOD_TYPES` 길이 5 고정 (늘리려면 이 줄을 같이 고치게 — 의도적 마찰).
- strength 무게 파생 라운드트립 — **앱이 실제로 보내는 페이로드(parts+movements)로** 저장 →
  `weight_kg` 가 세트 최댓값과 같은 값. 재저장 시 `None` 으로 안 덮임.
- strength PR 라운드트립 — 같은 리프트 두 번, 무거운 쪽이 `is_pr=1`.
- 강도 비교 — 43kg→43kg 비교 성립 / 43kg→20kg **비교 없음** + `'20kg 로는 첫 기록'` /
  캡↔완주 **비교 없음** / 맨몸 수업 두 건은 종전대로 비교(회귀).
- `round_reps` 가 `null` 이 되는 경우 전수 · `extra_reps >= round_reps` 400.
- 1RM 보드가 비어 있지 않음.

**앱**
- `lib/**` 에 `'for_time'`·`'amrap'`·`'emom'`·`'strength'` 리터럴 **집합**이 있으면 실패
  (축 표를 앱이 다시 갖는 것을 금지).
- `score_keys` 대로 칸이 그려지는지 — for_time 3칸 · amrap 2칸 · emom 1칸 · strength 0칸.
- 맨몸 동작만 든 EMOM 파트가 시트에 **남아 있는지** (지금 소멸, 무가드).
- `set_reps` 프리필 · 세트 줄 힌트가 전체 문자열이면 실패.
- `추가 회` 잔존 0건.
- 히스토리 상세에 파트 줄이 서는지 · 캡 배지 · 난도 배지 부재(기존 게이트 유지).
- 밀림 — 파트·세트가 늘어도 저장 버튼 y 불변.

**PC**
- AMRAP 파트에서 `라운드` 입력이 비활성인지.
- `wod.html` 의 로컬 라벨 조립(`replace(/_/g,' ')`) 금지 — 라벨은 서버 `WOD_TYPE_LABELS`.
