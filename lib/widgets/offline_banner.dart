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
          color: HyphenTokens.surface,
          padding: const EdgeInsets.symmetric(
            horizontal: HyphenTokens.sp4,
            vertical: HyphenTokens.sp2,
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '오프라인',
                  style: HyphenTokens.bannerLabel.copyWith(
                    color: HyphenTokens.accent,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '연결 시 동기화.',
                  style: HyphenTokens.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
