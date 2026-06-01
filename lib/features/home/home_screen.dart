import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/inbox_bell.dart';
import '../../widgets/offline_banner.dart';

/// v1.23 (2026-06-02) 재배치 진행 중 — Home 임시 placeholder.
/// - Phase 1: 점수(Tier·Engine·Radar·Trend) → Profile 로 이관 완료.
/// - Phase 2: CALCULATE WOD 카테고리 → WOD 탭 하단 아코디언으로 이관 완료.
/// - Phase 3(예정): Attend 의 게이미피케이션(Level·업적·Milestones) 이 여기로 들어옴.
/// - Phase 4(예정): Notice 공지/쪽지 아코디언이 최상단에 올라옴.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HOME'),
        automaticallyImplyLeading: false,
        actions: const [InboxBellAction()],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(FacingTokens.sp5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('HOME', style: FacingTokens.sectionLabel),
                      SizedBox(height: FacingTokens.sp2),
                      Text(
                        '곧 게이미피케이션 · 공지가 들어올 자리.',
                        style: FacingTokens.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
