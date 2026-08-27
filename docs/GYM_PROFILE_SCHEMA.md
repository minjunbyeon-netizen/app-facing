# GYM_PROFILE_SCHEMA — 박스 프로필 + 코치 프로필 DB 확장안

> **출처**: 2026-05-24 PERSONA_BACKLOG.md 18 필드 분류 결과
> **연계**: ARCHITECTURE_BRIEF §11.6 — 사용자 명시 승인 후 적용
> **목표**: 신규 방문자가 박스에 처음 들어왔을 때 알고 싶은 "가격·결제·시설·코치" 정보를 사장이 한 화면에서 편집·노출.

## 1. ALTER `gym_profiles` (+9 필드)

기존 7 필드(phone · coach_name · coach_bio · class_schedule · motto · ~~instagram~~ · ~~logo_url~~ · updated_at) 그대로 두고 아래 9 필드 추가. 모두 코치 권한으로 PATCH.

> **2026-08-27 (브리프 D63)**: `instagram`·`logo_url` 은 4기둥(공지·쪽지·수업 예약·수업 공개)
> 밖이라 제거됐다. PC 입력칸·API 직렬화·PATCH 수용·앱 모델 전부 삭제, DB 컬럼만 휴면 존치.
> 현재 편집·노출 필드는 **14개** (아래 9 + phone·coach_name·coach_bio·class_schedule·motto).

| 필드명 | 타입 | nullable | 용도 |
|---|---|---|---|
| `price_summary` | Text | yes | 1/3/12개월 가격 표 (markdown 또는 JSON. 자유 작성) |
| `payment_methods` | String(200) | yes | "카드·계좌이체·카카오페이" 같은 라벨 (다중 선택 string) |
| `receipt_info` | String(200) | yes | 영수증·소득공제·기업 복지 청구 안내 한 줄 |
| `parking_info` | String(200) | yes | 주차장·발렛 정보 (지하 X층, 발렛 가능 등) |
| `first_visit_guide` | Text | yes | 첫 방문 안내 (출입카드 등록·준비물·신발 추천 합쳐서) |
| `attire_guide` | String(300) | yes | 운동복·리프팅 슈즈 추천 (1줄) |
| `wifi_info` | String(120) | yes | "SSID / PW" 형식 |
| `contact_kakao` | String(120) | yes | 카카오톡 채널 URL 또는 @id |
| `free_notice` | Text | yes | 사장 자유 메모 — 휴무·이벤트·기타 공지 |

### 이유

- 별도 테이블 신설 안 함. `gym_profile` 1:1 관계 유지 — JOIN 비용 0, 사장 편집 UI 단일 폼.
- `price_summary` / `first_visit_guide` / `free_notice` 는 `Text` 자유 작성 — 박스마다 양식 달라 강제 스키마 안 둠.
- 단순 단일값 필드(payment_methods·wifi·receipt·parking·attire·contact_kakao) 만 정형화.

## 2. NEW `gym_coach_profiles`

다중 코치 지원. `gym_managers.role='coach'` 와 1:1 연결.

| 컬럼 | 타입 | nullable | 용도 |
|---|---|---|---|
| `id` | Integer PK | no | |
| `coach_user_id` | Integer FK → gym_managers.id | no | 인증 정보는 gym_managers 에. 프로필만 분리 |
| `gym_id` | Integer FK → gyms.id | no | 다지점 코치 지원 |
| `name` | String(80) | no | 표시 이름 (한글 또는 영문) |
| `photo_url` | String(300) | yes | 프로필 사진 |
| `career` | Text | yes | 경력 (자유 작성) |
| `certifications` | Text | yes | 자격증 목록 (CrossFit L1/L2/L3, USAW 등) |
| `specialty` | String(200) | yes | 전문 분야 ("짐내스틱·Engine build" 등) |
| `competition_records` | Text | yes | 대회 기록 (Games Finisher, Throwdown 등) |
| `demo_video_url` | String(300) | yes | YouTube/Instagram 시연 영상 |
| `sns_url` | String(200) | yes | 인스타·트위터 등 |
| `pt_bookable` | Boolean | no, default=False | PT 1:1 예약 받는지 토글 |
| `off_days_json` | Text | yes | JSON list ["2026-05-25", "2026-06-01", ...] |
| `hired_at` | Date | yes | 영업일 표시용 |
| `display_order` | Integer | no, default=0 | 박스 프로필에서 정렬 순서 (사장이 드래그) |
| `created_at` / `updated_at` | DateTime | no | 표준 |

