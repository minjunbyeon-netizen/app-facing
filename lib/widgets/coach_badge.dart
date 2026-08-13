import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'hkit.dart';

/// 코치 모드 시각 차별화 배지.
/// AppBar.actions 첫 자리에 두면 코치가 어떤 화면에 있는지 즉시 인지.
/// v1.32 — 자체 Container(각진 보더) 폐기, 모양은 HkBadge 하나로 통일.
/// 남은 역할은 "코치 = tierElite 색" 라는 의미 배선뿐이다.
class CoachBadge extends StatelessWidget {
  const CoachBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const HkBadge('COACH', color: HyphenTokens.tierElite);
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
