import 'package:flutter/services.dart';

/// v1.15 P1-1: CTA 촉각 피드백 유틸. 메서드 1회 호출로 일관 적용.
/// - `light()`: 일반 버튼/토글/탭 (default)
/// - `medium()`: 중요 CTA (Enter 1RM, Save, Start WOD)
/// - `heavy()`: 결과 공개 / 등급 확정 / 큰 전환
/// - `achievementUnlock()`: 칭호/배지 잠금 해제 모먼트.
///   reference/gamification.md §6-3, §6-4 (HWPO 톤, 조용한 만족감).
class Haptic {
  Haptic._();
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void selection() => HapticFeedback.selectionClick();

  /// v1.19+ 칭호/배지 unlock 전용. iOS HIG `.success` 대응.
  /// 일반 unlock: lightImpact 1회.
  /// 강조 (Tier 도달 / Legendary): heavyImpact 1회 추가 (80ms delay).
  static Future<void> achievementUnlock({bool emphasize = false}) async {
    await HapticFeedback.lightImpact();
    if (emphasize) {
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.heavyImpact();
    }
  }
}
