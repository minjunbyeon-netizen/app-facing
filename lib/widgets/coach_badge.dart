import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 코치 모드 시각 차별화 배지.
/// AppBar.actions 첫 자리에 두면 코치가 어떤 화면에 있는지 즉시 인지.
/// tierElite (Obsession) 색 + 1px border 미니멀.
class CoachBadge extends StatelessWidget {
  const CoachBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: FacingTokens.tierElite, width: 1),
      ),
      child: Text(
        'COACH',
        style: FacingTokens.sectionLabel.copyWith(
          color: FacingTokens.tierElite,
          letterSpacing: 1.6,
          height: 1.0,
        ),
      ),
    );
  }
}

/// AppBar.actions 첫 자리에 넣을 수 있는 padded wrapper.
class CoachBadgeAction extends StatelessWidget {
  const CoachBadgeAction({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Center(child: CoachBadge()),
    );
  }
}
