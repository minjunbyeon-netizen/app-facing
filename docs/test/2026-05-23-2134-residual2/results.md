# 3차 측정 잔여 마찰 fix 검증 — 2026-05-23 21:34

## §1 payroll prSub 초기값
- 수정: `payroll.html` 초기 `<div id="prSub">` 내용 제거 (빈 문자열) + JS `load()` try/catch + 즉시 "불러오는 중..." 갱신
- 검증: `prSub` initial value = `""` (empty) ✓

## §2 coach stats 회원 수
- 수정: `admin.py` stats endpoint `@require_boss` → `@require_role(["boss","manager","coach"])`
- 검증: boss members=22, coach members=22, match=True ✓

## §3 payroll URL 직접 접근 가드
- 수정: `app.py` `_require_boss_role()` 함수 추가, `/payroll` + `/settings/notifications` 라우트에 가드 적용
- 검증: coach /payroll → 302 redirect → /stats ✓

## 결과
ALL PASS: True
