// v1.19+ Engine 점수 Decay (옵션 B) — reference/gamification.md §3-3.
//
// 정책:
// - Engine overall_score 만 영향. Lv / Tier / 칭호 / 배지 보호.
// - 90일 무측정 기준선. -3% per month after 30 days inactive.
// - 재측정 시 즉시 회복 (decay 적용 없음).
// - 표시: "Last measurement: N days ago" + 회색 톤 안내.
//
// 안티: Whoop / Strava / Apple 누구도 Lv 자체 감소 안 함. 징벌형 회피.

class EngineDecay {
  EngineDecay._();

  /// 측정일로부터 N일 후 점수 decay 비율 (0.0 ~ 0.20).
  /// - 0~30일: 0% (decay 없음)
  /// - 30~90일: 선형 -3% per 30days → 90일에서 -6%
  /// - 90~180일: 선형 -3% per 30days → 180일에서 -15%
  /// - 180일+: -20% 캡 (그 이상 감소 안 함)
  static double decayFactor(int daysSinceLastMeasurement) {
    if (daysSinceLastMeasurement <= 30) return 0.0;
    if (daysSinceLastMeasurement <= 180) {
      // 30 → 0%, 60 → 3%, 90 → 6%, 120 → 9%, 150 → 12%, 180 → 15%.
      final months = (daysSinceLastMeasurement - 30) / 30.0;
      return (months * 0.03).clamp(0.0, 0.15);
    }
    // 180일 초과 → 캡 -20%
    return 0.20;
  }

  /// decay 적용된 표시 점수. 원본 보존, 표시값만 변환.
  /// score: 원본 0~100 또는 0~6 어떤 스케일이든 ratio 적용.
  static double applyDecay(double score, int daysSinceLastMeasurement) {
    final factor = decayFactor(daysSinceLastMeasurement);
    return score * (1.0 - factor);
  }

  /// 사용자 안내 텍스트 (한글 캡션, V10 패턴).
  /// 30일 미만이면 null (표시 안 함).
  static String? statusCaption(int daysSinceLastMeasurement) {
    if (daysSinceLastMeasurement <= 30) return null;
    if (daysSinceLastMeasurement <= 90) {
      return '$daysSinceLastMeasurement일 무측정. 재측정 권고.';
    }
    if (daysSinceLastMeasurement <= 180) {
      final pct = (decayFactor(daysSinceLastMeasurement) * 100).round();
      return '$daysSinceLastMeasurement일 무측정. 표시 점수 -$pct%.';
    }
    return '$daysSinceLastMeasurement일 무측정. 표시 점수 -20% (캡).';
  }

  /// 헤더 라벨 (영문, V1 단어 1개 라벨).
  static String? statusLabel(int daysSinceLastMeasurement) {
    if (daysSinceLastMeasurement <= 30) return null;
    return 'STALE';
  }
}
