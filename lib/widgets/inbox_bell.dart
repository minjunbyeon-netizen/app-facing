import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/haptic.dart';
import '../core/shell_nav_bus.dart';
import '../core/theme.dart';
import '../features/inbox/inbox_state.dart';

/// v1.22: 모든 탭 AppBar 공통 Bell 아이콘.
/// 탭 시 Inbox(NOTICE) 탭으로 점프. 미읽음 있으면 우상단 빨간 dot.
class InboxBellAction extends StatelessWidget {
  const InboxBellAction({super.key});

  @override
  Widget build(BuildContext context) {
    final hasUnread = context.watch<InboxState>().unreadCount > 0;
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: 'Notice',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Haptic.light();
              context.read<ShellNavBus>().requestTab(2);
            },
          ),
          if (hasUnread)
            const Positioned(
              right: 10,
              top: 10,
              child: _UnreadDot(),
            ),
        ],
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: FacingTokens.accent,
        shape: BoxShape.circle,
        border: Border.all(color: FacingTokens.bg, width: 1),
      ),
    );
  }
}