### Unique constraint
- `(gym_id, coach_user_id)` — 같은 박스에 같은 코치 중복 X.

### Index
- `(gym_id, display_order)` — 박스 프로필 화면에서 sort.

## 3. 신규 API endpoint (6)

| 메서드 | 경로 | 권한 | 용도 |
|---|---|---|---|
| `GET` | `/api/v1/gyms/{gym_id}/profile` | public (read) | 박스 프로필 전체 (gym_profiles + coach_profiles 묶어서 반환) |
| `PATCH` | `/api/v1/admin/gyms/{gym_id}/profile` | boss only | gym_profiles 9 신규 필드 + 기존 필드 PATCH |
| `GET` | `/api/v1/gyms/{gym_id}/coaches` | public (read) | 코치 목록 + summary (이름·사진·specialty 만) |
| `GET` | `/api/v1/gyms/{gym_id}/coaches/{coach_id}` | public (read) | 코치 상세 (위 모델 전체) |
| `PATCH` | `/api/v1/admin/gyms/{gym_id}/coaches/{coach_id}` | boss + coach(본인만) | 코치 프로필 편집 |
| `GET` | `/api/v1/gyms/{gym_id}/coaches/{coach_id}/off-days` | public (read) | 휴무 일정 only (캘린더 렌더 전용) |

### SSE 이벤트 추가
- `gym.profile.updated` — 사장이 박스 프로필 수정 시 폰들에 broadcast → 자동 reload
- `coach.profile.updated` — 코치 프로필 수정 시 broadcast

## 4. UI 매핑 (와이어프레임 → 필드)

박스 프로필 페이지 (회원 폰 / 사장 편집)
```
가격 카드            → gym_profiles.price_summary
결제·영수증 카드     → gym_profiles.payment_methods + receipt_info
첫 방문 안내 카드    → gym_profiles.first_visit_guide + attire_guide + wifi_info
COACHES 카드         → gym_coach_profiles list (gym_id 필터)
NOTICE 카드          → gym_profiles.free_notice
Contact 카드         → gym_profiles.phone + contact_kakao + parking_info
```

코치 더보기 페이지
```
큰 사진              → gym_coach_profiles.photo_url
경력 카드            → career + certifications
Specialty 카드       → specialty
Competition 카드     → competition_records
Demo Video 카드      → demo_video_url
PT 예약 카드         → pt_bookable (true 일 때만 노출)
Off-days 카드        → off_days_json
SNS 카드             → sns_url
```

## 5. 마이그레이션 순서

1. `gym_profiles` 9 필드 ALTER (`ADD COLUMN IF NOT EXISTS` 패턴)
2. `gym_coach_profiles` CREATE
3. 기존 7 필드(`coach_name`/`coach_bio`) 데이터 → `gym_coach_profiles` 1 행으로 이전 (default coach)
4. `gym_profiles.coach_name` / `coach_bio` 는 deprecate 표시 (다음 버전에 제거)
5. SSE 매트릭스에 2 event 추가

> 기존 `coach_name`/`coach_bio` 즉시 삭제 X — facing-admin 코드에서 사용 중. 1 phase 동안 두 모델 병행 → 다음 phase 에 cleanup.

## 6. 계약서 흡수 (참고)

박스 프로필 페이지에 "환불·중도 해지" / "등록비·시설비" / "보험·안전" / "보충 약관" 항목은 **계약서 템플릿** 에 흡수 (`contract_template.html_template` + `legal_clauses` JSON). 박스 프로필 화면엔 "계약서 미리보기 →" 링크 1줄만.

→ 별도 ALTER 불요. PHASE4 §1.3 ContractTemplate 그대로 사용.

---

_Generated: 2026-05-24 22:41 / Source: PERSONA_BACKLOG.md + facing-app/CLAUDE.md v1.16.2_
