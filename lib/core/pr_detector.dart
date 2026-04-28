// v1.20 Phase 2.5: 클라이언트 사이드 PR(Personal Record) 감지.
//
// 백엔드 is_pr 플래그가 도입되기 전 임시 추론.
// 정책: 동일 wod_type 의 시간(estimatedTotalSec)이 직전 기록 대비 단축됐으면 PR.
// rounds-based(AMRAP) 등 시간이 의미 없는 wod_type 은 제외.

import '../features/history/history_models.dart';

class PrDetector {
  PrDetector._();

  /// 정렬된 history 를 순회하며 PR 횟수 누적.
  /// `estimatedTotalSec` 기반. null/0 인 항목 skip.
  /// 같은 wod_type 의 직전 best 보다 strict 작은 경우 +1.
  static int countPrs(List<WodHistoryItem> history) {
    if (history.isEmpty) return 0;
    final sorted = [...history]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final best = <String, int>{};
    var count = 0;
    for (final h in sorted) {
      final sec = h.estimatedTotalSec;
      if (sec == null || sec <= 0) continue;
      final key = h.wodType.trim().toLowerCase();
      if (key.isEmpty) continue;
      final prev = best[key];
      if (prev == null) {
        best[key] = sec;
        continue;
      }
      if (sec < prev) {
        count++;
        best[key] = sec;
      }
    }
    return count;
  }

  /// 신규 기록 1건이 prior best 대비 PR 인지 판정 (forTime 전용).
  /// wod_session_screen 저장 직후 unlock 모먼트 발화 판정용.
  ///
  /// 정책:
  /// - newTotalSec ≤ 0 → false (의미 있는 시간 아님)
  /// - wodType 빈 문자열 → false (분류 불가)
  /// - prior history 에 동일 wod_type 기록 없음 → false (첫 기록은 PR 아님)
  /// - prior best 존재 + newTotalSec < best (strict) → true
  static bool isPrAgainst({
    required List<WodHistoryItem> priorHistory,
    required String wodType,
    required int newTotalSec,
  }) {
    if (newTotalSec <= 0) return false;
    final key = wodType.trim().toLowerCase();
    if (key.isEmpty) return false;
    int? best;
    for (final h in priorHistory) {
      if (h.wodType.trim().toLowerCase() != key) continue;
      final s = h.estimatedTotalSec;
      if (s == null || s <= 0) continue;
      if (best == null || s < best) best = s;
    }
    return best != null && newTotalSec < best;
  }
}
