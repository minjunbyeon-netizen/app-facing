import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/haptic.dart';
import '../core/theme.dart';
import '../features/inbox/inbox_screen.dart' show MessagingScreen;
import '../features/inbox/inbox_state.dart';

/// v1.22: 모든 탭 AppBar 공통 Bell 아이콘.
/// v1.26: 쪽지·공지 진입 일원화 — 탭 시 MessagingScreen push. 미읽음 dot 유지.
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
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MessagingScreen()),
              );
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
