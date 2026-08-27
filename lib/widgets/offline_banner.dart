import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/connectivity_state.dart';
import '../core/theme.dart';

/// 오프라인 배너 — **아래를 밀어내지 않는다** (v3.34 · 2026-08-27,
/// DESIGN-SSOT §레이아웃 안정성).
///
/// 전엔 `Column [OfflineBanner, Expanded(본문)]` 이라, 연결이 끊기고 붙을 때마다
/// 배너 높이(약 46)만큼 본문 전체가 위아래로 뛰었다. 회원이 매일 여는 홈에서
/// 지하철·엘리베이터를 지날 때마다 화면이 통째로 출렁이던 원인이다.
///
/// 이제 배너는 본문 **위에 겹쳐** 뜬다([OfflineBannerOverlay] — Stack 오버레이).
/// 자리를 상시 예약하는 방법(공간 예약)도 있으나, 거의 항상 온라인인 화면 맨 위에
/// 빈 띠를 하루 종일 두는 손해가 더 크다. 겹쳐 띄우면 온라인일 때 한 뼘도 먹지 않고,
/// 오프라인이 돼도 아래 요소의 y 가 그대로다. 가리는 것은 스크롤 목록의 맨 윗줄
/// 일부뿐이고 그마저 스크롤로 즉시 드러난다.
class OfflineBanner extends StatelessWidget {
  /// 레이아웃 안정성 검사·상태 골든이 배너 유무를 잡는 앵커.
  static const Key kBanner = Key('offline-banner');

  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityState>(
      builder: (ctx, state, _) {
        if (state.isOnline) return const SizedBox.shrink();
        return Container(
          key: kBanner,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: HyphenTokens.surface,
            // 본문 위에 떠 있으므로 아래 내용과 섞이지 않게 경계선 한 줄.
            border: Border(bottom: BorderSide(color: HyphenTokens.border)),
          ),
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

/// 본문 + 오프라인 배너를 겹쳐 얹는 골격 — 배너가 붙었다 떨어져도 본문 y 는 그대로다.
///
/// 배너를 쓰는 화면은 [OfflineBanner] 를 직접 Column 에 넣지 말고 이걸 쓴다
/// (§3 코드·클래스 SSOT). 배너는 읽기 전용이라 [IgnorePointer] 로 감싸 아래 본문의
/// 스크롤·탭을 가로채지 않는다.
class OfflineBannerOverlay extends StatelessWidget {
  final Widget child;
  const OfflineBannerOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(child: OfflineBanner()),
        ),
      ],
    );
  }
}
