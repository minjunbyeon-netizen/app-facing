// v3.18 (2026-08-25) — 요금제 표기 한글화. 코치 설정 '요금제' 목록이
// `time_based` · `-d` · `200000₩` 같은 내부 값을 그대로 보여주던 자리를
// 사람이 읽는 말로 옮긴다 (실기 검증에서 발견).
//
// 표기 정본은 여기 한 곳이다 (§0-B) — 화면 코드에 '기간제' 같은 문자열을
// 직접 타이핑하지 말고 이 함수를 부를 것. DB·API 값(plan_type)은 계약이라
// 그대로 두고, 번역만 여기서 한다 (`core/role_labels.dart` 와 같은 방식).

/// `gym_plan.plan_type` → 한글 라벨. 모르는 값이면 원문 그대로 (침묵 금지).
String planTypeKoLabel(String? type) {
  switch (type) {
    case 'time_based':
      return '기간제';
    case 'session_based':
      return '횟수제';
    case 'group_class':
      return '그룹 수업';
    case 'pt':
      return 'PT';
    case 'couple':
      return '커플';
    case 'family':
      return '가족';
    case 'seasonal':
      return '시즌';
    default:
      return type ?? '';
  }
}

/// 금액 표기 정본 — 천 단위 쉼표 + '원'. 앱 전체가 이 함수를 쓴다.
String wonKoLabel(Object? krw) {
  final n = krw is num ? krw.toInt() : int.tryParse('$krw') ?? 0;
  final digits = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '${n < 0 ? '-' : ''}$buf원';
}

/// 요금제 카드 두 번째 줄 — `250,000원 · 30일 · 기간제`.
///
/// 기간(duration_days)·횟수(session_count) 중 있는 쪽만 넣는다. 둘 다 없으면
/// 금액과 종류만 (종전엔 없는 기간을 `-d` 로 그려 빈 값처럼 보였다).
String planSummaryKoLabel(Map<String, dynamic> plan) {
  final parts = <String>[wonKoLabel(plan['price_krw'] ?? 0)];
  final days = (plan['duration_days'] as num?)?.toInt();
  final sessions = (plan['session_count'] as num?)?.toInt();
  if (days != null && days > 0) parts.add('$days일');
  if (sessions != null && sessions > 0) parts.add('$sessions회');
  final type = planTypeKoLabel(plan['plan_type']?.toString());
  if (type.isNotEmpty) parts.add(type);
  return parts.join(' · ');
}
