// QA (2026-06-11): 백엔드 wod_type enum('for_time'·'amrap'·'emom')의 언더스코어가
// UI에 그대로 노출("FOR_TIME") → 표시 시점에만 'FOR TIME' 형태로 변환.
// 데이터(API payload·비교 로직·저장값)는 raw 값 유지 — Text 렌더 직전에만 사용.

String wodTypeLabel(String raw) => raw.replaceAll('_', ' ').toUpperCase();
