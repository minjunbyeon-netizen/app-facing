# 기록 축 계약 — 파트 종류가 입력 칸을 정한다 (D121 · 2026-09-05)

> 사용자 지적(2026-09-05): "백스쿼트 5×5 수업이면 **첫 세트에 몇 kg 로 몇 회** 를 적고
> 싶지 않겠나. FOR TIME 은 동작마다 무게가 필요하면 넣고(토투바는 필요 없음), 그보다
> **몇 분 만에 끝났나** 를 적는 게 중요할 거고."
>
> 이 문서는 **서버·앱이 같이 보는 계약**이다. 런타임 정본은 서버
> `services/result_axes.py` 한 곳이고, 앱은 `wod_type` 과 `has_load` 를 **읽어서 그리기만**
> 한다 (대전제 6-b — 앱에 같은 표를 복제하지 않는다).

---

## 1. 왜 고치는가 (지금 상태)

| 파트 종류 | 회원이 적고 싶은 것 | 지금 시트가 주는 칸 |
|---|---|---|
| STRENGTH `5-5-5-5-5` | 세트별 60×5 · 65×5 · 70×5 … | 동작 1줄에 `[한 횟수][무게]` **한 쌍** |
| FOR TIME | **완주 시간** | 시간 칸 없음 |
| AMRAP | **라운드 + 추가 렙스** | 라운드 칸 없음 |
| 무게 없는 동작 (T2B·풀업) | 무게 칸이 없어야 | 항상 무게 칸 |

v3.45(2026-09-02)가 점수 칸을 걷어낸 것은 **과밀 해소**로는 옳았지만, 파트(D109 ·
2026-09-04)가 그 이틀 뒤에 들어오면서 지금 시트는 **파트도 종류도 못 보는** 상태가 됐다.
서버 컬럼(`time_sec`·`rounds`·`extra_reps`)과 `movement_library.has_load` 는 **그대로
살아 있다** — 없앤 것은 UI 뿐이다.

---

## 2. 축 표 (정본 = `services/result_axes.py`)

파트의 `wod_type` 하나가 그 파트의 입력 축을 정한다.

| `wod_type` | 파트 점수 | 동작 줄 | 비고 |
|---|---|---|---|
| `for_time` | **완주 시간** `time_sec` | 무게 쓰는 동작만 `[무게]` | 캡 초과면 `capped=true` + `extra_reps`(남긴 렙스) |
| `amrap` | **라운드** `rounds` + **추가 회** `extra_reps` | 무게 쓰는 동작만 `[무게]` | |
| `emom` | 없음 | 무게 쓰는 동작만 `[무게]` | 완주가 기본, 점수 축 없음 |
| `strength` | 없음 (세트가 담당) | **세트별** `[무게][횟수]` 줄 | 세트 수 = 코치 `reps` 의 `-` 개수 (`5-5-5-5-5` → 5), 없으면 1 |
| `custom`(수업) | 없음 | `[한 횟수]` + 무게 쓰는 동작만 `[무게]` | 지금 동작과 같음 |

**무게 칸 규칙 (전 종류 공통)**: 동작의 `has_load` 가 참일 때만 무게 칸을 그린다.
`has_load` 는 `movement_library.has_load` 가 정본이며, 사전에 없는 자유 입력 동작은
코치가 무게(`load_value`)를 적었으면 참으로 본다.

---

## 3. 서버 → 앱 (수업 목록 응답 확장)

`rounds_data[]` 의 각 파트:

```jsonc
{
  "index": 0,                 // NEW — 0부터, 파트 순서. 점수의 열쇠
  "title": "A 파트 · 15분 · STRENGTH · 5라운드",
  "wod_type": "strength",
  "duration_min": 15,
  "rounds": 5,
  "time_cap_sec": null,
  "lines": ["Back Squat 5-5-5-5-5회 · 60kg"],
  "movements": [
    {
      "movement_id": 31, "name": "Back Squat", "unit": "reps",
      "reps": "5-5-5-5-5", "load_value": "60", "load_unit": "kg",
      "has_load": true,       // NEW
      "set_count": 5          // NEW — strength 세트 줄 수 (reps 에서 파생, 정본은 서버)
    }
  ]
}
```

