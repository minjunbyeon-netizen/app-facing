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
          color: FacingTokens.fg,
          padding: const EdgeInsets.symmetric(
            horizontal: FacingTokens.sp4,
            vertical: FacingTokens.sp2,
          ),
          child: const SafeArea(
            top: false,
            bottom: false,
            child: Text(
              '오프라인 상태 · 연결되면 자동으로 동기화됩니다',
              style: TextStyle(
                color: FacingTokens.bg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: FacingTokens.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
