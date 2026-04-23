import 'package:flutter/services.dart';

/// v1.15 P1-1: CTA 촉각 피드백 유틸. 메서드 1회 호출로 일관 적용.
/// - `light()`: 일반 버튼/토글/탭 (default)
/// - `medium()`: 중요 CTA (Enter 1RM, Save, Start WOD)
/// - `heavy()`: 결과 공개 / 등급 확정 / 큰 전환
class Haptic {
  Haptic._();
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void selection() => HapticFeedback.selectionClick();
}
