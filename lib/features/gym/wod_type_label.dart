// QA (2026-06-11): 백엔드 wod_type enum('for_time'·'amrap'·'emom')의 언더스코어가
// UI에 그대로 노출("FOR_TIME") → 표시 시점에만 'FOR TIME' 형태로 변환.
// 데이터(API payload·비교 로직·저장값)는 raw 값 유지 — Text 렌더 직전에만 사용.

// 2026-08-23 — 'custom' 은 수업 세션에서 자동 게시된 글 (PC 캘린더의
// '수업 내용' write-through). 도메인 고정어(FOR TIME 등)가 아니라서
// 'CUSTOM' 으로 띄우면 뜻이 없다 — '수업' 으로 표기한다.
String wodTypeLabel(String raw) =>
    raw == 'custom' ? '수업' : raw.replaceAll('_', ' ').toUpperCase();
