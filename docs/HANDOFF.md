# HANDOFF - 2026-05-23 19:20

## 완료
- [x] linko.my 2차 경쟁사 분석 (사장PC + 마케팅 20장) — `docs/competitor/linko-screens-2.md`
- [x] 대시보드 캡처 저장 — `docs/test/2026-05-23-1901-dashboard/`
- [x] 회원 수정 모달 (members.html) — `openEdit()` + PATCH `/api/v1/admin/members/<id>` 이미 존재

## 진행중
- [ ] **facing-admin 4 도메인 수정 모달 통합** — 중단 지점: 분석 완료, 코드 작업 미착수
  - 현황 파악 결과:
    - 회원: `members.html:80` `openEdit()` + `#editModal` 이미 있음. 필드 확인 후 보강만
    - 코치: `coaches.html` 시급 inline edit만 있음 → 수정 모달 **신규 필요**
    - 계약서: `contracts.html` 발급/서명 모달만 → draft·sent 수정 모달 **신규 필요**
    - 락커: `lockers.html` `#lockerModal` (배정용)만 → 수정(날짜·메모 변경) 보강 필요
  - 백엔드 PATCH endpoints 상태:
    - `/api/v1/admin/members/<mid>` — **있음** (`admin.py:508`)
    - `/api/v1/admin/gyms/<gid>/coaches/<login_id>` — **있음** (`admin.py:825`)
    - `/api/v1/admin/gyms/<gid>/lockers/<no>` — **있음** (`admin.py:922`)
    - `/api/v1/admin/contracts/<cid>` PATCH — **없음, 신규 필요**. signed 후 422 거절 로직 포함

## 대기
- [ ] playwright 검증 4장 캡처 → `docs/test/2026-05-23-1911-edit-modals/`
- [ ] Phase 5 사장 폰판 운영 (`docs/briefs/` → 백엔드 연동)

## 결정사항 / 주의
- **admin HTML 위치**: `C:\dev\web\facing-admin\templates\` (services/facing 아님)
- **facing-admin 별도 repo**: `C:/dev/web/facing-admin/` — git push 시 이 경로 사용
- **계약서 PATCH**: 전자서명법 §3 — signed 상태면 422 반환, 프론트도 잠금 메시지 표시
- **락커 PATCH 기존 동작**: member_id+이름으로 매칭, end_date 자동 회원권 따라감. 수정 모달에서 수동 override 가능하도록 날짜 필드 추가
- **코치 수정 모달 필드**: name·phone·hourly_wage·employment_type·hired_at (백엔드 PATCH가 name/phone/hourly_wage 3개만 처리 — employment_type·hired_at 추가 필요 여부 확인)
- **배포 금지 (CLAUDE.md 최상위)**: `git push origin` 포함 모든 배포 행위 금지. 로컬 커밋까지만

## 관련 파일
- `C:/dev/web/facing-admin/templates/members.html` — 회원 수정 모달
- `C:/dev/web/facing-admin/templates/coaches.html` — 코치 수정 모달 신규
- `C:/dev/web/facing-admin/templates/contracts.html` — 계약서 수정 모달 신규
- `C:/dev/web/facing-admin/templates/lockers.html` — 락커 배정/수정 통합
- `C:/dev/services/facing/api/admin.py` — PATCH endpoints (508·825·922·계약서 신규)

## 다음 세션 권장 첫 프롬프트
`/resume` 후 → "facing-admin 4 도메인 수정 모달 통합 이어서 — coaches·contracts·lockers 3개 우선, members는 기존 모달 필드 보강만. 계약서 PATCH endpoint도 같이 추가해줘."
