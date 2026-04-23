import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/connectivity_state.dart';
import '../core/theme.dart';

/// 오프라인 상태일 때 상단에 얇은 배너를 표시. 온라인이면 SizedBox.shrink.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityState>(
      builder: (ctx, state, _) {
        if (state.isOnline) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: FacingTokens.surface,
          padding: const EdgeInsets.symmetric(
            horizontal: FacingTokens.sp4,
            vertical: FacingTokens.sp2,
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Text(
              'OFFLINE · 연결 시 동기화',
              style: FacingTokens.bannerLabel.copyWith(
                color: FacingTokens.accent,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
