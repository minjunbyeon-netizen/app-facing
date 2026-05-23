# fix4 검증 결과 — 2026-05-23 17:00

## 이슈 1 — contract-templates GET
- **OK**: GET /api/v1/admin/contract-templates 200 + templates 반환
- 수정: `_require_boss` → `_require_boss_or_coach` (GET만)

## 이슈 2 — SSE exponential backoff
- **OK**: _layout.html EventSource에 backoff(1→2→4→8→15→30s), 6회 실패 시 오프라인 배너 표시
- 자동 재시도 중단 + 새로고침 버튼 제공

## 이슈 3 — payroll/lockers/classes a11y
- payroll: `aria-label` + month input `aria-label`
- lockers: locker cell `<div>` → `<button>` + `role="gridcell"` + `aria-label="락커 N 상태"`
- classes: 빈 셀 `role="gridcell"` + `tabindex="0"` + `aria-label` + Enter/Space keydown

## 이슈 4 — plan_name humanize
- **OK**: `plan_name_display` 필드 추가 (admin.py), privacy.py 동기화
- 매핑: 1_month→1개월권, 6_month→6개월권 등
- 미매핑은 raw 그대로 반환 (안전 폴백)