`my_result` (재수정 프리필):

```jsonc
"my_result": {
  "parts": [                                  // NEW
    {"index": 1, "wod_type": "amrap", "rounds": 5, "extra_reps": 12},
    {"index": 2, "wod_type": "for_time", "time_sec": 754, "capped": false}
  ],
  "movements": [
    {"part_index": 0, "set_index": 0, "movement_id": 31, "name": "Back Squat",
     "unit": "reps", "reps": "5", "load_kg": 60.0, "scaled": false},
    {"part_index": 0, "set_index": 1, "movement_id": 31, "name": "Back Squat",
     "unit": "reps", "reps": "5", "load_kg": 65.0, "scaled": false},
    {"part_index": 1, "set_index": null, "movement_id": 50, "name": "Thruster",
     "unit": "reps", "reps": "12", "load_kg": 40.0, "scaled": false}
  ]
}
```

## 4. 앱 → 서버 (제출)

`POST /api/v1/gyms/{gym_id}/wods/{wod_id}/results`

```jsonc
{
  "parts": [
    {"index": 1, "rounds": 5, "extra_reps": 12},
    {"index": 2, "time_sec": 754, "capped": false}
  ],
  "movements": [
    {"part_index": 0, "set_index": 0, "movement_id": 31, "name": "Back Squat",
     "unit": "reps", "reps": "5", "load_kg": 60},
    {"part_index": 0, "set_index": 1, "movement_id": 31, "name": "Back Squat",
     "unit": "reps", "reps": "5", "load_kg": 65},
    {"part_index": 1, "movement_id": 50, "name": "Thruster",
     "unit": "reps", "reps": "12", "load_kg": 40}
  ]
}
```

- `parts` 는 **점수가 있는 파트만** 보낸다. 빈 칸은 아예 빼고 보낸다(0 을 지어내지 않는다).
- `wod_type` 은 앱이 보내지 않는다 — 서버가 게시물에서 읽는다 (한 사실을 두 곳에서 보내지 않는다).
- `movements` 는 종전 키에 `part_index`(필수)·`set_index`(strength 만) 를 더한 것.
- 옛 앱(3031 이하)이 보내는 `part_index` 없는 `movements` 도 계속 받는다 — `part_index=0`.

## 5. 저장

- 새 표 **`gym_wod_result_parts`** — `(result_id, part_index)` 유니크 ·
  `wod_type` · `time_sec` · `rounds` · `extra_reps` · `capped`.
- **`gym_wod_result_movements`** 에 컬럼 둘 추가 — `part_index`(기본 0) · `set_index`(널 허용).
- 재저장은 종전처럼 **통째 교체** (파트·동작 둘 다).

## 6. 표시 (한 곳에서 렌더)

히스토리 목록 둘째 줄·상세의 요약 문장은 **서버가 만든다**
(`services/program_lines.result_movements_summary` 확장). 앱은 받은 문자열을 그대로 쓴다.

예: `AMRAP 5R+12 · 12분 34초 · Back Squat 65kg×5`

## 7. 게이트 (같은 커밋에 넣는다)

- 서버: 축 표가 두 곳에 생기지 않는지 정적 검사 (`tests/test_ssot_result_axes_lint.py`) ·
  라운드트립 (제출 → 조회 → 같은 값) · 옛 형식 하위호환.
- 앱: 종류별 칸 렌더 검사 (for_time 은 시간 칸, amrap 은 라운드 칸, strength 는 세트 줄 수,
  `has_load` 거짓이면 무게 칸 없음) · 밀림 검사(파트가 늘어도 저장 버튼 y 불변).
